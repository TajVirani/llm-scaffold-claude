---
spec: .workflow/specs/00011-interrupted-run-cleanup
date: 2026-10-30
verdict: accepted-with-open-items
---

# Retrospective: Interrupted harness runs clean up their background suites

## Summary

- Spec: `.workflow/specs/00011-interrupted-run-cleanup/spec.md` (capabilities: CAP-001)
- Report: `.workflow/specs/00011-interrupted-run-cleanup/report.md`
- Tasks: 1 done, 0 deferred (the browser-suite gap is a Later requests line on `.workflow/deferred/browser-suite.md`)
- Evidence available: spec.md, report.md, tasks.md, design-log.md (questioning round 1, triage pass 1, sign-off), proposals.md, `artifacts/T1/` (three implementation and mini-review rounds plus the rework), `artifacts/gate-3.9-w1/`, `artifacts/gate-3.9-w2/`, `artifacts/sign-off-5.4/`, `artifacts/review/pass-1/`, git `3fee587..cc1e584`
- Evidence missing: verification-plan.md not produced (light path); no session logs beyond this session's design-log entries.

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-001 success: INT, TERM, HUP give 130, 143, 129; suite and child `sleep` gone; results dir gone | yes | report.md § Capabilities [E2]; `scripts/run-all-selection` passed=66 skipped=0 in `artifacts/sign-off-5.4/toolchain.txt` |
| CAP-001 success: a stub suite reading stdin gets end of file under an open pipe | yes | report.md [E2]; added in rework 1 (triage F1) |
| Constraint: bash 3.2 built-ins only, no new binary | yes | `tests/run-all.sh` diff `3fee587..cc1e584` uses `set -m`, `kill`, `trap`, `sleep` |
| Constraint: uninterrupted output, order and exit codes unchanged | yes | existing output-identity and concurrency checks pass; full harness 3593/3593 |
| Constraint: process group per suite, TERM, 2 s, KILL, ignore further signals | yes | `tests/run-all.sh` `start_suite`, `stop_and_exit` |
| Constraint: tests use the fixture copy and stub suites only | yes | `tests/scripts/run-all-selection.sh` interrupt cases use `$RUNNER` |
| Success signal: Ctrl-C at a terminal returns 130 with no suite left | partly | exercised with `kill -INT` against a fixture runner, not at a real terminal (report.md § Known gaps) |

Built but not asked for: the runner's `--help` now prints through the `# Requires:` header so the new exit-code line shows (T1 summary); the INT case skips with a reason when the suite itself starts with SIGINT ignored.

## Behavior verification

The selection suite starts a fixture copy of the runner on a stub suite whose child `sleep` records its pid, sends INT, TERM and HUP with `kill`, and checks the exit code, the suite and its `sleep`, and the results directory; a fourth case pipes input to the runner and checks a stub suite reads end of file. Ctrl-C from an interactive terminal and a real terminal hangup were not exercised.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1 medium: `set -m` dropped the suites' implicit `/dev/null` stdin | review-end-state `not_checked`, `tests/run-all.sh:195` | accept (patched in rework 1) | - |
| F2 low: guard comment overstated which expansions are guarded | T1 re-check mini-review, `tests/run-all.sh:209-210` | accept (patched in rework 1) | - |
| Browser gate skipped: no browser suite in this repo | 3.14 | defer | .workflow/deferred/browser-suite.md |
| Real-terminal Ctrl-C and hangup not exercised | review-end-state `not_verifiable` | accept: kill-driven cases cover the trap and the group kill; a terminal adds only signal delivery | - |
| A suite tool that daemonises or calls `setsid` escapes the group kill | spec.md § Assumptions | accept: no current suite was found to do so | - |

## Previous-retrospective follow-through

From `.workflow/decisions/retrospectives/008-pr-description-template.md`:

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 1. Pin each parsed input's accepted forms with a fixture before 0.6 | no evidence found | no matching text in `.agents/skills/feature-workflow/modules/*.md` |
| 2. Launch the Phase 1 build in a wave-start-style worktree, not `isolation: "worktree"` | yes | `.agents/skills/feature-workflow/modules/verification-setup.md:48` (spec 006, CAP-007) |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| A mini-review `out_of_scope_noticed` entry about lines the task itself changed (here, a comment T1 wrote) is an in-scope wording fix, not discovered work; the orchestrator's 3.7 text routes every entry to discovered work, which would file a backlog item for a one-line comment | skill change | Action item 1 |
| The medium defect F1 surfaced only as a lens's `not_checked` suspicion; verifying `not_checked` items at triage, as review-triage step 4 asks, found a real regression | process note | not recorded elsewhere: review-triage already says `not_checked` items are gaps to read |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| Job control (`set -m`) on a background launch dropped the job's implicit `/dev/null` stdin | `tests/run-all.sh` `start_suite` | the stdin end-of-file check in `tests/scripts/run-all-selection.sh` | already present (added at 5.3, P2) |

## Feature notes

- The INT case skips with a reason when the suite itself starts with SIGINT ignored; under the new runner suites start with job control, so it always runs (design-log.md, 2026-10-30 Retrospective notes section)
- The guard comment in `running_suite_groups` took two extra review rounds to state a true reason (design-log.md, 2026-10-30 Retrospective notes section)

## Model observations

None.

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| 1. implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about lines the task itself changed is handled as a fix round for that task, not handed to discovered work | scaffold maintainer, via a spec on feature-workflow | yes |

## Acceptance verdict

`accepted-with-open-items`: every spec item is met (the success signal partly: signals were sent with `kill`, not from a real terminal), T1 is `done`, and the browser-suite gap is deferred to `.workflow/deferred/browser-suite.md`. The stakeholder approved the work at 5.5 and this verdict at 5.7.

## Open questions

None.
