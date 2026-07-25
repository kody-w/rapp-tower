# The OpenRappter Foundation — draft charter

**Status: DRAFT for Kody. Not published, not filed, not announced.**
Chartered as a stewardship program of **Wildhaven Homes LLC**.

---

## Why this exists

openclaw ships under **"OpenClaw Foundation"** (their MIT copyright line). That
name does real work: it signals that the open surface has a *steward* rather than
an owner, that it will outlive any one contributor, and that a partner is talking
to an institution rather than to a person.

RAPP's open surface currently has no such name. Every public artifact resolves to
an individual GitHub account. That is a weaker posture than the work deserves,
and it makes a partnership conversation asymmetric before it starts:
**foundation-to-individual reads differently from foundation-to-foundation**,
regardless of the technical merits underneath.

An OpenRappter Foundation closes that gap without changing a single thing about
how the code is built or licensed.

## 🔴 The one decision only Kody can make

**"Foundation" carries a connotation of charitable or non-profit status.** Two
honest options, and they are genuinely different:

| Option | What it is | Cost | Honest framing required |
|---|---|---|---|
| **A. Stewardship name** *(recommended to start)* | A trade name / program of Wildhaven Homes LLC. No separate legal entity. | Zero. Available today. | The charter must **say so plainly**: "a stewardship program of Wildhaven Homes LLC." |
| **B. Incorporated non-profit** | An actual 501(c)(3) or equivalent, with a board and filings. | Real money, real time, ongoing compliance. | Nothing extra — it is what it says. |

**Do not do A while implying B.** Using "Foundation" as a bare label, with no
stated relationship to Wildhaven, invites a reader to assume non-profit status
that does not exist. That is a small misrepresentation with a large downside —
especially when the whole point is to stand next to another organisation's
Foundation. One sentence of disclosure removes the risk entirely and costs
nothing in credibility. It arguably *adds* some: stating your structure plainly
is what an institution does.

Note also that openclaw's own Foundation may be either A or B — their org is
unverified with no published governance document. So A puts you on exactly the
footing you are matching, not a lesser one.

## What it stewards

The **open surface** of the RAPP ecosystem — the parts intended to be freely
used, forked, taught, and redistributed:

- **rapp-brainstem** — the free front door. Deliberately unencumbered.
- **rapp-toaster** — the portability shim and drift oracle (Apache-2.0).
- The **published specs** — `rapp-neighborhood-protocol`, `rapp-twin-chat`,
  `rapp-holo`, the agent contract, and the interchange format.
- The **public registry** surfaces — RAR and the ring installers.
- **Interoperability work with other ecosystems**, which is the immediate reason
  this is being chartered.

It does **not** steward private work, customer material, or anything inside the
two-worlds boundary. Those are Wildhaven's and stay there.

## What it does not change

This charter is deliberately conservative. It **preserves the existing
trademark record exactly** as published at
[TRADEMARKS.md](https://kody-w.github.io/rapp-train/TRADEMARKS.md):

- **Compound marks** (`rapp-*`, "RAPP <thing>", CommunityRAPP™, RAR™, Rappter™,
  The RAPP Train™) remain claimed by **Wildhaven Homes LLC** at common law.
- **"RAPP" standing alone remains deliberately unclaimed.** The stem is open.
- **The RAPP Brainstem remains deliberately unencumbered** — anyone may run,
  name, teach, and redistribute it.
- Open-source licences on the code continue to grant **no rights to the marks**.

The Foundation is a **steward of the open surface, not a new claimant**. If this
charter ever appears to expand a mark claim, the published trademark record
governs and this document is wrong.

## Governance, honestly scoped

At Option A scale, "governance" means a small number of written commitments, not
a board:

1. **The open surface stays open.** Anything listed above stays under a
   permissive licence. No relicensing of already-published open artifacts to a
   restrictive licence.
2. **Specs are public and versioned.** A published spec is not silently edited;
   changes are versioned, the way `rapp-neighborhood-protocol/1.0` already is.
3. **Interop before extraction.** Work with other ecosystems is offered on
   merit — no capture, no telemetry as a condition of use, no requiring adoption
   of RAPP's shape to benefit.
4. **The boundary holds.** Work and customer material never enter Foundation
   surfaces. This is already the estate's iron law; the charter restates it.
5. **Provenance is honest.** Where prior art shaped the work, it is credited;
   where RAPP's own shape was later adopted by others, that is stated as history,
   not as a claim against them.

Point 5 is deliberate. It is the disciplined version of the lineage story — it
belongs in a charter and in a blog post, and not in the opening paragraph of a
pull request to somebody else's repository.

## Immediate practical effect

- Copyright lines on Foundation-stewarded repos can read
  **"© 2026 OpenRappter Foundation, a stewardship program of Wildhaven Homes LLC"**
  — matching openclaw's posture, with the structure disclosed.
- The openclaw conversation becomes **Foundation → Foundation**, which is the
  right footing for proposing an interoperability convention.
- Scout and any other downstream adopter has an institution to reference rather
  than a personal account.

## What I'd do next, in order

1. **Decide A or B.** A is available today and is what I'd start with.
2. **Add the disclosure sentence** to the charter and to the copyright line.
   This is the whole of the legal hygiene at Option A.
3. **Do not announce it separately.** Let it appear as the steward name on the
   toaster and the specs, and it becomes true by use — the same way the marks
   were established.
4. Only consider B if a partner, a grant, or a governance requirement actually
   asks for it. Incorporating ahead of need buys compliance overhead and nothing
   else.

---

*Every trademark statement here is copied from the published record rather than
restated from memory. If they conflict, the published record wins.*
