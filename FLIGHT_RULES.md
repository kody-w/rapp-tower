# FLIGHT RULES — pre-decided responses to emergencies

Decisions made calmly, in advance, so no session improvises under pressure.
Each rule is an if-then. If a rule is wrong, fix the rule via a `work/`
decision entry — never freelance past it mid-incident.

Every fact below was verified against the live system on 2026-07-18
(`work/2026-07-18-tower-blindspot/`). If reality has drifted from a rule,
that drift is itself a finding — log it.

---

## FR-1 · Loss of brainstem (`:7071` not answering)

**Never** `rm`, re-clone, `git reset --hard`, or `git clean` anything under
`~/.brainstem`. Sole-copy production state lives INSIDE it:
`~/.brainstem/src/rapp_brainstem/.brainstem_data/` (shared memories),
`~/.brainstem/twins/`, `~/.brainstem/cubbies/`. Memory is not part of the
install — it does not come back.

1. Diagnose first: `tools/triage.sh` (identity, not just port state).
2. The one verified restart command: **`~/.local/bin/brainstem`**
   (launcher script: correct cwd, venv python, dep check — run it in a
   persistent shell/tmux, it `exec`s in the foreground).
3. Do **not** "fix" this by enabling `com.brainstem.server` in launchd.
   The plist exists (`~/Library/LaunchAgents/com.brainstem.server.plist`)
   but is deliberately-or-accidentally disabled and its interpreter path
   has never been proven to serve the current code. Enabling it is a
   logged decision (`work/` entry + side-by-side verification), not a
   2am reflex.

## FR-2 · Grail checkout found push-capable

The push URL of `~/.brainstem/src` (and any `/tmp` release clone that
outlived its release) must be the neutered string. If `checkouts.sh` shows
the red `GRAIL PUSH ENABLED` banner, or you ever see a real URL:

```
git -C ~/.brainstem/src remote set-url --push origin DISABLED-push-to-grail-is-a-conscious-release-act-see-rapp-canary-.ring-RUNBOOK
```

Re-neuter **immediately**, then write a `work/` entry: when it was enabled,
by what, and whether anything was pushed (`git log origin/main..` in that
checkout). A push-capable grail checkout is a severity-1 condition — one
stray `git push` serves unqualified bytes to every installer on Earth.

## FR-3 · Bad version shipped to grail

Two levers, in order:

1. **Grail side**: revert grail main via the conscious-release path
   (RUNBOOK §5) — branch, revert commit, preflight, human merge.
2. **User side** — the pin-back one-liner. The ONLY implemented syntax is:

   ```
   curl -fsSL https://kody-w.github.io/rapp-installer/install.sh | bash -s -- --version v0.6.16
   ```

   ⚠️ `BRAINSTEM_VERSION=<prev>` as documented in PLAYBOOK.md §Scenario-10
   and RUNBOOK §5 is **implemented nowhere** — install.sh silently ignores
   it and installs latest (verified: zero matches in install.sh; parser
   only reads `--version`, install.sh:787). Until the docs are fixed via
   the train, this flight rule is the authoritative syntax.
3. Rehearse the downgrade per release (RUNBOOK §5 already requires it):
   run the user-facing command verbatim in a sandbox `HOME` and confirm it
   lands on the pinned tag. Record in the GO-NOGO closeout.

## FR-4 · Red oracle (preflight / rewrite-count / attestation / gate)

Iron law 4: the red oracle is the system working. Diagnose upstream, never
bypass. **Plus the silent half**: a drift-blocked `publish-pages` run
freezes that ring's Pages installers at old bytes while the repo moves on —
and Pages URLs are the only correct installers (iron law 5). After ANY red
publish-pages run: `tools/pages.sh`, and treat `LIVE-BEHIND` on an
installer surface as an active incident, not a cosmetic lag.

## FR-5 · Contested checkout is dirty / moved unexpectedly

Before concluding another session holds it (or that it's safe to touch):

1. `tools/holds.sh list` — is it claimed?
2. Known **automated writers** (not sessions, not drift):
   - `~/Documents/GitHub/RAPP` — written into every 30 min by cron
     (`tools/sim/loop_orchestrator.sh`, the rapp-sim loop).
   - `~/Documents/GitHub/RAR` — dirty state is long-standing orphaned
     build output (~Jun 27), deliberately unreconciled; see
     `work/2026-07-18-standing-oddities/`.
3. Never clean/reset/stash a contested checkout to "help". Scratch-clone
   (iron law 3) and move on.

## FR-6 · Port answers wrong / service behaves oddly

Run `tools/triage.sh` before touching anything. Standing conditions to not
"fix": `:7073` is double-bound by design-accident — the canary soak
brainstem on `127.0.0.1` shadows an Azure Functions host bound to
`*:7073` (work project, `~/MSFTAIBASTRAPP/RAPPtranscript2Prototype`).
Loopback traffic gets the brainstem; the func host is a *work* runtime —
never kill a listener you didn't start.

## FR-7 · Before ANY wipe / reinstall / reset of the brainstem

`tools/backup-memory.sh` is **step 0** — before `brainstem-reset`, before
install.sh's upgrade path, before any recovery move. Verify the archive
landed in `~/Backups/rapp-brainstem/` before proceeding. No archive, no
wipe.

## FR-8 · Demo in <1 hour and something is red

Check order: (1) `tools/triage.sh` — a port can be LIVE yet
**unauthenticated on a fallback model** (exactly how flight `:7075` was
found on 2026-07-18: serving gpt-4o instead of the soaked model — a take
filmed against it behaves unlike what qualified); (2) `tools/pages.sh` if
the demo installs anything; (3) `/exec-proof` for install demos. Never
demo a surface whose `/health` shows unauthenticated or a fallback model.

## FR-9 · Publishing from tower context to a public repo

`tools/leakcheck.sh <path>` against the private denylist before any push
that will land in a public `kody-w/*` repo. A hit is a full stop — git
history in a public repo is unredactable in practice (iron law 7; the
public conformance suite checks only a synthetic name and cannot catch
real ones).

## FR-10 · Real Copilot tokens outside `~/.brainstem`

Token copies are permitted in exactly two places: the soak render (its
purpose is authenticated soak) and ONE actively-tested flight render. On
any other sandbox, or on landing a flight: delete the copy
(`rm <render>/rapp_brainstem/.copilot_token`) before walking away. Sweep:
`find ~/.rapp-flight ~/.brainstem-soak -name .copilot_token`. A forgotten
plaintext token in a disposable directory is how a disposable directory
stops being disposable.
