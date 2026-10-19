<!--
File: Template for specs/NNN-slug/design-log.md: the append-only decision log for one feature. No frontmatter.
Created by modules/discovery.md (0.3.21); appended by questioning-loop (every round and deep dive), discovery (0.3.4, 0.4.4), questioning-loop (0.3.17), review-triage (4.4, triage entries), the discovered-work protocol (00.21-00.29 rulings), discovery 0.1.4 (Origin entry, for specs seeded from a work item), the deeper-prompt skill (0.3.22, Deeper prompt entry) and sign-off / retrospective (5.x, 5.7).
Sources: round anatomy (numbered questions, options, recommendation, the user's words verbatim, a decision ledger with stable ids where superseded decisions stay marked) adapted from .agents/skills/feature-workflow/references/REFERENCE-DOC.md (first-party; written locally alongside the former vendored copy of mattpocock/skills grill-with-docs, not an upstream file). Index-not-store ("one line per decision, link to the detail") adapted from mattpocock/skills/skills/engineering/wayfinder/SKILL.md@49dd158 "Decisions so far" (MIT). Triage entry fields (id, source lens, location, verdict high/medium/low/false/maybe-false, evidence, route) adapted from bmad-code-org/BMAD-METHOD skills/bmad-code-review/step-03-triage.md (MIT). Ledger that survives context compaction: obra/superpowers skills/subagent-driven-development/SKILL.md (MIT; idea only). The catalogue of entry shapes is first-party (PLAN/decision-flow-reference.md "Per-feature files", 0.3.4, 0.3.17, 0.3.21, 0.4.4, 4.4, 5.7).

Rules:
  - Append only. Never edit or delete an earlier entry. A reversal is a new entry that names what it supersedes; the old entry stays.
  - One dated section per round or event, newest last: `## YYYY-MM-DD <entry type>: <short title>`.
  - Decisions get stable ids D1, D2, ... in order across the whole file (ids are local to this feature). Superseding: `D7 (supersedes D3)`.
  - Index, not store: link to the artifact that holds the detail (spec.md section, ADR, deferred/ file, data-model.md, report.md) rather than copying it.
  - Quote the stakeholder verbatim where a decision turned on their wording.
  - Terms agreed at a term gate go in GLOSSARY.md; the log records only that the gate ran and links the term.
  - Delete the entry shapes you are not using, and this comment, in the finished file. Copy a shape each time you append.
-->

# Design log: <feature title>

Spec: [spec.md](spec.md)

<!-- Entry shapes. Copy one per event. -->

## YYYY-MM-DD Origin: <work-item filename>

<!-- 0.1.4. Written only for a spec seeded from a specs/work-backlog/ item (D69). First entry in the log. -->

- Work item: <NNN-slug-disc-###.md>
- Origin spec and step: <specs/NNN-slug>, step <n>
- Problem: <the item's problem, one or two lines>
- Evidence: <`path:line`, failing test or agent return, carried from the item>

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

## YYYY-MM-DD Deep dive: <question>

<!-- 0.3.12-0.3.13. A question deferred from a round, taken one at a time after the round closes. -->

- From: Q<n> in round <n>
- Explored: <what was examined, with sources>
- Answer: "<verbatim>"
- Decision: **D<n>** <decision>

## YYYY-MM-DD Placement: <owning module>

<!-- 0.3.3-0.3.4, and 0.3.5-0.3.7 when an ADR or rule conflict was found. -->

- Owning module: <module from docs/rules.md Ownership>
- Alternatives considered: <module: why not>
- Conflict with an ADR or rule: <none | conformed | superseded ADR-NNNN | proposed rule change, see proposals.md>
- Decision: **D<n>** <placement>. ADR: [docs/decisions/adr/NNNN-slug.md](../../docs/decisions/adr/NNNN-slug.md)

## YYYY-MM-DD Scope decision: <item>

<!-- 0.3.16-0.3.17. Something raised that sits outside the agreed scope. -->

- Item: <what was asked for>
- Ruling: <deferred | dropped>, because <durable reason>
- Handoff: [deferred/<slug>.md](../../deferred/<slug>.md) (HITL | AFK), also listed in spec.md `deferred`

## YYYY-MM-DD Impact classification

<!-- 0.4.4. One row per part of the schema or interfaces the change touches. Detail lives in data-model.md. -->

| Part | Classification | Note |
| --- | --- | --- |
| <entity, field, interface or migration> | create / extend / refactor / unchanged | <one line; see data-model.md § <heading>> |

## YYYY-MM-DD Triage, review pass <n>

<!-- 4.4-4.5. Every finding keeps its verdict and evidence; none is dropped or merged silently. -->

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F<n> | review-standards / review-end-state / review-targets | <one line> | `<path:line>` | high / medium / low / false / maybe-false | <what verified or disproved it; for maybe-false, what would settle it> | patch / defer ([deferred/<slug>.md](../../deferred/<slug>.md)) / decision needed (Q<n>) / discovered work (see "Discovered work" entry) / none (dismissed: <reason>) |

Failed lenses: none
Outcome: <rework k of 5 | loop back (4.5 decision needed) | loop back (4.6 third pass) | loop back (00.24 discovered work) | loop back (00.29 budget re-scope) | blocked (4.7) | deferred, to sign-off | clean, to sign-off>

<!-- `Failed lenses:` is "none" or the lens ids that errored or returned nothing usable. `Outcome:` is appended once the pass is decided (4.5-4.8); review-triage counts these lines for the pass number and the rework ceiling, so keep the wording. The two discovered-work loop backs (`00.24 discovered work`, `00.29 budget re-scope`) are also written as the last line of a Discovered work entry when the loop back did not come from a triage pass. -->

## YYYY-MM-DD Discovered work: <slug>

<!-- 00.21-00.29. Work found outside the agreed scope (D56) and the size-budget halt (D58). Use one of the three records below; the first is the full entry, the others are short. -->

- Found at: step <n> by <agent or reviewer>. Kind: bug / requirement / refactor / scope-expansion / decision / budget-split
- Problem and evidence: <one line; `path:line` or failing test>
- Assessment and ruling: blocker / can be solved later; <to discovery (spec back to draft) | stays blocked, human resolves | backlog item | ignored | split | re-scoped | overrun approved>
- Backlog item: [work-backlog/<NNN-slug>-disc-<###>.md](../work-backlog/<NNN-slug>-disc-<###>.md)

Dismissed item (00.25 No, D56), one line only:

- Dismissed discovered work: <slug>: <problem in a phrase> (`<path:line>`), not a blocker, user chose not to pursue.

Approved budget overrun (00.29 Approve, D58):

- Approved budget overrun: <max_tasks | max_changed_files> reached <n> against <limit>. Reason: "<stakeholder's words>". Budget raised to <new value> for this spec only (spec.md `budget`).

## YYYY-MM-DD Retrospective notes

<!-- 5.7. Feature-specific notes only. Process lessons go to the decision log (docs/decisions/), pitfalls to pitfalls.md. -->

- <note about this feature, with a link to the retrospective: docs/decisions/retrospectives/NNN-slug.md>
