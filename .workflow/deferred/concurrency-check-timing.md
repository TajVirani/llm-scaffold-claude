---
origin_spec: .workflow/specs/004-scoped-test-runs
created: 2026-10-22
---

# Timing-free concurrency checks in the runner suite

**Summary:** The runner selection suite proves parallel and serial runs by wall-clock limits, which a loaded machine can break.
**Mode:** AFK
**Origin:** [004-scoped-test-runs](../specs/004-scoped-test-runs/spec.md), 5.9 work-backlog item `004-scoped-test-runs-disc-003.md` (origin step 3.7), design-log entry 2026-10-22 Discovered work: timing-check-thresholds

## Goal

The suite proves that a default run executes suites concurrently and that `-j 1` runs them one at a time, without depending on how fast the machine is.

## Background

The parallel runner shipped with checks that time stub suites sleeping 2 s each against fixed limits. They passed on every run so far, so the stakeholder shelved the change rather than scheduling it.

**Current behaviour:** the parallel check requires the run to finish under 4 s; the serial check requires at least 4 s.

**Desired behaviour:** the stub suites record when they start and end, and the checks assert that some intervals overlap (default) or none do (`-j 1`).

## Decisions already made

- Suites run in parallel by default and print in suite order (D8, D9 in [.workflow/specs/004-scoped-test-runs/design-log.md](../specs/004-scoped-test-runs/design-log.md)).

## Evidence

- `tests/scripts/run-all-selection.sh:413` and `:419`, as of commit `9fe4e82d5435bd769bfe58f9e39b65d63ae3b662`.
- T1 profile-mini-review return, `out_of_scope_noticed` (kind refactor): [artifacts/T1/mini-review.yaml](../specs/004-scoped-test-runs/artifacts/T1/mini-review.yaml).

## Acceptance criteria

- [ ] No check in the runner selection suite compares elapsed time with a fixed limit.
- [ ] Concurrency under the default and serial behaviour under `-j 1` are still each proved by a check that fails if the behaviour is removed.

## Out of scope

- The intermittent codex-adapters check under parallel load (work item `001-large-path-disc-004`).
