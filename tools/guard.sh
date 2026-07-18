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

if [ $# -lt 1 ]; then echo "usage: guard.sh <repo-or-tree> [more...]" >&2; exit 64; fi

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
