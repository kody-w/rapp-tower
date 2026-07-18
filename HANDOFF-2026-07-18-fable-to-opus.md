# HANDOFF — Fable 5 → Opus, 2026-07-18 (late)

You are taking over mid-stride. This doc + `CLAUDE.md` + `FLIGHT_RULES.md`
are your boot sequence. Everything below was true at handoff; **re-derive
live state before acting on any SHA or run-id** — parallel sessions were
active all night and the train moves.

<!-- ═══════════════════════════════════════════════════════════════════════ -->
## 🔴 NEWEST (final Fable session, 2026-07-18 pm) — security pass + a LIVE LEAK

**Do this before the train work below.** A second-round blindspot swept the
domains the estate had never audited (supply-chain, autonomous-AI safety,
community-agent trust, legal/IP, forensics). One item is time-critical:

- **LIVE SECRET, PUBLIC RIGHT NOW**: `kody-w/localtoolsdev` is **public** and
  git-tracks `my-agent-app/.env` with a **real `AZURE_OPENAI_API_KEY`**
  (+ `AZURE_WEBJOBS_STORAGE`), since its first commit. GitHub secret-scanning
  has **1 open alert** (verified). NOT remediated autonomously — **Kody must
  rotate the Azure key first** (portal), then `git rm --cached` the file,
  purge history or make the repo private, close the alert. Same class, lower
  urgency: `documents-to-copilot-studio` hardcoded client_secret; four stale
  mode-644 `.copilot_token` files; dead sonosite SF token (since 07-07).

- **Built + committed this session (all tested)**: `tools/guard.sh` (content
  gate — secrets + denylist + secret-filenames; the gate that would have caught
  localtoolsdev), `tools/secrets-watch.sh` (sweeps open secret-scanning alerts
  estate-wide — run it to see the leak), `tools/fleet.sh` (autonomous-writer
  board + kill switch; 4 writers failing silently now). **Enabled
  secret-scanning + push-protection on `kody-w/RAR`** (was the only repo with
  both off). Plus `SECURITY.md` + `work/2026-07-18-legal-posture/`.

- **Your live queue** (priority): (1) **wire `tools/guard.sh` into the push
  paths** — `~/.claude/hooks/git-push-guard.sh` and `RAPP/tools/sim/push_canvas.sh`
  (gate built, nothing calls it yet; Kody-review — a wrong wiring blocks a wave).
  (2) Tighten `~/.claude/hooks/push-allowlist.txt` line 4 (bare `github.com/kody-w/`
  re-authorizes EVERY kody-w repo, defeating the allowlist). (3) `fleet.sh`
  dead-man alerting. (4) RAR license audit (the "127 Microsoft files" claim was
  **overclaimed** — my check found 0; don't assert it).

- **Kody-only, from this pass**: rotate the leak key; decommission/relocate the
  self-hosted Actions runner (= RCE on this root-of-trust laptop); **reconcile
  the trademark contradiction** — `rapp-train/TRADEMARKS.md` (Wildhaven Homes
  LLC; deliberately does NOT claim "RAPP" or "brainstem") vs `RAPP/TRADEMARK.md`
  ((c) Kody personally; DOES claim both) — the public self-contradiction can void
  the marks; license the grail + rings (today all-rights-reserved); decide the
  agent capability-boundary one-way door before more third-party agents ship.

**Full detail + verdicts (7 confirmed / 5 partial / 2 refuted, adversarially
verified):** `work/2026-07-18-tower-blindspot-r2/{HANDOFF.md,FINDINGS.json}` and
`SECURITY.md`. Trust those verdicts over raw findings — two lens claims were
overclaimed/refuted and are corrected there. **Do not re-run the blindspot.**
<!-- ═══════════════════════════════════════════════════════════════════════ -->

## First 10 minutes

0. **Read the 🔴 NEWEST block above first** — it has a live public secret leak.
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
6. **`fix/probe-pytest` (rapp-canary) — verify + merge.** `device_probe.sh`
   ran pytest in the install venv, which the sacred installer never populates
   with pytest → FALSE fail on every real machine (mis-read earlier as an
   auth-required test — it is NOT; fresh-clone credential-less container = 261
   passed). Fix pip-installs pytest first, skips cleanly if offline. Pushed,
   NOT merged. Container `rapp-probeverify` was verifying end-to-end at handoff:
   `docker logs rapp-probeverify` → if the two suite checks PASS, `git merge
   --no-ff fix/probe-pytest` to canary main, watch preflight.

**Also landed this session (device / twin / landgrab):** zero-config
`device_probe.sh` (pull-mode device testing → reports to a GitHub issue;
self-hosted runner push-mode retired) — merged to canary main. Flight-deck
port-collision false-✅ fixed (merged; `rapp-train#1` filed for its diverged
copy). `flight/project-twin` = `.twin/` project-resident AI twins over `/chat`
(`twin.sh` + `TwinConnector`; canary-twin verified live on :7091; keeps
`FLIGHT.json` — never merge to main). **Now has PUBLIC/PRIVATE layers**
(commit `1e596cb`): public `.twin/` (soul, agents, seed memories) travels &
commits; `.twin/private/` (gitignored, on-device) layers over it —
`private/soul.md` appended to public soul, `private/agents/*.py` override
public, learned memory in `private/engine/`. Verified: private marker layered
in, `.twin/private/` confirmed gitignored (won't travel). Battlestation reachable via
`ssh kodysbattlestation` (localadmin, keyed — **no VNC needed**); real Windows
join one-liner verified serving v0.6.16. **Landgrab:** 15 public `rapp-*` repos
(brainstem, twin, twin-in-residence, flight-deck, flight, rings, cortex,
spinal-cord, nervous-system, hippocampus, sdk, cli, docs, trademarks, platform)
— clean Apple-style branding (**one fine-print ™ line, NEVER ™-per-mention —
Kody emphatic**), each carrying `DISCLAIMER.md` + MIT `LICENSE`; usage policy
live on public `rapp-trademarks`. `kody-w/rapp-ip` (PRIVATE) = builder IP
portfolio. `wildhaven-ceo/rapp-brain/` = CEO second brain + `skill.md` (Molly
uses it by asking plain questions) + `today/rapp-deadlines.md` (3 calendar
events STAGED — Google Calendar OAuth expired, needs Kody reconnect). Full
delta: rapp-canary auto-memory `session-handoff-2026-07-18.md`.

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

## Addendum — from the twin-molding session (537685c3, injected 2026-07-18)

The sections above are the tower session's baton; this thread is yours too:

- **Kody's digital twin v2 is LIVE** — child brainstem on localhost:7082, soul at
  `~/.brainstem/twins/twin-kody/soul.md` (sha256 b2b7575a…edf11) plus
  `agents/kody_record_agent.py` (KodyRecord: every factual Kody-claim grounds there
  or the twin says "my record doesn't cover that"). Copies byte-identical: local cubby
  `~/.brainstem/cubbies/twin-kody-2026-07-17/` and PRIVATE `kody-w/rapp-batcave`
  at `cubbies/kody-w/cubbies/twin-kody/`. Standing order from Kody: **"keep molding"**
  as the brain grows — ritual + corrected script: `~/SecondBrain/wiki/syntheses/mold-twin-ritual.md`.
  Two paid-for lessons: Workflow-tool args DIE after the first await (hardcode literals);
  null-guard every lens result. Promotion bar: 3 lenses ≥9 + zero failures + leak-grep;
  tumble ONLY staging :7084 — never the live instance, never :7071/:7073 (soak).
- **The canon gate**: `~/SecondBrain/wiki/syntheses/maintainers-exam.md` — 100 questions,
  key sha-sealed (c18fa884…); pass = ≥90 with zero misses in identity + publishing before
  unassisted canon work. Never administered; first administration = rehearsal 0002.
- **fable-last-days campaign remainder** (tracker: `~/.claude/wow-ledger.md`): open —
  full-Constitution contradiction adjudication (D8 protocol), public estate one-pager
  beside the Lexicon, Art LII.2 litigation with Sol (pre-ruled D3), model race →
  capability frame, FY27 pre-mortem (work domain). Parked on Kody's word only:
  testament mint (drafted — the last day is now), D4 M365 git-history exposure
  (do-not-wait), commons rappid:v3 (D1), twin §12.1 re-genesis (master keys, D2).
- **Capacity**: Fable's spend limit tripped 2026-07-18 mid-molding. You are metered;
  the CSM muscle discipline (Sol builds, you gate with hands on real artifacts) is how
  this stays affordable.

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

---

## ✅ FINAL STAMP — Fable session closed clean (2026-07-18, last act)

- **The Azure key: Kody explicitly deprioritized it ("I don't care about the
  key"). DO NOT re-raise or nag — treat as accepted risk unless he brings it
  up.** The alert link stays in the red block for whenever he wants it.
- Full estate 200-sweep at close: deck, PLAYBOOK, TRADEMARKS, brand, llms.txt,
  flight.sh, all five ring/grail installers, rapp-holo spec — ALL SERVING.
- Unpushed-work sweep: every touched clone ahead=0; RAPP@shape/next local ==
  remote; only intentional local-only files remain (CLAUDE.local.md stubs).
- Trademark surfaces aligned to the one-fine-print-™ convention (partial —
  reconcile fully during the RAPP/TRADEMARK.md contradiction fix).
- Micro-finding for the next sync rehearsal: a run in the aibast-shape tree
  left `rapp_brainstem/.brainstem_secret` UNTRACKED-not-ignored — verify the
  synced .gitignore actually covers it in that shape (grail f3a2c9c intent).
- Soak :7073 and the VUI flight :7076 left serving on purpose (camera test
  pending). Scratchpad clones die with the session; all their work is pushed.

Fable out. The mission is three words.
