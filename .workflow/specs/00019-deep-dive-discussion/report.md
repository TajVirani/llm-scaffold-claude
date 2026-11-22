# Report: Hold the deep dive at once, as a discussion that reaches agreement

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `55d8ecf2a7bf44d466fa19d52fc1229ab1647da7` · Head: `52fb6f17dfcf3c1479e382380188b721d9cfb8cb`

## Summary

The questioning loop now holds a deep dive straight after the round is logged, as a discussion that ends on the stakeholder's yes to a written agreed statement, then checks the round's other answers against it; large-path 6.5 does the same, and the retrospective counts deep dive exchanges as waits. Every journey check passes and the whole harness is green (4909 passed, 0 failed). The most important gap: no check can show an agent actually holding the discussion in a live round; the next real round that picks a deep dive is the first.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-017 Deep dive held at once, ending in an agreed statement | PASS | [E1], [E2], [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 4909 passed, 0 failed, 81 suites; exit 0 | [E1] |
| CI | none | not applicable: the repo has no CI | none |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean | [artifacts/T1/](artifacts/T1/) |
| T2 | clean | [artifacts/T2/](artifacts/T2/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| New-feature start load | at most 45,000 bytes | 41392 bytes | PASS | `bash tests/lint/workflow-load-size.sh \| grep '^new-feature start:'` | [E4] |
| Questioning loop size | at most 15,000 bytes | 13980 bytes | PASS | `wc -c < .agents/skills/feature-workflow/modules/questioning-loop.md` | [E4] |
| Errors | none set | not measured: a step-file text change; wording and order are journeys | not measured | none | [E4] |
| Coverage | none set | not measured: no bash line-coverage tool is installed | not measured | none | [E4] |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Deep dive held at once | PASS | "00019 JRN-001" checks in `tests/lint/stakeholder-asks-docs.sh`, [E1]; red at baseline [E3] |
| JRN-002 Unfinished deep dive resumed | PASS | "00019 JRN-002" checks, [E1]; red at baseline [E3] |
| JRN-003 One label everywhere | PASS | "00019 JRN-003" checks, [E1]; red at baseline [E3] |
| JRN-004 Entry shapes carry the agreement | PASS | "00019 JRN-004" checks, [E1]; red at baseline [E3] |
| JRN-005 Large path behaves the same | PASS | "00019 JRN-005" checks, [E1]; red at baseline [E3] |
| JRN-006 Waits count includes exchanges | PASS | "00019 JRN-006" in `tests/scripts/retrospective-evidence.sh`, [E1]; red at baseline [E3] |
| JRN-007 Step list and totals hold | PASS | `lint/step-list`, `scripts/step-progress` in [E1] |

Behaviour verification: runtime behaviour was not exercised: the change is step-file text an agent reads; the harness checks the text, not an agent following it in a live round.

## Review outcome

- Review passes: 1 (rework ceiling 5; rework used 0) · Findings: 1 patched (F1, lineage wording, 201c795), 0 left open as known gaps, 0 dismissed (see design-log.md "Triage, review pass 1"); failed lenses: none
- Follow-up review recommended: no; the one finding was low and wording only
- Size budget: 2 of 10 tasks, 11 of 30 changed files (budget-check.sh at 5.4) · within

## Known gaps

- Gate skipped (3.10 browser suite): this repo has no browser suite; every journey is a harness check. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
- Live-round behaviour of the new 0.3.12–0.3.13 and 6.5 text (review-end-state, not verifiable): settled by the next real round that picks a deep dive.
- Scaffold-only planning files `assetlist.md:339,343` and `wayfinder-comparison.html:237` still describe the old defer option (review-standards, not checked): no rule says they track behaviour.
- A large-path session cut off mid deep dive leaves the round's other answers open, so the next round asks them again (accepted in the 2026-11-22 Assumed entry).
- Errors and coverage targets not measured (see Targets).

## Deferred

- [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md): no browser suite in this repo; a Later requests line was added at 3.14.

## How to verify

1. Run `tests/run-all.sh --suite lint/stakeholder-asks-docs --suite scripts/retrospective-evidence --suite lint/step-list --suite scripts/step-progress`.
2. Every suite passes; the 23 checks named "00019 JRN-00n" are among them. Then read `.agents/skills/feature-workflow/modules/questioning-loop.md` § The round, item 6.

## Evidence

- [E1] `artifacts/wording-p1/toolchain.txt`: `TOTAL passed=4909 failed=0 skipped=0 xfail=0 (81 suites)` (reused at 5.4 by `artifacts/sign-off-5.4/toolchain.json`, `reused_from: wording-p1`); also `artifacts/gate-3.9-w1/toolchain.txt`.
- [E2] `artifacts/T1/mini-review.yaml`, `artifacts/T2/mini-review.yaml`: verdict pass; `artifacts/review/pass-1/review-end-state.yaml`: 0 findings, 16 checked.
- [E3] `artifacts/phase-1-known-bad/record.md`: the 23 new checks failed on assertions at the baseline (passed=4886 failed=23).
- [E4] `artifacts/review/pass-1/review-targets.yaml` § measurements.
