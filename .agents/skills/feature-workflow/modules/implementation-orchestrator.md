# Phase 3: Implementation

You run the build: classify every task, launch one implementation agent per task in dependency **waves**, pass each task through the four gates, and merge between waves. You never write feature code yourself; agents do, and the gates judge it. You are done when every task record is `done` (or `split-out`), the harness and the browser suite pass on the merged spec branch (or a light-path suite gap is recorded), and the spec is `in-review`. The spec branch is **red by design** until then: Phase 1 committed tests for behaviour no task has built yet, so the full suite goes green only after the last wave (3.9, 3.11). Work outside the agreed scope is never folded into a task: it goes to `modules/discovered-work.md` (00.21-00.29).

Call the scripts from the project root exactly as written below, with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines). Status and task records change only through `status-transition.sh`.

## Launching agents

Three task types launch here. Each prompt opens with the ```` ```yaml launch-header ```` block on its first line. The required fields come from `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements --task-type <type>`:

| Task type | Node | Header fields | Agent tool options (Claude) |
| --- | --- | --- | --- |
| `implementation` | 3.3 | `spec_dir`, `task_id`, `work_type` (the value recorded at 3.1; a disagreeing value is denied) | `run_in_background: true`; working directory = the task worktree you created at wave start (see **Claude** below) |
| `integration` | 3.2 | `spec_dir`, `work_type` (a batch, no `task_id`) | `isolation: "worktree"` |
| `profile-mini-review` | 3.7 | `spec_dir`, `task_id`, `work_type` | none (read-only) |

````text
```yaml launch-header
task_type: implementation
spec_dir: .workflow/specs/NNN-slug
task_id: T3
work_type: backend-api
```
<the brief>
````

- **Claude.** Set `subagent_type` to the task type.
  An implementation launch runs in the task worktree you created at [wave start](#wave-start-task-branches-and-worktrees), never with `isolation: "worktree"`.
  The Agent tool has no working-directory option (a sub-agent starts in the main session's directory; `isolation: "worktree"` is the only other choice), so launch it without `isolation` and confine it by the brief: every Bash command starts with `cd <absolute worktree path> && `, and every Read, Edit and Write uses an absolute path inside the worktree. `hooks/worktree-write-guard.sh` enforces this for implementation and integration sub-agents: it reads the task from the launch header and denies a Write, Edit or NotebookEdit inside the main checkout but outside `.workflow/.worktrees/s<NNN>_t<N>`, and a Bash command without that leading `cd` (accident prevention; a command can still reach out after its `cd`). The stop audit finds the worktree itself and warns when it is missing. Fallback when an agent cannot work this way (it keeps getting denied, or edits the main checkout through Bash): remove the wave-start worktree and branch (`git worktree remove .workflow/.worktrees/<task_name> && git branch -d <branch>`; `-d` refuses a branch with commits: then keep it, add "first merge branch `<branch>` into yours" to the relaunch brief, and rename the isolation branch to the record's `branch` only after deleting the old one with `git branch -d` once its commits are merged), relaunch with `isolation: "worktree"` (needs `"worktree": {"baseRef": "head"}` in `.claude/settings.json` and the main checkout on the spec branch, so the worktree forks from the spec-branch tip), and after it returns rename its branch to the record's `branch` with `git branch -m <worktreeBranch from the Agent result> <branch>`. With no `.workflow/.worktrees/<task_name>` the stop audit and the worktree guard both use the isolation worktree.
  Name the worktree's absolute path in the brief as the directory the agent works in. Leave out `model` and the profile: `hooks/pre-launch.sh` resolves both through `resolve-launch.sh` and returns the launch with the model set and the profile inserted after the header. A deny naming 00.14 means no model is assigned for the type (fix `.workflow/model-map/<type>.md` or `.workflow/agent-overrides.yaml` with the human); a deny naming 00.18 or 00.19 is handled in 3.1.
- **Codex** (advisory). Build each launch with the orchestrator mode, then spawn with `.prompt` as the message and `.model` as the spawn's model. The generated `.codex/agents/*.toml` never carry `model` (a toml model would override the spawn-time one), so the model you pass here is what selects it:

  ```bash
  .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type implementation --spec-dir .workflow/specs/NNN-slug --task-id T3 --work-type backend-api <<'EOF'
  <the brief>
  EOF
  ```

  Spawn with `agent_type` set to the definition name with `-` replaced by `_` (`implementation`, `integration`, `profile_mini_review`); `--task-type` keeps the hyphenated name (`profile-mini-review`). Set the spawn `task_name` to `s<NNN>_t<N>` (for example `s007_t3` for `.workflow/specs/007-checkout`, `T3`) for every implementation launch, including a fix-round relaunch (keep it exactly `s<NNN>_t<N>`: the stop audit finds the task from it), to `s<NNN>_t<N>_r<round>` (for example `s007_t3_r2`) for the 3.7 `profile-mini-review` launch of review round `<round>`, and to `s<NNN>_integration_<enc(work_type)>` (for example `s007_integration_web`) for an integration batch, where `enc` lowercases and turns every character outside `[a-z0-9]` into `_`. Codex accepts only `[a-z0-9_]` in the name, with no `/`. The Codex stop audit finds its task from it, because the spawn message is encrypted. Spawn with `fork_turns: "none"`: a full-history fork may ignore the spawn `model` override, and it keeps the parent's history out of the sub-agent. The audit reads it back from the sub-agent transcript's `session_meta` `agent_path` and blocks on toolchain failure as on Claude.

  Codex has no `isolation` option. An implementation spawn runs in the task worktree created at [wave start](#wave-start-task-branches-and-worktrees) (`.workflow/.worktrees/<task_name>` on the task branch); name it in the brief as the directory the agent works in. For an integration batch create the worktree yourself before the spawn, named by its `task_name`: `git worktree add .workflow/.worktrees/<task_name> -b wf/NNN-slug/<task_name>` (for example `.workflow/.worktrees/s007_integration_web` on branch `wf/007-checkout/s007_integration_web`). `.workflow/.worktrees/` is gitignored. The stop audit runs the toolchain in `.workflow/.worktrees/<task_name>` (evidence still goes to the main checkout); without that directory it allows the stop with a warning. A fix-round relaunch keeps the same worktree.
- **Briefs are context pointers.** An implementation brief names the task file (`.workflow/specs/NNN-slug/<file>` from the record, committed on the spec branch so the worktree has it), the worktree path, the `codebase-map.md` extract for its module, and any shared-core interface integration applied for it. Nothing about other tasks; the task file is not pasted.
- **Resume, don't restart.** Send fix requests to the same agent (on Claude, SendMessage to the agent id from the Agent result); it keeps its worktree and context. When an agent cannot be continued, launch a fresh one with the same header and add to the brief: "first merge branch `<branch>` into yours, then fix: <findings>".

## Evidence and the ledger

Evidence lives under `.workflow/specs/NNN-slug/artifacts/` in the main checkout: `<task-id>/` per task, `integration-<work_type>/` per integration batch. The toolchain evidence is written by `run-toolchain.sh` (`toolchain.json`, `toolchain.txt`, `toolchain-digest.txt`) and the stop audit (`audit.json`, `audit-loop.json`). Beside them, save each agent's final result block as you receive it: `implementation.yaml`, `mini-review.yaml`, `integration.yaml`. With `tasks.md` statuses, these files are your ledger: after compaction or on resume, trust them and `git log` over memory.

**Rework entry (4.7).** `review-triage` reopens tasks (`set-task --status in-progress --step 4.7`) and loads this module with one patch line per finding, spec status still `in-review`. Skip 3.1's status change (`in-review` cannot go back to `in-progress`); launch each reopened task fresh with its patch lines in the brief, in a new task branch and worktree off the spec-branch tip ([wave start](#wave-start-task-branches-and-worktrees)), run the gates, then 3.16, 3.15, 3.9 and 3.10-3.11 as below, and set `in-review` again at 3.11 (or 3.14), which returns to `review-triage`.

**On resume** (status `in-progress`): skip `done` tasks. For an `in-progress` task, its worktree is `.workflow/.worktrees/<task_name>` on the record's `branch` (or see `implementation.yaml`, or the `cwd` in `toolchain.json`). If the worktree has commits and a clean audit, continue at 3.7; otherwise launch it again (a fresh launch; the task stays `in-progress`). If `.step` says 3.16 or 3.15, the wave's merges may be done but its budget check is not: run 3.15 before the next frontier. After `modules/discovered-work.md` unblocks the spec at 00.28, resume the same way, at the point the block interrupted.

## 3.1 Classify each task and start

1. **Classify.** For every task whose `work_type` is null (`yq --front-matter=extract '.tasks[] | select(.work_type == null) | .id' .workflow/specs/NNN-slug/tasks.md`), pick the profile in `.workflow/profiles/` whose `## File locations` cover the task's module and kind of work, and record it. A work type is set once and never reclassified:

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --work-type <work-type> --step 3.1
   ```

   **00.18 No.** A task that fits no profile is a finding: either the task is badly cut or a work type is missing. For a missing work type, create the profile with the human from `.workflow/profiles/TEMPLATE.md` (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 00.19`, then Write `.workflow/profiles/<work-type>.md`). With no human available: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 00.19 --blocked "task T3 has no profile; define .workflow/profiles/<work-type>.md"`.

2. **Start.** `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-progress --step 3.1` (from `ready-for-dev`, or again on resume).

3. **Record the implementation base.** Check you are on the spec branch (`git branch --show-current` prints the `spec_branch` from `spec.md`). If `impl_base_revision` is `""`, Edit it to `git rev-parse HEAD` now (the step is 3.1): the spec-branch tip, which holds the Phase 1 commit and the committed breakdown. On the light path, also set `baseline_revision` to the same sha if it is `""` (the spec branch's first commit, from 0.3.20). Both are never overwritten on resume or rework. The 3.15 size budget counts only files changed since `impl_base_revision`, so the Phase 1 harness and suite count only when a task changes them again.

4. **3.13: do both suites exist?** On the full path, yes: Phase 1 built them and `## Suites` in `verification-plan.md` names their commands. On the light path, look it up (a fact, not a question): the harness exists when the repo has a unit or integration test command to run (the profile Toolchain `test` key); the browser suite exists when `.workflow/profiles/e2e-browser.md` has a non-empty `e2e` command. Each missing suite skips its gate and is recorded at 3.14.

**Done when:** every task has a `work_type`, the spec is `in-progress`, `impl_base_revision` is a full SHA, and you know which suites exist.

## The wave loop

Repeat until no task is `pending`. A `split-out` task is terminal: it is never launched, never in a frontier, and never counted by an "every task is done" check. Each wave runs 3.2, the [wave start](#wave-start-task-branches-and-worktrees), 3.3, the per-task gates 3.4-3.8, then 3.16 (merge), 3.15 (budget), 3.13 and 3.9, in that order. The frontier is every pending task whose dependencies are all `done`:

```bash
yq --front-matter=extract '[.tasks[] | select(.status == "done") | .id] as $done
  | .tasks[] | select(.status == "pending" and ((.depends_on - $done) | length) == 0) | .id' .workflow/specs/NNN-slug/tasks.md
```

An empty frontier with tasks still pending means they wait on a `blocked` task: go to [Stops](#stops).

### 3.2 Integration batches, one work type each

Before launching the wave, collect its shared-core change requests: the **Notes** request of every frontier task with `touches_core: true`, plus shared-core requests from `scope-expansion` results. Group them by the requesting task's `work_type`, one batch per work type, so each launch carries exactly one profile. Launch the batches one at a time (header `task_type: integration`, `spec_dir`, `work_type`); each brief is a numbered list of requests, each stating the change and the contract its consumer needs, without task context.

When a batch returns:

- **Batch `status`** (top level; `.agents/agents/integration.md` "Return"). `done` or `partial`: handle each request by its verdict below (`partial` means some requests were rejected or conflict). `discovered-work`: out-of-scope work stopped the batch and nothing was applied; go to [Discovered work](#discovered-work-0021) at step 3.2 with its `discovered_work[]` entries. `profile-wrong`: a [stop](#stops) at step 3.2, quoting `profile_wrong.line`. `blocked`: read `blocked.reason`; a fact you look up and resume the agent, a decision you put to the stakeholder, or block the spec at step 3.2 when no answer is available.
- **`discovered_work[]`.** A non-empty list goes to [Discovered work](#discovered-work-0021) at step 3.2 whatever the status, `done` and `partial` included. While that module has the spec `blocked`, hold this batch's merge as 3.16 does; merge the `applied` work once it returns at 00.28.
- **Toolchain.** No stop audit fires for integration; the agent runs `run-toolchain.sh` itself. Check `artifacts/integration-<work_type>/toolchain.json` says `pass`; otherwise resume the agent with `toolchain-digest.txt`.
- **Verdicts** (per request: `applied`, `reject-not-shared-core`, `reject-other-work-type`, `conflict`, `blocked`). `applied`: merge its branch (`worktreeBranch` from the Agent result, or `wf/NNN-slug/<task_name>` on Codex) into the spec branch with `git merge --no-ff -m "Merge integration-<work_type>" <branch>` before the wave launches, and pass the new interface into the requesting tasks' briefs. `reject-other-work-type`: move the request to that work type's batch. `reject-not-shared-core`: it is module work for the requesting task; put it in that task's brief. `conflict`: a decision; put both options to the stakeholder, re-batch with their answer, or block the spec at step 3.2 when no answer is available. `blocked`: its `reason` names what stops it; when that is an entry in `discovered_work[]`, the request waits for that ruling and is re-batched after 00.28; otherwise handle it like `conflict`.
- Integration output gets no mini-review: that task type requires a `task_id`.

### Wave start: task branches and worktrees

After 3.2's merges, for each frontier task create its task branch off the current spec-branch tip and a worktree for it, from the main checkout on the spec branch. `<task_name>` is `s<NNN>_t<N>` (the Codex spawn name, used on both hosts) and `<branch>` is the record's `branch`:

```bash
git worktree add .workflow/.worktrees/<task_name> -b <branch> spec/NNN-slug
# e.g. git worktree add .workflow/.worktrees/s007_t3 -b task/007-checkout/T03-guest-cart spec/007-checkout
```

Light path (`branch: null`): no task branch; create the worktree detached at the spec-branch tip (`git worktree add --detach .workflow/.worktrees/<task_name> spec/NNN-slug`) and fast-forward the spec branch to its commits at 3.16. A worktree that already exists (resume, fix round, rework) is reused. Integration worktrees are created at 3.2 as above.

### 3.3 Launch the wave

**No new launch while the spec is `blocked`.** Before each launch, read `status` (`yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md`). While it is `blocked` (discovered work or a crossed budget at 00.21, or any other stop), start no new implementation or integration launch; tasks already running finish and pass through their gates, including their 3.7 mini-review and fix rounds.

**Pause before a `hitl` task.** For a frontier task with `mode: hitl`, ask the stakeholder before launching it: name the human decision, credential or manual step its task file's **Mode** line says it needs, and whether it can be supplied now. Launch it when they confirm (put what they supplied in the brief); otherwise leave it `pending` and launch the rest of the wave. A `hitl` task the stakeholder cannot serve in this session blocks the spec at 3.3 once the rest of the wave has merged (see [Stops](#stops)).

For each frontier task, mark it started, then launch it in the background in its task worktree:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress
```

Launch all of the wave's tasks before handling any return. Results arrive on their own; handle each as it lands.

### Per-task gates (3.4-3.8)

For each returned implementation, save `implementation.yaml`, then:

1. **Route the result `status`.** `done` continues below. `discovered-work` goes to [Discovered work](#discovered-work-0021). `profile-wrong`, `scope-expansion` and `blocked` go to [Stops](#stops). Separately, a non-empty `discovered_work[]` goes to [Discovered work](#discovered-work-0021) whatever the status, `done` included (a `can-wait` item may accompany a finished task); a `done` task keeps going through its gates while that module handles it.
2. **3.4 Negative and edge cases.** `tests_added` includes `negative` or `edge` tests, or the summary says why none apply. Otherwise resume the agent to add them.
3. **3.5-3.6 Tool audit clean?** On Claude the stop audit has already run the profile toolchain (the command keys `lint`, `typecheck`, `format`, `boundary` and `test`; never `serve` or `serve_ready`) and blocked the agent's stop until it passed. Read `artifacts/<task-id>/`:
   - `toolchain.json` says `pass` and there is no `audit.json`: **clean**.
   - `audit.json` with outcome `gave-up`: the agent stopped on the same failure three times. **Not clean**: a fix round with `toolchain-digest.txt`.
   - `audit.json` with outcome `warning` (or a new line in `artifacts/audit-warnings.jsonl`): the audit could not run. Run it yourself: `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id T3 --cwd <worktree>`. Exit 0 is clean; exit 1 is a fix round with its digest; exit 2 is a header or profile problem the agent cannot fix: relaunch with a corrected header, or treat a profile problem as `profile-wrong`.
   - On Codex the stop audit works the same way, finding the task from the spawn `task_name`. A malformed `task_name` makes it warn, so handle it as the `warning` case above.

   The audit's `test` key judges only this task's own tests plus no regressions: tests other tasks will make green are still red on the spec branch by design and never fail this task's gate.
   The scoping comes from the records: each record's `tests` lists the Phase 1 tests that task turns green (assigned at 2.5). `run-toolchain.sh` excludes the `tests` of every other task not yet `done` and runs the profile's `test_scoped` command with them in `$WF_EXCLUDE_TESTS` (the task's own in `$WF_TASK_TESTS`), so this task's tests, the `done` tasks' tests and every pre-existing test (regressions since `impl_base_revision`) must pass; with nothing to exclude it runs `test` unchanged. A profile without `test_scoped` cannot be scoped: a failing `test` is then reported as `unscoped` with a warning in `toolchain.json` and does not block, so check that output yourself and add `test_scoped` to the profile.

   No agent looks at the diff until this is clean.
4. **3.7 Mini-review.** Launch `profile-mini-review` (header `spec_dir`, `task_id`, `work_type`). Hand over the diff as the task worktree path and the base commit from `implementation.yaml` (`git -C <worktree> diff <base_commit>...HEAD`), plus `.workflow/specs/NNN-slug/artifacts/<task-id>/toolchain.json`; no diff file is written. Save its return as `mini-review.yaml`; `tool-covered` items and `tool_rule_candidate` findings feed the 5.2 proposals. A non-empty `out_of_scope_noticed` never changes the verdict: hand each entry to [Discovered work](#discovered-work-0021) with origin node `3.7`, as for `discovered_work[]`.
5. **3.8 Mini-review passes?** `verdict: fail` is a fix round with the failed items (location, finding, fix). `pass`: the task is ready to merge at 3.16.

**Fix rounds.** A fix round is one resume of the implementer with the failing gate's output, followed by the gates again from 3.5 (the stop audit fires on its next stop). 3.6, 3.8, 3.9 and 3.11 failures all count. Five rounds per task at most; at the cap, go to [Stops](#stops).

### 3.16 Merge the wave

When every task of the wave has passed 3.8 (or is blocked), take the passing tasks **in task-id order** (T2 before T3, also for approved `parallel_with` pairs). For each, in the main checkout on the spec branch:

1. **Task review.** Read the setting from `.workflow/rules.md` (`pr` when the section or key is absent):

   ```bash
   .agents/skills/feature-workflow/scripts/rules-setting.sh task_review   # prints pr | pr-blocking | local; exit 1 on an invalid value
   ```

   For `pr` and `pr-blocking`, `.agents/skills/feature-workflow/scripts/open-task-pr.sh .workflow/specs/NNN-slug T3 --record` does the push, picks gh or glab from the `origin` host, reuses an open PR/MR for the same branches, records the URL with `set-task --pr --step 3.16`, and prints the URL or `skipped: <reason>` (always exit 0); the bullets below are what it does.

   - `pr` (default): push the spec branch and the task branch (`git push -u origin spec/NNN-slug <branch>`; the setting is the stakeholder's standing consent to push these two branches) and open a PR/MR from the task branch into the spec branch, titled `T3: <task title>`, its body linking the task file and the mini-review verdict: `gh pr create --base spec/NNN-slug --head <branch> ...` when the `origin` remote is GitHub, `glab mr create --target-branch spec/NNN-slug --source-branch <branch> ...` when it is GitLab (the `glab` skill has the flags). It is a **non-blocking** review record: record its URL (`set-task ... T3 --pr <url> --step 3.16`) and continue without waiting. No remote, an unknown host or a missing CLI: skip the PR, leave `pr: null` and append one line to `design-log.md` saying why.
   - `pr-blocking`: as `pr`, then wait for approval before merging (`gh pr view <url> --json reviewDecision`, or `glab mr approvers`). Tell the stakeholder which PRs wait; merge each once approved. Review comments that ask for changes are a fix round (3.5-3.8 again, push again).
   - `local`: no push, no PR; `pr` stays null.
2. **Merge and mark done** (tasks become `done` only here):

   ```bash
   git merge --no-ff -m "Merge T3: <task title>" <branch>   # the message names the task id; 4.7 finds task owners by it
   .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status done --step 3.16
   ```

   Light path (`branch: null`): `git merge --ff-only <head_commit from implementation.yaml>` instead; no PR.
3. **Clean up.** With `pr` or `pr-blocking`, push the spec branch so the PR/MR shows as merged. Then `git worktree remove .workflow/.worktrees/<task_name>` and `git branch -d <branch>`. The next wave forks from the new spec-branch tip.

On a merge conflict, run `git merge --abort` and resume that implementer: "merge the spec branch into your branch, resolve the conflict, re-run your tests, commit". Its diff changed, so it passes 3.5-3.8 again before you merge it (push it again when it has a PR); the tasks after it in id order wait.

If the spec went `blocked` during the wave (00.21), hold the merge: tasks that pass 3.8 wait, and 3.16 and 3.15 run once `modules/discovered-work.md` unblocks the spec at 00.28. A `set-task --step` write while blocked would move `.step` off the protocol's node.

### 3.15 Within the size budget?

Once per wave, after its merges:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 3.15
.agents/skills/feature-workflow/scripts/budget-check.sh --spec-dir .workflow/specs/NNN-slug
```

It prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source, basis, target, merge_base, excluded, files, test_files}`. `changed_files` is the review load of the feature's PR/MR: the files in the diff from the merge-base of `HEAD` and `main_branch` (`rules-setting.sh main_branch`) that also changed since `impl_base_revision`, outside the spec folder and the work-backlog, minus tests. So merging `main_branch` into the spec branch adds nothing, the Phase 1 harness and suite count only when a task changes them again, and test files go to `test_files`. `excluded` gives each figure left out (`tests`, `spec_backlog`, `harness_only`, `merge_base`); `files` lists what counted. When neither `main_branch` nor `origin/<main_branch>` exists locally, it counts `impl_base_revision..HEAD` instead, with a warning and a `note` (`merge_base: null`), so caught-up changes count: fetch or fix `main_branch` and run it again. When `impl_base_revision` is unset it falls back to `baseline_revision` with a warning on stderr and in `note` (`basis: "baseline_revision"`; the Phase 1 files then count): set `impl_base_revision` as in 3.1 before the next wave. Only when both are unset is `changed_files` `null`.

- **Exit 0, within budget:** go to 3.13 (the suites known from 3.1), then 3.9.
- **Exit 2, over budget:** load `modules/discovered-work.md` with origin node `3.15`, found by `budget-check.sh`, the condition `size budget: <count> changed files, max_changed_files <max>` (name each entry of `over`), and the JSON as evidence. It runs 00.21, 00.22 and the 00.29 split, re-scope or approve choice. When it returns at 00.28 (split or approve), continue at 3.13; on re-scope the spec is `draft` and this module ends. A split has already set the tasks whose work became backlog items to `split-out` (`set-task --status split-out --step 00.29`); skip them from here on.
- **Exit 1:** a usage or environment error (reason on stderr: a missing tool or file, a malformed `budget` or `test_patterns`, an unknown baseline commit, an invalid `main_branch`). Fix the cause and run it again; never treat it as within budget. A JSON `note` with `changed_files: null` means the files were not counted (neither `impl_base_revision` nor `baseline_revision` is set): set them as in 3.1 before going on.

### 3.9 Tests pass and CI green?

After each wave's 3.15, if the harness exists, run the harness on the merged spec branch through the toolchain script, `<N>` the wave number:

```bash
.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id gate-3.9-w<N> --work-type test-harness --cwd "$PWD" --exclude-unfinished
```

It runs the `test-harness` profile's keys, `test` being the harness command recorded in `## Suites`, with the `tests` of every task not yet `done` excluded through the profile's `test_scoped` key; evidence lands in `artifacts/gate-3.9-w<N>/`. Without `test_scoped` a failing `test` is reported `unscoped` (a warning, exit 0): read `toolchain.txt` yourself and judge it by the bar below. Also run the CI check when it has a local entry point. Report CI green only from a run you saw.

The spec branch is red by design until the last wave, so the bar depends on the wave:

- **Not the last wave:** passes when every test that passed at `impl_base_revision` still passes and every test of a `done` task passes: the scoped run exits 0. Tests of tasks not yet merged are excluded and may still fail.
- **The last wave** (no task left `pending`): every task is `done`, so nothing is excluded and the whole harness must pass. CI green is required only here.

- **Yes:** next frontier.
- **No:** find the task whose module and seam the failing tests cover and reopen it:

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress --step 3.9
  ```

  Give it a fix round (resume its agent, or a fresh launch when the worktree is gone), then 3.5-3.8, 3.16, 3.15 and 3.9 again. If the task cannot continue (a stop, or the fifth round fails), record it with `set-task .workflow/specs/NNN-slug T3 --status blocked --step 3.9` and go to [Stops](#stops).

## 3.10-3.11 Browser suite against the running feature

After the last wave passes 3.9 (or straight after its 3.15 when only the browser suite exists), run the browser suite yourself with Bash on the merged spec branch: the browser-suite command from `## Suites` (the `e2e` key of `.workflow/profiles/e2e-browser.md`), or `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id e2e-<run> --work-type e2e-browser --cwd "$PWD" --e2e`, which runs the profile's other command keys (`lint`, `typecheck`, `format`, `boundary`, `test`) and then `e2e` last. The 3.5 stop audit never runs `e2e`, and the evidence-capture hook does not run the suite either: it only files the run's screenshots, traces, console and network logs under `artifacts/` by run and journey id (3.12). Where that hook is not wired (Codex, or before it is installed), copy the runner's output into `artifacts/<run>/<JRN-id>/` yourself.

- **3.11 Yes, every journey passes:** `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 3.11`, then [hand off](#hand-off).
- **No:** for each failing journey, take the capability it proves (`## Journeys`, Proves column) and reopen the task serving it: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress --step 3.11`. Give it a fix round, then 3.5-3.8, 3.16, 3.15, 3.9 and 3.10 again. A task that cannot continue: `set-task .workflow/specs/NNN-slug T3 --status blocked --step 3.11`, then [Stops](#stops).

## 3.13-3.14 Light path without suites

When 3.1 found a suite missing (light path only), run the suite that exists and skip only the missing suite's gate: 3.9 for the harness, 3.10-3.11 for the browser suite. Record each gap; it is never reported as a pass:

1. Load `modules/deferred-handoff.md` with each missing suite as a `3.14 suite gap` item. It writes `.workflow/deferred/<slug>.md`, sets step 3.14 and adds the path to `deferred` in `spec.md`; in that same `spec.md` write, add one line per skipped gate under `## Known gaps` with the handoff link.
2. **Only the harness exists:** once every task is `done` or `split-out` and 3.9 passes, `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 3.14`. **Only the browser suite exists:** 3.11 sets `in-review` as above. **Neither exists:** set `in-review` at 3.14 once every task is `done` or `split-out`, and go straight to Phase 4. Sign-off flags the gap in the 5.4 report.

## Discovered work (00.21)

Discovered work is report-only: an agent found work outside the agreed scope (a new requirement, a bug along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer) and did not fix it. It reaches you as any of:

- an implementation or integration result with `status: discovered-work`;
- a non-empty `discovered_work[]` on an implementation or integration result of **any** status, `done` and `partial` included;
- a non-empty `out_of_scope_noticed` in a `profile-mini-review` return (3.7).

Never fold it into a task or brief. Load `modules/discovered-work.md` once with every entry that has arrived, each with what its "What the caller hands you" table asks: origin node `3.4` for an implementation return, `3.2` for integration, `3.7` for a mini-review; found by (the agent, task id and its return); the problem (the entry's `summary`); the evidence (its `evidence`: `path:line` or a failing test); the kind (its `kind`); and its `blocker_assessment` and `reason` as your starting assessment. It blocks the spec (`blocked_condition: "discovered work: <slug>"`), presents it to the user and records the answer.

While it waits: tasks already running finish and pass through their gates (3.4-3.8), but you merge nothing and start no new launch (3.2 or 3.3) until the user answers. When it returns at 00.28, the spec is back at `blocked_from` and you continue the wave loop unchanged: resume the reporting task on its own scope only. If it ends at 00.24 (the spec is `draft`, back to 0.3.8) or leaves the spec `blocked` for a human, this module ends; leave the worktrees in place so a later resume finds them.

## Stops

A stop halts the task. Let the rest of the wave finish its gates and merge what passed (3.16), then block the spec with a condition a human can act on: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step <node> --blocked "<what a human must decide or do>"`. A task record that is not `done` goes `blocked` too: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status blocked`.

| Event | Handling | Spec block step |
| --- | --- | --- |
| `profile-wrong` | Stop; never work around the profile. Quote the profile line in the condition. An existing profile changes only at 5.3. | 3.3 (3.2 for an integration batch) |
| `scope-expansion` into shared core | Not a stop: the request joins the next integration batch (3.2); resume the task once it is merged. | none |
| `scope-expansion` into another module | Work outside the task's agreed scope: handle it as [discovered work](#discovered-work-0021), kind `scope-expansion`, with the paths and the reason as evidence. `tasks.md` is rewritten only at 2.5, so the task is never widened. | 00.21 (via the module) |
| `discovered-work` | [Discovered work](#discovered-work-0021). | 00.21 (via the module) |
| Budget over at 3.15 | [3.15](#315-within-the-size-budget). | 00.21 (via the module) |
| `blocked` on a fact | Not a stop: look it up in the code, answer, resume the agent. | none |
| `blocked` on a decision | Ask the stakeholder; with no answer available, block with the decision as the condition. | 3.3 |
| Fifth fix round fails | Block with the open findings and the gate that keeps failing. | the failing gate (3.6, 3.8, 3.9, 3.11) |
| Integration `conflict` with no decision | Block with both consumers' needs. | 3.2 |
| `hitl` task with no human input available (3.3) | Leave it `pending`; once the rest of the wave has merged, block with what the task needs from a human (its task file's **Mode** line). | 3.3 |

## Hand off

Task worktrees and branches are already gone (3.16). Remove what is left: `git worktree list`, then `git worktree remove <path>` for each remaining implementation or integration worktree under `.workflow/.worktrees/`, and `git branch -d <branch>` for its merged branch. Then load `modules/review-triage.md`.
