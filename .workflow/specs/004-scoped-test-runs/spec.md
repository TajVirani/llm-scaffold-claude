---
status: done # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "f8ea802e8efa7f56499a2743930887986e1ec020" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/004-scoped-test-runs # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "f8ea802e8efa7f56499a2743930887986e1ec020" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: true # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/browser-suite.md, .workflow/deferred/per-task-scoped-runs.md, .workflow/deferred/concurrency-check-timing.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 001-large-path-disc-001.md
budget: {max_tasks: 10, max_changed_files: 30}
---

# Scoped test runs for the harness profiles

## Why

Origin: 001-large-path-disc-001.md, the toolchain cannot scope the harness to a task. Every implementation agent on this repo runs the whole `tests/run-all.sh` harness (about 6 minutes, suites one at a time) at 3.5 and again in the stop audit, because no work profile has a `test_scoped` command and the runner selects only one suite at a time. On 001-large-path that cost 25 to 30 minutes and much of the ~100k tokens per agent. The runner should run only a task's own suites when asked, and run the full harness, which still runs once after every task is done, in parallel, so a task's test cost drops from minutes to seconds and the final full run to about two minutes.

## Capabilities

- **CAP-001** Scoped and parallel harness runs
  - **intent:** The toolchain can run only a task's own suites, or every suite minus the unfinished tasks' suites, and a full run uses every core.
  - **success:** `tests/run-all.sh --only-file F --exclude-file G` runs exactly the suites F names (or, F empty, every suite not in G), exits 2 on a selector that names no suite, and a default run executes suites in parallel with the same summary lines, order and exit codes as `-j 1`; the new suite proves each case.

## Constraints

- Bash 3.2, no new dependencies (`.workflow/rules.md` § Required versions).
- `tests/` stays independent of the workflow contract: the runner reads flags, never `WF_*` variables (D4).
- Output stays in suite (glob) order and the exit-code contract (0 pass, 1 a suite failed, 2 prerequisite or unknown suite) is unchanged (D7, D9).
- Existing profiles change only at 5.3: the `test_scoped` line is a proposal in [proposals.md](proposals.md).
- `--suite` combined with `--only-file` or `--exclude-file` exits 2; the default job count is `getconf _NPROCESSORS_ONLN`, falling back to 4 (assumptions confirmed in the build and checked by `tests/scripts/run-all-selection.sh`).

## Non-goals

- Speeding up `tests/scripts/install.sh` or `tests/scripts/status-transition-check-write.sh` themselves.
- Any change to `run-toolchain.sh`.
- Counting suites a task added or changed as its own (D6).
- Spec B: the stop audit's duplicate toolchain run and the brief wording.

## Success signal

On 001-large-path's next wave, an implementation agent's 3.5 toolchain and stop audit run only its task's suites in seconds, and the last-wave full run of `tests/run-all.sh` finishes in about two minutes instead of six.

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
