#!/bin/bash
# leakcheck.sh — the publishing-boundary gate (iron law 7 / FR-9).
# Greps a tree that is about to be pushed/published to a PUBLIC surface
# against the tower's private denylist. Any hit is a full stop: public git
# history is unredactable in practice.
# Usage: tools/leakcheck.sh <path-to-outgoing-tree> [more paths...]
set -uo pipefail

TOWER="$(cd "$(dirname "$0")/.." && pwd)"
DENYLIST="$TOWER/sensitive/denylist.json"

if [ $# -lt 1 ]; then
    echo "usage: leakcheck.sh <path> [path...]   # tree(s) about to go public" >&2
    exit 64
fi
if [ ! -f "$DENYLIST" ]; then
    echo "FATAL: denylist missing at $DENYLIST — refusing open (fail closed)" >&2
    exit 70
fi

RED=""; GRN=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'; fi

hits=0
for target in "$@"; do
    if [ ! -e "$target" ]; then
        echo "${RED}FATAL${RST}: no such path: $target" >&2
        exit 66
    fi
    # Terms + word-boundary flags come from the denylist; never inline them here.
    while IFS=$'\t' read -r term boundary rx; do
        [ -z "$term" ] && continue
        # An entry may carry an explicit `regex`, because literal terms cannot
        # express separator variants: "bchydro", "bc-hydro", "BC Hydro" and
        # "bc_hydro" are one name, and enumerating spellings is whack-a-mole
        # that loses (bc_hydro slipped through exactly that way).
        if [ -n "$rx" ]; then
            pattern="$rx"
        elif [ "$boundary" = "1" ]; then
            pattern="\\b${term}\\b"
        else
            pattern="$term"
        fi
        # grep -r follows the tree; exclude .git internals (history is checked
        # separately below), binaries reported as matches too (-I would hide them).
        found=$(grep -riIlE --exclude-dir=.git -- "$pattern" "$target" 2>/dev/null || true)
        if [ -n "$found" ]; then
            hits=1
            echo "${RED}LEAK${RST}: '${term}' in:"
            echo "$found" | sed 's/^/    /'
        fi
        # If the target is a git repo, sweep reachable history too — a term
        # scrubbed from the worktree still publishes via git log.
        if [ -d "$target/.git" ]; then
            ghits=$(git -C "$target" grep -riIlE "$pattern" "$(git -C "$target" rev-parse HEAD 2>/dev/null)" 2>/dev/null | head -5 || true)
            if [ -n "$ghits" ]; then
                hits=1
                echo "${RED}LEAK (in HEAD tree)${RST}: '${term}':"
                echo "$ghits" | sed 's/^/    /'
            fi
        fi
    done < <(python3 - "$DENYLIST" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
wb = set(d.get("word_boundary_terms", []))
for e in d["entries"]:
    print(f"{e['term']}\t{1 if e['term'] in wb else 0}\t{e.get('regex','')}")
PY
)
done

if [ "$hits" -ne 0 ]; then
    echo "${RED}NO-GO${RST}: denylisted terms found. Do not push/publish. (FR-9)"
    exit 1
fi
echo "${GRN}CLEAN${RST}: no denylisted terms in $*"
