---
spec: .workflow/specs/done/00016-per-run-handoffs
date: 2026-11-12
verdict: accepted-with-open-items
---

# Retrospective: Per-run session handoffs

## Summary

- Spec: `.workflow/specs/done/00016-per-run-handoffs/spec.md` (capabilities: CAP-015)
- Report: `.workflow/specs/done/00016-per-run-handoffs/report.md`
- Tasks: 2 done, 0 split out
- Evidence available: `spec.md`, `verification-plan.md`, `report.md`, `tasks.md`, `design-log.md` (one triage entry), `proposals.md` (P1, approved), `artifacts/` (T1, T2, phase-1-test-harness, phase-1-known-bad, gate-3.9-w1, gate-3.9-r1, sign-off-5.4, review/pass-1), `.workflow/specs/work-backlog/00016-per-run-handoffs.md` (B1), `.workflow/deferred/browser-suite.md`, git `0900278..a486359`, `.workflow/review-lessons.md`, the previous retrospective `00014-tracker-issue-spec-ids.md`
- Evidence missing: session logs (not read)

## Measurements

| Measure | Value |
| --- | --- |
| Elapsed | first log entry 2026-11-12; first commit 2026-11-12T20:38:18-05:00, last 2026-11-12T21:47:59-05:00; span 1 h 10 min |
| Waits | 9 answers recorded before sign-off; minutes: not recorded |
| Agent launches | implementation 4 (Phase 1, T1, T2, T1 rework), mini-review 3, integration 0, review lenses 3; discovery: not recorded |
| Harness runs | 3 run (3 pass, 0 fail), sign-off run reused; the known-bad run at 1.4 is outside this count |
| Findings by class | triage: 0 high, 0 medium, 3 low, 0 false, 0 unproven; routes: 3 patch, 0 decision needed, 0 discovered work, 0 proposal, 0 none; mini-review fails 1 (T2, R3, patched) |

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-015: handoff written under the session's own checkout, nothing in the main checkout | yes | report.md Journeys, JRN-001 |
| CAP-015: no handoff in `git status` with or without the install.sh ignore block | yes | report.md Journeys, JRN-002 |
| CAP-015: two handoffs for one spec in the same second have different names | yes | report.md Journeys, JRN-003 (fixed clock after F3) |
| CAP-015: the offer lists the own checkout first and names each handoff's path | yes | report.md Journeys, JRN-004, JRN-005 |
| Constraint: the handoff skill stays self-contained | yes | `.agents/skills/handoff/SKILL.md` Locate block calls no script |
| Constraint: the folder stays `.workflow/.handoff/`; install.sh block and repo `.gitignore` keep their entry | yes | report.md Size budget files: neither `install.sh` nor `.gitignore` changed |
| Constraint: the offer stays inside its size cap and still says not to resume unasked | yes | JRN-005 checks in `tests/hooks/audit-sync-resume.sh` |
| Constraint: an old-name handoff is still listed and can be resumed | yes | JRN-005; JRN-006 wording |
| Success signal | partly | proven in the harness; not exercised in a live session (report.md Known gaps) |
| JRN-006 Resume rules are written down | yes | report.md Journeys |
| Targets (offer size, errors, coverage) | partly | all three `not_measurable` by a command (report.md Targets vs measured) |

Built but not asked for: None.

## Behavior verification

The journeys ran in the harness against temp repositories: the skill's Locate block was extracted and run as written, and the session-start hook was run with a payload `cwd`. Runtime behaviour in a live session was not exercised: no session was started inside a spec worktree to read its offer.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| `lint/step-list` fails in any agent or scratch worktree (`checklist.md:328` names an ignored folder) | design-log.md, Discovered work: step-list-lint-in-agent-worktree; `artifacts/T1/implementation-r1.yaml` | kept | .workflow/specs/work-backlog/00016-per-run-handoffs.md B1 |
| Live SessionStart `cwd` in a spec worktree not checked | `artifacts/review/pass-1/review-end-state.yaml` not_verifiable | accept: the fixture proves the ordering, and the first real handoff from a spec worktree shows it | - |
| Targets not measurable by a command | `artifacts/review/pass-1/review-targets.yaml` | accept: the cap and exit code are asserted by the suite | - |
| Browser gate skipped | spec.md Known gaps | kept | .workflow/deferred/browser-suite.md |
| Task PRs not opened (`gh` not installed) | design-log.md, 3.16 line | accept: both tasks merged locally with their mini-review records | - |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| Run the tracker path once against a real GitLab project and a real GitHub repo (00014) | no evidence found | this spec ran with no tracker (`skipped: no tracker`) |

## Process lessons

None.

## Pitfalls

None.

## Feature notes

None.

## Model observations

None.

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Start one session inside a spec worktree that holds a handoff and confirm the offer lists it first | stakeholder, on the next handoff from a spec worktree | yes |

## Acceptance verdict

`accepted-with-open-items`. Machine verdict and stakeholder decision agree: the stakeholder approved the work and the PR description at 5.5 (design-log.md, Sign-off entry). Every spec item is met in the harness and both tasks are `done`; the open items are the live-session check, the unmeasured targets, the skipped browser gate and backlog item B1.

## Open questions

None.
