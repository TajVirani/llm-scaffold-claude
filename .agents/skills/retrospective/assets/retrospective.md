---
spec: .workflow/specs/NNN-slug
date: YYYY-MM-DD
verdict: accepted
---
<!--
File: Template for .workflow/decisions/retrospectives/NNN-slug.md, one per shipped feature. Written by the `retrospective` skill at 5.7 with the stakeholder present (D25); no `status` field lives here (D22).
Sources: structure adapted from bmad-code-org/BMAD-METHOD skills/bmad-retrospective/references/retro-document.md (MIT, Copyright (c) 2025 BMad Code, LLC; epic and ticket fields dropped, sections added). Plan: assetlist D12, D25, D34, D35; PLAN/decision-flow-reference.md 5.7.

How to fill it in:
  - Frontmatter: `spec` is the spec folder (.workflow/specs/NNN-slug). `verdict` is one of `accepted`, `accepted-with-open-items`, `rejected`, and matches the "Acceptance verdict" section. A gate that acts on the verdict reads this frontmatter, so keep both in sync. Add no other machine-read fields.
  - Replace each placeholder. If a section has nothing to record, write "None." so a reader knows it was considered.
  - Record observed facts, with a source reference (file:line, test output, report.md section). Leave time estimates out.
  - Every lesson names where it was recorded (Recorded in). Tier A writes (pitfalls.md, rules, profiles) go through the approved 5.7 step; write them with the stakeholder's agreement.
  - Delete this comment in the finished file.
-->

# Retrospective: <feature title>

## Summary

- Spec: `.workflow/specs/NNN-slug/spec.md` (capabilities: CAP-###)
- Report: `.workflow/specs/NNN-slug/report.md`
- Tasks: <count> done, <count> deferred (see `.workflow/deferred/`)
- Evidence available: <test output, metrics, review findings, design-log.md>
- Evidence missing: <what could not be gathered, or "None.">

## Result against the spec

Judge the combined result of all tasks against `spec.md`, not task by task.

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| <item from spec.md> | yes / partly / no | <report.md section, test, metric> |

Built but not asked for: <list, or "None.">

## Behavior verification

What was exercised end to end and what was observed. If runtime behavior was not exercised, say so here.

## Findings

Each finding keeps its source reference and a disposition: `fix now`, `defer` (link the `.workflow/deferred/` file), or `accept` (with the reason).

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| <what was found> | <review lens, task id, file:line> | fix now / defer / accept | <.workflow/deferred/slug.md or "-"> |

## Previous-retrospective follow-through

If an earlier retrospective exists, say whether its action items landed, with evidence. Otherwise write "No earlier retrospective."

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| <item> | yes / no / partly | <commit, file, check> |

## Process lessons

What the workflow did well or badly on this feature. Lessons about how we work, as opposed to lessons about this codebase.

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| <lesson> | tool rule (mechanical) / checklist line (judgement) / rule / profile / skill change | <proposals.md line, rules.md section, profile checklist, or "not recorded: reason"> |

Mechanical lessons become a tool rule; lessons that need judgement become a checklist line.

## Pitfalls

Observed failures only: something actually went wrong. Each entry also goes into `.workflow/decisions/pitfalls.md` with what happened, where, the spec it happened in, and the rule or check that now prevents it (if any).

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| <what happened> | <file or phase> | <rule, check, or "nothing yet"> | added / already present |

## Feature notes

Notes about this feature worth keeping that are not process lessons. They are appended to `.workflow/specs/NNN-slug/design-log.md` as a dated section; list them here with that pointer.

- <note> (design-log.md, <date> section)

## Model observations

Which model did well or badly on which task type. Proposals go to exactly one place per agent type and host (D35):

- the agent definition (`.agents/agents/<type>.md`) pins a model for that host in `models.<host>`: propose an entry in `<project>/agent-overrides.yaml`;
- otherwise: propose an entry in the `## Observations` section of `.workflow/model-map/<task-type>.md` (dated, one line). Leave its "Why this model" body and frontmatter unchanged.

Never edit `.agents/agents/*.md` in a target project: definitions are scaffold-owned and overwritten on reinstall.

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| <e.g. implementation> | claude / codex | <what happened, with evidence> | <alias change, or "none"> | .workflow/agent-overrides.yaml / .workflow/model-map/<type>.md |

## Action items

Routed items, each with an owner. Mark which are proposed changes awaiting human application.

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| <item> | <person or role> | yes / no |

## Acceptance verdict

`accepted`, `accepted-with-open-items`, or `rejected` (matches the frontmatter), and the evidence behind the call.

## Open questions

What a human answer would materially change, and anything the analysis could not resolve. "None." if empty.
