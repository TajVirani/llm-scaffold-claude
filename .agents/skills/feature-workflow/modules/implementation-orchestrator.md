# Phase 3: Implementation

You run the build: classify every task, launch one implementation agent per task in dependency **waves**, pass each task through the four gates, and merge between waves. You never write feature code yourself; agents do, and the gates judge it. You are done when every task record is `done` (or `split-out`), the harness and the browser suite pass on the merged spec branch (or a light-path suite gap is recorded), the spec is `in-review`, and the workflow data you wrote under `.workflow/` is committed on the spec branch. The spec branch is **red by design** until then: Phase 1 committed tests for behaviour no task has built yet, so the full suite goes green only after the last wave (3.9, 3.11). Work outside the agreed scope is never folded into a task: it goes to `modules/discovered-work.md` (00.21-00.29).

Call the scripts from the project root exactly as written below, with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines). Status and task records change only through `status-transition.sh`.

**The project root is the spec checkout.** That is the spec worktree `.workflow/.spec-worktrees/NNN-slug` that 1.1 (0.3.20 on the light path) created on the spec branch, or the main checkout for a spec started before spec worktrees existed. The session works there (see [Route by status](../SKILL.md#3-route-by-status) for moving it in): every relative path and command below runs in it, the step marker and `artifacts/` live in it, and agent worktrees nest inside it under `.workflow/.worktrees/`. The scripts resolve it themselves, from an agent worktree too.

## Launching agents

Three task types launch here. Each prompt opens with the ```` ```yaml launch-header ```` block on its first line. The required fields come from `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements --task-type <type>`:

| Task type | Node | Header fields | Agent tool options (Claude) |
| --- | --- | --- | --- |
| `implementation` | 3.3 | `spec_dir`, `task_id`, `work_type` (the value recorded at 3.1; a disagreeing value is denied) | `run_in_background: true`; working directory = the task worktree you created at wave start (see **Claude** below) |
| `integration` | 3.2 | `spec_dir`, `work_type` (a batch, no `task_id`) | working directory = the integration worktree you create at [3.2](#32-integration-batches-one-work-type-each) (see **Claude** below) |
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
  An implementation launch runs in the task worktree you created at [wave start](#wave-start-task-branches-and-worktrees), an integration launch in the integration worktree you create at [3.2](#32-integration-batches-one-work-type-each).
  The Agent tool has no working-directory option (a sub-agent starts in the main session's directory), so launch it without `isolation` and confine it by the brief: every Bash command starts with `cd <absolute worktree path> && `, and every Read, Edit and Write uses an absolute path inside the worktree. `hooks/worktree-write-guard.sh` enforces this for implementation and integration sub-agents: it reads the agent worktree from the launch header (`.workflow/.worktrees/s<NNN>_t<N>` for a task, `s<NNN>_integration_<enc(work_type)>` for an integration batch) and denies a Write, Edit or NotebookEdit inside the main checkout but outside it, and a Bash command without that leading `cd` (accident prevention; a command can still reach out after its `cd`). The stop audit finds the worktree itself and warns when it is missing. A confined agent whose agent worktree is missing is denied every call, reads and temp-dir writes included, so recreate the worktree (as at wave start or 3.2) before you relaunch the agent. An agent that keeps getting denied, or edits the main checkout through Bash, is never relaunched another way: it is a [stop](#stops).
  Name the worktree's absolute path in the brief as the directory the agent works in. Leave out `model` and the profile: `hooks/pre-launch.sh` resolves both through `resolve-launch.sh` and returns the launch with the model set and the profile inserted after the header. A deny naming 00.14 means no model is assigned for the type (fix `.workflow/model-map/<type>.md` or `.workflow/agent-overrides.yaml` with the human); a deny naming 00.18 or 00.19 is handled in 3.1.
- **Codex** (advisory). Build each launch with the orchestrator mode, then spawn with `.prompt` as the message and `.model` as the spawn's model. The generated `.codex/agents/*.toml` never carry `model` (a toml model would override the spawn-time one), so the model you pass here is what selects it:

  ```bash
  .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type implementation --spec-dir .workflow/specs/NNN-slug --task-id T3 --work-type backend-api <<'EOF'
  <the brief>
  EOF
  ```

  Spawn with `agent_type` set to the definition name with `-` replaced by `_` (`implementation`, `integration`, `profile_mini_review`); `--task-type` keeps the hyphenated name (`profile-mini-review`). Set the spawn `task_name` to `s<NNN>_t<N>` (for example `s007_t3` for `.workflow/specs/007-checkout`, `T3`) for every implementation launch, including a fix-round relaunch (keep it exactly `s<NNN>_t<N>`: the stop audit finds the task from it), to `s<NNN>_t<N>_r<round>` (for example `s007_t3_r2`) for the 3.7 `profile-mini-review` launch of review round `<round>`, and to `s<NNN>_integration_<enc(work_type)>` (for example `s007_integration_web`) for an integration batch, where `enc` lowercases and turns every character outside `[a-z0-9]` into `_`. Codex accepts only `[a-z0-9_]` in the name, with no `/`. The Codex stop audit finds its task from it, because the spawn message is encrypted. Spawn with `fork_turns: "none"`: a full-history fork may ignore the spawn `model` override, and it keeps the parent's history out of the sub-agent. The audit reads it back from the sub-agent transcript's `session_meta` `agent_path` and blocks on toolchain failure as on Claude.

  Codex has no `isolation` option. An implementation spawn runs in the task worktree created at [wave start](#wave-start-task-branches-and-worktrees) (`.workflow/.worktrees/<task_name>` on the task branch); name it in the brief as the directory the agent works in. An integration spawn runs in the integration worktree created at [3.2](#32-integration-batches-one-work-type-each), its `task_name` being the worktree's name. The stop audit runs the toolchain in `.workflow/.worktrees/<task_name>` (evidence still goes to the spec checkout); without that directory it allows the stop with a warning. A fix-round relaunch keeps the same worktree.
- **Briefs are context pointers.** An implementation brief names the task file (`.workflow/specs/NNN-slug/<file>` from the record, committed on the spec branch so the worktree has it), the worktree path, the `codebase-map.md` extract for its module, and any shared-core interface integration applied for it. Nothing about other tasks; the task file is not pasted.
- **Resume, don't restart.** Send fix requests to the same agent (on Claude, SendMessage to the agent id from the Agent result); it keeps its worktree and context. A 3.8 fix round that changes behaviour is the exception ([Fix rounds](#per-task-gates-34-38)). When an agent cannot be continued, launch a fresh one with the same header and add to the brief: "first merge branch `<branch>` into yours, then fix: <findings>".

## Evidence and the ledger

Evidence lives under `.workflow/specs/NNN-slug/artifacts/` in the spec checkout: `<task-id>/` per task, `integration-<work_type>/` per integration batch. The toolchain evidence is written by `run-toolchain.sh` (`toolchain.json`, `toolchain.txt`, `toolchain-digest.txt`) and the stop audit (`audit.json`, `audit-loop.json`). Beside them, each agent files its own result block: the implementation agent writes `<task-id>/implementation.yaml`, `profile-mini-review` writes `<task-id>/mini-review.yaml`, an integration batch writes `integration-<work_type>/integration.yaml` (the fields are in each agent's Return section under `.agents/agents/`). The agent's final message is only a summary block naming that file. With `tasks.md` statuses, these files are your ledger: after compaction or on resume, trust them and `git log` over memory.

**Reading a result file.** You never retype a block. When an agent returns, check the file its summary names:

```bash
.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/T3/implementation.yaml
```

- **Exit 0:** it prints a header line (the status or verdict and the counts) and a short tab-separated table: discovered-work rows, integration request rows, mini-review `fail` and `tool-covered` rows, and the stop field for a stop status. Route on that output. Read any other single field with `yq`, for example `yq '.head_commit' <file>`.
- **Exit 1** (one line per shape error, each naming the field), **exit 2 for a missing file or YAML that does not parse**, or no summary at all: resume the same agent once, with the checker's lines (or "write your result file as your Return section says"). If the file is still missing or invalid, it is a [stop](#stops).
- **Exit 2 for a usage error or a missing `jq` or `yq`:** fix the cause and run it again.

**Keep earlier rounds.** Before a fix round, a rework launch or a later integration batch of the same work type, rename each result file that already exists in that folder to `<name>-r<k>.yaml`, `k` being 1 + the count of existing `<name>-r*.yaml` files of that name, so the plain name is always the newest round (sign-off and the retrospective read the plain names). Rename once, when the round that produced the file ends (a fix round, a rework), never at a re-check launch: the fix round before it already renamed, and the re-check reads the fresh `implementation.yaml` that round wrote. For example, for `mini-review.yaml`:

```bash
d=.workflow/specs/NNN-slug/artifacts/T3; k=$(( $(find "$d" -maxdepth 1 -name 'mini-review-r*.yaml' | wc -l) + 1 )); mv "$d/mini-review.yaml" "$d/mini-review-r$k.yaml"
```

The one resume for a missing or invalid file renames nothing: the agent rewrites the same file.

**Rework entry (4.7).** `review-triage` reopens tasks (`set-task --status in-progress --step 4.7`) and loads this module with one patch line per finding, spec status still `in-review`. Skip 3.1's status change (`in-review` cannot go back to `in-progress`); rename each reopened task's `implementation.yaml` and `mini-review.yaml` first ([keep earlier rounds](#evidence-and-the-ledger)), then launch it fresh with its patch lines in the brief (its mini-review is a full one), in a new task branch and worktree off the spec-branch tip ([wave start](#wave-start-task-branches-and-worktrees)), run the gates, then 3.16, 3.15, 3.9 and 3.10-3.11 as below, and set `in-review` again at 3.11 (or 3.14), which returns to `review-triage`.

**On resume** (status `in-progress`): skip `done` tasks. For an `in-progress` task, its worktree is `.workflow/.worktrees/<task_name>` on the record's `branch` (or `yq '.worktree'` on the newest `implementation.yaml`, or the `cwd` in `toolchain.json`). If the worktree has commits and a clean audit, continue at 3.7; otherwise launch it again (a fresh launch; the task stays `in-progress`). If `.step` says 3.16 or 3.15, the wave's merges may be done but its budget check is not: run 3.15 before the next frontier. After `modules/discovered-work.md` unblocks the spec at 00.28, resume the same way, at the point the block interrupted.

## 3.1 Classify each task and start

1. **Classify.** For every task whose `work_type` is null (`yq --front-matter=extract '.tasks[] | select(.work_type == null) | .id' .workflow/specs/NNN-slug/tasks.md`), pick the profile in `.workflow/profiles/` whose `## File locations` cover the task's module and kind of work, and record it. A work type is set once and never reclassified:

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --work-type <work-type> --step 3.1
   ```

   **00.18 No.** A task that fits no profile is a finding: either the task is badly cut or a work type is missing. For a missing work type, create the profile with the human from `.workflow/profiles/TEMPLATE.md` (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 00.19`, then Write `.workflow/profiles/<work-type>.md`). With no human available: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 00.19 --blocked "task T3 has no profile; define .workflow/profiles/<work-type>.md"`.

2. **Start.** `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-progress --step 3.1` (from `ready-for-dev`, or again on resume).

3. **Record the implementation base.** Check you are in the spec checkout on the spec branch (`git branch --show-current` prints the `spec_branch` from `spec.md`). If `impl_base_revision` is `""`, Edit it to `git rev-parse HEAD` now (the step is 3.1): the spec-branch tip, which holds the Phase 1 commit and the committed breakdown. On the light path, also set `baseline_revision` to the same sha if it is `""` (the spec branch's first commit, from 0.3.20). Both are never overwritten on resume or rework. The 3.15 size budget counts only files changed since `impl_base_revision`, so the Phase 1 harness and suite count only when a task changes them again.

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

**The integration worktree.** Before launching a batch, from the spec checkout, create its worktree on a `wf/` branch off the spec-branch tip. `<name>` is `s<NNN>_integration_<enc(work_type)>`, for example `s007_integration_web` (`enc` lowercases and turns every character outside `[a-z0-9]` into `_`), the name the worktree guard finds it by:

```bash
git worktree add .workflow/.worktrees/<name> -b wf/NNN-slug/<name> spec/NNN-slug
```

`.workflow/.worktrees/` is gitignored. Name the worktree's absolute path in the brief as the directory the agent works in. A resumed batch or a fix round reuses the worktree. The merge removes it, so a later batch of the same work type creates it again off the new spec-branch tip.

When a batch returns, check its result file ([Reading a result file](#evidence-and-the-ledger)) and route on the printed table:

```bash
.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/integration-<work_type>/integration.yaml
```

- **Batch `status`** (top level; `.agents/agents/integration.md` "Return"). `done` or `partial`: handle each request by its verdict below (`partial` means some requests were rejected or conflict). `discovered-work`: out-of-scope work stopped the batch and nothing was applied; go to [Discovered work](#discovered-work-0021) at step 3.2 with its `discovered_work[]` entries. `profile-wrong`: a [stop](#stops) at step 3.2, quoting `profile_wrong.line`. `blocked`: read `blocked.reason`; a fact you look up and resume the agent, a decision you put to the stakeholder, or block the spec at step 3.2 when no answer is available.
- **`discovered_work[]`.** A non-empty list goes to [Discovered work](#discovered-work-0021) at step 3.2 whatever the status, `done` and `partial` included. While that module has the spec `blocked`, hold this batch's merge as 3.16 does; merge the `applied` work once it returns at 00.28.
- **Toolchain.** The agent runs `run-toolchain.sh` itself with `--exclude-unfinished`, so the Phase 1 tests of tasks not yet `done` are excluded from its `test` run rather than left for you to judge. On Claude the stop audit then runs the full toolchain in the integration worktree with the same scoping and `--reuse`; on Codex no stop audit runs for integration. Read `artifacts/integration-<work_type>/` as at 3.5-3.6: the batch is clean when `toolchain.json` says `pass` and no `audit.json` sits beside it; `audit.json` with outcome `gave-up` means resume the agent with `toolchain-digest.txt`, as does a `toolchain.json` that does not say `pass`; `audit.json` with outcome `warning` means the audit could not run (for example, the worktree was missing), so run it yourself with `--task-id integration-<work_type> --work-type <work_type> --exclude-unfinished --cwd <worktree> --reuse`.
- **Verdicts** (per request: `applied`, `reject-not-shared-core`, `reject-other-work-type`, `conflict`, `blocked`). `applied`: the change is on the batch branch; [merge the batch](#32-integration-batches-one-work-type-each) before the wave launches, and pass the new interface into the requesting tasks' briefs. `reject-other-work-type`: move the request to that work type's batch. `reject-not-shared-core`: it is module work for the requesting task; put it in that task's brief. `conflict`: a decision; put both options to the stakeholder, re-batch with their answer, or block the spec at step 3.2 when no answer is available. `blocked`: its `reason` names what stops it; when that is an entry in `discovered_work[]`, the request waits for that ruling and is re-batched after 00.28; otherwise handle it like `conflict`.
- **Merge the batch.** When at least one request is `applied`, merge the batch in the spec checkout, on the spec branch. The branch is the one the result file names (`yq '.branch'`): `wf/NNN-slug/<name>`, the branch you created. Run the artifacts gate first, each line as its own command, never piped (a pipe hides the gate's exit code), then merge and remove the worktree and branch:

  ```bash
  .agents/skills/feature-workflow/scripts/check-merge-artifacts.sh --spec-dir .workflow/specs/NNN-slug --rev wf/NNN-slug/<name>
  git merge --no-ff -m "Merge integration-<work_type>" wf/NNN-slug/<name>
  git worktree remove .workflow/.worktrees/<name>
  git branch -d wf/NNN-slug/<name>
  ```

  Merge only on gate exit 0. Exit 1 prints each path under `artifacts/` that the branch adds, changes or deletes: resume the agent with those lines to drop that change from its branch (its result file belongs in the spec checkout only), then run the gate again. Exit 2 is a usage or environment error: fix the cause and run it again. With nothing `applied`, skip the gate and the merge and run only the two clean-up lines.
- Integration output gets no mini-review: that task type requires a `task_id`.

### Wave start: task branches and worktrees

After 3.2's merges, commit the workflow data you have written since the last commit, so the task branches fork with it. Then, for each frontier task, create its task branch off the current spec-branch tip and a worktree for it, from the spec checkout. This holds on the light path too. `<task_name>` is `s<NNN>_t<N>` (the Codex spawn name, used on both hosts) and `<branch>` is the record's `branch`:

```bash
.agents/skills/feature-workflow/scripts/commit-workflow-data.sh .workflow/specs/NNN-slug -m "Workflow data for NNN-slug: wave <N> start"
git worktree add .workflow/.worktrees/<task_name> -b <branch> spec/NNN-slug
```

A record with `branch: null` (a light-path spec written before light-path tasks got branches) still gets a task branch: use `task/NNN-slug/T01-<slug>`, the stem of its `file`, as `<branch>` here and at 3.16. A worktree that already exists (resume, fix round, rework) is reused. Integration worktrees are created at 3.2 as above.

### 3.3 Launch the wave

**No new launch while the spec is `blocked`.** Before each launch, read `status` (`yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md`). While it is `blocked` (discovered work or a crossed budget at 00.21, or any other stop), start no new implementation or integration launch; tasks already running finish and pass through their gates, including their 3.7 mini-review and fix rounds.

**Pause before a `hitl` task.** For a frontier task with `mode: hitl`, ask the stakeholder before launching it: name the human decision, credential or manual step its task file's **Mode** line says it needs, and whether it can be supplied now. Launch it when they confirm (put what they supplied in the brief); otherwise leave it `pending` and launch the rest of the wave. A `hitl` task the stakeholder cannot serve in this session blocks the spec at 3.3 once the rest of the wave has merged (see [Stops](#stops)).

For each frontier task, mark it started, then launch it in the background in its task worktree:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress
```

Launch all of the wave's tasks before handling any return. Results arrive on their own; handle each as it lands.

### Per-task gates (3.4-3.8)

For each returned implementation, check the `implementation.yaml` the agent wrote ([Reading a result file](#evidence-and-the-ledger)): `.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/<task-id>/implementation.yaml`. Then:

1. **Route the result `status`.** `done` continues below. `discovered-work` goes to [Discovered work](#discovered-work-0021). `profile-wrong`, `scope-expansion` and `blocked` go to [Stops](#stops). Separately, a non-empty `discovered_work[]` goes to [Discovered work](#discovered-work-0021) whatever the status, `done` included (a `can-wait` item may accompany a finished task); a `done` task keeps going through its gates while that module handles it.
2. **3.4 Negative and edge cases.** `tests_added` includes `negative` or `edge` tests, or the summary says why none apply. Otherwise resume the agent to add them.
3. **3.5-3.6 Tool audit clean?** On Claude the stop audit has already run the profile toolchain with `--reuse` (the command keys `lint`, `typecheck`, `format`, `boundary` and `test`; never `serve` or `serve_ready`) and blocked the agent's stop until it passed. `toolchain.json` records `tree`, the hash of the checkout's content without the workflow data folders, the Tier A files and the profiles. When the agent's own 3.5 run passed on the same tree with the same commands, the audit runs nothing: it copies that record and adds `reused_from`, the evidence dir it came from. A reused pass is a pass. Read `artifacts/<task-id>/`:
   - `toolchain.json` says `pass` and there is no `audit.json`: **clean**.
   - `audit.json` with outcome `gave-up`: the agent stopped on the same failure three times. **Not clean**: a fix round with `toolchain-digest.txt`.
   - `audit.json` with outcome `warning` (or a new line in `artifacts/audit-warnings.jsonl`): the audit could not run. Run it yourself: `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id T3 --cwd <worktree> --reuse`. Exit 0 is clean; exit 1 is a fix round with its digest; exit 2 is a header or profile problem the agent cannot fix: relaunch with a corrected header, or treat a profile problem as `profile-wrong`.
   - On Codex the stop audit works the same way, finding the task from the spawn `task_name`. A malformed `task_name` makes it warn, so handle it as the `warning` case above.

   The audit's `test` key judges this task's own tests: tests other tasks will make green are still red on the spec branch by design and never fail this task's gate.
   The scoping comes from the records: each record's `tests` lists the Phase 1 tests that task turns green (assigned at 2.5). `run-toolchain.sh` runs the profile's `test_scoped` command whenever the task's own list or the excluded set (the `tests` of every other task not yet `done`) is non-empty, with the task's own in `$WF_TASK_TESTS` and the excluded in `$WF_EXCLUDE_TESTS`. With own tests listed, only the task's own suites run; with none, every suite minus the excluded ones. Only when both are empty does it run `test` whole. The `test` result in `toolchain.json` records `own` (the count of the task's own selectors), `excluded`, and `scoped: true` whenever `test_scoped` ran. The full harness, and with it regressions outside the task's suites, is the 3.9 gate's job. A profile without `test_scoped` cannot be scoped: a failing `test` is then reported as `unscoped` with a warning in `toolchain.json` and does not block, so check that output yourself and add `test_scoped` to the profile.

   No agent looks at the diff until this is clean.
4. **3.7 Mini-review.** Launch `profile-mini-review` (header `spec_dir`, `task_id`, `work_type`). Hand over the diff as the task worktree path and the base commit (`yq '.base_commit'` on `implementation.yaml`; the reviewer runs `git -C <worktree> diff <base_commit>...HEAD`), plus `.workflow/specs/NNN-slug/artifacts/<task-id>/toolchain.json`; no diff file is written. After a wording-only fix round the launch is a re-check instead (see Fix rounds below). When it returns, check the `mini-review.yaml` it wrote: `.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/<task-id>/mini-review.yaml`. Each item is a number (the profile checklist's position, or `R1`-`R5` for the readable-code lines), a verdict, a location and, for `fail` and `tool-covered`, a one-line note; `tool-covered` items and `fail` notes ending `(rule candidate)` feed the 5.2 proposals. A non-empty `out_of_scope_noticed` never changes the verdict: hand each entry to [Discovered work](#discovered-work-0021) with origin node `3.7`, as for `discovered_work[]`. An entry it returns as **current work** (a proven problem on lines or files this task changes, usually marked `blocks-this-task`) joins this task's 3.8 fix list as one more item, `oos <evidence location>: <summary>`, so the task gets a fix round even when the verdict is `pass`; the mini-review's `not_checked` lines go nowhere.
5. **3.8 Mini-review passes?** The fix list is the failed items (`n`, `location`, `note`: the checker's `fail` rows) plus any `oos` items 3.7 added. A non-empty fix list is a fix round, routed below. An empty one (`verdict: pass` and no `oos` item) means the task is ready to merge at 3.16.

**Fix rounds.** A fix round hands the implementer the failing gate's output, followed by the gates again from 3.5 (the stop audit fires on its next stop). 3.6, 3.8, 3.9 and 3.11 failures all count. For a 3.8 fix list, what must change decides who fixes it and how. An `oos` item is judged like a failed item: it takes a wording route only when it is wording only, and otherwise makes the round a behaviour fix.

- **Wording patch.** Every item on the fix list is a comment, a name or another readable-code item, fixing it changes no behaviour, and every note gives the new text (or says to delete the comment). Make the edit yourself instead of resuming the implementer:
  1. Rename `mini-review.yaml` to `mini-review-r<k>.yaml`. Read `head_commit` and `base_commit` from `implementation.yaml`: that `head_commit` is the previous head.
  2. In the task worktree, make each edit exactly as its note gives it, and nothing else.
  3. Run the toolchain, since no stop audit fires for your edit: `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id <task-id> --cwd <worktree>`. Exit 1: the edit broke a check, so take the Wording only route below with the fix list and the digest, renaming only `implementation.yaml` there, since `mini-review.yaml` is already renamed.
  4. Commit in the worktree with a Conventional Commit subject and the task id in the body (`git -C <worktree> commit -am "docs: <the wording change>" -m "<task-id>: wording fix from the 3.7 mini-review"`). Set the new commit as `head_commit` in `implementation.yaml` (`yq -i '.head_commit = "<new sha>"'`), so the record names the task branch's tip: the re-check reads it as the new head, and the 3.16 merge takes the branch with the patch on it.
  5. Launch `profile-mini-review` as a **re-check**, with the three lines the Wording only route below gives: the previous head from step 1, the new commit as the new head.

  The patch counts as a round. A note that leaves the new text open goes the Wording only route.
- **Wording only.** Every item on the fix list is a comment, a name or another readable-code item, and fixing it changes no behaviour, but a note leaves the new text to the implementer. Rename `mini-review.yaml` to `mini-review-r<k>.yaml` and `implementation.yaml` to `implementation-r<k>.yaml` ([keep earlier rounds](#evidence-and-the-ledger); each name counts its own `k`), then resume the same agent with the fix list, one line each, `<n> <location>: <note>` (an `oos` item as 3.7 wrote it). Its profile is already in its prompt, so the number names the checklist line. When it returns with a clean check and a clean audit (3.5-3.6), launch `profile-mini-review` as a **re-check**: the header, then these three lines in place of the diff pointer. The previous head is the `head_commit` the failed review judged: read it from the `implementation-r<k>.yaml` renamed at this 3.8 failure, not from a later one that a 3.6 fix round in between renamed, or the fix diff misses the first round's changes. Take the new `head_commit` and `base_commit` from the new `implementation.yaml`:

  ```text
  re-check of: .workflow/specs/NNN-slug/artifacts/<task-id>/mini-review-r<k>.yaml
  fix diff: <worktree> <that head_commit>..<new head_commit>
  full diff: <worktree> <base_commit>..<new head_commit>
  ```

  The reviewer judges only what the fix touched plus the items that failed before, and copies every other verdict through (`.agents/agents/profile-mini-review.md`, Re-check rule).
- **Behaviour fix.** Any item on the fix list needs the code to behave differently: rename both files as above, launch a fresh agent with the same header, and add to the brief "first merge branch `<branch>` into yours, then fix: <the fix list>". Its next mini-review is a full one.
 Five rounds per task at most; at the cap, go to [Stops](#stops).

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

It prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source, basis, target, merge_base, excluded, files, test_files}`. `changed_files` is the review load of the feature's PR/MR: the files in the diff from the merge-base of `HEAD` and `main_branch` (`rules-setting.sh main_branch`) that also changed since `impl_base_revision`, outside the spec folder and the work-backlog, minus tests. So merging `main_branch` into the spec branch adds nothing, the Phase 1 harness and suite count only when a task changes them again, and test files go to `test_files`. `excluded` gives each figure left out (`tests`, `spec_backlog`, `harness_only`, `merge_base`); `files` lists what counted. When neither `main_branch` nor `origin/<main_branch>` exists locally, it counts `impl_base_revision..HEAD` instead, with a warning and a `note` (`merge_base: null`), so caught-up changes count: fetch or fix `main_branch` and run it again. When `impl_base_revision` is unset it falls back to `baseline_revision` with a warning on stderr and in `note` (`basis: "baseline_revision"`; the Phase 1 files then count): set `impl_base_revision` as in 3.1 before the next wave. Only when both are unset is `changed_files` `null`.

- **Exit 0, within budget:** go to 3.13 (the suites known from 3.1), then 3.9.
- **Exit 2, over budget:** load `modules/discovered-work.md` with origin node `3.15`, found by `budget-check.sh`, the condition `size budget: <count> changed files, max_changed_files <max>` (name each entry of `over`), and the JSON as evidence. It runs 00.21, 00.22 and the 00.29 split, re-scope or approve choice. When it returns at 00.28 (split or approve), continue at 3.13; on re-scope the spec is `draft` and this module ends. A split has already set the tasks whose work became backlog items to `split-out` (`set-task --status split-out --step 00.29`); skip them from here on.
- **Exit 1:** a usage or environment error (reason on stderr: a missing tool or file, a malformed `budget` or `test_patterns`, an unknown baseline commit, an invalid `main_branch`). Fix the cause and run it again; never treat it as within budget. A JSON `note` with `changed_files: null` means the files were not counted (neither `impl_base_revision` nor `baseline_revision` is set): set them as in 3.1 before going on.

### 3.9 Tests pass and CI green?

After each wave's 3.15, if the harness exists, run the harness on the merged spec branch through the toolchain script, `<N>` the wave number:

```bash
.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id gate-3.9-w<N> --work-type test-harness --cwd "$PWD" --exclude-unfinished --reuse
```

It runs the `test-harness` profile's keys, `test` being the harness command recorded in `## Suites`, with the `tests` of every task not yet `done` excluded through the profile's `test_scoped` key; evidence lands in `artifacts/gate-3.9-w<N>/`. With `--reuse`, a passing record of the same merged tree with the same commands is copied (`reused_from`) and nothing runs again. Short of that, a key whose exact command already passed on this tree is not run again: when the merged tree is the one the task's own run passed (one task, or a light-path fast-forward), its `test` result is reused even though that run used another profile, and only this profile's `lint` runs. The reused result carries `reused_from`. Without `test_scoped` a failing `test` is reported `unscoped` (a warning, exit 0): read `toolchain.txt` yourself and judge it by the bar below. This is now the rare case, a profile that has no `test_scoped` key. Also run the CI check when it has a local entry point. Report CI green only from a run you saw.

The spec branch is red by design until the last wave, so the bar depends on the wave:

- **Not the last wave:** passes when every test that passed at `impl_base_revision` still passes and every test of a `done` task passes: the scoped run exits 0. Tests of tasks not yet merged are excluded and may still fail.
- **The last wave** (no task left `pending`): every task is `done`, so nothing is excluded and the whole harness must pass. CI green is required only here. When Phase 1 ran as tests in tasks (`Phase 1: tests in tasks` in `design-log.md`), run the deferred 1.4 check on the merged wave first ([verification-setup](verification-setup.md#14-do-both-suites-fail-a-known-bad-build), "Tests in tasks").

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

1. **Record each missing suite on the shelf.** A project that lacked the suite before already has a shelf file for it; list the suite-gap files and read each one's Summary line:

   ```bash
   grep -l '^\*\*Origin:\*\*.*3\.14 suite gap' .workflow/deferred/*.md
   ```

   - **A file for this suite exists** (its Summary names the same missing suite): add to it without asking. `.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 3.14`, then append one line to its **Later requests** section, `- .workflow/specs/NNN-slug, 3.14: <suite> gate skipped again; <why the suite is still missing> at commit <git rev-parse HEAD>.`, add the file's path to `deferred` in `spec.md` and log a one-line note in `design-log.md`.
   - **None exists** (the first time this project shows the gap): load `modules/deferred-handoff.md` with the missing suite as a `3.14 suite gap` item. It writes `.workflow/deferred/<slug>.md`, sets step 3.14 and adds the path to `deferred` in `spec.md`.

   In that same `spec.md` write, add one line per skipped gate under `## Known gaps` with the shelf file's link.
2. **Only the harness exists:** once every task is `done` or `split-out` and 3.9 passes, `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 3.14`. **Only the browser suite exists:** 3.11 sets `in-review` as above. **Neither exists:** set `in-review` at 3.14 once every task is `done` or `split-out`, and go straight to Phase 4. Sign-off flags the gap in the 5.4 report.

## Discovered work (00.21)

Discovered work is report-only: an agent found work outside the agreed scope (a new requirement, a bug along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer) and did not fix it. It reaches you as any of:

- an implementation or integration result with `status: discovered-work`;
- a non-empty `discovered_work[]` on an implementation or integration result of **any** status, `done` and `partial` included;
- a non-empty `out_of_scope_noticed` in a `profile-mini-review` return (3.7).

Never widen a task or brief on your own. Load `modules/discovered-work.md` once with every entry that has arrived, each with what its "What the caller hands you" table asks: origin node `3.4` for an implementation return, `3.2` for integration, `3.7` for a mini-review; found by (the agent, task id and its result file); the problem (the entry's `summary`); the evidence (its `evidence`: the reproduction or the quoted line with its `path:line`); the kind (its `kind`); and the agent's `blocker_assessment` and `reason`. The module's assessment ("Assess each report first") routes each entry; what happens next depends on the route:

- **Unproven.** One design-log line; nothing else. Continue the wave.
- **Current work.** A proven problem on lines or files this spec changes, simple to fix: the task that owns those lines fixes it. For a task still in its gates, add it to that task's next fix round (a 3.7 entry joins the 3.8 fix list); for a task already `done`, reopen it as 3.9 does (`set-task ... --status in-progress --step 3.9`) and give it a fix round. No question to the stakeholder.
- **For the stakeholder.** The module records it `to ask` and returns at once; it is asked with the others at the next ask, or at 5.5. Nothing is blocked and no launch is held: continue the wave where you were, and resume the reporting task on its own scope when it stopped for the entry.
- **Blocker.** The module blocks the spec (`blocked_condition: "discovered work: <slug>"`), presents every blocker that has arrived in one call and records the ruling. While it waits: tasks already running finish and pass through their gates (3.4-3.8), but you merge nothing and start no new launch (3.2 or 3.3) until the user answers. When it returns at 00.28, the spec is back at `blocked_from` and you continue the wave loop unchanged: resume the reporting task on its own scope only. If it ends at 00.24 (the spec is `draft`, back to 0.3.8) or leaves the spec `blocked` for a human, this module ends; leave the worktrees in place so a later resume finds them.

## Stops

A stop halts the task. Let the rest of the wave finish its gates and merge what passed (3.16), then block the spec with a condition a human can act on: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step <node> --blocked "<what a human must decide or do>"`. A task record that is not `done` goes `blocked` too: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status blocked`.

| Event | Handling | Spec block step |
| --- | --- | --- |
| `profile-wrong` | Stop; never work around the profile. Quote the profile line in the condition. An existing profile changes only at 5.3. | 3.3 (3.2 for an integration batch) |
| `scope-expansion` into shared core | Not a stop: the request joins the next integration batch (3.2); resume the task once it is merged. | none |
| `scope-expansion` into another module | Work outside the task's agreed scope: handle it as [discovered work](#discovered-work-0021), kind `scope-expansion`, with the paths and the reason as evidence. `tasks.md` is rewritten only at 2.5, so the task is never widened. | 00.21 (via the module) for a blocker; none otherwise |
| `discovered-work` | [Discovered work](#discovered-work-0021). | 00.21 (via the module) for a blocker; none otherwise |
| Result file missing or invalid after one resume ([Reading a result file](#evidence-and-the-ledger)) | Block with the agent, the task and the checker's first error line. | the node that read it (3.2, 3.4, 3.7) |
| Budget over at 3.15 | [3.15](#315-within-the-size-budget). | 00.21 (via the module) |
| `blocked` on a fact | Not a stop: look it up in the code, answer, resume the agent. | none |
| `blocked` on a decision | Ask the stakeholder; with no answer available, block with the decision as the condition. | 3.3 |
| Fifth fix round fails | Block with the open findings and the gate that keeps failing. | the failing gate (3.6, 3.8, 3.9, 3.11) |
| Integration `conflict` with no decision | Block with both consumers' needs. | 3.2 |
| Agent keeps working outside its worktree (repeated worktree-guard denies, or spec-checkout edits through Bash) | Never relaunch it another way: isolation cannot be configured from this repo, and an isolation launch is refused the result-file write to the spec checkout. Block the task with the denies as the condition. | 3.3 (3.2 for an integration batch) |
| `hitl` task with no human input available (3.3) | Leave it `pending`; once the rest of the wave has merged, block with what the task needs from a human (its task file's **Mode** line). | 3.3 |

## Hand off

Task worktrees and branches are already gone (3.16). Remove what is left: `git worktree list`, then `git worktree remove <path>` for each remaining implementation or integration worktree under `.workflow/.worktrees/`, and `git branch -d <branch>` for its merged branch. Commit the workflow data the last gates wrote (3.9 and 3.10 evidence, the `in-review` status): `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh .workflow/specs/NNN-slug -m "Workflow data for NNN-slug: implementation done"`. Then load `modules/review-triage.md`.
