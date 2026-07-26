# RAPP Tools quartet — findings that need Kody, not me

Date: 2026-07-26
Session: built and adversarially reviewed four local-first tools (rapp-shot,
rapp-voice, rapp-crispy, rapp-rewind) plus the `rapp-tools` fleet CLI; published
to RAPP_Store and cubbied in the private batcave.

Everything in the four tools is fixed and pushed. The items below are **not**
mine to act on: two are pre-existing estate state I did not create, one is a
defect in a repo outside this work, and one is a standing imprecision I chose to
leave rather than churn versions.

---

## 1. 🔴 `channel-secret.json` is TRACKED IN GIT in kody-w/rapp-batcave

`tools/guard.sh` on a fresh clone of the batcave:

```
SECRET-FILE TRACKED IN GIT: .../bc
    channel-secret.json
```

Introduced by commit `7bc492e` ("Add the §8 sealed-channel secret
(collaborator-gated key material)") — a different session, deliberately. The
batcave is private, so this is not a public exposure, but it violates the iron
law that **secrets never enter ANY repo, public or private — record a pointer,
never the value.**

**Why I did not act:** rotating the channel key and purging git history are both
consequential and irreversible, and the commit message suggests the placement
was intentional. If it was, it deserves a standing-oddities entry saying so.

**Options:** (a) confirm intentional and record it in
`work/2026-07-18-standing-oddities/`; (b) rotate the key, move the value to the
keychain, commit a pointer, and purge history.

## 2. 🟠 Work/customer content is in the batcave, which is a kody-w personal repo

Same gate run:

```
LEAK (in HEAD tree): 'aibast':
    cubbies/kody-w/agents/transcript2prototype_agent.py
    cubbies/kody-w/rapplications/transcript2prototype/GRAIL_SPEC.md
    cubbies/kody-w/rapplications/transcript2prototype/transcript2prototype_agent.py
    rapplications/project-tracker/README.md
LEAK: 'CORO' / 'MVW' / 'WorkIQ' also present
```

CLAUDE.md is explicit: work/customer content never lands in a kody-w personal
repo, **including the private one** — the two-worlds boundary is not a
public/private distinction. Pre-existing, from other sessions.

**Why I did not act:** removing it means rewriting history in a repo parallel
sessions are actively using.

**What I did instead:** gated only my own delta. Every batcave push this session
was verified CLEAN on the changed files alone (four eggs + four `cubby.json`),
never on the whole tree.

## 3. 🟠 kody-w/RAPP_Store silently loses promotions

`staging/_pending.json` is a single shared file, and each workflow run checks out
`main` at its own start. Editing several submissions at once makes the Process
runs race; the last writer wins and the other items vanish. Their Approve runs
then find nothing — and **two of them still commented "✅ Approved and promoted",
applied the `promoted` label, and closed the issue** while the catalogue was
never touched.

Observed: 4 issues approved, 4 marked `promoted`, 2 actually in `index.json`.

**Workaround used:** publish strictly one issue at a time, end to end, and verify
against `index.json` rather than the workflow's own claim. Script kept at
`work/2026-07-26-rapp-tools-quartet/publish_serial.sh`.

**Smallest real fix (in RAPP_Store, not done here):** the Approve workflow must
fail when `promote_rapplication.py` reports `E_NO_PENDING_FOR_ISSUE` instead of
labelling and closing; and `_pending.json` should be per-issue
(`staging/pending/<n>.json`) so runs cannot clobber each other.

## 4. 🟡 Two catalogue entries record a slightly stale `commit_sha`

`rapp_rewind` and `rapp_voice` point at the commit before their last (content-
neutral) push. Their `singleton_sha256` matches what the raw URL serves today, so
the entries are accurate about **content**; only the recorded provenance lags.
Correcting it requires a version bump the store demands for any re-promote, and
bumping a version for an unchanged artefact is worse than the imprecision.

---

## Standing note for whoever ships the next version of these tools

`rapp-tools/tools/rebuild-eggs.sh` is the only correct way to rebuild an egg —
it packs deterministically, syncs the twin agent from the singleton, and
restamps `egg_sha256`/`egg_bytes`/`version` in the catalogue. `--check` is the
oracle; it is read-only and reports DRIFT, STALE-EGG, STALE-SHA, STALE-BYTES.
`rapp-shot/tools/mutate.sh` must stay at 0 unexpected survivors: six review
rounds in a row, a green suite that could not fail was what let the next defect
through.
