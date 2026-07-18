# Decisions queue protocol

Kody decides open items by clicking buttons in the decision console; a Claude
session executes them. The bridge is `.tower/decisions-queue.jsonl` (gitignored).

## For Kody
1. `tools/decisions.py` (starts a local server, no deps).
2. Open **http://localhost:7788** — one card per open "needs Kody" item, my
   recommendation marked **★**. Click your choice per item. Re-click to change it.
3. Each click writes your decision to `.tower/decisions-queue.jsonl`.
4. Tell a Claude session: **"process the tower decisions queue"**.

## For the Claude session ("process the tower decisions queue")
1. Read `.tower/decisions-queue.jsonl` — one JSON object per line:
   `{id, title, label, action, ts, status}`.
2. For each `status:"queued"` item, **execute its `action`** (that string is the
   instruction). Respect the iron laws: anything touching the grail rides the
   train; nothing public ships without passing `tools/guard.sh`; draft
   legal/trademark changes into `work/` for Kody rather than force them.
3. On completion, set that line's `status` to `"done"` (rewrite the file) and
   report what was done. If an item needs Kody's own hands (e.g. `sf org login
   web`, revoking a Google key), mark `status:"needs-kody"` and say so.
4. Never act on an item that isn't in the queue — the queue IS the authorization.
