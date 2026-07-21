# 2026-07-21 — prod brainstem Copilot token heal (grail-runtime touch)

**Event class:** grail runtime touch (token file) — mandatory work/ entry.

**Symptom:** POST :7071/chat (prod) and :7082/chat (twin child) returned
`Copilot auth failed (401): Bad credentials`. Soak :7073 answered normally.
Prod's `~/.brainstem/src/rapp_brainstem/.copilot_token` had mtime today 13:04
(60-byte JSON, access_token only, no refresh_token) — token had gone bad.

**Action:** FR-7 memory backup ran first (`backup-memory.sh` → OK, 47 files).
Bad token archived in place as `.copilot_token.bad-2026-07-21` (mode 600),
then the soak instance's valid `.copilot_token` (Jul 18 15:57) copied over
prod's, mode 600. No restart needed — next /chat did a fresh exchange.

**Verified:** :7071/chat → `{"response":"OK","model":"claude-haiku-4.5"}`;
:7082/chat → `{"response":"OK","model":"gpt-5.4"}` (twin runs from the same
grail checkout, healed by the same file).

**Notes:** token values never printed/committed; files are local-only mode 600.
Open question for a later session: what rewrote prod's token file at 13:04
today (device-flow re-auth attempt without refresh_token?) — if it recurs,
wire the refresh-token path or a health alert on 401s.

Session: Fable 5, rapp-video walkthrough commission (filming needed live /chat).
