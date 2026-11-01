# Known-bad build record (1.4)

## Run 1: the baseline is the known-bad build

- Build: spec branch at `4e7d040` (baseline `1c5e46d` plus the Phase 1 harness only), in a detached scratch worktree.
- Command: `tests/run-all.sh` (the `test` key of `.workflow/profiles/test-harness.md`). Exit 1.
- Result: `TOTAL passed=3599 failed=79 skipped=0 xfail=0 (62 suites)`; failed suites: `scripts/install-claude-settings` (27), `hooks/worktree-guard` (48), `lint/agent-worktree-docs` (4). Every other suite passes, so nothing that existed regressed.
- Every failure is a `FAIL <check name>` assertion line from the harness's `check`/`eq` helpers: an allow where a deny is expected (JRN-001, JRN-003), exit 1 "unknown argument: --confined" where 2 or 0 is expected (JRN-004), "task worktree" wording (JRN-005), quoted `$` reads denied (JRN-006), the four deny rules absent (JRN-007), old `assetlist.md` text (JRN-009). No setup, import or crash error.
- Log: [harness.log](harness.log).

## Run 2: JRN-008 with an installer stand-in

- The JRN-008 checks assert an exit code the current installer already meets, so the baseline cannot show them red. Known-bad build: a scratch worktree at `4e7d040` whose `install.sh` gets two lines after the shebang: any target that already holds `.agents/VERSION` makes it exit 1 and write nothing (a re-run that refuses).
- Command: `tests/run-all.sh --suite scripts/install-upgrade`. Exit 1, `passed=47 failed=78`.
- `FAIL JRN-008 the upgrade re-run exits 0`, `FAIL JRN-008 the JRN-011 third run exits 0`, `FAIL JRN-008 two template groups in one group: the re-run exits 0`: all three new checks fail on their assertion. The three "re-run writes nothing" snapshot checks beside them pass, which is the blind spot the new checks close.
- Log: [upgrade-standin.log](upgrade-standin.log).

## Browser suite

Not applicable: no `e2e-browser` work type in this project; every journey is a harness suite.
