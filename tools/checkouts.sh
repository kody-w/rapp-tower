#!/bin/bash
# checkouts.sh — one-screen truth about every registered local checkout:
# branch, dirtiness, ahead/behind origin, so a session knows what it may
# touch before it touches anything.
set -uo pipefail

REGISTRY=(
  "$HOME/.brainstem/src|GRAIL (read-only, push-disabled)"
  "$HOME/Documents/GitHub/rapp-canary|ring: canary (contested — scratch-clone for work)"
  "$HOME/Documents/GitHub/rapp-nightly|ring: nightly (promotion target)"
  "$HOME/Documents/GitHub/rapp-alpha|ring: alpha (promotion target)"
  "$HOME/Documents/GitHub/rapp-beta|ring: beta (promotion target)"
  "$HOME/Documents/GitHub/RAPP|distro (WIP-prone — scratch-clone for work)"
  "$HOME/Documents/GitHub/RAR|registry (THE active checkout)"
  "$HOME/Documents/GitHub/aibast-agents-library|aibast fork (manual PRs only)"
  "$HOME/Documents/GitHub/rapp-train|deck/playbook"
  "$HOME/Documents/GitHub/rapp-tower|the tower (you are here)"
)

printf "%-38s %-24s %-8s %-11s %s\n" "CHECKOUT" "BRANCH" "DIRTY" "SYNC" "ROLE"
for entry in "${REGISTRY[@]}"; do
    path="${entry%%|*}"; role="${entry##*|}"
    name="~${path#"$HOME"}"
    if [ ! -d "$path/.git" ]; then
        printf "%-38s %-24s %-8s %-11s %s\n" "$name" "—" "—" "missing" "$role"
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
    printf "%-38s %-24s %-8s %-11s %s\n" "$name" "$branch" "$dirty" "$sync" "$role"
done

echo ""
echo "ports: $(for p in 7071 7073 7075 7076; do
    if lsof -nP -iTCP:$p -sTCP:LISTEN >/dev/null 2>&1; then printf '%s:LIVE ' "$p"; else printf '%s:- ' "$p"; fi
done)"
