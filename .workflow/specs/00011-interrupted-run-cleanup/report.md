# Report: Interrupted harness runs clean up their background suites

Spec: [spec.md](spec.md) · Verification plan: none (light path) · Baseline: `3fee587d96a73c6c2692e3cb534b5883aa7c7324` · Head: `cc1e584f0050ec7ced499cd5a6dc61f6e1eec3c3`

## Summary

`tests/run-all.sh` now starts each suite in its own process group with `/dev/null` as stdin. On INT, TERM or HUP it stops every running suite and its children (TERM, 2 s, then KILL), removes its results directory and exits 130, 143 or 129. An uninterrupted run is unchanged. The full harness passes (3593 of 3593); the only gap is the browser gate, skipped because this repo has no browser suite.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-001 Scoped and parallel harness runs (interrupted runs stop their suites) | PASS | [E1] [E2] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 3593 passed, 0 failed, 0 skipped (62 suites); exit 0 | [E1] |
| CI | none (CI deferred, ADR-0001) | not run | none |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (lint pass, test pass) after 2 wording fix rounds and rework 1 | [artifacts/T1/](artifacts/T1/) |

## Targets vs measured

no targets (light path)

## Journeys

None (light path: no verification plan). The interrupt behaviour is exercised by the INT, TERM and HUP cases and the stdin case in `tests/scripts/run-all-selection.sh` [E2].

Behaviour verification: the selection suite starts a fixture copy of the runner on a stub suite whose child `sleep` records its pid, sends each signal with `kill`, and checks the exit code, that the suite and its `sleep` are gone, and that the results directory is gone; the INT case ran (0 skipped). Ctrl-C from a real terminal and a real terminal hangup were not exercised.

## Review outcome

- Review passes: 1 (rework used 1 of 5) · Findings: 2 patched (F1 medium: suite stdin under `set -m`; F2 low: guard comment wording), 0 deferred, 0 dismissed (see design-log.md, Triage, review pass 1)
- Follow-up review recommended: no; the rework's patches were medium and low and passed their gates
- Mini-review: round 1 failed R2 (an unexplained guard), fixed; the re-check's out-of-scope note on the comment's stated reason was taken as this task's own wording fix (round 2); the rework's full mini-review passed 8 of 8.

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
- Not verifiable by the lenses: Ctrl-C at an interactive terminal with several suites, the closed-terminal HUP path end to end, and the assumption that no suite daemonises or calls `setsid` (review-end-state `not_verifiable`).
- Not checked: review-standards listed 5 and review-lessons 2 `not_checked` items (scope notes for a light-path spec); see `artifacts/review/pass-1/`.

## Deferred

- [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md): browser suite for this repo; Later requests line added (no severity: suite gap).

## How to verify

1. Run `tests/run-all.sh --suite scripts/run-all-selection`: expect `RESULT passed=66 failed=0 skipped=0`, including the INT, TERM, HUP and stdin cases.
2. Run `tests/run-all.sh` in a terminal and press Ctrl-C after a few seconds: expect the prompt back with exit status 130 (`echo $?`), and `ps -ax | grep 'bash .*tests/'` shows no suite from that run.
3. Run `tests/run-all.sh` to the end: expect the same summary format as before and exit 0.

## Evidence

- [E1] `artifacts/sign-off-5.4/toolchain.txt`: `TOTAL passed=3593 failed=0 skipped=0 xfail=0 (62 suites)` at `cc1e584`; also `artifacts/gate-3.9-w2/toolchain.txt`.
- [E2] `artifacts/T1/toolchain.txt` and `artifacts/T1/implementation.yaml` (`tests_added`): the INT, TERM and HUP cases and the stdin end-of-file case in `tests/scripts/run-all-selection.sh`.
