#!/bin/bash
# backup-status.sh — the durability board: would today's work survive losing
# this Mac? Checks Time Machine, the Obsidian vault, ~/.claude, the brainstem
# state archive, and sweeps ~/Documents/GitHub for work that exists nowhere else.
set -uo pipefail

if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'; else RED=""; GRN=""; RST=""; fi
row() { printf "%-19s %s%-6s%s %s\n" "$1" "$2" "$3" "$RST" "$4"; }

printf "%-19s %-6s %s\n" "CHECK" "STATE" "DETAIL"

# --- Time Machine ---------------------------------------------------------
tm=$(tmutil destinationinfo 2>&1)
if echo "$tm" | grep -q "No destinations configured"; then
    row "time-machine" "$RED" "RED" "no destination — this Mac is not being backed up at all"
else
    dest=$(echo "$tm" | awk -F': ' '/^Name/{print $2; exit}')
    latest=$(tmutil latestbackup 2>/dev/null | tail -1)
    [ -n "$latest" ] && latest="last: $(basename "$latest")" || latest="last backup unknown"
    row "time-machine" "$GRN" "OK" "dest '${dest:-?}' — $latest"
fi

# --- Obsidian vault -------------------------------------------------------
VAULT="$HOME/Documents/Obsidian Vault"
if [ ! -d "$VAULT/.git" ]; then
    row "obsidian-vault" "$RED" "RED" "not a git repo — vault history exists only on this disk"
elif ! git -C "$VAULT" remote get-url origin >/dev/null 2>&1; then
    commits=$(git -C "$VAULT" rev-list --count HEAD 2>/dev/null || echo "?")
    dirty=$(git -C "$VAULT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    row "obsidian-vault" "$RED" "RED" "git repo, NO remote — $commits commits + $dirty dirty files, sole copy"
else
    unpushed=$(git -C "$VAULT" log --branches --not --remotes --oneline 2>/dev/null | wc -l | tr -d ' ')
    dirty=$(git -C "$VAULT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed" = "0" ] && [ "$dirty" = "0" ]; then
        row "obsidian-vault" "$GRN" "OK" "remote set, pushed, clean"
    else
        row "obsidian-vault" "$RED" "RED" "remote set but $unpushed unpushed commits, $dirty dirty files"
    fi
fi

# --- ~/.claude ------------------------------------------------------------
if [ -d "$HOME/.claude/.git" ]; then
    row "~/.claude" "$GRN" "OK" "versioned"
else
    nskills=$(ls -d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
    row "~/.claude" "$RED" "RED" "not a git repo — $nskills skills + settings unversioned"
fi

# --- brainstem state archive ---------------------------------------------
newest=$(ls -t "$HOME/Backups/rapp-brainstem"/brainstem-state-*.tar.gz 2>/dev/null | head -1 || true)
if [ -z "$newest" ]; then
    row "brainstem-archive" "$RED" "RED" "no archive — run tools/backup-memory.sh (memory.json is sole-copy)"
else
    age_s=$(( $(date +%s) - $(stat -f %m "$newest") ))
    age_h=$(( age_s / 3600 ))
    detail="${age_h}h old — $(basename "$newest") ($(du -h "$newest" | awk '{print $1}'))"
    if [ "$age_s" -gt 172800 ]; then
        row "brainstem-archive" "$RED" "RED" "$detail — STALE (>48h), rerun backup-memory.sh"
    else
        row "brainstem-archive" "$GRN" "OK" "$detail"
    fi
fi

# --- repo sweep: work that exists nowhere else ----------------------------
offenders=""; total=0; risky=0
for d in "$HOME/Documents/GitHub"/*/; do
    [ -d "$d/.git" ] || continue
    total=$((total + 1))
    name=$(basename "$d")
    if ! git -C "$d" remote get-url origin >/dev/null 2>&1; then
        n=$(git -C "$d" rev-list --count HEAD 2>/dev/null || echo 0)
        offenders="${offenders}${n}|${name}|no-remote (${n} commits, sole copy)
"
        risky=$((risky + 1))
    else
        n=$(git -C "$d" log --branches --not --remotes --oneline 2>/dev/null | wc -l | tr -d ' ')
        if [ "$n" -gt 0 ]; then
            offenders="${offenders}${n}|${name}|ahead +${n} unpushed commits
"
            risky=$((risky + 1))
        fi
    fi
done

echo ""
if [ "$risky" -eq 0 ]; then
    echo "repo sweep: ${GRN}all $total repos in ~/Documents/GitHub have an origin and are pushed${RST}"
else
    echo "repo sweep: ${RED}$risky of $total repos hold commits that exist only on this disk${RST} (worst first):"
    printf "%s" "$offenders" | sort -t'|' -k1,1 -rn | head -8 | \
        awk -F'|' '{printf "  %-34s %s\n", $2, $3}'
    [ "$risky" -gt 8 ] && echo "  … and $((risky - 8)) more"
fi
