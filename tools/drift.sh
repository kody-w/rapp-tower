#!/bin/bash
# drift.sh — the drift-governance surface: are the rapp-map oracles green, is
# anyone holding the ball on open drift issues, which waivers are near expiry,
# and are the estate baselines (estate-map/neurons/graph) stale vs the spec?
# Run weekly, or before trusting any estate-wide reasoning.
set -uo pipefail

RED=""; GRN=""; YLW=""; RST=""
if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RST=$'\033[0m'; fi

MAP="$HOME/Documents/GitHub/rapp-map"
REPO="kody-w/rapp-map"
NOW_EPOCH=$(date +%s)

echo "== drift governance — $REPO =="

# ---- Oracles: latest run per guard workflow -------------------------------
printf "%-22s %-11s %s\n" "ORACLE" "CONCLUSION" "LAST RUN"
for wf in standing-guard.yml drift-lint.yml; do
    line=$(gh api "repos/$REPO/actions/workflows/$wf/runs?per_page=1" \
        --jq '.workflow_runs[0] | (.conclusion // .status) + "|" + .updated_at' 2>/dev/null)
    if [ -z "$line" ]; then
        printf "%-22s %s%-11s%s %s\n" "$wf" "$YLW" "unknown" "$RST" "gh api failed"
        continue
    fi
    concl="${line%%|*}"; when="${line##*|}"
    when_epoch=$(python3 -c "import datetime as d,sys;print(int(d.datetime.strptime(sys.argv[1],'%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=d.timezone.utc).timestamp()))" "$when" 2>/dev/null || echo "$NOW_EPOCH")
    age_h=$(( (NOW_EPOCH - when_epoch) / 3600 ))
    if [ "$age_h" -ge 48 ]; then age="$(( age_h / 24 ))d ago"; else age="${age_h}h ago"; fi
    col="$RED"; [ "$concl" = "success" ] && col="$GRN"
    flag=""; [ "$age_h" -gt 192 ] && flag=" ${RED}(oracle silent >8d)${RST}"
    printf "%-22s %s%-11s%s %s%s\n" "$wf" "$col" "$concl" "$RST" "$age" "$flag"
done

# ---- Open drift issues ----------------------------------------------------
issues=$(gh api "repos/$REPO/issues?state=open&per_page=100" --jq \
    '[.[] | select((.pull_request|not) and (([.labels[].name] | index("drift")) or (.title | test("drift";"i")))) | "#\(.number) \(.title)"] | .[]' 2>/dev/null)
if [ -n "$issues" ]; then
    n=$(printf '%s\n' "$issues" | wc -l | tr -d ' ')
    echo "open drift issues: ${YLW}${n}${RST}"
    printf '%s\n' "$issues" | sed 's/^/  /' | cut -c1-100
else
    echo "open drift issues: ${GRN}0${RST}"
fi

# ---- Waivers + baselines (local checkout) ---------------------------------
if [ ! -d "$MAP" ]; then
    echo "${RED}local checkout missing: $MAP — waiver/baseline checks skipped${RST}"
    exit 1
fi
SPEC_DATE=$(git -C "$MAP" log -1 --format=%ci -- ecosystem-spec.json 2>/dev/null | cut -d' ' -f1)

python3 - "$MAP" "${SPEC_DATE:-}" <<'PYEOF'
import json, os, sys, datetime as dt

mapdir, spec_date = sys.argv[1], sys.argv[2]
tty = sys.stdout.isatty()
RED, GRN, YLW, RST = ("\033[31m","\033[32m","\033[33m","\033[0m") if tty else ("","","","")
today = dt.date.today()

def load(name):
    try:
        with open(os.path.join(mapdir, name)) as f: return json.load(f)
    except Exception: return None

# Waivers
w = load("conformance/waivers.json") or {}
print(f"{'WAIVER':<14} {'EXPIRES':<12} DAYS LEFT")
for wv in w.get("waivers", []):
    exp = wv.get("expires")
    if not exp:
        print(f"{wv['id']:<14} {'(none)':<12} {YLW}no expiry{RST}"); continue
    days = (dt.date.fromisoformat(exp) - today).days
    col = RED if days < 30 else GRN
    tag = " EXPIRED" if days < 0 else ""
    print(f"{wv['id']:<14} {exp:<12} {col}{days}d{tag}{RST}")

# Baselines vs spec
em, nu, gr = load("estate-map.json"), load("neurons.json"), load("graph.json")
print(f"{'BASELINE':<18} {'BUILT':<12} {'SPEC':<12} VERDICT")
def row(name, built_iso):
    built = built_iso[:10] if built_iso else "?"
    if not built_iso or not spec_date:
        print(f"{name:<18} {built:<12} {spec_date or '?':<12} {YLW}unknown{RST}"); return
    lag = (dt.date.fromisoformat(spec_date) - dt.date.fromisoformat(built)).days
    if lag > 7: print(f"{name:<18} {built:<12} {spec_date:<12} {RED}STALE (spec is {lag}d newer){RST}")
    else:       print(f"{name:<18} {built:<12} {spec_date:<12} {GRN}fresh{RST}")
row("estate-map.json", (em or {}).get("built_at"))
row("neurons.json",   (nu or {}).get("built_at"))
row("graph.json",     (gr or {}).get("generated"))

# Repo-count agreement
ec = (em or {}).get("count"); nc = len((nu or {}).get("repos", []))
if ec == nc: print(f"repo count: estate-map {ec} == neurons {nc} {GRN}agree{RST}")
else:        print(f"repo count: estate-map {ec} vs neurons {nc} {RED}MISMATCH ({(nc or 0)-(ec or 0):+d}){RST}")
PYEOF
