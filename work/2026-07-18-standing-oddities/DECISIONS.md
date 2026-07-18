# 2026-07-18 — Standing oddities: recorded so intent stops being guesswork

Every item below is a **verified live fact** whose intent was previously
recorded nowhere. Status `NEEDS-KODY` = the tower found it, only Kody can
say whether it's deliberate. Adjudicating one = edit its status line here
(that edit is the decision record).

| # | Standing state | Evidence (2026-07-18) | Status |
|---|---|---|---|
| 1 | Production `:7071` runs as a **manual orphan** (parented to a zsh); `com.brainstem.server` plist exists but is not loaded and is launchd-disabled | `launchctl print-disabled gui/501`; triage.sh doctor | NEEDS-KODY — deliberate manual ops, or enable supervisor after side-by-side verification? (FR-1 forbids reflex-enabling) |
| 2 | `com.brainstem.imessage_heartbeat` exits 2 every 900 s — **the only liveness alarm has been dead since ~Jul 7** | launchctl last-exit; only heartbeat logs in `~/.brainstem/logs` | NEEDS-KODY — fix, or retire and replace with a scheduled `triage.sh` probe? |
| 3 | `RAR` checkout deliberately(?) 278 behind / 130 dirty (orphaned build output ~Jun 27) | `git -C ~/Documents/GitHub/RAR status/log` | NEEDS-KODY — reconcile date, or codify "frozen on purpose"? |
| 4 | `:7073` **double-bound**: soak brainstem (127.0.0.1) shadows a work Azure-Functions host (`*:7073`, `~/MSFTAIBASTRAPP/RAPPtranscript2Prototype`); a second func host sits on `:7072` | triage.sh; lsof | RECORDED — FR-6 says never kill the other listener; loopback gets the brainstem |
| 5 | Flight `:7075` (canary) serving **unauthenticated, fallback model gpt-4o** since 15:42 | `/health` on :7075 | NEEDS-KODY — re-auth the flight or stop it; never demo it as-is (FR-8) |
| 6 | Flights `beta` and `canary-flight-project-twin` are **dead** (pids gone), logs still claim :7075 | triage.sh FLIGHTS section | NEEDS-KODY — restart or clean up `~/.rapp-flight` entries |
| 7 | A **second brainstem runs from the grail checkout** on `:7082` (twin soul `twin-kody`, 5 agents, since Jul 18 12:52) — undocumented anywhere | triage.sh first run | NEEDS-KODY — known experiment (likely a parallel session's twin) or stray? |
| 8 | Soak restarted today on canary `9506437` — **newer than attested** `25fcc8a` (run-29658720229); soak evidence for that attestation is void | release_gate.sh NO-GO | RECORDED — re-qualify or re-point soak before any release |
| 9 | Failing launchd agents: `com.kody.daily-summary` (exit 2), `com.kody.sonosite.sf-refresh` (exit 1), `ai.openclaw.gateway` (exit 1) | launchctl list | NEEDS-KODY — fix or retire; silent-failure precedent is how #2 happened |
| 10 | A **microsoft/**-repo self-hosted Actions runner runs persistently on this machine (`rapp-mac-runner`) | launchctl list | RECORDED — work/personal boundary surface; registry now names it |
| 11 | Canary tip `0c19941` has **moved past** the newest qualification (attested `25fcc8a`) | train.sh | RECORDED — normal DEVELOP motion; next qualification covers it |
| 12 | rapp-map baselines stale vs spec (estate-map/neurons 16 d, graph 34 d); repo count 92 vs 99 mismatch | drift.sh | NEEDS-KODY — schedule ecosystem-sync regeneration; adjudicate the count once |
