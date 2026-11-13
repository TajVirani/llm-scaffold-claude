---
spec: .workflow/specs/done/00015-worktree-provisioning
date: 2026-11-12
verdict: accepted-with-open-items
---

# Retrospective: Worktree setup (spec 00015-worktree-provisioning)

## Summary

- Spec: `.workflow/specs/done/00015-worktree-provisioning/spec.md` (capabilities: CAP-015)
- Report: `.workflow/specs/done/00015-worktree-provisioning/report.md`
- Tasks: 9 done, 0 split out (`tasks.md` frontmatter)
- Evidence available:
  - `spec.md`, `verification-plan.md`, `report.md`, `tasks.md`, `design-log.md` (one triage entry, review pass 1, and the Sign-off entry) and `proposals.md` (P1, approved);
  - `artifacts/`: the Phase 1 known-bad record, one implementation and one mini-review result file per task (T3 has two of each), one integration result, five wave-gate runs (`gate-3.9-w1` to `w4`, `gate-3.9-r1`), `sign-off-5.4`, and the three lens files of review pass 1 with their raw target output;
  - `.workflow/deferred/rules-setting-usage-exit-code.md`, the one shelf file whose origin is this spec, and `.workflow/specs/work-backlog/00015-worktree-provisioning.md` (B1, kept at 5.5);
  - `.workflow/review-lessons.md` (RL-001 to RL-009) and the previous retrospective, `.workflow/decisions/retrospectives/00014-tracker-issue-spec-ids.md`;
  - git `aea4e6e..886a32c`: 42 commits, 174 files changed, 5,447 insertions, 140 deletions, the spec folder's artifacts included. The review lenses counted 51 files outside the spec folder at pass 1 (`artifacts/review/pass-1/review-standards.yaml`, `checked`).
- Evidence missing:
  - Session logs were not read. Two facts below (the mini-review result files that failed their shape check, and the gate 3.4 resume of T3) rest on the orchestrator's account of the run plus the files named beside them.

## Measurements

Counted from the spec folder and git as `modules/evidence.md` says; `not recorded` where the files do not hold the number.

| Measure | Value |
| --- | --- |
| Elapsed | first design-log entry 2026-11-12; commits 2026-11-12T16:42:04-05:00 to 2026-11-12T21:41:10-05:00; 4 h 59 min span, with no commit between 16:47 and 19:51 |
| Waits | 7 answers recorded in `design-log.md`; minutes: not recorded |
| Agent launches | implementation 11 (nine tasks, T3's rework, the Phase 1 harness), mini-review 10, integration 1, review lenses 3; discovery: not recorded. Resumes inside one launch leave no file: not recorded |
| Harness runs | 13 recorded runs passed, 0 failed; the other 4 of the 17 `toolchain.json` records hold no `test` run of their own (reused or skipped). A floor: each evidence folder keeps only its newest run |
| Findings by class | triage: 0 high, 0 medium, 1 low, 1 false, 0 unproven; routes: 1 patch, 0 decision needed, 0 discovered work, 0 proposal, 1 none; mini-review fails 4 (T1, T2, T6, T7: one name or comment each, patched from the reviewer's own fix text) |

The mini-review count is read from the `verdict:` line of each file. The command in `modules/evidence.md` matches only the quoted form `verdict: "fail"` and would print 1.

## Result against the spec

Judged on the merged spec branch at `886a32c`, all tasks together.

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-015: one script creates every agent worktree and scratch worktree and sets up every spec worktree; services start before a test run and stop on removal | yes, in fixture projects | report.md § Capabilities; `review-end-state.yaml` (16 checks, 0 findings) |
| Constraint: a project that declares nothing behaves as before | yes | JRN-002, `scripts/spec-worktree` in `gate-3.9-r1/toolchain.txt` |
| Constraint: the scaffold sets nothing project-specific; it hands over a slot, an instance name and a port offset | yes | `review-end-state.yaml`, "no project-specific values" |
| Constraint: copies are never links, and only gitignored files are copied | yes | JRN-001 cases; `review-end-state.yaml`, "copies never links" |
| Constraint: one set of services per spec; services start only for a toolchain key that will run | yes | JRN-005 cases in `scripts/run-toolchain` |
| Constraint: a failing setup command stops with its output; no fallback, no setup by hand | yes for the script; the "no agent sets up by hand" half is wording only | JRN-006; JRN-008 (`lint/worktree-setup-docs`); report.md § Known gaps |
| Constraint: bash 3.2, git and yq only; header and comment rules of the shell-scripts profile | yes | `review-targets.yaml`, script lint and harness lint pass |
| Success signal: a spec built start to sign-off in a project that declares its setup, a second spec beside it on its own ports | partly | proven in fixtures only; `review-end-state.yaml` `not_verifiable`; report.md § Known gaps |
| End state 1: spec and agent worktree hold the copied file and the setup command ran with the isolation values | yes | JRN-001 |
| End state 2: nothing declared leaves the same files and stdout | yes | JRN-002 |
| End state 3: a link into the main checkout fails setup and `run-toolchain.sh`; an outside link passes | yes | JRN-003 |
| End state 4: two spec worktrees hold different slots; a freed slot is reused | yes | JRN-004 |
| End state 5: `services_up` before `test` and `e2e`, not when skipped or reused; `remove` runs `services_down` | yes | JRN-005 |
| End state 6: a failing setup exits non-zero; a second run after the fix finishes | yes | JRN-006 |
| End state 7: a scratch worktree is set up with the spec's slot | yes | JRN-007 |
| End state 8: no document tells a reader to run a raw `git worktree add` or `remove` | yes | JRN-008 |
| JRN-001 to JRN-008 | yes | report.md § Journeys; `gate-3.9-r1/toolchain.txt`: `TOTAL passed=4860 failed=0 skipped=0 xfail=0 (79 suites)` |
| Target: script lint clean | yes | `review-targets.yaml` |
| Target: harness lint clean | yes | `review-targets.yaml` |
| Target: agent-docs lint clean | yes | `review-targets.yaml` |
| Target: every script this spec adds or changes has a suite | yes (0) | `review-targets.yaml` |
| Target: every new `.agents/` file is in `PROVENANCE.md` | yes; measured 1 against 0, and the measure was wrong | design-log.md, Triage, review pass 1, F2: `PROVENANCE.md` line 11 names the script |
| Targets: cost with nothing declared; line coverage of changed shell code | not measured, by design | design-log.md, "Assumed: targets that are not measured" |

Built but not asked for:
- `lint/step-list` now allows the gitignored agent worktree folder, because the suite failed in every new worktree (`artifacts/T2/implementation.yaml`, summary). The work needed it.
- A new suite, `tests/lint/standards-coverage-docs.sh`, in place of a case in `size-budget-docs.sh` (`artifacts/T7/implementation.yaml`, summary).
- `worktree-setup.sh env` gives a slot to a spec worktree made before this change (spec.md § Assumptions).

## Behavior verification

The whole harness passed on the merged spec branch after rework 1: 4,860 tests, 79 suites, 0 failed (`artifacts/gate-3.9-r1/toolchain.txt`; `sign-off-5.4` ran the same tree). The same suites failed by design before the feature existed, 72 assertion failures (`artifacts/phase-1-known-bad/record.md`).

The script was also used for real from wave 3 on: eight task worktrees were made and removed with it, the gates ran through the new `run-toolchain.sh`, and this spec worktree took slot 1 (report.md § Journeys, "Behaviour verification"). This repo declares no setup command, copy list or services, so that use exercised the nothing-declared path only. No project that declares them has run a spec through it. No browser run exists: the repo has no browser profile.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| The success signal is not shown live, and whether agents follow the no-setup-by-hand rule shows only in a live run | report.md § Known gaps; `review-end-state.yaml` `not_verifiable` | fix now: action item, a first run in a project that declares its setup | - |
| The implementation-resume load (the files a resumed implementation session reads) is a few bytes under its 55,000-byte lint limit. T5 and T9 each failed `lint/workflow-load-size` first (55,187 and 55,043 bytes) and trimmed wording to pass. The 00014 retrospective already measured 54,967 | `artifacts/T5/implementation.yaml` `evidence.suite`; `artifacts/T9/implementation.yaml` `evidence.red`; report.md § Known gaps; `retrospectives/00014-tracker-issue-spec-ids.md` § Result | kept, as the stakeholder ruled at 5.5 | `.workflow/specs/work-backlog/00015-worktree-provisioning.md` B1 |
| A stop audit on a worktree holding a link into the main checkout may block the same stop three times; not proven | `review-standards.yaml` `not_checked`; report.md § Known gaps | accept: unproven, and the link check itself is tested; a fixture run would settle it | - |
| `worktree-setup.sh` and `spec-worktree.sh` drop the settings reader's error text and stop with a generic message | `review-standards.yaml` `not_checked` | accept: the script still exits with a message, as the profile asks | - |
| Two spec worktrees created at the same instant may take one slot | `review-end-state.yaml` `not_checked`; report.md § Known gaps | accept: accepted in the data model; the spec does not ask for concurrent creation | - |
| `run-toolchain.sh --reuse-check` skips the link check | `artifacts/T4/implementation.yaml`, summary | accept: that option must run and write nothing | - |
| The asset-coverage target command greps for a path form `PROVENANCE.md` never uses (F2, false) | design-log.md, Triage, review pass 1 | accept for this spec; the command is lesson L3 | - |
| T1's ten own tests were written after the code and never seen failing | `artifacts/T1/implementation.yaml` `evidence.red` | accept: the Phase 1 cases for the same keys were seen failing | - |
| The settings reader exits 1 for a usage error where sibling scripts exit 2 | design-log.md, "Scope decision: usage exit code of the settings reader" | kept | .workflow/deferred/rules-setting-usage-exit-code.md |
| Line coverage of changed shell code, and the cost with nothing declared, are not measurable | report.md § Targets vs measured | accept: no bash coverage tool is installed; JRN-002 proves the unchanged behaviour | - |

F1 (one source for the isolation values, low) was patched in rework 1 (`artifacts/T3/implementation.yaml`, commit `1f09da1`) and is closed.

## Previous-retrospective follow-through

Previous file: `.workflow/decisions/retrospectives/00014-tracker-issue-spec-ids.md`.

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| Run the tracker path once against a real GitLab project and a real GitHub repo | no evidence found | The item waits for the first project that sets up a tracker. This spec filed no tracker issue (`spec.md` frontmatter `tracker_issue: ""`), and nothing in this repo records a live run |

## Process lessons

The stakeholder approved every lesson as drafted at 5.5 (design-log.md, Sign-off entry).

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| **L1.** The breakdown the stakeholder approved was ten tasks; it was regrouped to nine after approval, because a Phase 1 test is a whole suite owned by one task and three suites needed more than one approved task to pass. The suites were already named in the Check column of the Journeys table when the breakdown was drafted. Next time, draft the slices so that each suite in that column can be turned green by one task, before the breakdown quiz is sent. Source: design-log.md, "Breakdown quiz" (D8) and "Assumed: the breakdown follows the Phase 1 suites"; verification-plan.md § Journeys | skill change (judgement) | this table, plus the action item for one sentence in `.agents/skills/feature-workflow/modules/task-breakdown.md` 2.1 |
| **L2.** Two mini-review result files failed their shape check and cost a resume each: T1 (an item with no `location`) and T3 (YAML that did not parse, an unquoted value). The mini-review is the cheap reviewer that judges one task's diff. Its definition already says to double-quote values, and the same fault cost resumes in specs 00010, 007 and 009. Once the brief told the reviewer to check its own file with yq, no later file failed. Make that check a standing line in the reviewer's definition instead of a brief line the orchestrator has to remember. Source: orchestrator's account of the run; `artifacts/T1/mini-review-r1.yaml` and `artifacts/T2/mini-review-r1.yaml` (unquoted values) against `artifacts/T3/mini-review.yaml` and every later file (all values quoted); `.workflow/model-map.yaml` lines 53 to 55; `.agents/agents/profile-mini-review.md:67` | tool rule (mechanical) | the action item: a line in `.agents/agents/profile-mini-review.md` § Return telling the reviewer to run `check-task-result.sh` on its file before it returns |
| **L3.** The asset-coverage target command greps `PROVENANCE.md` for a new file's path under `.agents/`, but that file names a shared script by its bare name inside its skill's row. The review-targets lens therefore reported a miss at high severity and triage dismissed it as false. The same command sits in the verification plans of specs 009 and 00014, so the next plan will copy it. When filling the Targets table at 1.1, write the command to grep for the file's bare name. Source: design-log.md, Triage, review pass 1, F2; `artifacts/review/pass-1/review-targets.yaml` RT-1; verification-plan.md § Targets, `asset-coverage` | process | this table |

No review lesson was proposed: F1 was one duplicated line, patched, and no symptom here is likely to recur in a diff. No recorded review lesson was retired: P1 is a capability entry and enforces none of RL-001 to RL-009.

## Pitfalls

None. The two failures seen were fixed inside their own tasks: `lint/step-list` failing in every new worktree (T2) and the duplicated isolation values (F1, rework 1 of T3).

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| None. | - | - | - |

## Feature notes

None. The decisions worth keeping are already entries in `design-log.md` (the merge route, the regrouped breakdown) or known gaps in `report.md`.

## Model observations

| Task type | Host | Observation | Alias change |
| --- | --- | --- | --- |
| implementation | claude opus | **L4.** Nine tasks and one rework, each converging in one launch. Gate 3.4 (the check that a task added negative and edge tests) sent T1 and T3 back: each first listed no tests of its own although it built behaviour the Phase 1 cases did not cover; T1's ten added cases were never seen failing. T2 correctly returned discovered work for a lint that failed in every new worktree. Source: `artifacts/T1/implementation.yaml` summary and `evidence.red`; `artifacts/T3/implementation-r1.yaml` `tests_added`; `artifacts/T2/implementation.yaml` summary. Recorded in `.workflow/model-map.yaml`, `implementation.observations` | none |
| profile-mini-review | claude haiku | **L5.** Ten reviews; four failed on one real name or comment fault each (T1 R5, T2 R1, T6 R4, T7 R1), each with fix text the orchestrator applied without a fix round. Two result files failed their shape check and needed a resume (T1 a missing `location`, T3 unparseable YAML); none failed after the brief asked for quoted values checked with yq. Source: the four `mini-review-r1.yaml` files with `verdict: fail` and their `patched:` commits; the orchestrator's account for the two shape failures. Recorded in `.workflow/model-map.yaml`, `profile-mini-review.observations` | none |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Run one spec from start to sign-off in a project that declares `worktree_setup`, `services_up`, `services_down` and a `.worktreeinclude`, with a second spec beside it, and confirm no agent sets anything up by hand | stakeholder, on the first project that declares its setup | yes |
| L1: add to `task-breakdown.md` 2.1 that each suite in the Journeys Check column must be passable by one slice | stakeholder (a 5.3 proposal in a later feature, or applied by hand) | yes |
| L2: add to `.agents/agents/profile-mini-review.md` § Return that the reviewer runs `check-task-result.sh` on its result file before returning | stakeholder (a 5.3 proposal in a later feature, or applied by hand) | yes |

## Acceptance verdict

`accepted-with-open-items`. The machine verdict and the stakeholder's decision agree: the stakeholder approved the work and the merge message at 5.5 (design-log.md, Sign-off entry). Every capability, constraint, end-state objective, journey and measurable target is met in fixture projects; all nine tasks are `done`; the whole harness passes (4,860 tests, 79 suites); the one review finding left after triage was patched and no blocking finding is open. Open items: the success signal is proven in fixtures only and needs a live run, the resume load has no room left under its limit (backlog B1), and one item stays on the shelf (`rules-setting-usage-exit-code`).

## Open questions

- `task_review` in `.workflow/rules.md` reads `pr`, but the stakeholder ruled "merge locally, no PRs" for this spec (design-log.md, "Merge route"), and spec 00014 also merged every task locally (its retrospective, § Feature notes). Should the setting change to match, or does `pr` stay the default?
