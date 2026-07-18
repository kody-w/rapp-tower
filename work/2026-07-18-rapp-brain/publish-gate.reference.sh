#!/bin/bash
# publish-gate.sh — THE leak boundary. MUST pass before ANY push to this public
# repo. Two layers:
#   (1) generic secret patterns + secret filenames (self-contained, always runs)
#   (2) the tower's PRIVATE denylist of customer/work names (customer names live
#       ONLY in the private tower — this gate calls the tower's leakcheck if
#       present; if absent it WARNS, because the name layer can't run off-machine)
#
# Design principle: the public brain is built by INGESTING ONLY PUBLIC BYTES,
# never by redacting private content. This gate is the backstop, not the plan.
#   publish-gate.sh [tree]     (default: this repo, minus private/ and .git)
set -uo pipefail

BRAIN="$(cd "$(dirname "$0")/.." && pwd)"
TREE="${1:-$BRAIN}"
TOWER="${RAPP_TOWER:-$HOME/Documents/GitHub/rapp-tower}"
RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

hits=0
SECRET_PATTERNS='(ghp|ghu|ghs|gho)_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|(AZURE_OPENAI_API_KEY|client_secret|secret_key|access_token|api_key)[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+_.-]{20,}'
SECRET_FILES='\.env$|\.copilot_token$|\.pem$|_token$|_secret\.json$|secrets?\.(json|txt|ya?ml)$'
SELF='/tools/publish-gate\.sh$'

# 0) private/ must never be tracked here.
if [ -d "$TREE/.git" ]; then
  if git -C "$TREE" ls-files 2>/dev/null | grep -qE '^private/'; then
    hits=1; echo "${RED}BOUNDARY BREACH${RST}: files under private/ are git-TRACKED — that overlay must stay gitignored"
    git -C "$TREE" ls-files | grep -E '^private/' | sed 's/^/    /' | head
  fi
fi

# 1) secret value patterns (skip private/ overlay and this gate's own signatures).
while IFS= read -r f; do
  [ -z "$f" ] && continue
  echo "$f" | grep -qE "$SELF|/private/" && continue
  hits=1; echo "${RED}SECRET${RST}: $f matches a credential pattern"
done < <(grep -rlaE --exclude-dir=.git --exclude-dir=private "$SECRET_PATTERNS" "$TREE" 2>/dev/null)

# 2) secret filenames tracked in git.
if [ -d "$TREE/.git" ]; then
  tr=$(git -C "$TREE" ls-files 2>/dev/null | grep -vE '^private/' | grep -E "$SECRET_FILES" || true)
  [ -n "$tr" ] && { hits=1; echo "${RED}SECRET-FILE TRACKED${RST}:"; echo "$tr" | sed 's/^/    /'; }
fi

# 3) customer/work name denylist — the tower half of the boundary.
if [ -x "$TOWER/tools/leakcheck.sh" ]; then
  # scan everything EXCEPT private/ (which is gitignored and never pushed)
  scan=$(find "$TREE" -type f 2>/dev/null | grep -vE '/\.git/|/private/' | head -5000)
  if [ -n "$scan" ]; then
    if ! echo "$scan" | tr '\n' '\0' | xargs -0 "$TOWER/tools/leakcheck.sh" >/dev/null 2>&1; then
      hits=1; echo "${RED}DENYLIST${RST}: outgoing tree contains customer/work names (tower leakcheck) — do NOT publish"
    fi
  fi
else
  echo "${YEL}WARN${RST}: tower denylist not found at $TOWER — name-layer NOT checked. Run this gate from the tower machine before publishing."
fi

if [ "$hits" -ne 0 ]; then echo "${RED}NO-GO${RST}: leak boundary would be breached — do not push."; exit 1; fi
echo "${GRN}CLEAN${RST}: safe to publish $TREE"
