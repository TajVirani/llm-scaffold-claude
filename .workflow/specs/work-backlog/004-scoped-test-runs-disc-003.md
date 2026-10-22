---
origin_spec: .workflow/specs/004-scoped-test-runs
origin_step: "3.7"
discovered_at: 2026-10-22
status: moved-to-deferred
kind: refactor
---

# Wall-clock thresholds in the runner selection suite

## Problem

The parallel and serial checks in `tests/scripts/run-all-selection.sh` compare wall-clock seconds against fixed limits (under 4 s parallel, at least 4 s serial, for stub suites that sleep 2 s), so they may fail on a heavily loaded machine.

## Evidence

- `tests/scripts/run-all-selection.sh:413` and `:419`.
- T1 profile-mini-review return, `out_of_scope_noticed` (kind refactor), `.workflow/specs/004-scoped-test-runs/artifacts/T1/mini-review.yaml`.

## Why not a blocker

The limits leave margin and the checks passed in every run so far; the report-order check does not depend on timing.

## Suggested scope and size

- Scope: prove concurrency from overlapping start/end markers the stub suites write, instead of wall time. Best done together with 004-scoped-test-runs-disc-001 (load-sensitive checks).
- Size: one task, one file.

## Links

- Origin spec: [spec.md](../004-scoped-test-runs/spec.md)
- Design log entry: [design-log.md](../004-scoped-test-runs/design-log.md) (section 2026-10-22 Discovered work: timing-check-thresholds)
- Deferred file: [.workflow/deferred/concurrency-check-timing.md](../../deferred/concurrency-check-timing.md)
