---
spec: .workflow/specs/005-cache-build-followups
date: 2026-10-28
verdict: accepted-with-open-items
---

# Retrospective: Cache build follow-ups from spec 003

## Summary

- Spec: `.workflow/specs/005-cache-build-followups/spec.md` (capabilities: CAP-004, CAP-005)
- Report: `.workflow/specs/005-cache-build-followups/report.md`
- Tasks: 6 done, 0 split out (`tasks.md`); 3 items deferred (`main-checkout-resolver`, `bash-case-fallthrough`, `bash-line-coverage`)
- Evidence available: `spec.md`, `verification-plan.md`, `report.md`, `tasks.md`, `design-log.md` (triage pass 1, sign-off), `proposals.md`, `artifacts/` (T1-T6, gates 3.9 w1/w2/rework1, review pass 1, JRN-008, sign-off-5.4), the deferred files, `.workflow/review-lessons.md`, retrospective 004. Git range `1f59f20..65ae1c5`: 37 commits, 140 files changed (+5551 / -485; most of it workflow data and new suites).
- Evidence missing: session logs were not read; process lessons come from `design-log.md`, the gate artifacts and the stakeholder.

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-005 bash extractor: `case` arm patterns are not calls | yes | report.md Journeys JRN-001, JRN-002; TGT-002 = 0 |
| CAP-004 Boundary violations reads `Not checked` with a fixed reason when depcruise did not run | yes | report.md JRN-003, JRN-004 |
| Goal: one shared test-pattern helper | yes | JRN-005; TGT-004 = 0 after rework 1 (`artifacts/sign-off-5.4/tgt-004-after-rework.txt`) |
| Goal: six scripts validate folder paths through one helper | yes | JRN-006; TGT-005 = 0 |
| Goal: cache-regeneration calls only regenerate-caches, and rules.md Ownership allows it | yes | TGT-006 = 0; P1 applied at 5.3 (`.workflow/rules.md` agents `may_depend_on`) |
| Constraints: bash 3.2, shellcheck clean, no new deps | yes | TGT-003 no output; harness 3072/0 |
| Constraint: a detected call is reported as unresolved, never filtered | yes | JRN-001 suite; D3 |
| Success signal: rebuilt cache lists only real calls and says `Not checked` | partly | JRN-008 (`artifacts/JRN-008/record.md`): the `case` entries are gone and Boundary violations reads `Not checked`, but one false entry remains (`tests/scripts/extractor-bash.sh:205`, multi-line quoted text; existed before this spec) |
| TGT-001 build ≤ 2 s (raised from 1.2 s at 5.5) | yes | 1.17 s, review-targets pass 1 |
| TGT-007 line coverage | no (not measurable) | report.md Targets; deferred `bash-line-coverage.md` |

Built but not asked for: None. (The open-task-pr refusal of absolute paths outside specs/initiatives and the budget-check message change follow from D5/D10, which the spec named.)

## Behavior verification

A full regenerate-caches run at `99801e5` built, checked (`check-staged-cache.sh` printed `ok` for all three caches) and published modules, flows and architecture, and all three read `fresh`. Architecture was rebuilt and republished at `65ae1c5` after the 5.3 rules change regenerated the boundary config. The Mermaid diagrams were checked by hand, because node cannot load mermaid and jsdom here.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1 budget-check header comment copied the default patterns (TGT-004 fail) | review-targets RT-1, `budget-check.sh:36` | fixed in rework 1 | - |
| F2 PROVENANCE row for `lib/test-paths.sh` still said placeholder | review-standards RS-1, review-end-state RE-1, `PROVENANCE.md:29` | fixed in rework 1 | - |
| TGT-007 coverage not measurable | review-targets | defer | `.workflow/deferred/bash-line-coverage.md` |
| One false unresolved edge from multi-line quoted text | JRN-008 oracle diff | defer (backlog) | `.workflow/specs/work-backlog/005-cache-build-followups-disc-003.md` |
| Worktree guard blocks a sub-agent's own result file | integration batch 3.2, every later agent | started as next feature | `.workflow/specs/006-result-file-guard` |
| TGT-001 threshold inside timing noise | T4 return (disc-002) | accept: threshold raised to 2 s at 5.5 ("Up to 2s and pass") | - |

## Previous-retrospective follow-through

Retrospective 004 (`.workflow/decisions/retrospectives/004-scoped-test-runs.md`):

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| discovered-work 00.26: search open backlog items by concept before writing one | yes | `.agents/skills/feature-workflow/modules/discovered-work.md:120` (Match by concept) |
| review-triage: skip review-targets on the light path | yes | `.agents/skills/feature-workflow/modules/review-triage.md:21`, commit `2e40640` |
| Conventional Commits subject for the 5.8 merge of spec/004 | no | main shows `55413d0 Merge pull request #1 from TajVirani/spec/004-scoped-test-runs` (GitHub's default merge subject) |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| The worktree write guard denied every coding and review agent's own result file; copying each file out by hand was an extra step on every launch | skill change | `.workflow/specs/006-result-file-guard` (next feature) |
| A 5.3 rules change regenerated the boundary config right after the JRN-008 cache run, so the architecture cache went stale before 5.8 and had to be rebuilt | skill change | not recorded: stakeholder rejected the action item at 5.7 |
| A review finding whose symptom is a PROVENANCE row still reading `placeholder` after the stub became real | review lesson | `.workflow/review-lessons.md RL-002` |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| A Phase 1 placeholder's PROVENANCE row was not flipped when the task made it real (F2, rework 1) | `PROVENANCE.md`, task briefs at 2.5 | nothing yet | already present (P2, written at 5.3) |
| Scope lists expanded in the main session's zsh did not word-split, twice: build-architecture got one long `--scope` argument, and the scope existence check read one path | main-session Bash calls at 1.1 and the JRN-008 run | nothing yet | not added: stakeholder rejected at 5.7 |

## Feature notes

None.

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| profile-mini-review | claude | T5's first `mini-review.yaml` did not parse (L20 C97) and the agent was resumed to rewrite it; the other seven reviews (T1-T6 and T1 rework) parsed first time | none | not recorded: stakeholder rejected at 5.7 |

## Action items

None. Every finding was fixed, deferred, filed to the backlog or started as spec 006; the stakeholder rejected the sign-off cache action item.

## Acceptance verdict

`accepted-with-open-items`. Every capability, goal and constraint is met, and all 6 tasks are `done` (harness 3072/0, review pass 1 patched in rework 1). Open items, all tracked: TGT-007 is not measurable (deferred `bash-line-coverage.md`), and one false unresolved edge comes from multi-line quoted text (backlog `005-cache-build-followups-disc-003.md`). The stakeholder approved the work at 5.5.

## Open questions

None.
