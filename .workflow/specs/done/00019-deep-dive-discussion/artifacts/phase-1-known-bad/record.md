# 1.4 Known-bad build: spec 00019

- Fault: the baseline itself. The feature text does not exist yet; HEAD holds only the baseline plus the merged Phase 1 checks.
- Where: scratch worktree `.workflow/.worktrees/s00019_known_bad` at the spec-branch tip after the `phase-1-test-harness` merge, removed afterwards.
- Command: `tests/run-all.sh` (profile `test` key), full output in [harness.txt](harness.txt).
- Exit code: 1. TOTAL passed=4886 failed=23 (81 suites). Failed suites: `lint/stakeholder-asks-docs` (22), `scripts/retrospective-evidence` (1).
- Every failure is a new 00019 check, and each fails on its assertion (a missing phrase, a count below its minimum, a stale phrase still present, or a wrong number), not on setup:
  - JRN-001 (8 checks): phrases "straight after the round is logged", "say back", "where that is wrong", "explicit yes", "agreed statement", "contradicts", "still standing" missing from the 0.3.12 item; "after the round closes" still present.
  - JRN-002 (2): "deep dive under way" and "before computing a new frontier" missing from Entry.
  - JRN-003 (3): old label found in `steps.tsv`, `large-path.md`, `questioning-loop.md`, `assets/design-log.md`; new label found 0 times in each file.
  - JRN-004 (4): Deep dive shape missing Restated, Where it was wrong, Exchanges, Agreed statement, Round check; Initiative round shape missing agreed statement and round check; `questions.md` missing `(confirmed:`.
  - JRN-005 (5): § 6.5 missing the new label, "agreed statement", "explicit yes", `(confirmed:`; Done line still says "or deferred".
  - JRN-006 (1): waits count got 2 with a three-exchange deep dive, want 5 (without: 2, as wanted).
- No pre-existing check failed. Browser suite: not applicable (no e2e profile). StrykerJS: not applicable (bash project, not installed).
- Result: pass. Both new suites go red on the known-bad build, every new check on an assertion.
