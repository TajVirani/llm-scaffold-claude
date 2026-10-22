# Design log: Scoped test runs for the harness profiles

Spec: [spec.md](spec.md)

## 2026-10-21 Origin: 001-large-path-disc-001.md

- Work item: 001-large-path-disc-001.md
- Origin spec and step: .workflow/specs/001-large-path, step 3.7
- Problem: None of the three work profiles has a `test_scoped` command, and the test runner offers only `--suite NAME`, so the toolchain cannot exclude the Phase 1 tests of tasks that are not yet done. Every task's `test` key is reported unscoped (a warning, not a failure), and the orchestrator judges each run by hand against the known red suites.
- Evidence:
  - `.workflow/specs/001-large-path/artifacts/T1/toolchain.json` warnings: `test_scoped` absent, 10 excluded selectors could not be applied; the same warning in `artifacts/T3`, `artifacts/T8` and `artifacts/T9`.
  - `.workflow/profiles/shell-scripts.md`, `.workflow/profiles/test-harness.md`, `.workflow/profiles/agent-docs.md` § Toolchain: `test_scoped: ""`.
  - `tests/run-all.sh` usage header: `--suite NAME` is the only selector.
  - Reported by the T1 profile-mini-review return (`out_of_scope_noticed`, kind decision) and the T8 profile-mini-review return (kind refactor).
- Stakeholder findings (2026-10-21, quoted in the request): one `tests/run-all.sh` run takes about 6 minutes (`scripts/install` ~125 s, `scripts/status-transition-check-write` ~88 s, the other 29 suites ~2 min together); each implementation agent runs it four to five times (its own regression run, the 3.5 toolchain, the stop audit), so about 25 to 30 minutes per agent.

## 2026-10-21 Intake: split and scope

- D1: The findings split into two light-path specs. This spec (A, `tests` module) covers the runner selector and the profiles' `test_scoped` lines (the lines go to a 5.3 proposal, since existing profiles change only at 5.3). Spec B (`hooks`/`agents`/`feature-workflow`) covers the duplicate toolchain run in the stop audit and the brief wording. The step-list lint loop is not fixed in code: it ends when 001's T2 merges.
- D2: The spec branches off main; once done it is merged into `spec/001-large-path` before 001's next wave.
- D3: `test_scoped` runs only the task's own suites; the full harness runs once, when every task is done. Stakeholder: "Own suites, full check at the end of all tasks being completed." (`run-toolchain.sh:152-155` already falls back to `test` when nothing is excluded, i.e. at the last wave.)

## 2026-10-21 Deeper prompt

- Round 1: stakeholder answered downstream (spec B only), tools (parallel suites, taken into scope), gotchas (3.9 gate empty own set); block agreed with "ready".

**Ask:** Cut one implementation agent's test cost from the 6-minute harness to seconds. `tests/run-all.sh` should run only the task's own suites, and make the full harness, which runs once after every task is done, faster.

**Goals:**
- `run-all.sh` takes a list of suites as path selectors (`tests/lint/step-list.sh`, one per line, as `run-toolchain.sh` writes `$WF_TASK_TESTS_FILE`) and runs only those.
- `run-all.sh` takes an exclude list (`$WF_EXCLUDE_TESTS_FILE`) and runs every suite except those.
- This repo's three profiles get a `test_scoped` command (through a 5.3 proposal): own suites when the task has any; full minus excluded when the own list is empty (the 3.9 wave gate, or a task with no Phase 1 tests).
- Suites run in parallel so a full run finishes well under 6 minutes, with the same pass/fail summary and exit codes as today.
- A suite covers the selector, the exclude list, parallel runs and the exit codes.

**Downstream:** spec B (stop audit stops re-running the toolchain; briefs say "own suites only") relies on `test_scoped` being fast.

**Tools and technologies:** plain bash 3.2, no new dependencies; parallelism with background jobs or `xargs -P`, with a configurable job count.

**Gotchas:** the 3.9 gate calls the toolchain with `--exclude-unfinished` and no task record, and tasks with no Phase 1 tests (T1, T3, T8, T9) have an empty own list: that case must fall back to full-minus-excluded, never "run nothing". Parallel suites need every suite fully isolated (`new_workdir`, own git config and HOME); a suite that writes shared state will flake. Output must be buffered per suite so it does not interleave.

**Not asked for:** speeding up `scripts/install` or `status-transition-check-write` themselves; any change to `run-toolchain.sh`; spec B's stop-audit and brief changes.

**Original request:** "most of the wall time is the full test harness being run over and over… A scoped test command (the `test_scoped` work item), so the toolchain and the stop audit run only the suites a task owns plus a regression subset…" (with the answers "Own suites, full check at the end of all tasks being completed" and parallel suites)

## 2026-10-21 Questioning round 1

- Q1 Interface. Options: flags with files (`--only-file F`, `--exclude-file F`); read the WF_* env vars directly; defer. Recommended: flags (keeps `tests/` free of the workflow contract; mirrors `--suite`, `tests/run-all.sh:4-7`). Answer: "Flags with files (Recommended)". D4: `run-all.sh` takes `--only-file F` and `--exclude-file F`, path selectors one per line.
- Q2 Empty own-list fallback. Options: in `run-all.sh`; in the profile line; defer. Recommended: in `run-all.sh`. Answer: "In run-all.sh (Recommended)". D5: an empty or missing only-file means every suite minus the exclude file; the three profiles share one `test_scoped` line.
- Q3 Suites a task added count as its own? Options: yes via `git diff` against `$WF_IMPL_BASE`; no, Phase 1 list only; defer. Recommended: yes. Answer: "No, Phase 1 list only". D6: own suites are the task record's `tests` list only; new suites are covered by the agent's red/green runs and the final full run.
- Q4 Selector naming no suite. Options: exit 2; warn and skip; defer. Recommended: exit 2. Answer: "Exit 2 (Recommended)". D7: an unknown selector in either file exits 2, as an unknown `--suite` does.
- Facts looked up (fact-lookup): no suite shares state when run concurrently (all temp paths are `mktemp` under `${TMPDIR:-/tmp}`; no `$HOME`, global git config, port or working-tree writes; `tests/lib/common.sh:110-116`, `tests/scripts/install.sh:102-113`). Suites run one at a time as `bash "$f" >"$log" 2>&1`, RESULT footer parsed from the log (`tests/run-all.sh:77-110`). No stored per-suite timings. 33 suite files in the tree. This machine reports 14 cores.

## 2026-10-21 Questioning round 2

- Q1 Parallel default. Options: parallel by default with `-j N` (default core count via `getconf _NPROCESSORS_ONLN`, fallback 4; `-j 1` serial); opt-in `-j`; defer. Recommended: parallel by default (no shared state found in round 1). Answer: "Parallel by default (Recommended)". D8.
- Q2 Output order. Options: suite order, buffered; completion order; defer. Recommended: suite order. Answer: "Suite order (Recommended)". D9: each suite's output is buffered and printed in glob order; `-v` prints each full buffered log in that order.

## 2026-10-22 Light-path test

- D10 (supersedes D2): 001-large-path merged to main before this spec branched ("001 is merged. Continue"), so nothing is merged into `spec/001-large-path`; the fix reaches later specs through main.
- Light path: intent gaps none (Open Questions empty); no irreversible action; footprint one module (`tests`), one capability, three files. `spec/004-scoped-test-runs` created off main; budget 10 tasks / 30 files from `.workflow/rules.md`.

## 2026-10-22 Discovered work: codex-adapters-parallel-flake

- Found at 3.4 by the T1 implementation agent (`artifacts/T1/implementation.yaml`). Kind: bug.
- Problem: `hooks/codex-adapters` "workflow not installed -> silent allow" failed once in a parallel full run; passed alone, in a second parallel run and at `-j 1`. Evidence: `tests/hooks/codex-adapters.sh:146` or `:203`.
- Assessment: can be solved later (CAP-NEW-scoped-test-runs' success line is met). Ruling: "Next feature (Recommended)". Item: [../work-backlog/004-scoped-test-runs-disc-001.md](../work-backlog/004-scoped-test-runs-disc-001.md).

## 2026-10-22 Discovered work: interrupted-run-orphans

- Found at 3.7 by the T1 profile-mini-review (`artifacts/T1/mini-review.yaml`). Kind: bug.
- Problem: an interrupted `tests/run-all.sh` removes its results directory while background suites keep running. Evidence: `tests/run-all.sh:157`, `:167-176`.
- Assessment: can be solved later. Ruling: "Next feature (Recommended)". Item: [../work-backlog/004-scoped-test-runs-disc-002.md](../work-backlog/004-scoped-test-runs-disc-002.md).

## 2026-10-22 Discovered work: timing-check-thresholds

- Found at 3.7 by the T1 profile-mini-review. Kind: refactor.
- Problem: the suite's concurrency checks use fixed wall-clock limits. Evidence: `tests/scripts/run-all-selection.sh:413`, `:419`.
- Assessment: can be solved later. Ruling: "Next feature (Recommended)". Item: [../work-backlog/004-scoped-test-runs-disc-003.md](../work-backlog/004-scoped-test-runs-disc-003.md).

## 2026-10-22 Suite gap: browser suite

- 3.14: no `e2e-browser` profile, so the 3.10-3.11 browser gate was skipped; recorded in [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md). The 3.9 harness gate passed: 2347 passed, 0 failed, 33 suites, 2 min 23 s (`artifacts/gate-3.9-w1/`).
