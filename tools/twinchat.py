#!/usr/bin/env python3
"""twinchat.py — make a foreign host present as a uniform peer.

Canon: kody-w/rapp-neighborhood-protocol §3, §6a, §6b, §6e. This implements the
existing spec; it does not invent one.

    §3  every participant -- a person typing, a local brainstem.py, a vTwin in a
        tab, an MCP client, Claude on the string -- is INDISTINGUISHABLE on the
        wire. "Chat is the only wire."
    §6a envelope: {schema, from_rappid, to_rappid, utc, nonce, kind, payload, facets}
    §6b kinds:    say · share-fact · share-egg · request-fact · ack · console
    §6e response: {schema, channel, envelope, status, response}
                  a `say` is answered as the brainstem /chat contract:
                  {response, session_id, agent_logs, voice_mode}

WHY THIS EXISTS
    The toaster carries CAPABILITIES across a host boundary. This carries
    CONVERSATION across it. Together they are the membrane: a brainstem
    colonises a host the way a mitochondrion colonises a cell -- it does not
    rewrite the host, it trades across a narrow interface.

    Absorption runs two ways and only one of them was built:
      colonise -- project our capabilities into their native format  (toaster)
      absorb   -- wrap a foreign AI so it speaks twin-chat and becomes just
                  another neighbour                                  (this)

WHAT IS AND IS NOT PROVEN HERE
    The RAPP adapter is exercised against a live brainstem and works.
    Adapters for hosts whose membrane is not open are DECLARED, not claimed:
    `probe` reports what actually answered, never what ought to. A host with no
    chat-shaped endpoint cannot be a peer yet, and this says so rather than
    pretending.

    tools/neighborhoods.sh shows the estate-wide picture; this is the thing that
    turns a "none" in that MEMBRANE column into an "open".

    twinchat.py probe                   # which neighbours can actually speak?
    twinchat.py say "hello" --to rapp   # send a §6a `say`, get a §6e response
    twinchat.py envelope "hi"           # emit a bare envelope (no network)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone

SCHEMA_REQ = "rapp-twin-chat/1.0"
SCHEMA_RES = "rapp-twin-chat-response/1.0"
KINDS = ("say", "share-fact", "share-egg", "request-fact", "ack", "console")

# `console` operates a neighbour's runtime and is sealed-only under §8/§11.
# This tool refuses to originate one: an unsealed console frame is remote code
# execution wearing a chat envelope.
SEALED_ONLY = ("console",)


def utcnow() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def make_envelope(payload, kind: str = "say", to_rappid: str = "local",
                  from_rappid: str = "tower", facets=None) -> dict:
    if kind not in KINDS:
        raise ValueError(f"kind must be one of {KINDS}, got {kind!r}")
    if kind in SEALED_ONLY:
        raise ValueError(
            f"kind {kind!r} is sealed-only (neighborhood-protocol §8/§11). "
            "This tool will not originate one unsealed.")
    return {
        "schema": SCHEMA_REQ,
        "from_rappid": from_rappid,
        "to_rappid": to_rappid,
        "utc": utcnow(),
        "nonce": uuid.uuid4().hex,
        "kind": kind,
        "payload": payload if isinstance(payload, dict) else {"text": str(payload)},
        "facets": facets or [],
    }


def validate_envelope(env: dict) -> list:
    """Return a list of problems. Empty list means conformant."""
    bad = []
    if env.get("schema") != SCHEMA_REQ:
        bad.append(f"schema must be {SCHEMA_REQ!r}")
    for f in ("from_rappid", "to_rappid", "utc", "nonce", "kind", "payload"):
        if f not in env:
            bad.append(f"missing required field {f!r}")
    if env.get("kind") not in KINDS:
        bad.append(f"kind {env.get('kind')!r} not in {KINDS}")
    if not isinstance(env.get("facets", []), list):
        bad.append("facets must be a list")
    if not isinstance(env.get("payload", {}), dict):
        bad.append("payload must be an object")
    return bad


def make_response(env: dict, status: int, response, channel: str) -> dict:
    return {"schema": SCHEMA_RES, "channel": channel,
            "envelope": env, "status": status, "response": response}


# --------------------------------------------------------------------------
# Adapters. One per host. Each answers: can you speak, and how do I say a `say`?
# --------------------------------------------------------------------------

class Adapter:
    name = "abstract"
    channel = "unknown"
    membrane = None          # the URL that must ANSWER for this to be a peer

    def probe(self) -> tuple:
        """(reachable: bool, detail: str). Never infers -- only reports."""
        if not self.membrane:
            return (False, "no chat-shaped endpoint declared")
        try:
            with urllib.request.urlopen(self.membrane, timeout=4) as r:
                body = r.read(4000).decode("utf-8", "replace")
            return (r.status == 200, f"http {r.status}")
        except urllib.error.HTTPError as e:
            return (False, f"http {e.code}")
        except Exception as e:
            return (False, type(e).__name__)

    def say(self, env: dict) -> dict:
        raise NotImplementedError


class RappAdapter(Adapter):
    """The reference adapter. §6e says a `say` routes into the neighbour's
    brainstem and is answered as the /chat contract -- so this is a direct
    mapping, and it is the one adapter proven against a live host."""
    name = "rapp"
    channel = "5a-tether"

    def __init__(self, port=None):
        self.port = int(port or os.environ.get("RAPP_BRAINSTEM_PORT", 7071))
        self.membrane = f"http://localhost:{self.port}/health"

    def say(self, env: dict) -> dict:
        text = env["payload"].get("text", "")
        req = urllib.request.Request(
            f"http://localhost:{self.port}/chat",
            data=json.dumps({"user_input": text}).encode(),
            headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                body = json.loads(r.read().decode())
                status = r.status
        except urllib.error.HTTPError as e:
            return make_response(env, e.code, {"error": e.reason}, self.channel)
        except Exception as e:
            return make_response(env, 0, {"error": f"{type(e).__name__}: {e}"},
                                 self.channel)
        # §6e: answer with the brainstem contract, unaltered.
        return make_response(env, status, {
            "response": body.get("response"),
            "session_id": body.get("session_id"),
            "agent_logs": body.get("agent_logs"),
            "voice_mode": body.get("voice_mode"),
        }, self.channel)


class DeclaredAdapter(Adapter):
    """A host we know about whose membrane is not open. Declared so `probe`
    reports it honestly instead of omitting it -- an absent row reads as 'not
    considered', which is worse than 'not reachable'."""
    def __init__(self, name, note, membrane=None, channel="undeclared"):
        self.name, self.note, self.membrane, self.channel = name, note, membrane, channel

    def say(self, env):
        return make_response(env, 501, {
            "error": f"{self.name} has no twin-chat membrane yet",
            "detail": self.note,
            "needed": "an endpoint that accepts a §6a envelope and answers §6e",
        }, self.channel)


def adapters() -> dict:
    return {
        "rapp": RappAdapter(),
        "openrappter": DeclaredAdapter(
            "openrappter",
            "daemon runs locally; no chat-shaped endpoint found. Its capabilities "
            "are portable files, so the toaster already reaches it -- conversation "
            "does not yet.",
            channel="local"),
        "openclaw": DeclaredAdapter(
            "openclaw",
            "gateway is token-authed in ~/.openclaw/openclaw.json. Agents there are "
            "runtime STATE (sessions, auth profiles), not portable artifacts, so "
            "absorption here must be conversational -- this adapter is the only "
            "way in, and it is not built.",
            channel="gateway"),
        "claude-code": DeclaredAdapter(
            "claude-code",
            "no local endpoint; skills are files. Reached by the toaster, not by "
            "twin-chat.",
            channel="files"),
    }


# --------------------------------------------------------------------------

def cmd_probe(a) -> int:
    print(f"{'PEER':<14} {'MEMBRANE':<10} {'CHANNEL':<12} DETAIL")
    open_n = 0
    for name, ad in adapters().items():
        ok, detail = ad.probe()
        open_n += ok
        note = detail if ok else (getattr(ad, "note", detail) or detail)
        print(f"{name:<14} {'open' if ok else 'none':<10} {ad.channel:<12} {note[:76]}")
    print(f"\n{open_n}/{len(adapters())} neighbour(s) can currently speak twin-chat.")
    print("A 'none' is not a fault — it is an adapter that does not exist yet.")
    return 0


def cmd_envelope(a) -> int:
    env = make_envelope(a.text, kind=a.kind, to_rappid=a.to)
    bad = validate_envelope(env)
    print(json.dumps(env, indent=2))
    if bad:
        print("INVALID: " + "; ".join(bad), file=sys.stderr)
        return 1
    return 0


def cmd_say(a) -> int:
    ads = adapters()
    if a.to not in ads:
        print(f"unknown peer {a.to!r}; known: {', '.join(ads)}", file=sys.stderr)
        return 64
    ad = ads[a.to]
    env = make_envelope(a.text, kind="say", to_rappid=a.to)
    bad = validate_envelope(env)
    if bad:
        print("refusing to send a non-conformant envelope: " + "; ".join(bad),
              file=sys.stderr)
        return 65
    res = ad.say(env)
    if a.raw:
        print(json.dumps(res, indent=2))
        return 0 if res["status"] == 200 else 1
    print(f"status  {res['status']}  (channel {res['channel']}, nonce "
          f"{env['nonce'][:8]})")
    r = res.get("response") or {}
    if res["status"] == 200:
        print(f"reply   {str(r.get('response'))[:600]}")
        if r.get("agent_logs"):
            print(f"agents  {str(r['agent_logs'])[:200]}")
    else:
        print(f"error   {r.get('error')}")
        if r.get("detail"):
            print(f"detail  {r['detail']}")
    return 0 if res["status"] == 200 else 1


def cmd_selftest(a) -> int:
    checks = []
    env = make_envelope("hi")
    checks.append(("envelope conforms to §6a", validate_envelope(env) == []))
    checks.append(("schema is rapp-twin-chat/1.0", env["schema"] == SCHEMA_REQ))
    checks.append(("nonce is unique",
                   make_envelope("a")["nonce"] != make_envelope("b")["nonce"]))
    try:
        make_envelope("x", kind="console")
        sealed = False
    except ValueError:
        sealed = True
    checks.append(("refuses to originate unsealed `console` (§8/§11)", sealed))
    try:
        make_envelope("x", kind="bogus")
        rejected = False
    except ValueError:
        rejected = True
    checks.append(("rejects a kind outside §6b", rejected))
    bad = validate_envelope({"schema": "wrong"})
    checks.append(("validator catches a malformed envelope", len(bad) >= 5))
    res = make_response(env, 200, {"response": "ok"}, "5a-tether")
    checks.append(("response conforms to §6e",
                   res["schema"] == SCHEMA_RES and res["envelope"] is env))
    for label, ok in checks:
        print(f"  {'PASS' if ok else 'FAIL'}  {label}")
    fails = sum(1 for _, ok in checks if not ok)
    print(f"\n{len(checks)-fails}/{len(checks)} passed")
    return 1 if fails else 0


def main() -> int:
    p = argparse.ArgumentParser(prog="twinchat",
                                description="uniform-peer adapter (neighborhood-protocol §3/§6)")
    sub = p.add_subparsers(dest="cmd", required=True)

    pr = sub.add_parser("probe", help="which neighbours can actually speak twin-chat")
    pr.set_defaults(fn=cmd_probe)

    sy = sub.add_parser("say", help="send a §6a `say`, print the §6e response")
    sy.add_argument("text")
    sy.add_argument("--to", default="rapp")
    sy.add_argument("--raw", action="store_true")
    sy.set_defaults(fn=cmd_say)

    ev = sub.add_parser("envelope", help="emit a conformant envelope, no network")
    ev.add_argument("text")
    ev.add_argument("--kind", default="say")
    ev.add_argument("--to", default="local")
    ev.set_defaults(fn=cmd_envelope)

    st = sub.add_parser("selftest", help="conformance checks against §6")
    st.set_defaults(fn=cmd_selftest)

    a = p.parse_args()
    try:
        return a.fn(a)
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
