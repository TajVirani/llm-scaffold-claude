# Phase 1: Verification setup

You build the checks that will prove the feature, and prove that they can fail, before anyone writes feature code; a spec that adds nothing new to prove leaves the tests to its tasks instead ([Tests in tasks](#tests-in-tasks)). You are done when every target in `verification-plan.md` has a threshold and an exact command, `baseline_revision` is set, the harness and the browser suite are merged into the spec branch, both suites have gone **red** on a known-bad build, every new test failing on an assertion, and the Phase 1 work is committed on the spec branch (1.5).

Everything here runs in the main session at spec status `ready-for-dev`. Phase 1 writes no status except `blocked` (1.4, 00.19; 00.21 through `modules/discovered-work.md`). Call the scripts from the project root exactly as written below (from 1.1 on, the project root is the spec worktree that 1.1 creates), with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines). Mark each Phase 1 node as you enter it (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 1.<n>`) so a resumed session returns to it.

**Re-entry.** If you arrive here again after a loop back to 0.3.8 (the spec went `draft` and came back through 0.6), keep what exists: `baseline_revision` is never overwritten, and the suites recorded under `## Suites` in `verification-plan.md` stay. Redo 1.1-1.4 only for targets and journeys that are new or changed since they were built.

## 1.1 Measurable targets and the baseline

If the stakeholder changes scope before 1.1 starts, do not start it: set `draft`, then load the [questioning loop](questioning-loop.md#entry) at 0.3.8 with their change, verbatim, as the first frontier question. The call is refused once 1.1 has started; on exit 2 stop and report the reason.

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 0.6
```

1. **Create the spec worktree and capture the baseline.** All work for this spec lands on the **spec branch** `spec/NNN-slug`, in its own **spec worktree** `.workflow/.spec-worktrees/NNN-slug` inside the main checkout, so the main checkout stays on its branch and other specs can run beside this one; the branch reaches the main branch only at sign-off (5.8). Read `spec_branch` and `baseline_revision` from `spec.md`:

   ```bash
   yq --front-matter=extract '[.spec_branch, .baseline_revision] | @tsv' .workflow/specs/NNN-slug/spec.md
   ```

   When both are empty (`""`), set the step, then create the spec worktree from the checkout discovery ran in:

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 1.1
   .agents/skills/feature-workflow/scripts/spec-worktree.sh create .workflow/specs/NNN-slug
   ```

   It branches `spec/NNN-slug` off the main branch (`rules-setting.sh main_branch`, the PR/MR target), commits the uncommitted spec folder and the rest of discovery's workflow data on it as "Spec NNN-slug", leaves the main checkout on the branch it was on, adds the worktree and moves `.step` into it. It prints `worktree <path>` and `baseline <sha>`, the spec branch's first commit; exit 1 names what to fix first (a merge in progress, a branch that cannot be switched). Then **move the session into the worktree**: on Claude Code call the `EnterWorktree` tool with the printed path; on other hosts ask the stakeholder to reopen the session in that folder, writing a handoff first. From here on every command runs there.

   In the spec worktree, Edit the frontmatter, these two keys only (the guard rejects a status change): `spec_branch: spec/NNN-slug` and `baseline_revision: <the printed sha>`. When they are already set, leave them, and check the session is in the spec checkout on the spec branch (`git branch --show-current`; `spec-worktree.sh create` again prints the worktree of a spec whose branch exists). Every Phase 1 build forks from and merges into this branch.

2. **Fill the Targets table** of `verification-plan.md` (`## Targets`). First, when the handoff's resume or `design-log.md` records that the main branch moved since discovery (a "Main moved since handoff" entry), read the changes it lists in the affected area, and note in `design-log.md` any change to a contract the spec relies on. Cover performance, errors and coverage. Each row needs a threshold, the exact command that measures it, and the source of the threshold: a `spec.md` constraint, a `.workflow/rules.md` line, a stakeholder decision, or an assumption. A threshold the spec and rules do not give takes your recommended value: assume and log it as [conventions](../references/conventions.md#asking-the-stakeholder) says, with what the value rests on (a measurement of the baseline, a comparable target), and write `assumed (design-log.md)` as its source; the breakdown quiz offers it for veto before any feature code is written. A threshold that would change what must be built is a scope question: ask it. A target that cannot be measured stays in the table with the reason in place of the command. A target never names the test harness or its pass count: the 3.9 gate proves the harness passes, so a Targets row measures something else.

**Done when:** the session is in the spec worktree on `spec/NNN-slug`, `spec_branch` names it, `baseline_revision` is the full SHA of its first commit, and every row of `## Targets` has threshold, command (or the reason it cannot be measured) and source.

## Tests in tasks

Decide this after 1.1. A spec that adds no new capability (every capability in `spec.md` is an existing `CAP-###`, none is `CAP-NEW-*`) and needs no new suite (the harness exists, and so does the browser suite when a journey needs one) builds nothing in Phase 1: its implementers write the tests test-first inside their tasks, and 1.4 runs once, on the merged wave.

- Skip the 1.2 and 1.3 launches, and log one line in `design-log.md`: `Phase 1: tests in tasks (no new capability or suite)`.
- Set each journey's Check column in `## Journeys` to `in task`. Task breakdown puts each journey into the acceptance criteria of the task whose capability it proves; no task gets a `tests` list, so the spec branch stays green and every 3.9 gate runs the whole harness.
- 1.4 waits for Phase 3: it runs once after the last wave is merged, before that wave's 3.9 gate (see [1.4](#14-do-both-suites-fail-a-known-bad-build), "Tests in tasks").
- Go to 1.5 now: fill `## Suites`, and leave its 1.4 evidence cells as `after the last wave`.

Any other full-path spec runs 1.2-1.4 as below.

## Launching a Phase 1 build

1.2 and 1.3 are `implementation` launches under a test profile, like any coding task, but before `tasks.md` exists. So the launch header carries `spec_dir` and an explicit `work_type`, with no `task_id`: the one marked exception to looking the work type up by task id. The accepted header shapes come from `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements --task-type implementation`.

````text
```yaml launch-header
task_type: implementation
spec_dir: .workflow/specs/NNN-slug
work_type: test-harness        # e2e-browser for 1.3
```
<the build brief: see 1.2 or 1.3>
````

**The agent worktree.** On both hosts you create the build's worktree yourself before the launch, from the spec checkout, on a `wf/` branch off the spec-branch tip. `<name>` is `s<NNN>_phase_1_<enc(work_type)>`, for example `s007_phase_1_test_harness` (`enc` lowercases and turns every character outside `[a-z0-9]` into `_`); the worktree guard and the stop audit find the worktree by this name:

```bash
git worktree add .workflow/.worktrees/<name> -b wf/NNN-slug/<name> spec/NNN-slug
```

`.workflow/.worktrees/` is gitignored. Name the worktree's absolute path in the brief as the directory the agent works in, and say in every brief: run only the test files you write, never the whole harness, before or after your changes; 1.4 runs it. A resumed or relaunched build reuses the worktree while it exists. The merge removes it, so a 1.4 loop back creates it again with the same command, off a spec-branch tip that already holds the earlier round. 1.3 creates its worktree only after the 1.2 merge, so it starts from the harness.

- **Claude.** Call the Agent tool with `subagent_type: implementation` and the prompt above, as [Claude Code](../references/launching.md#claude-code) says, and confine the agent to its worktree as [An agent worktree on Claude Code](../references/launching.md#an-agent-worktree-on-claude-code) says.
- **Codex.** Build and spawn the launch as [launching](../references/launching.md#codex) says, with `--task-type implementation` and `--work-type` from the header; the `task_name` is the worktree `<name>`.
- **Denied outside its worktree.** An agent that keeps getting denied, or edits the spec checkout through Bash, is never relaunched another way: isolation cannot be configured from this repo, and an isolation launch is refused the result-file write to the spec checkout. Block the spec at its node: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step <1.2 or 1.3> --blocked "phase-1-<work_type> cannot work inside its agent worktree: <the deny>"`.
- **No profile.** A deny that names 00.19 means `.workflow/profiles/<work-type>.md` is missing. Create it with the human from `.workflow/profiles/TEMPLATE.md` (the shipped `test-harness` and `e2e-browser` examples are a starting point): `.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 00.19`, then Write the new profile, then launch again. With no human available, block the spec: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 00.19 --blocked "no <work-type> profile; a human must define .workflow/profiles/<work-type>.md"`.

**When the launch returns.** The stop audit has run the profile toolchain under the evidence id `phase-1-<work_type>`, with the `test` key skipped: the new tests are red by design until the feature is built, and 1.4 is what proves they fail. `lint`, `typecheck`, `format` and `boundary` still run. The agent has written its result block to its result file and returned only a summary block; never retype the block. Check the file:

```bash
.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/phase-1-<work_type>/implementation.yaml
```

Exit 0 prints the status line, the summary and any discovered-work rows; route on them, and read single fields with `yq` (for example `yq '.branch' <file>`). Exit 1, exit 2 for a missing file or YAML that does not parse, or no summary at all: resume the agent once with the checker's lines; a second missing or invalid file blocks the spec at the build's node (`status-transition.sh status .workflow/specs/NNN-slug blocked --step <1.2 or 1.3> --blocked "phase-1-<work_type> wrote no valid result file: <first error line>"`). Exit 2 for a usage error or a missing `jq` or `yq`: fix the cause and run it again. Before resuming the build for another round (a 1.4 loop back), rename the file to `implementation-r<k>.yaml`, `k` being 1 + the count of existing `implementation-r*.yaml` there, so the plain name is the newest round.

Then read the audit evidence in the spec checkout:

- `.workflow/specs/NNN-slug/artifacts/phase-1-<work_type>/toolchain.json` with `"status": "pass"` and no `audit.json` beside it: the audit is clean.
- `audit.json` present (outcome `warning` or `gave-up`), or `toolchain.json` says `fail`: run `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id phase-1-<work_type> --work-type <work_type> --skip test --cwd <worktree>` yourself. Exit 0 counts as clean; exit 1 goes back to the agent with the digest (resume it, for example with SendMessage on Claude); exit 2 is a profile or setup problem the agent cannot fix, so handle it like `profile-wrong`.
- On Codex the stop audit runs the same way, found from the spawn `task_name`; a malformed `task_name` gives a `warning`, handled as above.

Route the result `status`:

| Status | Action |
| --- | --- |
| `done` | Gate, merge and clean up as in [Merging a finished build](#merging-a-finished-build) below. |
| `profile-wrong` | Stop. Block the spec with the quoted profile line as the condition (`status-transition.sh status .workflow/specs/NNN-slug blocked --step <1.2 or 1.3> --blocked "<...>"`). Profiles are edited only at 5.3; the human decides how to continue. |
| `discovered-work` | Work outside the agreed scope: never fold it into the suites on your own. Load `modules/discovered-work.md` once with every entry, each with origin node `1.2` or `1.3`, found by (the agent and its result file), the problem, the evidence (the reproduction, or the quoted line with its `path:line`), the kind and the agent's `blocker_assessment`; the module's assessment routes each one. **Unproven:** one design-log line, nothing else. **Current work** (a proven problem in the suites or stubs this build writes, simple to fix): resume the build with it as one more thing to fix; the stakeholder is not asked. **For the stakeholder** (convoluted, scope-expanding or out of scope): the module records it `to ask` for the one batched question at the next ask or at 5.5, and returns at once. After any of these three, if `.step` no longer names the origin node, set it back (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug <1.2 or 1.3>`), then resume the build on its own scope, with no block. **Blocker:** the module blocks the spec; when it returns at 00.28, resume the build on its own scope; if it ends at 00.24 (`draft`) or leaves the spec `blocked`, Phase 1 stops here. A non-empty `discovered_work` on a `done` result goes the same way. |
| `blocked`, `scope-expansion` | Answer facts from the code and resume the agent. A decision the spec does not settle and whose answer changes scope or intent blocks the spec as above, with the decision as the condition; any other decision is assumed and logged as [conventions](../references/conventions.md#asking-the-stakeholder) says, and the agent resumed with it. Scope that spreads into work the spec did not agree is discovered work (row above). |

Phase 1 output gets no `profile-mini-review`: that task type requires a `task_id`, and Phase 1 has none. Its gates are the stop audit and 1.4.

### Merging a finished build

Merge in the spec checkout on the spec branch. The branch is the one the result file names (`yq '.branch' <file>`): `wf/NNN-slug/<name>`, the branch you created. First run the artifacts gate, then merge, then remove the worktree and its branch. Run each line as its own command and never pipe the gate into another command, because a pipe hides its exit code:

```bash
.agents/skills/feature-workflow/scripts/check-merge-artifacts.sh --spec-dir .workflow/specs/NNN-slug --rev wf/NNN-slug/<name>
git merge --no-ff -m "Merge phase-1-<work_type>" wf/NNN-slug/<name>
git worktree remove .workflow/.worktrees/<name>
git branch -d wf/NNN-slug/<name>
```

Merge only on gate exit 0. Exit 1 prints each path under `artifacts/` that the branch adds, changes or deletes: resume the agent with those lines to drop that change from its branch (its result file belongs in the spec checkout only), then run the gate again. Exit 2 is a usage or environment error: fix the cause and run it again.

## 1.2 Harness and CI checks

Launch under `work_type: test-harness`. The brief names what to build: the unit and integration harness for the modules this feature touches (from `codebase-map.md`), the CI checks that run it, the commands that measure the coverage targets from 1.1, and the fixtures and oracles from `verification-plan.md` (`## Fixtures and oracles`, pasted as rows). Ask for the harness command and the CI check name in the result `summary`. For each module listed as new in `codebase-map.md`, the brief also asks for a minimal interface stub first (the exported names and signatures from the `codebase-map.md` interface additions, returning a fixed placeholder value rather than throwing), so the new tests fail on an assertion at 1.4 instead of on an import error.

**Ask the breakdown quiz while the build runs.** Once the 1.2 launch is out, draft the task breakdown and ask its quiz as [task-breakdown 2.1](task-breakdown.md#21-split-into-vertical-slices) says, the 2.2 and 2.3 questions and the budget with it, without setting step 2.1. Nothing the quiz decides changes what 1.2 and 1.3 build: the slices read the spec, the data model, the journeys and the codebase map. Log the answers as a **Breakdown quiz** entry in `design-log.md`; task-breakdown takes them from there after 1.5. An answer that sends the spec back to discovery (2.2 or 2.3 No) launches no further Phase 1 build: let the running one return, then load task-breakdown at that step for the loop back.

**Done when:** the branch is merged and its worktree and branch removed, the stop audit is clean, and you can name the harness command; 1.4 is its first whole run.

## 1.3 Browser suite from the journeys

Launch under `work_type: e2e-browser`, after 1.2 is merged, in a worktree created only then so it starts from the harness. The brief pastes the `## Journeys` rows (ids, steps, expected outcomes) and the fixtures they use, and asks for one test per journey, named or tagged by its `JRN-###` id, so evidence is filed by journey. It also asks for the fault switch 1.4 uses: the e2e fixture honours `E2E_INJECT_FAULT=1` by answering every app API request with a 500 (`page.route('**/api/**', r => r.fulfill({ status: 500 }))`). Journeys for behaviour not built yet fail now; that is expected.

After the merge, update the Check column of `## Journeys` from `MISSING` to the test name or tag, so every journey has an automated check.

**Done when:** the branch is merged and its worktree and branch removed, the stop audit is clean, and no journey says `MISSING`.

## 1.4 Do both suites fail a known-bad build?

A suite that cannot go red proves nothing. For each suite, run it against a known-bad build and confirm it fails **on an assertion**: an import, compile, setup, crash or navigation-timeout error is not proof. Work in a scratch worktree under `.workflow/.worktrees/`, made from the spec checkout (`git worktree add --detach .workflow/.worktrees/s<NNN>_known_bad HEAD`), never in the spec checkout itself, and remove it afterwards (`git worktree remove --force .workflow/.worktrees/s<NNN>_known_bad`). A worktree there counts as the spec checkout it sits in, so the evidence hook files its runs in the spec checkout; write any output file the same way, by its absolute path in the spec checkout (`<spec checkout>` below), since the scratch copy is removed. The technique is targeted fault injection:

1. **The baseline is the first known-bad build.** The feature does not exist yet, so the merged suites at `HEAD` (the baseline plus only the 1.2-1.3 test work and interface stubs) must already be red for every new check. Run the harness command and the browser-suite command from the profiles' `test` and `e2e` keys with machine-readable output saved under `<spec checkout>/.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/`; with the example stack:

   ```bash
   npx vitest run --reporter=json --outputFile=<spec checkout>/.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/harness.json
   npx playwright test        # JSON reporter writes test-results/e2e-results.json; copy it beside harness.json
   ```

   **Pass:** every new harness test and every new `@JRN-###` test has status `failed`, and its first error is an assertion failure. For Vitest read `testResults[].assertionResults[].failureMessages`; for Playwright, `results[].errors[].message` matching `expect(`. A new test that passes on the baseline, or fails only for a setup reason, is not proof.
2. **Injected fault for the browser suite (always).** The e2e fixture honours `E2E_INJECT_FAULT=1` by routing the app's API to an error (`page.route('**/api/**', r => r.fulfill({ status: 500 }))`; 1.3 builds this into the fixture). Run `E2E_INJECT_FAULT=1` with the `e2e` command. **Pass:** every journey test fails. A journey that stays green under a dead backend is vacuous.
3. **StrykerJS on the harness (optional).** Only when the change modifies **existing** behaviour that the baseline run cannot prove red, run StrykerJS with `testRunner: "vitest"` and `mutate` scoped to the owning module from `codebase-map.md`, for example `npx stryker run --mutate "src/<module>/**/*.ts,!src/<module>/**/*.test.ts"`. **Pass:** exit 0 (the mutation score is at least `thresholds.break`). Read `reports/mutation/mutation.json` for `Survived` and `NoCoverage` mutants on the lines this feature will change and name them in the record. Skip this step when StrykerJS is not installed and say so in the record; it is never a silent pass.

Record each run (fault, command, exit code, each new test with its first error message) under `.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/`.

- **Yes, both fail on assertions:** go to 1.5.
- **No, a suite passes the broken build, or fails only on setup errors:** back to 1.2 (or 1.3). Create the build's agent worktree again ([Launching a Phase 1 build](#launching-a-phase-1-build); the merge removed it), then resume (or relaunch) the build for each such suite in it, with the tests that stayed green or errored and their output in the brief; re-run 1.4 after the merge.
- **The suites cannot be made to fail** (the agent reports it cannot, or five rounds for one suite still pass the broken build): block the spec.

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 1.4 \
    --blocked "<suite> cannot be made to fail a known-bad build: <what was tried>"
  ```

**Tests in tasks.** The known-bad build is the merged wave's tests on the code as it was before the tasks. In a scratch worktree at the spec-branch tip, made and removed as above, put every file the tasks changed outside the test paths (the profiles' `test_patterns`) back as it was at `impl_base_revision`, deleting the files they added:

```bash
git diff --name-only <impl_base_revision> HEAD                  # in the scratch worktree; keep the test files
git restore --source=<impl_base_revision> -- <each non-test file>
```

Run the harness, and the browser suite when it exists, with machine output under `artifacts/phase-1-known-bad/`, and record it as above. **Pass:** every test the tasks added fails on an assertion. A test that passes on the old code proves nothing: reopen the task that wrote it with that test named, give it a fix round, and run this check again after its merge. Then replace each `in task` in the Check column with the test name and fill the 1.4 evidence cells of `## Suites`.

**Done when:** both suites have a recorded red run on a known-bad build in which every new test fails on an assertion.

## 1.5 Record the suites and hand off

Fill `## Suites` in `verification-plan.md` from the profile Toolchain keys: the Harness row copies the `test` key of `.workflow/profiles/test-harness.md`, the Browser row the `e2e` key of `.workflow/profiles/e2e-browser.md`, each with its CI check (or `none`) and its 1.4 evidence path. Never write a suite command from memory. Gates 3.9 and 3.10 run these commands.

**Commit Phase 1 on the spec branch.** The harness, the browser suite and their stubs are already merged; commit what is left (the spec folder: `verification-plan.md`, `spec.md`, the 1.4 evidence) so the Phase 1 state is saved in one place and no task branch ever carries it as its own change:

```bash
git status --short                    # only spec-folder files may remain; anything else came from a build and is a finding
git add .workflow/specs/NNN-slug && git commit -m "Phase 1 for NNN-slug: suites red by design"
```

From here the spec branch is **red by design** (green with [tests in tasks](#tests-in-tasks), which has no Phase 1 tests yet): the new harness tests and journeys fail until the tasks that make them pass are merged. It stays red through Phase 3 and goes green only when the last wave is merged and the full suite passes (3.9 after the last wave, 3.11, then Phase 4). Task branches fork from this state; 3.1 records the spec-branch tip as `impl_base_revision`, so Phase 1 files never count toward a task's diff, and count toward the 3.15 size budget only when a task changes them again.

**Done when:** `## Suites` is filled and `git status --short` shows nothing under the spec folder. Then load `modules/task-breakdown.md`.
