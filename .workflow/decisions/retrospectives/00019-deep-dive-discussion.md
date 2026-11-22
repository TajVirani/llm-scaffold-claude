---
spec: .workflow/specs/00019-deep-dive-discussion
date: 2026-11-22
verdict: accepted-with-open-items
---

# Retrospective: Hold the deep dive at once, as a discussion that reaches agreement

## Summary

- Spec: `.workflow/specs/00019-deep-dive-discussion/spec.md` (capabilities: CAP-017)
- Report: `.workflow/specs/00019-deep-dive-discussion/report.md`
- Tasks: 2 done, 0 split out
- Evidence available: spec.md, verification-plan.md, report.md, tasks.md, design-log.md (triage pass 1, Sign-off entry), proposals.md, artifacts/ (phase-1-test-harness, phase-1-known-bad, T1, T2, gate-3.9-w1, wording-p1, sign-off-5.4, review/pass-1), git `55d8ecf^..52fb6f1` (14 commits), `.workflow/review-lessons.md`, previous retrospective 00017
- Evidence missing: session logs (not read); no work-backlog list for this spec (none was written); browser evidence (no browser suite in this repo)

## Measurements

| Measure | Value |
| --- | --- |
| Elapsed | first log entry 2026-11-21; first commit 2026-11-21T23:45:42-05:00, last 2026-11-22T00:32:22-05:00; span 0 h 47 min (Phase 0 ran before the first commit: not recorded) |
| Waits | 11 answers recorded plus 0 deep dive exchanges at 5.5 draft time; minutes: not recorded |
| Agent launches | implementation 3 (Phase 1 build, T1, T2), mini-review 2, integration 0, review lenses 3; discovery: not recorded (retrieval, module-audit and the Phase 0 skills left no file) |
| Harness runs | 4 run (4 pass, 0 fail), 4 reused |
| Findings by class | triage: 0 high, 0 medium, 1 low, 0 false, 0 unproven; routes: 1 patch, 0 decision needed, 0 discovered work, 0 proposal, 0 none; mini-review fails 0 |

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-017: deep dive held at once, ending in an agreed statement, round checked | yes | report.md § Capabilities; "00019 JRN-001" to "JRN-006" pass; review-end-state 0 findings |
| Constraint: the round still goes out as one ask | yes | `questioning-loop.md` 0.3.11 unchanged in shape; review-end-state checked 16 items, 0 findings |
| Constraint: 0.3.12 and 0.3.13 keep their ids, row count unchanged, no large-path step moves | yes | `lint/step-list`, `scripts/step-progress` pass (JRN-007) |
| Constraint: design log stays append only | yes | Deep dive shape and D6 wording ("superseded by a new decision"); review-end-state |
| Constraint: facts a deep dive needs are looked up, never asked | yes | "00019 JRN-001" item text; T1 mini-review pass |
| Constraint: ADR-0004 load budget | yes | report.md § Targets: 41392 of 45000 bytes |
| Success signal: in the same sitting, restate, talk through, yes to a written statement, re-ask only contradicted answers | partly | the text says it (JRN-001); no live round exercised it (report.md § Known gaps) |
| JRN-001 to JRN-007 | yes | report.md § Journeys; red at baseline in `artifacts/phase-1-known-bad/record.md` |
| Target: new-feature start load ≤ 45,000 bytes | yes | 41392 bytes (review-targets) |
| Target: questioning loop ≤ 15,000 bytes | yes | 13980 bytes (review-targets) |
| Target: errors, coverage | no number | not measurable by design (verification-plan.md § Targets) |

Built but not asked for: the Waits row of `.agents/skills/retrospective/assets/retrospective.md` (T2, outside its predicted file; the task's acceptance criterion needed it); `upstream-lineage.json` wording (F1 patch).

## Behavior verification

Runtime behaviour was not exercised: the change is step-file text an agent reads. The harness checks the text (23 checks, red at baseline, green at HEAD); no live questioning round picked a deep dive under the new text.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1: lineage entry still described the old defer option | review-standards RS-1, `upstream-lineage.json:1450,1453` | accept: patched in 201c795 | - |
| Live-round behaviour of the new text is unverified | review-end-state not_verifiable | accept: only a real round can show it; watch the next one that picks a deep dive | - |
| Planning files still describe the old defer option | review-standards not_checked, `assetlist.md:339,343`, `wayfinder-comparison.html:237` | accept: no rule says scaffold-only planning files track behaviour | - |
| A large-path session cut off mid deep dive leaves the round's other answers open | T1 result; design-log Assumed entry 2026-11-22, kept at 5.5 | accept: the price of keeping `initiative-transition.sh`'s settle-once rule | - |
| No browser suite | spec.md § Known gaps | kept | [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md) |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| Confirm in a desktop session worktree that the offer lists the spec's handoff and EnterWorktree moves into the spec worktree | no evidence found | no record in this spec's files; this session entered its spec worktree with EnterWorktree from the main checkout, with no handoff offered |
| Prevent the late test-harness lint: brief implementers to run it when a task changes `tests/`, or lint changed files by owning profile | no evidence found | this spec's tasks changed no `tests/` file; the Phase 1 build ran under `test-harness` and its lint passed (`artifacts/phase-1-test-harness/toolchain.json`), which neither proves nor disproves the fix |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| L1: `spec-worktree.sh create` (through `commit-workflow-data.sh`) commits the whole workflow root, so another draft spec's uncommitted glossary terms (00018's two, written at its 0.2.3) rode onto this spec's first commit and left the main checkout (D8). A draft spec's Tier A writes belong to whichever spec reaches 1.1 first. | tool rule (mechanical) | Action items (approved at 5.5) |
| L2: the module audit launched beside round 1 returned six gaps after the round was sent, so the round's Last round summary had to be withdrawn and assumptions taken afterwards. When the footprint is already plainly full path, the summary question should wait for the audit's return. | checklist line (judgement) | Action items (approved at 5.5) |

## Pitfalls

None. No gate failed, no finding was graded high or medium, and no task returned `profile-wrong`.

## Feature notes

- L3: watch the first real questioning round that picks "Talk it through (deep dive)": it is the only check that an agent holds the discussion as the text says (design-log.md, 2026-11-22 Retrospective notes section)

## Model observations

| Task type | Host | Observation | Alias change |
| --- | --- | --- | --- |
| implementation | claude | L4: T1 found that `initiative-transition.sh` settles a question once, chose a sound alternative order for large-path 6.5 instead of changing the script, and reported the trade-off plainly (`artifacts/T1/implementation.yaml`); one launch, no fix round, mini-review pass. Recorded in `.workflow/model-map.yaml` implementation observations. | none |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| L1: have `commit-workflow-data.sh` (and so `spec-worktree.sh create`) leave out, or warn about, uncommitted glossary hunks that another in-flight spec's design log names, so one spec's first commit does not carry another's Tier A writes | scaffold maintainer | yes |
| L2: add a line to `questioning-loop.md` 0.3.19 "Last round": do not add the summary question to a round while a module audit launched beside it is still out | scaffold maintainer | yes |

## Acceptance verdict

`accepted-with-open-items`. The stakeholder approved the work at 5.5 ("Approve both (Recommended)"), matching the machine verdict. Every spec item is met in the text and both tasks are `done`; the open items are the known gaps (no live-round check of the new text, no browser suite, the large-path cut-off trade-off, the planning files) and the unmeasured errors and coverage targets.

## Open questions

None.
