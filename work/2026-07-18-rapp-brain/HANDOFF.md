# RAPP Second Brain — convergence handoff (Fable → Opus, 2026-07-18)

> ## ✅ RESOLVED 2026-07-18 (Kody: "collapse to rapp-second-brain, archive rapp-ecosystem-brain")
>
> - **Canonical = `kody-w/rapp-second-brain`** (public) — the mature build:
>   ~330 repo cards already crawled, `COORDINATION.md` many-writer protocol,
>   `tools/{shard,claim,save-card,rebuild}.sh`, `reduce.yml` CI index. **Secret-
>   scanning + push-protection ENABLED.**
> - **`kody-w/rapp-ecosystem-brain` ARCHIVED** (read-only) with a README redirect
>   to the canonical repo. It was only a skeleton — nothing unique lost.
> - **Private hemisphere `kody-w/rapp-second-brain-private`** exists (private).
>   ⚠️ GitHub secret-scanning is **NOT available** on it (private repo, no
>   Advanced Security) — so the tower's `tools/guard.sh` is its **only** secret
>   gate. Wire guard.sh into that repo's push path/CI; do not rely on GitHub.
> - **Leak hygiene fixed + findings** (below "Leak findings" section).
>
> The rest of this doc is the original convergence analysis — kept for context.

Kody asked Fable to plan a crawl of the whole RAPP ecosystem (known + unknown,
public + private, no leaks) into a two-hemisphere second brain, as its own
public repo, handed to Opus. **While planning, I found parallel Opus sessions
had already built it.** So this handoff is a *convergence* doc, not a fourth
repo — plus the tower dependencies both existing plans point at, and the
private hemisphere's seed content.

## Situation (verified live 2026-07-18 ~22:45)

- **TWO public brain repos already exist**, both created today, both with strong
  plans that already assume the tower's content-gate:
  - `kody-w/rapp-second-brain` (public) — "two-hemisphere second brain (public
    hemisphere), built on rapp-map." Has `OPUS-HANDOFF.md`, `SCHEMA.md`,
    `brain/`, `tools/`, LICENSE. Cleanest framing + naming.
  - `kody-w/rapp-ecosystem-brain` (public) — has the stronger *operational*
    scaffold: `CONCURRENCY.md` (the parallel-writer protocol), `PLAN.md` (Phase 0
    safety contract), `claims/`, `crawl/`, `public/`, generated aggregates.
- **NO private hemisphere exists yet** — `rapp-second-brain-private`,
  `rapp-ecosystem-brain-private`, `rapp-brain-private` are all FREE.
- Fable did **not** create a competing repo. A half-built local `rapp-brain`
  scaffold was removed; its two tested scripts are preserved here as reference
  (`crawl-discover.reference.sh`, `publish-gate.reference.sh`).

## Recommendation #1 — collapse to ONE canonical public repo (Kody's call)

Two parallel public brain repos IS the fragmentation the estate's own doctrine
forbids. Pick one before Opus fans out, or the crawl splits in half.

- **Recommended**: adopt **`rapp-ecosystem-brain`'s scaffold + CONCURRENCY.md**
  as the operating base (it already solves the many-writers problem you flagged),
  under whichever **name** Kody prefers — `rapp-second-brain` is the better name.
  Simplest merge: copy `rapp-ecosystem-brain`'s `CONCURRENCY.md` + `claims/` +
  `build.py`-generated-aggregate pattern into `rapp-second-brain`, archive the
  other. Do this as a deliberate `work/` decision; don't let both run.

## Recommendation #2 — the private hemisphere is a SEPARATE PRIVATE repo

Both plans agree, and it is the right call for N parallel autonomous writers: a
gitignored `private/` inside the public repo is one `git add -f` from a leak.
Create `kody-w/rapp-second-brain-private` (PRIVATE) with **secret-scanning +
push-protection ON at creation** (lesson from the round-2 leak). Private cards
may reference public cards by `id`; never the reverse.

## The tower dependency both plans require (this is the seam)

Both existing plans say "run the tower's `tools/guard.sh`" / "reuse the estate's
content-gate tool (see the private ops handoff)." **This is that handoff.** The
tower (`kody-w/rapp-tower`, PRIVATE) provides the leak boundary:

- `tools/guard.sh <tree>` — secrets + denylist + secret-filename gate (exit 1 on
  hit). Verified working this session.
- `tools/leakcheck.sh <tree>` — the customer/work-name check it wraps.
- `sensitive/denylist.json` — the private canonical name list. **It lives ONLY in
  the tower and must never be copied into a brain repo** (that would publish the
  very names it protects). The brain's seam-guard *calls* the tower; it does not
  embed the list.

**Wire it as the brain's seam-guard** (put this in the public repo's
pre-push/pre-commit hook AND a GitHub Action — you cannot trust N autonomous
writers to each run it locally):

```bash
RAPP_TOWER="$HOME/Documents/GitHub/rapp-tower"
"$RAPP_TOWER/tools/guard.sh" .   # over the outgoing tree; abort push on exit 1
```

Off-machine (CI) the denylist isn't present, so the Action must run the generic
secret layer at minimum and treat the name layer as machine-only — OR store the
denylist as an encrypted Actions secret. Decide this when you build the Action.

## Private hemisphere SEED — real content, ready to ingest (not zero)

The private brain starts non-empty: this session's round-2 security pass IS
first-class private-brain content. Convert these tower artifacts into private
cards (pointers, never values):

- **Credential inventory** → `SECURITY.md` §4 + the secrets census in
  `work/2026-07-18-tower-blindspot-r2/FINDINGS.json` (token copies + paths +
  modes; the `localtoolsdev` public Azure-key leak — record as a pointer:
  "Azure key present in `localtoolsdev/my-agent-app/.env` — deprioritized by
  Kody"). NEVER transcribe a value.
- **Trust-boundary map** → `SECURITY.md` §1–3 (supply chain, agent execution,
  autonomous writers). Each is a private card with edges to the public nodes.
- **Autonomous-writer map** → `tools/fleet.sh` output (9 writers, states, kill
  commands) — the private "who mutates the estate" layer.
- **Standing oddities / decision log** → `work/2026-07-18-standing-oddities/`,
  `work/2026-07-18-legal-posture/` (trademark contradiction, license patchwork).
- **The tower itself** (checkouts registry, FLIGHT_RULES, RECOVERY) → the
  private ops layer.

## Real census (Fable's tested discovery, use these numbers)

`crawl-discover.reference.sh` ran live: **340 public · 141 private** kody-w repos
(≈481 non-archived; ~479 total). Two notes for whoever adopts it:
1. It correctly routes public→public seed, private→separate private location
   (never into the public tree). Verified.
2. The `estate-map.json` enrichment reported "340 frontier" because the JSON key
   for the repo list wasn't matched — **fix the parse** (`estate-map.json`'s repo
   array key is not `repos`/`estate`/`name`; inspect it) before trusting the
   in_estate_map column. The public/private split itself is correct.

## Phase plan (reconciled — both existing plans agree on this shape)

0. **Safety contract first** — wire the tower seam-guard before writing one
   public card. Visibility is ground truth, re-checked live per repo.
1. **Discover** — `crawl-discover` (adopt the reference or the repos' own);
   loop-until-dry on reference-crawl (grep cards for `github.com/kody-w/<repo>`).
2. **Deep-card each node** — a Workflow, one agent per node, schema-validated,
   sharded output (`public/notes/<repo>.md`), claim before work (CONCURRENCY.md).
   Public crawler reads PUBLIC bytes only; private crawler → private repo only.
3. **Edges + generated index** — `build.py` regenerates aggregates; writers never
   hand-edit them.
4. **Publish** — Pages + `llms.txt` for the public hemisphere; seam-guard on
   every push.
5. **Living brain** — wire to the drift machinery (rapp-map standing-guard,
   `tools/drift.sh`); scheduled re-crawl; `tools/secrets-watch.sh` over the estate.

## Do-not
- Do NOT create a third/fourth brain repo. Converge on one.
- Do NOT copy `sensitive/denylist.json` into any brain repo.
- Do NOT ingest secret values into either hemisphere — pointers only.
- Do NOT let both public brain repos run in parallel — pick one.

## Leak findings from the collapse leak-check (2026-07-18)

Running the tower `guard.sh` over the canonical public brain surfaced two
denylist terms. Recorded so the brain team fixes the systemic gap:

1. **`WorkIQ`** (work-data) — was in `brain/cards/repo_kody-w_cowork-cookbook-rapp.json`
   + `brain/inventory.json`. **Redacted** in the current tree (pushed to
   rapp-second-brain). History retains it; a purge is a Kody-decision.
   - **Root cause / new finding**: the SOURCE repo `kody-w/cowork-cookbook-rapp`
     is **PUBLIC and contains "WorkIQ" 6× in its own README** — a pre-existing
     work-data exposure the brain merely mirrored. Kody-decision: scrub or
     privatize that repo (same class as the localtoolsdev leak, lower severity).
2. **`aibast`** (6 files) — these are **legitimate public repo NAMES**
   (`aibast-agents-library`, `rapp-shape-aibast` are real public kody-w repos)
   and AIBAST is publicly referenceable as "Microsoft's distro of the Brainstem"
   (confident-host register). **NOT redacted** — redacting real public repo names
   would corrupt the brain.

**Systemic fix (brain team)**: the brain's `tools/leaktest.sh` reported CLEAN
while `WorkIQ` was present — its redaction list does **not** include the tower
denylist. Wire the brain's ingest/CI gate to call the tower `guard.sh`
(`RAPP_TOWER=~/Documents/GitHub/rapp-tower`), and give it a **public-repo-name
allowlist** so `aibast`-as-public-repo-name isn't a false positive while
`aibast`-as-work-context still trips. Off-machine CI won't have the denylist —
store it as an encrypted Actions secret or run the name-layer on-machine only.
