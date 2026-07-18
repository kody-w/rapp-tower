# GO / NO-GO — grail release checklist

Companion to RUNBOOK §5 (rapp-canary `.ring/RUNBOOK.md`). The RUNBOOK says
*how*; this sheet is the poll. Copy it into
`work/YYYY-MM-DD-release-vX.Y.Z/GONOGO.md`, check every line **with
evidence pasted** (command output, run URL), and keep it — the closeout is
how the next session knows the release actually finished.

## Poll — all GO before export

| # | Check | Evidence required | GO |
|---|---|---|---|
| 1 | Qualification run green + **archived** | `archive_attestations.sh <run-id>` output; `.ring/attestations/run-<id>/` committed | ☐ |
| 2 | `tools/release_gate.sh` — **containment**: grail main tip is an ancestor of the qualified canary commit (no un-backmerged hotfix to silently revert) | GO line with both SHAs | ☐ |
| 3 | `tools/release_gate.sh` — **soak evidence**: soak `source_commit` == qualified canary commit, age ≥ 2 days | GO line with SHAs + age | ☐ |
| 4 | Beta tip unmoved since qualification | `grail_gate.py verify` beta check | ☐ |
| 5 | Holds claimed: `tools/holds.sh claim grail-release "<vX.Y.Z>"` (covers canary checkout + release window) | `holds.sh list` output | ☐ |
| 6 | Pages green across rings before you start | `tools/pages.sh` — no DEPLOY-RED | ☐ |

**Any NO-GO stops the release.** Override only via
`release_gate.sh --override` + a `work/` decision entry (template in
`work/TEMPLATE-decision.md`) — the override exits non-zero on purpose.

## Release (RUNBOOK §5 mechanics)

Fresh `/tmp` clone → `release/vX.Y.Z` branch → `grail_gate.py verify
--export-to` → `tests/test_installer.sh` → VERSION bump → installer copies
into `docs/` → commit with qualification run URL → push → 7-VM preflight →
**Kody's human `--no-ff` merge** + `brainstem-vX.Y.Z` tag.

## Post-release closeout — the half that gets skipped

| # | Closeout item | Evidence required | Done |
|---|---|---|---|
| C1 | Push URL **re-neutered** on the release clone AND `~/.brainstem/src` still neutered | `git remote get-url --push origin` output showing `DISABLED-…` (both) | ☐ |
| C2 | Hotfix backmerge: anything that landed on grail main during the window merged back to canary (`git fetch <grail> main; git merge FETCH_HEAD`) | commit SHA or "window clean" | ☐ |
| C3 | KERNEL_PIN / version pins bumped where the estate records them | diff or "n/a" | ☐ |
| C4 | Pages deploys green after the release push | `tools/pages.sh` output | ☐ |
| C5 | Downgrade rehearsed **as a user would run it** (FR-3 syntax, sandbox HOME, lands on pinned tag) | rehearsal transcript | ☐ |
| C6 | Tag pushed; `work/YYYY-MM-DD-release-vX.Y.Z/` entry committed to the tower | this file, filled in | ☐ |
| C7 | Holds released: `tools/holds.sh release grail-release` | `holds.sh list` empty | ☐ |

- [ ] **Honesty check**: release notes state the soak population truthfully
      (today that is: the maintainer's own machines — say so until it isn't).
