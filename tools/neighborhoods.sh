#!/bin/bash
# neighborhoods.sh — the tower display that spans FOREIGN hosts, not just RAPP.
#
# Every other tower tool watches the RAPP estate: rings, grail, Pages, drift.
# This one watches the hosts RAPP is colonising — openrappter, openclaw, Claude
# Code, and anything else that holds capabilities in its own native format.
#
# The model (canon: rapp-neighborhood-protocol §3, "uniform peers"): a host is
# reachable through ONE narrow membrane, and every peer looks the same on the
# wire. A brainstem colonises a host the way a mitochondrion colonises a cell —
# it does not rewrite the host, it trades across that membrane. So the two
# questions worth displaying per neighborhood are:
#
#   CAN WE REACH IT?   is there a membrane, and does it answer
#   CAN WE TRADE?      are its capabilities in a shape we can carry across
#
# The second is the toaster's question. A capability with no capsule is RAW
# BREAD: it can be converted, but only by SYNTHESIS -- a re-render, not a
# recovery -- so it is not yet loop-safe. Counting bread vs toast per host is
# the honest measure of how far the absorption has actually got.
#
# Read-only. Never prints a token. Never touches a port it did not open.
set -uo pipefail

TOWER="$(cd "$(dirname "$0")/.." && pwd)"
TOASTER="${RAPP_TOASTER:-$TOWER/tools/agentshim.py}"
RED=""; GRN=""; YEL=""; DIM=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'; fi

RAW=0   # --raw-only: list every un-toasted capability path and exit

for a in "$@"; do
  case "$a" in
    --raw-only) RAW=1 ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
  esac
done

# host | label | membrane probe (empty = no endpoint) | capability globs
NEIGHBORHOODS=(
  "$HOME/.brainstem|RAPP native|http://localhost:7071/health|$HOME/.brainstem/src/rapp_brainstem/agents/*_agent.py"
  "$HOME/.openrappter|openrappter||$HOME/.openrappter/brainstem/agents/*_agent.py $HOME/.openrappter/typescript/skills/*/SKILL.md"
  "$HOME/.openclaw|openclaw||$HOME/.openclaw/agents/*/SKILL.md $HOME/.openclaw/agents/*/agent.md"
  "$HOME/.claude|claude code||$HOME/.claude/skills/*/SKILL.md"
)

probe() { # never follows redirects to a shell, never prints bodies
  curl -fsS -m 3 -o /dev/null -w '%{http_code}' "$1" 2>/dev/null || echo "000"
}

is_toast() { grep -qa "rci-capsule:v1:" "$1" 2>/dev/null; }

if [ "$RAW" -eq 0 ]; then
  printf "%-14s %-9s %-11s %-22s %s\n" "NEIGHBORHOOD" "PRESENT" "MEMBRANE" "CAPABILITIES" "TRADABLE"
fi

tot_bread=0; tot_toast=0
for entry in "${NEIGHBORHOODS[@]}"; do
  IFS='|' read -r root label probe_url globs <<< "$entry"
  [ -d "$root" ] || { [ "$RAW" -eq 0 ] && printf "%-14s ${DIM}%-9s %-11s %-22s %s${RST}\n" "$label" "no" "-" "-" "-"; continue; }

  # membrane: an endpoint that ANSWERS is the only thing that counts. A config
  # file claiming a gateway is not a membrane; port-open is not healthy either.
  if [ -n "$probe_url" ]; then
    code=$(probe "$probe_url")
    case "$code" in
      200) membrane="${GRN}open${RST}" ;;
      000) membrane="${RED}closed${RST}" ;;
      *)   membrane="${YEL}http $code${RST}" ;;
    esac
  else
    membrane="${DIM}none${RST}"      # no chat-shaped endpoint => cannot be a peer yet
  fi

  bread=0; toast=0; files=""
  for g in $globs; do
    for f in $g; do
      [ -f "$f" ] || continue
      if is_toast "$f"; then toast=$((toast+1)); else bread=$((bread+1)); files="$files$f"$'\n'; fi
    done
  done
  n=$((bread+toast))
  tot_bread=$((tot_bread+bread)); tot_toast=$((tot_toast+toast))

  if [ "$RAW" -eq 1 ]; then
    [ "$bread" -gt 0 ] && printf '%s' "$files"
    continue
  fi

  if [ "$n" -eq 0 ] && [ -d "$root/agents" ]; then
    # openclaw holds agents as runtime STATE (models.json, auth-profiles.json,
    # sessions/*.jsonl) rather than as portable capability files. That is not a
    # missing glob -- there is nothing droppable to carry. Colonising a host
    # like this cannot be done by dropping a file; it needs the adapter.
    tradable="${DIM}state only — no portable artifacts${RST}"
  elif [ "$n" -eq 0 ]; then tradable="${DIM}-${RST}"
  elif [ "$bread" -eq 0 ]; then tradable="${GRN}all $n toast${RST}"
  else tradable="${YEL}$bread raw${RST} / $toast toast"; fi
  printf "%-14s %-9s %-11s %-22s %s\n" "$label" "yes" "$membrane" "$n" "$tradable"
done

[ "$RAW" -eq 1 ] && exit 0

echo
echo "capabilities: $((tot_bread+tot_toast)) across the estate — ${tot_toast} toast, ${tot_bread} raw bread"
if [ "$tot_bread" -gt 0 ]; then
  echo "  raw bread cannot round-trip: conversion SYNTHESISES rather than recovers."
  echo "  make it tradable:  $TOASTER toast \$(bash $0 --raw-only | tr '\\n' ' ')"
fi
echo
echo "${DIM}membrane 'none' = no chat-shaped endpoint, so the host cannot present as a"
echo "uniform peer yet (rapp-neighborhood-protocol §3). That is the twin-chat"
echo "adapter's job, and it is NOT built — do not read 'none' as 'broken'.${RST}"
