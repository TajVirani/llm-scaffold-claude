## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- `tests/run-all.sh` starts each suite in its own process group (job control on only around the launch, so no job notices are printed) and gives it `/dev/null` as stdin, as before.
- On INT, TERM or HUP the runner ignores further signals, sends TERM to every running suite's group, waits up to 2 s, KILLs what is left, removes its results directory and exits 130, 143 or 129. Its usage text documents the new exit codes.
- `tests/scripts/run-all-selection.sh` gains one interrupt case per signal (exit code, suite and its child `sleep` gone, results directory gone) and a case that a suite reading stdin gets end of file.
- Tier A: CAP-001 now names the interrupt behaviour and links this spec; a new pitfall records the `set -m` stdin trap. The Tier B caches were regenerated at `58019c8`.

## Why the change

- An interrupted harness run left its background suites running and writing after the runner exited, and since 004 every run is parallel, so one Ctrl-C could leave several suites behind (backlog item `004-scoped-test-runs-disc-002.md`).
- CAP-001 intent: a developer or script can stop a harness run with INT, TERM or HUP and be left with no suite process, or child of one, still running.

## Why this approach

- Owning module: `tests` alone, so no placement ADR; the change extends CAP-001.
- One process group per suite (D1) reaches grandchildren such as a suite's `sleep`; walking the tree with `pgrep -P` could miss reparented children, and `timeout`/`setsid` would add binaries. It reuses the pattern `.agents/agents/review-targets.md` already uses.
- TERM, a 2 s grace, then KILL (D2) lets suites' own EXIT traps remove their temp dirs without letting a stuck suite hang the runner. HUP is handled too (D3), because suites in their own groups no longer get the terminal's hangup directly.

## Special things to note

- Report: [report.md](report.md). Task PRs: none (light path, T1 committed on the spec branch).
- Browser gate skipped: this repo has no browser suite ([.workflow/deferred/browser-suite.md](../../../deferred/browser-suite.md)).
- Not exercised: Ctrl-C at a real terminal and a real terminal hangup; the checks send signals with `kill`.
- A suite tool that daemonises or calls `setsid` would escape the group kill; none was checked.

## How to test

1. Run `tests/run-all.sh --suite scripts/run-all-selection`: expect `RESULT passed=66 failed=0 skipped=0`.
2. Run `tests/run-all.sh` in a terminal and press Ctrl-C after a few seconds: expect exit status 130 and no `bash .../tests/...` suite left in `ps`.
3. Run `tests/run-all.sh` to the end: expect the usual summary and exit 0 (3593 passed at sign-off).

## Blast radius

- Reviewed files (tests excluded): `.workflow/cache/architecture.md`, `.workflow/cache/flows.md`, `.workflow/cache/modules.md`, `.workflow/deferred/browser-suite.md`; the code change is in `tests/run-all.sh` and `tests/scripts/run-all-selection.sh`.
- `tests/run-all.sh` is the whole test gate: every profile's `test` and `test_scoped` key, `run-toolchain.sh` at 3.5, 3.9 and 5.4, and every hand run go through it. A launch bug would show up as suites failing or hanging in every harness run.
- Nothing under `.agents/` changes, and nothing is installed into target projects.

## Risk and reversibility

Risk: Low - the uninterrupted path keeps its output and exit codes (full harness 3593 of 3593); the interrupt path is new code checked by kill-driven cases only.
Reversibility: Easy - reverting the merge commit restores the previous runner and suite; no data or settings change.

## Areas, concepts and seams changed

- Runner command line (`tests/run-all.sh`): new exit codes 130, 143 and 129 on INT, TERM and HUP; the usage text now prints up to `# Requires:`.
- Suite launch (`start_suite`): each suite runs in its own process group with `/dev/null` as stdin.
- Concepts: CAP-001 (scoped and parallel harness runs).

## How to undo this PR

Revert the merge commit on main (`git revert -m 1 <merge commit>`). Nothing else to restore: no data, settings or installed files change.
