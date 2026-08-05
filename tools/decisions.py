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
import json, os, datetime, html, re, subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

TOWER = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUEUE = os.path.join(TOWER, ".tower", "decisions-queue.jsonl")
os.makedirs(os.path.dirname(QUEUE), exist_ok=True)
PORT = int(os.environ.get("DECISIONS_PORT", "7788"))

# Each item: id, title, context, options[{label, rec?, action}]
# `action` is the instruction a Claude session executes when this choice is queued.
ITEMS = [
  # The three Google-key leaks are individually flaggable: a `resolve` option marks
  # the item done IMMEDIATELY (no AI session needed), rewrites the NEEDS-KODY row in
  # the standing-oddities ledger (which clears the dashboard's red strip on next
  # regen), and best-effort closes the repo's open secret-scanning alerts via `gh`.
  {"id":"leak-mars-barn-opus","title":"Google API-key leak — mars-barn-opus","ctx":"Committed .playwright-profile/ browser cache; dir purged from all 526 commits + force-pushed by Fable. Flag resolved once you've revoked the key in Google Cloud Console.","resolve_match":"mars-barn-opus","gh_repo":"kody-w/mars-barn-opus","opts":[
    {"label":"✓ Key revoked — flag resolved","rec":True,"resolve":True,"action":"Resolved by Kody in the console; secret-scanning alerts closed (resolution=revoked)."},
    {"label":"Not yet — keep open","action":"Leave the mars-barn-opus Google-key alert open."}]},
  {"id":"leak-gemini-cli-tips","title":"Google API-key leak — gemini-cli-tips","ctx":".claude/commands/gemini-power.md; key redacted across all history + force-pushed by Fable. Flag resolved once you've revoked the key in Google Cloud Console.","resolve_match":"gemini-cli-tips","gh_repo":"kody-w/gemini-cli-tips","opts":[
    {"label":"✓ Key revoked — flag resolved","rec":True,"resolve":True,"action":"Resolved by Kody in the console; secret-scanning alerts closed (resolution=revoked)."},
    {"label":"Not yet — keep open","action":"Leave the gemini-cli-tips Google-key alert open."}]},
  {"id":"leak-thematrix","title":"Google API-key leak — TheMatrix","ctx":".knowledge-bases/kody-voice/QUICK_IMAGE_PROMPTS.md; key redacted across all history + force-pushed by Fable. Flag resolved once you've revoked the key in Google Cloud Console.","resolve_match":"TheMatrix","gh_repo":"kody-w/TheMatrix","opts":[
    {"label":"✓ Key revoked — flag resolved","rec":True,"resolve":True,"action":"Resolved by Kody in the console; secret-scanning alerts closed (resolution=revoked)."},
    {"label":"Not yet — keep open","action":"Leave the TheMatrix Google-key alert open."}]},
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

# ── openrappter morning decisions ──────────────────────────────────────────────
# openrappter's agent runs each morning and writes the decisions it wants Kody to
# sign off on (in this same item shape) to ~/.openrappter/tower-decisions.json.
# They show as cards here alongside the estate items; your click queues the action.
#
# Re-read per request, not at import. #1: this block used to run once at module
# level, so a decision written while the console was open never appeared — the
# page rendered normally, with an authoritative-looking total, and silently
# omitted it. An agent surfacing a decision at 03:00 had done nothing if the
# page had been open since midnight. Cached like fleet_items() so the page stays
# instant.
_OR_DECISIONS = os.path.join(os.path.expanduser("~"), ".openrappter", "tower-decisions.json")
_OR_CACHE = {"mtime": None, "items": []}

def openrappter_items():
    """Decisions openrappter wants Kody to sign off on, re-read when they change.

    Keyed on mtime rather than a clock: the file changes rarely and a stale
    read here is exactly the failure being fixed. A missing, half-written or
    malformed file yields nothing and never takes the console down — it is
    written by another process, so a torn read is a normal event, not an error.
    """
    try:
        mtime = os.path.getmtime(_OR_DECISIONS)
    except OSError:
        _OR_CACHE["mtime"], _OR_CACHE["items"] = None, []
        return []
    if mtime == _OR_CACHE["mtime"]:
        return _OR_CACHE["items"]

    items = []
    try:
        with open(_OR_DECISIONS) as f:
            od = json.load(f)
        raw = od.get("items", od) if isinstance(od, dict) else od
        for it in (raw or []):
            if isinstance(it, dict) and it.get("id") and it.get("opts"):
                it = dict(it)
                it.setdefault("ctx", "")
                it["title"] = "🦖 " + str(it.get("title", it["id"]))
                it["_source"] = "openrappter"
                items.append(it)
    except Exception:
        # A torn read now would poison the cache until the next write, so do
        # not record this mtime — try again on the next request.
        return _OR_CACHE["items"]

    _OR_CACHE["mtime"], _OR_CACHE["items"] = mtime, items
    return items

# ── fleet decisions (the control-tower pattern, across ALL remote devices) ────
# Probes every device's satellite tower (remote-devices/satellite/ on :towerPort)
# over Tailscale and generates decision cards: install the satellite where it is
# missing, plus per-device findings (brainstem down, disk low). The processing
# session executes the chosen action ON that device — ssh where keyed
# (battlestation), otherwise via the main tower's install one-liner + Screen
# Sharing. Cached 30s so the page stays instant.
_FLEET_CACHE = {"ts": 0.0, "items": []}

def _probe(host, port):
    from urllib.request import urlopen
    try:
        with urlopen(f"http://{host}:{port}/status.json", timeout=1.8) as r:
            return json.loads(r.read())
    except Exception:
        return None

def fleet_items():
    import time as _t
    if _t.time() - _FLEET_CACHE["ts"] < 30:
        return _FLEET_CACHE["items"]
    items = []
    try:
        reg = json.load(open(os.path.join(TOWER, "remote-devices", "devices.json")))
    except Exception:
        reg = {"devices": []}
    port = reg.get("towerPort", 7799)
    main = reg.get("main", "")
    from concurrent.futures import ThreadPoolExecutor
    devs = reg.get("devices", [])
    with ThreadPoolExecutor(max_workers=8) as ex:
        sts = list(ex.map(lambda d: _probe(d["host"], port), devs))
    for d, st in zip(devs, sts):
        short = d["host"].split(".")[0]
        if st is None:
            items.append({"id": f"fleet-install-{short}",
                "title": f"🖥 Install the RAPP control tower satellite on {d['name']}?",
                "ctx": f"{d['host']} has no satellite tower answering on :{port}. Installing one makes it a full member of the federated tower — its own board, live status, drill-down from the main board, and a target the tower can act on.",
                "opts": [
                    {"label": "Install it (via Tailscale)", "rec": True,
                     "action": f"Install the tower satellite on {d['name']} ({d['host']}): if `ssh {short}` is keyed, copy remote-devices/satellite/ files + write satellite.json + persistent service and verify http://{d['host']}:{port}/status.json. If no ssh, walk Kody through it over Screen Sharing (vnc://{d['host']}): run  curl -fsSL http://{main}:{port}/install.sh | bash  on that device, then verify from the main tower."},
                    {"label": "Not this device", "action": f"Skip installing the satellite on {d['name']}; leave the card cleared for this round."},
                    {"label": "Remove from fleet", "action": f"Remove {d['name']} ({d['host']}) from remote-devices/devices.json and the Remote Devices app card."}]})
            continue
        if st.get("brainstem") != "up":
            items.append({"id": f"fleet-brainstem-{short}",
                "title": f"🖥 Brainstem DOWN on {d['name']}",
                "ctx": f"Satellite tower on {d['host']} is up but nothing answers on its :7071. If this device should serve a brainstem, start it; if not, record that it deliberately doesn't run one.",
                "opts": [
                    {"label": "Start / install the brainstem there", "rec": True,
                     "action": f"On {d['name']} ({d['host']}): start the brainstem on :7071 (or install via the public one-liner if absent), via ssh if keyed else Screen Sharing; verify the satellite reports brainstem=up."},
                    {"label": "This device doesn't run one", "action": f"Record in remote-devices/README.md that {d['name']} intentionally runs no brainstem."}]})
        disk = st.get("disk_free_gb")
        if isinstance(disk, (int, float)) and disk < 10:
            items.append({"id": f"fleet-disk-{short}",
                "title": f"🖥 Disk critically low on {d['name']} — {disk}GB free",
                "ctx": f"The satellite on {d['host']} reports {disk}GB free. Below ~10GB things start failing (updates, temp files, the brainstem's memory writes).",
                "opts": [
                    {"label": "Investigate + clean it up", "rec": True,
                     "action": f"On {d['name']} ({d['host']}): identify the biggest space consumers (via ssh if keyed, else guide over Screen Sharing) and propose a cleanup — show findings before deleting anything."},
                    {"label": "Known — leave it", "action": f"Record the low-disk state on {d['name']} as known/accepted."}]})
    _FLEET_CACHE.update(ts=_t.time(), items=items)
    return items

def resolve_ledger(match):
    """Rewrite NEEDS-KODY rows containing `match` in every work/*/DECISIONS.md
    to ✅ RESOLVED — this is what clears the dashboard's red strip + count."""
    stamp = datetime.date.today().isoformat()
    hit = 0
    import glob
    for path in glob.glob(os.path.join(TOWER, "work", "*", "DECISIONS.md")):
        with open(path) as f: text = f.read()
        out = []
        for line in text.splitlines(keepends=True):
            if match in line and "NEEDS-KODY" in line:
                new = re.sub(r"\*\*NEEDS-KODY:?[^*]*\*\*",
                             f"✅ RESOLVED {stamp} (Kody, decisions console)", line)
                if new != line: hit += 1
                line = new
            out.append(line)
        if hit:
            with open(path, "w") as f: f.write("".join(out))
    return hit

def gh_close_alerts(repo):
    """Best-effort: close every open secret-scanning alert on `repo` as revoked."""
    try:
        r = subprocess.run(["gh","api",f"repos/{repo}/secret-scanning/alerts?state=open",
                            "--jq",".[].number"], capture_output=True, text=True, timeout=25)
        nums = [n for n in r.stdout.split() if n.strip().isdigit()]
    except Exception:
        return -1, []
    closed = []
    for n in nums:
        try:
            p = subprocess.run(["gh","api","-X","PATCH",
                                f"repos/{repo}/secret-scanning/alerts/{n}",
                                "-f","state=resolved","-f","resolution=revoked"],
                               capture_output=True, text=True, timeout=25)
            if p.returncode == 0: closed.append(n)
        except Exception:
            pass
    return len(nums), closed

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

# status (from the queue, set when a session processes it) -> badge label + css state
def badge(status):
    s = (status or "").lower()
    if s.startswith("done"):     return ("✅ Done", "b-done")
    if s.startswith("prepared"): return ("🚂 Prepared — rides the train", "b-work")
    if s.startswith("drafted"):  return ("✍️ Drafted — your sign-off", "b-work")
    if s.startswith("proposed"): return ("🗳️ Proposed — your pick", "b-work")
    if s.startswith("queued") and status != "queued": return ("⏳ Queued — run fresh", "b-work")
    if s == "queued":            return ("• Chosen — awaiting the AI", "b-open")
    return ("• No decision yet", "b-open")

def page():
    ch = load_choices()
    pending, done = [], []
    all_items = fleet_items() + openrappter_items() + ITEMS
    for it in all_items:
        rec = ch.get(it["id"], {})
        chosen = rec.get("label")
        status = rec.get("status", "queued" if chosen else None)
        blabel, bclass = badge(status)
        is_done = (status or "").lower().startswith("done")
        act = rec.get("action", "")
        if is_done:
            # completed card — dimmed, no buttons, shows the action taken
            done.append(
                f'<div class="card dim"><div class="t">✓ {html.escape(it["title"])} '
                f'<span class="badge b-done">{blabel}</span></div>'
                f'<div class="chosen">You chose: <b>{html.escape(chosen or "")}</b></div>'
                f'<div class="acted">→ {html.escape(act)}</div></div>')
        else:
            btns = []
            for o in it["opts"]:
                sel = "sel" if chosen == o["label"] else ""
                rc = "rec" if o.get("rec") else ""
                star = "★ " if o.get("rec") else ""
                rz = ' data-resolve="1"' if o.get("resolve") else ""
                btns.append(
                    f'<button class="opt {rc} {sel}" '
                    f'data-id="{html.escape(it["id"], quote=True)}" '
                    f'data-label="{html.escape(o["label"], quote=True)}" '
                    f'data-action="{html.escape(o["action"], quote=True)}" '
                    f'data-title="{html.escape(it["title"], quote=True)}"{rz}>'
                    f'{star}{html.escape(o["label"])}</button>')
            pnote = (f'<div class="acted pendact">→ next: {html.escape(act)}</div>' if chosen and act else '')
            pending.append(
                f'<div class="card"><div class="t">{html.escape(it["title"])} '
                f'<span class="badge {bclass}">{blabel}</span></div>'
                f'<div class="ctx">{html.escape(it["ctx"])}</div>'
                f'<div class="opts">{"".join(btns)}</div>{pnote}</div>')
    ph = (f'<h2 class="sec">⚡ Still needs you · {len(pending)}</h2>' + "".join(pending)) if pending else '<h2 class="sec">🎉 Nothing left needs you</h2>'
    dh = (f'<h2 class="sec dimh">✅ Done · {len(done)}</h2>' + "".join(done)) if done else ''
    return (HTML.replace("{{PENDING}}", ph).replace("{{DONE}}", dh)
                .replace("{{N}}", str(len(all_items))).replace("{{D}}", str(len(done)))
                .replace("{{P}}", str(len(pending))))

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
.badge{font-size:11px;font-weight:700;margin-left:8px;padding:1px 8px;border-radius:20px;white-space:nowrap}
.b-done{color:var(--g);border:1px solid #1f5c33;background:var(--gb)}
.b-work{color:var(--y);border:1px solid #6b5410}
.b-open{color:var(--mut);border:1px solid var(--bd)}
.sec{font-size:15px;letter-spacing:.03em;margin:22px 0 10px;text-transform:uppercase}
.dimh{color:var(--mut)}
.card.dim{opacity:.6}
.chosen{font-size:13px;margin-bottom:2px}
.acted{color:var(--mut);font-size:13px}
.pendact{margin-top:8px;color:var(--y)}
.bar{position:sticky;bottom:0;background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:12px 16px;margin-top:16px;display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}
.hint{color:var(--mut);font-size:13px}
code{background:rgba(127,127,127,.15);padding:1px 6px;border-radius:5px}
</style></head><body>
<header><div><h1>🗼 Decision console</h1><div class="sub">Your picks and what the AI did with them. ★ = my recommendation. Re-click any open item to change it.</div></div>
<div class="sub">{{D}} done · {{P}} still need you · {{N}} total</div></header>
{{PENDING}}
{{DONE}}
<div class="bar"><div class="hint">Queued to <code>.tower/decisions-queue.jsonl</code>. Re-run a Claude session with <b>“process the tower decisions queue”</b> after new picks.</div>
<div class="hint" id="stat"></div></div>
<script>
async function choose(b){
  const d=b.dataset;
  b.textContent='… saving';
  try{
    const r=await fetch('/choose',{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({id:d.id,label:d.label,action:d.action,title:d.title,resolve:!!d.resolve})});
    if(!r.ok) throw new Error('HTTP '+r.status);
    const j=await r.json();
    document.getElementById('stat').textContent=j.note?('✓ '+j.note):('✓ queued: '+d.label);
    location.reload();
  }catch(e){
    document.getElementById('stat').textContent='✗ error: '+e.message+' (is the server still running?)';
    b.textContent='⚠ retry';
  }
}
document.addEventListener('click',function(e){
  const b=e.target.closest('.opt');
  if(b) choose(b);
});
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
        note = ""
        item = next((i for i in ITEMS if i["id"] == data.get("id")), None)
        if data.get("resolve") and item:
            # Kody flagged it resolved: done NOW — no AI session in the loop.
            rows = resolve_ledger(item.get("resolve_match", "")) if item.get("resolve_match") else 0
            note = f"resolved — {rows} ledger row(s) cleared"
            if item.get("gh_repo"):
                total, closed = gh_close_alerts(item["gh_repo"])
                if total == -1:  note += "; gh alert check failed (close manually)"
                elif total == 0: note += "; no open alerts on " + item["gh_repo"]
                else:            note += f"; closed {len(closed)}/{total} alert(s) on " + item["gh_repo"]
            rec["status"] = "done — " + note
        save_choice(rec)
        self.send_response(200); self.send_header("Content-Type","application/json"); self.end_headers()
        self.wfile.write(json.dumps({"ok": True, "note": note}).encode())

if __name__ == "__main__":
    print(f"Decision console → http://localhost:{PORT}   (queue: {QUEUE})")
    print("Click your choices, then tell a Claude session: \"process the tower decisions queue\"")
    try: HTTPServer(("127.0.0.1", PORT), H).serve_forever()
    except KeyboardInterrupt: print("\nstopped.")
