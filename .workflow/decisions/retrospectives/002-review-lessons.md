---
spec: .workflow/specs/done/002-review-lessons
date: 2026-10-22
verdict: accepted-with-open-items
---

# Retrospective: Review lessons: a Phase 4 lens for retrospective lessons

## Summary

- Spec: `.workflow/specs/done/002-review-lessons/spec.md` (capabilities: CAP-002, CAP-003)
- Report: `.workflow/specs/done/002-review-lessons/report.md`
- Tasks: 6 done, 0 split-out; 6 shelf items linked (3 written by this spec: `retrospective-template-drift.md`, `harness-run-lint-target.md`, `comment-id-lint.md`; 3 existing files given a Later requests line: `session-start-timing-target.md`, `research-model-map.md`, `concurrency-check-timing.md`)
- Evidence available: `spec.md`; `verification-plan.md`; `report.md`; `tasks.md`; `design-log.md` (one triage entry, two discovered-work entries, the wave and rework entries); `proposals.md` (13 approved); `artifacts/` (toolchain output per task, nine gate and sign-off runs, four lens pass files, the live-run journey files and `record.md`); the six shelf files; git `7289fbf..a6f7854` (47 commits; 51 files, +5062/-65 outside the spec folder); the previous retrospective `004-scoped-test-runs.md`
- Evidence missing: `.workflow/review-lessons.md` did not exist before this retrospective (expected: this is the feature that creates it). Session logs: none kept; process lessons come from `design-log.md`, the artifacts and the stakeholder, who asked that the T1 review-round churn be weighed.

## Result against the spec

Judge the combined result of all tasks against `spec.md`, not task by task.

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-002 Review lessons lens: one high `RL-` finding on a repeating diff, none without; the pass file passes the triage check; graded and routed with no change to triage's verdicts or routing | yes | `artifacts/review-lessons/jrn-001.yaml` (RL-1 high, `lesson: RL-001`), `jrn-002.yaml` (`findings: []`), both checks exit 0; `artifacts/review/pass-1/review-lessons.yaml` ran beside the other three lenses on this spec; `modules/review-triage.md` step 4 unchanged in verdicts and routing |
| CAP-003 Review lessons written by the retrospective: one entry, nothing else changes; a rejected lesson writes nothing; the guard allows at 5.7 and denies elsewhere | yes (the live write happened in this retrospective, step 5 below) | `tests/scripts/check-write-tier-a.sh` 116/116 and `tests/hooks/write-guards.sh` 101/101 (JRN-004); `tests/lint/review-lessons.sh` 33/33 (JRN-006 oracle, JRN-008); `tests/scripts/review-lessons.sh` 26/26; this document's Process lessons table for the entry written |
| Constraint: same pass-file shape, ids `RL-<n>`, `category: lesson`; triage changes only by four lenses and one checker row | yes | `check-review-findings.sh` lens table (T2); `review-triage.md` (T4); `report.md` § Capabilities |
| Constraint: lens read-only, cheap tier; only the retrospective writes the file, at 5.7, creating it from the feature-workflow template | yes | `.agents/agents/review-lessons.md` (tools Read, Grep, Glob, Bash; one heredoc write of its pass file); `.workflow/model-map/review-lessons.md` (`tier: cheap`); `retrospective/modules/routing.md` § Review lessons; `check-write.sh` class `review-lessons` (5.7 only) |
| Constraint: repeated review lesson high, repeated pitfall or retrospective lesson medium | yes | `review-lessons.md` § Scoring; JRN-001 severity high |
| Constraint: file shape (`lessons:` list, five fields, `retired` and `enforced_by`), validated by the script | yes | `assets/review-lessons.md` header; `scripts/review-lessons.sh`; `tests/scripts/review-lessons.sh` |
| Constraint: step `4.9` after 4.3, Phase 4 count 9 on both paths | yes | `references/steps.tsv`; `tests/lint/step-list.sh` 36/36; `tests/scripts/step-progress.sh` 66/66 |
| Constraint: `workflow-paths.sh` through the integration agent | yes | `artifacts/integration-shell-scripts/integration.yaml` (request 1 applied, `ebd2c2b`) |
| Constraint: manifest, PROVENANCE, generated toml, frontmatter exactly `name`, `description`, `tools` | yes | `tests/lint/review-lessons.sh` asset assertions; `tests/scripts/generate-codex-agents.sh` 44/44; `tests/lint/frontmatter.sh` 40/40; targets `asset-coverage` 0 |
| Success signal: an approved lesson is one entry written at 5.7 and nowhere else; the next review runs four lenses, the fourth returning one high finding on a repeat and none otherwise | yes | this retrospective's step 5 (the entry); `artifacts/review/pass-1/` (four lens files); JRN-001 and JRN-002 |
| JRN-001 Lens finds a repeated lesson | yes, on the final lens | run 1 pass, run 2 fail on the pre-fix lens, run 3 pass (`artifacts/review-lessons/record.md`) |
| JRN-002 Lens stays silent without the repeat | yes | runs 1 and 3 |
| JRN-003 to JRN-008 (harness journeys) | yes | `artifacts/sign-off-5.4/toolchain.txt`: 45 suites, 2614 passed, 0 failed |
| Targets: script lint, harness lint, script coverage, asset coverage | yes | `artifacts/review/pass-1/review-targets.yaml` (4 pass) |
| Targets: agent-docs lint clean; guard and launch hook wall time | partly: not measured by the lens (the first runs through the harness runner, proven green by the 3.9 gates; the second has no target by the 1.1 decision) | `report.md` § Targets vs measured; `.workflow/deferred/harness-run-lint-target.md`, `session-start-timing-target.md` |
| Non-goals held (no change to the three lenses' inputs, no auto-written rules, pr-quality untouched, no invented lesson, retrieval unchanged, template drift deferred) | yes | `git diff --stat 7289fbf..a6f7854`: the three lens definitions, `pr-quality/`, `retrieval.md` untouched; the only lesson text lives in `tests/fixtures/review-lessons.sh` |

Built but not asked for: `scripts/review-lessons.sh` and its suite (the validator moved out of the template at review pass 1, F1, with the stakeholder's approval); a standalone retrospective turns an approved review lesson into an action item (T5, a consequence of the guard denying the file outside a feature's 5.7, consistent with "at 5.7 and nowhere else"); the `readable-code.md` R4 header-exemption sentence (P8).

## Behavior verification

The real `review-lessons` lens was launched from inside fixture repos (built by `tests/fixtures/review-lessons.sh` under the gitignored `.workflow/.worktrees/`, so the launch hook resolved the fixture's own spec and model map) with the exact header and one-line task review-triage uses. On the repeating diff it wrote one `RL-1` high finding at `src/report.sh:4`, confidence 85, `lesson: RL-001`; on the guarded diff it wrote `findings: []`; `check-review-findings.sh` accepted both files. Three runs of JRN-001 in all: pass (85), fail (the unchanged pre-fix lens scored the hunk about 60, weighing the lesson's consequence clause), pass (85, after the T3 fix to the definition). The lens also ran at 4.9 inside this spec's own review pass 1 beside the other three lenses, on a repo with no lessons file, and returned a clean `status: done` file. The retrospective's own write of a review lesson was exercised in step 5 of this document. Not exercised at runtime: the Codex launch form (`agent_type review_lessons`), as Codex is not installed here.

## Findings

Each finding keeps its source reference and a disposition: `fix now`, `defer` (link the `.workflow/deferred/` file), or `accept` (with the reason).

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1 validator logic lived in the template's comment, outside `scripts/` and shellcheck | review-standards RS-1; design-log triage pass 1 | accept: patched in rework 1 (`scripts/review-lessons.sh`, 26-assertion suite, `79dc40d`) | - |
| F2 journey ids in three test body comments | review-standards RS-2 | accept: patched in rework 1 (`c9813b5`); rule line P7 applied | - |
| F3 lens definition shaped like its siblings, not the agent template | review-standards RS-3 | accept: profile rule P4 applied at 5.3 says a Phase 4 lens follows the lens shape | - |
| F4 agent-docs lint target not measured (runs through the harness runner) | review-targets `not_measurable` | defer | `.workflow/deferred/harness-run-lint-target.md` |
| F5 no performance target | review-targets `not_measurable`; 1.1 decision | defer (Later requests line) | `.workflow/deferred/session-start-timing-target.md` |
| F6 retrospective's live write of a lesson unverifiable before 5.7 | review-end-state `not_verifiable` | accept: verified in step 5 of this document (one entry written, validated; see Process lessons) | - |
| F7 four lenses in a real review | review-end-state `not_verifiable` | accept: this spec's pass 1 ran four lenses (`artifacts/review/pass-1/`) | - |
| F8 hard-coded task-type and agent counts in about six files (Shotgun Surgery, under 80) | review-standards `not_checked` | accept as a finding of the codebase: becomes review lesson RL-001 below | - |
| F9 backlog items duplicated shelved items (retrospective 004's lesson not applied) | review-lessons `not_checked`, confidence 50 | accept: both items moved to the shelf at 5.9; pitfall P12 recorded; the 004 action item stays open (below) | - |
| JRN-001 run 2 miss: the lens weighed a lesson's consequence clause as a condition | 3.11, `artifacts/review-lessons/jrn-001-run2-after-rework.yaml` | accept: fixed in the definition (`7507db6`); pitfall P11 | - |
| T3 `profile-wrong`: the agent-docs lint key ran a suite pinned red by a sibling task | `artifacts/T3/implementation-wave1.yaml` | accept: profile P3 applied; pitfall P9 | - |
| Gate `gate-3.9-w1b` failed on a wall-clock assertion under load | `artifacts/gate-3.9-w1b/toolchain.txt:27-28` | defer (Later requests line) | `.workflow/deferred/concurrency-check-timing.md` |
| Stakeholder concern: six mini-review launches on T1 (two in wave 1, four in the rework), each failing round naming one new cosmetic item on lines an earlier round had passed (R4 header paths twice despite the `rules.md` exemption; `[[ ]]`; directive reasons; a reason for `2>/dev/null`) | `artifacts/T1/mini-review-r1.yaml`, `mini-review-rework-r1.yaml`, `-r2.yaml`, `-r3.yaml`, `mini-review.yaml` | accept: the grep-able items go to the P13 lint (shelved); the brief for round 4 carried the earlier rounds' verdicts and passed; recorded as process lesson PL1 and an action item | `.workflow/deferred/comment-id-lint.md` |
| Capability ids assigned as CAP-001/CAP-002 before re-reading `capabilities.md`, which already held CAP-001 | design-log "Sign-off 5.1-5.3" | accept: corrected at 5.3 (sed; `yq --front-matter=process -i` on `tasks.md`, since `set-task` rewrites only provisional ids); pitfall candidate below | - |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| discovered-work 00.26: search open items by concept before writing a work item | no | `.agents/skills/feature-workflow/modules/discovered-work.md` 00.26 still checks only the numbering; this spec repeated the failure (F9, two duplicates of shelved items) |
| review-triage step 2: skip `review-targets` on the light path and record "no targets (light path)" | yes | `.agents/skills/feature-workflow/modules/review-triage.md` § 2, "Light path: no targets lens" |
| Use a Conventional Commits subject for the 5.8 merge of spec/004 | partly | `dfa4c3e chore(workflow): sign off 004-scoped-test-runs ...` is conventional; the merge itself took GitHub's default subject `55413d0 Merge pull request #1 from TajVirani/spec/004-scoped-test-runs` |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| Mini-review churn: six launches on T1 (two in wave 1, four in the rework), each failing round naming one new cosmetic item on lines an earlier round had passed; the grep-able items (ids and paths in body comments, single-bracket tests) belong to a lint, and a later round should carry the earlier rounds' verdicts so it re-judges changed lines and must justify failing an unchanged one (the round-4 brief did, and passed) | tool rule (mechanical) and skill change | proposals.md P13 (approved) and `.workflow/deferred/comment-id-lint.md`; the 3.7 brief change is an action item |
| Re-read `capabilities.md` in the same step as assigning ids; batching the read with the assignment gave this spec ids CAP-001 and CAP-002 while CAP-001 existed | checklist line (judgement), orchestrator practice | not recorded beyond this document and the pitfall: the module already states the rule |
| Main moved between this spec's 0.6 and 1.1 (the lens contract moved from an inline yq check to pass files and `check-review-findings.sh`); the handoff carried the old main sha and the drift was found only by reading the module at 1.1. The handoff Resume, or 1.1, should diff the affected area since the handoff's sha | skill change | action item |
| Write a review lesson's symptom with the mistake first and its consequence after "so": the fixture lesson's consequence clause ("a confusing error far from the call") is what the lens argued against on JRN-001 run 2 | skill change (template header note) | action item |
| Carried from 004: write a work item only after checking the shelf and the open backlog by concept; this spec repeated the failure (F9) | skill change | action item (still open from 004) |
| A change that adds a task type or agent leaves hard-coded counts and lists stale in up to six files (F8; spec 001 missed `research` in project-setup's tier table) | review lesson | `.workflow/review-lessons.md RL-001` |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| Capability ids assigned before re-reading `capabilities.md` (CAP-001 taken) | sign-off 5.3 | none yet | added |
| An agent-docs task's lint key ran a suite pinned red by a sibling task (T3 `profile-wrong`) | agent-docs profile `lint` | P3 (applied 5.3) | already present (P9) |
| A 3.9 gate overlapped an agent's full-harness run; the runner's wall-clock assertion failed | gate `gate-3.9-w1b` | one harness at a time; assertion shelved | already present (P10) |
| The lens weighed a lesson's consequence clause as a matching condition (JRN-001 run 2) | `.agents/agents/review-lessons.md` | the T3 fix | already present (P11) |
| Backlog items written without a shelf check duplicated shelved items (F9) | discovered-work 00.26 | none yet | already present (P12) |

## Feature notes

- The cheap-tier lens's judgement is a sample (pass, fail, pass on JRN-001); a later feature could run each live journey twice or adopt an n-of-m rule (design-log.md, 2026-10-22 Retrospective notes)
- The live-run technique: build the fixture under the gitignored `.workflow/.worktrees/` and move the shell into it, so the launch hook resolves the fixture's spec and model map (design-log.md, 2026-10-22 Retrospective notes)
- This repo now carries `.workflow/model-map/review-lessons.md` and `.workflow/review-lessons.md` with RL-001 (design-log.md, 2026-10-22 Retrospective notes)

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| review-lessons | claude (haiku) | JRN-001 pass, fail, pass on an unchanged definition before the fix (`artifacts/review-lessons/jrn-001-run2-after-rework.yaml`); run 3 appended notes after the summary block and left a scratch file in the temp dir | none | .workflow/model-map/review-lessons.md |
| profile-mini-review | claude (cheap tier) | six rounds on T1 with inconsistent verdicts across rounds, two failures on header lines `rules.md` exempts (`artifacts/T1/mini-review-r1.yaml`, `mini-review-rework-r{1,2,3}.yaml`); the round whose brief carried the earlier verdicts passed | none | .workflow/model-map/profile-mini-review.md |
| implementation | claude (opus) | six tasks done; every rework and fix round converged in one launch; T3 returned `profile-wrong` correctly (`artifacts/T3/implementation-wave1.yaml`) | none | .workflow/model-map/implementation.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| Mini-review brief (implementation-orchestrator 3.7, or the profile-mini-review definition): carry the earlier rounds' verdicts so a later round re-judges changed lines and must justify failing an unchanged one | scaffold maintainer | yes |
| The lint suite for ids and paths in shell comments and single-bracket tests (P13, `.workflow/deferred/comment-id-lint.md`) | scaffold maintainer (test-harness work in a next feature) | yes |
| handoff Resume or verification-setup 1.1: when main moved since the handoff's sha, diff the affected area before 1.1 and record the drift | scaffold maintainer | yes |
| `.agents/skills/feature-workflow/assets/review-lessons.md` header: a symptom leads with the mistake, the consequence follows "so" | scaffold maintainer | yes |
| discovered-work 00.26: check the deferred shelf and the open backlog by concept before writing a work item (carried from retrospective 004) | scaffold maintainer | yes |

## Acceptance verdict

`accepted-with-open-items`. Every spec item is met with evidence (Result against the spec): six tasks `done`, the full harness green at `a6f7854` (45 suites, 2614 assertions), both live journeys pass on the final lens, four lenses ran on this spec's own review, and the retrospective wrote RL-001 to `.workflow/review-lessons.md` through the documented procedure (CAP-003's live half). Open items, all tracked: two unmeasured targets (`harness-run-lint-target.md`, `session-start-timing-target.md`), the comment-id lint (`comment-id-lint.md`), the retrospective template drift, and the five action items above. No blocking finding is open. The stakeholder approved the work at 5.5; the machine verdict and the stakeholder's agree.

## Open questions

None.
