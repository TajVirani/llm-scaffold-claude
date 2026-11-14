---
spec: .workflow/specs/00017-handoffs-from-session-worktrees
date: 2026-11-13
verdict: accepted-with-open-items
---

# Retrospective: Handoffs found from session worktrees

## Summary

- Spec: `.workflow/specs/00017-handoffs-from-session-worktrees/spec.md` (capabilities: CAP-015, changed)
- Report: `.workflow/specs/00017-handoffs-from-session-worktrees/report.md`
- Tasks: 1 done, 0 split out
- Evidence available: spec.md, report.md, tasks.md, design-log.md (round 1, Merge route, Suite gap, Triage pass 1, Sign-off), proposals.md, artifacts/ (T1, gate-3.9-w1, wording-p1, sign-off-5.4, review/pass-1), git `317fdd0..HEAD`
- Evidence missing: verification-plan.md not produced (light path); no session logs read

## Measurements

| Measure | Value |
| --- | --- |
| Elapsed | first log entry 2026-11-13; commits 18:15 to 19:22 (-05:00); span 1 h 7 min |
| Waits | 5 answers recorded in round 1 ("all recommended") plus the sign-off ask; minutes: not recorded |
| Agent launches | implementation 2 (T1, one 3.9 fix round), mini-review 2, integration 0, review lenses 1 (review-combined); discovery: not recorded (retrieval 1) |
| Harness runs | 2 run (2 pass), others reused; the 3.9 gate's first run failed on lint, not tests |
| Findings by class | triage: 0 high, 0 medium, 1 low, 0 false, 0 unproven; routes: 1 patch, 0 decision needed, 0 discovered work, 0 proposal, 0 none; mini-review fails 0 |

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-015: a non-spec checkout lists its own handoffs, then every other worktree's | yes | `tests/hooks/audit-sync-resume.sh` session-worktree and main cases; report.md Tests |
| CAP-015: a spec worktree lists its own plus the main checkout's only | yes | `tests/hooks/audit-sync-resume.sh` spec-worktree negative case |
| CAP-015: Resume first moves into the handoff's checkout | yes | `.agents/skills/handoff/SKILL.md` Resume step 1; `tests/scripts/handoff-skill.sh` |
| Constraint: handoff skill Locate stays self-contained | yes | review-combined pass 1 checked; Locate block unchanged |
| Constraint: cap of 3, newest first, character cap | yes | edge case "keeps the cap of 3" |
| Success signal: a fresh desktop session worktree offers the spec's handoff and moves into the spec worktree | partly | the hook side is tested; the live session and the EnterWorktree switch were not exercised (Triage pass 1 Gaps) |

Built but not asked for: None.

## Behavior verification

The hook ran end to end in fixtures (stdin payload to `additionalContext`) across main, spec and session worktrees; 4885 tests passed (report.md Tests). Before the change, the same hook run from Commonplace's `.claude/worktrees/quirky-yonath-09ed4f` omitted the 00031 handoff. No live Claude Code desktop session was run, so the EnterWorktree move from a session worktree into a spec worktree is not exercised.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| Hook wiring doc stated the old rule | F1 (RC-1), `.agents/hooks/claude-settings.template.md:9` | accept: patched in f8af45a | - |
| Browser suite missing | 3.14, spec.md Known gaps | kept | .workflow/deferred/browser-suite.md |
| Live desktop session and EnterWorktree switch from a session worktree not verified | Triage pass 1 Gaps | fix now | - |
| `PROVENANCE.md:166` states the pre-00016 handoff location | review-combined not_checked | accept: pre-existing, outside this spec | - |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 00016: start one session inside a spec worktree that holds a handoff and confirm the offer lists it first | no evidence found | no live session recorded; this spec's fixtures cover it, not a live run |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| A task classified under one work type that also changes `tests/` is linted only by its own profile, so a test-harness lint failure first shows at the 3.9 gate | judgement lesson (profile or brief line) | `.workflow/decisions/pitfalls.md` "Lint a task's tests with the test-harness profile too" (L1) |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| T1 (shell-scripts) added a test with a shellcheck SC2034 warning; its toolchain did not lint `tests/`, and the 3.9 gate failed after merge | implementation-setup 3.1 classification; run-toolchain.sh | nothing yet | added (L1, applied once with proposals.md P2) |

## Feature notes

- In Commonplace the stakeholder hit this through Claude Code desktop: each session opens in `.claude/worktrees/<name>`, and older scaffold versions also nested spec worktrees inside that folder; this spec fixes only the offer and Resume, not the existing nested worktrees. (L2; design-log.md, 2026-11-13 Retrospective notes)

## Model observations

| Task type | Host | Observation | Alias change |
| --- | --- | --- | --- |
| implementation | claude | L3 (model-map.yaml implementation): T1 done in one launch with 7 tests (negative and edge included) and reported the stale step reference it caused as discovered work; it did not run the test-harness lint on its new tests, so one 3.9 fix round, which converged in one launch | none |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Start a Claude Code desktop session in a session worktree of a project with a spec in flight; confirm the offer lists the spec's handoff and that EnterWorktree moves into `.workflow/.spec-worktrees/<spec>` | stakeholder | yes |
| Prevent the late test-harness lint (pitfall L1): brief implementers to run the test-harness lint when a task changes `tests/`, or have `run-toolchain.sh` lint changed files by owning profile | scaffold maintainer | yes |

## Acceptance verdict

`accepted-with-open-items`: every CAP-015 item and constraint is met with tests; the success signal is partly met (no live desktop session), and the browser suite is a known gap kept on the shelf. The stakeholder approved the work at 5.5.

## Open questions

- Does Claude Code's EnterWorktree accept a switch from a session worktree (`.claude/worktrees/<name>`) into `.workflow/.spec-worktrees/<spec>`? Its tool notes say a switch from inside a worktree targets `.claude/worktrees/`; if it refuses, Resume and the router need another route (reopen the session there).
