---
cache_stamps:
  modules: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
  flows: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
  architecture: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
---

# Codebase map: Interrupted harness runs clean up their background suites

Affected area: module `tests` (owns `tests/**`): `tests/run-all.sh`, `tests/scripts/run-all-selection.sh`, `tests/lib/common.sh` (read only).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Runner CLI | Parses repeated `--suite`, `--only-file`, `--exclude-file`, `-j N`, `--list`, `-v`/`--verbose`, `-h`; unknown argument exits 2 | `tests/run-all.sh:42-77` |
| Flag conflicts and names | `--suite` with `--only-file` or `--exclude-file` exits 2; an unknown `--suite` name exits 2 | `tests/run-all.sh:78-80`, `:103-109` |
| Suite discovery | Every file matched by `scripts/*.sh`, `hooks/*.sh`, `lint/*.sh` under `tests/`; label `<dir>/<name>` | `tests/run-all.sh:82-88` |
| Selector files | One path or label per line; unknown selector exits 2; `--suite` wins, else only-list minus exclude-list | `tests/run-all.sh:111-127`, `:143-157` |
| Prerequisites | `preflight` (bash 3.2+, git, jq, yq v4) exits 2; missing shellcheck exits 2 after selection | `tests/run-all.sh:164-168`; `tests/lib/common.sh:77-96` |
| Default job count | `default_jobs`: `getconf _NPROCESSORS_ONLN`, else 4; at most `$jobs` suites in flight | `tests/run-all.sh:26-33`, `:39`, `:274-278` |
| Start and report order | Suites start largest file first; reports print in glob index order, polling `.done` files every 0.1 s | `tests/run-all.sh:263-285` |
| Results directory and EXIT trap | `mktemp -d` under `${TMPDIR:-/tmp}`; `trap 'rm -rf "$results"' EXIT` is the only trap | `tests/run-all.sh:170-171` |
| Suite launch | Each suite is `bash FILE` in a background subshell, output to `N.log`; rc and seconds to `N.tmp`, renamed to `N.done` | `tests/run-all.sh:183-192` |
| Per-suite report | Counts from the last `^RESULT ` line; no footer = failure with its log indented; non-zero rc marks FAIL | `tests/run-all.sh:203-240` |
| Output detail | Default shows `FAIL`, `xfail`, `skip` lines and indented detail; `-v` shows full logs and a `== failures` block | `tests/run-all.sh:210-214`, `:245-259`, `:292-304` |
| Selector temp file | `mktemp` at :132, before the EXIT trap is set (:171); removed at :141 and on the error exits :134, :138 | `tests/run-all.sh:132-141` |
| Final wait | `wait` after the report loop | `tests/run-all.sh:286` |
| Shared helpers | `ok`, `ko`, `skip`, `xfail`, `t`, `eq`, `check` (eval), `finish` (RESULT footer, exit by failures) | `tests/lib/common.sh:31-74` |
| Shared env helpers | `preflight`, `have_shellcheck`, `shellcheck_files`, `new_workdir` (mktemp plus `trap "rm -rf" EXIT`), `make_fixture_repo` and others | `tests/lib/common.sh:77-148` |
| Selection suite fixture | Copies `run-all.sh` and `lib/common.sh` into `$WORK/repo/tests` and runs that copy, never the real harness | `tests/scripts/run-all-selection.sh:15-22` |
| Stub suites | alpha (sleep 2), beta (sleep 2), gamma (1 fail), delta; each writes epoch `.start` and `.end` to `$MARKERS` | `tests/scripts/run-all-selection.sh:27-46` |
| Concurrency checks | Default run must show alpha/beta interval overlap; `-j 1` none; no elapsed-time limit | `tests/scripts/run-all-selection.sh:138-159` |
| Interrupt handling | None: no INT, TERM or HUP trap and no kill of background suites | `tests/run-all.sh:171`, `:183-192`, `:286` |
| Suite coverage list | Header lists selection, -j, order, -v, exit codes; no interrupted-run case | `tests/scripts/run-all-selection.sh:2-9` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| Runner command line | `tests/run-all.sh [-v] [-j N] [--suite NAME]... [--only-file F] [--exclude-file G] [--list] [-h]`; exit 0 all pass, 1 a suite failed, 2 usage or prerequisite | Operators; `run-all-selection.sh` `run_all` (`:49-52`); profile `test` / `test_scoped` keys | `tests/run-all.sh:3-17`, `:303-305` |
| Suite output contract | `ok`/`FAIL`/`xfail`/`skip` lines, then `RESULT passed=N failed=N skipped=N xfail=N` | Every suite via `finish`; runner at `:215` | `tests/lib/common.sh:69-74`; `tests/run-all.sh:215` |
| Suite exit status | Non-zero marks FAIL regardless of counts | Runner | `tests/run-all.sh:187-188`, `:229-230` |
| `new_workdir` | Sets exported `WORK` and an EXIT trap | Suites, e.g. `tests/scripts/run-all-selection.sh:15` | `tests/lib/common.sh:110-116` |
| Stub marker files | `$MARKERS/<name>.start` and `.end` hold epoch seconds | `alpha_beta_overlap` | `tests/scripts/run-all-selection.sh:27-41`, `:138-144` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| CAP-001 Scoped and parallel harness runs | Runs the selected suites in parallel by default with the same report as a serial run | `.workflow/capabilities.md` § CAP-001 |
| ADR-0001 project baseline | CI deferred; `tests/run-all.sh` run by hand is the gate | `.workflow/decisions/adr/0001-project-baseline.md` § Deferred |
| Pitfall: never overlap a 3.9 gate with an agent's full-harness run | Wall-clock concurrency assertion failed under load; the current suite uses interval overlap | `.workflow/decisions/pitfalls.md` § Never overlap a 3.9 gate with an agent's full-harness run |
| Retrospective 004: interrupted run leaves suites running | Found by the T1 mini-review, kept open in the work backlog | `.workflow/decisions/retrospectives/004-scoped-test-runs.md` § Findings |
| Rules, required versions | bash 3.2 only, no bash 4 constructs; shellcheck for tests and lint | `.workflow/rules.md` § Required versions |
| Rules, ownership | `tests` owns `tests/**`; `.agents/lib/**` is shared core | `.workflow/rules.md` § Ownership, § Shared core |
| Rules, cross-cutting | Nothing in `.agents/` depends on `tests/`; tests run from a fixture copy | `.workflow/rules.md` § Cross-cutting policy |
| Deferred `concurrency-check-timing.md` | Different concept (timing assertions); already resolved at HEAD per its own Later requests | `.workflow/deferred/concurrency-check-timing.md` |
| Deferred `per-task-scoped-runs.md`, `harness-run-lint-target.md`, `comment-id-lint.md`, `browser-suite.md` | Related to the runner; none covers interrupt handling | `.workflow/deferred/` (each file) |

## Library options

### Process stop on INT/TERM

Verdict: Use existing. Bash built-ins (`trap`, `kill`, `$!`) with one process group per suite from `set -m`, the pattern `.agents/agents/review-targets.md:56` and `:100` already use (start in a group; stop with TERM to the group, then KILL after a wait). Adopt no library; reject `timeout`/`gtimeout`/`setsid` as new required binaries.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| bash built-ins + `set -m` process group (incumbent pattern) | caution: POSIX defines negative-pid group kill; bash 3.2 not run by the agent | pass | caution: stock /bin/bash 3.2.57 may be dropped by Apple | unknown; no third-party code | pass: 0 deps |
| Do nothing | fail: background jobs ignore INT when job control is off | pass | pass | pass | pass, leaves the bug |
| Walk the tree with `ps` / `pgrep -P` | caution: orphans reparent before the walk | pass | pass | unknown | caution |
| `timeout` / `gtimeout` | fail: wraps one command; stock macOS lacks it | caution | unknown | unknown | fail: extra install |
| `setsid` | caution: macOS availability unverified; not needed | caution | unknown | unknown | fail: extra install |

Evidence:
- official: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/kill.html (negative pid selects a process group).
- official: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html (async lists without job control).
- official: https://www.gnu.org/software/bash/manual/html_node/Signals.html (search snippet: background commands ignore SIGINT/SIGQUIT when job control is off).
- official: https://gnu.org/software/bash/manual/html_node/The-Set-Builtin.html (search snippet: `set -m` gives separate process groups and prints a status line when a job finishes).
- community: https://mail.gnu.org/archive/html/bug-bash/2015-10/msg00077.html; https://kitemetric.com/blogs/bringing-the-timeout-command-to-macos-without-installing-gnu-coreutils; https://jmmv.dev/2019/11/macos-bash-baggage.html; https://lists.gnu.org/r/groff/2021-10/msg00086.html.
- local: `.workflow/rules.md:149-156`; `tests/lib/common.sh:76-96`; `tests/scripts/install-upgrade.sh:98-113`; `.agents/agents/review-targets.md:53-57, 100`.

Risks (from the return):
- Terminal Ctrl-C reaches only the runner's foreground group, so the runner must forward the stop itself (TERM, then KILL after a short wait).
- `set -m` may print job status lines into the output `run-all-selection.sh:161-176` compares exactly.
- A suite tool that daemonises or calls `setsid` escapes the group kill; no current suite checked.
- The stub's `sleep` is a grandchild of the suite's bash; a check that kills only the suite PID would pass while `sleep` survives.

## Not found

- Interrupted-run cleanup in `.workflow/deferred/`: none of the 21 files match by concept. Reported by retrieval.
- Interrupt, kill or signal handling in `tests/run-all.sh`, `tests/lib/common.sh`, `tests/scripts/run-all-selection.sh`: only the EXIT traps (`run-all.sh:171`, `common.sh:114`) and `wait` (`run-all.sh:286`). Reported by retrieval.
- Flow coverage for the runner: `.workflow/cache/flows.md` has no entry for `tests/run-all.sh`. Reported by retrieval.
- `concurrency-check-timing.md` § Current behaviour describes elapsed limits HEAD no longer has. Reported by retrieval.
- `rules.md` § Required versions cites `tests/run-all.sh:63` for shellcheck; that line is `esac` (shellcheck use is at `:16-17`, `:165-168`). Reported by retrieval.
- Bash 3.2 runtime behaviour of `set -m`, group kill and job notices: not run by library-evaluation; checked by the main session in the questioning loop facts.
