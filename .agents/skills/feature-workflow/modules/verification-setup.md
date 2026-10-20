# Phase 1: Verification setup

You build the checks that will prove the feature, and prove that they can fail, before anyone writes feature code. You are done when every target in `verification-plan.md` has a threshold and an exact command, `baseline_revision` is set, the harness and the browser suite are merged into the spec branch, both suites have gone **red** on a known-bad build, every new test failing on an assertion, and the Phase 1 work is committed on the spec branch (1.5).

Everything here runs in the main session at spec status `ready-for-dev`. Phase 1 writes no status except `blocked` (1.4, 00.19; 00.21 through `modules/discovered-work.md`). Call the scripts from the project root exactly as written below, with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines). Mark each Phase 1 node as you enter it (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 1.<n>`) so a resumed session returns to it.

**Re-entry.** If you arrive here again after a loop back to 0.3.8 (the spec went `draft` and came back through 0.6), keep what exists: `baseline_revision` is never overwritten, and the suites recorded under `## Suites` in `verification-plan.md` stay. Redo 1.1-1.4 only for targets and journeys that are new or changed since they were built.

## 1.1 Measurable targets and the baseline

1. **Create the spec branch and capture the baseline.** All work for this spec lands on the **spec branch** `spec/NNN-slug`; it reaches the main branch only at sign-off (5.8). Read `spec_branch` and `baseline_revision` from `spec.md`:

   ```bash
   yq --front-matter=extract '[.spec_branch, .baseline_revision] | @tsv' .workflow/specs/NNN-slug/spec.md
   ```

   When both are empty (`""`), set the step, branch off the main branch carrying the uncommitted spec folder, and make the spec branch's first commit; the baseline is that commit:

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 1.1
   git switch -c spec/NNN-slug "$(.agents/skills/feature-workflow/scripts/rules-setting.sh main_branch)"   # the project's main branch, the PR/MR target
   git add .workflow/specs/NNN-slug && git commit -m "Spec NNN-slug"
   git rev-parse HEAD                    # the value for baseline_revision
   ```

   Then Edit the frontmatter, these two keys only (the guard rejects a status change): `spec_branch: spec/NNN-slug` and `baseline_revision: <that sha>`. When they are already set, leave them, and check you are on the spec branch (`git branch --show-current`; `git switch spec/NNN-slug` otherwise). Every Phase 1 build forks from and merges into this branch.

2. **Fill the Targets table** of `verification-plan.md` (`## Targets`). Cover performance, errors and coverage. Each row needs a threshold, the exact command that measures it, and the source of the threshold: a `spec.md` constraint, a `.workflow/rules.md` line, or a stakeholder decision. Thresholds the spec and rules do not give are decisions, so ask them: put every open threshold to the stakeholder in one round, each with a recommended value. A target that cannot be measured stays in the table with the reason in place of the command.

**Done when:** you are on `spec/NNN-slug`, `spec_branch` names it, `baseline_revision` is the full SHA of its first commit, and every row of `## Targets` has threshold, command (or the reason it cannot be measured) and source.

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

- **Claude.** Call the Agent tool with `subagent_type: implementation`, `isolation: "worktree"` (each implementation launch gets its own worktree) and the prompt above. Leave out `model`: `hooks/pre-launch.sh` resolves the model and prepends the whole profile after the header.
- **Codex** (advisory). Build the launch with the orchestrator mode (`--task-type implementation`), then spawn (`agent_type` = the definition name with `-` replaced by `_`; `--task-type` keeps the hyphen) with `.prompt` as the message, `.model` as the spawn's model (the generated `.codex/agents/*.toml` never carry `model`, so this is what selects it) `task_name` set to `s<NNN>_phase_1_<enc(work_type)>`, for example `s007_phase_1_test_harness` (`enc` lowercases and turns every character outside `[a-z0-9]` into `_`; Codex accepts only `[a-z0-9_]`, no `/`), so the stop audit can find the launch, and `fork_turns: "none"` so the model override applies. Codex has no `isolation` option, so first create the worktree yourself, named by the `task_name`: `git worktree add .workflow/.worktrees/<task_name> -b wf/NNN-slug/<task_name>` (for example `.workflow/.worktrees/s007_phase_1_test_harness`; `.workflow/.worktrees/` gitignored), and name it in the brief as the directory the agent works in; the stop audit runs the toolchain there and warns when it is missing:

  ```bash
  .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type implementation \
    --spec-dir .workflow/specs/NNN-slug --work-type test-harness <<'EOF'
  <the build brief>
  EOF
  ```

- **No profile.** A deny that names 00.19 means `.workflow/profiles/<work-type>.md` is missing. Create it with the human from `.workflow/profiles/TEMPLATE.md` (the shipped `test-harness` and `e2e-browser` examples are a starting point): `.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 00.19`, then Write the new profile, then launch again. With no human available, block the spec: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 00.19 --blocked "no <work-type> profile; a human must define .workflow/profiles/<work-type>.md"`.

**When the launch returns.** The stop audit has run the profile toolchain under the evidence id `phase-1-<work_type>`, with the `test` key skipped: the new tests are red by design until the feature is built, and 1.4 is what proves they fail. `lint`, `typecheck`, `format` and `boundary` still run. Read the agent's result block, then the audit evidence in the main checkout:

- `.workflow/specs/NNN-slug/artifacts/phase-1-<work_type>/toolchain.json` with `"status": "pass"` and no `audit.json` beside it: the audit is clean.
- `audit.json` present (outcome `warning` or `gave-up`), or `toolchain.json` says `fail`: run `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id phase-1-<work_type> --work-type <work_type> --skip test --cwd <worktree>` yourself. Exit 0 counts as clean; exit 1 goes back to the agent with the digest (resume it, for example with SendMessage on Claude); exit 2 is a profile or setup problem the agent cannot fix, so handle it like `profile-wrong`.
- On Codex the stop audit runs the same way, found from the spawn `task_name`; a malformed `task_name` gives a `warning`, handled as above.

Route the result `status`:

| Status | Action |
| --- | --- |
| `done` | Merge the worktree branch into the spec branch in the main checkout: `git merge --no-ff -m "Merge phase-1-<work_type>" <branch>` (branch from the result block, or `worktreeBranch` in the Agent result). |
| `profile-wrong` | Stop. Block the spec with the quoted profile line as the condition (`status-transition.sh status .workflow/specs/NNN-slug blocked --step <1.2 or 1.3> --blocked "<...>"`). Profiles are edited only at 5.3; the human decides how to continue. |
| `discovered-work` | Work outside the agreed scope: never fold it into the suites. Load `modules/discovered-work.md` with origin node `1.2` or `1.3`, found by (the agent and its return), the problem, the evidence (`path:line`, a failing test, or the return quoted) and the kind. When it returns at 00.28, resume the build on its own scope; if it ends at 00.24 (`draft`) or leaves the spec `blocked`, Phase 1 stops here. |
| `blocked`, `scope-expansion` | Answer facts from the code and resume the agent. A decision the spec does not settle blocks the spec as above, with the decision as the condition. Scope that spreads into work the spec did not agree is discovered work (row above). |

Phase 1 output gets no `profile-mini-review`: that task type requires a `task_id`, and Phase 1 has none. Its gates are the stop audit and 1.4.

## 1.2 Harness and CI checks

Launch under `work_type: test-harness`. The brief names what to build: the unit and integration harness for the modules this feature touches (from `codebase-map.md`), the CI checks that run it, the commands that measure the coverage targets from 1.1, and the fixtures and oracles from `verification-plan.md` (`## Fixtures and oracles`, pasted as rows). Ask for the harness command and the CI check name in the result `summary`. For each module listed as new in `codebase-map.md`, the brief also asks for a minimal interface stub first (the exported names and signatures from the `codebase-map.md` interface additions, returning a fixed placeholder value rather than throwing), so the new tests fail on an assertion at 1.4 instead of on an import error.

**Done when:** the branch is merged, the stop audit is clean, and you can name the harness command and have run it once on the merged checkout.

## 1.3 Browser suite from the journeys

Launch under `work_type: e2e-browser`, after 1.2 is merged so the new worktree starts from it. The brief pastes the `## Journeys` rows (ids, steps, expected outcomes) and the fixtures they use, and asks for one test per journey, named or tagged by its `JRN-###` id, so evidence is filed by journey. It also asks for the fault switch 1.4 uses: the e2e fixture honours `E2E_INJECT_FAULT=1` by answering every app API request with a 500 (`page.route('**/api/**', r => r.fulfill({ status: 500 }))`). Journeys for behaviour not built yet fail now; that is expected.

After the merge, update the Check column of `## Journeys` from `MISSING` to the test name or tag, so every journey has an automated check.

**Done when:** the branch is merged, the stop audit is clean, and no journey says `MISSING`.

## 1.4 Do both suites fail a known-bad build?

A suite that cannot go red proves nothing. For each suite, run it against a known-bad build and confirm it fails **on an assertion**: an import, compile, setup, crash or navigation-timeout error is not proof. Work in a throwaway worktree (`git worktree add --detach <scratch dir> HEAD`), never in the main checkout, and remove it afterwards (`git worktree remove --force <scratch dir>`). The technique is targeted fault injection:

1. **The baseline is the first known-bad build.** The feature does not exist yet, so the merged suites at `HEAD` (the baseline plus only the 1.2-1.3 test work and interface stubs) must already be red for every new check. Run the harness command and the browser-suite command from the profiles' `test` and `e2e` keys with machine-readable output saved under `.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/`; with the example stack:

   ```bash
   npx vitest run --reporter=json --outputFile=.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/harness.json
   npx playwright test        # JSON reporter writes test-results/e2e-results.json; copy it beside harness.json
   ```

   **Pass:** every new harness test and every new `@JRN-###` test has status `failed`, and its first error is an assertion failure. For Vitest read `testResults[].assertionResults[].failureMessages`; for Playwright, `results[].errors[].message` matching `expect(`. A new test that passes on the baseline, or fails only for a setup reason, is not proof.
2. **Injected fault for the browser suite (always).** The e2e fixture honours `E2E_INJECT_FAULT=1` by routing the app's API to an error (`page.route('**/api/**', r => r.fulfill({ status: 500 }))`; 1.3 builds this into the fixture). Run `E2E_INJECT_FAULT=1` with the `e2e` command. **Pass:** every journey test fails. A journey that stays green under a dead backend is vacuous.
3. **StrykerJS on the harness (optional).** Only when the change modifies **existing** behaviour that the baseline run cannot prove red, run StrykerJS with `testRunner: "vitest"` and `mutate` scoped to the owning module from `codebase-map.md`, for example `npx stryker run --mutate "src/<module>/**/*.ts,!src/<module>/**/*.test.ts"`. **Pass:** exit 0 (the mutation score is at least `thresholds.break`). Read `reports/mutation/mutation.json` for `Survived` and `NoCoverage` mutants on the lines this feature will change and name them in the record. Skip this step when StrykerJS is not installed and say so in the record; it is never a silent pass.

Record each run (fault, command, exit code, each new test with its first error message) under `.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/`.

- **Yes, both fail on assertions:** go to 1.5.
- **No, a suite passes the broken build, or fails only on setup errors:** back to 1.2 (or 1.3). Resume (or relaunch) the build for each such suite, with the tests that stayed green or errored and their output in the brief; re-run 1.4 after the merge.
- **The suites cannot be made to fail** (the agent reports it cannot, or five rounds for one suite still pass the broken build): block the spec.

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 1.4 \
    --blocked "<suite> cannot be made to fail a known-bad build: <what was tried>"
  ```

**Done when:** both suites have a recorded red run on a known-bad build in which every new test fails on an assertion.

## 1.5 Record the suites and hand off

Fill `## Suites` in `verification-plan.md` from the profile Toolchain keys: the Harness row copies the `test` key of `.workflow/profiles/test-harness.md`, the Browser row the `e2e` key of `.workflow/profiles/e2e-browser.md`, each with its CI check (or `none`) and its 1.4 evidence path. Never write a suite command from memory. Gates 3.9 and 3.10 run these commands.

**Commit Phase 1 on the spec branch.** The harness, the browser suite and their stubs are already merged; commit what is left (the spec folder: `verification-plan.md`, `spec.md`, the 1.4 evidence) so the Phase 1 state is saved in one place and no task branch ever carries it as its own change:

```bash
git status --short                    # only spec-folder files may remain; anything else came from a build and is a finding
git add .workflow/specs/NNN-slug && git commit -m "Phase 1 for NNN-slug: suites red by design"
```

From here the spec branch is **red by design**: the new harness tests and journeys fail until the tasks that make them pass are merged. It stays red through Phase 3 and goes green only when the last wave is merged and the full suite passes (3.9 after the last wave, 3.11, then Phase 4). Task branches fork from this state; 3.1 records the spec-branch tip as `impl_base_revision`, so Phase 1 files never count toward a task's diff, and count toward the 3.15 size budget only when a task changes them again.

**Done when:** `## Suites` is filled and `git status --short` shows nothing under the spec folder. Then load `modules/task-breakdown.md`.
