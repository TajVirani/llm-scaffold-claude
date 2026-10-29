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

## Run 4: harness after the 2.3 loop-back (JRN-004 rework)

- Build: `4907bca` (Merge phase-1-test-harness, JRN-004 rework for D12/D16) in a throwaway detached worktree, removed afterwards.
- Fault: none injected; the baseline is the known-bad build, as in Run 1.
- Command: `tests/run-all.sh -v --suite <s>` for the same three suites; log [harness-r2.log](harness-r2.log).
- Result: exit 1 for every suite; 67 failures, all assertions: check-pr-body 26, sign-off-pr 26, task-breakdown 15 (the JRN-004 cases; the 115 existing cases pass). The one `No such file` match in the log is the case name `JRN-004 pr_template .github/missing.md (no such file) -> 1 naming it`, not an error.
- The build agent ran the reworked JRN-004 cases against a throwaway reference in a scratch copy: 130/130 passed.

## Run 5: harness after the 4.5 loop-back (D19, D20, F2; F5 refactor)

- Build: the merge of `d3a3614` onto the spec branch, in a throwaway detached worktree, removed afterwards.
- Fault: none injected; today's feature code is the known-bad build for D19, D20 and F2.
- Command: `tests/run-all.sh -v --suite <s>` for `scripts/check-pr-body` and `scripts/sign-off-pr`; log [harness-r3.log](harness-r3.log).
- Result: exit 1 for both; 8 failures, all assertions (no `command not found`, `syntax error` or `unbound variable`): check-pr-body 5 (JRN-003 D19 cases), sign-off-pr 3 (JRN-006 D20 and F2 cases). New cases that pass today pin behaviour that must hold (filled mixed-level bodies, no-headings exit 2, project-setup lists the four paths). The agent's full run: `TOTAL passed=3155 failed=8 (58 suites)`; its throwaway reference passed check-pr-body 44/44 and sign-off-pr 30/30.
