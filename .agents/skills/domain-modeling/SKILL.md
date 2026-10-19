---
name: domain-modeling
description: Agree canonical terms with the stakeholder and record decisions. Use when a request or answer uses a new, ambiguous or conflicting term, when a new concept has no canonical name, at the feature-workflow term gates (0.2.2, 0.3.14, 0.4.2), when writing, editing or superseding an ADR (including the placement ADR at 0.3.7), or when writing or editing GLOSSARY.md.
---

<!--
Sources: adapted from mattpocock/skills skills/engineering/domain-modeling/SKILL.md (MIT, Copyright (c) 2026 Matt Pocock; commit 49dd158; notice in ./LICENSE). Changes: scoped to the term gates and ADRs (D10); stakeholder agreement before each glossary write; step marker before Tier A writes (D16); placement and superseding flow for 0.3.5-0.3.7; naming baseline for review-standards; paths moved to docs/decisions/adr/. Plan: PLAN/decision-flow-reference.md 00.1, 00.4, 0.2.2-0.2.3, 0.3.5-0.3.7, 0.3.14-0.3.15, 0.4.2-0.4.3, 5.3; assetlist D8, D10, D16, D21, D51.
-->

# Domain Modeling

Build and sharpen the project's domain model as you design: challenge terms, invent edge-case scenarios, and write the glossary and decisions down the moment they crystallise. Reading `GLOSSARY.md` for vocabulary is a habit any skill can have; this skill is for changing the model.

## Files

- `GLOSSARY.md` at the repo root, or one per context listed in a root `GLOSSARY-MAP.md`. Format: [assets/GLOSSARY-FORMAT.md](assets/GLOSSARY-FORMAT.md).
- `docs/decisions/adr/NNNN-slug.md`. Format and test: [assets/ADR-FORMAT.md](assets/ADR-FORMAT.md). Template: [assets/adr.md](assets/adr.md).

Create files lazily: only when you have something to write. Write them from the main session: the Tier A write guard denies writes made inside a sub-agent (D16).

## Set the step before a Tier A write

`GLOSSARY.md` and `docs/decisions/` are Tier A. Inside a feature (a `specs/NNN-slug/` folder is in flight), set the step marker before each write so `tier-a-write-guard` allows it:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug <node-id>
```

| Write | `<node-id>` |
| --- | --- |
| Glossary entry agreed at term gate 0.2.2 | `0.2.3` |
| Glossary entry agreed at term gate 0.3.14 | `0.3.15` |
| Glossary entry agreed at term gate 0.4.2 | `0.4.3` |
| Placement ADR, and marking a superseded ADR | `0.3.7` |
| Glossary entry from a proposal approved at sign-off (D51) | `5.3` |

Glossary files are writable only at the three agree-definition steps and at 5.3 (D51). At 5.3, `sign-off` applies the approved `proposals.md` entries; when one is a glossary change, write it exactly as approved, in the glossary format, under step `5.3`.

If the guard denies a write, stop and report the denial with the agreed text. Write Tier A files only through Write or Edit, never through Bash.

## Term gates

| Gate | Fires when | Agree at |
| --- | --- | --- |
| 0.2.2 | The request uses a new, ambiguous or conflicting term | 0.2.3 |
| 0.3.14 | An answer introduces a new or conflicting term | 0.3.15 |
| 0.4.2 | A new concept has no canonical name | 0.4.3 |

At each gate, agree the term inline with the stakeholder, who is already in the conversation:

1. **Challenge against the glossary.** When a term conflicts with `GLOSSARY.md`, say so at once: "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"
2. **Sharpen fuzzy language.** For a vague or overloaded term, propose a precise canonical term: "You're saying 'account': do you mean the Customer or the User? Those are different things."
3. **Discuss concrete scenarios.** Stress-test the relationships with scenarios that probe the boundaries between concepts.
4. **Cross-reference with code.** When the stakeholder states how something works, check whether the code agrees, and surface any contradiction: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"
5. **Propose the entry.** Give the canonical term, a one or two sentence definition and the `_Avoid_` aliases, with your recommendation. The stakeholder confirms or corrects it.
6. **Write it now.** Set the step, then update `GLOSSARY.md` per the format. Capture each term as it is agreed rather than batching.

The gate is done when every term it raised is either in `GLOSSARY.md` as agreed, or the stakeholder confirmed it means an existing entry.

### Glossary only

`GLOSSARY.md` holds terms and nothing else: no implementation details, no spec, no scratch notes, no decisions. Every fact has one home: rationale in an ADR, schema in the feature's `data-model.md`, per-feature decisions in `design-log.md`.

### Naming baseline

`GLOSSARY.md` is the naming baseline for `review-standards` (4.1). Code, docs and specs use the canonical term. An `_Avoid_` alias used where a canonical term exists is a naming finding; "Flagged ambiguities" gives the settled resolution.

## ADRs

### The three-part test

Write or offer an ADR only when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. [ADR-FORMAT.md](assets/ADR-FORMAT.md) lists what qualifies.

### Placement (0.3.5-0.3.7)

After placement is resolved at 0.3.4:

1. **0.3.5 Conflict check.** Compare the placement with the ADRs in `docs/decisions/adr/` and with `docs/rules.md`. A rule conflict becomes a 5.3 proposal, not a mid-feature override.
2. **0.3.6 Conform or supersede.** For an ADR conflict, the stakeholder chooses: revise the placement to conform, or supersede the ADR.
3. **0.3.7 Write the placement ADR.** Apply the three-part test; a resolved ownership boundary is a boundary decision. Set the step to `0.3.7`, copy [assets/adr.md](assets/adr.md) to the next number, and fill it in. When the placement supersedes an ADR, follow "Superseding an ADR" in [ADR-FORMAT.md](assets/ADR-FORMAT.md): the new ADR names the one it replaces, and the old one stays in place, marked `status: superseded by ADR-NNNN`, body unchanged.

If the placement fails the test, record it in the feature's `design-log.md` instead.

### Other ADRs

Inside a feature, the guard admits ADR writes only at 0.3.7 (and at 5.3 and 5.7, owned by other steps). An ADR that passes the test elsewhere goes to `proposals.md` for approval at 5.3 (D21).

## Done

- Every term raised at a gate is agreed and written, or confirmed as an existing entry.
- Every ADR written passes the three-part test and follows ADR-FORMAT.md; every superseded ADR is marked and unchanged otherwise.
- No Tier A write happened without the matching step set.
