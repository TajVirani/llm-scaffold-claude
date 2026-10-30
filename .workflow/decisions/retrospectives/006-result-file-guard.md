---
spec: .workflow/specs/006-result-file-guard
date: 2026-10-30
verdict: accepted-with-open-items
---

# Retrospective: Sub-agents can write their own result file

## Summary

- Spec: `.workflow/specs/006-result-file-guard/spec.md` (capabilities: CAP-006, CAP-007)
- Report: `.workflow/specs/006-result-file-guard/report.md`
- Tasks: 7 done, 0 deferred (T1-T7 in `tasks.md`)
- Evidence available: `report.md`; `verification-plan.md`; `design-log.md` (triage passes 1-2, rulings D16-D32, discovered work); `proposals.md` (P1-P5 approved); `artifacts/` (per-task toolchain and mini-review rounds, `gate-3.9-*`, `review/pass-1`, `review/pass-2`, `sign-off-5.4`). Git `e049f4d..HEAD`: 56 commits, 32 non-workflow files, +2113 / −127.
- Evidence missing: session logs, so process lessons come from `design-log.md`, the result files and the stakeholder. The first session's handoff is `.workflow/.handoff/006-result-file-guard.md`.

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-006 Sub-agents file their own result file | partly | Harness proves every part (JRN-001 to 009, 011 to 014; `report.md` Journeys). JRN-010, a live no-isolation Phase 1 or integration launch, has not run (`report.md` Known gaps). |
| CAP-007 Read-only commands pass the worktree guard | yes, narrowed | JRN-009 in `tests/hooks/worktree-guard.sh`. `sed -n` counts as a read only for print-only scripts, by stakeholder decision D31 (design-log "T4 mini-review round 2"). |
| Constraint: bash 3.2 and git only, no new dependency | yes | T4 checked under `/bin/bash` 3.2.57 (`artifacts/T4/implementation-r1.yaml`); no new dependency in the diff |
| Constraint: no result-file agent launched with isolation; fallback removed | yes | T5 text; `tests/lint/agent-worktree-docs.sh` 27/27 (JRN-008) |
| Constraint: names byte-identical to Codex `task_name` via `wf_` lib functions | yes | JRN-001; target codex-enc-copies = 0 (`review/pass-2/review-targets.yaml`) |
| Constraint: light path keeps detached worktree and `--ff-only` | yes | T5 text; gate before the light-path fast-forward (JRN-008) |
| Constraint: other writes stay confined | yes | JRN-002 to 004; T1 round 4 closed a fail-open (design-log "T1 mini-review round 2") |
| Constraints: installer matcher rule, no wait without a terminal, `--dry-run`, `--force`, mixed, match-all and plain rules, two-template groups (D19-D32) | yes | JRN-011 to 013 in `tests/scripts/install-upgrade.sh`, 122/122 at T6 round 5 |
| Constraint: rule documented in four places | yes | JRN-014 `tests/lint/install-matcher-docs.sh` 20/20 |
| Success signal | partly | Phase 3 tasks and mini-reviews filed their result files with no copy, a stray `artifacts/` change is refused (JRN-007), upgraded targets audit integration (JRN-006), and `cat file \| head` passes (JRN-009). A live Phase 1 or integration build without isolation is still pending (JRN-010). |
| Targets (8 rows) | 7 yes, 1 not measured | `report.md` Targets vs measured; line coverage not measurable (D17) |

Built but not asked for: four things.
- `yq -s` and `--split-exp` are denied, because they write files (T4).
- `--matchers=merge` and `--matchers=replace` print one line naming the mode (T6 round-4 audit).
- A malformed (non-string) matcher is kept with a warning (T6 round 4).
- An empty `--matchers` value exits 2 (T6 round 3).

All four fall within the spec's intent and are recorded in `design-log.md`.

## Behavior verification

The scaffold has no running application. Every journey except JRN-010 runs the real hooks, scripts and `install.sh` against fixture repos in the harness. The full run passes: 3475 passed, 0 failed, 60 suites (`artifacts/sign-off-5.4/toolchain.txt`).

In this spec's own build:
- The artifacts gate ran for real before three merges.
- Every Phase 3 implementation and mini-review result file landed in the main checkout with no copy step.
- Phase 1 and integration agents were not exercised without isolation. They ran under isolation and needed the hand copy this spec removes.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| JRN-010 not exercised for Phase 1 and integration | review-end-state passes 1-2 `not_verifiable`; `report.md` Known gaps | accept: no Phase 1 or integration work remained once T5 landed; the next spec's first such launch checks it | - |
| Line coverage of changed shell code not measured | `verification-plan.md` Targets; D17 | accept: no bash coverage tool, and no new dependency allowed | - |
| F1 (high) briefs named the launch checkout | `design-log.md` Triage, review pass 1 | fixed (rework 1) | - |
| F2 (low) 3.2 said no stop audit for integration | `design-log.md` Triage, review pass 1 | fixed (rework 1) | - |
| F3, F4, F5 and discovered items disc-003, 005, 007 | `design-log.md` Discovered work entries | started as spec 00010 | `.workflow/specs/00010-worktree-guard-followups` |
| disc-002 spec folder digit rule | `design-log.md` Sign-off (5.5) | fix now (quick fix after 5.8, outside the flow) | - |

## Previous-retrospective follow-through

The previous retrospective (`005-cache-build-followups.md`) recorded no action items.

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| Fix-round churn on rule-heavy tasks: T6 needed all 5 fix rounds and T1 and T4 three or four, each full review finding a new edge (D19-D32 matcher rules, command parsing). T6's round-4 branch-by-branch audit against its header closed three gaps at once (design-log T6 rounds 1-5). | skill change | Action item 1 |
| A task's own acceptance-criteria misses reached the orchestrator as mini-review `out_of_scope_noticed` (T1 missing transcript, T4 attached sed `w`, T6 two template groups), because the review checks only the profile checklist. | skill change | Action item 2 |
| A shellcheck `disable=` without its reason failed review twice (T6 rounds 2 and 4). | tool rule (mechanical) | Action item 3 |
| The 2.1 breakdown left `install.sh` without an owning task, so T1 met an acceptance line it could not satisfy and the spec looped back (design-log "Discovered work: upgrade-matcher-merge"). | skill change | Action item 4 |
| Regex denylists for a tool's write forms leak; allowlisting the read forms closed the class (D31). | review lesson | `.workflow/review-lessons.md` RL-003 |
| A doc-extraction test filled every path placeholder with the expected path and hid F1. | review lesson | `.workflow/review-lessons.md` RL-004 |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| The guard suite filled the launch-checkout placeholder with the agent worktree, hiding F1 | `tests/hooks/worktree-guard.sh`; `.agents/agents/*.md` | the guard suite's `cd <agent worktree> &&` check (T3 rework) | already present (added at 5.3, P5) |

## Feature notes

- JRN-010 is pending the next spec's first Phase 1 or integration launch (design-log.md, 2026-10-30 Retrospective notes).
- The artifacts gate's first real runs all passed (exit 0), and no wave merge changed `artifacts/` (design-log.md, 2026-10-30 Retrospective notes).
- New spec folders use 5-digit numbers, starting at `00010` (design-log.md, 2026-10-30 Retrospective notes).

## Model observations

None. There is no evidence specific to the model behind a task type: the fix-round churn traces to the review scope and the task's rule density, not to a model.

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| 1. `.agents/agents/implementation.md`: for a task with many rule branches, audit every branch against the spec and the script header before stopping, and list what was checked in the summary. | scaffold maintainer | yes |
| 2. `.agents/agents/profile-mini-review.md`: report a miss against the task file's acceptance criteria as its own category, separate from `out_of_scope_noticed`. | scaffold maintainer | yes |
| 3. Tool rule: a lint check that every `# shellcheck disable=` line carries its reason. Pair it with dropping that clause from checklist item 8 of the shell-scripts profile. | scaffold maintainer | yes |
| 4. `modules/task-breakdown.md` 2.1: check that every End state objective maps to a task whose module owns the files it needs. | scaffold maintainer | yes |
| 5. disc-002 quick fix: any digit count is valid in the lib, `resolve-launch.sh` and the 0.1.1 scan, and new specs get 5-digit numbers. | orchestrator, after 5.8 | no |

## Acceptance verdict

`accepted-with-open-items`. Every task is `done`. Both capabilities, every constraint, and 7 of 8 targets are met with harness evidence, and the stakeholder approved at 5.5. Two items stay open:
- JRN-010, the live no-isolation Phase 1 and integration launch: accepted, and checked by the next spec's first such launch.
- Line coverage: not measurable (D17).

## Open questions

None.
