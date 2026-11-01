# T01: Stop background suites when the runner is interrupted

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** When `tests/run-all.sh` receives INT, TERM or HUP while suites are running, it stops every suite it started, children included, removes its results directory and exits with the signal's conventional code (130, 143, 129). A run that is not interrupted behaves exactly as today.

- Each suite starts in its own process group: switch job control on (`set -m`) only around the background launch in `start_suite`, and off right after, so no job notices reach the output (D1).
- On a handled signal: ignore further INT/TERM/HUP, send TERM to the process group of every suite still running, wait up to 2 s for them to exit, KILL the groups still alive, remove the results directory, exit 130 / 143 / 129 (D2, D3).
- Bash 3.2 built-ins and macOS base tools only.

**Seam:** the runner's command line and exit code, driven by `tests/scripts/run-all-selection.sh` against its fixture copy of the runner (`run_all`, `tests/scripts/run-all-selection.sh:49-52`) and stub suites (`stub_suite`, `:27-41`).

**Acceptance criteria:**

- [ ] For each of INT, TERM and HUP sent to the fixture runner while a stub suite runs, the runner exits 130, 143 and 129 respectively (D3).
- [ ] After that exit, neither the stub suite's process nor its child `sleep` (a grandchild of the runner, its pid recorded by the stub) is alive (D1, D2, D4).
- [ ] After that exit, the runner's results directory is gone; the case finds it through a `TMPDIR` inside the suite's work dir (D4).
- [ ] The INT case starts the fixture runner where SIGINT is not ignored on entry (a non-interactive background job ignores it), so the check proves the trap and not an inherited ignore.
- [ ] Every existing check in `tests/scripts/run-all-selection.sh` still passes unchanged, including the output-identity and concurrency checks: an uninterrupted run prints exactly what it printed before (no job notices).
- [ ] `tests/scripts/run-all-selection.sh` header `# Covers:` names the interrupt cases; the runner's usage text or header mentions the signal exit codes.

**Predicted files:** `tests/run-all.sh`, `tests/scripts/run-all-selection.sh`

**Phase 1 tests:** None.

**Size:** S (2 files, about 100 changed lines).

**Mode:** afk.

**Notes:** None. Facts checked on /bin/bash 3.2.57 (design-log.md, Questioning round 1): `set -m` gives a background job its own process group and `kill -TERM -- -PGID` stops its grandchildren; `set -m` left on prints `[1]+ Done` notices, switched off right after the launch it prints nothing; a bash EXIT trap runs when the shell is killed by TERM.
