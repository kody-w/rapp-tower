#!/usr/bin/env python3
"""Apply the installer loading/robustness fixes to install.sh by exact-anchor replacement.

Usage: patch_installers.py <grail|live> <path/to/install.sh>
Every anchor must match exactly once or the script aborts without writing.
"""
import sys

flavor, path = sys.argv[1], sys.argv[2]
src = open(path, encoding="utf-8").read()
orig = src

VENV_HELPER = r'''
# Debian/Ubuntu split `venv` out of the interpreter package: `python3 -m venv` fails
# with "ensurepip is not available" until pythonX.Y-venv is installed. Returns 1 where
# apt is absent so the caller can fall back to a plain ensurepip attempt.
apt_install_python_venv() {
    command -v apt-get &> /dev/null || return 1
    local pyver=""
    if [[ -n "${PYTHON_CMD:-}" ]]; then
        pyver=$("$PYTHON_CMD" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null) || pyver=""
    fi
    echo -e "  ${YELLOW}Installing the Debian/Ubuntu venv package for Python ${pyver:-3}...${NC}"
    sudo apt-get update || true
    if [[ -n "$pyver" ]] && sudo apt-get install -y "python${pyver}-venv"; then return 0; fi
    sudo apt-get install -y python3-venv
}
'''

VENV_FAIL_HINT = r'''            echo -e "  ${RED}✗${NC} Failed to create virtual environment"
            if command -v apt-get &> /dev/null; then
                echo "    Try: sudo apt-get install -y python3-venv, then rerun this command"
            else
                echo "    Try: $PYTHON_CMD -m ensurepip --upgrade, then rerun this command"
            fi
            exit 1'''

common = [
    # F1: Ubuntu 24.04+ has no python3.11 apt package; fall back to the distro python3.
    (
        "            sudo apt-get update && sudo apt-get install -y python3.11 python3.11-venv python3-pip\n",
        "            # Ubuntu 24.04+ ships no python3.11 package (python3 there is 3.12+), so\n"
        "            # fall back to the distro default — find_python accepts any 3.11+.\n"
        "            sudo apt-get update || true\n"
        "            sudo apt-get install -y python3.11 python3.11-venv python3-pip \\\n"
        "                || sudo apt-get install -y python3 python3-venv python3-pip\n",
    ),
    # helper function, inserted before version_gt()
    (
        "\n# Compare two semver strings. Returns 0 if $1 > $2, 1 otherwise.\n",
        VENV_HELPER + "\n# Compare two semver strings. Returns 0 if $1 > $2, 1 otherwise.\n",
    ),
    # F4: bound the two VERSION lookups so a black-holed GitHub can't stall the run.
    (
        '    remote_version=$(curl -fsSL "$REMOTE_VERSION_URL" 2>/dev/null | tr -d \'[:space:]\') || true\n'
        '\n'
        '    if [[ -z "$remote_version" ]]; then\n'
        '        echo -e "  ${YELLOW}⚠${NC} Could not check remote version — upgrading anyway"\n'
        '        return 0\n'
        '    fi\n',
        '    # Bounded: without --max-time a black-holed GitHub (packets dropped, not refused)\n'
        '    # parks this curl on the OS connect timeout. A timeout (28) means GitHub itself\n'
        '    # is black-holed, so every later git fetch/pull would hang the same way (measured\n'
        '    # 133s) — keep the installed version and launch it. A fast failure (refused, DNS,\n'
        '    # TLS) keeps today\'s behavior: git fails just as fast, so try the upgrade anyway.\n'
        '    local curl_rc=0\n'
        '    remote_version=$(curl -fsSL --connect-timeout 10 --max-time 20 "$REMOTE_VERSION_URL" 2>/dev/null) || curl_rc=$?\n'
        '    remote_version=$(printf \'%s\' "$remote_version" | tr -d \'[:space:]\')\n'
        '\n'
        '    if [[ -z "$remote_version" ]]; then\n'
        '        if [[ "$curl_rc" == 28 ]]; then\n'
        '            GITHUB_UNREACHABLE=true\n'
        '            echo -e "  ${YELLOW}⚠${NC} GitHub is not reachable right now — keeping the installed version"\n'
        '            return 1\n'
        '        fi\n'
        '        echo -e "  ${YELLOW}⚠${NC} Could not check remote version — upgrading anyway"\n'
        '        return 0\n'
        '    fi\n',
    ),
    (
        '            TARGET_VER=$(curl -sf "$REMOTE_VERSION_URL" 2>/dev/null || echo "0.0.0")\n',
        '            TARGET_VER=$(curl -sf --connect-timeout 10 --max-time 20 "$REMOTE_VERSION_URL" 2>/dev/null || echo "0.0.0")\n',
    ),
    # F3 (part 1): remember the pre-upgrade commit so a bundled agent's old copy can be
    # recognised as "just the previous release" rather than user work.
    (
        '            git stash --quiet 2>/dev/null || true\n',
        '            local OLD_HEAD=""\n'
        '            OLD_HEAD=$(git rev-parse HEAD 2>/dev/null) || OLD_HEAD=""\n'
        '            git stash --quiet 2>/dev/null || true\n',
    ),
    # F3 (part 2): "shipped" = tracked by git, not "present in the directory" — the
    # directory also holds the user's untracked agents after a reset/pull.
    (
        '                local SHIPPED=""\n'
        '                for shipped_file in "$AGENTS_DIR"/*.py; do\n'
        '                    [ -f "$shipped_file" ] || continue\n'
        '                    SHIPPED="$SHIPPED $(basename "$shipped_file")"\n'
        '                done\n',
        '                # "Shipped" means tracked by git in the fresh checkout. Listing the\n'
        '                # directory instead also counts the user\'s own untracked agents (a\n'
        '                # reset/pull leaves them in place) and so flagged every one of them,\n'
        '                # plus every bundled agent, as a "collision" on each upgrade.\n'
        '                local SHIPPED=""\n'
        '                SHIPPED=$(cd "$AGENTS_DIR" && git ls-files -- \'*.py\' 2>/dev/null | tr \'\\n\' \' \')\n'
        '                if [ -z "${SHIPPED// /}" ]; then\n'
        '                    for shipped_file in "$AGENTS_DIR"/*.py; do\n'
        '                        [ -f "$shipped_file" ] || continue\n'
        '                        SHIPPED="$SHIPPED $(basename "$shipped_file")"\n'
        '                    done\n'
        '                fi\n',
    ),
    # F6 (part 1): flag for the launch path.
    (
        'PIN_VERSION=""\n',
        'PIN_VERSION=""\n'
        'SOURCE_SYNCED_THIS_RUN=false\n'
        'GITHUB_UNREACHABLE=false\n',
    ),
    (
        '    echo -e "  ${GREEN}✓${NC} Source code ready"\n}\n',
        '    echo -e "  ${GREEN}✓${NC} Source code ready"\n'
        '    SOURCE_SYNCED_THIS_RUN=true\n}\n',
    ),
    # F6 (part 2): don't pull again at launch when this run just synced the source.
    (
        '    # Always pull latest code before launching\n'
        '    if [ -d "$BRAINSTEM_HOME/src/.git" ]; then\n'
        '        cd "$BRAINSTEM_HOME/src"\n'
        '        git pull --quiet 2>/dev/null || true\n'
        '    fi\n',
        '    # Pull latest code before launching — unless this very run already fetched\n'
        '    # and checked out the source, in which case a pull is one more round trip to\n'
        '    # GitHub for nothing, and never when GitHub was already found unreachable (a\n'
        '    # pull would hang on the OS timeout). A pinned checkout is never moved.\n'
        '    if [ -d "$BRAINSTEM_HOME/src/.git" ] && [[ "$SOURCE_SYNCED_THIS_RUN" != true ]] \\\n'
        '        && [[ "$GITHUB_UNREACHABLE" != true ]] && [ -z "$PIN_VERSION" ]; then\n'
        '        cd "$BRAINSTEM_HOME/src"\n'
        '        git pull --quiet 2>/dev/null || true\n'
        '    fi\n',
    ),
]

if flavor == "live":
    specific = [
        # F2: venv failure → install the distro venv package and retry; honest hint.
        (
            '    if ! run_with_heartbeat "Creating Python virtual environment" "$PYTHON_CMD" -m venv "$VENV_DIR"; then\n'
            '        # Some systems need ensurepip first\n'
            '        "$PYTHON_CMD" -m ensurepip 2>/dev/null || true\n'
            '        if ! run_with_heartbeat "Retrying Python virtual environment" "$PYTHON_CMD" -m venv "$VENV_DIR"; then\n'
            '            echo -e "  ${RED}✗${NC} Failed to create virtual environment"\n'
            '            echo "    Try: $PYTHON_CMD -m pip install virtualenv"\n'
            '            exit 1\n'
            '        fi\n'
            '    fi\n',
            '    if ! run_with_heartbeat "Creating Python virtual environment" "$PYTHON_CMD" -m venv "$VENV_DIR"; then\n'
            '        rm -rf "$VENV_DIR"\n'
            '        # Debian/Ubuntu ship venv separately (pythonX.Y-venv); without it `-m venv`\n'
            '        # fails with "ensurepip is not available". Install it, then retry. Elsewhere\n'
            '        # a bare ensurepip run is the usual cure.\n'
            '        if ! apt_install_python_venv; then\n'
            '            "$PYTHON_CMD" -m ensurepip 2>/dev/null || true\n'
            '        fi\n'
            '        if ! run_with_heartbeat "Retrying Python virtual environment" "$PYTHON_CMD" -m venv "$VENV_DIR"; then\n'
            + VENV_FAIL_HINT + '\n'
            '        fi\n'
            '    fi\n',
        ),
        # F5: drop the pip self-upgrade (measured ~3s + a network round trip; every
        # Python 3.11+ venv already carries a pip new enough for these wheels).
        (
            '    # Ensure pip is up to date inside the venv\n'
            '    run_with_heartbeat "Updating pip" "$VENV_DIR/bin/python" -m pip install --upgrade pip --disable-pip-version-check || true\n',
            '    # No `pip install --upgrade pip` here: every Python 3.11+ venv already carries\n'
            '    # a pip new enough for these wheels, and the upgrade cost a network round trip\n'
            '    # (~3s measured) plus one more way to fail before the first dependency lands.\n',
        ),
        # F7: a failed retry must reach the import check (which prints the ✗ + hint)
        # instead of killing the script silently under `set -e`.
        (
            '        echo -e "  ${YELLOW}⚠${NC} Retrying dependency install with full output..."\n'
            '        "$VENV_DIR/bin/python" -m pip install -r "$req_file" --progress-bar on\n',
            '        echo -e "  ${YELLOW}⚠${NC} Retrying dependency install with full output..."\n'
            '        "$VENV_DIR/bin/python" -m pip install -r "$req_file" --progress-bar on || true\n',
        ),
        (
            '    if ! run_with_heartbeat "Installing missing Python dependencies" "$VENV_DIR/bin/python" -m pip install -r "$req_file" --disable-pip-version-check; then\n'
            '        "$VENV_DIR/bin/python" -m pip install -r "$req_file" --progress-bar on\n',
            '    if ! run_with_heartbeat "Installing missing Python dependencies" "$VENV_DIR/bin/python" -m pip install -r "$req_file" --disable-pip-version-check; then\n'
            '        "$VENV_DIR/bin/python" -m pip install -r "$req_file" --progress-bar on || true\n',
        ),
        # F3 (part 3, upgrade path): only a copy that differs from what the OLD checkout
        # shipped is user work worth preserving + warning about.
        (
            '                    case " $SHIPPED " in\n'
            '                        *" $fname "*)\n'
            '                            preserve_agent_collision "$agent_file"\n'
            '                            continue\n'
            '                            ;;\n'
            '                    esac\n',
            '                    case " $SHIPPED " in\n'
            '                        *" $fname "*)\n'
            '                            # Bundled agent: the fresh checkout wins (issue #2). Stay quiet\n'
            '                            # when the backup is byte-identical to what the OLD checkout\n'
            '                            # shipped — that is the previous release, not user work.\n'
            '                            if [ -n "$OLD_HEAD" ] \\\n'
            '                                && git show "$OLD_HEAD:rapp_brainstem/agents/$fname" 2>/dev/null | cmp -s - "$agent_file"; then\n'
            '                                continue\n'
            '                            fi\n'
            '                            preserve_agent_collision "$agent_file"\n'
            '                            continue\n'
            '                            ;;\n'
            '                    esac\n',
        ),
        # F3 (part 4, fresh-repair path): same idea — identical to the shipped file is not a collision.
        (
            '                case " $FRESH_SHIPPED " in\n'
            '                    *" $fn "*)\n'
            '                        preserve_agent_collision "$af"\n'
            '                        continue\n'
            '                        ;;\n'
            '                esac\n',
            '                case " $FRESH_SHIPPED " in\n'
            '                    *" $fn "*)\n'
            '                        cmp -s "$af" "$AGENTS_DIR/$fn" 2>/dev/null || preserve_agent_collision "$af"\n'
            '                        continue\n'
            '                        ;;\n'
            '                esac\n',
        ),
    ]
elif flavor == "grail":
    specific = [
        # F2
        (
            '    "$PYTHON_CMD" -m venv "$VENV_DIR" 2>/dev/null || {\n'
            '        # Some systems need ensurepip first\n'
            '        "$PYTHON_CMD" -m ensurepip 2>/dev/null || true\n'
            '        "$PYTHON_CMD" -m venv "$VENV_DIR" || {\n'
            '            echo -e "  ${RED}✗${NC} Failed to create virtual environment"\n'
            '            echo "    Try: $PYTHON_CMD -m pip install virtualenv"\n'
            '            exit 1\n'
            '        }\n'
            '    }\n',
            '    "$PYTHON_CMD" -m venv "$VENV_DIR" 2>/dev/null || {\n'
            '        rm -rf "$VENV_DIR"\n'
            '        # Debian/Ubuntu ship venv separately (pythonX.Y-venv); without it `-m venv`\n'
            '        # fails with "ensurepip is not available". Install it, then retry. Elsewhere\n'
            '        # a bare ensurepip run is the usual cure.\n'
            '        if ! apt_install_python_venv; then\n'
            '            "$PYTHON_CMD" -m ensurepip 2>/dev/null || true\n'
            '        fi\n'
            '        "$PYTHON_CMD" -m venv "$VENV_DIR" || {\n'
            + VENV_FAIL_HINT + '\n'
            '        }\n'
            '    }\n',
        ),
        # F5
        (
            '    # Ensure pip is up to date inside the venv\n'
            '    "$VENV_DIR/bin/python" -m pip install --upgrade pip --quiet 2>/dev/null || true\n',
            '    # No `pip install --upgrade pip` here: every Python 3.11+ venv already carries\n'
            '    # a pip new enough for these wheels, and the upgrade cost a network round trip\n'
            '    # (~3s measured) plus one more way to fail before the first dependency lands.\n',
        ),
        # F7 (two sites: setup_deps and ensure_deps)
        (
            '    "$VENV_DIR/bin/pip" install -r "$req_file" --quiet 2>/dev/null || \\\n'
            '        "$VENV_DIR/bin/pip" install -r "$req_file"\n',
            '    "$VENV_DIR/bin/pip" install -r "$req_file" --quiet 2>/dev/null || \\\n'
            '        "$VENV_DIR/bin/pip" install -r "$req_file" || true\n',
        ),
        # F3 (part 3)
        (
            '                    case " $SHIPPED " in *" $fname "*) continue ;; esac\n',
            '                    case " $SHIPPED " in\n'
            '                        *" $fname "*)\n'
            '                            # Bundled agent: the fresh checkout wins (issue #2). Keep a copy\n'
            '                            # only when it differs from what the OLD checkout shipped —\n'
            '                            # identical means the previous release, not user work.\n'
            '                            if [ -n "$OLD_HEAD" ] \\\n'
            '                                && git show "$OLD_HEAD:rapp_brainstem/agents/$fname" 2>/dev/null | cmp -s - "$agent_file"; then\n'
            '                                continue\n'
            '                            fi\n'
            '                            preserve_agent_collision "$agent_file"\n'
            '                            continue\n'
            '                            ;;\n'
            '                    esac\n',
        ),
    ]
else:
    sys.exit("flavor must be grail or live")

expected_counts = {}
for old, new in common + specific:
    n = src.count(old)
    want = 2 if (flavor == "grail" and old.startswith('    "$VENV_DIR/bin/pip" install -r')) else 1
    if n != want:
        sys.exit(f"ABORT: anchor matched {n}x (want {want}):\n{old[:160]!r}")
    src = src.replace(old, new)

open(path, "w", encoding="utf-8").write(src)
print(f"patched {path}: {len(common)+len(specific)} replacements, {len(src)-len(orig):+d} bytes")
