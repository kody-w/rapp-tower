#!/bin/bash
# fleet.sh — the autonomous-writer board. Five+ scheduled writers commit/push
# with nobody watching; several fail silently. This is their single status
# surface and documented kill switch. Default is READ-ONLY status; --freeze
# prints the exact stop command for each (and with --freeze --yes, executes
# the reversible ones). Run before trusting the estate is quiet, or when an
# autonomous run may have gone wrong.
set -uo pipefail

RED=""; GRN=""; YEL=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'; fi

MODE="${1:-status}"

# Each writer: id | kind | pushes-to | kill command | note
# (pipe-delimited; bash 3.2, no associative arrays)
WRITERS=(
  "rapp-sim-loop|cron */30|PUBLIC kody-w/sim-art-collective|PUSH_CANVAS=0 in env OR comment the crontab line|RAPP/tools/sim/loop_orchestrator.sh — the only autonomous PUBLIC pusher"
  "rappterverse-npc|cron */30|local sim (openrappter)|comment the crontab line|m365-agents-for-python/openrappter"
  "openrappter-daemon|launchd com.openrappter.daemon|local|launchctl bootout gui/501/com.openrappter.daemon|persistent daemon"
  "clawdbot-heartbeat|launchd ai.clawdbot.rappterverse.heartbeat|—|launchctl bootout gui/501/ai.clawdbot.rappterverse.heartbeat|every 1800s"
  "brainstem-imessage-heartbeat|launchd com.brainstem.imessage_heartbeat|—|launchctl bootout gui/501/com.brainstem.imessage_heartbeat|liveness alarm — FAILING since ~Jul 7 (standing-oddities #2)"
  "daily-summary|launchd com.kody.daily-summary|Obsidian vault|launchctl bootout gui/501/com.kody.daily-summary|midnight"
  "sonosite-sf-refresh|launchd com.kody.sonosite.sf-refresh|Salesforce token (WORK)|launchctl bootout gui/501/com.kody.sonosite.sf-refresh|work/customer surface — every 5400s"
  "openclaw-gateway|launchd ai.openclaw.gateway|—|launchctl bootout gui/501/ai.openclaw.gateway|gateway"
  "actions-runner|launchd actions.runner.kowildfe_microsoft-RAPPtranscript2Prototype.rapp-mac-runner|— (RCE surface)|launchctl bootout gui/501/<label>|self-hosted runner for a microsoft/* repo — anyone with repo-write gets code exec on THIS laptop (see SECURITY.md)"
)

launchd_state() {
  # arg: label substring -> prints running-pid / last-exit or 'not-loaded'
  local label="$1"
  local line
  line=$(launchctl list 2>/dev/null | awk -v l="$label" '$3 ~ l {print; exit}')
  if [ -z "$line" ]; then echo "not-loaded"; return; fi
  local pid ex
  pid=$(echo "$line" | awk '{print $1}')
  ex=$(echo "$line" | awk '{print $2}')
  if [ "$pid" != "-" ]; then echo "running(pid $pid)"; else
    if [ "$ex" = "0" ]; then echo "idle(exit 0)"; else echo "FAILING(exit $ex)"; fi
  fi
}

cron_has() { crontab -l 2>/dev/null | grep -qF "$1" && echo "scheduled" || echo "absent"; }

echo "AUTONOMOUS WRITER              STATE                  TARGET"
for w in "${WRITERS[@]}"; do
  IFS='|' read -r id kind target kill note <<EOF
$w
EOF
  state="?"
  case "$kind" in
    cron*)
      case "$id" in
        rapp-sim-loop) state=$(cron_has "loop_orchestrator.sh");;
        rappterverse-npc) state=$(cron_has "rappterverse_npc_agent");;
      esac ;;
    launchd*)
      lbl="${kind#launchd }"
      state=$(launchd_state "$lbl") ;;
  esac
  color="$GRN"
  case "$state" in
    FAILING*) color="$RED";;
    not-loaded|absent) color="$YEL";;
  esac
  tcolor=""
  case "$target" in
    PUBLIC*|*RCE*|*WORK*) tcolor="$RED";;
  esac
  printf "%-29s ${color}%-22s${RST} ${tcolor}%s${RST}\n" "$id" "$state" "$target"
done

if [ "$MODE" = "--freeze" ]; then
  echo ""
  echo "${YEL}FREEZE — stop commands (reversible; re-enable by re-loading launchd / uncommenting cron):${RST}"
  for w in "${WRITERS[@]}"; do
    IFS='|' read -r id kind target kill note <<EOF
$w
EOF
    printf "  %-29s %s\n" "$id" "$kill"
  done
  echo ""
  echo "This is a documented kill list, not an auto-executor: freezing crontab/launchd"
  echo "is a system-state change — run each line deliberately and log it in work/."
  echo "The one env kill needs no privileges: export PUSH_CANVAS=0 (stops the only public pusher)."
fi

echo ""
echo "notes:"
for w in "${WRITERS[@]}"; do
  IFS='|' read -r id kind target kill note <<EOF
$w
EOF
  case "$target" in
    PUBLIC*|*RCE*|*WORK*) printf "  ${RED}!${RST} %s: %s\n" "$id" "$note";;
  esac
done
