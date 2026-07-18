# SECURITY.md — the RAPP ecosystem threat model (tower view)

The estate is (a) shipped to strangers via `curl | bash`, (b) operated by
autonomous AIs that push unwatched, and (c) executes community-contributed
code on end-user machines. That is three trust boundaries most projects never
have all at once. This file names each, what covers it today, and the
confirmed hardening asks. Verified live 2026-07-18
(`work/2026-07-18-tower-blindspot-r2/`).

## 1. Supply chain — one-liner to running code

**Trust chain**: user runs `curl -fsSL https://kody-w.github.io/rapp-installer/install.sh | bash`
→ install.sh (fetched over TLS) → clones the grail → pip-installs
**range-pinned, un-hashed** deps from PyPI → runs the Flask server → loads agents.

- **No signature or checksum on executable code.** The only integrity hash in
  the whole system guards `soul.md` (a non-executable persona doc). A compromise
  of the GitHub repo, GitHub Pages, or any PyPI dependency injects code onto
  every installing machine (confirmed #1).
- **Dependency confusion**: `brainstem.py:_auto_install()` pip-installs package
  names parsed from a community agent's failed `import` — an attacker publishes
  that name on PyPI (confirmed #6).

**Asks (ride the train):** hash-pin deps in a `constraints.txt` inside the
payload (rides shared_sha256, pins per release tag); publish a checksum users
can verify; longer-term Sigstore/cosign provenance. Disable or allowlist
`_auto_install`.

## 2. Community-agent execution — full trust on the user's machine

The brainstem loads registry agents via `importlib.util.spec_from_file_location`
+ `module_from_spec` — **arbitrary Python, no sandbox**, with full filesystem,
network, the Copilot token, and the memory store. A malicious or buggy agent on
an end-user machine can exfiltrate that user's Copilot seat token on load and do
anything the user can (confirmed #3 mechanism, #9).

- **Covered**: `/agents/import` DOES verify SHA-256 against the RAR catalog on
  the enforced path (the "opt-in only" claim was **refuted** on verify — do not
  cite it). Build-time regex scan exists in RAR.
- **Gap / one-way door (#9)**: the "agents run fully trusted" contract already
  has real third-party dependents (Bill Whalen, Howard Hoy agents). Every month
  that ships more, a capability boundary later breaks more published agents. The
  direction must be **decided now** even if the answer is "documented trust, no
  sandbox yet" — write it down as a contract so it is a choice, not a default.

## 3. Autonomous AI writers — code pushed with nobody watching

Nine scheduled writers (`tools/fleet.sh`); several push, one to a **public**
repo, and four are **failing silently** right now. Risks:

- **No content gate on any autonomous push** (#5). The tower now ships
  `tools/guard.sh` (secrets + denylist + secret-filenames) — but **it must be
  wired** into `git-push-guard.sh` and `push_canvas.sh` (see HANDOFF next-steps).
- **Push-allowlist defeated**: `~/.claude/hooks/push-allowlist.txt` line 4 is a
  bare `github.com/kody-w/` prefix authorizing every kody-w repo. Tighten to the
  explicit legit target set (Kody-review — a wrong tightening blocks a live wave).
- **No bot identity**: autonomous commits are forensically indistinguishable from
  Kody's own; push provenance evaporates after GitHub's 90-day event window.
  Ask: a dedicated bot committer identity + a run ledger per autonomous wave.
- **Kill switch**: `tools/fleet.sh --freeze` documents each writer's stop
  command; the only public pusher also honors `PUSH_CANVAS=0`.

## 4. Credentials

- **Production Copilot token** (`~/.brainstem/src/.../.copilot_token`, ghu_ GitHub
  App user token): **non-expiring, no refresh_token**, 3 legitimate copies + 1
  that landed in the contested `rapp-canary` checkout. Blast radius: full Copilot
  under Kody's seat/identity (not repo write). **No abuse-detection channel** —
  exfiltration is invisible indefinitely (#3). FR-10 governs copy hygiene.
- **Self-hosted Actions runner** on this laptop for `microsoft/RAPPtranscript2Prototype`:
  anyone with write to that repo gets **code execution on the ecosystem's root of
  trust** (#4). Highest-leverage single fix: move it off this machine.
- **Secret-scanning**: now enabled on RAR (was off). `tools/secrets-watch.sh`
  sweeps open alerts estate-wide so they stop firing into a void. **One open
  alert live now**: `kody-w/localtoolsdev` public `.env` (see HANDOFF incident).

## Reporting
Private estate — no external disclosure process needed today. When RAPP has real
external adoption, this file needs a coordinated-disclosure contact and an
`/agents` capability-restriction story (§2) before, not after.
