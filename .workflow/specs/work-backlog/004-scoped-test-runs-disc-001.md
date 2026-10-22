---
origin_spec: .workflow/specs/004-scoped-test-runs
origin_step: "3.4"
discovered_at: 2026-10-22
status: open
kind: bug
---

# Intermittent codex-adapters failure under parallel harness runs

## Problem

The `hooks/codex-adapters` check "workflow not installed -> silent allow" failed once in a parallel full-harness run (non-zero exit, empty output). It passed when the suite ran alone, in the next parallel run and in a `-j 1` run. With `tests/run-all.sh` now parallel by default, a load- or timing-sensitive check like this may fail a final full run at random.

## Evidence

- `tests/hooks/codex-adapters.sh:146` or `:203` (both checks share the name; the run report does not say which).
- T1 implementation return, `.workflow/specs/004-scoped-test-runs/artifacts/T1/implementation.yaml`: first default run `FAIL hooks/codex-adapters passed=98 failed=1`; second default run 2347/2347; `-j 1` run 2347/2347.

## Why not a blocker

CAP-NEW-scoped-test-runs' success line is met: the selector, exclude and parallel behaviour are proven by `tests/scripts/run-all-selection.sh`, and a parallel full run passed. The flake is in a suite the spec did not touch.

## Suggested scope and size

- Scope: find which of the two checks fails and why under load (hook runtime, a timeout, a race on the fixture), and make it deterministic. `tests/hooks/codex-adapters.sh`, possibly `.agents/hooks/codex-write-guard.sh` or `codex-pre-spawn.sh`.
- Size: one task, one or two files; well inside the 10-task and 30-file defaults.

## Links

- Origin spec: [spec.md](../004-scoped-test-runs/spec.md)
- Design log entry: [design-log.md](../004-scoped-test-runs/design-log.md) (section 2026-10-22 Discovered work: codex-adapters-parallel-flake)
