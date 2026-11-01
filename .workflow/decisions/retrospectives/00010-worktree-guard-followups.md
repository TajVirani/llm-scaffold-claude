---
spec: .workflow/specs/done/00010-worktree-guard-followups
date: 2026-10-30
verdict: accepted-with-open-items
---

# Retrospective: Worktree guard and upgrade follow-ups

## Summary

- Spec: `.workflow/specs/done/00010-worktree-guard-followups/spec.md` (capabilities: CAP-007 changed, CAP-008 changed, CAP-010 new)
- Report: `.workflow/specs/done/00010-worktree-guard-followups/report.md`
- Tasks: 4 done (T1-T4), 0 split out; 7 items deferred (`frontmatter-extract-write-guard.md`, `subagent-missing-transcript-path.md`, and five backlog items moved at 5.9), plus Later requests lines on `bash-line-coverage.md` and `comment-id-lint.md`
- Evidence available: spec.md, verification-plan.md, report.md, tasks.md, design-log.md (rounds 1-3, triage pass 1, sign-off), proposals.md (P1-P4 approved), `artifacts/` (Phase 1 known-bad record, per-task toolchain and mini-review files, review pass 1, gates 3.9 w1/w2/rework1, sign-off-5.4), git `1c5e46d..f276ea1` plus the sign-off commits (25 commits to the 5.4 head; 13 files outside `.workflow/`, +383/-68)
- Evidence missing: session logs (process lessons come from design-log.md and the stakeholder)

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-007 fail closed: unconfinable implementation/integration agent denied every call, cause named; unparsable payload and missing jq denied; "agent worktree" wording; orchestrator line | yes | report.md Capabilities; JRN-001, JRN-003, JRN-005 in `hooks/worktree-guard` (`artifacts/sign-off-5.4/toolchain.txt`) |
| CAP-008 quoted `$`: single-quoted `$`/backtick reads pass; `$`, backtick, backslash outside single quotes deny | yes | JRN-006 checks; `artifacts/phase-1-known-bad/record.md` Run 1 (red at baseline) |
| CAP-010 in-place extract denied in template and repo settings, merged by `install.sh` | yes | JRN-007 checks; live refusal 2026-10-30 (design-log triage F3) |
| Constraint: rule lives in `check-worktree-scope.sh`, hooks thin (D1) | yes | `--confined` in the scope check; the hook only passes it (T1, T2 diffs) |
| Constraint: Codex unchanged | yes | `codex-write-guard.sh` not in the diff; JRN-004 Codex case allowed |
| Constraint: linked-worktree launches keep cwd confinement | yes | JRN-002 checks |
| Constraint: `install.sh` and template line 148 untouched | yes | `git diff 1c5e46d..HEAD -- install.sh` empty; deny rules inserted above line 148 (T3 diff) |
| Constraint: bash 3.2, no new runtime | yes | script-lint target pass; library-evaluation verdict |
| Constraint: `assetlist.md` rewritten in place, no "Amended by" (D8) | yes | JRN-009 checks |
| Constraint: three upgrade re-run checks assert exit 0 | yes | JRN-008; red under a refusing installer (record.md Run 2) |
| Success signal | yes | report.md Summary and How to verify |
| JRN-001 to JRN-009 | yes | report.md Journeys |
| Targets: 7 measurable | yes | report.md Targets vs measured (all PASS, guard-time 0.19 s against 0.5 s) |
| Target: line coverage | partly | not measured by decision D14 |

Built but not asked for: None. (The Phase 1 harness also asserted exit 0 on a third re-run check at `tests/scripts/install-upgrade.sh:184`, inside the spec's "three re-run checks".)

## Behavior verification

The harness drives `worktree-write-guard.sh` and `check-worktree-scope.sh` with real payloads, fixture repos, agent worktrees and a linked worktree, and runs `install.sh` into fixture targets; the full harness passes (`TOTAL passed=3678 failed=0 (62 suites)`). In the orchestrating Claude Code session, `yq --front-matter=extract -i` on a scratch file was refused by the new deny rule and a plain extract read ran. Not exercised: a live sub-agent payload with a missing transcript (deferred).

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1 journey id in a suite body comment | review-standards RS-1, `tests/hooks/worktree-guard.sh:92` | fix now (patched in rework 1) | - |
| F2 "named worktree" alias in hook header and suite labels | review-standards RS-2, `worktree-write-guard.sh:29` | fix now (patched in rework 1) | - |
| F3 other in-place extract spellings (`-Pi`) pass the prefix allow | review-lessons RL-1 (repeats RL-005) | defer | [.workflow/deferred/frontmatter-extract-write-guard.md](../../deferred/frontmatter-extract-write-guard.md) |
| F4 quoted write flags pass the read-only check (pre-existing) | review-lessons RL-2 | defer | [.workflow/deferred/read-only-allowlist-flags.md](../../deferred/read-only-allowlist-flags.md) |
| Missing-transcript deny proven on fixtures only | review-end-state `not_verifiable` | defer | [.workflow/deferred/subagent-missing-transcript-path.md](../../deferred/subagent-missing-transcript-path.md) |
| Line coverage not measured | review-targets | accept: no bash coverage tool and no new dependency (D14); shelf item exists | [.workflow/deferred/bash-line-coverage.md](../../deferred/bash-line-coverage.md) |
| Second stop-audit row in `assetlist.md` | Phase 1 build, disc-001 | defer | [.workflow/deferred/asset-list-stop-audit-row.md](../../deferred/asset-list-stop-audit-row.md) |
| Guard errors before confinement exit non-zero | T2 mini-review, disc-002 | defer | [.workflow/deferred/worktree-guard-early-errors.md](../../deferred/worktree-guard-early-errors.md) |
| Malformed transcript gets the wrong cause | T2 mini-review, disc-003 | defer | [.workflow/deferred/worktree-guard-transcript-cause.md](../../deferred/worktree-guard-transcript-cause.md) |
| Hooks folder resolved with `cd` and `cd -P` | T2 mini-review, disc-004 | defer | [.workflow/deferred/worktree-guard-hooks-dir.md](../../deferred/worktree-guard-hooks-dir.md) |
| Journey ids in suite headers | T2 rework mini-review, disc-006 | defer | [.workflow/deferred/comment-id-lint.md](../../deferred/comment-id-lint.md) (Later requests) |

## Previous-retrospective follow-through

Previous: `.workflow/decisions/retrospectives/008-pr-description-template.md` is the newest by number; its sibling 006 was the origin of this spec, so 006's action items are checked here.

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 006-1 `implementation.md`: audit every rule branch before stopping | no evidence found | `grep -n branch .agents/agents/implementation.md` shows no such step |
| 006-2 `profile-mini-review.md`: acceptance-criteria misses as their own category | no evidence found | `grep -n acceptance .agents/agents/profile-mini-review.md` prints nothing |
| 006-3 lint that every `# shellcheck disable=` carries a reason | no evidence found | no such suite under `tests/lint/` |
| 006-4 `task-breakdown.md` 2.1: map End state objectives to owning tasks | no evidence found | `grep -n "End state" .agents/skills/feature-workflow/modules/task-breakdown.md` prints nothing |
| 006-5 any digit count; five-digit new specs | yes | commit `f436aed` |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| The 0.4.6 module audit found a blocking ordering question the questioning loop missed: where a new deny mode sits in an ordered allow/deny chain (D10), costing a loop-back round. When a design adds a mode to an ordered rule chain, settle its place in the order during the loop. | checklist line (judgement) | not recorded in a checklist: this document only (approved as a process lesson) |
| A live check in the orchestrating session settled a host-behaviour assumption the repo could not (deny rule firing, F3). When a spec assumes host behaviour, check it live at review. | process lesson | this document |
| The project's rules on journey ids disagree: mini-review R5 fails them on changed suite-header lines while 39 suites carry them. | rule | [.workflow/deferred/comment-id-lint.md](../../deferred/comment-id-lint.md) Later requests (disc-006) |
| F3 repeats an existing review lesson (text denylist beside a prefix allow) | review lesson | already present: `.workflow/review-lessons.md` RL-005 |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| A mini-review result file with an unquoted `: ` string did not parse; one resume | `artifacts/T1/mini-review.yaml` (3.7) | `check-task-result.sh` parse check and the brief asking to quote such strings | added |
| `yq --front-matter=extract -i` truncating files (004's pitfall) | settings | four deny rules (partly; P4 at 5.3) | already present (Prevented by updated at 5.3) |

## Feature notes

- The four in-place extract deny rules also apply in this repo's own sessions (design-log.md, 2026-10-30 Retrospective notes section)
- With jq missing, the worktree guard denies main-session tool calls by design, D9 (design-log.md, 2026-10-30 Retrospective notes section)

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| profile-mini-review | claude | Caught real wording faults (T2 R2, R5) and three real out-of-scope guard bugs; one T1 result file held unquoted YAML (`artifacts/T1/mini-review.yaml`, resumed once) | none | .workflow/model-map/profile-mini-review.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Carry forward 006 action items 1-4 (no evidence they landed). | scaffold maintainer | yes |
| Decide whether suite headers may name journey ids before building the comment-id lint (`.workflow/deferred/comment-id-lint.md`). | scaffold maintainer | yes |

## Acceptance verdict

`accepted-with-open-items`. Every capability, constraint, journey and measurable target in spec.md and verification-plan.md is met with evidence (report.md; full harness 3678 passed, 0 failed), and T1-T4 are `done`. Open items are deferred and tracked: F3 (medium) and the missing-transcript live check, five backlog items moved to `.workflow/deferred/` at 5.9, and line coverage not measured by decision. The stakeholder approved the work at 5.5 and the verdict at 5.7.

## Open questions

None.
