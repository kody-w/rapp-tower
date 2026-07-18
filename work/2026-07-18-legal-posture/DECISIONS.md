# 2026-07-18 — Legal/IP posture: license patchwork + trademark contradiction

Verified by reading the repos + `gh api .../license` on 2026-07-18. These are
Kody-decision items (and several ride the train to reach the grail). The tower
records the exact state + a recommendation; nothing here is auto-applied.

## 1. License patchwork (confirmed)

| Repo | License (GitHub) | Reality |
|---|---|---|
| `rapp-installer` (**GRAIL**) | **NONE** | all-rights-reserved — users have **no legal right to run the installer everyone runs** |
| `rapp-canary` (ring) | **NONE** | same; the ring pipeline republishes unlicensed code |
| `rapp-nightly/alpha/beta` | none/unset | same class |
| `RAR` | MIT | permissive |
| `rapp-map` | MIT | permissive |
| `RAPP` | NOASSERTION (custom) | `TRADEMARK.md` declares **PolyForm Small Business 1.0.0** (code) + **CC BY-NC 4.0** (docs) — source-available, NOT OSI-open, non-commercial |
| `rapp-train` | NOASSERTION | custom |
| Landgrab `rapp-*` repos | MIT + DISCLAIMER (per prior baton) | permissive |

**The contradiction that bites**: a user installs the MIT-licensed everything via
an **unlicensed** installer that pip-installs into a **PolyForm-non-commercial**
core. A single distribution chain spans MIT ↔ no-license ↔ non-commercial. A
lawyer (or a cautious enterprise adopter) cannot answer "may I run this
commercially?" — and today the honest answer for the grail is "no license grants
you anything."

**Recommendation (Kody):** pick ONE coherent posture and make it consistent
across the install chain. If the intent is "free front door, tolled cloud tier"
(per TRADEMARKS.md), the grail + rings should carry an explicit permissive or
source-available LICENSE that *matches* what RAPP core claims. Adding a LICENSE to
the grail **rides the train** (branch on canary → … → human merge) — it cannot be
pushed to `rapp-installer` directly.

## 2. Trademark contradiction (confirmed — read both docs)

Two live, public trademark documents disagree on owner AND scope:

| | `rapp-train/TRADEMARKS.md` | `RAPP/TRADEMARK.md` |
|---|---|---|
| **Owner** | **Wildhaven Homes LLC** | **Kody Wildfeuer** (personal; "Copyright (c) 2026 Kody Wildfeuer") |
| **"RAPP" alone** | **deliberately NOT claimed** ("the stem is open") | **claimed** as a mark |
| **brainstem** | **deliberately unencumbered** ("the front door is never tolled") | **claimed** ("brainstem when used in conjunction with any of the above") |
| Licenses cited | Apache-2.0 / CC-BY (per prior baton) + no-mark-grant | PolyForm SB 1.0.0 + CC BY-NC 4.0 |

**Why it matters**: a defendant contesting the marks can point to Kody's own
public, self-contradicting claims — one document disclaiming exactly what the
other claims, split between a personal name and an LLC with no assignment on
record — as evidence the marks are neither consistently used nor clearly owned.
That undercuts the common-law claim the whole TRADEMARKS.md rests on ("public use
+ dated git history serve as record of use"). And the git-history-as-evidence
base is itself unsigned and force-pushable.

**Recommendation (Kody):** decide **one owner** (Wildhaven Homes LLC vs personal)
and **one scope** (is "RAPP" alone and "brainstem" claimed or free?), then:
1. Make the two docs say the same thing (retire one, or make `RAPP/TRADEMARK.md`
   defer to the canonical `TRADEMARKS.md`).
2. Record the assignment (personal→LLC or vice-versa) so ownership is provable.
3. Protect the evidence base: branch-protection + no-force-push on mark-bearing
   public repos, and an annotated dated tag whenever a TRADEMARK doc changes.

## 3. Contributor licensing (needs audit — do not assert numbers yet)

Community agents enter RAR by issue-paste with **no CLA/DCO**. Without a
contributor grant, Kody cannot safely relicense or confidently redistribute
third-party agents. A round-2 lens claimed "RAR strips the MIT notice from 127
Microsoft-copyright files" — **that was overclaimed**: a direct check found **0**
Microsoft-copyright files in the RAR working tree. Before making any attribution
claim, run a real license audit of RAR contents (`grep -rl 'Copyright' RAR`,
check provenance of Bill Whalen / Howard Hoy agents). Adding a lightweight DCO
("Signed-off-by") to the submit flow is the cheap forward fix.
