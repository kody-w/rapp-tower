# 2026-07-24 — The SKILL.md Toaster, the content gate wired, and the membrane thesis

Three threads, one session. Two shipped and verified; one is a design that is
grounded in existing canon and NOT yet built (stated plainly at the bottom).

---

## 1. rapp-god re-leak — CLOSED

**What happened.** The 2026-07-23 `07c7728` "rapp mono repo" commit vacuumed an
archived copy of `kody-w/localtoolsdev` into `kody-w/rapp-god` (**public**),
re-publishing an Azure Function Key in 18 files plus a tracked
`my-agent-app/.env`. Secret-scanning alert #1 opened 2026-07-23.

**Severity: low, and here is the evidence rather than an assumption.** I pulled
both alerts' `secret` payloads and hashed them: `sha256 bbef67d2…`, identical,
56 bytes. localtoolsdev alert #1 is `resolved/revoked` (2026-07-18). **The
credential was already dead when it was re-leaked.**

**Done:** key replaced with a redaction marker in all 18 archived copies;
tracked `.env` removed; pushed as `93344d02`; verified against the live GitHub
API that HEAD no longer serves the key and the `.env` 404s; alert closed as
`revoked`. Estate is now **0 open alerts across 297 repos, 0 public scanning
blind spots**.

**Deliberately NOT done — history rewrite.** The credential is dead, and a
force-push across a 566 MB repo with a daily CI writer costs more than it buys.
Recorded here as an intentional "leave it" per the standing-oddities rule.

### 🔴 The finding that outranks the key — needs Kody

Running the full-tree gate over rapp-god surfaced something worse than a dead
credential. **A public repo is publishing the customer roster it exists to
redact:**

`docs/components/RAPP-Bible/scripts/build_repo_pages.py`
```python
PII_PATTERNS = [... r"marriott", r"fujifilm", r"sonosite", r"bchydro",
                    r"unilever", r"manpowergroup" ...] + [re.compile(r"\bMSC\b")]
```
Same roster in `scripts/mirror_sync.py` (`("sonosite", "example-co")`) and
`tests/test_no_pii.py`.

The sanitiser's denylist **is** the disclosure. This is exactly why the tower's
own denylist is local-only and "never leaves the tower" — that principle is
violated here, in public. **This is Kody's call** (public repo, real customer
names, and the fix changes sanitiser behaviour).

Proposed fix: load the roster from an env var or an untracked local file, with
the tracked code carrying only a neutral fallback. Names never live in the repo.

*(`CORO` also flagged — verified a false positive: it matches "coroutine" and
base64 blobs. No action.)*

---

## 2. The content gate is now actually wired — and it was fail-open

`tools/guard.sh` was built on 2026-07-18 but never called from a push path.
This session found out why, and it was not neglect:

> **A whole-tree scan of rapp-god takes >8 minutes.** A gate that costs eight
> minutes gets bypassed, and a bypassed gate is not a gate.

**Built `--changed` mode** — scans only what the push actually carries.
**1.9 seconds** on the rapp-god diff. That is the difference between a gate that
gets used and one that gets routed around. `--install-hook` installs it as a
repo's `pre-push`.

### The bug that mattered more

The first version passed a brand-new repo's first push **vacuously**: with no
upstream, `origin/main..HEAD` does not resolve, staged is empty, so it scanned
nothing and returned CLEAN. **That is fail-open at the single most dangerous
moment** — the initial publish of a whole tree to a new public repo, which is
precisely the localtoolsdev failure mode.

Now fails closed: no upstream ⇒ scan **all tracked files**. Regression-tested —
a new repo containing a `.env` with a credential-shaped value is blocked
(`exit=1`), a clean one passes (`exit=0`).

---

## 3. rapp-toaster — https://github.com/kody-w/rapp-toaster (PUBLIC, live)

Kody's name for the pattern: **the SKILL.md Toaster.** Bread goes in, toast
comes out, same toast on every platform — and single-file agent drops stay
universally tradable.

**The invariant (Kody's clause, and it is load-bearing):** `agent.py` is the
grail. Every other format is a **projection** that carries the canonical record
inside itself — the **RCI capsule** (gzip+base64, rides as an HTML comment in
`SKILL.md`, `x-rci` in `skill.json`, a trailing comment in `agent.py`).

### Two fidelities — conflating them is how capabilities rot

| | |
|---|---|
| **Transport** | Can the original be recovered byte-exact? Unconditionally yes, via the capsule. |
| **Behavioural** | Does it still behave deterministically *on the host*? Depends on what the host can execute — so it is **graded**, not assumed: `EXEC` / `CODE` / `SPEC`. |

**`--bundle` is the answer to "export to simple SKILL.md platforms without
losing determinism."** It ships the runnable stdlib-only agent beside the
markdown and rewrites the markdown to *command a call* instead of *describing a
procedure* ("## Run this — do not improvise"). Determinism survives because the
same bytes execute. The tool **refuses to claim `EXEC` without first executing
the bundled file** — an earlier build claimed it falsely and was caught.

### Verified, not asserted

- **17/17** selftest.
- **31/31** real artifacts round-trip byte-exact (every brainstem agent + every
  Claude skill on this machine + clawhub).
- **6,138 conversions across 32 real artifacts, zero drift** —
  `soak` tests fixed-point, path-independence, and idempotence.
- **Live brainstem proof:** `blindspot/SKILL.md` → `agent.py` → dropped into the
  running brainstem → `/health` showed **9 agents, 0 quarantined** → `/chat`
  returned `[Blindspot]` in `agent_logs`. Removed afterwards; grail checkout
  returned to its exact pre-existing 6 dirty files.
- **Standalone proof:** a real brainstem agent exported to a plain SKILL.md
  folder ran from an unrelated directory with no brainstem and returned live
  Hacker News data.

### The drift the soak caught (this is why soak exists)

A single round trip passed every time. The soak failed **26 chains**, all
starting `openclaw → skill`. Root cause: the plain-skill projection re-emitted
`metadata.openclaw` in its frontmatter, so `detect()` reclassified the
projection **as** openclaw, and reading it back **overwrote the true original in
the capsule vault with a derived file.**

> **A projection must never be mistakable for the thing it projects from.**

Mapped into the estate: `kody-w/rapp-map` `estate-map.json` (surgical
single-entry insert, `fdd1973`).

---

## 4. The membrane thesis — design, NOT yet built

Kody: *"How can we layer a functioning brainstem over anything else (Hermes,
openclaw, open human) without killing that organism… it would just be another
twin the brainstem can work with."*

**This is already canon.** `kody-w/rapp-neighborhood-protocol` §3, *Uniform
peers*:

> A person typing, a local `brainstem.py`, a vTwin in a tab, an MCP client
> dialing `/chat`, or Claude on the string are **indistinguishable on the wire**.
> …**Chat is the only wire** — MCP is simply another transport that *carries*
> the §6 envelope, never a new kind of unit or peer.

That IS the mitochondrion rule, already written down: a narrow membrane
(`/chat`, the twin-chat envelope), a host that keeps its own genome, and an
organelle that supplies something the host cannot make itself. Endosymbiosis,
not conquest. So this does not need a new protocol — it needs **adapters** to an
existing one.

**Absorption runs in two directions, and both are needed:**

1. **Host → us (absorb).** Wrap a foreign AI so it speaks twin-chat. It becomes
   a **neighbor** — indistinguishable from a vTwin. Its capabilities become
   callable by our swarms. This is "just another twin."
2. **Us → host (colonise).** Project our capabilities into the host's native
   format with the toaster. The host runs RAPP capability **without adopting
   RAPP** — it never knows. This half is **built and shipped today**.

**The honest constraint, which the Majin Buu framing hides:** you can only
colonise a host that exposes *some* extension point — a skills directory, a tool
protocol, an MCP socket, a subprocess boundary. That is not a limitation to
route around; it is the thing that should *define the tiers*. A host with a
skills dir gets `EXEC`. A host with only a system prompt gets `SPEC`. Grading
this honestly is what keeps "RAPP is above that" from becoming a claim we cannot
cash.

### What is NOT built (do not report these as done)

- **A twin-chat adapter contract** for a non-RAPP host to present as a uniform
  peer. Direction 1 above. This is the actual next build.
- **A tower display spanning neighborhoods.** `tools/` today sees the RAPP
  estate only. A `neighborhoods.sh` would show, per host (openclaw,
  openrappter, Hermes, …): adapter present? peer reachable? capabilities
  projected in? drift vs their native format?
- Both were designed this session, neither was written.

---

## Files

- `tools/agentshim.py` — the toaster (tower copy; canonical home is now the
  public `kody-w/rapp-toaster` as `toaster.py`). **Drift risk: two copies.**
  Reconcile to one before either is edited again.
- `tools/guard.sh` — `--changed`, `--install-hook`, fail-closed first push.
