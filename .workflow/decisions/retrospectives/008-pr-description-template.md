---
spec: .workflow/specs/008-pr-description-template
date: 2026-10-30
verdict: accepted-with-open-items
---

# Retrospective: PR description template

## Summary

- Spec: `.workflow/specs/008-pr-description-template/spec.md` (capabilities: CAP-006)
- Report: `.workflow/specs/008-pr-description-template/report.md`
- Tasks: 6 done (T1-T6), 0 split out; 3 scope items shelved at 0.3.17 (`spec-issue-creation.md`, `workflow-settings-home.md`, `initiative-pr-template.md` in `.workflow/deferred/`)
- Evidence available: `spec.md`, `verification-plan.md`, `report.md`, `tasks.md`, `design-log.md` (two triage entries, decisions D1-D20, sign-off entries), `proposals.md` (P1-P6 approved), `artifacts/` (T1-T6 toolchain and mini-review files, gates 3.9 w1-w3 and rework 1, review cycle 1 and cycle 2 pass files, `sign-off-5.4/`, both Phase 1 harness runs), `.workflow/review-lessons.md`, retrospective 005, git `a36d149..1fa3a87` (47 commits, 147 files, +5869 -74, most of it workflow data and artifacts)
- Evidence missing: session logs (process lessons come from `design-log.md` and the stakeholder only). The 5.8 half of JRN-007 runs after this retrospective, at the merge.

Going-in concerns: none (design-log.md, Sign-off: stakeholder approval (5.5)).

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-006 intent: sign-off fills the template from evidence, the stakeholder approves the text, 5.8 publishes it | yes | `modules/sign-off.md` 5.4, 5.5, 5.8; this spec's own `pr-body.md` approved at 5.5 (design-log Sign-off entry) |
| CAP-006 success: ten sections in order, check passes, PR opened with the file; bad shapes fail | yes (5.8 at the merge) | report.md Journeys JRN-001, JRN-002, JRN-005; `artifacts/sign-off-5.4/check-pr-body.txt` exit 0 |
| Constraint: no new dependencies | yes | `check-pr-body.sh` header ("needs only awk, grep and sed"); no manifest or tool added (git diff stat) |
| Constraint: body through a file, never `gh --template` with a body flag | yes | TGT-004 measured 0 (report.md Targets) |
| Constraint: `pr_template` in Workflow settings, changed only through Tier A steps | yes | `rules-setting.sh` key; `project-setup/modules/files.md` PR template; sign-off 5.2 row |
| Constraint: sections filled from evidence, not claims | partly | guidance and 5.4 only; `check-pr-body.sh` checks shape (report.md Known gaps); this spec's body was filled from report.md, design-log.md, codebase-map.md and budget-check.sh |
| Non-goals (issue creation, settings home, REVIEW.md, task PR bodies, initiative PR, review reading the template) | yes, none built | three shelf files in spec.md `deferred`; `open-task-pr.sh` and `assets/report.md` unchanged (pr-body.md Blast radius) |
| Success signal: the next spec to sign off shows the filled template at 5.5 and publishes exactly that text | partly (this spec is that spec; 5.5 done, 5.8 at the merge) | design-log Sign-off entry; the 5.8 local merge uses `-F` with `--cleanup=verbatim` |
| JRN-001 to JRN-006 | yes | report.md Journeys: `check-pr-body` 47/47, `task-breakdown` 132/132, `sign-off-pr` 30/30 |
| JRN-007 this spec signs off with its own template | partly (5.4 pass; 5.8 at the merge) | `artifacts/sign-off-5.4/check-pr-body.txt` |
| TGT-001 to TGT-007 | yes | report.md Targets vs measured; `artifacts/review/pass-1/targets/` |
| TGT-008 line coverage | not measured (stakeholder decision, 1.1) | report.md Targets vs measured |

Built but not asked for: a separate 5.5 PR-description approval (D18) and the 5.4 stop-and-ask on an unusable host template (D20). Both were decided with the stakeholder mid-build, so they are in the design log, not in the spec's capability text.

## Behavior verification

The harness runs the real `check-pr-body.sh`, `rules-setting.sh` and the 5.8 publish block (extracted from `modules/sign-off.md`) against fixture repos, with recording stand-ins for `gh` and `glab` (report.md Journeys). At this spec's own 5.4 the real check passed on the filled `pr-body.md` on its first run. A live `gh pr create --body-file` was not exercised: `gh` is not installed here and origin is a local path.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| `gh pr create --body-file` never run against a live `gh` | report.md Known gaps; review-end-state `not_verifiable` | accept: `gh` is not installed; the flag is cited from the gh manual at 0.2.5; the first GitHub project's 5.8 exercises it | - |
| The 5.8 local merge leaves its message temp file in `$TMPDIR` when the switch or merge fails | design-log 3.8 T4 | accept: only a stray temp file; the merge result and the approved body are unaffected | - |
| Line coverage of changed shell code not measured | TGT-008 | accept: stakeholder decision at 1.1 (no tool, no new dependencies) | - |
| Drift between the 5.5 approval and 5.8 not detected | D17 | accept: stakeholder decision | - |
| `check-pr-body.sh` checks shape, not truth | review-end-state `not_verifiable` | accept: by design; the constraint rests on template guidance and 5.4 | - |
| Asset-template guidance comments can name scaffold-only `.workflow/` paths | T6 mini-review R4; F1 | defer | [.workflow/deferred/comment-id-lint.md](../../deferred/comment-id-lint.md) |

Review findings F1-F9 are closed: 7 patched, F3 and F6 applied at 5.3 as P1 and P2 (design-log triage entries; proposals.md).

## Previous-retrospective follow-through

Retrospective 005 recorded no action items (`005-cache-build-followups.md`, Action items: "None."). Nothing to follow through.

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| A spec line about a user-supplied file ("that template's headings") left the accepted forms open; review found it (F4) and it cost a loop back to 0.3.8 | checklist line (judgement) | action item 1 |
| The 1.2 harness launches with `isolation: "worktree"` left their result files in the worktree twice; the third run, in a worktree under `.workflow/.worktrees/`, wrote in place | skill change | action item 2; `.workflow/decisions/pitfalls.md` (Fork a Phase 1 build's worktree, recurred) |
| A script behaviour change left module prose stating the old contract (F7, F8) | review lesson | `.workflow/review-lessons.md RL-003` |
| A shipped asset named a `.workflow/deferred/` file only this repo holds (F1, T6 R4) | review lesson | `.workflow/review-lessons.md RL-004` |
| Went well: the separate PR-description approval and the check script worked on this spec's own sign-off; the body passed on its first fill | process lesson | this document only |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| Shipped template cited a scaffold-only `.workflow/deferred/` path (F1); the fix round repeated it in guidance (T6 R4) | `.agents/skills/*/assets/` | none yet (shelved lint `comment-id-lint.md`) | already present (applied at 5.3, P4) |
| Module prose kept the old `##`-only contract after D19 (F7, F8) | `modules/sign-off.md` 5.4 | none yet; RL-003 now guides review | already present (applied at 5.3, P5) |
| Phase 1 result files stayed in the `isolation: "worktree"` worktree twice | verification-setup 1.2 | none yet | already present (recurrence added at 5.3, P6) |

## Feature notes

- CAP-006 was assigned in this clone while spec 006 is in flight in its own clone; 006's 5.3 must read `capabilities.md` from a main that already holds 008, or both claim CAP-006 (design-log.md, 2026-10-30 Retrospective notes section)
- No task PRs were opened (origin is a local path); this spec's 5.8 is a local merge carrying `pr-body.md` (design-log.md, 2026-10-30 Retrospective notes section)

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| implementation | claude | T4 built beyond its task file (hash check, separate approval; D17 removed one, D18 kept the other); T2 resumed once for tests; T1 one behaviour fix round | none | .workflow/model-map/implementation.md |
| profile-mini-review | claude | Caught real faults on T1, T2, T6; asked for `[ ]` against retrospective 002 (F5); a false `tree` mismatch again at T6 | none | .workflow/model-map/profile-mini-review.md |
| review-targets | claude | Cycle 1 reported TGT-003 (a lint command) as not_measurable; cycle 2 measured all seven | none | .workflow/model-map/review-targets.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| 1. Questioning loop or verification setup (0.5): for each input the feature parses from a user's file, pin its accepted forms with a fixture before 0.6 | scaffold maintainer, via a spec on feature-workflow | yes |
| 2. Verification setup 1.2: launch the Phase 1 build in a wave-start-style worktree under `.workflow/.worktrees/` instead of `isolation: "worktree"` | scaffold maintainer, via a spec on feature-workflow | yes |

## Acceptance verdict

`accepted-with-open-items`. Every capability, constraint and journey is met or met in part with evidence; all six tasks are `done`; no blocking finding is open. The open items are the accepted gaps above (live `gh`, the temp file, TGT-008, D17, shape-only checks), the deferred lint, and the 5.8 half of JRN-007, which runs at the merge. The stakeholder answered the candidate round with "No preference", so the recommended candidates and verdict were applied as presented.

## Open questions

None.
