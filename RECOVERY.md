# RECOVERY — if this laptop dies today

Everything below was inventoried 2026-07-18. Verdict then: **no Time
Machine destination, no iCloud Documents sync** — the machine-only column
is a total loss until the action items at the bottom are done.
`tools/backup-status.sh` shows the current state of this page's claims.

## What survives (on GitHub)

- Every pushed `kody-w/*` repo, incl. this tower (private), the rings,
  the grail, rapp-map, rapp-train, RAR origin.
- GitHub Pages surfaces (installers, deck, playbook, llms.txt).
- The public install path itself: a new machine can run the one-liner and
  get a working brainstem — **minus all memory/state**.

## Machine-only (dies with the SSD)

| Asset | Location | Consequence if lost |
|---|---|---|
| Production memory: shared_memories, twins, cubbies, soul.md, .env, tokens | `~/.brainstem/…` | Months of memory/twin state — **no third copy on Earth** unless `~/Backups/rapp-brainstem/` archives were made AND live off-machine |
| Obsidian vault (feeds kody-twin + 3 more skills) | `~/Documents/Obsidian Vault` — git repo, **no remote** | Twin has nothing to read; years of notes gone |
| 21 Claude skills (incl. flex-unbrick — sole copy of the Azure SFI PNA runbook) | `~/.claude/skills` — **not a git repo** | All encoded operational knowledge gone |
| launchd plists + crontab (supervisors, heartbeats, sim loops) | `~/Library/LaunchAgents`, `crontab -l` | Rebuilt from memory only |
| Unpushed commits / no-remote repos under `~/Documents/GitHub` | varies — `tools/backup-status.sh` sweeps | Whatever was ahead of origin |
| `~/Backups/rapp-brainstem/` archives | local disk | The memory backup dies with the machine it protects — off-machine copy required |

## Ordered restore (new machine)

1. `xcode-select --install`, Homebrew, `gh auth login`, git identity.
2. Clone the tower first: `gh repo clone kody-w/rapp-tower ~/Documents/GitHub/rapp-tower`
   — this file, FLIGHT_RULES, and the registry come back immediately.
3. Clone the registry list (CLAUDE.md table): rapp-canary, rapp-nightly,
   rapp-alpha, rapp-beta, RAPP, RAR, rapp-map, rapp-train,
   aibast-agents-library.
4. Production brainstem: public one-liner
   (`curl -fsSL https://kody-w.github.io/rapp-installer/install.sh | bash`),
   then **stop it and restore state** from the newest
   `brainstem-state-*.tar.gz` (untar over
   `~/.brainstem/src/rapp_brainstem/.brainstem_data`, `~/.brainstem/twins`,
   `~/.brainstem/cubbies`, plus soul.md/.env/.copilot_token) — then
   `~/.local/bin/brainstem` (the installer creates that launcher).
5. Vault + skills: restore from their remotes (action items 2–3 below make
   this line true).
6. Re-neuter check: `git -C ~/.brainstem/src remote get-url --push origin`
   must show `DISABLED-…` (fresh installs may leave a real URL — FR-2).
7. crontab + launchd: re-create from the registry section in CLAUDE.md
   (ports & automated writers) — deliberately, one at a time, logging each
   as a `work/` decision.

## Action items (each one deletes a row from "machine-only")

These are Kody-account decisions — the tower can't do them for him:

1. **Attach a Time Machine destination today.** One decision removes the
   whole-machine SPOF.
2. Give the vault a **private** origin and push
   (`gh repo create kody-w/obsidian-vault --private`).
3. Make `~/.claude` (or at least `~/.claude/skills`) a git repo with a
   **private** origin and push.
4. Keep the newest memory archive off-machine (TM covers this once #1 is
   done; until then, anything — even AirDrop to a second device).

Rule worth writing down: **"never public" ≠ "never pushed"** — private
repos exist precisely so restricted things still survive the SSD.
