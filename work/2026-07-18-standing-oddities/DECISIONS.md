# 2026-07-18 — Standing oddities: recorded so intent stops being guesswork

Every item below is a **verified live fact** whose intent was previously
recorded nowhere. Status `NEEDS-KODY` = the tower found it, only Kody can
say whether it's deliberate. Adjudicating one = edit its status line here
(that edit is the decision record).

| # | Standing state | Evidence (2026-07-18) | Status |
|---|---|---|---|
| 1 | Production `:7071` runs as a **manual orphan** (parented to a zsh); `com.brainstem.server` plist exists but is not loaded and is launchd-disabled | `launchctl print-disabled gui/501`; triage.sh doctor | ✅ RESOLVED 2026-07-18 (Kody) — service was launchd-disabled; enabled + swapped orphan→supervised. :7071 now KeepAlive-supervised, survives reboot. |
| 2 | `com.brainstem.imessage_heartbeat` exits 2 every 900 s — **the only liveness alarm has been dead since ~Jul 7** | launchctl last-exit; only heartbeat logs in `~/.brainstem/logs` | ✅ RESOLVED 2026-07-18 — retired (script gone); plist in `~/.tower-retired-launchagents/`. Liveness now: dashboard `--watch` or a scheduled `triage.sh` probe. |
| 3 | `RAR` checkout deliberately(?) 278 behind / 130 dirty (orphaned build output ~Jun 27) | `git -C ~/Documents/GitHub/RAR status/log` | ✅ RESOLVED 2026-07-18 (Kody: reconcile) — origin already had the build output; backed up 130 files, reset to origin. Now synced+clean. |
| 4 | `:7073` **double-bound**: soak brainstem (127.0.0.1) shadows a work Azure-Functions host (`*:7073`, `~/MSFTAIBASTRAPP/RAPPtranscript2Prototype`); a second func host sits on `:7072` | triage.sh; lsof | RECORDED — FR-6 says never kill the other listener; loopback gets the brainstem |
| 5 | Flight `:7075` (canary) serving **unauthenticated, fallback model gpt-4o** since 15:42 | `/health` on :7075 | ✅ RESOLVED 2026-07-18 (Kody: stop) — :7075 flight stopped. |
| 6 | Flights `beta` and `canary-flight-project-twin` are **dead** (pids gone), logs still claim :7075 | triage.sh FLIGHTS section | ✅ RESOLVED 2026-07-18 (Kody: clean up) — dead flights beta + canary-flight-project-twin removed. |
| 7 | A **second brainstem runs from the grail checkout** on `:7082` (twin soul `twin-kody`, 5 agents, since Jul 18 12:52) — undocumented anywhere | triage.sh first run | ✅ RECORDED 2026-07-18 (Kody: leave it) — known twin experiment (twin-kody on :7082); left running. |
| 8 | Soak restarted today on canary `9506437` — **newer than attested** `25fcc8a` (run-29658720229); soak evidence for that attestation is void | release_gate.sh NO-GO | RECORDED — re-qualify or re-point soak before any release |
| 9 | Failing launchd agents: `com.kody.daily-summary` (exit 2), `com.kody.sonosite.sf-refresh` (exit 1), `ai.openclaw.gateway` (exit 1) | launchctl list | ✅ PARTIAL 2026-07-18 — `daily-summary` + `openclaw.gateway` retired (targets deleted/unbuilt). `sonosite.sf-refresh` KEPT — **NEEDS-KODY**: `sf org login web` (work cred, expired 07-07). |
| 10 | A **microsoft/**-repo self-hosted Actions runner runs persistently on this machine (`rapp-mac-runner`) | launchctl list | RECORDED — work/personal boundary surface; registry now names it |
| 11 | Canary tip `0c19941` has **moved past** the newest qualification (attested `25fcc8a`) | train.sh | RECORDED — normal DEVELOP motion; next qualification covers it |
| 12 | rapp-map baselines stale vs spec (estate-map/neurons 16 d, graph 34 d); repo count 92 vs 99 mismatch | drift.sh | ⏳ QUEUED 2026-07-18 (Kody: run it) — ecosystem-sync NOT run at session tail (capacity); run fresh next session. |

### Added by the round-2 security pass (2026-07-18 pm)

| # | Standing state | Evidence | Status |
|---|---|---|---|
| 13 | **LIVE LEAK**: `kody-w/localtoolsdev` (public) tracks a real `AZURE_OPENAI_API_KEY` in `my-agent-app/.env` | `gh api .../secret-scanning/alerts` = 1 open | ✅ RESOLVED 2026-07-18 — Kody rotated the key; Fable purged `my-agent-app/.env` from ALL history (force-pushed, 0 forks), gitignored, alert resolved/revoked (0 open). |
| 14 | A **live production Copilot token copy landed in the contested `rapp-canary` checkout** (`rapp_brainstem/.copilot_token`, gitignored, Jul 18 12:20) | secrets census | ✅ RESOLVED 2026-07-18 — stray token deleted from the canary checkout (FR-10). |
| 15 | Four **stale legacy `.copilot_token` files at mode 644** (world-readable) under `rapp-brainstem-beta` [PUBLIC], `RAPP-Private-Workspace`, `rapp2mcs`, `openrapp-desktop` | secrets census | ✅ RESOLVED 2026-07-18 — deleted (found **6** not 4: +`rappterverse`,`rappterbook` nested brainstems); only 3 legitimate mode-600 copies remain (prod/soak/active-flight). |
| 16 | `~/.claude/hooks/push-allowlist.txt` line 4 is a bare `github.com/kody-w/` prefix — with the guard's fixed-string match it re-authorizes **every** kody-w repo | direct read | 🗳️ PROPOSED 2026-07-18 (Kody: tighten) — 30+ repos actively pushed; recommend content-gate over repo-list. See work/2026-07-18-decisions-executed/push-allowlist-proposal.md — awaiting Kody's pick. |
| 17 | Two **contradictory trademark docs**: `rapp-train/TRADEMARKS.md` (Wildhaven LLC; "RAPP"/brainstem free) vs `RAPP/TRADEMARK.md` ((c) Kody; both claimed) | read both | ✍️ DRAFTED 2026-07-18 (Kody: Wildhaven LLC owns all) — reconciled RAPP/TRADEMARK.md at work/2026-07-18-decisions-executed/RAPP-TRADEMARK.reconciled.md; apply + record assignment. |
| 18 | Grail + all four ring repos are **public with no LICENSE** (all-rights-reserved) | `gh api .../license` | 🚂 PREPARED 2026-07-18 (Kody: Apache-2.0) — branch kody-w/rapp-canary @ add-apache-2.0-license; rides the train to your grail merge. |
| 19 | Self-hosted Actions runner for a `microsoft/*` repo = RCE on the root-of-trust laptop (also oddity #10) | launchctl | ✅ RESOLVED 2026-07-18 (Kody: decommission) — launchd agent stopped + retired (RCE surface inactive). GitHub-side ./config.sh remove pending. |

### Added by the brain-collapse leak-check (2026-07-18)

| # | Standing state | Evidence | Status |
|---|---|---|---|
| 20 | Public repo `kody-w/cowork-cookbook-rapp` contains work-data term **WorkIQ** 6× in its README | brain-collapse guard.sh | ✅ RESOLVED 2026-07-18 — NOT an exposure: WorkIQ used **nominatively** (Microsoft product name) with a trademark disclaimer, ZERO customer data. No scrub needed. Denylist flags the product *name*; real concern is customer *data*. |
| 21 | `rapp-second-brain-private` can't use GitHub secret-scanning (private, no GHAS) — tower `guard.sh` is its ONLY secret gate | gh api 422 | RECORDED — wire guard.sh into that repo's push path |
| 22 | Brain `leaktest.sh` redaction list ≠ tower denylist (WorkIQ slipped) | brain-collapse | NEEDS-BRAIN-TEAM — wire tower guard.sh into brain CI + public-repo-name allowlist |

### Added by the close-out estate secret sweep (2026-07-18)

The full `secrets-watch.sh` sweep found 3 MORE public leaks (all Google API keys,
open for months). Files wiped by Fable; keys need Kody's revocation.

| # | Standing state | Evidence | Status |
|---|---|---|---|
| 23 | `kody-w/mars-barn-opus` leaked a Google API key in a committed `.playwright-profile/` browser cache | secrets-watch #1 (2026-04-02) | ✅ FILE WIPED (dir purged from all 526 commits, force-pushed) — **NEEDS-KODY: revoke the key in Google Cloud Console + close the alert** |
| 24 | `kody-w/gemini-cli-tips` leaked a Google API key in `.claude/commands/gemini-power.md` | secrets-watch #1 (2025-11-26) | ✅ KEY REDACTED across all history (force-pushed) — **NEEDS-KODY: revoke + close alert** |
| 25 | `kody-w/TheMatrix` leaked a Google API key in `.knowledge-bases/kody-voice/QUICK_IMAGE_PROMPTS.md` | secrets-watch #1 (2025-11-21) | ✅ KEY REDACTED across all history (force-pushed) — **NEEDS-KODY: revoke + close alert** |

Note: the fast-parallel sweep variant returned a FALSE 0 (parallel gh calls that
errored counted as "no alert"). The sequential `secrets-watch.sh` is authoritative.

| 26 | `documents-to-copilot-studio` (private) hardcodes a client_secret in tracked static/app.js | round-2 | ✅ RECORDED 2026-07-18 (Kody: leave it) — accepted tracked secret in the private repo. |
