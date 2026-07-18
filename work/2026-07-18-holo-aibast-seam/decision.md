# DECISION GATE — HOLO senses crossing the aibast seam

**Status: DECIDED 2026-07-18, then CORRECTED same day (Kody).** The first
implementation ("standing grant") implied Wildhaven authority over
Microsoft's repository — wrong and dangerous at the employer seam. AIBAST
is Microsoft's; Wildhaven owns nothing there and grants nothing to it. The
live TRADEMARKS.md language is a one-way DISCLAIMER: no mark claims against
code our contributors submit upstream (marker strings included), offered
under that repo's own license. The flight may merge; the seam rule is:
never words that imply ownership, authority, affiliation, or that AIBAST is
"part of the ecosystem."

Two clean options:

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
