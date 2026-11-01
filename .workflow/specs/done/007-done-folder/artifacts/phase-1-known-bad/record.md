# Known-bad build record: 007-done-folder (1.4)

## Run 1: baseline plus the Phase 1 harness (merge 7f1e12a)

- Build: `HEAD` at merge `7f1e12a` (baseline `9e971ad` plus the harness, the `move-to-done.sh` stub that does nothing and exits 0, no feature code), in a detached scratch worktree.
- Fault: the feature does not exist yet (the baseline is the known-bad build).
- Command: `tests/run-all.sh -v`; log [harness.log](harness.log). Exit 1.
- Result: `TOTAL passed=3646 failed=122 (64 suites)`. Every failure is in the seven suites Phase 1 added or extended; the other 57 suites pass.

| Suite | Failed | First failing case |
| --- | --- | --- |
| `scripts/check-write-paths` | 34 | `done/** main session deny: .workflow/specs/done/012-x/spec.md` |
| `scripts/lib-workflow-paths` | 9 | `WF_SPECS_DONE` value (`got=... unbound variable want=.workflow/specs/done`) |
| `scripts/move-to-done` | 54 | JRN-001 `--check` names the pending task (stub exits 0) |
| `scripts/review-lessons` | 6 | `origin_spec` under `done/` refused |
| `scripts/sign-off-pr` | 3 | 5.8 `SPEC_DIR` on the `done/` path |
| `hooks/session-start-initiatives` | 2 | `spec_done_on_main` true for a spec in `done/` |
| `lint/done-folder-docs` | 14 | `sign-off.md` 5.7 runs `move-to-done.sh --check` |

- Assertion check: every failure is a `FAIL` line from an `eq`/`check`/`t` assertion with `got`/`want` detail; error text in some `got` values (an unbound `WF_SPECS_DONE`, a missing moved file) is the observed value the assertion compared, not a crash of the suite. No suite aborted or failed in setup.
- Passing on the baseline by design: refusal, "changes nothing" and byte-identical cases, listed in [implementation.yaml](../phase-1-test-harness/implementation.yaml).

## Run 2: browser suite

Not applicable: no `e2e-browser` work type and no browser; JRN-001 to JRN-007 are harness suites (as in spec 008).

## StrykerJS

Skipped: not installed, and the scaffold is bash (no JS harness).
