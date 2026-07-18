# HANDOFF — round-2 blindspot, mid-execution (2026-07-18)

**Written for the session that takes over (Fable capacity ending).** This is
the single source of truth for continuing. Everything below is either DONE
(committed) or a precise next step. Ground facts were verified live; where a
lens agent overclaimed, the correction is noted — do not act on the raw
`FINDINGS.json` without reading the verdict column here.

## 🔴 ACTIVE INCIDENT — do this first, it is not optional

**A live Azure OpenAI API key is public right now.**
- Repo `kody-w/localtoolsdev` is **public** and git-tracks `my-agent-app/.env`
  containing a real `AZURE_OPENAI_API_KEY` (+ `AZURE_WEBJOBS_STORAGE`), in
  history since the first commit. **GitHub secret-scanning shows 1 open alert**
  on it (verified via `gh api repos/kody-w/localtoolsdev/secret-scanning/alerts`).
- **Only Kody can fully remediate** (rotate = Azure portal). The rewrite/privatize
  steps are consequential and were deliberately NOT done autonomously.
- **Runbook** (Kody, in order): (1) **Rotate** the Azure OpenAI key in the Azure
  portal — the leaked value is burned regardless of anything else. (2) Remove the
  file from the repo (`git rm --cached my-agent-app/.env`, add to `.gitignore`,
  commit). (3) Purge history (`git filter-repo` or BFG) OR — simpler and safer —
  make the repo **private** if it has no reason to be public. (4) Close the
  secret-scanning alert. (5) Rotate `AZURE_WEBJOBS_STORAGE` too.
- **Same class, lower urgency** (from the secrets reader, verify before acting):
  `kody-w/documents-to-copilot-studio` (private) hardcodes a client_secret in
  tracked `static/app.js`; four stale legacy `.copilot_token` files at mode 644
  (world-readable) under old checkouts (`rapp-brainstem-beta` [PUBLIC],
  `RAPP-Private-Workspace`, `rapp2mcs`, `openrapp-desktop`) — delete + confirm
  revoked. `com.kody.sonosite.sf-refresh` Salesforce token dead since 2026-07-07
  (157 failures; work/customer credential — re-auth `sf org login web`).

## DONE this session (committed to the tower)

**Tools built + live-verified** (all run clean; see each file's header):
- `tools/guard.sh` — CONTENT gate (secrets + denylist + secret-filenames) for
  any tree bound for a public repo. This is the gate that would have caught
  localtoolsdev. Tested: clean fixture rc=0, planted `.env` rc=1.
- `tools/secrets-watch.sh` — sweeps OPEN GitHub secret-scanning alerts across all
  kody-w repos + flags public repos with scanning disabled. Ends "alerts fire
  into a void." **Run this to see the localtoolsdev alert.**
- `tools/fleet.sh` — autonomous-writer board: 9 writers, live state, per-writer
  kill command, `--freeze` prints the stop list. Verified: correctly shows 4
  FAILING writers + flags the public pusher / work-token / RCE-runner.

**Estate change executed** (protective, reversible, logged here):
- **Enabled secret-scanning + push-protection on `kody-w/RAR`** — it was the one
  repo with both OFF, and the highest-volume autonomous-write target. Verified on.

## Verified findings (7 confirmed · 5 partial · 2 refuted)

Raw data: `FINDINGS.json`. Verdicts are the workflow's adversarial pass PLUS my
own direct checks. `fixOwner` decides who can close it.

### Confirmed GAPs
| # | Finding | Owner | Status here |
|---|---|---|---|
| 2 | Secret-scanning alerts fire into a void — the localtoolsdev key sat open | tower | **`secrets-watch.sh` built**; leak → Kody runbook above |
| 3 | Production Copilot token is non-expiring, has no refresh_token, and any loaded agent can read it off disk; zero abuse-detection | kody | See SECURITY.md; needs a Copilot-usage review + token hygiene decision |
| 4 | Self-hosted Actions runner (`microsoft/RAPPtranscript2Prototype`) = anyone with repo-write gets **code execution on the root-of-trust laptop** | kody | Decommission or move off this machine; documented in SECURITY.md |
| 6 | Deps range-pinned not hash-pinned; `_auto_install` pip-installs package names parsed from a community agent's failed import (dependency-confusion) | train | Spec in SECURITY.md; ride canary→grail |
| 8 | Installer everyone runs is **unlicensed** — grail + all 4 rings public with NO LICENSE (verified: rapp-installer, rapp-canary = none) | train | See legal DECISIONS; add LICENSE via the train |
| 9 | One-way door: full-trust agent contract already has real third-party dependents; sandboxing later breaks published agents | kody | Decide the capability-boundary direction NOW (SECURITY.md) |
| 14 | Built-in support channel is a black hole: 9 unanswered help requests incl. 2 real external users since April | tower | Needs a triage + a real channel; not yet built |

### Partial (adjacent mitigation exists; failure still lands)
| # | Finding | Owner | Note |
|---|---|---|---|
| 1 | Install/update path execs unsigned code; only checksum in the system guards `soul.md` (non-executable) | train | Real; supply-chain hardening spec in SECURITY.md |
| 5 | No secret/PII gate on autonomous public-push paths | tower | **`guard.sh` built**; still must be WIRED into push paths (next steps) |
| 10 | "RAR strips MIT from 127 Microsoft files" — **OVERCLAIMED**: my check found 0 Microsoft-copyright files in RAR working tree | tower | Downgraded to "run a real license audit"; do NOT assert the 127 number |
| 11 | No fleet kill switch / dead-man alerting | tower | **`fleet.sh` built**; wire dead-man alerting next |
| 12 | Day-2 death: installer runs server foreground-only, no service, no restart docs | train | Same root as r1 FR-1; fix rides train |

### Refuted (do not act)
- **#7** `/agents/import` opt-in integrity — verifier REFUTED; brainstem enforces
  integrity on the real path. (My raw read of `if expected_sha256:` looked opt-in;
  the verify pass found the enforced path. Trust the refutation.)
- **#13** model-picker unreservable-models retry ladder — REFUTED.
- Also refuted by MY direct checks (not in the workflow's refuted list, correct here):
  the "leaked key alert since May 8" **date** was wrong (0 alerts on the repos I
  checked; the real open alert is on localtoolsdev, undated-by-me); the
  "push-guard neutered" is real but see below.

## NOT DONE — next steps, in priority order

1. **Wire `guard.sh` into the push paths** (the tower built the gate; nothing calls
   it yet — finding #5). Two integration points, both Kody-review because they
   change live automation:
   - `~/.claude/hooks/git-push-guard.sh` (the WHERE gate) → add a call to
     `guard.sh` on the pushing repo as a WHAT gate before allowing a public push.
   - `RAPP/tools/sim/push_canvas.sh` (the sim loop's public pusher) → `guard.sh`
     the canvas dir before push; abort on rc=1.
2. **Tighten `~/.claude/hooks/push-allowlist.txt`** — line 4 is a bare
   `github.com/kody-w/` prefix that (with the guard's `grep -qF` match)
   re-authorizes EVERY kody-w repo, defeating the allowlist. Replace with the
   explicit set of repos autonomous sessions actually push to. **NOT done
   autonomously** — removing it could block a live wave (e.g. sim-art-collective);
   Kody must confirm the legit target list first.
3. **`SECURITY.md`** at tower root — threat model (supply chain / agent trust /
   autonomous writers / token) + the confirmed asks. (Drafted this session — see
   file; extend if time.)
4. **`work/2026-07-18-legal-posture/DECISIONS.md`** — license patchwork + the
   trademark contradiction, with recommended texts. (Drafted — needs Kody sign-off.)
5. **Add `fleet.sh` dead-man alerting** — a scheduled check that pages when a
   writer flips to FAILING (4 are failing silently right now).
6. **Run a real RAR license audit** (finding #10 downgraded) before asserting any
   Microsoft-attribution claim.

## Kody-decision shortlist (only he can close these)
1. **Rotate the localtoolsdev Azure key** (active leak — do first).
2. **Decommission / relocate the self-hosted Actions runner** off the laptop that
   is the ecosystem's root of trust.
3. **Reconcile the trademark ownership** — `rapp-train/TRADEMARKS.md` (Wildhaven
   Homes LLC; does NOT claim "RAPP" or "brainstem") vs `RAPP/TRADEMARK.md`
   ((c) Kody personally; DOES claim both). The public contradiction can void the
   marks. Pick one owner + one scope, assign on record.
4. **License the grail + rings** (via the train) — today users have no legal right
   to run the installer.
5. **Decide the agent capability-boundary direction** before more third-party
   agents ship against the full-trust contract (one-way door #9).
6. **Copilot token hygiene** — it is non-expiring and readable by any loaded
   agent; decide on rotation cadence + whether soak/flight renders should hold
   real prod tokens (FR-10 already narrows this).

## Provenance
- Workflow `wpr2wvqvg` (28 agents, 0 errors, ~20 min): 7 readers → 6 lenses →
  merge → adversarial verify. Script + journal under the session's `workflows/`.
  Note: the `install-supplychain` reader returned placeholder junk ("test"/"a/b/c")
  — that ONE ground cell is empty; the supply-chain LENS still ran against the
  other readers and its findings (#1, #6) are sound and independently checked.
- My direct verifications this session: license presence per repo; secret-scanning
  status per repo; token-copy census (3 prod copies + 1 in canary checkout, modes
  ok); localtoolsdev leak (confirmed public + tracked + 1 alert); RAR Microsoft
  claim (refuted — 0 files); trademark contradiction (confirmed by reading both);
  agent loader (`importlib` exec, `_auto_install` pip); push-allowlist bare prefix
  (confirmed line 4).
