#!/bin/bash
# holds.sh — the parallel-session holds protocol: advisory claims on contested
# targets (checkouts, ports, rings) so sessions stop fighting over worktrees.
# Usage: holds.sh claim <target> <intent...> | release <target> | list | check <target>
# 'check' exits 1 if another session holds the target. Holds >24h are STALE.
set -uo pipefail

TOWER="/Users/kodywildfeuer/Documents/GitHub/rapp-tower"
STATE_DIR="$TOWER/.tower"
STATE="$STATE_DIR/holds.json"
mkdir -p "$STATE_DIR"

# Session identity: stable per Claude session, else user+tty+shell-pid.
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    HOLDER="claude:$CLAUDE_SESSION_ID"
else
    if TTYNAME=$(tty 2>/dev/null); then TTYNAME="${TTYNAME#/dev/}"; else TTYNAME="notty"; fi
    HOLDER="$(id -un)@$TTYNAME:$PPID"
fi

cmd="${1:-list}"; shift || true

python3 - "$STATE" "$cmd" "$HOLDER" "$@" <<'PYEOF'
import json, os, sys, datetime as dt

state_path, cmd, holder = sys.argv[1], sys.argv[2], sys.argv[3]
args = sys.argv[4:]
tty = sys.stdout.isatty()
RED, GRN, YLW, RST = ("\033[31m","\033[32m","\033[33m","\033[0m") if tty else ("","","","")

def load():
    try:
        with open(state_path) as f: return json.load(f)
    except Exception: return {"holds": []}

def save(d):
    tmp = state_path + ".tmp"
    with open(tmp, "w") as f: json.dump(d, f, indent=2); f.write("\n")
    os.replace(tmp, state_path)

def now(): return dt.datetime.now(dt.timezone.utc)

def age_of(h):
    try:
        t = dt.datetime.fromisoformat(h["claimed_at"].replace("Z","+00:00"))
        secs = (now() - t).total_seconds()
    except Exception:
        return "?", False
    hrs = secs / 3600
    label = f"{int(hrs)}h" if hrs >= 1 else f"{int(secs//60)}m"
    return label, hrs > 24

data = load()
holds = data.get("holds", [])

if cmd == "claim":
    if not args: print("usage: holds.sh claim <target> <intent...>"); sys.exit(2)
    target, intent = args[0], " ".join(args[1:]) or "(no intent given)"
    cur = next((h for h in holds if h["target"] == target), None)
    if cur and cur["holder"] != holder:
        age, stale = age_of(cur)
        tag = f" {YLW}STALE{RST}" if stale else ""
        print(f"{RED}REFUSED{RST} {target} held by {cur['holder']} ({age} ago{tag}): {cur['intent']}")
        sys.exit(1)
    holds = [h for h in holds if h["target"] != target]
    holds.append({"target": target, "holder": holder, "intent": intent,
                  "claimed_at": now().strftime("%Y-%m-%dT%H:%M:%SZ")})
    data["holds"] = holds; save(data)
    print(f"{GRN}CLAIMED{RST} {target} by {holder}: {intent}")

elif cmd == "release":
    if not args: print("usage: holds.sh release <target>"); sys.exit(2)
    target = args[0]
    cur = next((h for h in holds if h["target"] == target), None)
    if not cur:
        print(f"no hold on {target}"); sys.exit(0)
    if cur["holder"] != holder:
        print(f"{YLW}note{RST}: releasing a hold owned by {cur['holder']} (you are {holder})")
    data["holds"] = [h for h in holds if h["target"] != target]; save(data)
    print(f"{GRN}RELEASED{RST} {target}")

elif cmd == "check":
    if not args: print("usage: holds.sh check <target>"); sys.exit(2)
    target = args[0]
    cur = next((h for h in holds if h["target"] == target), None)
    if not cur:
        print(f"{GRN}FREE{RST} {target}"); sys.exit(0)
    age, stale = age_of(cur)
    if cur["holder"] == holder:
        print(f"{GRN}YOURS{RST} {target} (claimed {age} ago): {cur['intent']}"); sys.exit(0)
    tag = f" {YLW}STALE — consider release{RST}" if stale else ""
    print(f"{RED}HELD{RST} {target} by {cur['holder']} ({age} ago{tag}): {cur['intent']}")
    sys.exit(1)

elif cmd == "list":
    if not holds:
        print("no active holds"); sys.exit(0)
    print(f"{'TARGET':<32} {'HOLDER':<28} {'AGE':<8} INTENT")
    for h in sorted(holds, key=lambda x: x.get("claimed_at","")):
        age, stale = age_of(h)
        tag = f" {RED}STALE{RST}" if stale else ""
        mine = " (you)" if h["holder"] == holder else ""
        print(f"{h['target']:<32} {(h['holder']+mine):<28} {age+tag:<8} {h['intent'][:50]}")

else:
    print("usage: holds.sh claim <target> <intent...> | release <target> | list | check <target>")
    sys.exit(2)
PYEOF
