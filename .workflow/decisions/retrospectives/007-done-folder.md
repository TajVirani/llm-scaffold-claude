---
spec: .workflow/specs/done/007-done-folder
date: 2026-10-31
verdict: accepted-with-open-items
---

# Retrospective: Done folder for finished specs

## Summary

- Spec: `.workflow/specs/done/007-done-folder/spec.md` (capabilities: CAP-011)
- Report: `.workflow/specs/done/007-done-folder/report.md`
- Tasks: 5 done, 0 deferred (2 shelf items written at discovery: `sign-off-scoped-commit.md` Later requests line, `launch-against-done-spec.md`)
- Evidence available: `artifacts/sign-off-5.4/toolchain.txt` (3951 passed, 0 failed), gate records `artifacts/gate-3.9-*`, review pass files `artifacts/review/pass-1..3/`, task result and mini-review files under `artifacts/T1`-`T5`, `design-log.md`
- Evidence missing: JRN-005 (the sweep of this repo) runs at 5.8, after this retrospective.

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-011 success line (move, rewrite, no `.step`, outbound links, `pr-body.md` path, numbering, deny, refusal at 5.7) | yes (fixtures) | report.md Capabilities; `tests/scripts/move-to-done.sh`, `check-write-paths`, `sign-off-pr` in `artifacts/sign-off-5.4/toolchain.txt` |
| Constraints (check twice, commit on spec branch, D14 order, D15 stop, any-digit numbers, rewrite scope, deny, review-lessons rule, plain `mv`, no literal path) | yes | review-end-state pass 3 (all constraints checked, 0 findings); TGT-004 = 0 |
| Success signal: this repo's done specs under `done/` | partly: runs at 5.8 | report.md Known gaps |
| JRN-001-004, 006, 007 | yes | report.md Journeys |
| JRN-005 | not yet: 5.8 | report.md Journeys |
| TGT-001-007 | yes (TGT-003 from the 5.4 harness run) | report.md Targets vs measured |
| TGT-008 line coverage | not measured (no tool) | report.md Targets vs measured |

Built but not asked for: the rollback on a failed move or sweep (asked for at T5 mini-review, in scope as the task's own defect), and the `--sweep` skip of the spec being signed off (review F1).

## Behavior verification

Every journey except JRN-005 ran as a harness suite against a fixture git repo; the sweep also ran three times on scratch clones of this repo at the baseline for TGT-007 (12.86 s best of 3, `artifacts/review/pass-3/review-targets.yaml`). The real sweep and move of this repo run at 5.8.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| JRN-005 not yet exercised | report.md Known gaps | accept: runs at 5.8, followed by `tests/run-all.sh` | - |
| No suite runs the large-path 6.13 rewrite loop | review-end-state not_verifiable; backlog `007-done-folder-disc-001.md` | accept: stakeholder ruled it a non-issue at 5.5 (item dismissed) | - |
| TGT-007 is load-sensitive (33.86 s once at load average 23) | `artifacts/T5/implementation-r4.yaml` | accept: met at normal load in three measurements | - |
| Integration commit subjects without a type prefix | triage F2, F3, F8; backlog `007-done-folder-disc-002.md` | accept: stakeholder ruled it a non-issue at 5.5 (item dismissed) | - |

## Previous-retrospective follow-through

From `.workflow/decisions/retrospectives/00013-validator-diagnostic.md`:

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 1. (carried from 00011) implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about the task's own lines is a fix round | no | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md` has no such line (last change `5e345a0`); in this spec it was applied by hand (T4 round 1, T5 round 1) |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| When a mini-review's out-of-scope note was a defect in the task's own new code (T4 round 1: the 6.13 `sed` missed adjacent paths; T5 round 1: partial state after a failed move), handling it as part of the same fix round fixed it in one launch, with no backlog item for the stakeholder to rule on. The stakeholder's sign-off concern ("Useless findings, or things that should just be fixed as part of the work") asks for exactly this. | skill change | not recorded: the open action item carried from 00011 and 00013 already covers it (below) |

## Pitfalls

None. The stakeholder rejected the two failure entries proposed at 5.3 as one-offs (P3, P4).

## Feature notes

- After `main` moved to `469ade4` during review, the 5.8 sweep covers 001-006, 008 and 00010-00013; 009 stays at the top level (design-log.md, 2026-10-31 Main merged into the spec branch).

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| profile-mini-review | claude | Caught real faults (unchecked reads and writes under suspended `set -e` in T5 three times, the sweep's partial state, a missing reason comment), but wrote an unreadable result file twice (T3 round 1 missing `location` fields; T5 round 5 unquoted `: ` in a note), each costing a resume, and twice reported a false `toolchain.json` tree mismatch (T1, T5 re-checks). | none | .workflow/model-map/profile-mini-review.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| 1. (carried from 00011, 00013) implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about the task's own lines is a fix round, not discovered work | scaffold maintainer, via a spec on feature-workflow | yes |

## Acceptance verdict

`accepted-with-open-items`. Every capability, constraint, target and journey is met on fixtures, and all 5 tasks are `done`. The one open item is JRN-005, the sweep of this repo, which runs at 5.8 under the full test suite. The stakeholder approved the work at 5.5 ("finish sign-off").

## Open questions

None.
