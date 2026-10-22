<!--
File: Template for .workflow/specs/NNN-slug/design-log.md: the append-only decision log for one feature. No frontmatter. An initiative keeps the same log at .workflow/initiatives/NNN-slug/design-log.md: conversion moves the spec's log there and replaces its `Spec:` line with `Initiative: [initiative.md](initiative.md)`.
Created by modules/discovery.md (0.3.21); appended by questioning-loop (every round and deep dive), discovery (0.3.4, 0.4.4), questioning-loop (0.3.17), review-triage (4.4, triage entries), the discovered-work protocol (00.21-00.29 rulings), discovery 0.1.4 (Origin entry, for specs seeded from a work item), the deeper-prompt skill (0.3.22, Deeper prompt entry), sign-off / retrospective (5.x, 5.7) and the large path (Conversion at 0.3.23; Initiative round at 6.8 and Emission at 6.9, both in an initiative's log; the Origin entry of an emitted spec at its 0.1.4).

Rules:
  - Append only. Never edit or delete an earlier entry. A reversal is a new entry that names what it supersedes; the old entry stays.
  - One dated section per round or event, newest last: `## YYYY-MM-DD <entry type>: <short title>`.
  - Decisions get stable ids D1, D2, ... in order across the whole file (ids are local to this feature). Superseding: `D7 (supersedes D3)`.
  - Index, not store: link to the artifact that holds the detail (spec.md section, ADR, .workflow/deferred/ file, data-model.md, report.md) rather than copying it.
  - Quote the stakeholder verbatim where a decision turned on their wording.
  - Terms agreed at a term gate go in .workflow/GLOSSARY.md; the log records only that the gate ran and links the term.
  - Delete the entry shapes you are not using, and this comment, in the finished file. Copy a shape each time you append.
-->

# Design log: <feature title>

Spec: [spec.md](spec.md)

<!-- Entry shapes. Copy one per event. -->

## YYYY-MM-DD Origin: <work-item filename>

<!-- 0.1.4. Written only for a spec seeded from a .workflow/specs/work-backlog/ item. First entry in the log. -->

- Work item: <NNN-slug-disc-###.md>
- Origin spec and step: <.workflow/specs/NNN-slug>, step <n>
- Problem: <the item's problem, one or two lines>
- Evidence: <`path:line`, failing test or agent return, carried from the item>

## YYYY-MM-DD Origin: initiative <NNN-slug>, slice S<n>

<!-- 0.1.4. Written only for a spec emitted from an initiative slice. First entry in the emitted spec's log. The binding decisions are the `settled` lines of the slice's questions, copied verbatim: they bind this spec and are not reopened in its questioning loop. -->

- Initiative: <.workflow/initiatives/NNN-slug>
- Slice: S<n> <slice title>
- Binding decisions:
  - IQ<n>: <the question's settled line, verbatim>

## YYYY-MM-DD Origin: converted from spec <NNN-slug>

<!-- Conversion. Written in the moved log when the questioning loop converts a draft spec into an initiative. The spec folder is deleted; its number stays consumed, so the next spec takes a higher one. -->

- Spec: <.workflow/specs/NNN-slug> (draft, step <n>)
- Initiative created: <.workflow/initiatives/NNN-slug> on branch `initiative/NNN-slug`
- Number consumed: <NNN>, kept as the initiative's `origin`
- Reason: <why the subject is several features, one or two lines; quote the stakeholder where they decided it>
- Re-pointed: <shelf items, work items and superseded_by links now naming the initiative, or "none">

## YYYY-MM-DD Deeper prompt

<!-- 0.3.22. Written by the deeper-prompt skill once the stakeholder explicitly agrees; the questioning loop takes it as input. A re-agreed prompt is a new entry; the loop reads the newest. -->

**Ask:** <the request, restated at the elevated level>

**Goals:**
- <observable outcome>

**Downstream:** <later work that builds on this, high level, or "none known">

**Tools and technologies:** <preferred or ruled-out tools, or "no preference">

**Gotchas:** <known constraints and traps, or "none known">

**Not asked for:** <kept out of scope, or "nothing">

**Original request:** "<verbatim>"

Revisions: <one line per restate round: what the stakeholder changed>, or "agreed as first restated".

## YYYY-MM-DD Questioning round <n>

<!-- 0.3.8-0.3.11. One block per question in the round. -->

**Q<n>. <question>**

- Why now: <the settled decision or fact that made this answerable>
- Options: <A: concrete option and its cost> · <B: ...>
- Recommended: <option>, because <reason; cite codebase-map.md where it came from>
- Answer: "<stakeholder's words, verbatim>" (or: deferred to deep dive)
- Decision: **D<n>** <the decision, one line>

Facts looked up instead of asked (0.3.10): <fact>: <answer> (source `<path:line>`), or "None."

## YYYY-MM-DD Initiative round <n>

<!-- 6.8, in an initiative's log. One round over the frontier of questions.md: the questions whose dependencies are all settled or done. One block per question asked or launched. -->

Frontier: <IQ<n>, IQ<n>, ...>

**IQ<n>. <question>** (decision)

- Options: <A: concrete option and its cost> · <B: ...>
- Recommended: <option>, because <reason with its source>
- Answer: "<stakeholder's words, verbatim>"
- Settled: <the line written to questions.md>. Decision: **D<n>** <one line>

**IQ<n>. <question>** (research)

- Launched: <task_type>, <one line: what the agent was asked>
- Result: <settled with <source>> or <left researching across the session end>

Slices planned or changed: <S<n> <title>: questions IQ<n>, depends on S<n>>, or "none".
Still researching: <IQ<n> (<task_type>)>, or "none".

## YYYY-MM-DD Emission: S<n> as <NNN-slug>

<!-- 6.9, in an initiative's log. A settled slice becomes one spec. The spec folder stays uncommitted on the initiative branch; this entry, the slice record and the reference-table row are committed together. -->

- Slice: S<n> <slice title>, questions <IQ<n>, IQ<n>>, all settled
- Spec: [<NNN-slug>](../../specs/NNN-slug/spec.md), seeded at 0.1.4 with `initiative: <NNN-slug>`
- Stakeholder confirmation: "<words, verbatim>"
- Remaining: <S<n>, ...> planned, or "none, the initiative moves to planned"

## YYYY-MM-DD Deep dive: <question>

<!-- 0.3.12-0.3.13. A question deferred from a round, taken one at a time after the round closes. -->

- From: Q<n> in round <n>
- Explored: <what was examined, with sources>
- Answer: "<verbatim>"
- Decision: **D<n>** <decision>

## YYYY-MM-DD Placement: <owning module>

<!-- 0.3.3-0.3.4, and 0.3.5-0.3.7 when an ADR or rule conflict was found. -->

- Owning module: <module from .workflow/rules.md Ownership>
- Alternatives considered: <module: why not>
- Conflict with an ADR or rule: <none | conformed | superseded ADR-NNNN | proposed rule change, see proposals.md>
- Decision: **D<n>** <placement>. ADR: [.workflow/decisions/adr/NNNN-slug.md](../../decisions/adr/NNNN-slug.md)

## YYYY-MM-DD Scope decision: <item>

<!-- 0.3.16-0.3.17. Something raised that sits outside the agreed scope. -->

- Item: <what was asked for>
- Ruling: <deferred | dropped>, because <durable reason>
- Handoff: [.workflow/deferred/<slug>.md](../../deferred/<slug>.md) (HITL | AFK), also listed in spec.md `deferred`

## YYYY-MM-DD Impact classification

<!-- 0.4.4. One row per part of the schema or interfaces the change touches. Detail lives in data-model.md. -->

| Part | Classification | Note |
| --- | --- | --- |
| <entity, field, interface or migration> | create / extend / refactor / unchanged | <one line; see data-model.md § <heading>> |

## YYYY-MM-DD Triage, review pass <n>

<!-- 4.4-4.5. Every finding keeps its verdict and evidence; none is dropped or merged silently. -->

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F<n> | review-standards / review-end-state / review-targets | <one line> | `<path:line>` | high / medium / low / false / maybe-false | <what verified or disproved it; for maybe-false, what would settle it> | patch / defer ([.workflow/deferred/<slug>.md](../../deferred/<slug>.md)) / decision needed (Q<n>) / discovered work (see "Discovered work" entry) / none (dismissed: <reason>) |

Failed lenses: none
Outcome: <rework k of 5 | loop back (4.5 decision needed) | loop back (4.6 third pass) | loop back (00.24 discovered work) | loop back (00.29 budget re-scope) | blocked (4.7) | deferred, to sign-off | clean, to sign-off>

<!-- `Failed lenses:` is "none" or the lens ids that errored or returned nothing usable. `Outcome:` is appended once the pass is decided (4.5-4.8); review-triage counts these lines for the pass number and the rework ceiling, so keep the wording. The two discovered-work loop backs (`00.24 discovered work`, `00.29 budget re-scope`) are also written as the last line of a Discovered work entry when the loop back did not come from a triage pass. -->

## YYYY-MM-DD Discovered work: <slug>

<!-- 00.21-00.29. Work found outside the agreed scope and the size-budget halt. Use one of the three records below; the first is the full entry, the others are short. -->

- Found at: step <n> by <agent or reviewer>. Kind: bug / requirement / refactor / scope-expansion / decision / budget-split
- Problem and evidence: <one line; `path:line` or failing test>
- Assessment and ruling: blocker / can be solved later; <to discovery (spec back to draft) | stays blocked, human resolves | backlog item | ignored | split | re-scoped | overrun approved>
- Backlog item: [work-backlog/<NNN-slug>-disc-<###>.md](../work-backlog/<NNN-slug>-disc-<###>.md)

Dismissed item (00.25 No), one line only:

- Dismissed discovered work: <slug>: <problem in a phrase> (`<path:line>`), not a blocker, user chose not to pursue.

Approved budget overrun (00.29 Approve):

- Approved budget overrun: <max_tasks | max_changed_files> reached <n> against <limit>. Reason: "<stakeholder's words>". Budget raised to <new value> for this spec only (spec.md `budget`).

## YYYY-MM-DD Retrospective notes

<!-- 5.7. Feature-specific notes only. Process lessons go to the decision log (.workflow/decisions/), pitfalls to pitfalls.md. -->

- <note about this feature, with a link to the retrospective: .workflow/decisions/retrospectives/NNN-slug.md>
