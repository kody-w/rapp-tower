#!/bin/bash
# checkouts.sh — one-screen truth about every registered local checkout:
# branch, dirtiness, ahead/behind origin, who holds what, plus the grail
# push tripwire and memory-backup staleness. Identity/health of live
# services is tools/triage.sh; train position is tools/train.sh.
set -uo pipefail

RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

REGISTRY=(
  "$HOME/.brainstem/src|GRAIL — LIVE SOLE-COPY STATE inside (.brainstem_data, twins, cubbies): backup-memory.sh before ANY surgery"
  "$HOME/Documents/GitHub/rapp-canary|ring: canary (contested — scratch-clone for work)"
  "$HOME/Documents/GitHub/rapp-nightly|ring: nightly (promotion target)"
  "$HOME/Documents/GitHub/rapp-alpha|ring: alpha (promotion target)"
  "$HOME/Documents/GitHub/rapp-beta|ring: beta (promotion target)"
  "$HOME/Documents/GitHub/RAPP|distro (cron writes here every 30 min — dirty is often the sim loop, not a session)"
  "$HOME/Documents/GitHub/RAR|registry (THE active checkout; stale/dirty on purpose — see work/2026-07-18-standing-oddities)"
  "$HOME/Documents/GitHub/rapp-map|estate map + drift governance (drift.sh reads it)"
  "$HOME/Documents/GitHub/aibast-agents-library|work-sync fork (manual PRs only)"
  "$HOME/Documents/GitHub/rapp-train|deck/playbook/llms.txt"
  "$HOME/Documents/GitHub/rapp-tower|the tower (you are here)"
)

printf "%-38s %-24s %-9s %-11s %s\n" "CHECKOUT" "BRANCH" "DIRTY" "SYNC" "ROLE"
for entry in "${REGISTRY[@]}"; do
    path="${entry%%|*}"; role="${entry##*|}"
    name="~${path#"$HOME"}"
    if [ ! -d "$path/.git" ]; then
        printf "%-38s %-24s %-9s %-11s %s\n" "$name" "—" "—" "missing" "$role"
        continue
    fi
    branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "detached")
    dirty=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [ "$dirty" = "0" ] && dirty="clean" || dirty="${dirty} files"
    sync="?"
    upstream=$(git -C "$path" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)
    if [ -n "$upstream" ]; then
        counts=$(git -C "$path" rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null || echo "? ?")
        behind="${counts%%	*}"; ahead="${counts##*	}"
        sync="+${ahead}/-${behind}"
        [ "$sync" = "+0/-0" ] && sync="synced"
    fi
    printf "%-38s %-24s %-9s %-11s %s\n" "$name" "$branch" "$dirty" "$sync" "$role"
done

# --- Grail push tripwire (FR-2): the push URL must be the neutered string.
grail_push=$(git -C "$HOME/.brainstem/src" remote get-url --push origin 2>/dev/null || echo "unreadable")
case "$grail_push" in
    DISABLED-*) echo "grail push: ${GRN}neutered${RST}" ;;
    *) echo "${RED}██ GRAIL PUSH ENABLED ██${RST} push URL is '$grail_push' — re-neuter NOW (FR-2)" ;;
esac

# --- Memory backup staleness (FR-7): no archive or >48h is red.
newest=$(ls -t "$HOME/Backups/rapp-brainstem/"brainstem-state-*.tar.gz 2>/dev/null | head -1 || true)
if [ -z "$newest" ]; then
    echo "memory backup: ${RED}NONE — sole-copy production state is unbacked (run tools/backup-memory.sh)${RST}"
else
    age_h=$(( ( $(date +%s) - $(stat -f %m "$newest") ) / 3600 ))
    if [ "$age_h" -gt 48 ]; then
        echo "memory backup: ${YEL}${age_h}h old${RST} ($(basename "$newest")) — refresh via tools/backup-memory.sh"
    else
        echo "memory backup: ${GRN}${age_h}h old${RST} ($(basename "$newest"))"
    fi
fi

# --- Holds (parallel-session protocol) — full protocol in tools/holds.sh
if [ -x "$(dirname "$0")/holds.sh" ]; then
    "$(dirname "$0")/holds.sh" list 2>/dev/null | sed 's/^/holds: /' | head -6
fi

echo ""
echo "ports (existence only — identity/auth/health: tools/triage.sh):"
echo "  $(for p in 7071 7073 7075 7076; do
    if lsof -nP -iTCP:$p -sTCP:LISTEN >/dev/null 2>&1; then printf '%s:LIVE ' "$p"; else printf '%s:- ' "$p"; fi
done) — 7071 prod · 7073 soak(+func collision, FR-6) · 7075/7076 flights (~/.rapp-flight)"
