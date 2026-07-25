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

`docs/components/RAPP-Bible/scripts/build_repo_pages.py` line ~24 defines
`PII_PATTERNS` as a literal list of **seven real customer/account names**
(six regex literals plus one word-boundary acronym). The same roster appears in
`scripts/mirror_sync.py` as redaction pairs (`(<customer>, "example-co")`) and
in `tests/test_no_pii.py` as compiled patterns.

*(The names are deliberately not reproduced here — read them from the file. This
document is the decision log, not another copy of the roster.)*

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

---

## 5. Estate-wide PII wipe (2026-07-24, later)

**Scoping first, because "wipe across 371 public repos" is how you corrupt an
estate.** Code-searched all 10 denylist terms across every kody-w repo, then
filtered to genuinely public destinations (the raw search covers private repos
too — the tower itself was in the first result set).

Raw: 411 hits. Public: 215 across 42 repos. **Actually customer PII: 21 files.**
The gap is the whole story:

| Term class | Verdict |
|---|---|
| `CORO`, `MVW` | **False positives.** `CORO` matches "**coro**utine", fictional demo names ("Zane Coro"), and the Italian musical term. `MVW` matched only inside base64 blobs. 0 real in 28 sampled. Wiping these would have corrupted 19 repos of unrelated code. `leakcheck.sh` was separately verified to honour word boundaries correctly — the false positives were an artifact of the search, not the denylist. |
| `Berkley`, `kowildfe`, `Kunal` | **Zero public exposure.** The most sensitive terms (a colleague's name, the MS alias) were already clean. |
| `aibast`, `WorkIQ` | Work-name exposure, not customer PII. Largely structural — `aibast` appears in Kody's own public repo *names*. |
| `Sonosite`, `bchydro`, `marriott`, … | **Real.** Wiped. |

**Wiped and verified (5 public repos):**

- `RAPP-Bible` — the sanitiser scripts hardcoded the customer roster. Roster
  now injected via `$RAPP_PII_TERMS` / untracked `.pii-terms`
  (`scripts/pii_terms.py`); **unconfigured now RAISES** rather than yielding an
  empty banned-list, which would have made `test_no_pii.py` pass vacuously.
- `RAPP-Network`, `RAR` — a real customer was the worked example throughout the
  spec, README and agent docstrings, plus an anchor path and a rappid whose sha
  is a dictionary-reversible hash *of the name*. Neutralised. A hardcoded
  private-agent roster moved to `$RAPP_EXTRA_PROJECT_AGENTS`.
- `rapp-god` — vendored copies synced **after** upstream, deliberately: the
  mono-repo import vacuums upstream trees wholesale, so a fix only here comes
  straight back on the next import. Exactly the Azure-key failure from the
  morning.
- `rapp-agents` — customer name in a test sentinel.

**Verification:** 14 previously-flagged public files re-read by content at
origin (not via the search index, which lagged ~10 min and reported 7 false
"still leaking"): **0 still leaking.**

### Two process failures worth recording

1. **I pushed RAPP-Bible past a NO-GO.** That scratch clone had no hook, and I
   chained `git push` after a gate call without checking its exit. The content
   was a *pre-existing* work-term, not a new leak, but the discipline failed.
   Hook installed; re-pushed clean.
2. **CI caught drift I had not tested.** I soaked the bundled *agent* but never
   the bundled *SKILL.md*. A `--bundle` export is a derived one-way projection
   and does **not** round-trip to itself. The invariant that does hold —
   now enforced over four routes and documented — is that every path out of a
   bundled export converges on the **byte-exact grail**.

### 🔴 Still open — Kody's call

- **`RAPP-Bible` CI will fail closed** until the roster is provided:
  `gh secret set PII_TERMS -R kody-w/RAPP-Bible`. That failure is by design.
- **`RAPP_EXTRA_PROJECT_AGENTS`** must be exported to restore the previous
  default twin-provisioning behaviour.
- **`aibast` / `WorkIQ` across ~18 more public repos** — not wiped. `aibast`
  is in public repo *names*; clearing it means renaming repos and rewriting
  cross-references. That is a structural decision, not a wipe.

---

## 6. EXHAUSTIVE PII sweep — final (supersedes §5's sampled numbers)

§5 reported a **sample** as if it were proof. Kody called it. Redone properly:
every public repo, full tree, tarball-streamed, no search index involved.

**Coverage: 371 public repos = 366 scanned + 5 empty (no default branch).**
**19,889 hits → 100% adjudicated via equivalence classes, 0 dropped.**

Two bugs in my own verification, both caught and fixed before reporting:
* `gh search code` silently truncates at 100 results — two terms were capped,
  and its index lagged ~10 min behind pushes. It is not a verification tool.
* The first classifier dropped **19,143 of 19,145 lines**: it split on 4 tab
  fields when the sweep emits 3, and `continue`d past everything. It now
  asserts `classified == parsed` and prints dropped samples, so a silent
  drop cannot recur.

| Term | Hits | Verdict |
|---|---|---|
| `aibast` | 19,532 | **Structural, not wipeable.** Azure RG names, public *repo names*, `microsoft.github.io` install URLs. |
| `WorkIQ` | 309 | Work-name. |
| `MSC` | 16 | **Benign.** `"carriers": ["Maersk Line", "MSC"]` in a supply-chain demo — a public shipping line, plus comments *about* word-boundary handling. A false-positive generator. |
| `Kunal` | 16 | **Real PII** — a colleague's name as an example speaker label. Fixed. |
| `kowildfe` | 14 | **Real PII** — see below. Fixed. |
| `RAPPtranscript2Prototype`, `bchydro` | 1, 1 | Fixed. |

I had reported `kowildfe` and `Kunal` as **zero public exposure**. Wrong, from
the truncated search. Both were public.

### 🔴 A captured authenticated M365 session was public in FOUR repos

`snapshot-1760370929454.html`, 30 MB of signed-in M365 DOM:
a real `@microsoft.com` identity (90x), a **JWK `cryptoKey` with A256GCM key
material**, **126 distinct tenant/directory GUIDs**, SharePoint tenant URLs,
`login_Hint`/`upn`/`oid`/`puid`. No bearer tokens.

Deleted, not sanitised — 30 MB of authenticated DOM cannot be reliably
redacted, because the identifiers you fail to match are the ones you did not
know to look for. Nothing loaded it at runtime.

| Repo | Status |
|---|---|
| `kody-w/rapp-shape-aibast` | removed, API-verified 404 |
| `kody-w/aibast-agents-library` (fork) | removed, API-verified 404 |
| `kody-w/rapp-god` (two vendored copies, different upstreams) | removed, 0 remain |
| **`microsoft/aibast-agents-library`** | **NOT TOUCHED — serving it publicly, HTTP 200** |

**Microsoft's copy is Kody's to escalate.** Iron law: never push to
`microsoft/*`. It must go through Microsoft's internal security process — a
public PR would advertise the leak. Contents verified by fetching their raw
URL: identical exposure.

Also still open: the blob remains reachable by SHA in the *history* of the
kody-w repos. HEAD is clean; history purge or privatisation is destructive and
was not done autonomously.

### Gate change: the denylist is now a RATCHET

Blocking any file containing a denylisted name walled off real PII fixes three
times — clearest case, `estate-map.json` must name `kody-w/aibast-agents-library`
**accurately**, so an undecided cleanup blocked a customer-name fix. The
denylist now fails only when a change **adds** occurrences; pre-existing debt
is reported. **Secrets are unchanged: fatal everywhere, no baseline.**

Denylist also grew 10 -> 16 entries (7 customer names it had never contained,
so every run since 07-18 passed them) and gained regex terms, because
enumerating separator spellings loses — `bc_hydro` slipped past while I was
adding `bchydro`/`bc-hydro`/`bc hydro` by hand.

### Toaster: raw bread

Kody's doctrine, now enforced: a capsule-less `SKILL.md` is **raw bread** and
cannot enter the loop — soaking it measures whether two renders agree, not
whether fidelity held. `toaster.py toast` is the normalising pass; `soak`
refuses raw bread. The first implementation silently no-opped (read vaults the
raw bytes, so render restored exactly what toasting meant to replace); the
idempotence check caught it.
