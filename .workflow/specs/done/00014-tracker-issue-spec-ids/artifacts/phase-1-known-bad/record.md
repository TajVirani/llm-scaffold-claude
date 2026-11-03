# 1.4 known-bad record: 00014-tracker-issue-spec-ids

## Run 1: baseline as the known-bad build

- Fault: none injected. The feature is not built; HEAD 452764b is the base e8162a9 plus the 1.2 harness and four interface stubs that print placeholders and exit 0.
- Where: scratch worktree `.workflow/.worktrees/s00014_known_bad` at 452764b (`revision.txt`), removed afterwards.
- Command: `tests/run-all.sh -v`, output `harness.txt`, failures block `failures.txt`.
- Exit: 1 (`harness-exit.txt`). TOTAL passed=4472 failed=161 skipped=0 xfail=0 (81 suites).
- Failing suites, exactly the six new and five extended ones: scripts/check-write-paths, scripts/issue-tracking-setup, scripts/issue-tracking, scripts/lib-workflow-paths, scripts/next-spec-number, scripts/review-lessons, scripts/sign-off-pr, scripts/status-transition-tasks, scripts/tracker-adoption, lint/issue-tracking-docs, lint/shared-tracker-logic.

## Every new test fails

- New suites: the only passing lines are fixture sanity checks (`fixture: ...`, 9) and the closing `shellcheck_files` assertions (6); no journey test passes.
- Extended suites: run at the base e8162a9 (`extended-suites-at-baseline.txt`, exit 0) they pass 208, 133, 43, 34 and 153; at 452764b the same counts pass and only the added tests fail (5, 10, 5, 4, 5).
- Other 70 suites: all pass, as at the base.

## Every failure is an assertion

`failures.txt` lists each of the 161 failures with its first detail line. Each is a wrong value or exit code from a stub (`out=00000 want=00016`, `out=https://example.invalid/placeholder`, `rc=0` where a refusal is expected), a step file missing its tracker call (`step 3.16 has no line matching issue-tracker.sh ... move ... done`), today's validators refusing an `old_` name (`spec dir must be .workflow/specs/done/NNN-slug`), or today's `status-transition.sh` refusing `--issue` (`unknown option: --issue`). No failure is a missing command (rc 126/127), a syntax error, an unbound variable or a fixture crash.

## Steps not run

- Injected browser fault: no browser suite in this spec (design-log "Phase 1 scope and interface stubs").
- StrykerJS: not applicable and not installed; the harness is bash, not Vitest. The behaviour this spec changes in existing scripts (`move-to-done.sh`, `open-task-pr.sh`, `rules-setting.sh`) is held by their existing suites, which must pass unchanged (JRN-013).

Verdict: pass, the harness fails the known-bad build on assertions.
