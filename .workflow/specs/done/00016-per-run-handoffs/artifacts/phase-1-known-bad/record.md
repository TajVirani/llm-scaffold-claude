# Known-bad run (1.4)

- Fault: the baseline. The feature is not built; HEAD is the baseline plus the Phase 1 tests (38b9d84).
- Command: `tests/run-all.sh`, run in a scratch worktree `.workflow/.worktrees/s00016_known_bad`.
- Exit code: 1. Output: [harness.txt](harness.txt).
- New tests, all failed on an assertion (`check` printed FAIL with the value it got; no setup or source error):
  - `scripts/handoff-skill`: 11 of 11 failed (JRN-001 x5, JRN-002, JRN-003 x2, JRN-006 x2, shellcheck of the Locate block: no Locate block).
  - `hooks/audit-sync-resume`: the 6 new JRN-004 and JRN-005 checks and the 1 updated check failed; the other 59 passed.
- Not from this spec: `lint/step-list` failed 1 check, `checklist.md:328: .workflow/.worktrees/` does not exist. The scratch worktree has no `.workflow/.worktrees/` folder of its own; the path exists in the spec checkout.
- Browser suite: none. The project has no e2e profile; every journey is a harness check.
- StrykerJS: skipped, not installed and not applicable to bash.
