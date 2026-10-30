# Design log: Interrupted harness runs clean up their background suites

Spec: [spec.md](spec.md)

## 2026-10-30 Origin: 004-scoped-test-runs-disc-002.md

- Work item: 004-scoped-test-runs-disc-002.md
- Origin spec and step: .workflow/specs/004-scoped-test-runs, step 3.7
- Problem: When `tests/run-all.sh` is interrupted (Ctrl-C or a kill), its EXIT trap removes the results directory, but suites started in the background are not stopped: they keep running and writing after the runner has exited.
- Evidence:
  - `tests/run-all.sh:157` (trap `rm -rf` of the results directory), `tests/run-all.sh:167-176` (`start_suite` runs each suite in a background subshell). At HEAD 58019c8 these are `tests/run-all.sh:171` and `:183-192`.
  - T1 profile-mini-review return, `out_of_scope_noticed` (kind bug), `.workflow/specs/004-scoped-test-runs/artifacts/T1/mini-review.yaml`. Not reproduced by a run.
- Why not a blocker (from the item): a normal run waits for every suite, so CAP-NEW-scoped-test-runs and every completed run are unaffected; only an interrupted run leaks processes.
- Suggested scope and size (from the item): on INT/TERM, kill the background suite process groups before removing the results directory, and exit 130/143; add a check to `tests/scripts/run-all-selection.sh`. One task, two files.

## 2026-10-30 Reframe: change to CAP-001

The goal changes an existing capability: CAP-001 (scoped and parallel harness runs, `.workflow/capabilities.md`). The spec keeps CAP-001; no new capability. Owning module is clear: every touched path is under `tests` (`.workflow/rules.md` § Ownership), so no placement ADR (0.3.3 Yes).

## 2026-10-30 Deeper prompt

**What this changes:** On Ctrl-C or a kill, `tests/run-all.sh` stops every background suite and its child processes, removes its results directory and exits 130 (INT) or 143 (TERM).

**Why:** Today an interrupted run leaves suites running and writing after the runner has exited.

**Ask:** Make an interrupted harness run end cleanly: when the run is stopped, nothing it started keeps running, and the caller sees the conventional signal exit code.

**Goals:**
- After INT or TERM reaches the runner, no suite process it started (nor any child of one) is still alive.
- The runner exits 130 on INT and 143 on TERM, and its results directory is gone.
- A run that is not interrupted keeps exactly today's output, order and exit codes (0/1/2).
- `tests/scripts/run-all-selection.sh` proves the interrupt behaviour against stub suites, never the real harness.

**Downstream:** none known.

**Tools and technologies:** bash 3.2 built-ins and macOS base tools only (job control or ps/pkill); no new dependency.

**Gotchas:** A non-interactive bash ignores SIGINT in background jobs, and a signal ignored on entry cannot be trapped, so the suite case must start the runner where INT is deliverable. A normal run's output and exit codes must not change.

**Not asked for:** cleaning up after SIGKILL of the runner (untrappable); changes to individual suites' own cleanup traps; a partial summary printed on interrupt.

**Original request:** "on INT/TERM, kill the background suite process groups before removing the results directory, and exit 130/143; add a check to `tests/scripts/run-all-selection.sh`." (the backlog item's Suggested scope)

Revisions: agreed as first restated.

## 2026-10-30 Questioning round 1

**Q1. How does the runner stop a suite and its children?**

- Why now: the deeper prompt fixes the goal (nothing the run started stays alive); the mechanism is the root decision.
- Options: A: one process group per suite (`set -m` on only around the `&` launch), kill the group on a signal · B: walk the tree with `pgrep -P` (misses reparented children)
- Recommended: A, because it reaches grandchildren and matches the in-repo pattern (`codebase-map.md` § Library options; `.agents/agents/review-targets.md:56`, `:100`)
- Answer: "Process groups (Recommended)"
- Decision: **D1** Each suite starts in its own process group, with `set -m` switched on only around the background launch; a handled signal kills every running suite's group.

**Q2. In what order does the runner stop the suites?**

- Why now: follows D1.
- Options: A: TERM to every group, wait up to 2 s, KILL what is left, ignore further INT/TERM/HUP while cleaning up · B: KILL at once (suites' temp dirs left behind)
- Recommended: A, because suites' EXIT traps (`tests/lib/common.sh:114`) then remove their work dirs and a stuck suite cannot hang the runner
- Answer: "TERM, 2 s, KILL (Recommended)"
- Decision: **D2** On a handled signal: ignore further handled signals, TERM every suite group, wait up to 2 s for them to exit, KILL the groups still alive, remove the results directory, exit with the signal's code.

**Q3. Is HUP handled too?**

- Why now: D1 moves suites out of the runner's process group, so a closed terminal no longer reaches them directly.
- Options: A: trap HUP too, exit 129 · B: INT and TERM only, accept the closed-terminal gap
- Recommended: A, because without it D1 would regress the closed-terminal case
- Answer: "Yes, trap HUP too (Recommended)"
- Decision: **D3** INT, TERM and HUP are handled alike; exit codes 130, 143 and 129.

**Q4. How does the suite prove it?**

- Why now: follows D1-D3.
- Options: A: one case per handled signal against a stub suite whose child `sleep` records its pid; assert the exit code, that the suite and its `sleep` are gone, and that the results dir (found through a TMPDIR inside the work dir) is gone; INT sent to a runner started where INT is not ignored · B: TERM only
- Recommended: A, because a check on the suite pid alone passes while the grandchild survives (`codebase-map.md` § Library options, Risks)
- Answer: "Per-signal checks (Recommended)"
- Decision: **D4** `tests/scripts/run-all-selection.sh` gets one interrupt case per handled signal, asserting on the grandchild `sleep`, the exit code and the results dir; the existing output-identity checks keep guarding the uninterrupted run.

Facts looked up instead of asked (main session, /bin/bash 3.2.57 on this machine):
- `set -m` in a non-interactive script gives a background job its own process group, and `kill -TERM -- -PGID` stops its grandchildren.
- With `set -m` left on, bash prints `[1]+ Done ...` job notices to the output; switched off right after the launch, nothing is printed and the job keeps its own group.
- A bash EXIT trap runs when the shell is killed by TERM.
