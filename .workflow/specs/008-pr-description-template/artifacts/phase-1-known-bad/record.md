# Phase 1 known-bad runs (1.4)

## Run 1: harness on the baseline plus the Phase 1 tests and stubs

- Build: `c10742b` (Merge phase-1-test-harness) in a throwaway detached worktree, removed afterwards.
- Fault: none injected; the feature is not built, so the baseline is the known-bad build. `check-pr-body.sh` is an interface stub that exits 3 for any input and `assets/pr-template.md` is a one-line placeholder, so no case fails on a missing file.
- Command: `tests/run-all.sh -v --suite <s>` for each of the three suites with new cases; log [harness.log](harness.log).
- Result: exit 1 for every suite; 60 failures, every one a `FAIL JRN-00n ...` line from an assertion. Each suite reached its TOTAL line. The only setup-like text in the log is the stub's own `rc=3 ... check-pr-body.sh: not implemented` (48 lines), quoted as assertion detail; the log has no `command not found`, `No such file`, `syntax error` or `unbound variable`.

| Suite | Failed | Journeys |
| --- | --- | --- |
| scripts/check-pr-body | 26 | JRN-001, JRN-002, JRN-003 (its 1 pass is the shellcheck of the stub) |
| scripts/sign-off-pr | 26 | JRN-005, JRN-006 (the first JRN-005 case reports no publish block after the `<!-- 5.8 publish commands -->` marker) |
| scripts/task-breakdown | 8 | JRN-004 (the existing 115 cases pass) |

- Full run on the merged spec branch: `TOTAL passed=3073 failed=60 skipped=0 xfail=0 (58 suites)`; every existing case passes.
- The build agent also ran the new suites against a throwaway reference build in a scratch copy (deleted afterwards): check-pr-body 27/27, task-breakdown 123/123, sign-off-pr 18/26 (every JRN-005 case; the 8 JRN-006 text cases had no step text written to match). So the suites can go green, not only red.

## Run 2: browser suite

Not applicable: no e2e work type and no browser; every journey is a harness suite except JRN-007, which is run by hand at 5.x.

## Run 3: StrykerJS

Skipped: StrykerJS mutates JS/TS only and the changed code is bash. Not a silent pass.
