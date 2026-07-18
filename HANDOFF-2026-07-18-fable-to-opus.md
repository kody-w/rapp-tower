# HANDOFF — Fable 5 → Opus, 2026-07-18 (late)

You are taking over mid-stride. This doc + `CLAUDE.md` + `FLIGHT_RULES.md`
are your boot sequence. Everything below was true at handoff; **re-derive
live state before acting on any SHA or run-id** — parallel sessions were
active all night and the train moves.

## First 10 minutes

1. Read `CLAUDE.md` (command brief), `FLIGHT_RULES.md` (FR-1…FR-10), this doc.
2. Run `tools/checkouts.sh` and `tools/triage.sh` — situational truth.
3. **Auto-memory does NOT load here.** The estate's memory lives at
   `~/.claude/projects/-Users-kodywildfeuer--brainstem-src/memory/` —
   read `MEMORY.md` there manually; it indexes ~75 hard-won lessons.
4. The public map: https://kody-w.github.io/rapp-train/ (deck) →
   PLAYBOOK.md (13 scenarios) → llms.txt (machine entry).

## What exists (all live-verified tonight)

- **The train**: canary→nightly→alpha→beta→(human-only)grail. Hub =
  rapp-canary `.ring/` (promote, qualify, attest, grail_gate, soak).
  Grail main is branch-protected; local grail push URLs are neutered.
- **Flight deck**: per-ring Pages serve RENDERED identity installers;
  flight.sh sandboxes any ring/branch; VM one-liner tests green on 3 OSes.
- **Shape Yard**: RAPP@shape/next + rapp-shape-aibast rehearse deliveries;
  finding→fix-upstream→re-rehearse loop proven (2 real finds, both fixed).
- **rapp-holo/1.0**: the |||HOLO||| projection standard (kody-w/rapp-holo);
  reference VUI on flight branch `feature/voice-gesturepad` (served at
  /vui, port 7076 locally now). Verified end-to-end minus camera gestures.
- **IP/brand layer**: TRADEMARKS.md (compound marks owned by **Wildhaven
  Homes LLC** — exact name matters; stem + Brainstem deliberately free),
  brand.html (+ The Line), quality-control clause, Apache-2.0/CC-BY-4.0
  licensing. Mission: **"No dream deferred."** → thesis: every person and
  every AI, working productively — together → vehicle: RAPP.

## In flight — your likely work queue

1. **v0.6.17 grail release, parked at the gate.** Beta has moved since the
   last qualification — run a FRESH qualification (RUNBOOK §3) on current
   mains, then `grail_gate.py`, then the ephemeral release-day rehearsal
   (PLAYBOOK Scenario 9) before Kody's human merge. Never trust tonight's
   run-ids; mint new ones.
2. **VUI flight merge** — complete and verified except the camera path
   (needs Kody's webcam + hands). Seam decision RESOLVED (see
   `work/2026-07-18-holo-aibast-seam/`). Merge to canary only when Kody
   says; then it rides normally.
3. **aibast PR #16** (v0.6.16 sync) still open on microsoft's repo —
   sequencing vs v0.6.17 is an open decision (merge #16 first, or
   supersede with a fresh sync from the tag after v0.6.17).
4. **Canary issues #3/#4/#5** — Models-API auth fallback (platform-
   existential), community-agent trust model, installer signing. Real
   engineering; enters at canary like everything.
5. **Human-only queue** (do not do these; remind, don't nag): patent .ics
   one-click import (Apr 5 2027 hard deadline), hardware keys on kody-w,
   counsel items in wildhaven-ceo `action-items.md`, VUI camera test.

## The rules that will save you (cost of learning them: one night)

- **Never push to kody-w/rapp-installer or microsoft/anything.** Grail
  changes ride the train. Period.
- **AIBAST is Microsoft's distro of the Brainstem.** Never write words
  implying ownership/authority/grants toward it — disclaimer only. Public
  wording is NEVER defensive/cynical: same facts, confident-host register
  (blunt doctrine stays in tower/vault).
- **Scratch-clone pattern** for canary/RAPP/anything contested — parallel
  sessions hold the shared checkouts. Check `tools/holds.sh`.
- **Red oracles are the system working** (preflight, rewrite-count drift
  — recount lives in RUNBOOK, attestation, gate). Fix upstream; never bypass.
- **Ring installers are Pages-only**; raw URLs carry grail identity.
- **/chat response field is `response`** (not assistant_response).
- **Creative mandate**: Jobs-as-influence taste lens, build autonomously,
  never copy; canon in memory file `feedback_creative_direction_avatar.md`.
  Hughes' "Harlem" is referenced, never reproduced (copyright).
- **Done means done**: exercise the live artifact, cite run URLs and SHAs.
  Kody demos this in front of people — a false "done" is the cardinal sin.

## Where evidence lives

Qualification chains: canary `.ring/attestations/`. Decisions: tower
`work/`. CEO/legal: `kody-w/wildhaven-ceo` (Molly is non-technical — plain
English there). Ports: 7071 prod · 7073 soak · 7075/7076 flights.

Carry it well. The mission is three words.

## The other half of the baton (added 2026-07-18, second Fable session)

This doc is the ESTATE/TRAIN half. The CUSTOMER/WORK/DOCTRINE half lives in the
one brain: `~/SecondBrain/wiki/syntheses/opus-takeover-2026-07-18.md` — read it in
the same first 10 minutes. It carries: the post-Fable doctrine reshape (Opus =
cortex+spine, Sol REFUTE-review mandatory, novel canon → precedence chain → Kody),
the Kody-only pending calls (testament minting, FSI qa-gate, FY27 packet send,
Scout RFC go, RED BINDER successor conflict, docket D4), and the drivable work
queue (t2p security-review fix pass is the first commission). The brain itself
(`~/SecondBrain`, 106 pages, index-first, local-only) is the map of Kody's whole
work world — customers, engagements, contradiction ledger, people. Auto-memory in
home-dir sessions points there; in THIS workdir it does not auto-load — read both
memory estates manually.
