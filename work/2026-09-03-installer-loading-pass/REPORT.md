# aka.ms/rappinstall — adversarial loading/performance pass (2026-09-03)

**Target.** `aka.ms/rappinstall` → `microsoft.github.io/aibast-agents-library/docs/installer.html`,
whose macOS/Linux one-liner is `curl -fsSL https://microsoft.github.io/aibast-agents-library/install.sh | bash`
(1128 lines, brainstem v0.6.16). The brainstem application it installs was measured too.

**Outcome.** Six confirmed defects, all fixed and proven on clean machines, staged on the
release train without touching the grail:

- PR on the pre-release channel: https://github.com/kody-w/rapp-canary/pull/12 (CI preflight run
  33770782909 on the 7-VM matrix was in progress at hand-off; branch `fix/installer-loading-pass`).
- Same patch on the live AIBAST bytes, pushed to the fork:
  https://github.com/kody-w/aibast-agents-library/tree/fix/installer-loading-pass —
  PR to microsoft/* is Kody's call: https://github.com/microsoft/aibast-agents-library/compare/main...kody-w:aibast-agents-library:fix/installer-loading-pass
- Nothing pushed to kody-w/rapp-installer or microsoft/*.

## What was measured (evidence/ has the raw logs)

Fresh install on this Mac, throwaway `$HOME`, prerequisites present:

| phase | live | patched |
|---|---|---|
| sparse clone (2 round trips) | 3s | 2s |
| venv | 2s | 5s* |
| pip self-upgrade | 3s | removed |
| pip deps (16 wheels) | 31s | 25s |
| CLI + env | 0s | 0s |
| **total** | **39s** | **34s** |

\* venv timing varies 2–5s run to run. The pip phase is this Mac's package proxy
(`packagefeedproxy.microsoft.io`): resolving through it takes 17.5s while installing the same
16 wheels from a local directory takes 1.6s, and plain PyPI takes 4.7s warm. The installer's own
overhead is ~8s of the 39s; the rest is network the installer does not control.

Re-run when already up to date: 1s. Upgrade 0.6.15→0.6.16: 3–4s.

Brainstem app (fresh install, 4 bundled agents, unauthenticated): cold start to `/health` 200 in
0.32s; `/` serves the 203KB single-file UI in 2ms; UI loads self-contained (no external scripts)
with DOMContentLoaded at 22ms and load at 89ms; `/health` 44ms (it re-imports agents and probes
the gh CLI on every 5s poll — 33-agent real install: 6–14ms warm, 192ms cold); 143 req/s on
`/health` at concurrency 20 (werkzeug threaded). The 33-agent real install ships a 35KB tools
array on every `/chat` — that is the only app-side scale cost worth watching, and it is a
per-install choice, not a defect. No app changes were made.

## Confirmed defects → fixes (all reproduced before, re-proven after)

1. **Ubuntu 24.04 with no python3 dies in 2s.** The apt fallback hardcodes `python3.11`, which
   Noble does not ship. Fix: fall back to `python3 python3-venv python3-pip` (3.12; `find_python`
   accepts 3.11+). Proof: bare `ubuntu:24.04` container installs and answers `/version` in 78s.
2. **Ubuntu/Debian with python3 but no `python3-venv` fails**, and the hint (`pip install
   virtualenv`) is wrong. Fix: install `pythonX.Y-venv` via apt and retry; honest hint. Proof: 36s
   to a serving brainstem.
3. **Black-holed GitHub hangs the installer.** `check_for_upgrade`'s curl has no `--max-time`
   (hung >300s under iptables DROP); git then hangs 133s more. Fix: bound both VERSION curls; a
   curl *timeout* keeps the installed version and launches. Refused/DNS/TLS failures keep today's
   "upgrading anyway" path, so the CI hosts-file black-hole is unaffected. Proof: patched rerun
   reaches "Starting RAPP Brainstem" in 26s and serves; the live installer, same container, was
   still on "Checking for updates..." when killed at 150s.
4. **Every upgrade flags every bundled agent and every untracked user agent as a
   "custom-agent name collision"** and copies them into `recovery/`. Cause: "shipped" was read
   from the directory after `git reset --hard`, which leaves untracked files. Fix: shipped =
   `git ls-files`; a bundled copy byte-identical to the previous release (`git show OLD_HEAD:…`)
   is silent. Proof: rehearsal with a custom agent, a soul edit and one deliberately edited
   bundled agent → exactly 1 warning, custom agent and soul kept, bundled agent refreshed.
5. **A failed dependency retry dies silently** under `set -e` (seen on Debian 12 when PyPI
   flaked): no ✗ line, then the server crashes on `import requests`. Fix: `|| true` so the
   import check prints the failure and the fix.
6. **Wasted network on every fresh install**: `pip install --upgrade pip` (1.4–3s) and a
   launch-time `git pull` right after this run already fetched the source. Both removed
   (pinned checkouts were never pulled anyway).

## Not done / for Kody

- `install.ps1` is untested here (no Windows leg run locally); the canary CI preflight covers it.
- **Drift:** the live AIBAST `install.sh` is ~440 lines ahead of the grail/canary installer
  (heartbeat spinner, sparse clone, `--no-launch`, `BRAINSTEM_REPO_URL` overrides). The manifest
  says `install.sh` flows verbatim upstream→downstream, so the next `sync-to-aibast.sh` would
  clobber those features. Decide which repo owns them.
- The launch-path `git pull` on the "already up to date" path still pulls main's tip past the
  VERSION gate. Left as is (behavior, not perf); worth a ruling.
- Canary's `tests/test_installer.sh` fails 2/45 with system python (no flask); 45/45 with the venv
  python. Pre-existing, environmental.

## Re-run it

`~/.rapp-tests/installer/{fresh-home,upgrade-rehearsal,docker-matrix,blackhole}.sh <install.sh>`.
Docker on this Mac needs `PIP_INDEX_URL=https://packagefeedproxy.microsoft.io/pypi/simple/`
(baked into the scripts). `patch_installers.py` here re-applies the fix to either byte set.
