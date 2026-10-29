# Phase 1 known-bad runs (1.4)

## Run 1: harness on the baseline plus the Phase 1 tests and stubs

- Build: `e302664` (Merge phase-1-test-harness) in a throwaway detached worktree, removed afterwards.
- Fault: none injected; the feature is not built, so the baseline is the known-bad build. The lib functions are placeholder stubs (`.agents/lib/test-paths.sh`, `wf_main_root`, `wf_norm_folder`), so no case fails on a missing file or function.
- Command: `tests/run-all.sh --suite <s>` for each of the seven suites with new failing cases; log [harness.log](harness.log).
- Result: exit 1 for every suite; 58 failures, every one a `FAIL JRN-00n ...` line from an `eq` or `check` assertion. Each suite reached its TOTAL line; the log has no `command not found`, `No such file`, `syntax error` or `unbound variable`.

| Suite | Failed | Journeys |
| --- | --- | --- |
| scripts/extractor-bash | 2 | JRN-001 |
| scripts/cache-repo-architecture | 2 | JRN-002 |
| scripts/cache-boundary-check | 4 | JRN-003 |
| scripts/lib-test-paths | 25 | JRN-005 |
| scripts/lib-workflow-paths | 19 | JRN-006 |
| scripts/task-breakdown | 2 | JRN-006 (open-task-pr task mode and `--record`) |
| scripts/cache-scripts | 4 | JRN-007 |

- Full run on the merged spec branch: `TOTAL passed=3001 failed=58 skipped=0 xfail=0 (56 suites)`; every existing case passes.
- New cases that pass at baseline pin today's behaviour, by design: JRN-004 (violations listed, bad `--violations-json` exits 2), the JRN-005 two-script agreement and per-script invalid-value exits, the JRN-006 per-script normaliser cases, and the JRN-007 `ok`/exit-code contract. They guard the refactor; they are not proof of new behaviour.

## Run 2: browser suite

Not applicable: no e2e work type and no browser; every journey is a harness suite except JRN-008, which is run by hand at 5.x.

## Run 3: StrykerJS

Skipped: StrykerJS mutates JS/TS only and the changed code is bash. Not a silent pass.
