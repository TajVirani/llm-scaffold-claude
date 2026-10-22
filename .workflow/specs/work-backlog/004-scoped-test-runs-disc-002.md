---
origin_spec: .workflow/specs/004-scoped-test-runs
origin_step: "3.7"
discovered_at: 2026-10-22
status: open
kind: bug
---

# Interrupted harness runs leave background suites running

## Problem

When `tests/run-all.sh` is interrupted (Ctrl-C or a kill), its EXIT trap removes the results directory, but suites started in the background are not stopped: they keep running and writing after the runner has exited.

## Evidence

- `tests/run-all.sh:157` (trap `rm -rf` of the results directory), `tests/run-all.sh:167-176` (`start_suite` runs each suite in a background subshell).
- T1 profile-mini-review return, `out_of_scope_noticed` (kind bug), `.workflow/specs/004-scoped-test-runs/artifacts/T1/mini-review.yaml`. Not reproduced by a run.

## Why not a blocker

A normal run waits for every suite, so CAP-NEW-scoped-test-runs and every completed run are unaffected; only an interrupted run leaks processes.

## Suggested scope and size

- Scope: on INT/TERM, kill the background suite process groups before removing the results directory, and exit 130/143; add a check to `tests/scripts/run-all-selection.sh`.
- Size: one task, two files.

## Links

- Origin spec: [spec.md](../004-scoped-test-runs/spec.md)
- Design log entry: [design-log.md](../004-scoped-test-runs/design-log.md) (section 2026-10-22 Discovered work: interrupted-run-orphans)
