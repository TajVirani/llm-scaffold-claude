---
spec: .workflow/specs/004-scoped-test-runs
date: 2026-10-22
verdict: accepted-with-open-items
---

# Retrospective: Scoped test runs for the harness profiles

## Summary

- Spec: `.workflow/specs/004-scoped-test-runs/spec.md` (capabilities: CAP-001)
- Report: `.workflow/specs/004-scoped-test-runs/report.md`
- Tasks: 1 done, 0 split out; 3 items deferred (see `.workflow/deferred/browser-suite.md`, `per-task-scoped-runs.md`, `concurrency-check-timing.md`)
- Evidence available: `design-log.md` (Origin to Retrospective notes), `artifacts/T1/` (implementation, two mini-review rounds, toolchain), `artifacts/gate-3.9-w1/`, `artifacts/review/pass-1/` (three lenses), `report.md`, git range `f8ea802..9fe4e82` plus the uncommitted 5.3 writes
- Evidence missing: `verification-plan.md` not produced (light path); no session logs beyond this session
- Stakeholder concern going in: "not enough questioning or discovery at the start"

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-001 success: `--only-file F` / `--exclude-file G` select suites, exit 2 on an unknown selector | yes | review-end-state pass 1 `checked`; `tests/scripts/run-all-selection.sh` 31/31 (report.md E2) |
| CAP-001 success: parallel default with the same summary, order and exit codes as `-j 1` | yes | report.md E1, E2 (parallel/serial comparison check) |
| Constraint: bash 3.2, no new dependencies | yes | review-end-state `checked`; mini-review R2 comment on the bash 3.2 guard |
| Constraint: `tests/` reads no `WF_*` variable | yes | review-end-state `checked` (grep) |
| Constraint: output order and exit contract unchanged | yes | report.md E1 |
| Constraint: profiles change only at 5.3 | yes | proposals.md P1-P3 approved and applied at 5.3 |
| Success signal: per-task runs in seconds; full run about two minutes | partly | full run 142 s (E1); one own suite 17 s via `test_scoped` (E3); not yet observed on a live spec ([per-task-scoped-runs.md](../../deferred/per-task-scoped-runs.md)) |

Built but not asked for: selector files accept suite labels as well as paths; a selection emptied by exclusion exits 0 (`artifacts/T1/implementation.yaml`, `considered_not_built`).

## Behavior verification

The harness ran end to end three times on the merged branch: the 3.9 gate (2347/2347, 2 min 23 s), the 5.4 run with the 5.3 profile edits (2347/2347, 142 s), and the implementer's `-j 1` run (2347/2347, 425 s). The `test_scoped` line was exercised directly with selector files (report.md E3). It was not exercised through `run-toolchain.sh` on a spec with unfinished tasks; no browser behaviour applies.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| T1 commit subjects are not Conventional Commits | review-standards RS-1 (F1) | fix now: the 5.8 merge uses a Conventional subject (stakeholder: "Fix at merge") | - |
| Workflow-data commits carry other specs' files | RS-2, RE-1 (F2), `commit-workflow-data.sh:6-7` | accept: stakeholder "This is acceptable" | `.workflow/specs/work-backlog/004-scoped-test-runs-disc-004.md` (dismissed) |
| Browser gate skipped | 3.14 suite gap | defer | `.workflow/deferred/browser-suite.md` |
| Success signal not observed on a live spec | review-end-state `not_verifiable` | defer | `.workflow/deferred/per-task-scoped-runs.md` |
| Wall-clock thresholds in the selection suite | T1 mini-review `out_of_scope_noticed` | defer | `.workflow/deferred/concurrency-check-timing.md` |
| Interrupted run leaves suites running | T1 mini-review `out_of_scope_noticed` | defer (kept open in the backlog) | `.workflow/specs/work-backlog/004-scoped-test-runs-disc-002.md` |
| Light path taken with a 167-line runner change, and three behaviours (empty selection, labels, interrupt) left to the implementer | stakeholder concern; `git diff --stat f8ea802..f786aa3`; design-log rounds 1-2 (D4-D9); `artifacts/T1/implementation.yaml` | accept: stakeholder did not route it to a change | - |

## Previous-retrospective follow-through

No earlier retrospective.

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| Discovery was thin: caches and library-evaluation were skipped, the light path skips the module audit, and the loop asked six questions in two rounds; the runner's error and edge behaviour was decided by the implementer, and the change ran past the ~100-line light-path rule of thumb | skill change | not recorded: stakeholder rejected the action item |
| 00.26 wrote a work item that duplicated an open one (`004-scoped-test-runs-disc-001` vs `001-large-path-disc-004`); it should search open items by concept first | skill change | Action items |
| review-targets was launched on the light path with no `verification-plan.md`, so it had nothing to measure | skill change | Action items |
| The implementer used `T1:` commit subjects instead of Conventional Commits | tool rule (mechanical) | not recorded: stakeholder rejected the action item |
| The brief limited full-harness runs to the timing evidence, and per-task test cost stayed low (own suite about 16 s per run) | skill change | not recorded: covered by the stop-audit spec (spec B) |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| `yq --front-matter=extract -i` deleted two work-item bodies | main-session edits of `.workflow/specs/work-backlog/` (00.26, 5.9) | nothing yet | added |
| An unquoted heredoc ran markdown code spans as commands and hung the shell | main-session Bash writes at 3.14 | nothing yet | added |

## Feature notes

- Labels accepted in selector files; an emptied selection exits 0 (design-log.md, 2026-10-22 Retrospective notes section)
- Measured timings: 142 s parallel vs 425 s serial; 17 s for one own suite (design-log.md, 2026-10-22 Retrospective notes section)

## Model observations

None. One fix round on a comment and one rule finding on commit subjects are not enough evidence to judge a model.

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| discovered-work 00.26: before writing a work item, search open items in `.workflow/specs/work-backlog/` by concept and extend a match instead of writing a duplicate | scaffold maintainer | yes |
| review-triage step 2: skip `review-targets` when the spec has no `verification-plan.md` (light path) and record "no targets (light path)" | scaffold maintainer | yes |
| Use a Conventional Commits subject for the 5.8 merge of spec/004 (F1) | orchestrator at 5.8 | no |

## Acceptance verdict

`accepted-with-open-items`. CAP-001 and every constraint are met with evidence (report.md E1-E3) and the only task is `done`. The success signal is only partly observable until a spec with unfinished tasks runs under the new `test_scoped` line, and the browser gap and two backlog items stay tracked in `.workflow/deferred/` and the work backlog. The stakeholder approved the work at 5.5.

## Open questions

None.
