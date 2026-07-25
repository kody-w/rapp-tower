# Skills are production infrastructure now. Nothing is stopping them from drifting.

**The case for a portability shim — for openclaw, and for everyone shipping skills.**

*Draft. Not submitted. Evidence in this document was produced against real
`openclaw/openclaw` skills, not fixtures.*

---

## I. Where we actually are

Something happened quietly over the last two years: **the skill became the unit
of capability exchange.** Not the library. Not the API. A markdown file with a
name, a description, and some prose telling a model how to do a thing.

The numbers are no longer small. The official OpenClaw Skills Registry has
**5,400+ skills**. `openclaw/openclaw` is at 384k stars. Claude Code ships a
skills directory. openrappter has its own. Microsoft Scout clones openclaw's
shape wholesale. On one developer laptop — mine — there are **82 capabilities
across four runtimes in four incompatible shapes**, and none of them can see
each other.

That is an ecosystem. And ecosystems this size stop being a convenience and
start being infrastructure. People are running businesses on these files. Agents
are editing these files. Skills call other skills.

Here is the uncomfortable part:

> **A skill is a production artifact with the change-control properties of a
> sticky note — and it executes against production systems with real
> credentials.**

No types. No schema. No lockfile. No test that fails when its meaning changes.
We took the least verifiable artifact in software — freeform prose — and made it
the interface between autonomous systems.

## II. The failure mode nobody logs

Take a skill. Move it somewhere else. What survives?

The prose survives. What dies is everything *underneath* the prose: the implicit
contract about what it accepts, the commands that were meant to run in order,
the invariant that it never executes anything unresolved. That layer was never
written in a form the next platform could read — so the next platform re-derives
it, or, far more often, improvises it.

Do that once and it looks fine. **That is the entire problem.** Skill drift is
an *accumulation* failure:

- every individual hop is plausible
- the prose still reads correctly
- a human reviewing the diff sees nothing alarming
- and twenty hops later the capability accepts different inputs than it claims,
  runs a subtly different sequence, and **no single commit is the one that broke
  it**

We solved this everywhere else in software. Dependencies drifted, so we built
lockfiles. APIs drifted, so we built schemas. Data drifted, so we built
migrations and contract tests. Skills are the newest production surface and they
have **none of it**.

And it is about to get much worse, for three reasons that are all accelerating:

1. **Registry scale.** 5,400 skills cannot be hand-reviewed for
   meaning-preservation. Nobody is even trying.
2. **Cross-platform copying is now normal.** A skill written for one runtime
   gets pasted into three others within a week. Each paste is a lossy re-render.
3. **Agents are editing skills.** The moment an agent rewrites a skill — to
   "optimize" it, to fix a failure — you have an autonomous system mutating
   production behaviour with no oracle watching. openclaw's own issue tracker
   has a live feature request for *auto-optimization on failure*. That is drift
   with a scheduler attached.

## II½. This is a liability, and it should be named as one

Everything above is an engineering problem. What follows is not — it is exposure,
and it is the reason this cannot wait for a tidier moment.

**Skills are not documentation. They are instructions executed against real
systems, with real credentials, by systems that act without a human in the
loop.** An openclaw skill runs `gh pr create`. Others touch cloud accounts,
customer records, payment flows, production infrastructure. The file is prose;
the consequences are not.

Now hold that next to four facts that are all true today:

1. **There is no integrity boundary on a skill.** No signature, no canonical
   form, no checksum of meaning. A skill that has been edited, re-rendered, or
   pasted through three platforms is indistinguishable from the one that was
   reviewed.
2. **Agents are being given permission to rewrite them.** openclaw's own tracker
   carries a live request for skill *auto-optimization on failure*. Whatever the
   merits, the shape of that is: **an autonomous system mutating production
   behaviour, on a trigger, with no oracle watching.** Nothing in the stack can
   currently answer "did that change what this capability does?"
3. **Drift does not fail loudly.** A drifted dependency crashes. A drifted skill
   keeps working and does the *wrong thing, confidently*, in a tone that reads
   exactly like the right thing. It will be found by its consequences, not by
   its errors.
4. **The corpus is shared and copied without provenance.** 5,400+ skills move
   between runtimes by copy-paste. There is no lineage, no "this came from
   there, unchanged."

Put together, that is a **supply-chain exposure with an autonomous mutation
path and no detection layer**. We have seen this exact shape before — in package
registries, in CI plugins, in browser extensions — and every time, the industry
paid for the lesson before it built the controls.

### The question nobody can currently answer

For any organisation running agents against systems that matter, one question
decides whether this is adoptable:

> **"Does this capability mean today exactly what it meant when we approved it?"**

Right now the honest answer is *we don't know, and we have no way to find out.*

That is not a gap you can paper over with process. You cannot attest to a control
you cannot prove is unchanged. Anyone operating under SOC 2, ISO 27001, HIPAA,
PCI, or an internal change-management regime is either going to be told they
cannot use skills in scope, or is going to say yes to something they cannot
evidence. Both outcomes are bad, and the second is worse.

And it lands on real parties: the **platform** that distributed a skill that
drifted, the **author** whose name is on it, the **enterprise** whose agent acted
on it, and the **registry** that served it. Today none of them can demonstrate
which version was in force at the time of an incident, because "version" isn't a
concept that exists for a prose file.

### We already have the shape that fixes it

This is the part worth sitting with: **nothing new has to be invented.** The
mechanism is already proven and running.

- A **canonical record that travels inside the artifact** turns "which version
  was in force?" from unanswerable into a byte comparison.
- A **drift oracle in CI** turns silent semantic change into a red build — the
  same way a failing contract test does for an API.
- **Byte-exact recovery** turns "has this been altered since review?" into a
  question with a yes-or-no answer, for any skill, at any point in its travels.

That converts a governance void into an ordinary, boring, testable control. Not
a new standard, not a committee, not a migration. A capsule and a test.

The corpus is 5,400 skills and growing, agents are starting to edit them, and
the detection layer is currently *zero*. The window where this is cheap to fix
is now, while it is a convention rather than an incident report.

## III. The instinct that will fail: converge the formats

The reflex when formats diverge is to converge them. Pick a winner. Write a
migration tool. Deprecate the rest.

That will not work here, and it is worth being blunt about why:

- **Nobody is going to migrate 5,400 skills.** Not for anyone.
- **Migration is terminal.** It implies a cutover, a deprecated old world, and a
  long tail of half-migrated artifacts that nobody owns.
- **It doesn't even solve the problem.** The next runtime that appears restarts
  it from zero.

A migration tool asks every ecosystem to become less itself. That is a tax with
no payer.

## IV. The alternative: don't move anything. Shim it.

**Leave every artifact exactly where it is, in exactly the format its platform
wants — and make the canonical record travel *inside* it.**

Formats stop being destinations you move *between*. They become **simultaneous
projections of one underlying thing**. There is no cutover because nothing is
ever migrated. openclaw skills stay `SKILL.md` in `.agents/skills/`. Permanently.
No frontmatter change, no new required fields, no deprecated path.

The mechanism is a compressed canonical record embedded as an HTML comment —
invisible to every renderer, ignored by every parser that isn't looking for it,
and sufficient for any platform to recover the original **byte-exact**.

There is an engineering tell that proves this is a shim and not a migration, and
it's worth stating plainly because it is falsifiable:

> **A migration tool would never need byte-exact round-tripping.**
> One-way conversions never come back, so they can be lossy and nobody notices
> for a year. Fidelity has to hold in *every* direction over *unlimited* hops
> precisely because a shim is crossed continuously. The drift oracle exists
> *because* it is a shim.

## V. What this gives openclaw specifically

### 1. A drift oracle — and you already believe in this

openclaw already ships
`extensions/oc-path/src/oc-path/tests/scenarios/roundtrip-property.test.ts`:

```ts
function roundTrip(raw: string): string {
  return emitMd(parseMd(raw).ast);
}
describe("roundtrip-property", () => {
  it("byte-fidelity over 100 generated shapes", () => {
```

**Byte-fidelity round-trip property testing over generated inputs.** That is
already openclaw's discipline, applied inside the markdown parser.

This is the same property, one altitude up: nothing today proves byte-fidelity
across a *platform boundary*, and that is exactly where a 5,400-skill corpus
loses its meaning.

A single round trip is not enough — I built that first and it passed on
everything. Three properties catch accumulation:

- **fixed point** — repeated conversion must stop changing bytes
- **path independence** — `A→B→A` and `A→C→D→E→A` must land on identical bytes
- **idempotence** — converting to a format twice is a no-op

Run over 32 real agents and skills — **6,138 conversions** — this caught a bug
every single round trip had passed: one projection re-emitted a
platform-specific metadata key, so format *detection* reclassified the
projection as the thing it was projecting *from*, and reading it back
**overwrote the true original with a derived copy**.

> A projection must never be mistakable for the thing it projects from.

That is one line of insight that cost 26 failing chains to find. It is now a
test anyone can run.

### 2. Every openclaw skill becomes a single-file, runnable agent — for free

This is the part with the largest upside, and it costs openclaw nothing.

Because the canonical record travels inside the artifact, an openclaw skill can
be projected into a **single self-contained Python file** — stdlib only, no
install, no framework, no runtime dependency on openclaw or on RAPP.

Run against `openclaw/openclaw`'s real `agent-transcript` skill:

```
INPUT   .agents/skills/agent-transcript/SKILL.md      4,048 bytes, untouched
OUTPUT  agent_transcript_agent.py                    16,982 bytes, stdlib-only
```

It declares a standard tool contract:

```json
{ "type": "function",
  "function": { "name": "AgentTranscript",
                "description": "Add a redacted agent transcript section to GitHub PR or issue bodies…",
                "parameters": { "type": "object", "properties": {}, "required": [] } } }
```

It **runs**, with no framework present, and resolves the skill's own documented
commands deterministically:

```json
{ "status": "ok",
  "steps": ["gh pr create --body-file", "open", "open /tmp/agent-transcript-preview.html"] }
```

And it converts **back**:

```
toasted skill   9533645ba9992cbc   6,901B
round-tripped   9533645ba9992cbc   6,901B
IDENTICAL: True
```

openclaw gets its own file returned, byte for byte.

**Why this matters for shareability.** Today, sharing an openclaw skill means
sharing a file that only means something inside openclaw. After this, the same
skill is *additionally*:

- a file anyone can `python3 <file>.py` with zero install
- a standard function-calling tool definition any LLM stack can consume
- droppable into a RAPP brainstem, or any runtime that reads single-file agents
- **and still a perfectly normal openclaw skill**, unchanged

That is a step change in reach for the registry, achieved without asking a
single skill author to do anything differently. The 5,400 skills become 5,400
portable, runnable artifacts — and openclaw becomes the place they came from.

## VI. What everyone else gets

The same thing, which is the point. A shim is only worth building if it is
non-partisan:

- **Skill authors** write once and their work runs in more places, with a test
  that tells them when it stops meaning what they meant.
- **Runtimes** (Claude Code, openrappter, Scout, whatever ships next quarter)
  consume the corpus without asking anyone to convert to their shape.
- **Enterprises** get the thing they actually need and currently cannot buy:
  **a skill that provably has not drifted since review.** For anyone running
  agents against production systems, "this capability means today exactly what
  it meant when we approved it" is not a nice-to-have. It is the audit.
- **Downstream clones** inherit it. Microsoft Scout carries openclaw's shape, so
  it carries openclaw's drift problem; fix it upstream and Scout inherits the
  fix. Fix it in a clone and you have a fork.

## VII. What I am not claiming

Credibility here depends on the limits being as loud as the pitch.

- **This does not make prose skills deterministic.** Derivation on real registry
  skills is modest: `autoreview` yielded 1 typed parameter and 5 lifted
  commands; `agent-transcript` yielded 0 parameters and 3 commands. Prose-heavy
  skills simply do not declare much that can be recovered *conservatively*, and
  inventing a contract the author never implied would be drift with extra steps.
- That result is itself the finding, and it is the uncomfortable one:
  **most skills in circulation today carry almost no machine-recoverable
  contract.** They work because a capable model reads them charitably. They will
  drift because nothing anchors them.
- **Behavioural fidelity is not uniform and should never be sold as such.** It
  depends on what the host can execute. Grade it honestly — the host runs the
  real code (`EXEC`), the code travels but may not run (`CODE`), or only the
  typed contract travels (`SPEC`). A tool claiming uniform fidelity across
  demonstrably different platforms is selling drift with a confidence interval
  of zero.
- **This is one file of Python and a set of properties.** The ideas matter more
  than the implementation. Take the properties; reimplement them in TypeScript
  inside `oc-path` if that is the right home.

## VIII. The ask

Small, reversible, and sequenced so it can be evaluated on merit:

1. **A conversation, on the existing thread.** openclaw issue
   [#45993](https://github.com/openclaw/openclaw/issues/45993) asks for a
   cross-platform migration tool. The useful answer is *you may not need one* —
   a shim dissolves the requirement. Attached to that thread, not a competing
   issue.
2. **An optional CI workflow** running the drift oracle over `.agents/skills/`.
   Pure addition. No runtime change. Trivially revertible. This is where the
   value is provable without adopting anything.
3. **Only then**, a discussion about the capsule — additive, invisible, and
   nothing changes for skill authors.

**One blocker to clear first:** `openclaw/openclaw` reports
`license.spdx_id = NOASSERTION`. The implementation is Apache-2.0. Nothing
should move in either direction until the licensing is understood.

---

## The one-paragraph version

Skills became production infrastructure without acquiring any of the safety
properties production infrastructure has — no integrity boundary, no version
that means anything, no way to prove a capability still means what it meant when
it was approved. They drift silently, at registry
scale, and agents are now editing them autonomously. Converging the formats
won't happen and wouldn't fix it. Instead, let every skill carry its own
canonical record so all formats become simultaneous projections of one thing —
no migration, no cutover, nothing deprecated. You get a drift oracle that fails
when meaning changes, and every skill becomes a single-file runnable agent for
free. openclaw's skills stay exactly as they are, and reach considerably
further.

---

*Implementation: [kody-w/rapp-toaster](https://github.com/kody-w/rapp-toaster) —
one stdlib-only Python file, Apache-2.0. `soak` is the drift oracle. Every
number in this document is reproducible against it.*
