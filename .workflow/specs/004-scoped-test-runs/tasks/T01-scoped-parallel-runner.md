# T01: Scoped and parallel harness runs

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `tests/run-all.sh` can run a chosen set of suites, or every suite minus an excluded set, and runs suites in parallel by default. A caller passes `--only-file F` (suite paths one per line, e.g. `tests/lint/step-list.sh`, the format `run-toolchain.sh` writes to `$WF_TASK_TESTS_FILE`) and `--exclude-file G` (same format). An empty or missing only-file means every suite minus G. `-j N` sets the number of suites run at once; the default is `getconf _NPROCESSORS_ONLN`, falling back to 4; `-j 1` runs serially. Each suite's output is buffered and printed in the usual glob order, so the report reads exactly as today; `-v` prints each suite's full buffered log in that order. The final full harness gets faster; a task's toolchain run drops to its own suites (design-log D3-D9).

**Seam:** The `tests/run-all.sh` CLI (flags, stdout summary lines, exit code 0 / 1 / 2). The new suite drives it as a black box: it copies `run-all.sh` and `tests/lib/common.sh` into a `new_workdir` fixture with small stub suites under `scripts/`, `hooks/`, `lint/` (some pass, one fails, one sleeps to prove parallelism and ordering), so it never recurses into the real harness.

**Acceptance criteria:**

- [ ] `--only-file F` runs exactly the suites F names; a selector may be a repo-relative path (`tests/scripts/x.sh`) and matches the suite file it names.
- [ ] `--exclude-file G` runs every suite except those G names; an empty or missing `--only-file` with `--exclude-file G` runs every suite not in G; both files together run F minus G.
- [ ] A selector in either file that names no suite exits 2 with a message naming it; `--suite` combined with `--only-file` or `--exclude-file` exits 2.
- [ ] With no `-j`, suites run concurrently (proved by stub suites whose combined sleep exceeds the wall time); `-j 1` runs one at a time; `-j` with a non-positive or non-integer value exits 2.
- [ ] Output lines (PASS/FAIL per suite, failure and xfail detail, the summary) appear in glob order and match a `-j 1` run of the same suites, apart from timings; exit codes are unchanged (0 all passed, 1 any failed, 2 prerequisite or unknown suite).
- [ ] The usage header documents the new flags, and `tests/README.md` lists the new suite and flags.
- [ ] `tests/run-all.sh` on the real tree passes, and is reported with its wall time next to a `-j 1` run's.

**Predicted files:** `tests/run-all.sh`, `tests/scripts/run-all-selection.sh` (new suite), `tests/README.md`.

**Phase 1 tests:** None.

**Size:** S (3 files, about 150 changed lines).

**Mode:** afk.

**Notes:** Bash 3.2: no `wait -n`, no associative arrays, no `mapfile`; a job-slot loop over background PIDs works. No new dependencies. The runner must not read any `WF_*` variable (D4). The `test_scoped` profile line is not part of this task; it is proposal P1-P3 in [../proposals.md](../proposals.md) for 5.3.
