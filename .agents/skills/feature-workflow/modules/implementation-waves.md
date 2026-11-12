# Phase 3: Implementation, the wave loop

You run the build: launch one implementation agent per task in dependency **waves**, pass each task through the four gates, and merge between waves. Before the first wave, 3.1 classifies every task in [implementation-setup](implementation-setup.md); after the last wave, [implementation-finish](implementation-finish.md) runs the browser suite and hands off. You never write feature code yourself; agents do, and the gates judge it. You are done when every task record is `done` (or `split-out`), the harness and the browser suite pass on the merged spec branch (or a light-path suite gap is recorded), the spec is `in-review`, and the workflow data you wrote under `.workflow/` is committed on the spec branch. The spec branch is **red by design** until then: Phase 1 committed tests for behaviour no task has built yet, so the full suite goes green only after the last wave (3.9, 3.11). Work outside the agreed scope is never folded into a task: it goes to `modules/discovered-work.md` (00.21-00.28).

**The project root is the spec checkout** ([Route by status](../SKILL.md#3-route-by-status) says which folder that is and how to move the session in): every relative path and command below runs in it, the step marker and `artifacts/` live in it, and agent worktrees nest inside it under `.workflow/.worktrees/`. The scripts resolve it themselves, from an agent worktree too.

## Resume and rework

**On resume** (status `in-progress`, `impl_base_revision` set): when a task's `work_type` is null (`yq --front-matter=extract '.tasks[] | select(.work_type == null) | .id' .workflow/specs/NNN-slug/tasks.md` prints an id), load `modules/implementation-setup.md` first, run 3.1, and come back here. Then skip `done` tasks. For an `in-progress` task, its worktree is `.workflow/.worktrees/<task_name>` on the record's `branch` (or `yq '.worktree'` on the newest `implementation.yaml`, or the `cwd` in `toolchain.json`). If the worktree has commits and a clean audit, continue at 3.7 ([gates](implementation-gates.md#per-task-gates-34-38)); otherwise launch it again (a fresh launch; the task stays `in-progress`). If `.step` says 3.16 or 3.15, the wave's merges may be done but its budget check is not: run 3.15 before the next frontier. If `.step` says 3.10, 3.11 or 3.14, the waves are done: load `modules/implementation-finish.md` and continue there. After `modules/discovered-work.md` unblocks the spec at 00.28, resume the same way, at the point the block interrupted.

**Rework entry (4.7).** `review-triage` reopens tasks (`set-task --status in-progress --step 4.7`) and loads this step file with one patch line per finding, spec status still `in-review`. 3.1 does not run (its status change cannot take `in-review` back to `in-progress`); rename each reopened task's `implementation.yaml` and `mini-review.yaml` first ([keep earlier rounds](#evidence-and-the-ledger)), then launch it fresh with its patch lines in the brief (its mini-review is a full one), in a new task branch and worktree off the spec-branch tip ([wave start](#wave-start-task-branches-and-worktrees)), run the gates, then 3.16, 3.15, 3.13 and 3.9 as below and 3.10-3.11 in [implementation-finish](implementation-finish.md#310-311-browser-suite-against-the-running-feature), and set `in-review` again at 3.11 (or 3.14), which returns to `review-triage`.

## Launching agents

Three task types launch here, each with the launch header and the spawn [launching](../references/launching.md) gives for your host. The required fields come from `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements --task-type <type>`:

| Task type | Node | Header fields | Agent tool options (Claude) |
| --- | --- | --- | --- |
| `implementation` | 3.3 | `spec_dir`, `task_id`, `work_type` (the value recorded at 3.1; a disagreeing value is denied) | `run_in_background: true`; working directory = the task worktree you created at wave start (see **Claude** below) |
| `integration` | 3.2 | `spec_dir`, `work_type` (a batch, no `task_id`) | working directory = the integration worktree you create at [3.2](implementation-shared-core.md#32-integration-batches-one-work-type-each) (see **Claude** below) |
| `profile-mini-review` | 3.7 | `spec_dir`, `task_id`, `work_type` | none (read-only) |

- **Claude.** Set `subagent_type` to the task type.
  An implementation launch runs in the task worktree you created at [wave start](#wave-start-task-branches-and-worktrees), an integration launch in the integration worktree you create at [3.2](implementation-shared-core.md#32-integration-batches-one-work-type-each).
  Name the worktree's absolute path in the brief as the directory the agent works in, and confine the agent to it as [An agent worktree on Claude Code](../references/launching.md#an-agent-worktree-on-claude-code) says. A confined agent whose agent worktree is missing is denied every call, reads and temp-dir writes included, so recreate the worktree (as at wave start or 3.2) before you relaunch the agent. An agent that keeps getting denied, or edits the main checkout through Bash, is never relaunched another way: it is a [stop](#stops). A deny naming 00.18 or 00.19 is handled in 3.1.
- **Codex.** Build and spawn each launch as [launching](../references/launching.md#codex) says, passing `--task-id` and `--work-type` from the header. Its task-name table gives the name for each launch here, and its agent-worktree rule says where each spawn runs.
- **Briefs are context pointers.** An implementation brief names the task file (`.workflow/specs/NNN-slug/<file>` from the record, committed on the spec branch so the worktree has it), the worktree path, the `codebase-map.md` extract for its module, and any shared-core interface integration applied for it. Nothing about other tasks; the task file is not pasted.
- **Resume, don't restart.** Send fix requests to the same agent (on Claude, SendMessage to the agent id from the Agent result); it keeps its worktree and context. A 3.8 fix round that changes behaviour is the exception ([Fix rounds](implementation-gates.md#per-task-gates-34-38)). When an agent cannot be continued, launch a fresh one with the same header and add to the brief: "first merge branch `<branch>` into yours, then fix: <findings>".

## Evidence and the ledger

Evidence lives under `.workflow/specs/NNN-slug/artifacts/` in the spec checkout: `<task-id>/` per task, `integration-<work_type>/` per integration batch. The toolchain evidence is written by `run-toolchain.sh` (`toolchain.json`, `toolchain.txt`, `toolchain-digest.txt`) and the stop audit (`audit.json`, `audit-loop.json`). Beside them, each agent files its own result block: the implementation agent writes `<task-id>/implementation.yaml`, `profile-mini-review` writes `<task-id>/mini-review.yaml`, an integration batch writes `integration-<work_type>/integration.yaml` (the fields are in each agent's Return section under `.agents/agents/`). The agent's final message is only a summary block naming that file. With `tasks.md` statuses, these files are your ledger: after compaction or on resume, trust them and `git log` over memory.

**Reading a result file.** You never retype a block. When an agent returns, check the file its summary names:

```bash
.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/T3/implementation.yaml
```

- **Exit 0:** it prints a header line (the status or verdict and the counts) and a short tab-separated table: discovered-work rows, integration request rows, mini-review `fail` and `tool-covered` rows, and the stop field for a stop status. Route on that output. Read any other single field with `yq`, for example `yq '.head_commit' <file>`.
- **Exit 1** (one line per shape error, each naming the field), **exit 2 for a missing file or YAML that does not parse**, or no summary at all: resume the same agent once, with the checker's lines (or "write your result file as your Return section says"). If the file is still missing or invalid, it is a [stop](#stops).
- **Exit 2 for a usage error or a missing `jq` or `yq`:** fix the cause and run it again.

**Keep earlier rounds.** Before a fix round, a rework launch or a later integration batch of the same work type, rename each result file that already exists in that folder to `<name>-r<k>.yaml`, `k` being 1 + the count of existing `<name>-r*.yaml` files of that name, so the plain name is always the newest round (sign-off and the retrospective read the plain names). Rename once, when the round that produced the file ends (a fix round, a rework, a patch you apply at 3.8). For example, for `mini-review.yaml`:

```bash
d=.workflow/specs/NNN-slug/artifacts/T3; k=$(( $(find "$d" -maxdepth 1 -name 'mini-review-r*.yaml' | wc -l) + 1 )); mv "$d/mini-review.yaml" "$d/mini-review-r$k.yaml"
```

The one resume for a missing or invalid file renames nothing: the agent rewrites the same file.

## The wave loop

Repeat until no task is `pending`. A `split-out` task is terminal: it is never launched, never in a frontier, and never counted by an "every task is done" check. Each wave runs 3.2, the [wave start](#wave-start-task-branches-and-worktrees), 3.3, the per-task gates 3.4-3.8, then 3.16 (merge), 3.15 (budget), 3.13 and 3.9, in that order. The frontier is every pending task whose dependencies are all `done`:

```bash
yq --front-matter=extract '[.tasks[] | select(.status == "done") | .id] as $done
  | .tasks[] | select(.status == "pending" and ((.depends_on - $done) | length) == 0) | .id' .workflow/specs/NNN-slug/tasks.md
```

An empty frontier with tasks still pending means they wait on a `blocked` task: go to [Stops](#stops). When no task is left `pending` and the last wave has passed 3.9 (or skipped it at 3.13), load `modules/implementation-finish.md` for 3.10-3.11, 3.14 and the hand off.

### Shared-core changes before the wave

Before launching the wave, look for shared-core change requests: the **Notes** request of a frontier task with `touches_core: true`, or a shared-core request from a `scope-expansion` result. When there is one, load `modules/implementation-shared-core.md` and run 3.2 there: it batches the requests by work type, launches each batch in its own integration worktree and merges what was applied, then returns here for the wave start. With none, go straight to the wave start.

### Wave start: task branches and worktrees

After 3.2's merges, commit the workflow data you have written since the last commit, so the task branches fork with it. Then, for each frontier task, create its task branch off the current spec-branch tip and a worktree for it, from the spec checkout. This holds on the light path too. `<task_name>` is `s<NNN>_t<N>` (the Codex spawn name, used on both hosts) and `<branch>` is the record's `branch`:

```bash
.agents/skills/feature-workflow/scripts/commit-workflow-data.sh .workflow/specs/NNN-slug -m "Workflow data for NNN-slug: wave <N> start"
git worktree add .workflow/.worktrees/<task_name> -b <branch> spec/NNN-slug
```

A worktree that already exists (resume, fix round, rework) is reused. Integration worktrees are created at 3.2, in `modules/implementation-shared-core.md`.

### 3.3 Launch the wave

**No new launch while the spec is `blocked`.** Before each launch, read `status` (`yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md`). While it is `blocked` (discovered work at 00.21, or any other stop), start no new implementation or integration launch; tasks already running finish and pass through their gates, including their 3.7 mini-review and fix rounds.

**Pause before a `hitl` task.** Launch the wave's other tasks first, so they run while the stakeholder answers ([conventions](../references/conventions.md#asking-the-stakeholder)). Then, for a frontier task with `mode: hitl`, ask the stakeholder before launching it: name the human decision, credential or manual step its task file's **Mode** line says it needs, and whether it can be supplied now. Launch it when they confirm (put what they supplied in the brief); otherwise leave it `pending` and launch the rest of the wave. A `hitl` task the stakeholder cannot serve in this session blocks the spec at 3.3 once the rest of the wave has merged (see [Stops](#stops)).

For each frontier task, mark it started, then launch it in the background in its task worktree:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress
.agents/skills/issue-tracking/scripts/issue-tracker.sh move <issue> in_progress
```

Launch all of the wave's tasks before handling any return. Results arrive on their own; handle each as it lands.

### Gates for each returned task

When the first implementation agent of a wave returns, load `modules/implementation-gates.md` and pass every returned task through it: result routing, the 3.4 negative and edge cases, the 3.5-3.6 tool audit, the 3.7 mini-review and 3.8 with its fix rounds. A task that passes 3.8 waits for 3.16 below. Every later pass through 3.5-3.8 runs from the same file: a fix round after 3.9 or 3.11, a 3.16 merge conflict or `pr-blocking` review, and a resume that continues at 3.7.

### 3.16 Merge the wave

When every task of the wave has passed 3.8 (or is blocked), take the passing tasks **in task-id order** (T2 before T3, also for approved `parallel_with` pairs). For each, in the spec checkout on the spec branch:

1. **Task review.** Read the setting from `.workflow/rules.md` (`pr` when the section or key is absent):

   ```bash
   .agents/skills/feature-workflow/scripts/rules-setting.sh task_review   # prints pr | pr-blocking | local; exit 1 on an invalid value
   ```

   A PR needs a host: when `origin` is on neither GitHub nor GitLab, or there is no `origin`, `pr` and `pr-blocking` print `local`, with a stderr note giving the reason. The first time a spec reads `local` this way, append that note once to `design-log.md` as a **Merge route** entry; every task and the spec itself then merge locally, with no per-task log line.

   For `pr` and `pr-blocking`, `.agents/skills/feature-workflow/scripts/open-task-pr.sh .workflow/specs/NNN-slug T3 --record` does the push, picks gh or glab from the `origin` host, reuses an open PR/MR for the same branches, records the URL with `set-task --pr --step 3.16`, and prints the URL or `skipped: <reason>` (always exit 0); the bullets below are what it does.

   - `pr` (default): push the spec branch and the task branch (`git push -u origin spec/NNN-slug <branch>`; the setting is the stakeholder's standing consent to push these two branches) and open a PR/MR from the task branch into the spec branch, titled `T3: <task title>`, its body linking the task file and the mini-review verdict: `gh pr create --base spec/NNN-slug --head <branch> ...` when the `origin` remote is GitHub, `glab mr create --target-branch spec/NNN-slug --source-branch <branch> ...` when it is GitLab (the `glab` skill has the flags). It is a **non-blocking** review record: record its URL (`set-task ... T3 --pr <url> --step 3.16`) and continue without waiting. A missing or logged-out CLI, or a failed push: skip the PR, leave `pr: null` and append one line to `design-log.md` saying why.
   - `pr-blocking`: as `pr`, then wait for approval before merging (`gh pr view <url> --json reviewDecision`, or `glab mr approvers`). Tell the stakeholder which PRs wait; merge each once approved. Review comments that ask for changes are a fix round (3.5-3.8 again, push again).
   - `local`: no push, no PR; `pr` stays null.
2. **Gate, merge and mark done** (tasks become `done` only here). Run the artifacts gate first, each line as its own command, never piped (a pipe hides the gate's exit code):

   ```bash
   .agents/skills/feature-workflow/scripts/check-merge-artifacts.sh --spec-dir .workflow/specs/NNN-slug --rev <branch>
   git merge --no-ff -m "Merge T3: <task title>" <branch>   # the message names the task id; 4.7 finds task owners by it
   .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status done --step 3.16
   .agents/skills/issue-tracking/scripts/issue-tracker.sh move <issue> done
   ```

   The light path merges its task branch the same way, `--no-ff`, so `git log` names T1 by its merge as on the full path.

   Merge only on gate exit 0. Exit 1 prints each path under `artifacts/` that the task adds, changes or deletes: resume the implementer with those lines to drop that change from its commits (its result file belongs in the spec checkout only), then run the gate again; the tasks after it in id order wait. Exit 2 is a usage or environment error: fix the cause and run it again.
3. **Clean up.** With `pr` or `pr-blocking`, push the spec branch so the PR/MR shows as merged. Then, on both paths, `git worktree remove .workflow/.worktrees/<task_name>` and `git branch -d <branch>` (the safe delete: the branch is merged). The next wave forks from the new spec-branch tip.
4. **Commit the workflow data.** Once the wave's merges are done, commit what the wave wrote under `.workflow/` (task records, gate evidence under `artifacts/`, `design-log.md`, deferred items, decisions) on the spec branch, so it sits beside the merged code:

   ```bash
   .agents/skills/feature-workflow/scripts/commit-workflow-data.sh .workflow/specs/NNN-slug -m "Workflow data for NNN-slug: wave <N> merged"
   ```

   It stages the spec folder, the work-backlog and the rest of `.workflow/` except other spec and initiative folders, leaves gitignored state (`.step`, `.worktrees/`) out, commits only those paths and prints `committed <sha>` or `nothing to commit`. Exit 1 means the spec checkout is off the spec branch (or detached) or mid-merge: fix that and run it again. Exit 2 with `local state is not gitignored` means the `.gitignore` workflow block is missing an entry: restore it (install.sh writes it), never commit the path.

On a merge conflict, run `git merge --abort` and resume that implementer: "merge the spec branch into your branch, resolve the conflict, re-run your tests, commit". Its diff changed, so it passes 3.5-3.8 again before you merge it (push it again when it has a PR); the tasks after it in id order wait.

If the spec went `blocked` during the wave (00.21), hold the merge: tasks that pass 3.8 wait, and 3.16 and 3.15 run once `modules/discovered-work.md` unblocks the spec at 00.28. A `set-task --step` write while blocked would move `.step` off the protocol's node.

### 3.15 Within the size budget?

Once per wave, after its merges:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 3.15
.agents/skills/feature-workflow/scripts/budget-check.sh --spec-dir .workflow/specs/NNN-slug
```

It prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source, basis, target, merge_base, excluded, files, test_files}`. `changed_files` is the review load of the feature's PR/MR: the files in the diff from the merge-base of `HEAD` and `main_branch` that also changed since `impl_base_revision`, outside the spec folder and the work-backlog, minus tests (`test_files`); `excluded` gives each figure left out and `files` what counted. Without a local `main_branch` or `origin/<main_branch>`, `merge_base` is null and caught-up changes count (a `note` says so): fetch or fix `main_branch` and run it again. With `impl_base_revision` unset nothing is counted (`changed_files: null`, and a `note` says why): set it as in 3.1 and run it again.

- **Exit 0, within budget:** go to 3.13, then 3.9.
- **Exit 2, over budget:** not a stop, and nothing is asked. When `design-log.md` has no **Size budget overrun** entry yet (`grep -q '^## .* Size budget overrun' .workflow/specs/NNN-slug/design-log.md` fails), append one with the figures from the JSON; a later wave adds nothing. Then go to 3.13; sign-off reports the final figures (5.4).
- **Exit 1:** a usage or environment error (reason on stderr: a missing tool or file, a malformed setting, an unknown commit). Fix the cause and run it again; never treat it as within budget.

### 3.13 Do both suites exist?

After each wave's 3.15, look up which suites exist (a fact, not a question). On the full path both do: Phase 1 built them and `## Suites` in `verification-plan.md` names their commands. On the light path, the harness exists when the repo has a unit or integration test command to run (the profile Toolchain `test` key); the browser suite exists when `.workflow/profiles/e2e-browser.md` has a non-empty `e2e` command. A missing suite skips only its own gate, 3.9 for the harness and 3.10-3.11 for the browser suite, and is recorded at [3.14](implementation-finish.md#314-record-each-missing-suite); it is never reported as a pass.

- **The harness exists:** run 3.9.
- **It is missing:** skip 3.9 and go on as 3.9's **Yes** does.

### 3.9 Tests pass and CI green?

After each wave's 3.13, when the harness exists, run the harness on the merged spec branch through the toolchain script, `<N>` the wave number:

```bash
.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id gate-3.9-w<N> --work-type test-harness --cwd "$PWD" --exclude-unfinished --reuse
```

It runs the `test-harness` profile's keys, `test` being the harness command recorded in `## Suites`, with the `tests` of every task not yet `done` excluded through the profile's `test_scoped` key; evidence lands in `artifacts/gate-3.9-w<N>/`. With `--reuse`, a passing record of the same merged tree with the same commands is copied (`reused_from`) and nothing runs again; a task's own run is scoped to its changed files, so the gate never reuses it. This gate is the one place the whole harness runs in a wave: agents, fix rounds and the stop audit run only the suites that cover their changed files. Without `test_scoped` a failing `test` is reported `unscoped` (a warning, exit 0): read `toolchain.txt` yourself and judge it by the bar below. Also run the CI check when it has a local entry point. Report CI green only from a run you saw.

The spec branch is red by design until the last wave, so the bar depends on the wave:

- **Not the last wave:** passes when every test that passed at `impl_base_revision` still passes and every test of a `done` task passes: the scoped run exits 0. Tests of tasks not yet merged are excluded and may still fail.
- **The last wave** (no task left `pending`): every task is `done`, so nothing is excluded and the whole harness must pass. CI green is required only here. When Phase 1 ran as tests in tasks (`Phase 1: tests in tasks` in `design-log.md`), run the deferred 1.4 check on the merged wave first ([verification-setup](verification-setup.md#14-do-both-suites-fail-a-known-bad-build), "Tests in tasks").

- **Yes:** next frontier; after the last wave, load `modules/implementation-finish.md`.
- **No:** find the task whose module and seam the failing tests cover and reopen it:

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress --step 3.9
  .agents/skills/issue-tracking/scripts/issue-tracker.sh move <issue> in_progress
  ```

  Give it a fix round (resume its agent, or a fresh launch when the worktree is gone), then 3.5-3.8 ([gates](implementation-gates.md#per-task-gates-34-38)), 3.16, 3.15 and 3.9 again. If the task cannot continue (a stop, or the fifth round fails), record it with `set-task .workflow/specs/NNN-slug T3 --status blocked --step 3.9` and go to [Stops](#stops).

## Discovered work (00.21)

Discovered work is report-only: an agent found work outside the agreed scope and did not fix it. It reaches you as any of:

- an implementation or integration result with `status: discovered-work`;
- a non-empty `discovered_work[]` on an implementation or integration result of **any** status, `done` and `partial` included;
- a non-empty `out_of_scope_noticed` in a `profile-mini-review` return (3.7).

Never widen a task or brief on your own. Load `modules/discovered-work.md` once with every entry that has arrived, each with what its "What the caller hands you" table asks: origin node `3.4` for an implementation return, `3.2` for integration, `3.7` for a mini-review; found by (the agent, task id and its result file); the problem (the entry's `summary`); the evidence (its `evidence`: the reproduction or the quoted line with its `path:line`); the kind (its `kind`); and the agent's `blocker_assessment` and `reason`. The module's assessment ("Assess each report first") routes each entry; what happens next depends on the route:

- **Unproven.** One design-log line; nothing else. Continue the wave.
- **Current work.** A proven problem on lines or files this spec changes, simple to fix: the task that owns those lines fixes it. For a task still in its gates, add it to that task's next fix round (a 3.7 entry joins the 3.8 fix list); for a task already `done`, reopen it as 3.9 does (`set-task ... --status in-progress --step 3.9`) and give it a fix round. No question to the stakeholder.
- **For the stakeholder.** The module records it `to ask` and returns at once; it is asked with the others at the next ask, or at 5.5. Nothing is blocked and no launch is held: continue the wave where you were, and resume the reporting task on its own scope when it stopped for the entry.
- **Blocker.** The module blocks the spec (`blocked_condition: "discovered work: <slug>"`), presents every blocker that has arrived in one call and records the ruling. While it waits: tasks already running finish and pass through their gates (3.4-3.8), but you merge nothing and start no new launch (3.2 or 3.3) until the user answers. When it returns at 00.28, the spec is back at `blocked_from` and you continue the wave loop unchanged: resume the reporting task on its own scope only. If it ends at 00.24 (the spec is `draft`, back to 0.3.8) or leaves the spec `blocked` for a human, Phase 3 stops here; leave the worktrees in place so a later resume finds them.

## Stops

A stop halts the task. Let the rest of the wave finish its gates and merge what passed (3.16), then block the spec with a condition a human can act on: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step <node> --blocked "<what a human must decide or do>"`. A task record that is not `done` goes `blocked` too: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status blocked`.

| Event | Handling | Spec block step |
| --- | --- | --- |
| `profile-wrong` | Stop; never work around the profile. Quote the profile line in the condition. An existing profile changes only at 5.3. | 3.3 (3.2 for an integration batch) |
| `scope-expansion` into shared core | Not a stop: the request joins the next integration batch (3.2); resume the task once it is merged. | none |
| `scope-expansion` into another module | Work outside the task's agreed scope: handle it as [discovered work](#discovered-work-0021), kind `scope-expansion`, with the paths and the reason as evidence. `tasks.md` is rewritten only at 2.5, so the task is never widened. | 00.21 (via the module) for a blocker; none otherwise |
| `discovered-work` | [Discovered work](#discovered-work-0021). | 00.21 (via the module) for a blocker; none otherwise |
| Result file missing or invalid after one resume ([Reading a result file](#evidence-and-the-ledger)) | Block with the agent, the task and the checker's first error line. | the node that read it (3.2, 3.4, 3.7) |
| Budget over at 3.15 | Not a stop: [3.15](#315-within-the-size-budget) logs it once. | none |
| `blocked` on a fact | Not a stop: look it up in the code, answer, resume the agent. | none |
| `blocked` on a decision | When its answer changes scope or intent, or the action is hard to reverse, ask the stakeholder; with no answer available, block with the decision as the condition. Any other decision: assume and log it as [conventions](../references/conventions.md#asking-the-stakeholder) says, then resume the agent with it. | 3.3 for a block; none otherwise |
| Fifth fix round fails | Block with the open findings and the gate that keeps failing. | the failing gate (3.6, 3.8, 3.9, 3.11) |
| Integration `conflict` with no decision | Block with both consumers' needs. | 3.2 |
| Agent keeps working outside its worktree (repeated worktree-guard denies, or spec-checkout edits through Bash) | Never relaunch it another way: isolation cannot be configured from this repo, and an isolation launch is refused the result-file write to the spec checkout. Block the task with the denies as the condition. | 3.3 (3.2 for an integration batch) |
| `hitl` task with no human input available (3.3) | Leave it `pending`; once the rest of the wave has merged, block with what the task needs from a human (its task file's **Mode** line). | 3.3 |

