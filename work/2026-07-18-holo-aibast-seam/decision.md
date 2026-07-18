# DECISION GATE — HOLO senses crossing the aibast seam

**Status: DECIDED 2026-07-18 — option (b), executed.** The standing grant
for microsoft/aibast-agents-library is live in TRADEMARKS.md (same
first-hit-free terms). Counsel may revisit during the employer-seam review
of the new assets; until then the flight is free to merge when Kody says.

Once the flight merges, `agents/holo_agent.py` + `gesturepad.html` become
promoted payload; the next grail release carries them; the next
sync-to-aibast puts Wildhaven-marked senses (|||HOLO||| strings, VUI/HOLO
vocabulary) inside Microsoft's repository. Two clean options:

- **(a) Manifest exclusion** — teach `tools/aibast.manifest` to exclude the
  sense files (needs an `exclude` directive; small script change riding the
  train). aibast ships the engine without the marked senses.
- **(b) Explicit mark grant** — one paragraph in TRADEMARKS.md granting
  aibast distribution of the marker strings as shipped code (an integration
  license instance). aibast ships everything; the marks stay owned.

Recommendation: **(b)** — aibast IS a genuine integration ("first hit is
free" applies on its face), and (a) forks the payload shape we worked to
keep mechanical. But it is an IP call touching the employer seam → Kody
decides, ideally after the counsel pass on the new assets.
