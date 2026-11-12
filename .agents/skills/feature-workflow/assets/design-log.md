<!--
File: Template for .workflow/specs/NNN-slug/design-log.md: the append-only decision log for one feature. No frontmatter. An initiative keeps the same log at .workflow/initiatives/NNN-slug/design-log.md: conversion moves the spec's log there and replaces its `Spec:` line with `Initiative: [initiative.md](initiative.md)`.
Created by modules/discovery.md (0.3.21); appended by questioning-loop (every round and deep dive), discovery (0.3.4), discovery-impact (0.4.4), questioning-loop (0.3.17), review-triage (4.4, triage entries), the discovered-work protocol (00.21-00.28 rulings), implementation-waves (3.15, a Size budget overrun entry), discovery 0.1.4 (Origin entry, for specs seeded from a work item), the deeper-prompt skill (0.3.22, Deeper prompt entry), sign-off (5.5 Sign-off entry, 5.6, 5.9) / retrospective (5.7), any step that assumes an answer (an Assumed entry, references/conventions.md "Asking the stakeholder"), verification-setup (1.2, a Breakdown quiz asked while Phase 1 builds), the handoff skill on resume (a `Main moved since handoff` entry; its shape is in that skill's Resume step 3) and the large path (Conversion at 0.3.23; Initiative round at 6.8 and Emission at 6.9, both in an initiative's log; the Origin entry of an emitted spec at its 0.1.4).

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

## YYYY-MM-DD Origin: <work item>

<!-- 0.1.4. Written only for a spec seeded from a .workflow/specs/work-backlog/ item. First entry in the log. -->

- Work item: <NNN-slug.md#B<n>, the backlog line>
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

<!-- 0.3.22. Written by the deeper-prompt skill with its agreement pending; the questioning loop asks for it in its first ask and logs the answer in that round. A changed prompt is a new entry; the loop reads the newest. -->

**Ask:** <the request, restated at the elevated level>

**Goals:**
- <observable outcome>

**Downstream:** <later work that builds on this, high level, or "none known">

**Tools and technologies:** <preferred or ruled-out tools, or "no preference">

**Gotchas:** <known constraints and traps, or "none known">

**Not asked for:** <kept out of scope, or "nothing">

**Original request:** "<verbatim>"

Revisions: <one line per restate round: what the stakeholder changed>, or "first restatement".

Agreement: <pending, asked in the first questioning ask | agreed in Questioning round <n>>

## YYYY-MM-DD Questioning round <n>

<!-- 0.3.8-0.3.11. One block per question in the round. -->

**Q<n>. <question>**

- Why now: <the settled decision or fact that made this answerable>
- Options: <A: concrete option and its cost> · <B: ...>
- Recommended: <option>, because <reason; cite codebase-map.md where it came from>
- Answer: "<stakeholder's words, verbatim>" (or: deferred to deep dive)
- Decision: **D<n>** <the decision, one line>

Facts looked up instead of asked (0.3.10): <fact>: <answer> (source `<path:line>`), or "None."

## YYYY-MM-DD Assumed: <the question, in a phrase>

<!-- Any step. A question that changes neither scope nor intent and gates nothing hard to reverse: its recommended answer was taken without asking (references/conventions.md, "Asking the stakeholder"). The next blocking ask offers it for veto and logs the `Offered for veto:` line in its own entry. -->

- Step: <node>
- Question: <the question as it would have been asked, with the options>
- Answer taken: <the recommended answer>
- Why safe to assume: <why the answer changes neither scope nor intent, and how it is undone if vetoed>

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

## YYYY-MM-DD Breakdown quiz

<!-- 2.1, asked while the Phase 1 builds run (verification-setup 1.2) or at 2.1 itself. Task breakdown takes the answers from here and asks again only about what Phase 1 changed. -->

- Asked at: <1.2, beside the harness build | 2.1>
- Slices: <approved as shown | changed: "<stakeholder's words, verbatim>">
- Edges, parallel_with and hitl modes: <approved | changed: "<verbatim>">
- Offered for veto: <Assumed entry titles, the 2.3 seams among them; vetoed: <titles> | none>
- Size: <within the project defaults: <t> tasks, <f> predicted files | over (<t> tasks, <f> predicted files against <max_tasks> / <max_changed_files>): split as proposed (B<n>, ...) | kept as one spec, budget raised to max_tasks <n>, max_changed_files <n>>
- Decision: **D<n>** <the breakdown as approved, one line>

## YYYY-MM-DD Triage, review pass <n>

<!-- 4.4-4.5. Every finding keeps its verdict and evidence; none is dropped or merged silently. -->

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F<n> | review-standards / review-end-state / review-targets / review-combined | <one line> | `<path:line>` | high / medium / low / false / unproven | <the reproduction or quoted line that proved it, or what disproved it; for unproven, what would settle it> | patch / decision needed (Q<n>) / discovered work (to ask, <convoluted / scope-expanding / out of scope>, or the blocker's ruling; see its Discovered work record) / proposal P<n> / none (dismissed: <reason>) |

Failed lenses: none
Gaps: <each not_verifiable requirement or unmeasured target, its lens and what would settle it | none>
Outcome: <rework k of 5 | loop back (4.5 decision needed) | loop back (4.6 third pass) | loop back (00.24 discovered work) | blocked (4.7) | open items, to sign-off | clean, to sign-off>

<!-- `Failed lenses:` is "none" or the lens ids that errored or returned nothing usable. `Gaps:` is written at 4.8 and read by the 5.4 report. `Outcome:` is appended once the pass is decided (4.5-4.8); review-triage counts these lines for the pass number and the rework ceiling, so keep the wording. The discovered-work loop back (`00.24 discovered work`) is also written as the last line of a Discovered work entry when the loop back did not come from a triage pass. -->

## YYYY-MM-DD Discovered work: <slug>

<!-- 00.21-00.28. Work found outside the agreed scope. Use one of the records below; the first is the full entry, the others are short. An item waiting for the stakeholder's batched question takes the full entry with the ruling "to ask (<class>)"; its answer comes later as a `Ruling:` line in the entry of the ask that carried it (the Sign-off entry at 5.5). -->

- Found at: step <n> by <agent or reviewer>. Kind: bug / requirement / refactor / scope-expansion / decision
- Problem and evidence: <one line; the reproduction (command and output, or failing test) or the quoted rule line with `path:line`>
- Assessment and ruling: blocker; <to discovery (spec back to draft) | stays blocked, human resolves | kept for later | dropped> / to ask (<convoluted | scope-expanding | out of scope>), recommended <fold in | keep for later | drop> because <reason>
- Backlog line: [work-backlog/<NNN-slug>.md](../work-backlog/<NNN-slug>.md) B<n> (only once kept)

Ruling on a waiting item (00.25, written in the entry of the ask that carried it), one line per item:

- Ruling: <slug>: fold in | kept for later (B<n>) | dropped. Asked at <node>.

Unproven report (no reproduction and no quotable line), one line only:

- Unproven report: <slug>: <claim in a phrase>, from <agent> at <node>; nothing filed. Would settle it: <one line>.

Duplicate discovered work (00.26, matched a shelf file or an open backlog line by concept), one line only:

- Duplicate discovered work: <slug> matches <file or list line>; <Later requests line appended | existing line stands | not appended, item of <its origin spec>>.

## YYYY-MM-DD Size budget overrun

<!-- 3.15, once per spec: the first wave whose budget-check.sh exits 2. Not a stop and not asked; a later wave adds nothing. Sign-off reports the final figures (5.4). -->

- Wave <n>: <tasks | changed_files> <n> against <limit> (budget-check.sh, basis impl_base_revision). Build continues.

## YYYY-MM-DD Sign-off: stakeholder approval (5.5)

<!-- 5.5. One entry for the one sign-off ask: the assumptions offered for veto, the work and the PR description, the proposals, the one list question (a ruling per waiting discovered-work item and per open backlog line) and the retrospective's drafted lessons, all answered in one call. 5.3, 5.9 and the retrospective (5.7) apply these lines without asking again. A change request (5.6) appends its own entry after this one. -->

- Offered for veto: <Assumed entry titles; vetoed: <titles> | none> (or "no assumptions")
- Approval: yes / change requested: "<stakeholder's words, verbatim>"
- PR description: approved as shown / changed: "<stakeholder's words, verbatim>"; confirmed in the follow-up | not asked (change requested)
- Proposals: all approved | exceptions: <P<n>: modify <text> / P<n>: reject <reason>, verbatim> | no proposals
- Ruling: <slug or B<n>>: fold in / keep for later / drop / start it as the next feature (one line per item on the list, or "Backlog: no items")
- Retrospective lessons: recorded as drafted | none | exceptions: <L<n>: change <text> / L<n>: reject <reason>, verbatim> | no candidates
- Concerns for the retrospective: <the stakeholder's words, verbatim | none>
- Follow-up: <the reworded rows and body confirmed, verbatim answer | none>

## YYYY-MM-DD Retrospective notes

<!-- 5.7. Feature-specific notes only. Process lessons go to the decision log (.workflow/decisions/), pitfalls to pitfalls.md. -->

- <note about this feature, with a link to the retrospective: .workflow/decisions/retrospectives/NNN-slug.md>
