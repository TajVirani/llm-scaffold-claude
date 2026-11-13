# Phase 1 known-bad record (1.4)

Known-bad build: the spec branch after the Phase 1 merge (the baseline plus the new tests and the `worktree-setup.sh` stub, which does no work). Run in a scratch worktree, `.workflow/.worktrees/s00015_known_bad`, detached at `HEAD`.

| Fault | Command | Exit | Result |
| --- | --- | --- | --- |
| The feature does not exist yet | `tests/run-all.sh` | 1 | 4725 passed, 73 failed, 78 suites. Full log: [harness.txt](harness.txt) |

New tests, all failing on an assertion (`FAIL <title>` with the value it got):

| Suite | Failed | Passed | Journeys |
| --- | --- | --- | --- |
| `scripts/worktree-setup` (new) | 36 | 14 | JRN-001, JRN-003 (check), JRN-004, JRN-007 |
| `lint/worktree-setup-docs` (new) | 19 | 21 | JRN-008 |
| `scripts/spec-worktree` (extended) | 7 | 73 | JRN-002, JRN-005 step 7, JRN-006 |
| `scripts/run-toolchain` (extended) | 10 | 118 | JRN-003 (toolchain), JRN-005 |

The passes in the two new suites are the negative cases that hold on a stub (for example, a tracked file is not copied). No failure is a missing file, a syntax error or a setup error.

Not from this spec: `lint/step-list` fails 1 of 36 in the scratch worktree only, because `checklist.md:328` names the gitignored folder `.workflow/.worktrees/`, which a new worktree does not have. It passes in the spec checkout.

## Steps not run

- Browser suite and injected fault: not applicable. The project has no `e2e-browser` profile; every journey is a harness suite.
- StrykerJS: not applicable to bash.
