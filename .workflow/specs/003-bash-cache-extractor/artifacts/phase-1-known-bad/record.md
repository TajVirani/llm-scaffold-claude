# Phase 1 known-bad record: 003-bash-cache-extractor

## Run 1: baseline harness (step 1.4.1)

- Build: spec branch at `8135fb2` (baseline `86609a6` plus the 1.2 harness and the two extractor stubs, which print `{"modules":[]}` and exit 0), run in a throwaway detached worktree.
- Command: `tests/run-all.sh` (the `test` key of `.workflow/profiles/test-harness.md`).
- Exit: 1. `TOTAL passed=2764 failed=52 skipped=0 xfail=0 (51 suites)`; full log [harness.log](harness.log).
- Failed suites: `scripts/build-architecture` (3, the new `chk-arch-unresolved-*` cases), `scripts/cache-bash-project` (19, JRN-001), `scripts/cache-js-unchanged` (6, JRN-002), `scripts/cache-missing-extractor-key` (3, JRN-003), `scripts/cache-mixed-extractors` (6, JRN-004), `scripts/extractor-bash` (15). All other 45 suites pass.
- Every new failure is an assertion (got/want or rc/want mismatch). First errors fall into four groups:
  - the stubs print an empty graph: `got= want=lib/paths.sh,...`, `got=null want={"lib/paths.sh":[...]}`, `rc=0 want=2: {"modules":[]}`;
  - `build-architecture.sh` still runs depcruise for a bash project: `got=2 want=0`, `depcruise failed: depcruise must not run for this project`;
  - unknown new flags: `unknown argument: --extractor`, `unknown argument: --print-generator`;
  - `check-staged-cache.sh` still requires three sections: `rc=1 want=0: sections must be exactly: Module graph, Edges, Boundary violations`.
- No failure is an import, missing-file, syntax or crash error.
- Expected after the feature lands: `arch-golden` and `viol-sorted-unique` in `tests/scripts/build-architecture.sh` (passing now) will need updating for the four-section architecture body.

## Run 2: browser suite fault injection (step 1.4.2)

Not applicable: the project has no e2e work type and no browser UI; every journey (JRN-001 to JRN-004) is a harness suite, and JRN-005 is a manual run at 5.3.

## Run 3: StrykerJS (step 1.4.3)

Skipped: StrykerJS does not apply to bash, and the change's existing behaviour (JS/TS rendering) is pinned by the JRN-002 byte-identity oracle rendered at `baseline_revision`.
