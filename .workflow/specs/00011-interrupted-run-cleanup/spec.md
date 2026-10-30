---
status: draft # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/00011-interrupted-run-cleanup # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: true # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 004-scoped-test-runs-disc-002.md
budget: {max_tasks: 10, max_changed_files: 30}
---

# Interrupted harness runs clean up their background suites

## Why

Origin: 004-scoped-test-runs-disc-002.md, interrupted harness runs leave background suites running.

When `tests/run-all.sh` is interrupted (Ctrl-C, a kill or a closed terminal), its EXIT trap removes the results directory, but the suites it started in the background keep running and writing after the runner has exited. Since 004 made suites run in parallel by default, every interrupted harness run can leave several suites and their child processes behind, still writing into temporary work directories and competing with the next run. An interrupted run must end cleanly: nothing it started keeps running, and the caller sees the conventional signal exit code. A run that is not interrupted stays exactly as it is.

## Capabilities

- **CAP-001** Scoped and parallel harness runs (changed: interrupted runs stop their suites)
  - **intent:** A developer or script can stop a harness run with INT, TERM or HUP and be left with no suite process, or child of one, still running.
  - **success:** In `tests/scripts/run-all-selection.sh`, for each of INT, TERM and HUP sent to a fixture runner while a stub suite runs, the runner exits 130, 143 or 129, the stub suite and its child `sleep` are no longer alive, and the results directory is gone; the existing checks of an uninterrupted run still pass unchanged.

## Constraints

- bash 3.2 built-ins and macOS base tools only; no new required binary (`.workflow/rules.md` § Required versions; D1).
- An uninterrupted run's output, order and exit codes (0, 1, 2) do not change: `set -m` is on only around each suite's background launch, so no job notices are printed (D1).
- Each suite runs in its own process group; a handled signal stops every running suite's group with TERM, waits up to 2 s, then KILLs the groups still alive, and ignores further handled signals while it cleans up (D1, D2, D3).
- The suite tests the runner from its fixture copy against stub suites, never the real harness (`tests/scripts/run-all-selection.sh:15-22`).

## Non-goals

- Cleaning up after SIGKILL of the runner (it cannot be trapped).
- Changing individual suites' own cleanup traps (`tests/lib/common.sh:114`).
- Printing a partial summary when a run is interrupted.
- A signal that arrives before any suite has started keeps today's behaviour.

## Success signal

Pressing Ctrl-C (or sending TERM or HUP) during a parallel harness run returns the prompt with the signal's exit code, and `ps` shows no suite process from that run; an uninterrupted run prints exactly what it printed before.

## Assumptions

- A suite tool that daemonises or calls `setsid` would escape the group kill; no current suite was checked for one (`codebase-map.md` § Library options, Risks).

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Tasks: [tasks.md](tasks.md)
