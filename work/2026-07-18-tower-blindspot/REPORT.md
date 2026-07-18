# 2026-07-18 — Tower blindspot: what mission control was missing

Method: 8 parallel readers grounded the live estate (rapp-map, canary
`.ring/`, rapp-train + live Pages, grail, RAR, live ports, GitHub census,
skills/automation); 7 expert lenses hunted gaps against that inventory;
16 merged findings each went through adversarial verification (a refuter
with file access tried to prove the gap already covered). **8 confirmed
GAP · 8 PARTIAL · 0 refuted.** Raw data: `FINDINGS.json`. Everything
buildable inside the tower was built the same day (see "Shipped").

## Build-now shortlist (was ≤5; the rest shipped today)

These are the items the tower **cannot** do for Kody — his accounts, his
call:

1. **Attach a Time Machine destination** — the laptop has zero
   machine-level backup; vault, 21 skills, plists, crontab, and 13 repos'
   disk-only commits all die with the SSD. Minutes now vs. weeks later.
2. **Give the Obsidian vault and `~/.claude` private origins and push**
   — "never public" ≠ "never pushed" (RECOVERY.md action items 2–3).
3. **Fix the phantom rollback docs via the train** — PLAYBOOK Scenario 10
   and RUNBOOK §5 prescribe `BRAINSTEM_VERSION=…`, which install.sh
   ignores; the only real syntax is `--version` (FR-3 holds the truth
   until the train delivers the doc fix).
4. **Harden grail branch protection** — `enforce_admins=false`, no
   required reviews: one stray admin push serves unqualified bytes to
   every installer. Flip it once, log it in `work/`.
5. **Decide the namespace one-way door** — declare `kody-w.github.io` a
   frozen permanent contract or move to a custom domain **now** (Pages
   custom domains keep old URLs redirecting; this is the only reversible
   moment). Same stroke: branch-protect + tag the trademark-evidence
   repos.

## Ranked findings (verified verdicts)

| # | Finding | Class | Verdict | Closed by |
|---|---|---|---|---|
| 1 | `:7071` is an orphan process; supervisor disabled; the only liveness alarm dead since Jul 7 | silent-killer | PARTIAL | `triage.sh` doctor section, FR-1; heartbeat disposition → standing-oddities |
| 2 | Sole-copy production memory unbacked since Jun 4, inside the recovery blast radius | one-way-door | PARTIAL | `backup-memory.sh` (**first backup made today**), FR-7, registry warning |
| 3 | Laptop has zero backup; vault/skills/plists die with it | spof | GAP | `backup-status.sh`, RECOVERY.md; **shortlist 1–2 are Kody's** |
| 4 | One push bypasses the grail gate; push-URL re-neuter has no tripwire | missing-control | GAP | `checkouts.sh` tripwire, FR-2, GO-NOGO C1; **shortlist 4 is Kody's** |
| 5 | Public rollback lever documented in 2 places, implemented in 0 | silent-killer | GAP | FR-3 (true syntax); **shortlist 3** rides the train |
| 6 | Nothing pins the runtime (range deps, no lockfile, unpinned brew python) | silent-killer | PARTIAL | recommendation only — constraints.txt must ride the train; brew pin is Kody's machine call |
| 7 | grail_gate has no containment check — mechanically stages the hotfix silent-revert | silent-killer | GAP | `release_gate.sh` (containment **PASSes today** — verified live) |
| 8 | Service display shows port-open, not identity/auth — all four booleans misleading | silent-killer | PARTIAL | `triage.sh` (first run found `:7082` second brainstem, dead flights, `:7072`/`:7080` unregistered) |
| 9 | Publishing boundary has no machine denylist; the public one checks a synthetic name | missing-control | GAP | `sensitive/denylist.json` + `leakcheck.sh` + FR-9 |
| 10 | Pages-live vs origin parity invisible; blocked deploys freeze installers silently | missing-control | PARTIAL | `pages.sh` (all six surfaces LIVE-CURRENT today) |
| 11 | Soak evidence never reaches the gate — RELEASE can run on bytes that soaked 0 days | missing-control | GAP | `release_gate.sh` (**honest NO-GO today**: soak on 9506437, attestation on 25fcc8a) |
| 12 | No holds/handover between parallel sessions; PLAYBOOK Scenario 3 tells sessions to collide | missing-control | GAP | `holds.sh` + checkouts integration; PLAYBOOK amendment rides the train |
| 13 | Permanent identity (URLs, trademark evidence) on an unprotected personal account | one-way-door | PARTIAL | **shortlist 5 is Kody's** — record the decision either way |
| 14 | No train-position board | missing-control | PARTIAL | `train.sh` (live: nightly/alpha/beta ATTESTED, canary MOVED past run-29658720229) |
| 15 | Decision log has zero entries — intent indistinguishable from accident | erosion | GAP | this report + standing-oddities seed + TEMPLATE-decision.md + CLAUDE.md must-log rule |
| 16 | Drift governance reports to nobody while its own baselines drift | erosion | PARTIAL | `drift.sh` (live: oracles green, 1 open drift issue, nearest waiver 88d, all 3 baselines STALE, 92-vs-99 confirmed) |

## Already covered (checked, solid — why the rest is believable)

- **Attestation chain integrity**: `ring_attestation.py` sha256 payload
  chaining + `grail_gate.py` beta-tip re-verification — sound; the gaps
  were *around* it (soak, containment), not in it.
- **Ring identity rendering**: rewrite-count oracles (26/70/2) +
  zero-remaining check in `render_ring.py`; publish-pages.yml is
  drift-oracle gated.
- **Promotion safety**: `promote_ring.py` refuses non-parent edges, grail
  edge, dirty trees, FLIGHT.json poison pills.
- **Drift machinery itself**: conformance golden suite (8 mechanical
  classes), waiver ledger with canon-pinning + freshness watchdog, weekly
  standing-guard — running and green; it just had no audience (now:
  `drift.sh`).
- **Recovery paths are state-preserving by design**: install.sh's
  re-clone path backs up `.brainstem_data`; `brainstem-reset` middens
  rather than wipes; the verifier corrected finding 2's blast-radius
  claim accordingly.
- **A verified one-command restart exists**: `~/.local/bin/brainstem`
  (correct cwd, venv, dep check) — FR-1 now records it.

## One-way doors closing soon (decide deliberately, even if "keep as is")

- **Namespace/domain** (shortlist 5) — reversible only while the
  installed base is small.
- **Launchd supervisor**: enabling `com.brainstem.server` unverified is a
  new failure mode; leaving it disabled is a standing decision — either
  way, log it (standing-oddities has the facts).
- **Denylist governance**: every new customer name gets added the day it
  first appears; removals are `work/` decisions.
- **Waiver r3-04** expires 2026-10-14 (88d) — `drift.sh` counts it down.

## Shipped today (all live-verified on this machine)

`tools/triage.sh` · `tools/train.sh` · `tools/pages.sh` ·
`tools/release_gate.sh` · `tools/backup-memory.sh` (+ first real backup:
`~/Backups/rapp-brainstem/brainstem-state-20260718-163025.tar.gz`) ·
`tools/backup-status.sh` · `tools/drift.sh` · `tools/holds.sh` ·
`tools/leakcheck.sh` + `sensitive/denylist.json` · upgraded
`tools/checkouts.sh` · `FLIGHT_RULES.md` · `GO-NOGO.md` · `RECOVERY.md` ·
this decision log.
