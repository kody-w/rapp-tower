#!/bin/bash
# triage.sh — service-telemetry board: identity + health (not just LISTEN) for
# every port 7070-7090, the flight roster, and a :7071 brainstem doctor.
# Run before touching any live service or assuming a port is yours.
set -uo pipefail

RED=""; GRN=""; DIM=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; DIM=$'\033[2m'; RST=$'\033[0m'; fi

shorten() { # keep tail of long paths, $HOME -> ~
    local p="${1/#$HOME/~}"
    if [ ${#p} -gt 34 ]; then p="…${p:$((${#p}-33))}"; fi
    printf '%s' "$p"
}

health_line() { # $1=port -> "summary|FLAG1 FLAG2" (empty if no JSON health)
    local resp; resp=$(curl -sm 2 "http://127.0.0.1:$1/health" 2>/dev/null) || true
    HJ="$resp" python3 - <<'PY' 2>/dev/null
import json, os
try:
    d = json.loads(os.environ.get("HJ", ""))
except Exception:
    raise SystemExit(0)
ver = str(d.get("version", "?"))
ver = ("v" + ver) if ver[:1].isdigit() else ver
model = d.get("model") or ",".join(d.get("engines", [])) or "?"
status = d.get("status", "?")
auth = d.get("copilot") or d.get("auth") or status
n = len(d.get("agents", d.get("engines", [])))
flags = []
if status == "unauthenticated" or str(auth).lower() == "disabled":
    flags.append("UNAUTH")
if d.get("model") == "gpt-4o":
    flags.append("FALLBACK-MODEL")
print(f"{ver} {model} auth={auth} agents={n}|{' '.join(flags)}")
PY
}

# ---- PORTS 7070-7090 --------------------------------------------------------
LISTENERS=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
    | awk 'NR>1 {n=split($9,a,":"); p=a[n]+0; if (p>=7070 && p<=7090) print p, $2, $9}' \
    | sort -un -k1,1 -k2,2)

printf "%-5s %-9s %-6s %-11s %-24s %-34s %s\n" "PORT" "REG" "PID" "START" "PROC" "CWD" "HEALTH"
echo "$LISTENERS" | awk '{print $1}' | sort -un | while read -r port; do
    [ -z "$port" ] && continue
    pids=$(echo "$LISTENERS" | awk -v p="$port" '$1==p {print $2}' | sort -un)
    npids=$(echo "$pids" | wc -l | tr -d ' ')
    flagred=0
    case "$port" in
        7071) rtxt="prod" ;;
        7073) rtxt="soak" ;;
        7075|7076) rtxt="flight" ;;
        *) rtxt="UNREG"; flagred=1 ;;
    esac
    if [ "$npids" -gt 1 ]; then rtxt="$rtxt x${npids}!"; flagred=1; fi
    role=$(printf '%-9s' "$rtxt")
    [ "$flagred" = 1 ] && role="${RED}${role}${RST}"
    hp=$(health_line "$port"); hsum="${hp%%|*}"; hflags="${hp#*|}"
    [ -z "$hp" ] && hsum="${DIM}no /health${RST}"
    [ -n "$hflags" ] && [ "$hflags" != "$hp" ] && hsum="$hsum ${RED}${hflags}${RST}"
    first=1
    for pid in $pids; do
        proc=$(ps -o command= -p "$pid" 2>/dev/null | awk '{n=split($1,a,"/"); o=a[n]; for(i=2;i<=NF&&i<=3;i++){m=split($i,b,"/"); o=o" "b[m]} print substr(o,1,24)}')
        start=$(ps -o lstart= -p "$pid" 2>/dev/null | awk '{print $2 $3, substr($4,1,5)}')
        cwd=$(shorten "$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')")
        bind=$(echo "$LISTENERS" | awk -v p="$port" -v i="$pid" '$1==p && $2==i {print $3; exit}')
        note="$hsum"
        if [ "$npids" -gt 1 ]; then
            case "$bind" in 127.0.0.1:*) note="$hsum ${DIM}(loopback wins)${RST}" ;; *) note="${DIM}shadowed on loopback${RST}" ;; esac
        fi
        if [ "$first" = 1 ]; then
            printf "%-5s %b %-6s %-11s %-24s %-34s %b\n" "$port" "$role" "$pid" "$start" "$proc" "$cwd" "$note"
            first=0
        else
            printf "%-5s %-9s %-6s %-11s %-24s %-34s %b\n" "" "" "$pid" "$start" "$proc" "$cwd" "$note"
        fi
    done
done

# ---- FLIGHTS ----------------------------------------------------------------
echo ""
printf "%-33s %-7s %-6s %-9s %s\n" "FLIGHT (~/.rapp-flight)" "PID" "ALIVE" "COMMIT" "PORT"
for d in "$HOME"/.rapp-flight/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    pid=$(cat "$d/flight.pid" 2>/dev/null | tr -d '[:space:]')
    alive="${RED}dead${RST}"; port="-"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        alive="${GRN}live${RST}"
        port=$(lsof -nP -a -p "$pid" -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {n=split($9,a,":"); print a[n]; exit}')
        [ -z "$port" ] && port="?"
    fi
    commit=$(RJ="$d/render.json" python3 -c 'import json,os; print(json.load(open(os.environ["RJ"])).get("source_commit","?")[:7])' 2>/dev/null || echo "?")
    printf "%-33s %-7s %b   %-9s %s\n" "$name" "${pid:--}" "$alive" "$commit" "$port"
done

# ---- BRAINSTEM DOCTOR :7071 -------------------------------------------------
echo ""
echo "BRAINSTEM DOCTOR :7071"
h=$(health_line 7071); hsum="${h%%|*}"
if [ -n "$h" ]; then
    bpid=$(echo "$LISTENERS" | awk '$1==7071 {print $2; exit}')
    bstart=$(ps -o lstart= -p "$bpid" 2>/dev/null | awk '{print $2 $3, substr($4,1,5)}')
    echo "  serving: ${GRN}YES${RST}  $hsum  (pid $bpid, since $bstart)"
else
    echo "  serving: ${RED}NO — :7071 not answering /health${RST}"
fi
if launchctl list com.brainstem.server >/dev/null 2>&1; then
    echo "  launchd: com.brainstem.server LOADED (supervised)"
else
    pl="not found"; [ -f "$HOME/Library/LaunchAgents/com.brainstem.server.plist" ] && pl="plist exists but"
    dis=""; launchctl print-disabled "gui/$(id -u)" 2>/dev/null | grep -q '"com.brainstem.server" => disabled' && dis=", disabled in launchd"
    echo "  launchd: NOT LOADED ($pl not loaded$dis) -> manual orphan launch"
fi
echo "  restart: ~/.local/bin/brainstem   (NEVER rm/re-clone ~/.brainstem — memory lives inside)"
