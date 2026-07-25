# Skill drift is coming for every agent ecosystem, and nobody is measuring it

*Draft — Kody Wildfeuer. Thesis piece. Not published.*

There are now more than five thousand skills in the OpenClaw registry. There are
twenty-one in my `~/.claude/skills`. There are fifty-one more in my openrappter
install, nine agents in my brainstem, and two runtimes on this laptop that hold
capabilities in shapes that cannot see each other.

Every one of those is a file that tells a model how to do something. And every
one of them is quietly rotting.

## The failure nobody logs

Take a skill written for one platform. Move it to another. What survives?

The prose survives — the paragraphs a model reads and follows. What doesn't
survive is everything *underneath* the prose: the typed contract that said this
capability accepts a `repo` and a `marker` and returns a URL, the commands that
were meant to run in order, the invariant that it never executes anything it
hasn't resolved. That layer was never written down in a form the next platform
could read, so the next platform re-derives it — or, more often, improvises it.

Do that once and the result looks fine. That is the whole problem. **Skill drift
is an accumulation failure.** Each individual hop is plausible. The prose still
reads correctly. A human reviewing the diff sees nothing alarming. Twenty hops
later the capability accepts different inputs than it claims, runs a subtly
different sequence, and no commit in the history is the one that broke it.

We have a word for this in every other part of software. We call it drift, and
we build oracles to catch it: type checkers, schema migrations, golden files,
contract tests. In the agent-skill ecosystem we have none of that. We have
markdown files, copied between platforms by hand, and vibes.

## Why a round trip proves nothing

The obvious test is: convert it there and back, check it matches.

I built exactly that, and it passed on every artifact I owned. Then I built the
test that actually matters and it failed twenty-six times.

A single round trip cannot see accumulation. Three properties can:

1. **Fixed point.** After one normalising pass, repeated conversion must stop
   changing bytes. If cycle 7 differs from cycle 6, it drifts.
2. **Path independence.** `A→B→A` and `A→C→D→E→A` must land on the *same bytes*.
   If the route changes the destination, your format is lying about being a
   projection of one underlying thing.
3. **Idempotence.** Converting to a format twice in a row is a no-op.

Running those across every real agent and skill on my machine — 6,138
conversions across 32 artifacts — found a bug that every single round trip had
passed: one projection re-emitted a platform-specific metadata key in its
frontmatter, so format *detection* reclassified the projection as the thing it
was projecting *from*, and reading it back overwrote the true original with a
derived copy.

The rule that fell out of that is the one I'd give anyone building this:

> **A projection must never be mistakable for the thing it projects from.**

## Raw bread and toast

Here is the part that took me longest to see, and it is the crux.

Before you can measure fidelity, something has to be *canonical*. A hand-written
`SKILL.md` has no canonical form — there's nothing underneath it to be faithful
to. So "did it round-trip?" is not a hard question, it is a **meaningless** one:
you are comparing two renders and asking whether they agree.

A raw skill file is **bread**. You cannot test bread for drift. You have to
**toast** it first: scan the prose, interpret whatever deterministic layer is
actually evidenced in it, and freeze that as the canonical record the artifact
now carries with it. Toasting is a chemical change, not a wrapper. You have to
put a stake in the ground somewhere, and the toast moment is that stake.

Everything after the stake is measurable. Nothing before it is.

The derivation has to be conservative or it is worse than nothing. A parameter
counts only if it appears inside a command the document actually gives; a
placeholder mentioned in a sentence is documentation, not an input. An explicit
contract the author wrote is never overridden — derivation only fills gaps.
Inventing a contract the author never implied doesn't help anyone; it silently
changes what the capability claims to accept, which is drift with extra steps.

## Two fidelities, and conflating them is how skills rot

**Transport fidelity**: can the original be recovered byte-exact later? This one
is fully solvable. Carry the canonical record *inside* the artifact — a
compressed capsule riding as an HTML comment in the markdown, invisible to every
host that doesn't care. Any platform can hand it on; any platform can recover it.

**Behavioural fidelity**: does it still behave deterministically *on the host*?
This one is **not** always solvable, and pretending otherwise is the lie that
gets you burned. It depends entirely on what the host can execute. So grade it
honestly instead of claiming every export is equal:

- **EXEC** — the host runs the real code. Byte-identical behaviour.
- **CODE** — the code travels in a fenced block; determinism only if the host runs it.
- **SPEC** — the typed contract travels; the model conforms to the interface but computes the answer itself.

The trick for getting EXEC on a platform that only eats markdown is to stop
*describing* the procedure and start *commanding a call*: ship the runnable file
next to the markdown, and have the markdown say **run this, do not improvise**.
Determinism survives because the same bytes execute. The host model never
paraphrases; it shells out.

And do not let the tool claim EXEC without executing the file first. Mine did,
once. I caught it because the tier said EXEC and the file couldn't import.

## What I actually found in the wild

I ran this against real skills from the OpenClaw registry, not fixtures.

They round-trip byte-exact — including a 35 KB prose skill — through four
different formats, 396 conversions, zero drift. That part works.

But the derivation on them is *modest*: one skill yielded a single typed
parameter and five lifted commands; another yielded none at all. Prose-heavy
skills simply don't declare much that can be recovered conservatively.

That is not a failure of the method, it is the measurement working. It says
something true and uncomfortable: **most skills in circulation today have almost
no machine-recoverable contract.** They are prose with a name on top. They work
because a capable model reads them charitably, and they will drift precisely
because nothing anchors them.

## The fix is not migration

The instinct when formats diverge is to converge them: pick a winner, write a
migration tool, deprecate the rest. That instinct is wrong here, and expensively
so. Nobody is going to migrate five thousand skills, and if they did, the next
platform would restart the problem.

The alternative is a **shim**: leave every artifact exactly where it is, in
exactly the format its platform wants, and make the canonical record travel
*inside* it. Formats stop being destinations you move between and become
simultaneous projections of one underlying thing. There is no cutover because
nothing is ever migrated.

This is also why the fidelity bar is so much higher than a migration would need.
A one-way conversion never has to come back, so it can be lossy and nobody
notices for a year. A shim is crossed continuously, in both directions,
unboundedly — which is precisely why it has to be byte-exact, and why an
accumulation oracle is mandatory rather than nice to have.

## What to do about it

You do not need my tooling. You need three things in whatever you build:

1. **A canonical record that travels inside the artifact.** If the capability
   can't carry its own truth, every platform boundary is a lossy re-render.
2. **A drift oracle that tests accumulation, not a single hop.** Fixed point,
   path independence, idempotence. Run it in CI. A single round trip will lie
   to you.
3. **Honest tiering.** Say what survives on this host and what doesn't. A tool
   that claims uniform fidelity across platforms that demonstrably differ is
   selling you drift with a confidence interval of zero.

Five thousand skills is a corpus. Corpora rot. We learned this with
dependencies, and we built lockfiles. We learned it with APIs, and we built
schemas. Skills are next, and right now the entire ecosystem is running on
copy-paste and good intentions.

The fix is not a standards committee. It is a stake in the ground and a test
that can tell you when you've moved off it.

---

*The implementation I describe is open source and stdlib-only:
[kody-w/rapp-toaster](https://github.com/kody-w/rapp-toaster). It converts
between `agent.py`, `SKILL.md`, and two other formats without losing fidelity,
and its `soak` command is the drift oracle described above. Take the ideas; the
code is one file if you want it.*
