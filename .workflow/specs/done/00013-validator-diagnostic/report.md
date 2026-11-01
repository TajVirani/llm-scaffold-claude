# Report: The single writers keep the validator's diagnostic

Spec: [spec.md](spec.md) · Verification plan: none (light path) · Baseline: `7b0ccebe3e9e0616e5897479915113897dc40fbe` · Head: `205595d1e7781f6d2a033c22707e4125194a7235`

## Summary

`status-transition.sh set-task` and `initiative-transition.sh` now run their template validator without `-e` and read its printed verdict: `true` writes, `false` refuses exactly as before (exit 1 and 2), and a validator yq cannot run exits 1 with yq's own error text. The full harness passes (3623 of 3623); the only gap is the browser gate, skipped because this repo has no browser suite.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-009 Single writers report a broken validator | PASS | [E1] [E2] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 3623 passed, 0 failed, 0 skipped (62 suites); exit 0 | [E1] |
| CI | none (CI deferred, ADR-0001) | not run | none |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (lint pass, test pass), first round | [artifacts/T1/](artifacts/T1/) |

## Targets vs measured

no targets (light path)

## Journeys

None (light path: no verification plan). The writers' behaviour is exercised by the broken-validator and rejection cases in `tests/scripts/status-transition-tasks.sh` and `tests/scripts/initiative-transition.sh` [E2].

Behaviour verification: each suite puts a PATH yq shim in front of the real yq that fails only the validator call, runs the writer, and checks the exit code (1), yq's diagnostic on stderr, the file byte-identical, `.step` unchanged and no prepared copy left; an ordinary rejection keeps today's message and exit code with no yq `Error:` text. Not exercised: a real yq release that warns on stderr while exiting 0 (triage F1, dismissed).

## Review outcome

- Review passes: 1 (rework used 0 of 5) · Findings: 0 patched, 0 deferred, 1 dismissed with reason (F1, maybe-false) (see design-log.md, Triage, review pass 1)
- Follow-up review recommended: no
- Mini-review: passed first round, 11 pass and 2 not applicable.

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../../deferred/browser-suite.md)

## Deferred

- [.workflow/deferred/browser-suite.md](../../../deferred/browser-suite.md): browser suite for this repo; Later requests line added (suite gap, no severity).

## How to verify

1. Run `tests/run-all.sh --suite scripts/status-transition-tasks --suite scripts/initiative-transition`: expect both suites to pass (153 and 80 checks at sign-off).
2. In a scratch spec, point PATH at a `yq` wrapper that fails only for the validator expression, run `status-transition.sh set-task`: expect exit 1 and a message starting `cannot run the tasks.md schema validator` with yq's text.

## Evidence

- [E1] `artifacts/sign-off-5.4/toolchain.txt`: `TOTAL passed=3623 failed=0 skipped=0 xfail=0 (62 suites)`; `scripts/status-transition-tasks passed=153`, `scripts/initiative-transition passed=80`; also `artifacts/gate-3.9-w1/toolchain.txt`.
- [E2] `artifacts/T1/implementation.yaml` (`tests_added`): the broken-validator, non-boolean-result and rejection cases in both suites.
