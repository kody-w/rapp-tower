#!/bin/bash
# guard.sh — the CONTENT gate for anything about to be pushed/published to a
# PUBLIC surface. The estate's push-allowlist (~/.claude/hooks/) is a WHERE
# gate (which repo); this is the WHAT gate (does the tree contain a secret or
# a denylisted name). It is what would have stopped the localtoolsdev .env
# leak. Autonomous push paths and /ship should call this; it also runs as a
# standalone pre-push check.
#   guard.sh <repo-or-tree> [more...]   # exit 1 on any secret/denylist hit
set -uo pipefail
TOWER_HOLDS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/holds.sh"


# ── FR-10: parallel-session holds ────────────────────────────────────────────
# On 2026-07-25 two Claude sessions wrote 11 commits to rapp-light and 9 to RAR
# within two hours, both authoring as the same human. They independently built
# two different "check 6", and untangling it cost a rebase conflict and two
# pushes that silently did not happen. holds.sh existed the whole time and said
# "no active holds" — nobody claimed anything, including me.
#
# An advisory protocol that runs on the honour system is not a protocol. The
# content gate already runs on every push path, so the holds check runs here,
# where it cannot be forgotten. A collision on cosmetics is what got caught
# tonight; the one that will not get caught is two sessions editing the same
# security control.
check_holds() {
  local slug="$1" name
  [ -n "$slug" ] || return 0
  name="${slug##*/}"
  [ -x "$TOWER_HOLDS" ] || return 0
  if ! "$TOWER_HOLDS" check "$name" >/tmp/.guard-holds 2>&1; then
    echo "${RED}NO-GO${RST}: another session holds '$name'."
    sed 's/^/    /' /tmp/.guard-holds
    echo "    Coordinate, or take it over deliberately:"
    echo "      tools/holds.sh release $name && tools/holds.sh claim $name \"why\""
    return 1
  fi
  # Not held by anyone. Claim it for this session so a concurrent writer sees
  # us — pushing to a repo IS working on it, and a claim nobody makes is a
  # claim nobody honours.
  "$TOWER_HOLDS" claim "$name" "guard: pushing" >/dev/null 2>&1 || true
  return 0
}


TOWER="$(cd "$(dirname "$0")/.." && pwd)"
RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

#   guard.sh --changed [<range>] [repo]  # ONLY the files a push would carry
#   guard.sh --install-hook <repo>       # install as that repo's pre-push hook
#
# WHY --changed EXISTS: the whole-tree scan is O(repo). On kody-w/rapp-god
# (2.3 GB, 42k blobs) it runs >8 minutes — which is exactly why this gate was
# built but never wired into a push path. A hook that costs 8 minutes gets
# bypassed, and a bypassed gate is not a gate. --changed scans only what the
# push actually adds, so it costs milliseconds and can be mandatory.

MODE="tree"; RANGE=""
case "${1:-}" in
  --changed|--staged)
    MODE="changed"; shift
    case "${1:-}" in ""|-*) : ;; *..*) RANGE="$1"; shift ;; esac ;;
  --install-hook)
    repo="${2:-}"; [ -d "$repo/.git" ] || { echo "usage: guard.sh --install-hook <repo>" >&2; exit 64; }
    hook="$repo/.git/hooks/pre-push"
    { echo '#!/bin/bash'
      echo '# installed by rapp-tower guard.sh — the CONTENT gate (FR-9).'
      echo '# Blocks a push carrying a secret or a denylisted name. To bypass in a'
      echo '# real emergency: git push --no-verify (and record why in work/).'
      echo "exec \"$TOWER/tools/guard.sh\" --changed \"\$(git rev-parse --show-toplevel)\""
    } > "$hook"
    chmod +x "$hook"
    echo "${GRN}installed${RST}: $hook -> guard.sh --changed"
    exit 0 ;;
esac

if [ $# -lt 1 ]; then echo "usage: guard.sh [--changed [range]] <repo-or-tree> [more...]" >&2; exit 64; fi

hits=0

# Secret value patterns — HIGH-PRECISION only (provider-prefixed tokens, private
# keys, and explicit credential ASSIGNMENTS with a real-looking value). Word-only
# matches like a bare "api_key" in prose are deliberately excluded to avoid
# flagging docs/SHAs. Presence of the PATTERN is flagged; the value is never
# printed (only file:count).
SECRET_PATTERNS='(ghp|ghu|ghs|gho)_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|(AZURE_OPENAI_API_KEY|VITE_ENTRA_CLIENT_SECRET|client_secret|secret_key|access_token|api_key)[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+_.-]{20,}'

# The tower's own signature files DEFINE these patterns/terms — never self-flag.
SELF_EXCLUDE='/tools/guard\.sh$|/tools/leakcheck\.sh$|/sensitive/'

# Filenames that should never ride to a public repo (even gitignored ones can
# be force-added; catch tracked ones).
SECRET_FILES='\.env$|\.copilot_token$|\.pem$|_token$|\.brainstem_secret$|_secret\.json$|secrets?\.(json|txt|ya?ml)$'

# ---- --changed: scan only the files this push would carry ------------------
if [ "$MODE" = "changed" ]; then
  repo="${1:-.}"
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || {
    echo "${RED}FATAL${RST}: --changed needs a git repo: $repo" >&2; exit 66; }

  # Range resolution, most-specific first: explicit range > unpushed commits
  # vs the tracked upstream > staged. Fail OPEN on range errors is wrong here:
  # if we cannot tell what is being pushed, we scan the index (fail closed).
  # Two different rules, and conflating them makes the gate cry wolf:
  #   SECRETS  -- never belong in ANY repo, public or private. Always checked.
  #   DENYLIST -- the PUBLISHING boundary (customer/work names). Only meaningful
  #               when the destination is PUBLIC. The tower itself is private and
  #               is explicitly allowed to hold work context (CLAUDE.md), so
  #               enforcing the denylist here would block the estate's own
  #               decision log and train everyone to --no-verify.
  # Fail closed on ambiguity: if visibility cannot be determined, treat as PUBLIC.
  vis="PUBLIC"; vis_why="could not determine remote visibility — assuming public"
  origin_url=$(git -C "$repo" remote get-url origin 2>/dev/null || true)
  if [ -z "$origin_url" ]; then
    vis="PUBLIC"; vis_why="no origin remote — assuming public"
  else
    slug=$(printf '%s' "$origin_url" | sed -E 's#(git@|https://)github\.com[:/]##; s#\.git$##')
    v=$(gh repo view "$slug" --json visibility --jq '.visibility' 2>/dev/null || true)
    if [ -n "$v" ]; then vis="$v"; vis_why="origin $slug is $v"; fi
  fi

  no_upstream=0
  if [ -z "$RANGE" ]; then
    up=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
    if [ -n "$up" ] && git -C "$repo" rev-parse --verify -q "$up" >/dev/null 2>&1; then
      RANGE="$up..HEAD"
    else
      no_upstream=1
    fi
  fi

  # FAIL CLOSED. With no upstream — a brand-new repo's FIRST push, which is
  # precisely when a whole leaky tree gets published in one shot — there is no
  # diff to take, so "no diff" must mean "scan everything tracked", never
  # "nothing to scan". An earlier build of this gate passed a first push
  # vacuously; that is the single most dangerous moment to wave through.
  if [ "$no_upstream" -eq 1 ]; then
    files=$(git -C "$repo" ls-files 2>/dev/null || true)
    label="ALL tracked (first push — no upstream)"
  else
    files=$(git -C "$repo" diff --name-only --diff-filter=ACMR "$RANGE" 2>/dev/null || true)
    label="$RANGE"
  fi
  staged=$(git -C "$repo" diff --name-only --cached --diff-filter=ACMR 2>/dev/null || true)
  files=$(printf '%s\n%s\n' "$files" "$staged" | grep -v '^$' | sort -u || true)

  n=$(printf '%s' "$files" | grep -c . || true)
  if [ "${n:-0}" -eq 0 ]; then
    if [ "$no_upstream" -eq 1 ]; then
      echo "${RED}NO-GO${RST}: no upstream AND no tracked files — cannot determine what "
      echo "  would be pushed. Refusing to wave it through (fail closed)."
      exit 1
    fi
    check_holds "${slug:-}" || exit 1
    echo "${GRN}CLEAN${RST}: nothing to scan ($label — no added/changed files)"; exit 0
  fi

  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    f="$repo/$rel"
    [ -f "$f" ] || continue                       # deleted paths carry nothing
    echo "$rel" | grep -qE "$SELF_EXCLUDE" && continue
    if echo "$rel" | grep -qE "$SECRET_FILES"; then
      hits=1; echo "${RED}SECRET-FILE${RST}: $rel (must never ride to a public repo)"
    fi
    c=$(grep -aEc "$SECRET_PATTERNS" "$f" 2>/dev/null || echo 0)
    if [ "${c:-0}" -gt 0 ] 2>/dev/null; then
      hits=1; echo "${RED}SECRET${RST}: $rel ($c line(s) match a credential pattern)"
    fi
    if [ "$vis" != "PRIVATE" ] && [ -x "$TOWER/tools/leakcheck.sh" ]; then
      if ! "$TOWER/tools/leakcheck.sh" "$f" >/dev/null 2>&1; then
        # RATCHET, not a wall. A file may carry pre-existing denylisted names
        # that are a separate, undecided cleanup (e.g. a work-distro name that
        # an estate map must state ACCURATELY). Blocking those walls off
        # unrelated PII fixes to the same file -- which is how a gate ends up
        # bypassed. So: compare against the committed baseline and fail only
        # if this change ADDS occurrences. Untracked/new files have no
        # baseline and are judged in full.
        now=$("$TOWER/tools/leakcheck.sh" "$f" 2>/dev/null | grep -c "^LEAK" || true)
        base=0
        if git -C "$repo" cat-file -e "HEAD:$rel" 2>/dev/null; then
          tmp=$(mktemp); git -C "$repo" show "HEAD:$rel" > "$tmp" 2>/dev/null
          base=$("$TOWER/tools/leakcheck.sh" "$tmp" 2>/dev/null | grep -c "^LEAK" || true)
          rm -f "$tmp"
        fi
        if [ "${now:-0}" -gt "${base:-0}" ]; then
          hits=1
          echo "${RED}DENYLIST${RST}: $rel ADDS sensitive name(s) (${base} -> ${now})"
        else
          echo "${YEL}denylist (pre-existing, not added by this change)${RST}: $rel (${base})"
        fi
      fi
    fi
  done <<< "$files"

  if [ "$hits" -ne 0 ]; then
    echo "${RED}NO-GO${RST}: push blocked — secret or denylisted content in the diff (FR-9)."
    echo "  reviewed $n changed file(s) over $label  [$vis_why]"
    exit 1
  fi
  scope="secrets + denylist"
  [ "$vis" = "PRIVATE" ] && scope="secrets only (private destination — denylist N/A)"
  check_holds "${slug:-}" || exit 1
  echo "${GRN}CLEAN${RST}: $n changed file(s) over $label — safe to push"
  echo "  checked: $scope  [$vis_why]"
  exit 0
fi

for target in "$@"; do
  if [ ! -e "$target" ]; then echo "${RED}FATAL${RST}: no such path: $target" >&2; exit 66; fi

  # 1) denylisted names (customer/work) — delegate to leakcheck (fail-closed).
  if [ -x "$TOWER/tools/leakcheck.sh" ]; then
    if ! "$TOWER/tools/leakcheck.sh" "$target" >/dev/null 2>&1; then
      hits=1; echo "${RED}DENYLIST${RST}: $target contains sensitive names —"; "$TOWER/tools/leakcheck.sh" "$target" 2>/dev/null | grep -E 'LEAK|:' | head
    fi
  fi

  # 2) secret VALUE patterns in the tree (report file + count, never the value).
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    echo "$f" | grep -qE "$SELF_EXCLUDE" && continue
    n=$(grep -aEc "$SECRET_PATTERNS" "$f" 2>/dev/null || echo 0)
    if [ "$n" -gt 0 ] 2>/dev/null; then hits=1; echo "${RED}SECRET${RST}: $f ($n line(s) match a credential pattern)"; fi
  done < <(grep -rlaE --exclude-dir=.git "$SECRET_PATTERNS" "$target" 2>/dev/null)

  # 3) secret FILENAMES, both on disk and (if a git repo) tracked in HEAD.
  found=$(find "$target" -type f 2>/dev/null | grep -vE '/\.git/' | grep -E "$SECRET_FILES" || true)
  if [ -n "$found" ]; then
    echo "${YEL}SECRET-FILE on disk${RST} (ensure gitignored, verify not tracked):"; echo "$found" | sed 's/^/    /' | head
  fi
  if [ -d "$target/.git" ]; then
    tracked=$(git -C "$target" ls-files 2>/dev/null | grep -E "$SECRET_FILES" || true)
    if [ -n "$tracked" ]; then hits=1; echo "${RED}SECRET-FILE TRACKED IN GIT${RST}: $target —"; echo "$tracked" | sed 's/^/    /' | head; fi
  fi
done

if [ "$hits" -ne 0 ]; then
  echo "${RED}NO-GO${RST}: do not push/publish — secret or denylisted content present (FR-9)."
  exit 1
fi
echo "${GRN}CLEAN${RST}: no secrets or denylisted names in $*"
