# 1.4 Known-bad build: Phase 1 suites against the merged HEAD

Spec: 001-large-path · Step 1.4 · 2026-10-22

## Run 1: the baseline is the first known-bad build

- Fault: none injected. The feature does not exist yet: HEAD `78cc479` is the baseline `f7a4b23`, the Tier A commit and the merge of `phase-1-test-harness` (suites, fixtures and interface stubs). `initiative-transition.sh` is a stub that exits 0 and writes nothing; no `6.x` rows, no `research` task type, no initiative lines in the session-start hook.
- Where: a detached throwaway worktree at HEAD, removed afterwards.
- Command: `tests/run-all.sh -v` (the `test` key of `.workflow/profiles/test-harness.md`, verbose); full output in `harness.log` beside this file.
- Exit code: 1. `TOTAL passed=2088 failed=93 skipped=0 xfail=0 (31 suites)`.
- Reference run on main `b2e2c86` before Phase 1 (23 suites): `TOTAL passed=1989 failed=0`. Those 23 suites still pass here, except `lint/step-list` and `scripts/step-progress`, which 1.2 extended and which fail only on their new JRN-007 assertions.
- Every new suite reached its `RESULT` line. Every failure is a `FAIL` line from `t`, `eq` or `check`, so an assertion failure; none is a missing file, a sourcing error, a `preflight` exit or a crash.
- Assertions that pass on this build are the suites' own replay of the module steps (for example "the spec folder is gone" after the suite's `git` replay) and regression guards on unchanged behaviour ("phase 0 row still prints Phase 1 of 6"). Every journey still has failing assertions on the behaviour the feature must add.

Verdict: pass. Both conditions of 1.4 hold for the harness: red on a known-bad build, red on assertions.

## Run 2: injected fault for the browser suite

Not applicable. The project has no e2e work type and no browser suite; every journey is a harness suite (discovered work `no-e2e-work-type`, dismissed 00.25 No on 2026-10-22, see `design-log.md`).

## Run 3: StrykerJS on the harness

Skipped, and said so here: the stack is bash, StrykerJS is a JavaScript mutation tool and is not installed. The feature changes no existing JavaScript behaviour.

## Failing assertions per suite (each with its detail line)

### scripts/initiative-conversion
RESULT passed=25 failed=3 skipped=0 xfail=0
- FAIL JRN-001 the initiative marker names the entry step  ->  got= want=6.1
- FAIL JRN-001 the offer lists the initiative once  ->  got=0 want=1
- FAIL JRN-001 the offer shows the initiative exploring at the entry step  ->  (no detail)

### scripts/initiative-transition
RESULT passed=13 failed=26 skipped=0 xfail=0
- FAIL JRN-002 a decision question cannot be researching  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 a question cannot be settled without a settled line  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 IQ1 is researching  ->  got=open want=researching
- FAIL JRN-002 IQ1 launched names the research task type  ->  got=null want=research
- FAIL JRN-002 IQ1 launched records when  ->  null
- FAIL JRN-002 the next session's offer lists the initiative once  ->  got=0 want=1
- FAIL JRN-002 the offer shows one pending research question  ->  (no detail)
- FAIL JRN-002 a researching question cannot be launched again  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 IQ1 is settled  ->  got=open want=settled
- FAIL JRN-002 IQ1 settled line is the source  ->  got=null want=https://example.org/storage-survey#formats
- FAIL JRN-002 frontier 2 is IQ2 and IQ3  ->  got=IQ1 IQ3 want=IQ2 IQ3
- FAIL JRN-002 after the write-back no research is pending  ->  (no detail)
- FAIL JRN-002 a settled question cannot be launched  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 a slice cannot be emitted without its spec  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 a slice cannot be emitted while its questions are open  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 a planned slice cannot carry a spec  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 a planned slice cannot jump to done  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 planned is refused while questions are open  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 done is refused from exploring  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-002 step writes the initiative marker  ->  got=6.1 want=6.2
- FAIL JRN-002 set-pr records merge_pr  ->  got=null want=https://github.com/o/r/pull/7
- FAIL JRN-002 an unknown subcommand is a usage error  ->  rc=0 want=1: 
- FAIL JRN-002 a missing initiative folder is an environment error  ->  rc=0 want=1: 
- FAIL JRN-002 a folder outside .workflow/initiatives is a usage error  ->  rc=0 want=1: 
- FAIL JRN-002 an unknown question id is a usage error  ->  rc=0 want=1: 
- FAIL JRN-002 set-pr with a value that is not a URL is a usage error  ->  rc=0 want=1: 

### scripts/initiative-emission
RESULT passed=15 failed=7 skipped=0 xfail=0
- FAIL JRN-003 every question of S1 is settled  ->  got=open open want=settled settled
- FAIL JRN-003 the Origin entry carries the binding decisions  ->  # Design log: Core flow
- FAIL JRN-003 the spec validator names the initiative key  ->  (.status | test("^(draft|ready-for-dev|in-progress|in-review|done|blocked)$")) and
- FAIL JRN-003 the spec validator rejects an initiative that is not a string  ->  (no detail)
- FAIL JRN-003 the spec template documents the initiative key  ->  (no detail)
- FAIL JRN-003 S1 is emitted  ->  got=planned want=emitted
- FAIL JRN-003 S1 names its spec  ->  got=null want=002-core-flow

### scripts/initiative-merge
RESULT passed=17 failed=18 skipped=0 xfail=0
- FAIL JRN-005 the initiative is planned  ->  got=exploring want=planned
- FAIL JRN-005 local: main carries the planned initiative  ->  got=exploring want=planned
- FAIL JRN-005 done is refused while a slice is not done  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 done: main carries the done initiative  ->  got=exploring want=done
- FAIL JRN-005 done: every slice on main is done  ->  got=emitted emitted want=done done
- FAIL JRN-005 after done, status exploring exits 2  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 after done, status planned exits 2  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 after done, step exits 2  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 after done, set-slice exits 2  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 after done, set-question exits 2  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 after done, set-pr exits 2  ->  rc=0 want=2 with a reason on stderr: 
- FAIL JRN-005 pr dry run exits 0  ->  got=1 want=0
- FAIL JRN-005 pr dry run prints the gh command with head and base  ->  open-task-pr.sh: unknown option: --head
- FAIL JRN-005 pr dry run prints the title  ->  (no detail)
- FAIL JRN-005 pr: the PR URL is printed  ->  got= want=https://github.com/o/r/pull/21
- FAIL JRN-005 pr: the initiative branch is pushed  ->  (no detail)
- FAIL JRN-005 pr: --record writes merge_pr  ->  got=null want=https://github.com/o/r/pull/21
- FAIL JRN-005 pr dry run on GitLab prints the glab command with source and target  ->  open-task-pr.sh: unknown option: --head

### scripts/resolve-launch-initiative
RESULT passed=4 failed=9 skipped=0 xfail=0
- FAIL JRN-008 --requirements lists research  ->  cache-regeneration, fact-lookup, implementation, integration, library-evaluation, module-audit, profile-mini-review, retrieval, review-end-state, review-standards, review-targets, standards-discovery
- FAIL JRN-008 research requires spec_dir  ->  got=null want=["spec_dir"]
- FAIL JRN-008 research carries no profile  ->  got=null want=none
- FAIL JRN-008 --requirements --task-type research exits 0  ->  rc=2 want=0: resolve-launch.sh: unknown task type 'research' (known: cache-regeneration, fact-lookup, implementation, integration, library-evaluation, module-audit, profile-mini-review, retrieval, review-end-state, review-standards, review-targets, standards-discovery)
- FAIL JRN-008 the research launch resolves  ->  got=2 want=0
- FAIL JRN-008 the research launch returns a model  ->  resolve-launch.sh: unknown task type 'research' (known: cache-regeneration, fact-lookup, implementation, integration, library-evaluation, module-audit, profile-mini-review, retrieval, review-end-state, review-standards, review-targets, standards-discovery)
- FAIL JRN-008 the research prompt keeps the header first and the body  ->  resolve-launch.sh: unknown task type 'research' (known: cache-regeneration, fact-lookup, implementation, integration, library-evaluation, module-audit, profile-mini-review, retrieval, review-end-state, review-standards, review-targets, standards-discovery)
- FAIL JRN-008 the resolved header names the initiative folder  ->  got= want=.workflow/initiatives/001-storage-overhaul
- FAIL JRN-008 a fact-lookup launch from an initiative folder resolves  ->  got=2 want=0

### hooks/session-start-initiatives
RESULT passed=4 failed=10 skipped=0 xfail=0
- FAIL JRN-004 the offer lists the branch-only initiative once  ->  got=0 want=1
- FAIL JRN-004 the branch-only line shows status exploring  ->  (no detail)
- FAIL JRN-004 the branch-only line shows the current step  ->  (no detail)
- FAIL JRN-004 the branch-only line shows one pending research question  ->  (no detail)
- FAIL JRN-004 the offer names the large path for resuming  ->  (no detail)
- FAIL JRN-004 after the merge the offer lists the initiative once, from main  ->  got=0 want=1
- FAIL JRN-004 the main line shows status planned  ->  In-flight features in this project (from .workflow/specs/*/spec.md frontmatter; status and .step are written only by status-transition.sh):
- FAIL JRN-004 the main line shows the current step  ->  In-flight features in this project (from .workflow/specs/*/spec.md frontmatter; status and .step are written only by status-transition.sh):
- FAIL JRN-004 the main line shows no pending research  ->  In-flight features in this project (from .workflow/specs/*/spec.md frontmatter; status and .step are written only by status-transition.sh):
- FAIL JRN-004 an initiative on main and on its branch is listed once  ->  got=0 want=1

### hooks/initiative-write-guards
RESULT passed=7 failed=5 skipped=0 xfail=0
- FAIL JRN-006 the initiative marker is at the read-only step  ->  got=6.1 want=6.2
- FAIL JRN-006 initiative.md at a 6.x step that does not write it is denied  ->  decision=allow want=deny reason=
- FAIL JRN-006 initiative.md from a sub-agent is denied  ->  decision=allow want=deny reason=
- FAIL JRN-006 the initiative .step is never written by Write  ->  decision=allow want=deny reason=
- FAIL JRN-006 glossary at another 6.x step is denied  ->  decision=allow want=deny reason=

### hooks/codex-pre-spawn-initiative
RESULT passed=6 failed=4 skipped=0 xfail=0
- FAIL JRN-008 research is a workflow task type  ->  (no detail)
- FAIL JRN-008 research s001_research is denied with a reason  ->  rc=0 out=
- FAIL JRN-008 research i002_research (no such initiative) is denied  ->  rc=0 out=
- FAIL JRN-008 fact_lookup i009_fact_lookup (no such initiative) is denied  ->  rc=0 out=

### lint/step-list
RESULT passed=28 failed=6 skipped=0 xfail=0
- FAIL JRN-007 phase row P6 is phase 6  ->  got= want=6/phase
- FAIL JRN-007 steps.tsv has large-track rows  ->  (no detail)
- FAIL JRN-007 the conversion node is a phase 0 step on both paths  ->  got= want=0/both
- FAIL JRN-007 the reference names the conversion node  ->  (no detail)
- FAIL JRN-007 the reference has a Phase 6 section  ->  (no detail)
- FAIL JRN-007 check-write.sh step lists name 6.x steps  ->  (no detail)

### scripts/step-progress
RESULT passed=47 failed=5 skipped=0 xfail=0
- FAIL JRN-007 steps.tsv has large-track rows  ->  (no detail)
- FAIL JRN-007 the first large row prints the large form  ->  got= want=Large path · step 1 of 0 —  (6.1)
- FAIL JRN-007 the last large row prints the large form  ->  got= want=Large path · step 0 of 0 —  (6.1)
- FAIL JRN-007 the conversion node prints as a Discovery step on the full path  ->  (no detail)
- FAIL JRN-007 the conversion node prints as a Discovery step on the light path  ->  (no detail)


## Run 3 (2026-10-22, re-entry after the 4.6 loop back): JRN-005 step 5

- Fault: the baseline for the new step is the merged spec branch at 1a2718a, where 6.13's replay (`close_check`) still returns early on an existing `origin/initiative/*` ref; the D33 rule is not built.
- Command: `tests/run-all.sh --suite scripts/initiative-merge` in a detached scratch worktree at HEAD; log [run-3-initiative-merge.log](run-3-initiative-merge.log).
- Exit 1. New checks and their first error, both assertions:
  - FAIL JRN-005 under pr the stale remote branch does not stop the done flip -> `rc=0 branch=main status=planned`
  - FAIL JRN-005 under pr the done flip marks every slice done -> `got=emitted emitted want=done done`
- The three new setup checks (main at `planned`, the merged branch still on origin, the branch on origin reads `planned`) pass; every other check in the suite passes (61 of 63).
