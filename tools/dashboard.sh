#!/bin/bash
# dashboard.sh — the tower's situational view, as a self-contained local HTML.
# The tower is PRIVATE (iron law 7): its state (denylist, customer names, leak
# findings) must never serve at *.github.io. So this renders LOCALLY — a single
# file you open in a browser, no publish, no leak. Regenerate anytime; it runs
# the live tools + parses the decision queue.
#   tools/dashboard.sh          # generate + open dashboard.html
#   tools/dashboard.sh --no-open # just generate
set -uo pipefail

TOWER="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$TOWER/dashboard.html"
STAMP="$(date '+%Y-%m-%d %H:%M %Z')"

# Run a tool, strip ANSI, HTML-escape. Never fail the whole dashboard on one tool.
run() { bash "$TOWER/tools/$1" 2>&1 | sed $'s/\033\\[[0-9;]*m//g' | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' || echo "(tool $1 unavailable)"; }

CHECKOUTS="$(run checkouts.sh)"
TRIAGE="$(run triage.sh)"
TRAIN="$(run train.sh)"
FLEET="$(run fleet.sh)"
DRIFT="$(run drift.sh)"

# Decision queue: every NEEDS-KODY row from the standing-oddities ledger.
QUEUE="$(grep -h 'NEEDS-KODY' "$TOWER"/work/*/DECISIONS.md 2>/dev/null \
  | sed 's/^| *[0-9]* *| *//; s/ *| *[^|]*| *NEEDS-KODY *[—-]* */ → /; s/ *|$//' \
  | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' \
  | awk '{print "<li>" $0 "</li>"}')"
[ -z "$QUEUE" ] && QUEUE="<li>none open</li>"

cat > "$OUT" <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>🗼 RAPP Control Tower</title>
<style>
:root{--bg:#0d1117;--card:#161b22;--bd:#30363d;--fg:#e6edf3;--mut:#8b949e;--red:#f85149;--grn:#3fb950;--yel:#d29922;--acc:#58a6ff}
@media(prefers-color-scheme:light){:root{--bg:#f6f8fa;--card:#fff;--bd:#d0d7de;--fg:#1f2328;--mut:#636c76;--red:#cf222e;--grn:#1a7f37;--yel:#9a6700;--acc:#0969da}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:14px/1.5 -apple-system,Segoe UI,sans-serif}
.wrap{max-width:1200px;margin:0 auto;padding:20px}
header{display:flex;justify-content:space-between;align-items:baseline;flex-wrap:wrap;gap:8px;border-bottom:1px solid var(--bd);padding-bottom:12px;margin-bottom:16px}
h1{margin:0;font-size:22px}.mut{color:var(--mut)}.mission{font-style:italic;color:var(--mut)}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:14px}
.card{background:var(--card);border:1px solid var(--bd);border-radius:10px;padding:14px;overflow:auto}
.card.wide{grid-column:1/-1}
h2{margin:0 0 10px;font-size:14px;text-transform:uppercase;letter-spacing:.05em;color:var(--acc)}
pre{margin:0;font:12px/1.45 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre;overflow-x:auto}
ul.q{margin:0;padding-left:18px}ul.q li{margin:5px 0}
.pill{display:inline-block;padding:1px 8px;border-radius:20px;font-size:11px;border:1px solid var(--bd)}
a{color:var(--acc)}.links a{margin-right:14px;white-space:nowrap}
.foot{color:var(--mut);font-size:12px;margin-top:18px;border-top:1px solid var(--bd);padding-top:10px}
</style></head><body><div class="wrap">
<header>
  <div><h1>🗼 RAPP Control Tower</h1><div class="mission">No dream deferred — every person and every AI, working productively.</div></div>
  <div class="mut">snapshot ${STAMP}<br><span class="pill">private · local view · never published</span></div>
</header>

<div class="grid">
  <div class="card wide"><h2>⚑ Decision queue — needs Kody</h2><ul class="q">${QUEUE}</ul></div>

  <div class="card"><h2>Checkouts &amp; tripwires</h2><pre>${CHECKOUTS}</pre></div>
  <div class="card"><h2>Train position</h2><pre>${TRAIN}</pre></div>
  <div class="card wide"><h2>Service triage (identity / auth / health)</h2><pre>${TRIAGE}</pre></div>
  <div class="card"><h2>Autonomous writers</h2><pre>${FLEET}</pre></div>
  <div class="card"><h2>Drift governance</h2><pre>${DRIFT}</pre></div>

  <div class="card wide links"><h2>Views &amp; repos</h2>
    <p><b>Public (safe to share):</b>
      <a href="https://kody-w.github.io/rapp-train/">train deck</a>
      <a href="https://kody-w.github.io/rapp-train/PLAYBOOK.md">playbook</a>
      <a href="https://kody-w.github.io/rapp-roadmap/">roadmap board</a>
      <a href="https://github.com/kody-w/rapp-second-brain">second brain (canonical)</a></p>
    <p><b>Private mission control:</b>
      <a href="https://github.com/kody-w/rapp-tower">rapp-tower</a> ·
      <a href="https://github.com/kody-w/rapp-second-brain-private">brain (private)</a> —
      <span class="mut">FLIGHT_RULES.md · GO-NOGO.md · RECOVERY.md · SECURITY.md · work/</span></p>
  </div>
</div>

<div class="foot">Regenerate: <code>tools/dashboard.sh</code>. This file is gitignored — it holds private state and must never be published (iron law 7).</div>
</div></body></html>
HTML

echo "generated $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
if [ "${1:-}" != "--no-open" ]; then
  command -v open >/dev/null 2>&1 && open "$OUT" && echo "opened in browser"
fi
