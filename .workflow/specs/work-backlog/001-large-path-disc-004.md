---
origin_spec: .workflow/specs/001-large-path
origin_step: "3.4"
discovered_at: 2026-10-22
status: open
kind: bug
---

# A flaky silent-allow check in the Codex adapters suite

## Problem

The check named "workflow not installed -> silent allow" in the Codex adapters suite failed once in a full harness run and passed in four runs after it, with no code change in between. Two checks in the suite share that name, so a failure line cannot be traced to the line that produced it. The failure happened while six harness runs were executing in parallel on the same machine, so timing or resource contention is the likely cause, but that is unconfirmed.

## Evidence

- `tests/hooks/codex-adapters.sh:146` and `:203`, two checks with the same name, at commit `291e55289f399f767e7403715e14b73ffa5a7ccd`.
- The first toolchain run of T1's rework (`.workflow/specs/001-large-path/artifacts/T1/`) recorded `FAIL workflow not installed -> silent allow` and `FAILED suites: hooks/codex-adapters`; three standalone runs of the suite and the next full run passed (2280 of 2280).
- Reported by the T1 rework implementation return (`discovered_work`, kind bug, can-wait).

## Why not a blocker

The suite and the hook it covers are not touched by 001-large-path, and the failure did not reproduce. No capability or journey depends on it.

## Suggested scope and size

- Scope: give the two checks distinct names, find what makes the hook's silent-allow path sensitive to timing or environment (run the suite under load, or with `run-toolchain.sh`'s environment), and fix or isolate it. Leaves out any change to the hook's behaviour unless the investigation finds a real race.
- Size: one task in the tests module (two files at most), well inside the defaults.

## Links

- Origin spec: [spec.md](../001-large-path/spec.md)
- Design log entry: [design-log.md](../001-large-path/design-log.md) (section 2026-10-22 Discovered work: codex-adapters-flaky-check)
