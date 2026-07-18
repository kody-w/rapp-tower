# CLAUDE.md — the RAPP Control Tower

> **The mission: no dream deferred.** The thesis: every person and every AI, working productively — together. The vehicle: RAPP.

This repo is **mission control for the entire RAPP ecosystem**. Sessions land
HERE for cross-ecosystem work. Nothing in this repo ships to users; it exists
so full-scale AI-first work never has to squat inside a production checkout.

**The prime directive: command the railroad from the tower, never from the
tracks.** Operate on other repos via fresh scratch clones (below), not by
editing shared checkouts in place.

## The estate at a glance

- **Estate map (LOAD for estate-wide reasoning)**: kody-w/rapp-map — `estate-map.json` + `neurons.json`
- **The train (release vehicle)**: deck https://kody-w.github.io/rapp-train/ · PLAYBOOK https://kody-w.github.io/rapp-train/PLAYBOOK.md · machine entry https://kody-w.github.io/rapp-train/llms.txt
- **Train ops**: RUNBOOK at kody-w/rapp-canary `.ring/RUNBOOK.md` (five verbs); topology in `.ring/train.json`
- **Interaction standard**: kody-w/rapp-holo (`rapp-holo/1.0` — |||HOLO||| projections; VUI = surfaces)
- **Vocabulary**: https://kody-w.github.io/rapp-train/TRADEMARKS.md (Wildhaven Homes LLC; integration self-licenses)

## Local checkout registry (roles + touch rules)

| Path | Repo | Role | Rule |
|---|---|---|---|
| `~/.brainstem/src` | kody-w/rapp-installer | THE GRAIL — live production install | READ-ONLY. Push URL is `DISABLED-…` on purpose; `checkouts.sh` red-banners if not (FR-2). **LIVE SOLE-COPY STATE inside** (`.brainstem_data/`, plus `~/.brainstem/twins/`, `cubbies/`) — `tools/backup-memory.sh` before ANY surgery (FR-7); never rm/re-clone/reset |
| `~/Documents/GitHub/rapp-canary` | kody-w/rapp-canary | Train entry ring + hub tooling | Contested by parallel sessions — treat as read-only reference; do branch work in scratch clones |
| `~/Documents/GitHub/rapp-{nightly,alpha,beta}` | rings | Promotion targets | Only ever receive `promote_ring.py` output |
| `~/Documents/GitHub/RAPP` | kody-w/RAPP | Reference distro (lts) | Often carries another session's WIP **and a cron writer every 30 min** (`tools/sim/loop_orchestrator.sh`) — dirty ≠ session; scratch-clone for changes; `shape/next` branch = Beta siding |
| `~/Documents/GitHub/RAR` | kody-w/RAR | Agent registry — THE active checkout | `~/RAR` is stale; never touch it. Dirty/behind state is deliberate-until-adjudicated (standing-oddities #3) |
| `~/Documents/GitHub/rapp-map` | kody-w/rapp-map | Estate map + drift governance (spec mirror, neurons, conformance, waivers) | Normal edits fine; `tools/drift.sh` reads it |
| `~/Documents/GitHub/aibast-agents-library` | kody-w fork of microsoft/… | Work sync vehicle | PRs to Microsoft are MANUAL (SAML); never push microsoft/* |
| `~/Documents/GitHub/rapp-train` | kody-w/rapp-train | Deck + playbook + llms.txt | Normal edits fine |
| `~/Documents/GitHub/rapp-tower` | kody-w/rapp-tower | THIS repo | Work products in `work/YYYY-MM-DD-topic/` |

Live local services — **port-open ≠ healthy; identity/auth via
`tools/triage.sh`**: production brainstem `:7071` (manual orphan launch —
restart is `~/.local/bin/brainstem`, FR-1) · canary soak `:7073`
(`~/.brainstem-soak/render/`, double-bound with a work Azure-Functions host
on `*:7073`; a second func host on `:7072` — FR-6, never kill listeners you
didn't start) · flights from `~/.rapp-flight/` on `:7075+` (four flights
exist; some dead) · local branch flights (`.ring/tools/flight.sh`) default
`:7081+` · parallel sessions/experiments hold more ports (`:7082` has run a
second brainstem from the grail checkout). Two scripts are both named
`flight.sh` — `.ring/tools/` (local branch flights) vs `.ring/pages/`
(public sandbox flights); don't confuse them.

## The iron laws (non-negotiable)

1. **Nothing pushes to the grail** (kody-w/rapp-installer) or to microsoft/*.
   Grail changes ride the train: branch on canary → preflight → promote →
   qualify → `grail_gate.py` → Kody's human merge.
2. **Everything enters at Canary**; outer rings receive promotions only.
3. **Scratch-clone pattern** for any contested/production checkout:
   `git clone -q --branch <b> https://github.com/kody-w/<repo>.git "$SCRATCH/<name>"`,
   work there, push the branch, dispose. Never fight another session for a
   shared worktree.
4. **Red oracles are the system working** (preflight, rewrite-count drift,
   attestation chain, gate). Diagnose upstream; never bypass.
5. **Ring installers are only correct from Pages URLs** — raw URLs carry
   grail identity by design.
6. **Drive the brainstem via POST localhost:7071/chat** — capabilities are
   agents through `/chat`, never new REST routes.
7. **Publishing boundary**: this repo is PRIVATE — work/customer context may
   land here, but never flows from here into public kody-w repos.

## Flight rules & release polls

- **`FLIGHT_RULES.md`** — pre-decided if-then for emergencies (loss of
  brainstem, grail push-capable, bad version shipped, red oracle, contested
  checkout, port conflicts, pre-demo reds, publishing boundary). Read it
  before improvising under pressure.
- **`GO-NOGO.md`** — grail-release poll + post-release closeout. Copy into
  `work/` per release; `tools/release_gate.sh` must say GO before
  `grail_gate.py --export-to`.
- **`RECOVERY.md`** — if this laptop dies: what survives, what doesn't,
  ordered restore.

## Tower tools (the situational displays)

- `tools/checkouts.sh` — one-screen checkout truth + grail push tripwire +
  memory-backup age + holds.
- `tools/triage.sh` — service **identity/health/auth** per port (not just
  LISTEN), flights, brainstem doctor with the verified restart command.
- `tools/train.sh` — train position: per-ring tip/VERSION/lock/attestation
  with ATTESTED / MOVED / NO-ATTN verdicts.
- `tools/pages.sh` — Pages-live vs origin parity per public surface
  (LIVE-CURRENT / LIVE-BEHIND / DEPLOY-RED); byte-check for rapp-train.
- `tools/release_gate.sh` — pre-release GO/NO-GO: grail-main containment +
  soak-evidence checks; `--override` requires a decision record and still
  exits non-zero.
- `tools/drift.sh` — drift-governance surface: oracle conclusions, open
  drift issues, waiver countdowns, baseline staleness.
- `tools/backup-memory.sh` / `tools/backup-status.sh` — sole-copy state
  archiver (step 0 of any brainstem surgery) + machine durability board.
- `tools/holds.sh` — parallel-session holds: `claim/release/list/check`
  (state in `.tower/`, gitignored). Claim before touching a contested
  checkout, a ring, or a release window; release on handover.
- `tools/leakcheck.sh` + `sensitive/denylist.json` — the publishing-boundary
  gate (FR-9). Run against any tree headed for a public repo. The denylist
  is private-canonical; it never leaves the tower.

## Work products & the decision log

Cross-repo plans, audits, reports, drafts: `work/YYYY-MM-DD-<topic>/`.
Commit them — the tower's history is the ecosystem's decision log.

**Three event classes MUST get a `work/` entry** (template:
`work/TEMPLATE-decision.md`): ring promotions/qualifications/releases;
anything touching the grail or its runtime (launchd, tokens, push URLs);
any "leave it broken/stale on purpose" call. Standing intentional oddities
live in `work/2026-07-18-standing-oddities/` — adjudicate there, don't
re-derive intent from forensics.
