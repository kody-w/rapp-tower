#!/bin/bash
# dashboard.sh — the tower's situational view as a TV-glanceable status board.
# One screen of big traffic-light tiles you can read across the room, plus the
# top-priority strip and (below the fold) the raw tool output. The tower is
# PRIVATE (iron law 7) so this renders LOCALLY — never *.github.io.
#   tools/dashboard.sh              generate + open
#   tools/dashboard.sh --no-open    just generate
#   tools/dashboard.sh --watch [N]  regenerate every N sec (default 60) — leave
#                                    running for a live TV board (page auto-reloads)
set -uo pipefail

TOWER="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$TOWER/dashboard.html"
REFRESH=60

run(){ bash "$TOWER/tools/$1" 2>&1 | sed $'s/\033\\[[0-9;]*m//g'; }
esc(){ sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

generate(){
  local STAMP; STAMP="$(date '+%a %H:%M %Z')"
  local CHECKOUTS TRIAGE TRAIN FLEET DRIFT
  CHECKOUTS="$(run checkouts.sh)"; TRIAGE="$(run triage.sh)"; TRAIN="$(run train.sh)"
  FLEET="$(run fleet.sh)"; DRIFT="$(run drift.sh)"

  # ---- derive traffic-light signals from the live output ----
  local s_prod c_prod s_push c_push s_bkp c_bkp s_train c_train s_writ c_writ s_drift c_drift s_leak c_leak n_dec

  echo "$TRIAGE" | grep -q 'serving: YES' && { s_prod="UP"; c_prod="g"; } || { s_prod="DOWN"; c_prod="r"; }

  if echo "$CHECKOUTS" | grep -q 'GRAIL PUSH ENABLED'; then s_push="OPEN"; c_push="r"; else s_push="SAFE"; c_push="g"; fi

  local bkp; bkp="$(echo "$CHECKOUTS" | grep -oE 'memory backup: [0-9]+h' | grep -oE '[0-9]+' | head -1)"
  if [ -z "$bkp" ]; then s_bkp="NONE"; c_bkp="r"; elif [ "$bkp" -gt 48 ]; then s_bkp="${bkp}h"; c_bkp="y"; else s_bkp="${bkp}h"; c_bkp="g"; fi

  if echo "$TRAIN" | grep -q 'in step'; then s_train="IN STEP"; c_train="g"; else s_train="CHECK"; c_train="y"; fi

  n_writ="$(echo "$FLEET" | grep -c 'FAILING' || true)"; n_writ="${n_writ:-0}"
  if [ "$n_writ" -eq 0 ]; then s_writ="ALL OK"; c_writ="g"; else s_writ="${n_writ} FAILING"; c_writ="y"; fi

  if echo "$DRIFT" | grep -q 'STALE'; then s_drift="STALE"; c_drift="y"; else s_drift="OK"; c_drift="g"; fi

  # leak: an unresolved LIVE-LEAK row (still NEEDS-KODY) in the decision ledger
  if grep -hi 'LIVE LEAK' "$TOWER"/work/*/DECISIONS.md 2>/dev/null | grep -q 'NEEDS-KODY'; then s_leak="OPEN"; c_leak="r"; else s_leak="CLEAR"; c_leak="g"; fi

  n_dec="$(grep -hcE '^\| .*NEEDS-KODY' "$TOWER"/work/*/DECISIONS.md 2>/dev/null | paste -sd+ - | bc 2>/dev/null || echo 0)"
  n_dec="${n_dec:-0}"

  # top-3 priority lines (the reds first): leak, runner, unauth flight
  local TOP
  TOP="$(grep -hE '^\| .*NEEDS-KODY' "$TOWER"/work/*/DECISIONS.md 2>/dev/null \
    | grep -iE 'LEAK|RCE|runner|unauthenticated' \
    | sed 's/^| *[0-9]* *| *//; s/ *|.*$//; s/\*\*//g; s/`//g' | esc | head -3 | awk '{print "<li>"$0"</li>"}')"
  [ -z "$TOP" ] && TOP="<li>no red-flag items</li>"

  local CO_E TR_E TRN_E FL_E DR_E
  CO_E="$(echo "$CHECKOUTS" | esc)"; TR_E="$(echo "$TRIAGE" | esc)"; TRN_E="$(echo "$TRAIN" | esc)"
  FL_E="$(echo "$FLEET" | esc)"; DR_E="$(echo "$DRIFT" | esc)"

  cat > "$OUT" <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="${REFRESH}">
<title>🗼 RAPP Control Tower</title>
<style>
:root{--bg:#0a0e14;--card:#121821;--bd:#26303d;--fg:#e6edf3;--mut:#8b949e;
--r:#f85149;--rb:#3d1518;--g:#3fb950;--gb:#0f2417;--y:#d29922;--yb:#2b2410;--acc:#58a6ff}
*{box-sizing:border-box;margin:0;padding:0}
html,body{height:100%}
body{background:var(--bg);color:var(--fg);font:16px/1.4 -apple-system,Segoe UI,sans-serif;padding:clamp(10px,1.6vw,26px);display:flex;flex-direction:column;gap:clamp(8px,1.2vh,18px)}
.top{display:flex;justify-content:space-between;align-items:baseline;flex-wrap:wrap;gap:8px}
h1{font-size:clamp(20px,2.6vw,40px)}
.sub{color:var(--mut);font-style:italic;font-size:clamp(11px,1.1vw,17px)}
.stamp{text-align:right;color:var(--mut);font-size:clamp(12px,1.2vw,20px)}
.pill{display:inline-block;padding:2px 10px;border-radius:20px;border:1px solid var(--bd);font-size:clamp(9px,.8vw,13px)}
.tiles{flex:0 0 auto;display:grid;grid-template-columns:repeat(4,1fr);gap:clamp(8px,1vw,18px)}
.tile{border-radius:14px;border:1px solid var(--bd);padding:clamp(10px,1.4vw,22px);display:flex;flex-direction:column;justify-content:space-between;min-height:clamp(90px,13vh,150px)}
.tile .lbl{font-size:clamp(10px,1vw,16px);letter-spacing:.08em;text-transform:uppercase;color:var(--mut)}
.tile .val{font-size:clamp(22px,3.2vw,52px);font-weight:800;line-height:1}
.g{background:var(--gb);border-color:#1f5c33}.g .val{color:var(--g)}
.y{background:var(--yb);border-color:#6b5410}.y .val{color:var(--y)}
.r{background:var(--rb);border-color:#8a2a26}.r .val{color:var(--r)}
.focus{flex:0 0 auto;background:var(--rb);border:1px solid #8a2a26;border-radius:14px;padding:clamp(10px,1.4vw,22px)}
.focus h2{color:var(--r);font-size:clamp(12px,1.2vw,19px);letter-spacing:.06em;text-transform:uppercase;margin-bottom:6px}
.focus ul{list-style:none;display:flex;flex-direction:column;gap:6px}
.focus li{font-size:clamp(14px,1.5vw,24px);font-weight:600;padding-left:20px;position:relative}
.focus li:before{content:"▲";position:absolute;left:0;color:var(--r);font-size:.7em;top:.25em}
.detail{flex:1 1 auto;display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:clamp(8px,1vw,16px);overflow:auto;min-height:0}
.detail .card{background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:12px;overflow:auto}
.detail h3{color:var(--acc);font-size:12px;letter-spacing:.05em;text-transform:uppercase;margin-bottom:8px}
pre{font:11px/1.4 ui-monospace,Menlo,monospace;white-space:pre;overflow-x:auto}
</style></head><body>
<div class="top">
  <div><h1>🗼 RAPP Control Tower</h1><div class="sub">No dream deferred — every person and every AI, working productively.</div></div>
  <div class="stamp">${STAMP}<br><span class="pill">private · local · auto-refresh ${REFRESH}s</span></div>
</div>

<div class="tiles">
  <div class="tile ${c_prod}"><div class="lbl">Prod :7071</div><div class="val">${s_prod}</div></div>
  <div class="tile ${c_train}"><div class="lbl">Train</div><div class="val">${s_train}</div></div>
  <div class="tile ${c_bkp}"><div class="lbl">Memory backup</div><div class="val">${s_bkp}</div></div>
  <div class="tile ${c_push}"><div class="lbl">Grail push</div><div class="val">${s_push}</div></div>
  <div class="tile ${c_writ}"><div class="lbl">Autonomous writers</div><div class="val">${s_writ}</div></div>
  <div class="tile ${c_drift}"><div class="lbl">Drift baselines</div><div class="val">${s_drift}</div></div>
  <div class="tile ${c_leak}"><div class="lbl">Secret leak</div><div class="val">${s_leak}</div></div>
  <div class="tile ${c_leak}"><div class="lbl">Needs Kody</div><div class="val">${n_dec}</div></div>
</div>

<div class="focus"><h2>▲ Top priority — act now</h2><ul>${TOP}</ul>
<div style="margin-top:10px;font-size:clamp(12px,1.1vw,16px);color:var(--fg)">🗳️ Decide all ${n_dec} open items with buttons: run <code style="background:rgba(127,127,127,.2);padding:1px 6px;border-radius:5px">tools/decisions.py</code> → <b>localhost:7788</b></div></div>

<div class="detail">
  <div class="card"><h3>Checkouts &amp; tripwires</h3><pre>${CO_E}</pre></div>
  <div class="card"><h3>Train position</h3><pre>${TRN_E}</pre></div>
  <div class="card"><h3>Autonomous writers</h3><pre>${FL_E}</pre></div>
  <div class="card"><h3>Service triage</h3><pre>${TR_E}</pre></div>
  <div class="card"><h3>Drift governance</h3><pre>${DR_E}</pre></div>
</div>
</body></html>
HTML
  echo "generated $OUT — prod:$s_prod train:$s_train backup:$s_bkp push:$s_push writers:$s_writ drift:$s_drift leak:$s_leak needs-kody:$n_dec"
}

case "${1:-}" in
  --watch)
    N="${2:-60}"; REFRESH="$N"
    echo "watch mode: regenerating every ${N}s (Ctrl-C to stop). Put the browser tab fullscreen on the TV."
    generate; command -v open >/dev/null && open "$OUT"
    while true; do sleep "$N"; generate >/dev/null 2>&1 || true; done ;;
  --no-open) generate ;;
  *) generate; command -v open >/dev/null 2>&1 && open "$OUT" && echo "opened" ;;
esac
