#!/usr/bin/env python3
"""decisions.py — the tower's interactive decision console.

Serves a local web page of every open "needs Kody" item as recommendation-first
BUTTON cards. Clicking a button writes the choice to .tower/decisions-queue.jsonl
(one line per item, latest wins). A Claude session then runs:

    "process the tower decisions queue"

...reads that file, executes the chosen action per item, and marks it done.

Local only, no deps (Python stdlib). The tower is PRIVATE — this never publishes.
Run:  tools/decisions.py   then open  http://localhost:7788
"""
import json, os, datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

TOWER = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUEUE = os.path.join(TOWER, ".tower", "decisions-queue.jsonl")
os.makedirs(os.path.dirname(QUEUE), exist_ok=True)
PORT = int(os.environ.get("DECISIONS_PORT", "7788"))

# Each item: id, title, context, options[{label, rec?, action}]
# `action` is the instruction a Claude session executes when this choice is queued.
ITEMS = [
  {"id":"google-keys","title":"3 public Google API-key leaks (files already wiped)","ctx":"mars-barn-opus, gemini-cli-tips, TheMatrix — leaked files purged/redacted from history by Fable; keys still need revocation in Google Cloud Console.","opts":[
    {"label":"I revoked all 3 — close the alerts","rec":True,"action":"Close the open secret-scanning alerts on kody-w/mars-barn-opus, gemini-cli-tips, TheMatrix with resolution=revoked."},
    {"label":"Not yet — remind me later","action":"Leave the 3 Google-key alerts open; add a reminder to revoke them in Google Cloud Console."}]},
  {"id":"runner","title":"Self-hosted Actions runner = RCE on this laptop","ctx":"A runner for microsoft/RAPPtranscript2Prototype runs on the root-of-trust laptop; anyone with write to that repo gets code execution here.","opts":[
    {"label":"Decommission it","rec":True,"action":"Unregister/remove the self-hosted GitHub Actions runner (actions.runner.kowildfe_microsoft-RAPPtranscript2Prototype) from this laptop and bootout its launchd agent."},
    {"label":"Relocate it off this machine","action":"Document a plan to move the self-hosted runner to a non-root-of-trust machine; disable it here meanwhile."},
    {"label":"Keep it (accept the risk)","action":"Record in standing-oddities that the self-hosted runner stays on this machine as an accepted risk."}]},
  {"id":"trademark","title":"Contradictory trademark docs","ctx":"rapp-train/TRADEMARKS.md (Wildhaven Homes LLC; 'RAPP'/brainstem deliberately free) vs RAPP/TRADEMARK.md ((c) Kody personally; both claimed). Public contradiction can void the marks.","opts":[
    {"label":"Wildhaven Homes LLC owns all","rec":True,"action":"Reconcile the trademark docs to Wildhaven Homes LLC as sole owner (make RAPP/TRADEMARK.md defer to rapp-train/TRADEMARKS.md); record the assignment. Draft the change in work/2026-07-18-legal-posture/ for review — do not push public repos without Kody's ok."},
    {"label":"Kody (personal) owns all","action":"Reconcile the trademark docs to Kody Wildfeuer personal ownership; update TRADEMARKS.md to match. Draft in work/ for review."},
    {"label":"Decide later","action":"Leave the trademark contradiction open; keep in the queue."}]},
  {"id":"grail-license","title":"Grail + rings are unlicensed (all-rights-reserved)","ctx":"kody-w/rapp-installer + the four ring repos have no LICENSE — users have no legal right to run the installer. Adding one rides the train.","opts":[
    {"label":"Apache-2.0 (matches the brand layer)","rec":True,"action":"Draft adding Apache-2.0 LICENSE to grail + rings via the train (branch on canary, ride to grail). Prepare the branch; do NOT merge to grail (human-only)."},
    {"label":"MIT (matches RAR/rapp-map)","action":"Draft adding MIT LICENSE to grail + rings via the train. Prepare the canary branch; do not merge to grail."},
    {"label":"PolyForm SB (matches RAPP core)","action":"Draft adding PolyForm Small Business 1.0.0 LICENSE to grail + rings via the train. Prepare the canary branch; do not merge to grail."},
    {"label":"Decide later","action":"Leave the grail licensing decision open."}]},
  {"id":"push-allowlist","title":"push-allowlist bare prefix defeats the guard","ctx":"~/.claude/hooks/push-allowlist.txt line 4 (bare github.com/kody-w/) re-authorizes every kody-w repo. Tightening wrong could block a live autonomous wave.","opts":[
    {"label":"Tighten it (derive list, I'll confirm)","rec":True,"action":"Derive the set of repos autonomous sessions legitimately push to (from recent push activity + known writers), propose a tightened push-allowlist.txt replacing the bare prefix, and show it for Kody's confirmation before applying."},
    {"label":"Leave as-is (accept broad allow)","action":"Record accepting the broad push-allowlist as intentional."}]},
  {"id":"sonosite","title":"Sonosite SF token refresh failing (work cred)","ctx":"com.kody.sonosite.sf-refresh fails since 07-07; needs `sf org login web` (Kody's Salesforce credential).","opts":[
    {"label":"I'll re-auth it (sf org login web)","rec":True,"action":"Mark the sonosite SF re-auth as Kody-handled; verify the agent succeeds on next run."},
    {"label":"Retire the agent (don't need it)","action":"Retire com.kody.sonosite.sf-refresh to ~/.tower-retired-launchagents (reversible), like the other dead agents."}]},
  {"id":"drift","title":"rapp-map baselines stale vs spec","ctx":"estate-map/neurons 16d behind spec, graph 34d; 92-vs-99 repo-count mismatch. The drift oracle certifies green over a stale map.","opts":[
    {"label":"Run ecosystem-sync regeneration","rec":True,"action":"Invoke the ecosystem-sync skill to regenerate estate-map.json / neurons.json / graph.json to the current spec, and adjudicate the 92-vs-99 repo-count mismatch once."},
    {"label":"Defer","action":"Leave the rapp-map baseline staleness open."}]},
  {"id":"prod-supervisor","title":"Prod :7071 is a manual orphan (no supervisor)","ctx":"com.brainstem.server plist exists but is disabled/not-loaded; nothing restarts :7071 after a reboot. FR-1 forbids reflex-enabling.","opts":[
    {"label":"Enable supervisor (verify first)","rec":True,"action":"Verify the com.brainstem.server plist serves the current code side-by-side against the running orphan; only if identical, bootstrap it and log the decision in work/. FR-1."},
    {"label":"Keep manual, document it","action":"Record in standing-oddities that :7071 is deliberately manually launched (no launchd supervisor)."}]},
  {"id":"flight-7075","title":"Flight :7075 unauthenticated (fallback gpt-4o)","ctx":"The canary flight on :7075 serves gpt-4o unauthenticated instead of the soaked model — a demo against it behaves unlike what qualified (FR-8).","opts":[
    {"label":"Re-authenticate the flight","rec":True,"action":"Re-auth the :7075 canary flight's Copilot credential so it serves the soaked model, not the gpt-4o fallback."},
    {"label":"Stop the flight","action":"Stop the :7075 canary flight (flight.sh stop)."}]},
  {"id":"dead-flights","title":"Dead flight entries in ~/.rapp-flight","ctx":"Flights 'beta' and 'canary-flight-project-twin' are dead (pids gone) but their entries/logs linger.","opts":[
    {"label":"Clean up the dead entries","rec":True,"action":"Remove the dead flight directories (beta, canary-flight-project-twin) from ~/.rapp-flight and reconcile the flight registry."},
    {"label":"Restart them","action":"Restart the dead flights (beta, canary-flight-project-twin)."},
    {"label":"Leave them","action":"Leave the dead flight entries as-is."}]},
  {"id":"brainstem-7082","title":"Undocumented 2nd brainstem on :7082","ctx":"A second brainstem runs from the grail checkout on :7082 (twin-kody soul, 5 agents) — undocumented; likely a parallel session's twin.","opts":[
    {"label":"Investigate + document","rec":True,"action":"Identify what launched the :7082 brainstem (twin-kody), determine if intentional, and either document it in standing-oddities or stop it."},
    {"label":"Leave it (known twin)","action":"Record :7082 as a known twin experiment in standing-oddities; leave running."}]},
  {"id":"rar-stale","title":"RAR checkout 278-behind / 130-dirty","ctx":"The active RAR checkout is far behind origin with orphaned build output. Deliberate or drift is unrecorded.","opts":[
    {"label":"Codify as frozen-on-purpose","rec":True,"action":"Document in standing-oddities that RAR's dirty/behind state is intentional; no reconcile needed."},
    {"label":"Reconcile to origin","action":"Scratch-clone RAR, review the 130 dirty files + 278-behind commits, and reconcile safely without disturbing the active checkout."}]},
  {"id":"docs-copilot-secret","title":"documents-to-copilot-studio hardcoded secret","ctx":"Private repo kody-w/documents-to-copilot-studio hardcodes a client_secret in tracked static/app.js. Private, so not a public leak, but a tracked secret.","opts":[
    {"label":"Scrub the secret from the repo","rec":True,"action":"Remove/redact the hardcoded client_secret in kody-w/documents-to-copilot-studio static/app.js (and history if warranted); replace with an env reference."},
    {"label":"Leave it (private repo)","action":"Record accepting the tracked secret in the private documents-to-copilot-studio repo."}]},
]

def load_choices():
    d = {}
    if os.path.exists(QUEUE):
        for line in open(QUEUE):
            line = line.strip()
            if not line: continue
            try: r = json.loads(line)
            except: continue
            d[r["id"]] = r
    return d

def save_choice(rec):
    ch = load_choices()
    ch[rec["id"]] = rec
    with open(QUEUE, "w") as f:
        for r in ch.values():
            f.write(json.dumps(r) + "\n")

def page():
    ch = load_choices()
    cards = []
    for it in ITEMS:
        chosen = ch.get(it["id"], {}).get("label")
        btns = []
        for o in it["opts"]:
            sel = "sel" if chosen == o["label"] else ""
            rec = "rec" if o.get("rec") else ""
            star = "★ " if o.get("rec") else ""
            btns.append(f'<button class="opt {rec} {sel}" onclick="choose(\'{it["id"]}\',{json.dumps(o["label"])},{json.dumps(o["action"])},{json.dumps(it["title"])})">{star}{o["label"]}</button>')
        status = f'<span class="done">queued → {chosen}</span>' if chosen else '<span class="pend">no decision yet</span>'
        cards.append(f'<div class="card" id="c_{it["id"]}"><div class="t">{it["title"]} {status}</div><div class="ctx">{it["ctx"]}</div><div class="opts">{"".join(btns)}</div></div>')
    qn = len(ch)
    return HTML.replace("{{CARDS}}", "".join(cards)).replace("{{N}}", str(len(ITEMS))).replace("{{Q}}", str(qn))

HTML = """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>🗼 Tower — Decisions</title><style>
:root{--bg:#0a0e14;--card:#121821;--bd:#26303d;--fg:#e6edf3;--mut:#8b949e;--acc:#58a6ff;--g:#3fb950;--gb:#0f2417;--y:#d29922}
@media(prefers-color-scheme:light){:root{--bg:#f6f8fa;--card:#fff;--bd:#d0d7de;--fg:#1f2328;--mut:#636c76;--gb:#dafbe1}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 -apple-system,Segoe UI,sans-serif;padding:clamp(12px,2vw,28px)}
header{display:flex;justify-content:space-between;align-items:baseline;flex-wrap:wrap;gap:8px;border-bottom:1px solid var(--bd);padding-bottom:12px;margin-bottom:16px}
h1{margin:0;font-size:clamp(20px,2.4vw,32px)}.sub{color:var(--mut)}
.card{background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:14px 16px;margin-bottom:12px}
.t{font-weight:700;font-size:clamp(15px,1.5vw,19px);margin-bottom:4px}
.ctx{color:var(--mut);font-size:13px;margin-bottom:10px}
.opts{display:flex;gap:8px;flex-wrap:wrap}
.opt{cursor:pointer;border:1px solid var(--bd);background:transparent;color:var(--fg);border-radius:8px;padding:8px 14px;font-size:14px;transition:.12s}
.opt:hover{border-color:var(--acc)}
.opt.rec{border-color:#2ea043}.opt.rec:before{}
.opt.sel{background:var(--gb);border-color:var(--g);color:var(--g);font-weight:700}
.done{color:var(--g);font-size:12px;font-weight:600;margin-left:8px}
.pend{color:var(--mut);font-size:12px;margin-left:8px}
.bar{position:sticky;bottom:0;background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:12px 16px;margin-top:16px;display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}
.hint{color:var(--mut);font-size:13px}
code{background:rgba(127,127,127,.15);padding:1px 6px;border-radius:5px}
</style></head><body>
<header><div><h1>🗼 Decision console</h1><div class="sub">Click your choice per item — ★ is my recommendation. Each click queues a task for the AI.</div></div>
<div class="sub">{{Q}}/{{N}} decided · private · local</div></header>
{{CARDS}}
<div class="bar"><div class="hint">Queued to <code>.tower/decisions-queue.jsonl</code>. Then tell a Claude session: <b>“process the tower decisions queue”</b>.</div>
<div class="hint" id="stat"></div></div>
<script>
async function choose(id,label,action,title){
  const r=await fetch('/choose',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id,label,action,title})});
  if(r.ok){document.getElementById('stat').textContent='✓ queued: '+label;location.reload();}
}
</script></body></html>"""

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        body = page().encode()
        self.send_response(200); self.send_header("Content-Type","text/html; charset=utf-8")
        self.send_header("Content-Length",str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_POST(self):
        n = int(self.headers.get("Content-Length","0"))
        data = json.loads(self.rfile.read(n) or b"{}")
        rec = {"id":data["id"],"title":data.get("title",""),"label":data["label"],
               "action":data["action"],"ts":datetime.datetime.now().isoformat(timespec="seconds"),"status":"queued"}
        save_choice(rec)
        self.send_response(200); self.send_header("Content-Type","application/json"); self.end_headers()
        self.wfile.write(b'{"ok":true}')

if __name__ == "__main__":
    print(f"Decision console → http://localhost:{PORT}   (queue: {QUEUE})")
    print("Click your choices, then tell a Claude session: \"process the tower decisions queue\"")
    try: HTTPServer(("127.0.0.1", PORT), H).serve_forever()
    except KeyboardInterrupt: print("\nstopped.")
