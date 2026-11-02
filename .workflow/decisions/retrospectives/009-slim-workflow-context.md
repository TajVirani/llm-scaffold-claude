---
spec: .workflow/specs/009-slim-workflow-context
date: 2026-11-02
verdict: accepted-with-open-items
---

# Retrospective: Slim the workflow context

## Summary

- Spec: `.workflow/specs/009-slim-workflow-context/spec.md` (capabilities: CAP-012)
- Report: `.workflow/specs/009-slim-workflow-context/report.md`
- Tasks: 10 done, 0 split out (`tasks.md`)
- Evidence available: `spec.md`, `verification-plan.md`, `report.md`, `tasks.md`, `design-log.md` (triage pass 1, rework 1 result, sign-off entry), `proposals.md` (P1–P4 approved), `artifacts/` (toolchain per task, gates 3.9 w1–w7 and rework1, sign-off-5.4, review pass 1), `.workflow/specs/work-backlog/009-slim-workflow-context.md` (B1, B2), shelf files `cache-scope-paths.md` and `in-review-hand-off.md`, git `a29eca7..8930c34`, `.workflow/review-lessons.md`, previous retrospective `00013-validator-diagnostic.md`
- Evidence missing: session logs (process lessons come from `design-log.md` and the stakeholder only); waiting minutes

## Measurements

| Measure | Value |
| --- | --- |
| Elapsed | first log entry 2026-10-29; first commit 2026-11-01T14:12:26-05:00, last 2026-11-02T10:28:45-05:00; commit span 20 h 16 min (questioning rounds 1–4 came before the first commit) |
| Waits | 29 answers recorded; minutes: not recorded |
| Agent launches | implementation 20, mini-review 22, integration 0, review lenses 4 (result files, so fix rounds count); discovery: not recorded |
| Harness runs | 20 run (20 pass, 0 fail), 0 reused (toolchain records; a floor, each dir keeps its newest run) |
| Findings by class | triage: 0 high, 1 medium, 4 low, 3 false, 0 unproven; routes: 4 patch, 0 decision needed, 1 discovered work, 0 proposal, 3 none; mini-review fails 5 (T1 r1, r2, r3, r5; T7 r1) |
| Change volume | 62 commits; `git diff --stat a29eca7..HEAD`: 207 files, +13,702 −884 (spec folder and artifacts included) |

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-012: a new-feature start loads at most 45,000 bytes | yes | 44,733 bytes, report.md Targets vs measured [E2] |
| CAP-012: an implementation resume loads at most 55,000 bytes | yes | 54,360 bytes, report.md [E2] |
| CAP-012: a test suite fails above either limit (D19) | yes | `lint/workflow-load-size` padded-fixture checks (JRN-008), report.md Journeys |
| CAP-012: every rule lives in one file | yes | `lint/shared-rule-homes` green; F3 (a second copy in verification-setup) fixed in rework 1 |
| CAP-012: every relative link and anchor under `.agents/` resolves | partly | `lint/md-links` green, but it skips `assets/` folders (report.md Known gaps) |
| CAP-012: `tests/run-all.sh` passes | yes | `TOTAL passed=4458 failed=0 (75 suites)`, artifacts/sign-off-5.4/toolchain.txt |
| Constraint: behaviour unchanged | yes | full suite green; review-end-state compared the orchestrator split line by line with the baseline (pass-1 `checked`) |
| Constraint: no new dependencies | yes | byte counts with `wc`, checks in bash (codebase-map.md Library options) |
| Constraint: bash 3.2, term-list script in domain-modeling, output style references no script | yes | `term-list.sh`; review-end-state pass-1 `checked` (term list and output style print the same 43 lines) |
| Constraint: `modules/` keeps its name | yes | folder unchanged |
| Constraint: 3.9 and 3.13 in the waves step file; 3.2 and 3.4–3.8 in their own files | yes | `implementation-waves.md`, `implementation-shared-core.md`, `implementation-gates.md` |
| Constraint: 0.2.1 reads only module names and `owns` paths | yes | `lint/affected-area` (JRN-009) |
| Constraint: small-path.md folded in, no overlay | yes | file deleted; `lint/small-path-docs` (JRN-007) |
| Constraint: escalation rule lives once, in discovered-work.md | yes | review-end-state pass-1 `checked` |
| Constraint: `modules:` and `progressive_loading:` keys removed | yes | review-end-state pass-1 `checked` (no `modules:` or `progressive_loading:` key in SKILL.md frontmatter) |
| Success signal: 45 KB start, 55 KB resume, full suite with link lint and size check passes | yes | report.md Summary and Tests |
| JRN-001 to JRN-010 | yes | report.md Journeys, each a green suite at head and red at baseline (artifacts/phase-1-known-bad/record.md) |
| Targets: script lint, harness lint, agent-docs lint, script coverage, PROVENANCE coverage | yes | report.md Targets vs measured |
| Target: line coverage of changed shell code | no (not measured) | no bash coverage tool; stated as not measured in verification-plan.md |

Built but not asked for: None.

## Behavior verification

Every journey is a harness suite: each new suite was red on the baseline and is green at head (artifacts/phase-1-known-bad/record.md, artifacts/sign-off-5.4/toolchain.txt). In a live session, Phase 4 and sign-off ran from the new step files (`review-triage.md`, `implementation-waves.md`, `implementation-gates.md`, `implementation-finish.md`, `sign-off.md`) and worked as written. The new router was not exercised: this session started in the main checkout and loaded feature-workflow from there before moving into the spec worktree.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| feature-workflow links into the retrospective skill's files, an edge rules.md Ownership does not declare (pre-existing) | review-standards RS-3, F5; `sign-off.md:134,194` | kept | .workflow/specs/work-backlog/009-slim-workflow-context.md B1 |
| Implementation agents quote `self_review[].item`, which `check-task-result.sh` rejects | 3.4 wave 1 and rework 1 (T1, T2, T9, T10); `.agents/agents/implementation.md:141` | kept | .workflow/specs/work-backlog/009-slim-workflow-context.md B2 |
| Live sessions following the split step files on Claude Code and Codex not observed | review-end-state not_verifiable | accept: the first feature session on main after the merge settles it | - |
| Line coverage of changed shell code not measured | review-targets | accept: no bash coverage tool, no new dependency allowed | - |
| Links inside `assets/` files are not checked | review-end-state not_checked; `lint/md-links` skips `assets/` | accept: `lint/md-links` treats `assets/` files as templates and skips them | - |
| `term-list.sh` and the output style's `awk` command are not on the shipped allow list | review-end-state not_checked; `.agents/hooks/claude-settings.template.json` | accept: unproven; a fresh target-project session would show whether it prompts | - |
| Start load has 267 bytes spare and counts the term list | report.md Known gaps | accept: ADR-0004 says to trim when the lint fails | - |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 00013: at 3.7, an out_of_scope_noticed entry about lines the task itself changed is handled as a fix round, not discovered work | partly | de09eea added the route (a 3.7 entry routed as current work joins the 3.8 fix list), now at `modules/implementation-gates.md:19` and the waves "Current work" route; a `can-wait` entry about the task's own lines still goes to discovered work first (`.agents/agents/profile-mini-review.md:57`) |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| The split step files ran Phase 4 and sign-off on their first live use; the escalation rule sent all four fixes to workers, and the stakeholder saw two asks (5.3, 5.5) | process | this document |
| A rule moved into a shared reference file kept a paraphrased copy in the step file it left (F3) | review lesson | `.workflow/review-lessons.md` RL-008 |
| A Targets command ran a suite file directly, but suites are committed 100644 and run through `bash`, so the targets lens could not measure two targets (F4) | judgement | action item: a verification-setup 1.1 line, not recorded yet |
| A mini-review read "new file" as new to the task branch and asked for `[ ]` in a file the spec created (F1, as in spec 008) | profile | `.workflow/profiles/shell-scripts.md` § Language and style rules (P4, applied at 5.3) |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| A moved rule kept a copy in the step file it left (F3) | `modules/verification-setup.md` | none yet; RL-008 tells review to look | already present (added at 5.3, P3) |
| T10 was merged before its mini-review file passed the checker; a pipe hid the exit code | 3.16, wave 7 | waves 3.16 "each line as its own command, never piped" | already present ("Never pipe a gate checker into head inside a && chain") |

## Feature notes

- A session that starts in the main checkout loads the old router even after moving into the spec worktree (design-log.md, 2026-11-02 Retrospective notes)
- The start load has 267 bytes spare and counts the term list (design-log.md, 2026-11-02 Retrospective notes)

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| implementation | claude | Quoted `self_review[].item` in T1, T2, T9 and T10 (B2), each fixed in one resume; every rework converged in one launch | none | .workflow/model-map/implementation.md |
| profile-mini-review | claude | Full re-review of T1 caught a missing `# die MSG :` comment four earlier rounds passed; T1 round 1 asked for `[ ]` in a new file again (as in 008); one result file missed a `location` | none | .workflow/model-map/profile-mini-review.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Add a verification-setup 1.1 line: a Targets command runs a suite file through `bash`, as the harness does (F4) | stakeholder, as a 5.3 proposal in a later feature | yes |

## Acceptance verdict

`accepted-with-open-items`: every capability success line, constraint, journey and success signal is met at head (report.md, full suite 4458/0), and every task is `done`. Open items stay tracked: B1 and B2 on the backlog list, and the known gaps above (live-session check of the new router, line coverage, links inside `assets/`, the allow-list question, the load margin). The stakeholder approved the work at 5.5.

## Open questions

None.
