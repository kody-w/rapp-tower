#!/bin/bash
# guard.sh — the CONTENT gate for anything about to be pushed/published to a
# PUBLIC surface. The estate's push-allowlist (~/.claude/hooks/) is a WHERE
# gate (which repo); this is the WHAT gate (does the tree contain a secret or
# a denylisted name). It is what would have stopped the localtoolsdev .env
# leak. Autonomous push paths and /ship should call this; it also runs as a
# standalone pre-push check.
#   guard.sh <repo-or-tree> [more...]   # exit 1 on any secret/denylist hit
set -uo pipefail

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
    if [ -x "$TOWER/tools/leakcheck.sh" ]; then
      if ! "$TOWER/tools/leakcheck.sh" "$f" >/dev/null 2>&1; then
        hits=1; echo "${RED}DENYLIST${RST}: $rel contains a sensitive name"
      fi
    fi
  done <<< "$files"

  if [ "$hits" -ne 0 ]; then
    echo "${RED}NO-GO${RST}: push blocked — secret or denylisted content in the diff (FR-9)."
    echo "  reviewed $n changed file(s) over $label"
    exit 1
  fi
  echo "${GRN}CLEAN${RST}: $n changed file(s) over $label — safe to push"
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
