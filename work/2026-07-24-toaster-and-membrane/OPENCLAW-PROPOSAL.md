# Proposal to openclaw: a drift oracle for the skills registry

**Status: DRAFT — not submitted. Kody's call whether this goes anywhere.**

Target: `openclaw/openclaw` (384k★). Related: `VoltAgent/awesome-openclaw-skills`
(51k★, 5,400+ skills from the official registry).

---

## Read this first — how to pitch it, and how not to

**Lead with the problem, not with lineage.** Kody's point that RAPP shaped this
space before openclaw existed, and that RAPP later adopted openclaw's shape
because that shape went viral, is almost certainly true and is *worth telling* —
but a priority claim is the wrong opening move to a 384k-star project. It
invites an argument about history instead of a conversation about a bug, and it
makes a good technical contribution look like a flag-planting exercise.

Put the lineage in the blog post, in your own voice, on your own surface. Keep
the PR on merit. If maintainers get curious about where the ideas came from,
that is a much better moment to tell the story than paragraph one.

**Do not oversell the derivation.** I tested this against real registry skills.
The honest result: `autoreview` yielded 1 typed parameter and 5 lifted commands;
`agent-transcript` yielded none. Prose-heavy skills don't declare much that can
be recovered conservatively. Claiming "this makes your skills deterministic"
would be false and would be caught in review within a day.

The defensible claim is narrower and stronger:

> The registry has 5,400+ skills and no way to detect when one silently changes
> meaning as it moves between platforms or gets edited. Here is an oracle for
> that, and it works on your actual skills today.

---

## The problem, in openclaw's own terms

openclaw skills are `.agents/skills/<name>/SKILL.md` — YAML frontmatter plus
prose, often with a sibling `scripts/` directory. That shape is good. It already
pairs instructions with executables, which is more than most ecosystems do.

What it lacks is anything canonical *underneath* the prose. A skill's real
contract — what it accepts, what it runs, in what order — lives only in
paragraphs. Which means:

- **Nothing detects semantic drift.** Edit a skill, or move it between a
  platform that reads frontmatter and one that doesn't, and the prose survives
  while the implied contract quietly changes. No test fails.
- **Cross-platform copies are lossy re-renders**, not transfers. There is no
  record of what the original meant, so the destination re-derives it.
- **At 5,400 skills this is a corpus problem**, not a per-skill problem. Nobody
  can hand-review that for meaning-preservation.

## What we're offering

[`kody-w/rapp-toaster`](https://github.com/kody-w/rapp-toaster) — one
stdlib-only Python file, Apache-2.0, no install, no dependencies.

Two things openclaw could use independently of each other:

### 1. `soak` — a drift oracle for CI

Tests the three properties a single round trip cannot see:

- **fixed point** — repeated conversion must stop changing bytes
- **path independence** — every route must land on identical bytes
- **idempotence** — converting twice is a no-op

Run it over the registry in CI and a skill that changes meaning goes red. This
is the part with the clearest standalone value to openclaw and requires adopting
nothing else.

### 2. A capsule that makes skills portable without changing their shape

A compressed canonical record embedded as an HTML comment. Invisible to every
renderer, ignored by every parser that doesn't look for it, and it lets any
platform recover the original byte-exact. `SKILL.md` stays exactly as it is
today — no frontmatter changes, no new required fields, no migration.

## Evidence — run against real openclaw skills, not fixtures

| Skill | Size | Result |
|---|---|---|
| `.agents/skills/autoreview/SKILL.md` | 35 KB prose | round-trips **byte-exact** through 4 formats |
| `.agents/skills/agent-transcript/SKILL.md` | 4 KB | round-trips **byte-exact** |

**396 conversions across both, zero drift**, path-independent and fixed-point
stable in every direction.

Derivation results, stated honestly: `autoreview` → 1 typed parameter, 5 lifted
commands. `agent-transcript` → 0 parameters, 3 commands. Prose-heavy skills
yield little. That is the measurement working, and it is itself a finding worth
the maintainers' attention: most skills in circulation carry almost no
machine-recoverable contract.

Broader validation: 6,138 conversions across 32 real agents and skills, zero
drift. The oracle earned its keep by catching a bug every single round trip had
passed — a projection was re-emitting a platform-specific metadata key, so
format detection reclassified it as the thing it was projecting from and
overwrote the original with a derived copy.

## Why this is worth a partnership, not just a PR

openclaw and openrappter solve overlapping problems from different ends.
openclaw has enormous distribution and a real skill corpus. RAPP has spent its
time on the deterministic layer — typed contracts, single-file portable agents,
provenance. Neither side needs the other to change shape:

- openclaw skills stay `SKILL.md`. No format change, no migration.
- The capsule is additive and invisible.
- The oracle is a CI job that can be adopted or ignored per-repo.

The shared interest is that **a skill written once should mean the same thing
everywhere it lands**, and neither ecosystem can guarantee that alone.

## They already believe in this — lead with THEIR prior art

I did the search this doc demanded, and it changed the pitch. openclaw ships
`extensions/oc-path/src/oc-path/tests/scenarios/roundtrip-property.test.ts`:

```ts
function roundTrip(raw: string): string {
  return emitMd(parseMd(raw).ast);
}
describe("roundtrip-property", () => {
  it("byte-fidelity over 100 generated shapes", () => {
```

They are already doing byte-fidelity round-trip property testing over generated
inputs. That is the *same discipline*, applied one level down — inside their
markdown parser.

**So do not present round-tripping as a new idea to them. It is theirs.** The
pitch is: you already prove byte-fidelity across `parseMd`/`emitMd`; nothing
proves it across a *platform boundary*, and that is where a 5,400-skill corpus
actually loses meaning. Same property, one altitude up.

## Suggested first step — attach to an OPEN issue, don't open a new one

Two live issues are already asking for pieces of this:

| Issue | Why it's the door |
|---|---|
| [#45993 — Feature Request: Cross-platform migration tool (migrate export/import)](https://github.com/openclaw/openclaw/issues/45993) | **This is literally the toaster.** Someone has already asked for the thing. Comment there with the working implementation and the evidence. |
| [#57091 — Improve Workspace Skill Loading: frontmatter parsing error visibility and validation for SKILL.md](https://github.com/openclaw/openclaw/issues/57091) | Skill validation. `soak` is the accumulation-level companion to their per-file validation. |

Sequence:

1. **Comment on #45993** with the drift argument, the evidence, and a link to
   the repo. Do not open a competing issue.
2. Offer `soak` as an **optional CI workflow** against `.agents/skills/` — pure
   addition, no runtime change, trivially revertible.
3. Only if that lands, discuss the capsule.

Opening a large PR into a 384k-star project's core is how good ideas get closed
unread. Answering an open feature request with a working implementation is how
they get merged.

## Downstream: Microsoft Scout — hit the source first

Scout is an openclaw clone and carries the same shape, so the same drift
problem exists there by inheritance. Kody's sequencing is right and it is worth
stating explicitly in any conversation:

> **Fix it at openclaw and Scout inherits it. Fix it at Scout and openclaw
> doesn't.** A convention adopted upstream flows down to every clone; a
> convention adopted in one clone is a fork.

So: openclaw first, deliberately. Do not split the effort, and do not pitch
both in parallel — a maintainer who sees the same proposal in two places reads
it as spray, not as a considered contribution.

**Hard constraint on the Scout side.** `microsoft/*` is push-forbidden under
the estate's iron laws, and PRs to Microsoft repos are manual under SAML. So
Scout is *never* an autonomous action: it is Kody, by hand, through Microsoft's
internal process. Treat the Scout conversation as a follow-on that only starts
once openclaw has responded — and note that Scout inheriting it from upstream
is a much easier internal sell than "adopt my external tool."

There is existing surface area to build on: the RAPP `issue_triage_agent.py`
already references Scout RFC #3997 and notes that a single-file agent's
metadata block is what would register as a squad member under Scout's crews
layout. That is the natural bridge when the time comes.

## 🔴 Licence blocker — resolve BEFORE any code moves

`gh api repos/openclaw/openclaw` reports **`license.spdx_id = NOASSERTION`** —
GitHub cannot identify a standard licence for the repo. rapp-toaster is
Apache-2.0.

Do not contribute code, and do not accept code from them, until you know what
their terms actually are. Read their LICENSE/COPYING and CONTRIBUTING before
step 1 above. Commenting on an issue with a link is safe; landing files is not,
yet.

## Honest risks

- **Partly solved already, and that's good news.** They have round-trip
  property tests inside `oc-path`, and two open issues asking for migration and
  skill validation. Nothing found does cross-platform drift detection. Read
  #45993's full thread before commenting — someone may have started.
- **"Not invented here" is real** at this scale, and the capsule touches every
  skill file. The CI-oracle-first sequencing exists to de-risk exactly that.
- **The lineage story could sour it** if it leads. See the top of this doc.
- **Licence is NOASSERTION** — see the blocker above. This is the one item that
  can stop the whole thing, so check it first, not last.
