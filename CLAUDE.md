# CLAUDE.md — the RAPP Control Tower

> **The mission: every AI and every person can work productively with RAPP.**

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
| `~/.brainstem/src` | kody-w/rapp-installer | THE GRAIL — live production install | READ-ONLY. Push URL is `DISABLED-…` on purpose. NEVER re-enable outside a conscious release (RUNBOOK §5) |
| `~/Documents/GitHub/rapp-canary` | kody-w/rapp-canary | Train entry ring + hub tooling | Contested by parallel sessions — treat as read-only reference; do branch work in scratch clones |
| `~/Documents/GitHub/rapp-{nightly,alpha,beta}` | rings | Promotion targets | Only ever receive `promote_ring.py` output |
| `~/Documents/GitHub/RAPP` | kody-w/RAPP | Reference distro (lts) | Often carries another session's WIP — scratch-clone for changes; `shape/next` branch = Beta siding |
| `~/Documents/GitHub/RAR` | kody-w/RAR | Agent registry — THE active checkout | `~/RAR` is stale; never touch it |
| `~/Documents/GitHub/aibast-agents-library` | kody-w fork of microsoft/… | aibast sync vehicle | PRs to Microsoft are MANUAL (SAML); never push microsoft/* |
| `~/Documents/GitHub/rapp-train` | kody-w/rapp-train | Deck + playbook + llms.txt | Normal edits fine |
| `~/Documents/GitHub/rapp-tower` | kody-w/rapp-tower | THIS repo | Work products in `work/YYYY-MM-DD-topic/` |

Live local services: production brainstem `:7071` (from ~/.brainstem — do not
disturb) · canary soak `:7073` (`rapp-canary/.ring/tools/soak.sh`) · flights
`:7075` (`~/.rapp-flight/`) · parallel sessions sometimes hold ports — check
`lsof` before assuming yours.

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

## Tower tools

- `tools/checkouts.sh` — one-screen status of every registered checkout
  (branch, dirty, ahead/behind, who-holds-what).

## Work products

Cross-repo plans, audits, reports, drafts: `work/YYYY-MM-DD-<topic>/`.
Commit them — the tower's history is the ecosystem's decision log.
