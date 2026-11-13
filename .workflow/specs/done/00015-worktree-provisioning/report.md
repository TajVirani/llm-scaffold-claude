# Report: Worktree provisioning

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `aea4e6ebc531a649e09ff3f34d241fb48cabe9e1` · Head: `886a32cc72875d109f0784ff573cf3122a81830f`

## Summary

One script, `worktree-setup.sh`, now creates every agent worktree and scratch worktree and sets up every spec worktree: it gives the spec a slot, copies the project's gitignored files as real files, runs the project's setup command with the spec's isolation values and refuses a symlink that reaches back into the main checkout. `run-toolchain.sh` runs that link check and starts the project's services before a test run, and removing a spec worktree stops them. The whole harness passes on the merged spec branch (4860 passed, 0 failed, 79 suites) [E1]. The most important gap: the behaviour is proven in fixture projects only; no project that declares a setup command and services has run a spec through it yet.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-016 Worktree setup | PASS | [E1], [E2], [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9), whole harness, nothing excluded | `tests/run-all.sh` | 4860 passed, 0 failed, 79 suites; exit 0 | [E1] |
| CI | none (this repo has no CI; the harness run by hand is the whole gate) | not applicable | [E1] |
| Browser | none (no `e2e-browser` profile; every journey is a harness suite) | not applicable | verification-plan.md § Suites |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| Integration batch (path constants) | clean | [artifacts/integration-shell-scripts/](artifacts/integration-shell-scripts/) |
| T1 | clean | [artifacts/T1/](artifacts/T1/) |
| T2 | clean after one fix round (a lint that failed in every new worktree, fixed in the task) | [artifacts/T2/](artifacts/T2/) |
| T3 | clean; clean again after rework 1 | [artifacts/T3/](artifacts/T3/) |
| T4 | clean | [artifacts/T4/](artifacts/T4/) |
| T5 | clean | [artifacts/T5/](artifacts/T5/) |
| T6 | clean | [artifacts/T6/](artifacts/T6/) |
| T7 | clean | [artifacts/T7/](artifacts/T7/) |
| T8 | clean | [artifacts/T8/](artifacts/T8/) |
| T9 | clean | [artifacts/T9/](artifacts/T9/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| Worktree setup with nothing declared adds no work | not measured | not measured: no number to take; JRN-002 proves the behaviour is unchanged | not measured | none | [E2] |
| Script lint clean | exit 0; 0 shellcheck findings | 0 shellcheck findings, comment lint clean | PASS | `script-lint` in verification-plan.md | [E4] |
| Harness lint clean | exit 0; 0 shellcheck findings | 0 shellcheck findings, comment lint clean | PASS | `harness-lint` in verification-plan.md | [E4] |
| Agent-docs lint clean | exit 0; each lint suite reports 0 failed | 0 failed in each of the four suites | PASS | `agent-docs-lint` in verification-plan.md | [E4] |
| Every script this spec adds or changes has a suite | 0 | 0 | PASS | `script-coverage` in verification-plan.md | [E4] |
| Every new `.agents/` file is in `PROVENANCE.md` | 0 | 1 | FAIL as measured; the finding was triaged false (F2) | `asset-coverage` in verification-plan.md | [E4], [E5] |
| Line coverage of changed shell code | not measured | not measured: no bash coverage tool is installed | not measured | none | [E4] |

The one FAIL is the measuring command, not the file: `PROVENANCE.md` line 11 names `worktree-setup.sh` in the feature-workflow row, in the bare-name form every other shared script there uses, and the command greps for the full path [E5].

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 A set-up spec and agent worktree | PASS | `scripts/worktree-setup` in [E1] |
| JRN-002 A project that declares nothing | PASS | `scripts/spec-worktree` in [E1] |
| JRN-003 A link back into the main checkout is refused | PASS | `scripts/worktree-setup` and `scripts/run-toolchain` in [E1] |
| JRN-004 Two specs, two slots | PASS | `scripts/worktree-setup` in [E1] |
| JRN-005 Services around a test run | PASS | `scripts/run-toolchain` and `scripts/spec-worktree` in [E1] |
| JRN-006 A failing setup command | PASS | `scripts/spec-worktree` in [E1] |
| JRN-007 A scratch worktree | PASS | `scripts/worktree-setup` in [E1] |
| JRN-008 The documents name the script | PASS | `lint/worktree-setup-docs` in [E1] |

Behaviour verification: the script was also used for real in this spec from wave 3 on. Eight task worktrees were created with `worktree-setup.sh agent` and removed with `worktree-setup.sh remove`, the gates ran through the new `run-toolchain.sh` (link check passed), and this spec worktree took slot 1. This repo declares no setup command, copy list or services, so that use exercised the nothing-declared path only.

## Review outcome

- Review passes: 1 (rework 1 of 5 used) · Findings: 1 patched (F1, low: one source for the isolation values), 0 left open, 1 dismissed with reason (F2, false); see the Triage entry in design-log.md. The end-state lens found nothing in 16 checks. No lens failed.
- Follow-up review recommended: no. No finding was verified high.
- Size budget: 9 of 10 tasks, 36 of 37 changed files (budget-check.sh at 5.4) · within. The file limit was raised from 30 to 37 for this spec in the Breakdown quiz.

## Known gaps

- Success signal not shown live: a spec built from start to sign-off in a project that declares its setup, with a second spec beside it on its own ports, needs a run in such a project.
- Whether agents follow the never-install-copy-or-link rule shows only in a live run; the documents say it and a lint checks the wording.
- A stop audit on a worktree that holds a link into the main checkout exits 1 with no evidence file, and the agent is told to report the link, not repair it, so the audit may block the same stop three times before it gives up. Not proven; a stop-audit run on such a fixture would settle it.
- `worktree-setup.sh` and `spec-worktree.sh` drop the settings reader's error text and stop with a generic message.
- Two spec worktrees created at the same instant may take the same slot. Accepted in the data model.
- `run-toolchain.sh --reuse-check` skips the link check, because that option runs and writes nothing.
- `typecheck`, `format` and `boundary` are empty keys in this repo's profiles, so nothing ran for them.
- Two targets are not measurable (the cost with nothing declared, and line coverage of shell code), and the asset-coverage command needs the bare-name form to measure what the rule asks.
- The implementation-resume load is a few bytes under its 55,000-byte lint limit after this change.
- T1's ten own tests were written after the code and never seen failing; the Phase 1 cases for the same keys were.

## Deferred

- [.workflow/deferred/rules-setting-usage-exit-code.md](../../../deferred/rules-setting-usage-exit-code.md): the settings reader exits 1 for a usage error where sibling scripts exit 2.

## How to verify

1. Run `tests/run-all.sh` on the spec branch. Expected: `TOTAL passed=4860 failed=0`, 79 suites.
2. Run `tests/run-all.sh --suite scripts/worktree-setup`. Expected: 60 passed, 0 failed.
3. In a throwaway project with the scaffold installed, put `worktree_setup: "touch .setup-ran"` in the Workflow settings block of `.workflow/rules.md`, add `.env` to `.gitignore` and to `.worktreeinclude`, create a `.env`, then create a spec worktree. Expected: the worktree holds `.env` as a regular file and `.setup-ran`.

## Evidence

- [E1] [artifacts/gate-3.9-r1/toolchain.txt](artifacts/gate-3.9-r1/toolchain.txt): `TOTAL passed=4860 failed=0 skipped=0 xfail=0 (79 suites)`, the whole harness on the merged spec branch after rework 1; [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt) is the same tree, reused.
- [E2] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md): the same suites failing by design before the feature existed (72 assertion failures).
- [E3] [artifacts/review/pass-1/review-end-state.yaml](artifacts/review/pass-1/review-end-state.yaml): 16 requirements checked against the spec, 0 findings.
- [E4] [artifacts/review/pass-1/review-targets.yaml](artifacts/review/pass-1/review-targets.yaml) and its raw output under [artifacts/review/pass-1/targets/](artifacts/review/pass-1/targets/).
- [E5] design-log.md, Triage, review pass 1, F2: `grep -c 'worktree-setup.sh' PROVENANCE.md` prints 1.
