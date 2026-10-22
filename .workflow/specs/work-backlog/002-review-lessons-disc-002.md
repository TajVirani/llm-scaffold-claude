---
origin_spec: .workflow/specs/002-review-lessons
origin_step: "3.9"
discovered_at: 2026-10-22
status: open
kind: bug
---

# A timing assertion in the run-all selection suite fails under load

## Problem

The suite that tests the harness runner's parallelism proves "suites run concurrently" by wall time: four one-second stub suites must finish in under four seconds. When the machine is busy, for example when two full harness runs overlap, the stub suites take the whole four seconds and the assertion fails although the runner did run them in parallel. A green gate can then turn red for a reason unrelated to the change under test.

## Evidence

- `.workflow/specs/002-review-lessons/artifacts/gate-3.9-w1b/toolchain.txt:27-28`: `FAIL with no -j, suites run concurrently` / `took 4s for 4s of sleeping suites`, in a gate run that overlapped T5's toolchain run of the whole harness.
- The same assertion passed in `artifacts/gate-3.9-w1/toolchain.txt` and in `artifacts/gate-3.9-w1c/toolchain.txt` (the re-run without concurrent load), on the same merged tree apart from T3's five non-script files.
- `tests/scripts/run-all-selection.sh`, the "concurrent runs by default" case in its `# Covers:` header.

## Why not a blocker

No capability or journey of 002-review-lessons touches the runner; the gate passes when re-run without concurrent load, and the orchestrator can avoid overlapping harness runs.

## Suggested scope and size

- Scope: make the concurrency assertion independent of load: compare the parallel run's wall time with a serial `-j 1` run of the same stubs taken in the same test (parallel must be shorter), or prove concurrency by observing overlapping start and end timestamps the stubs write, instead of a fixed bound. Leave the runner alone.
- Size: one task in `tests`, one file; far below the defaults of 10 tasks and 30 changed files in `.workflow/rules.md`.

## Links

- Origin spec: [spec.md](../002-review-lessons/spec.md)
- Design log entry: [design-log.md](../002-review-lessons/design-log.md) (section 2026-10-22 Discovered work: flaky-parallel-timing-test)
