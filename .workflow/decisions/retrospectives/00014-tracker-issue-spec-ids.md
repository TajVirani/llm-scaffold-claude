---
spec: .workflow/specs/done/00014-tracker-issue-spec-ids
date: 2026-11-03
verdict: accepted-with-open-items
---

# Retrospective: Tracker issues as spec IDs

## Summary

- Spec: `.workflow/specs/done/00014-tracker-issue-spec-ids/spec.md` (capabilities: CAP-013, CAP-014)
- Report: `.workflow/specs/done/00014-tracker-issue-spec-ids/report.md`
- Tasks: 10 done, 0 split out
- Evidence available:
  - `spec.md`, `verification-plan.md`, `report.md`, `tasks.md`, `design-log.md` (two triage entries, the sign-off entry) and `proposals.md` (P1-P7 approved);
  - `artifacts/` (per-task toolchain, mini-review and implementation records, two review passes, Phase 1 known-bad record, `sign-off-5.4`);
  - `work-backlog/00014-tracker-issue-spec-ids.md` (B1, B2) and the two shelf files in `deferred`;
  - git `e8162a9..a32f33f`: 71 commits, 244 files changed, 19,253 insertions, 423 deletions, the spec folder's artifacts included.
- Evidence missing: session logs were not read; process lessons come from `design-log.md` and the stakeholder.

## Measurements

| Measure | Value |
| --- | --- |
| Elapsed | first design-log entry 2026-11-02; commits 2026-11-02T14:03:05-05:00 to 2026-11-02T19:45:09-05:00 on the spec branch; 5 h 42 min span (sign-off continued 2026-11-03) |
| Waits | 28 answers recorded in `design-log.md`; minutes: not recorded |
| Agent launches | implementation 22, mini-review 23, integration 2, review lenses 8; discovery: not recorded |
| Harness runs | 20 recorded runs passed, 0 failed (a floor: each evidence dir keeps its newest run) |
| Findings by class | triage: 1 high, 7 medium, 4 low, 0 false, 0 unproven; routes: 8 patch, 0 decision needed, 2 discovered work, 1 proposal, 1 none; mini-review fails 5 |

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-013 Specs and tasks filed as tracker issues | yes, against fake CLIs | report.md Capabilities; JRN-001 to JRN-009 |
| CAP-014 Tracker setup and adoption | yes, against fake CLIs and a local bare origin | report.md Capabilities; JRN-010 to JRN-014 |
| No tracker: numbering, templates and PR stub unchanged, no tracker call | yes | JRN-001 (`scripts/next-spec-number`); the PR stub is unchanged in `assets/pr-template.md` |
| Unreachable tracker stops the spec start | yes | JRN-008 |
| Issue created first, placeholder title, empty body; number padded to five digits | yes | JRN-002, JRN-003 |
| glab for GitLab, gh for GitHub, from `origin` | yes | JRN-002, JRN-003; `wf_origin_host` |
| Settings in `.workflow/issue-tracking.yaml` | yes | JRN-010 |
| Three-label issue flow; done closes | yes | JRN-007; sign-off 5.8 moves to done on both routes after rework 1 (F2) |
| Adoption deletes nothing on the remote; renamed branch pushed, old one reported | yes | JRN-011 |
| Load budgets: start ≤ 45,000, resume ≤ 55,000 | yes (44,286 and 54,967) | report.md Targets vs measured |
| Scripts in the `issue-tracking` skill (ADR-0005) | yes | `.agents/skills/issue-tracking/scripts/` |
| No logic copied; path rewrite and host choice in `.agents/lib` | yes | JRN-013 (`lint/shared-tracker-logic`); the https URL rule keeps several copies (review pass 2 not_checked) |
| `old_` prefix renames only the Done folder and its backlog list | yes | JRN-011, JRN-012 |
| Project PR template: URL and `Closes #<n>` appended; `check-pr-body.sh` unchanged | yes | JRN-009 |
| Tests use fake glab and gh only | yes | `tests/fixtures/fake-trackers.sh`; no live call in any suite |
| Success signal: two people get two numbers on a real tracker | partly | proven only against the fake's increasing numbers (JRN-004) |
| Every target in verification-plan.md | yes, except line coverage, not measurable | report.md Targets vs measured |

Built but not asked for:
- Adoption files task issues for specs past task breakdown (rework 2, F12). It is needed for the capability's success line, though no journey named it.
- The session-start hook accepts `old_` backlog lists (rework 1, F3).

## Behavior verification

Runtime behaviour was exercised only against fake gh and glab on PATH and a local bare git origin, as D17 requires: `tests/run-all.sh` passed 4,770 tests across 81 suites at 5.4 (`artifacts/sign-off-5.4/toolchain.txt`). No live GitLab or GitHub was called.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| Tracker adoption skips `.workflow/initiatives/`, so initiatives keep old spec names (F4) | review-end-state pass 1, `tracker-adoption.sh:245` | kept | .workflow/deferred/initiative-tracker-issues.md (Later requests) |
| Step files prescribe commit subjects that are not Conventional Commits (F10) | review-standards pass 1, `.workflow/rules.md:145` | kept | .workflow/specs/work-backlog/00014-tracker-issue-spec-ids.md B2 |
| Phase 1 runs as one long serial harness build | orchestrator, design-log "Discovered work, Phase 1 duration" | kept | .workflow/specs/work-backlog/00014-tracker-issue-spec-ids.md B1 |
| An http GitLab files an issue before its URL is refused (F11) | review-standards pass 2 | accept: a GitLab served over plain http is unlikely in everyday use and the fix adds a guard | - |
| Tracker calls proven against fakes only: GraphQL child task, CLI minimums, simultaneous starts | report.md Known gaps | accept: D17 limits tests to fakes; one live run settles each | - |
| Line coverage of changed shell code not measurable | report.md Targets vs measured | accept: no bash coverage tool is installed; script-coverage stands in | - |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| (00013, carried from 00011) an `out_of_scope_noticed` entry about lines the task itself changed is handled as a fix round, not discovered work | yes | `.agents/skills/feature-workflow/modules/implementation-gates.md` 3.7 ("An entry it returns as **current work** ... joins this task's 3.8 fix list"); used in this spec for T5, T4 and T8 (design-log rework entries) |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| A step-file reader of a new frontmatter key had no writer step, and no Phase 1 lint caught it; only review pass 1 did (F1, high) | review lesson | .workflow/review-lessons.md RL-009 |
| Phase 1 took about 56 minutes in one serial build covering 14 journeys | process | .workflow/specs/work-backlog/00014-tracker-issue-spec-ids.md B1 |
| Quoted `self_review` checklist numbers cost one resume in each of the three wave-1 tasks; the brief line that names the unquoted form stopped it | process | not recorded: fixed on main in 44d72c0 (`check-task-result.sh` accepts a quoted number) |
| Wording re-checks kept finding new missing reasons on bash workarounds (T5, and T6 twice) | profile | .workflow/profiles/shell-scripts.md (P7, applied at 5.3) |
| A rule repeated at seven step-file call sites (F8) | review lesson | already present: .workflow/review-lessons.md RL-008 |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| No step wrote `tracker_issue`, so every tracker call would have exited 2 (F1) | `modules/discovery.md` 0.1.4 | `lint/issue-tracking-docs` 0.1.4 check | already present (P5, 5.3) |
| Adoption filed no task issues, so an adopted spec would stop at 3.3 (F12) | `scripts/tracker-adoption.sh` | `tests/scripts/tracker-adoption.sh` JRN-011 task-issue case | already present (P6, 5.3) |

## Feature notes

- Adoption leaves the main checkout's renames uncommitted by design (design-log.md, 2026-11-03 Retrospective notes section).
- The 4.7 reopen tracker call lives in `review-triage.md` to fit the resume budget (design-log.md, 2026-11-03 Retrospective notes section).
- Every task merged locally because gh is not installed (design-log.md, 2026-11-03 Retrospective notes section).

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| implementation | claude | 10 tasks; 3 behaviour fix rounds and 5 wording rounds, each converging in one launch; wave-1 agents wrote quoted `self_review` items; T8 first skipped negative tests and added 16 on one resume | none | .workflow/model-map/implementation.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Run the tracker path once against a real GitLab project (child-task GraphQL call, `relates_to` fallback, close on an already-closed issue) and a real GitHub repo | stakeholder, on the first project that sets up a tracker | yes |

## Acceptance verdict

`accepted-with-open-items`. Every spec item is met against fake CLIs, all 10 tasks are `done`, the full harness passes (4,770 tests, 81 suites), and the stakeholder approved the work at 5.5. Two items are kept for later (F4 on the shelf, B2 on the backlog), and the live-tracker checks remain known gaps.

## Open questions

None.
