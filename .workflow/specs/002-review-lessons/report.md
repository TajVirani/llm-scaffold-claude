# Report: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `7289fbf78919ba022f59aa336370e2fca50806bf` · Head: `7a71bf00f7dba980ef78c4b29549793eb4fcb21b` (code; the sign-off writes are committed on top at 5.8)

## Summary

The Phase 4 review now runs a fourth lens, `review-lessons`, at step 4.9: it reads the project's review lessons, pitfalls and retrospectives and files findings in the same pass-file shape as the other lenses, and the retrospective can record an approved lesson in `.workflow/review-lessons.md` at 5.7 and retire it in place. Six tasks merged, the full harness passes (45 suites, 2614 assertions), both live journeys pass against the final lens, and one review pass produced two patches, now merged. The most important gap: the retrospective's own live write of a lesson is exercised only at this spec's 5.7, and the cheap-tier lens's judgement is a sample (three live runs of JRN-001: pass, fail, pass; the failing reasoning was removed by a fix to the definition).

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-002 Review lessons lens | PASS | [E1] [E2] [E3] [E4] |
| CAP-003 Review lessons written by the retrospective | PASS in the harness (guard, template, validator, procedure oracle); the live write of an approved lesson runs at this spec's 5.7 (gap F6) | [E5] [E6] [E7] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 2614 passed, 0 failed, 45 suites; exit 0 (`TOTAL passed=2614 failed=0 skipped=0 xfail=0 (45 suites)`) | [E8] |
| CI | none: the project has no CI; the run by hand is the whole gate | not applicable | [E8] |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (lint pass, test pass) | [artifacts/T1/](artifacts/T1/) |
| T2 | clean | [artifacts/T2/](artifacts/T2/) |
| T3 | clean | [artifacts/T3/](artifacts/T3/) |
| T4 | clean | [artifacts/T4/](artifacts/T4/) |
| T5 | clean | [artifacts/T5/](artifacts/T5/) |
| T6 | clean | [artifacts/T6/](artifacts/T6/) |
| integration-shell-scripts | clean | [artifacts/integration-shell-scripts/](artifacts/integration-shell-scripts/) |
| phase-1-test-harness | clean (lint; test skipped by design at 1.2) | [artifacts/phase-1-test-harness/](artifacts/phase-1-test-harness/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| Script lint clean | exit 0; 0 shellcheck findings | 0 findings (no output), exit 0 | PASS | `script-lint` (verification-plan.md) | [E9] |
| Harness lint clean | exit 0; 0 shellcheck findings | 0 findings (no output), exit 0 | PASS | `harness-lint` | [E9] |
| Agent-docs lint clean, Phase 4 counted as 9 | exit 0; the four lint suites report 0 failed | not measured: the command runs through `tests/run-all.sh`, which the targets lens treats as the harness; the four suites ran green inside the 3.9 gates [E8] | not measured | `agent-docs-lint` | [E9] |
| Every script this spec adds or changes has a suite | `0` printed | 0 | PASS | `script-coverage` | [E9] |
| Every new `.agents/` asset is in the manifest (agents) and `PROVENANCE.md` (all) | `0` printed | 0 | PASS | `asset-coverage` | [E9] |
| Guard and launch hook wall time | none | not measured: no performance target, stakeholder decision at 1.1 | not measured | none | [E9] |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Lens finds a repeated lesson | PASS (live run 3 against the final lens; run 1 pass, run 2 fail on the pre-fix lens) | [artifacts/review-lessons/](artifacts/review-lessons/) `jrn-001.yaml`, `jrn-001.check.txt`, `record.md` |
| JRN-002 Lens stays silent without the repeat | PASS (live runs 1 and 3) | [artifacts/review-lessons/](artifacts/review-lessons/) `jrn-002.yaml`, `jrn-002.check.txt` |
| JRN-003 Canned lens pass file passes the triage check | PASS | `tests/scripts/check-review-findings.sh` in [E8] |
| JRN-004 Guard allows at 5.7 and denies elsewhere | PASS | `tests/scripts/check-write-tier-a.sh`, `tests/hooks/write-guards.sh` in [E8] |
| JRN-005 Launch accepted with the header, refused without a model | PASS | `tests/hooks/pre-launch.sh` in [E8] |
| JRN-006 Retrospective procedure writes one entry and nothing else | PASS for the oracle half (`validate` and `next-id` on appended and retired entries); the agent's judgement runs live at 5.7 | `tests/lint/review-lessons.sh`, `tests/scripts/review-lessons.sh` in [E8] |
| JRN-007 Progress line counts the new step fourth | PASS | `tests/scripts/step-progress.sh`, `tests/lint/step-list.sh` in [E8] |
| JRN-008 Template and project-setup row | PASS | `tests/lint/review-lessons.sh` in [E8] |

Behaviour verification: the real `review-lessons` lens was launched from inside two fixture repos built by `tests/fixtures/review-lessons.sh` (one recorded lesson, a spec with `baseline_revision`, one commit adding `src/report.sh`), with the exact header and one-line task triage uses; it wrote its pass file, which `check-review-findings.sh` accepted, with one `RL-1` high finding (`lesson: RL-001`, `src/report.sh:4`) on the repeating diff and none on the guarded diff [E1] [E2]. The same lens ran at 4.9 on this repo's own change inside review pass 1 beside the other three lenses [E3].

## Review outcome

- Review passes: 1 (rework ceiling 5; rework used 1) · Findings: 2 patched (F1 logic moved into `scripts/review-lessons.sh`; F2 journey ids out of body comments), 1 deferred as a proposal (F3, P4 applied at 5.3), 2 gap handoffs (F4, F5), 1 gap verified at 5.7 (F6), 1 resolved by the pass itself (F7), 1 dismissed (F8, pre-existing, low if true), 1 recorded for 5.9 and the retrospective (F9) (see design-log.md "Triage, review pass 1")
- A 3.11 fix round on T3 after the rework (JRN-001 run 2 failed): the lens definition now matches a lesson on the mistake its symptom names, not its consequence clause
- Follow-up review recommended: no. No patch was a verified high; the T3 fix is a prose change to one agent definition, reviewed at 3.7

## Known gaps

- F6: the retrospective's judgement writing a real approved review lesson is exercised only at this spec's 5.7; the harness proves the guard, the template and the validator. Closed by the 5.7 record in the retrospective.
- Target "Agent-docs lint clean": not measured by the targets lens (its command runs through the harness runner); the suites ran green in the 3.9 gates. Handoff: [.workflow/deferred/harness-run-lint-target.md](../../deferred/harness-run-lint-target.md)
- Target "Guard and launch hook wall time": no target by the 1.1 decision. Handoff: [.workflow/deferred/session-start-timing-target.md](../../deferred/session-start-timing-target.md) (Later requests)
- Lens judgement at the cheap tier is a sample: JRN-001 passed twice and failed once on the unchanged pre-fix definition; the reasoning behind the miss is removed, not the variance.
- Not checked by the lenses: typecheck, format and boundary keys have no command in this project; `.workflow/review-lessons.md` does not exist here until a 5.7 writes it; this repo has no retrospectives folder yet.

## Deferred

- [.workflow/deferred/retrospective-template-drift.md](../../deferred/retrospective-template-drift.md): two stale notes in the retrospective template (0.3.17 scope decision)
- [.workflow/deferred/harness-run-lint-target.md](../../deferred/harness-run-lint-target.md): lint targets that run through the harness runner (4.8 gap)
- [.workflow/deferred/session-start-timing-target.md](../../deferred/session-start-timing-target.md): no performance target (4.8 gap, Later requests line)
- [.workflow/deferred/comment-id-lint.md](../../deferred/comment-id-lint.md): the lint suite for ids and paths in shell comments (5.3 approved tool rule P13)

## How to verify

1. `tests/run-all.sh`: expect `TOTAL passed=2614 failed=0 skipped=0 xfail=0 (45 suites)`.
2. `bash tests/lint/review-lessons.sh` and `bash tests/scripts/review-lessons.sh`: 33/33 and 26/26.
3. `.agents/skills/feature-workflow/scripts/check-review-findings.sh .workflow/specs/002-review-lessons/artifacts/review/pass-1/review-lessons.yaml`: exit 0, four lenses ran on this spec.
4. Build a fixture and launch the lens: `bash -c 'source tests/lib/common.sh; source tests/fixtures/review-lessons.sh; review_lessons_repo "$1" repeat' _ <dir>`, then from `<dir>` launch `review-lessons` with the header `spec_dir: .workflow/specs/001-fixture` and the one-line task; expect one `RL-1` high finding at `src/report.sh:4`.

## Evidence

- [E1] [artifacts/review-lessons/jrn-001.yaml](artifacts/review-lessons/jrn-001.yaml) and [jrn-001.check.txt](artifacts/review-lessons/jrn-001.check.txt): one `RL-1` high, confidence 85, `lesson: RL-001`, check exit 0; runs 1 and 2 beside them; narrative in [record.md](artifacts/review-lessons/record.md)
- [E2] [artifacts/review-lessons/jrn-002.yaml](artifacts/review-lessons/jrn-002.yaml) and [jrn-002.check.txt](artifacts/review-lessons/jrn-002.check.txt): `findings: []`, check exit 0
- [E3] [artifacts/review/pass-1/review-lessons.yaml](artifacts/review/pass-1/review-lessons.yaml): the lens's own pass on this spec, `status: done`, check exit 0
- [E4] `tests/hooks/pre-launch.sh` (JRN-005) and `tests/scripts/resolve-launch.sh` in [E8]: the launch row and model resolution
- [E5] `tests/scripts/check-write-tier-a.sh` (116) and `tests/hooks/write-guards.sh` (101) in [E8]: the 5.7-only guard
- [E6] `tests/lint/review-lessons.sh` (33) in [E8]: template, `validate`/`next-id` oracle, project-setup row, asset set
- [E7] `tests/scripts/review-lessons.sh` (26) in [E8]: the validator script's contract
- [E8] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt): `TOTAL passed=2614 failed=0 skipped=0 xfail=0 (45 suites)`, every suite `PASS`; same result in [artifacts/gate-3.9-fix-t3/](artifacts/gate-3.9-fix-t3/)
- [E9] [artifacts/review/pass-1/review-targets.yaml](artifacts/review/pass-1/review-targets.yaml) (`measurements`) and the raw outputs under [artifacts/review/pass-1/targets/](artifacts/review/pass-1/targets/)
