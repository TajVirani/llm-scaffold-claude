# Report: Slim the workflow context

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `a29eca7c475544a99ccc9d986cde87e02f4f140d` · Head: `4b7c9a7`

## Summary

Feature-workflow is now a router, two reference files (`references/conventions.md`, `references/launching.md`) and one step file per stage, and the output style reads a term list in place of the whole glossary. A new-feature start loads 44,733 bytes (was about 81,000) and an implementation resume 54,360 (was about 85,000), both under their limits, and the full suite passes. The most important gap: no live session has run the new router yet, and the start load has only 267 bytes to spare.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-012 Lean workflow load | PASS | [E1] [E2] [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9, 5.4) | `tests/run-all.sh` | `TOTAL passed=4458 failed=0 skipped=0 xfail=0 (75 suites)`; exit 0 | [E1] |
| CI | none: this repo has no CI; `tests/run-all.sh` run by hand is the gate | not applicable | — |

Tool audit (3.5) per task (the rework round for T1, T4, T9, T10):

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean | [artifacts/T1/](artifacts/T1/) |
| T2 | clean | [artifacts/T2/](artifacts/T2/) |
| T3 | clean | [artifacts/T3/](artifacts/T3/) |
| T4 | clean | [artifacts/T4/](artifacts/T4/) |
| T5 | clean | [artifacts/T5/](artifacts/T5/) |
| T6 | clean | [artifacts/T6/](artifacts/T6/) |
| T7 | clean | [artifacts/T7/](artifacts/T7/) |
| T8 | clean | [artifacts/T8/](artifacts/T8/) |
| T9 | clean | [artifacts/T9/](artifacts/T9/) |
| T10 | clean | [artifacts/T10/](artifacts/T10/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| New-feature start load | <= 45000 bytes | 44733 bytes | PASS | `bash tests/lint/workflow-load-size.sh \| sed -n 's/^new-feature start: \([0-9]*\) bytes.*/\1/p'` | [E2] |
| Implementation resume load | <= 55000 bytes | 54360 bytes | PASS | `bash tests/lint/workflow-load-size.sh \| sed -n 's/^implementation resume: \([0-9]*\) bytes.*/\1/p'` | [E2] |
| Script lint clean | exit 0; 0 shellcheck findings | exit 0; 0 findings over 49 files | PASS | the `script-lint` command | [E4] |
| Harness lint clean | exit 0; 0 shellcheck findings | exit 0; 0 findings over 86 files | PASS | the `harness-lint` command | [E5] |
| Agent-docs lint clean | exit 0; each lint suite reports 0 failed | exit 0; 41, 36, 45, 13 passed, 0 failed | PASS | the `agent-docs-lint` command | [E6] |
| Every script this spec adds or changes has a suite | `0` printed | 0 | PASS | the `script-coverage` command | [E7] |
| Every new `.agents/` file is in `PROVENANCE.md` | `0` printed | 0 | PASS | the `asset-coverage` command | [E8] |
| Line coverage of changed shell code | not measured | not measured: no bash coverage tool, and the spec allows no new dependency | not measured | none | — |

The review-targets lens recorded both load targets `not_measurable`: the plan's commands ran the suite directly and it is committed 100644 (F4). The commands now start with `bash`; the numbers above are from those commands at `4b7c9a7`. The agent-docs lint was run at 4.8 (F7), not by the lens.

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 New-feature start load | PASS | `lint/workflow-load-size` in [E1]; [E2] |
| JRN-002 Implementation resume load | PASS | `lint/workflow-load-size` in [E1]; [E2] |
| JRN-003 Every step routes to one step file | PASS | `lint/step-routing` in [E1] |
| JRN-004 Link lint catches a broken anchor | PASS | `lint/md-links` in [E1]; red on an injected broken link in [E3] |
| JRN-005 Term list and lookup | PASS | `scripts/term-list` in [E1] |
| JRN-006 One home per shared rule | PASS | `lint/shared-rule-homes` in [E1] |
| JRN-007 Frontmatter and small-path docs | PASS | `lint/small-path-docs`, `lint/frontmatter` in [E1] |
| JRN-008 Size check fails above a target | PASS | `lint/workflow-load-size` padded-fixture checks in [E1] |
| JRN-009 Affected area from `owns` paths | PASS | `lint/affected-area` in [E1] |
| JRN-010 Full suite green | PASS | [E1] |

Behaviour verification: every journey is a harness suite; each new suite was red on the baseline [E3] and is green at head [E1]. Runtime behaviour in a live session was not exercised end to end: this Phase 4 session followed the new `review-triage.md`, but the Skill tool loaded the router from the main checkout, which still holds the old one.

## Review outcome

- Review passes: 1 (rework used 1 of 5) · Findings: 4 patched (F1–F4), 0 deferred, 3 settled gaps dismissed (F6–F8), 1 discovered work waiting for a ruling (F5); failed lenses: none (see design-log.md "Triage, review pass 1" and "Rework 1 result")
- Follow-up review recommended: no; no patch was graded high

## Known gaps

- Live sessions on Claude Code and Codex following the split step files were not observed; the first feature session on `main` after the merge settles it (review-end-state, not verifiable).
- Line coverage of changed shell code: not measured, no bash coverage tool (review-targets).
- Links inside `.agents/**/assets/*.md` are not checked: `lint/md-links` skips `assets/` folders (review-end-state, not checked).
- `term-list.sh` and the output style's `awk` command are not on the allow list in `.agents/hooks/claude-settings.template.json`; a target project in default permission mode may get a prompt at session start (review-end-state, not checked).
- Load margin: the new-feature start has 267 bytes to spare and counts the term list, so a few new glossary terms can fail `lint/workflow-load-size` (ADR-0004 says to trim, not raise).

## Deferred

- [.workflow/deferred/cache-scope-paths.md](../../deferred/cache-scope-paths.md): validate cache scope paths in publishing and the stamp check (scope decision, Phase 0).
- [.workflow/deferred/in-review-hand-off.md](../../deferred/in-review-hand-off.md): run the hand-off on the 3.14 routes to review (scope decision, Phase 0).

## Open items

- feature-workflow-retrospective-edge (to ask, out of scope, found at 4.1): sign-off.md links into the retrospective skill's files, an edge `rules.md` Ownership does not declare; it predates this spec. Recommended: keep for later.
- Quoted `self_review[].item` (to ask, out of scope, found at 3.4): implementation agents write the checklist number as a quoted string, which `check-task-result.sh` rejects; it recurred in rework 1 (T1, T9, T10). Recommended: keep for later.

## How to verify

1. `bash tests/lint/workflow-load-size.sh` prints `new-feature start: 44733 bytes (limit 45000)` and `implementation resume: 54360 bytes (limit 55000)`.
2. `tests/run-all.sh` ends with `TOTAL passed=4458 failed=0`.

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt): the harness run at head
- [E2] `bash tests/lint/workflow-load-size.sh` at `4b7c9a7`: "new-feature start: 44733 bytes (limit 45000)", "implementation resume: 54360 bytes (limit 55000)"
- [E3] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md): each new suite red before the change, `lint/md-links` red on an injected broken link
- [E4] [artifacts/review/pass-1/targets/script-lint-clean.txt](artifacts/review/pass-1/targets/script-lint-clean.txt)
- [E5] [artifacts/review/pass-1/targets/harness-lint-clean.txt](artifacts/review/pass-1/targets/harness-lint-clean.txt)
- [E6] design-log.md "Triage, review pass 1", F7: the four agent-docs lint suites at 4.8
- [E7] [artifacts/review/pass-1/targets/every-script-this-spec-adds-or-changes-has-a-suite.txt](artifacts/review/pass-1/targets/every-script-this-spec-adds-or-changes-has-a-suite.txt)
- [E8] [artifacts/review/pass-1/targets/every-new-agents-file-is-in-provenance-md.txt](artifacts/review/pass-1/targets/every-new-agents-file-is-in-provenance-md.txt)
