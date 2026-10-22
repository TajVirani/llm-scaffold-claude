# Report: Scoped test runs for the harness profiles

Spec: [spec.md](spec.md) · Proposals: [proposals.md](proposals.md) · Design log: [design-log.md](design-log.md)

## Summary

`tests/run-all.sh` now takes `--only-file F` and `--exclude-file G` (suite paths or labels, one per line) and runs suites in parallel by default (`-j N`; `-j 1` serial), printing the same report in the same order as a serial run. The three work profiles now carry a `test_scoped` line that passes the toolchain's selector files to it. A full harness run dropped from about 6 minutes (425 s at `-j 1`) to 142 s; a task that owns one suite now runs it in 17 s.

Two details shipped beyond the agreed wording: selector files also accept suite labels (`scripts/x`), and a selection that exclusion leaves empty runs nothing and exits 0 (an unknown selector still exits 2).

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-001 Scoped and parallel harness runs | PASS | [E1] [E2] [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 2347 passed / 0 failed / 33 suites; exit 0; 142 s at HEAD plus the 5.3 profile edits | [E1] |
| Runner selection suite | `tests/run-all.sh --suite scripts/run-all-selection` | 31 passed / 0 failed | [E2] |
| CI | none (deferred by ADR-0001) | not run | — |

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (mini-review pass on round 2, one fix round for readable-code R2) | [artifacts/T1/](artifacts/T1/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| none | — | not measured: no `verification-plan.md` on the light path | not measured | — | [E4] |

Informal timings (not targets): full run 142 s parallel vs 425 s at `-j 1`; `test_scoped` with one own suite 17 s; with no own suite and `install` excluded 104 s (32 suites) [E3].

## Journeys

None defined (light path, no `verification-plan.md`).

## Review outcome

One review pass, rework used 0 of 5. Findings: F1 low (T1 commit subjects not Conventional Commits; stakeholder: fix at the 5.8 merge), F2 discovered work (workflow-data commits carry other specs' files; next feature, shipped as-is), G1 gap deferred. Patched 0, deferred 1, dismissed 1. Failed lenses: none. `followup_review_recommended: false`.

## Known gaps

- Browser gate (3.10-3.11) skipped: no `e2e-browser` profile in this repo ([browser-suite.md](../../deferred/browser-suite.md)).
- review-targets measured nothing: no Targets table on the light path.
- Success signal not yet observed on a live spec: per-task scoped runs need a spec with unfinished tasks, and the stop audit still runs the toolchain a second time (separate spec) ([per-task-scoped-runs.md](../../deferred/per-task-scoped-runs.md)).
- `test_scoped` runs only while some task is unfinished; with nothing excluded the full `test` runs (by design, D3).

## Deferred

- [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md) (no severity; 3.14 suite gap)
- [.workflow/deferred/per-task-scoped-runs.md](../../deferred/per-task-scoped-runs.md) (no severity; 4.8 review gap)

Backlog items from this spec: `004-scoped-test-runs-disc-002` (interrupted run leaves suites running), `-disc-003` (wall-clock thresholds in the selection suite), `-disc-004` (workflow-data commits carry other specs' files). The codex-adapters flake was merged into `001-large-path-disc-004`.

## How to verify

```bash
tests/run-all.sh                     # parallel full run
tests/run-all.sh -j 1                # serial, same report
printf 'tests/scripts/run-all-selection.sh\n' > /tmp/own; : > /tmp/excl
tests/run-all.sh --only-file /tmp/own --exclude-file /tmp/excl
```

## Evidence

- [E1] Full harness at HEAD 9fe4e82 with the 5.3 profile edits, run 2026-10-22 by the main session: `TOTAL passed=2347 failed=0 skipped=0 xfail=0 (33 suites)`, real 141.88 s, exit 0. Gate run: [artifacts/gate-3.9-w1/toolchain.txt](artifacts/gate-3.9-w1/toolchain.txt).
- [E2] [artifacts/T1/toolchain.txt](artifacts/T1/toolchain.txt), [artifacts/T1/implementation.yaml](artifacts/T1/implementation.yaml): selection suite 31/31; `-j 1` full run 425 s.
- [E3] `test_scoped` smoke run from `.workflow/profiles/test-harness.md`: own = run-all-selection → 1 suite, 31 passed, 16.8 s; own empty, exclude install → 32 suites, 2209 passed, 104.5 s.
- [E4] [artifacts/review/pass-1/review-targets.yaml](artifacts/review/pass-1/review-targets.yaml).
