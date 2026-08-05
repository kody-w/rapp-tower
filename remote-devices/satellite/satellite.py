#!/usr/bin/env python3
"""satellite.py — a device-local RAPP control tower that points back to the main one.

Every fleet device runs this on tailnet port 7799. It serves:

  /                the device's own tower board: its live status + the whole
                   federated fleet (fetched client-side from each sibling's
                   /status.json) + a button back to the MAIN tower board
  /status.json     live device status (CORS-open — the main dashboard and the
                   sibling boards drill into this)
  /tower           main only: the full dashboard.html board (auto-regenerated
                   in the background when stale); satellites redirect to main
  /install.sh, /satellite.py, /devices.json
                   self-distribution — a new device bootstraps FROM the tower:
                   curl -fsSL http://<main>:7799/install.sh | bash

Config: satellite.json next to this file:
  {"host": "<own tailnet fqdn>", "main": "<main tailnet fqdn>", "port": 7799,
   "role": "main"|"satellite", "tower_dir": "<path to rapp-tower checkout (main only)>"}

Zero dependencies (stdlib). The tailnet is the trust boundary — never expose
this port publicly. The tower is PRIVATE (iron law 7).
"""
import json, os, socket, subprocess, sys, time, platform
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.request import urlopen

HERE = os.path.dirname(os.path.abspath(__file__))
CFG = {"host": socket.gethostname(), "main": "", "port": 7799, "role": "satellite", "tower_dir": ""}
try:
    CFG.update(json.load(open(os.path.join(HERE, "satellite.json"))))
except Exception:
    pass
try:
    DEVICES = json.load(open(os.path.join(HERE, "devices.json"))).get("devices", [])
except Exception:
    DEVICES = []

START = time.time()
NAME = next((d["name"] for d in DEVICES if d.get("host") == CFG["host"]), CFG["host"].split(".")[0])
KNOWN_PORTS = [7071, 7073, 7075, 7076, 7081, 7082, 7088, 7091, 7788, 7799]
_last_regen = 0.0

def port_open(p, host="127.0.0.1", t=0.4):
    try:
        with socket.create_connection((host, p), timeout=t):
            return True
    except Exception:
        return False

def status():
    st = {
        "app": "rapp-tower-satellite/1", "name": NAME, "host": CFG["host"],
        "role": CFG["role"], "main": CFG["main"], "platform": platform.system(),
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "uptime_s": int(time.time() - START),
    }
    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=len(KNOWN_PORTS)) as ex:
        opens = list(ex.map(port_open, KNOWN_PORTS))
    st["ports"] = [p for p, o in zip(KNOWN_PORTS, opens) if o]
    st["brainstem"] = "up" if 7071 in st["ports"] else "down"
    try:
        import shutil
        st["disk_free_gb"] = round(shutil.disk_usage(os.path.expanduser("~")).free / 1e9, 1)
    except Exception:
        pass
    try:
        st["load"] = round(os.getloadavg()[0], 2)  # not on Windows
    except Exception:
        pass
    if CFG["role"] == "main":
        try:
            st["tower_git"] = subprocess.run(
                ["git", "-C", CFG["tower_dir"], "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True, timeout=5).stdout.strip()
        except Exception:
            pass
        if not st.get("tower_git"):
            # TCC blocks Documents from LaunchAgents — dashboard.sh stamps a meta
            # copy here on every regen
            try:
                st["tower_git"] = json.load(open(os.path.join(HERE, "satellite-meta.json"))).get("git", "")
            except Exception:
                pass
    return st

def maybe_regen_dashboard():
    """Main only: refresh dashboard.html in the background if stale (>120s)."""
    global _last_regen
    dash = os.path.join(CFG.get("tower_dir", ""), "dashboard.html")
    sh = os.path.join(CFG.get("tower_dir", ""), "tools", "dashboard.sh")
    if not (CFG.get("tower_dir") and os.path.exists(sh)):
        return dash
    try:
        stale = (time.time() - os.path.getmtime(dash)) > 120 if os.path.exists(dash) else True
    except Exception:
        stale = True
    if stale and time.time() - _last_regen > 60:
        _last_regen = time.time()
        subprocess.Popen(["bash", sh, "--no-open"], stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL)
    return dash

PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>🗼 __NAME__ — RAPP Tower</title>
<style>
:root{--bg:#0a0e14;--card:#121821;--bd:#26303d;--fg:#e6edf3;--mut:#8b949e;--g:#3fb950;--r:#f85149;--y:#d29922;--pink:#fd8ea1}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--fg);font:16px/1.4 -apple-system,Segoe UI,sans-serif;padding:clamp(12px,2vw,28px)}
.top{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px;margin-bottom:18px}
h1{font-size:clamp(20px,2.6vw,34px)}
.sub{color:var(--mut);font-size:13px;margin-top:2px}
.mainbtn{display:inline-block;background:var(--pink);color:#1a1a1a;font-weight:700;border-radius:10px;padding:12px 18px;text-decoration:none}
.mainbtn:hover{filter:brightness(1.06)}
.fleet{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:14px}
.dev{background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:14px;display:flex;flex-direction:column;gap:6px}
.dev.me{border-color:var(--pink)}
.dt{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.dt b{font-size:16px}
.tag{font-size:10px;font-weight:700;letter-spacing:.05em;white-space:nowrap}
.tag:before{content:"● "}
.up{color:var(--g)}.down{color:var(--r)}.unk{color:var(--y)}
.host{font:11px/1.4 ui-monospace,Menlo,monospace;color:var(--mut);overflow-wrap:anywhere}
.meta{color:var(--mut);font-size:12px;min-height:2.6em}
.btns{display:flex;gap:8px;margin-top:6px}
.b{flex:1;display:block;text-align:center;border-radius:8px;padding:9px 6px;text-decoration:none;font-size:13px;font-weight:700}
.b.tower{background:var(--pink);color:#1a1a1a}
.b.vnc{border:1px solid var(--bd);color:var(--fg)}
.b:hover{filter:brightness(1.1)}
footer{margin-top:20px;color:var(--mut);font-size:12px}
</style></head><body>
<div class="top">
  <div><h1>🗼 __NAME__</h1><div class="sub">RAPP control tower __ROLEWORD__ · __HOST__ · every device is a tower; they all point home</div></div>
  __MAINLINK__
</div>
<div class="fleet" id="fleet"></div>
<footer>federated over Tailscale · each card is that device's own satellite tower (:__PORT__) · status refreshes every 30s</footer>
<script>
const DEVICES=__DEVICES__,ME=__ME__,PORT=__PORTJS__;
function card(d,st){
  const cls=st?(st.brainstem==='up'?'up':'unk'):'down';
  const label=st?('TOWER UP'+(st.brainstem==='up'?' · BRAINSTEM':'')):'NO TOWER';
  const meta=st?('role '+st.role+' · '+(st.platform||'')+' · ports '+(st.ports||[]).join(',')+
    (st.load!==undefined?' · load '+st.load:'')+(st.disk_free_gb!==undefined?' · '+st.disk_free_gb+'GB free':'')):
    'satellite not reachable — install it from the main tower, or the device is asleep';
  return `<div class="dev ${d.host===ME?'me':''}"><div class="dt"><b>${d.name}${d.host===ME?' (this device)':''}</b>`+
    `<span class="tag ${cls}">${label}</span></div>`+
    `<div class="host">${d.host}</div><div class="meta">${meta}</div>`+
    `<div class="btns"><a class="b tower" href="http://${d.host}:${PORT}/">⌖ Tower</a>`+
    `<a class="b vnc" href="vnc://${d.host}">Screen&nbsp;Share</a></div></div>`;
}
async function probe(d){
  try{
    const r=await fetch(`http://${d.host}:${PORT}/status.json`,{signal:AbortSignal.timeout(2500)});
    return await r.json();
  }catch(e){return null;}
}
async function render(){
  const sts=await Promise.all(DEVICES.map(probe));
  document.getElementById('fleet').innerHTML=DEVICES.map((d,i)=>card(d,sts[i])).join('');
}
render();setInterval(render,30000);
</script></body></html>"""

def board():
    roleword = "— MAIN" if CFG["role"] == "main" else "satellite"
    mainlink = ""
    if CFG["role"] != "main" and CFG.get("main"):
        mainlink = f'<a class="mainbtn" href="http://{CFG["main"]}:{CFG["port"]}/tower">⬆ Main Tower Board</a>'
    elif CFG["role"] == "main":
        mainlink = '<a class="mainbtn" href="/tower">📺 Full Board</a>'
    return (PAGE.replace("__NAME__", NAME).replace("__HOST__", CFG["host"])
        .replace("__ROLEWORD__", roleword).replace("__MAINLINK__", mainlink)
        .replace("__DEVICES__", json.dumps(DEVICES)).replace("__ME__", json.dumps(CFG["host"]))
        .replace("__PORTJS__", str(CFG["port"])).replace("__PORT__", str(CFG["port"])))

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _send(self, body, ctype="text/html; charset=utf-8", code=200):
        if isinstance(body, str): body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        try:
            self._get()
        except Exception as e:
            try: self._send(f"satellite error: {e}", "text/plain", 500)
            except Exception: pass
    def _get(self):
        p = self.path.split("?")[0]
        if p == "/status.json":
            self._send(json.dumps(status()), "application/json")
        elif p == "/tower":
            if CFG["role"] == "main":
                maybe_regen_dashboard()
                # prefer the repo's board; fall back to the copy dashboard.sh
                # publishes here (TCC blocks ~/Documents from LaunchAgents)
                body = None
                for dash in (os.path.join(CFG.get("tower_dir", ""), "dashboard.html"),
                             os.path.join(HERE, "dashboard.html")):
                    try:
                        body = open(dash, "rb").read(); break
                    except Exception:
                        continue
                if body:
                    self._send(body)
                else:
                    self._send("dashboard.html not generated yet — run tools/dashboard.sh", "text/plain", 503)
            else:
                self.send_response(302)
                self.send_header("Location", f"http://{CFG['main']}:{CFG['port']}/tower")
                self.end_headers()
        elif p in ("/install.sh", "/satellite.py", "/devices.json"):
            f = os.path.join(HERE, p.lstrip("/"))
            if os.path.exists(f):
                ct = "application/json" if p.endswith(".json") else "text/plain; charset=utf-8"
                self._send(open(f, "rb").read(), ct)
            else:
                self._send("not found", "text/plain", 404)
        else:
            self._send(board())

class Srv(ThreadingHTTPServer):
    # stock server_bind calls socket.getfqdn() → reverse-DNS lookup that can hang
    # for ~30s per start on tailnet Macs; skip it
    def server_bind(self):
        import socketserver
        socketserver.TCPServer.server_bind(self)
        self.server_name = "rapp-tower-satellite"
        self.server_port = self.server_address[1]

if __name__ == "__main__":
    port = int(CFG["port"])
    print(f"🗼 {NAME} — RAPP tower {CFG['role']} on :{port} (main: {CFG['main'] or 'me'})", flush=True)
    Srv(("0.0.0.0", port), H).serve_forever()
