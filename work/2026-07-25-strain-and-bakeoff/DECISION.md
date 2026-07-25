# Kernel minimality, RAPP Light, and the bake-off pattern (2026-07-25)

## 1. The 183-line merge was unconstitutional, not merely inelegant

A three-format skill hot-loader was written into `brainstem.py` (canary
`cb094b7`), then reverted (`5498419`). Writing the rule into the constitution
revealed it already existed:

- **Article I** — "the brainstem is a loader + an LLM loop + a response
  splitter. That's it."
- **Article XXVI** — rejects any change loading responsibility into
  `brainstem.py` which a `*_agent.py` could serve.

Preflight was green throughout. Every oracle in the path checks correctness;
none checks placement. **The gap was enforcement, not the rule.**

→ PR **kody-w/RAPP#100**, proposal at
`docs/proposals/2026-07-25-kernel-minimality-enforcement.md`, Article LVI adds
only: the four extension points enumerated, the burden of proof assigned in
writing, one runtime form, and the precedent. **Not self-merged** — Article XXVI
makes an amendment a brainstem-level decision, and an agent should not ratify
the law that constrains agents.

## 2. The capability re-landed as an agent — the proof that LVI.2 is true

`skill_digester_agent.py` on canary main (`74fdb36`). **0 lines in
brainstem.py.** No kernel hook was needed because one already exists:
`load_agents()` runs on every `/chat`, so an agent's `__init__` is a per-turn
hook.

Digestion always terminates in `agent.py`. A fed `.md` never stays resident in
`agents/` in its own shape — one runtime form, or the brainstem carries a second
loader and a second lifecycle.

## 3. RAPP Light — the first strain (public: kody-w/rapp-light)

Locked-down enterprise deployment **without forking the kernel**. Every hardened
fork dies the same way: it drifts and stops receiving upstream security fixes.
A strain constrains from outside, so a grail fix reaches the restricted
deployment the same day.

Five checks: seal → ring → identity → capability → egress. The capability check
is the differentiator — declared capabilities are **verified against the syntax
tree**, so an allowlist is not an allowlist of promises.

Rings: `frontier → private-preview → public-preview → ga`. Band expands by
individual approvals carrying recorded exceptions. Elevation is a credential,
not a build — and cannot bypass the checks.

**Deliberate non-claim (T6):** not a defence against a local administrator.
Neither is any endpoint DLP product. Stated plainly because a control that
overclaims fails review.

## 4. Bake-off (public: kody-w/rapp-bake-off)

The counter to being pre-empted rather than beaten. Convert every "we already do
that" into a customer-owned, pre-registered side-by-side. Accept-and-win,
accept-and-lose, or refuse — **the refusal is the result.**

Rules exist to remove specific excuses: customer writes the tasks; metrics
sealed before measuring with the customer holding the key; each entrant driven
by its own team; clock starts at a clean machine; published either way.

## 5. Standing item for Kody

- **PR #100 needs ratification** (or rejection) — it is deliberately blocked on
  a human.
- Monday: rapp-light is the Microsoft submission. `docs/THREAT-MODEL.md`,
  `RAI.md`, `COMPLIANCE.md` are written for that review.
