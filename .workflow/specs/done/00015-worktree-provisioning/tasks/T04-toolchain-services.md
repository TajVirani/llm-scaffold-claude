# T04: Toolchain run starts services

Index: [../tasks.md](../tasks.md) · Blocked by: T3 Worktree setup script · Parallel with: None

**What to build:** `run-toolchain.sh` refuses to run in a worktree that holds a link back into the repository, hands every key's command the spec's isolation values, and starts the project's services before a test run, so nobody starts an environment by hand. Contract: [data-model.md](../data-model.md) § `run-toolchain.sh`.

**Seam:** the `run-toolchain.sh` command line and its evidence files (`toolchain.txt`, `toolchain.json`), driven by `tests/scripts/run-toolchain.sh`.

**Acceptance criteria:**

- [ ] The link check runs on `--cwd` first; a bad link is exit 1 with the link named, before any key runs.
- [ ] Every key's command gets `WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET`, `WF_MAIN_ROOT` and `WF_SPEC_ROOT` of the spec worktree `--cwd` belongs to; from the main checkout they are `0`, `main`, `0` and the main checkout.
- [ ] `services_up` runs once, in the spec worktree, with the isolation values, before the first `test` or `e2e` key that will actually run; one call serves both keys; from an agent worktree it still runs in the spec worktree.
- [ ] No `services_up` call when `test` is skipped and `e2e` is not asked for, on a `--reuse` hit, or with `--reuse-check`.
- [ ] The `services_up` run is recorded in the evidence like a key. A failing one fails the run, its output is in the evidence, and the keys that need services do not run.
- [ ] `services_down` is never run here.
- [ ] With no `services_up` declared the evidence and exit codes are what they are today.
- [ ] `tests/run-all.sh --suite scripts/run-toolchain` passes whole.

**Predicted files:** `.agents/skills/feature-workflow/scripts/run-toolchain.sh`

**Phase 1 tests:** `tests/scripts/run-toolchain.sh`

**Size:** M (1 file, about 160 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** Get the link check and the isolation values by calling `worktree-setup.sh check` and `worktree-setup.sh env`; do not compute them again. The stop-audit hook calls this script with `--reuse` in agent worktrees, so a service start can happen inside a hook's run: keep its output out of stdout.
