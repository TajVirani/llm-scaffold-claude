# Phase 1 known-bad runs (1.4)

## Run 1: harness on the baseline plus the Phase 1 tests and stubs

- Build: `346b568` (Merge phase-1-test-harness) in a throwaway detached worktree, removed afterwards.
- Fault: none injected. The feature is not built, so the baseline is the known-bad build. `wf_enc`, `wf_agent_worktree_name` and `check-merge-artifacts.sh` are placeholder stubs (print nothing, status 0), so no case fails on a missing file or function.
- Command: `tests/run-all.sh --suite <s>` for each of the seven suites with new failing cases. Full log: [harness.log](harness.log).
- Result: every suite exits 1, with 123 failures in all. Each one is a `FAIL JRN-00n ...` line from an assertion (`got=`/`want=`, `rc=`, or a matched line). Every suite reached its TOTAL line. The log has no `command not found`, `No such file`, `syntax error` or `unbound variable`.

| Suite | Failed | Journeys |
| --- | --- | --- |
| scripts/lib-workflow-paths | 52 | JRN-001 |
| hooks/worktree-guard | 24 | JRN-002 (3), JRN-003 (3), JRN-009 (18) |
| lint/agent-worktree-docs | 20 | JRN-008 |
| scripts/check-merge-artifacts | 15 | JRN-007 |
| hooks/audit-agent-worktrees | 10 | JRN-005 |
| scripts/install-claude-settings | 1 | JRN-006 |
| scripts/install-upgrade | 1 | JRN-006 |

- Full run on the merged spec branch gave `TOTAL passed=3163 failed=123 skipped=0 xfail=0 (59 suites)`, and every existing case passes.
- Some new cases already pass at baseline. They pin behaviour that works today, by design, and guard against regressions; they do not prove new behaviour.
  - JRN-002 to JRN-004: the result-file command taken from the briefs runs, and its file passes `check-task-result.sh`.
  - JRN-004 has no red case. The new behaviour it covers, an absolute main-checkout path in the briefs, is proven red by JRN-008's brief-path cases instead.
  - JRN-002 and JRN-003: the deny cases for writes outside the agent worktree.
  - JRN-009: the flag and shell-form deny cases.
- One existing case changed its command, not its verdict. In `hooks/worktree-guard`, "task agent Bash without cd -> deny" now runs `npm test` instead of `git status`, because `git status` joins the read-only allowlist.

## Run 2: browser suite

Not applicable. There is no e2e work type and no browser. Every journey is a harness suite, except JRN-010, which is run by hand on the first real launch.

## Run 3: StrykerJS

Skipped. StrykerJS mutates JS/TS only, and the changed code is bash. This is not a silent pass.

## Run 4: harness re-entry for JRN-011 to JRN-014

- Fault: the merged spec branch `04aba50`, which has the JRN-011 to 014 tests but not the installer or docs change (T1 is unmerged too). Run in a throwaway detached worktree.
- Command: `tests/run-all.sh --suite scripts/install-upgrade --suite lint/install-matcher-docs`, exit 1. Log: [harness-r2.log](harness-r2.log).
- Result: `TOTAL passed=48 failed=36 (2 suites)`. `scripts/install-upgrade` has 21 failures: 20 new plus the earlier JRN-006 "after the upgrade" case. `lint/install-matcher-docs` has 15.
- Every new failure is an assertion. First errors:
  - JRN-011: `got=implementation`, and no Warnings line names a merged or kept group.
  - JRN-012: `--matchers=*` exits `got=2 want=0` as an unknown option. Matchers are left `implementation|foo`, the `--dry-run` preview shows no matcher, and the bogus-value error does not name the modes.
  - JRN-013: the prompt text is empty, Enter and `r` leave `implementation|foo`, and the mixed-group prompt lists no hooks.
  - JRN-014: each of the four doc sections lacks `--matchers`, the three modes and the no-terminal rule, `--help` has no `--matchers`, and the Merge rules still skip a group whatever its matcher.
- Some new cases already pass on today's `install.sh`. They pin behaviour that is right now, by design, as in Run 1:
  - Match-all, covered and mixed groups are untouched, and the third run writes nothing.
  - `keep` leaves the matcher unchanged, `bogus` exits 2, and both dry runs write nothing.
  - `(a|b)c` is never merged.
  - Every pseudo-terminal run ends within 20 s and `k` keeps.
  - Each of the four doc sections is found.
- Pseudo-terminal: macOS `script -q /dev/null` worked, so no JRN-013 case was skipped.
