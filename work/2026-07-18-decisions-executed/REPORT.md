# 2026-07-18 — Decisions console: what got executed

Kody answered all 13 items in `tools/decisions.py`; this is what a Claude session
did with each. Queue: `.tower/decisions-queue.jsonl`.

## ✅ Done (executed + verified)
| Decision | Result |
|---|---|
| Google keys → **revoked, close alerts** | 3 secret-scanning alerts (mars-barn-opus, gemini-cli-tips, TheMatrix) resolved/revoked. 0 open. |
| Runner → **decommission** | launchd agent booted out + plist retired (`~/.tower-retired-launchagents/`). RCE surface inactive. **GitHub-side removal pending** (needs a removal token: `cd ~/.rapp-ci-runner && ./config.sh remove --token <from repo Settings→Actions→Runners>`). |
| Sonosite → **retire agent** | `com.kody.sonosite.sf-refresh` retired (reversible). |
| Prod :7071 → **enable supervisor (verify first)** | Verified plist serves identical code (venv py3.11 + same script + deps). Service was launchd-**disabled** (round-1 finding) → enabled, swapped orphan→supervised. :7071 back up identical (v0.6.16, 3 agents), now KeepAlive-supervised — **survives reboot**. Memory backed up first (FR-7). |
| Flight :7075 → **stop** | Stopped (pid 66771). |
| Dead flights → **clean up** | Removed `beta` + `canary-flight-project-twin` from `~/.rapp-flight`. |
| :7082 twin → **leave it** | Recorded as known twin experiment (standing-oddities #7). |
| RAR → **reconcile to origin** | Was 278-behind / 130-dirty (redundant build output — origin already had the agents). Backed up 130 files to `~/Backups/rar-reconcile-20260718`, reset to origin, cleaned. Now **behind=0 ahead=0 dirty=0**. |
| docs-to-copilot-studio → **leave it** | Recorded: accepted tracked client_secret in the private repo (no action). |

## 🚂 Prepared (rides the train — your merge)
| Decision | Result |
|---|---|
| Grail license → **Apache-2.0** | Branch **`kody-w/rapp-canary @ add-apache-2.0-license`** pushed: `LICENSE` (Apache-2.0) + `NOTICE` (© Wildhaven Homes LLC). Next: promote → qualify → grail_gate → **your human merge** to grail. Do NOT merge to grail directly. |

## ✍️ Drafted (your final sign-off — public/legal)
| Decision | Result |
|---|---|
| Trademark → **Wildhaven Homes LLC owns all** | Reconciled `RAPP/TRADEMARK.md` drafted at `RAPP-TRADEMARK.reconciled.md` (defers to canonical TRADEMARKS.md; drops the contradictory "RAPP"-alone + personal-brainstem claims). Apply by replacing the file + recording the personal→LLC assignment. Not auto-pushed — public legal wording is yours to publish. |
| push-allowlist → **tighten (derive, confirm)** | See `push-allowlist-proposal.md`. **Recommendation: don't tighten.** 30+ kody-w repos are actively pushed to; an explicit list is long, fragile, and breaks waves. For a single-owner namespace the bare prefix is defensible — the real protection is the **content gate** (`guard.sh`) blocking secrets/customer-names regardless of repo. Your call. |

## ⏳ Teed up (needs a dedicated run — not done, to protect capacity)
| Decision | Status |
|---|---|
| rapp-map drift → **run ecosystem-sync regeneration** | NOT run this session — `ecosystem-sync` regenerates the whole estate map/mesh and can spawn a large swarm; running it at a session tail risks capacity. **Run it fresh:** invoke the `ecosystem-sync` skill (regenerate estate-map/neurons/graph to current spec + adjudicate the 92-vs-99 count). Queued for the next session. |
