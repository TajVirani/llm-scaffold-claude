<!--
File: Phase 3 module of `feature-workflow` (3.1-3.16): the main-session orchestrator. Classifies tasks, launches one implementation agent per task in dependency waves, batches shared-core work for integration, drives the four gates, merges each wave (3.16) and checks the size budget after it (3.15), and hands discovered work to modules/discovered-work.md (00.21-00.29).
Triggers/inputs: specs/NNN-slug/tasks.md with spec status `ready-for-dev` (full path from modules/task-breakdown.md; light path from 0.3.20 with a one-task tasks.md, D14), or `in-progress` on resume. Reads spec.md, tasks.md, verification-plan.md (`## Journeys`, `## Suites`), codebase-map.md, docs/rules.md, profiles/.
Outputs/handoff: Merged task branches on the feature branch, task records `done`, evidence under specs/NNN-slug/artifacts/, spec status `in-review` (3.11, or 3.14 on a light path without suites). Hands off to modules/review-triage.md; discovered work and a crossed size budget go to modules/discovered-work.md (00.21).
Plan refs: PLAN/decision-flow.mermaid P3 (3.1-3.16), 00.18-00.21; reference "Phase 3 - Implementation", "The four gates of Phase 3", "Model selection", "Status" (task statuses), "Sub-agent task types"; assetlist D5, D9, D13, D14, D18, D19, D28, D29, D31, D33, D35, D37, D40, D45, D50, D53, D55, D56, D58, D59, D60, D61, D62, D66, D67, D68.
Sources: first-party. Frontier-driven waves, one worktree and branch per implementer, background launches, context pointers, a dedicated integration owner, worktree clean-up at the end: mattpocock/skills/skills/engineering/implement-spec/SKILL.md@49dd158 (MIT). Record the base commit before dispatch; resume the same implementer with the findings; cap a task's fix loop at five rounds; never fix in the controller; a ledger that survives compaction: obra/superpowers skills/subagent-driven-development/SKILL.md (MIT, (c) 2025 Jesse Vincent). Native worktree tool first, `git worktree add` as fallback: obra/superpowers skills/using-git-worktrees/SKILL.md (MIT). Waves from depends_on: open-gsd/gsd-core agents/gsd-planner.md (MIT, (c) 2026 Open GSD). Execution tracking prior art: claude-night-market spec-kit agents/implementation-executor.md (MIT). The four gates, integration batching per work type, the light-path suite gap and the Codex advisory calls are first-party (plan). Patterns only; no substantial text copied.
-->

# Phase 3: Implementation

You run the build: classify every task, launch one implementation agent per task in dependency **waves**, pass each task through the four gates, and merge between waves. You never write feature code yourself; agents do, and the gates judge it. You are done when every task record is `done` (or `split-out`, D68), the harness and the browser suite pass on the merged feature branch (or a light-path suite gap is recorded), and the spec is `in-review`. Work outside the agreed scope is never folded into a task: it goes to `modules/discovered-work.md` (00.21-00.29; D56).

Call the scripts from the project root exactly as written below, with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines; D36). Status and task records change only through `status-transition.sh` (D16, D45).

## Launching agents

Three task types launch here. Each prompt opens with the ```` ```yaml launch-header ```` block on its first line (D37). The required fields come from `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements --task-type <type>` (D31):

| Task type | Node | Header fields | Agent tool options (Claude) |
| --- | --- | --- | --- |
| `implementation` | 3.3 | `spec_dir`, `task_id`, `work_type` (the value recorded at 3.1; a disagreeing value is denied) | `isolation: "worktree"`, `run_in_background: true` |
| `integration` | 3.2 | `spec_dir`, `work_type` (a batch, no `task_id`; D28) | `isolation: "worktree"` |
| `profile-mini-review` | 3.7 | `spec_dir`, `task_id`, `work_type` | none (read-only) |

````text
```yaml launch-header
task_type: implementation
spec_dir: specs/NNN-slug
task_id: T3
work_type: backend-api
```
<the brief>
````

- **Claude.** Set `subagent_type` to the task type. Leave out `model` and the profile: `hooks/pre-launch.sh` resolves both through `resolve-launch.sh` and returns the launch with the model set and the profile inserted after the header (D33, D35). A deny naming 00.14 means no model is assigned for the type (fix `model-map/<type>.md` or `agent-overrides.yaml` with the human); a deny naming 00.18 or 00.19 is handled in 3.1.
- **Codex** (advisory, D9, D40). Build each launch with the orchestrator mode, then spawn with `.prompt` as the message and `.model` as the spawn's model. The generated `.codex/agents/*.toml` never carry `model` (a toml model would override the spawn-time one), so the model you pass here is what selects it (D67):

  ```bash
  .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type implementation --spec-dir specs/NNN-slug --task-id T3 --work-type backend-api <<'EOF'
  <the brief>
  EOF
  ```

  Spawn with `agent_type` set to the definition name with `-` replaced by `_` (`implementation`, `integration`, `profile_mini_review`); `--task-type` keeps the hyphenated name (`profile-mini-review`). Set the spawn `task_name` to `s<NNN>_t<N>` (for example `s007_t3` for `specs/007-checkout`, `T3`) for every implementation launch, including a fix-round relaunch (keep it exactly `s<NNN>_t<N>`: the stop audit finds the task from it), to `s<NNN>_t<N>_r<round>` (for example `s007_t3_r2`) for the 3.7 `profile-mini-review` launch of review round `<round>`, and to `s<NNN>_integration_<enc(work_type)>` (for example `s007_integration_web`) for an integration batch, where `enc` lowercases and turns every character outside `[a-z0-9]` into `_`. Codex accepts only `[a-z0-9_]` in the name, with no `/`. The Codex stop audit finds its task from it, because the spawn message is encrypted (D66). Spawn with `fork_turns: "none"`: a full-history fork may ignore the spawn `model` override (D67), and it keeps the parent's history out of the sub-agent. The audit reads it back from the sub-agent transcript's `session_meta` `agent_path` and blocks on toolchain failure as on Claude.

  Codex has no `isolation` option: create each implementation and integration worktree yourself before the spawn, named by its `task_name`: `git worktree add .worktrees/<task_name> -b wf/NNN-slug/<task_name>` (for example `.worktrees/s007_t3` on branch `wf/007-checkout/s007_t3`), with `.worktrees/` gitignored, and name it in the brief as the directory the agent works in. The stop audit runs the toolchain in `.worktrees/<task_name>` (evidence still goes to the main checkout); without that directory it allows the stop with a warning. A fix-round relaunch keeps the same worktree.
- **Briefs are context pointers.** An implementation brief holds the task's section of `tasks.md` (what to build, seam, acceptance criteria), the `codebase-map.md` extract for its module, and any shared-core interface integration applied for it. Nothing about other tasks.
- **Resume, don't restart.** Send fix requests to the same agent (on Claude, SendMessage to the agent id from the Agent result); it keeps its worktree and context. When an agent cannot be continued, launch a fresh one with the same header and add to the brief: "first merge branch `<branch>` into yours, then fix: <findings>".

## Evidence and the ledger

Evidence lives under `specs/NNN-slug/artifacts/` in the main checkout: `<task-id>/` per task, `integration-<work_type>/` per integration batch. The toolchain evidence is written by `run-toolchain.sh` (`toolchain.json`, `toolchain.txt`, `toolchain-digest.txt`) and the stop audit (`audit.json`, `audit-loop.json`). Beside them, save each agent's final result block as you receive it: `implementation.yaml`, `mini-review.yaml`, `integration.yaml`. With `tasks.md` statuses, these files are your ledger: after compaction or on resume, trust them and `git log` over memory.

**Rework entry (4.7).** `review-triage` reopens tasks (`set-task --status in-progress --step 4.7`) and loads this module with one patch line per finding, spec status still `in-review`. Skip 3.1's status change (`in-review` cannot go back to `in-progress`); launch each reopened task fresh with its patch lines in the brief, run the gates, then 3.16, 3.15, 3.9 and 3.10-3.11 as below, and set `in-review` again at 3.11 (or 3.14), which returns to `review-triage`.

**On resume** (status `in-progress`): skip `done` tasks. For an `in-progress` task, find its worktree from `implementation.yaml` (or the `cwd` in `toolchain.json`). If the worktree has commits and a clean audit, continue at 3.7; otherwise launch it again (a fresh launch; the task stays `in-progress`). If `.step` says 3.16 or 3.15, the wave's merges may be done but its budget check is not: run 3.15 before the next frontier. After `modules/discovered-work.md` unblocks the spec at 00.28, resume the same way, at the point the block interrupted.

## 3.1 Classify each task and start

1. **Classify.** For every task whose `work_type` is null (`yq --front-matter=extract '.tasks[] | select(.work_type == null) | .id' specs/NNN-slug/tasks.md`), pick the profile in `profiles/` whose `## File locations` cover the task's module and kind of work, and record it. A work type is set once and never reclassified:

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T3 --work-type <work-type> --step 3.1
   ```

   **00.18 No.** A task that fits no profile is a finding: either the task is badly cut or a work type is missing. For a missing work type, create the profile with the human from `profiles/TEMPLATE.md` (`.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 00.19`, then Write `profiles/<work-type>.md`; D50). With no human available: `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug blocked --step 00.19 --blocked "task T3 has no profile; define profiles/<work-type>.md"`.

2. **Start.** `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug in-progress --step 3.1` (from `ready-for-dev`, or again on resume).

3. **Light path only: capture the baseline (D53).** If `spec.md` has `light_path: true` and `baseline_revision: ""`, Edit that key to `git rev-parse HEAD` now (the step is 3.1).

4. **3.13: do both suites exist?** On the full path, yes: Phase 1 built them and `## Suites` in `verification-plan.md` names their commands. On the light path, look it up (a fact, not a question): the harness exists when the repo has a unit or integration test command to run (the profile Toolchain `test` key, D61); the browser suite exists when `profiles/e2e-browser.md` has a non-empty `e2e` command. Each missing suite skips its gate and is recorded at 3.14.

**Done when:** every task has a `work_type`, the spec is `in-progress`, and you know which suites exist.

## The wave loop

Repeat until no task is `pending`. A `split-out` task (D68) is terminal: it is never launched, never in a frontier, and never counted by an "every task is done" check. Each wave runs 3.2, 3.3, the per-task gates 3.4-3.8, then 3.16 (merge), 3.15 (budget), 3.13 and 3.9, in that order. The frontier is every pending task whose dependencies are all `done`:

```bash
yq --front-matter=extract '[.tasks[] | select(.status == "done") | .id] as $done
  | .tasks[] | select(.status == "pending" and ((.depends_on - $done) | length) == 0) | .id' specs/NNN-slug/tasks.md
```

An empty frontier with tasks still pending means they wait on a `blocked` task: go to [Stops](#stops).

### 3.2 Integration batches, one work type each

Before launching the wave, collect its shared-core change requests: the **Notes** request of every frontier task with `touches_core: true`, plus shared-core requests from `scope-expansion` results. Group them by the requesting task's `work_type`, one batch per work type, so each launch carries exactly one profile (D28). Launch the batches one at a time (header `task_type: integration`, `spec_dir`, `work_type`); each brief is a numbered list of requests, each stating the change and the contract its consumer needs, without task context.

When a batch returns:

- **Batch `status`** (top level; `.agents/agents/integration.md` "Return"). `done` or `partial`: handle each request by its verdict below (`partial` means some requests were rejected or conflict). `discovered-work`: out-of-scope work stopped the batch and nothing was applied; go to [Discovered work](#discovered-work-0021) at step 3.2 with its `discovered_work[]` entries. `profile-wrong`: a [stop](#stops) at step 3.2, quoting `profile_wrong.line`. `blocked`: read `blocked.reason`; a fact you look up and resume the agent, a decision you put to the stakeholder, or block the spec at step 3.2 when no answer is available.
- **`discovered_work[]`.** A non-empty list goes to [Discovered work](#discovered-work-0021) at step 3.2 whatever the status, `done` and `partial` included. While that module has the spec `blocked`, hold this batch's merge as 3.16 does; merge the `applied` work once it returns at 00.28.
- **Toolchain.** No stop audit fires for integration; the agent runs `run-toolchain.sh` itself. Check `artifacts/integration-<work_type>/toolchain.json` says `pass`; otherwise resume the agent with `toolchain-digest.txt`.
- **Verdicts** (per request: `applied`, `reject-not-shared-core`, `reject-other-work-type`, `conflict`, `blocked`). `applied`: merge its branch (`worktreeBranch` from the Agent result) into the feature branch with `git merge --no-ff -m "Merge integration-<work_type>" <branch>` before the wave launches, and pass the new interface into the requesting tasks' briefs. `reject-other-work-type`: move the request to that work type's batch. `reject-not-shared-core`: it is module work for the requesting task; put it in that task's brief. `conflict`: a decision; put both options to the stakeholder, re-batch with their answer, or block the spec at step 3.2 when no answer is available. `blocked`: its `reason` names what stops it; when that is an entry in `discovered_work[]`, the request waits for that ruling and is re-batched after 00.28; otherwise handle it like `conflict`.
- Integration output gets no mini-review: that task type requires a `task_id` (D31).

### 3.3 Launch the wave

**No new launch while the spec is `blocked`.** Before each launch, read `status` (`yq --front-matter=extract '.status' specs/NNN-slug/spec.md`). While it is `blocked` (discovered work or a crossed budget at 00.21, or any other stop), start no new implementation or integration launch; tasks already running finish and pass through their gates, including their 3.7 mini-review and fix rounds (D56).

For each frontier task, mark it started, then launch it in the background in its own worktree:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T3 --status in-progress
```

Launch all of the wave's tasks before handling any return. Results arrive on their own; handle each as it lands.

### Per-task gates (3.4-3.8)

For each returned implementation, save `implementation.yaml`, then:

1. **Route the result `status`.** `done` continues below. `discovered-work` goes to [Discovered work](#discovered-work-0021). `profile-wrong`, `scope-expansion` and `blocked` go to [Stops](#stops). Separately, a non-empty `discovered_work[]` goes to [Discovered work](#discovered-work-0021) whatever the status, `done` included (a `can-wait` item may accompany a finished task); a `done` task keeps going through its gates while that module handles it.
2. **3.4 Negative and edge cases.** `tests_added` includes `negative` or `edge` tests, or the summary says why none apply. Otherwise resume the agent to add them.
3. **3.5-3.6 Tool audit clean?** On Claude the stop audit has already run the profile toolchain (the command keys `lint`, `typecheck`, `format`, `boundary` and `test`; never `serve` or `serve_ready`; D61, D62) and blocked the agent's stop until it passed (D19). Read `artifacts/<task-id>/`:
   - `toolchain.json` says `pass` and there is no `audit.json`: **clean**.
   - `audit.json` with outcome `gave-up`: the agent stopped on the same failure three times (D55). **Not clean**: a fix round with `toolchain-digest.txt`.
   - `audit.json` with outcome `warning` (or a new line in `artifacts/audit-warnings.jsonl`): the audit could not run. Run it yourself: `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir specs/NNN-slug --task-id T3 --cwd <worktree>`. Exit 0 is clean; exit 1 is a fix round with its digest; exit 2 is a header or profile problem the agent cannot fix: relaunch with a corrected header, or treat a profile problem as `profile-wrong`.
   - On Codex the stop audit works the same way, finding the task from the spawn `task_name` (D66). A malformed `task_name` makes it warn, so handle it as the `warning` case above.

   No agent looks at the diff until this is clean.
4. **3.7 Mini-review.** Launch `profile-mini-review` (header `spec_dir`, `task_id`, `work_type`). Hand over the diff as the task worktree path and the base commit from `implementation.yaml` (`git -C <worktree> diff <base_commit>...HEAD`), plus `specs/NNN-slug/artifacts/<task-id>/toolchain.json`; no diff file is written. Save its return as `mini-review.yaml`; `tool-covered` items and `tool_rule_candidate` findings feed the 5.2 proposals. A non-empty `out_of_scope_noticed` never changes the verdict: hand each entry to [Discovered work](#discovered-work-0021) with origin node `3.7`, as for `discovered_work[]`.
5. **3.8 Mini-review passes?** `verdict: fail` is a fix round with the failed items (location, finding, fix). `pass`: the task is ready to merge at 3.16.

**Fix rounds.** A fix round is one resume of the implementer with the failing gate's output, followed by the gates again from 3.5 (the stop audit fires on its next stop). 3.6, 3.8, 3.9 and 3.11 failures all count. Five rounds per task at most; at the cap, go to [Stops](#stops).

### 3.16 Merge the wave

When every task of the wave has passed 3.8 (or is blocked), merge each passing task's branch into the feature branch in the main checkout, then mark it `done` (D18; tasks become `done` only here):

```bash
git merge --no-ff -m "Merge T3: <task title>" <branch>   # the message names the task id; 4.7 finds task owners by it
.agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T3 --status done --step 3.16
```

On a merge conflict, run `git merge --abort` and resume that implementer: "merge the feature branch into your branch, resolve the conflict, re-run your tests, commit". Its diff changed, so it passes 3.5-3.8 again before you merge it.

If the spec went `blocked` during the wave (00.21), hold the merge: tasks that pass 3.8 wait, and 3.16 and 3.15 run once `modules/discovered-work.md` unblocks the spec at 00.28. A `set-task --step` write while blocked would move `.step` off the protocol's node.

### 3.15 Within the size budget?

Once per wave, after its merges (D58):

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 3.15
.agents/skills/feature-workflow/scripts/budget-check.sh --spec-dir specs/NNN-slug
```

It prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source}` and counts changed files from `baseline_revision` to `HEAD`, outside the spec folder.

- **Exit 0, within budget:** go to 3.13 (the suites known from 3.1), then 3.9.
- **Exit 2, over budget:** load `modules/discovered-work.md` with origin node `3.15`, found by `budget-check.sh`, the condition `size budget: <count> changed files, max_changed_files <max>` (name each entry of `over`), and the JSON as evidence. It runs 00.21, 00.22 and the 00.29 split, re-scope or approve choice. When it returns at 00.28 (split or approve), continue at 3.13; on re-scope the spec is `draft` and this module ends. A split has already set the tasks whose work became backlog items to `split-out` (`set-task --status split-out --step 00.29`, D68); skip them from here on.
- **Exit 1:** a usage or environment error (reason on stderr: a missing tool or file, a malformed `budget`, an unknown baseline commit). Fix the cause and run it again; never treat it as within budget. A JSON `note` with `changed_files: null` means the files were not counted (no `baseline_revision`): fix the baseline (D53) before going on.

### 3.9 Tests pass and CI green?

After each wave's 3.15, if the harness exists, run the harness command from `## Suites` in `verification-plan.md` (the profile Toolchain `test` key; D61) on the merged feature branch, and the CI check when it has a local entry point. Save the output under `artifacts/suites/` (one file per run). Report CI green only from a run you saw.

- **Yes:** next frontier.
- **No:** find the task whose module and seam the failing tests cover and reopen it (D59):

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T3 --status in-progress --step 3.9
  ```

  Give it a fix round (resume its agent, or a fresh launch when the worktree is gone), then 3.5-3.8, 3.16, 3.15 and 3.9 again. If the task cannot continue (a stop, or the fifth round fails), record it with `set-task specs/NNN-slug T3 --status blocked --step 3.9` and go to [Stops](#stops).

## 3.10-3.11 Browser suite against the running feature

After the last wave passes 3.9 (or straight after its 3.15 when only the browser suite exists, D60), run the browser suite yourself with Bash on the merged feature branch: the browser-suite command from `## Suites` (the `e2e` key of `profiles/e2e-browser.md`), or `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir specs/NNN-slug --task-id e2e-<run> --work-type e2e-browser --cwd "$PWD" --e2e`, which runs the profile's other command keys (`lint`, `typecheck`, `format`, `boundary`, `test`) and then `e2e` last. The 3.5 stop audit never runs `e2e`, and the evidence-capture hook does not run the suite either: it only files the run's screenshots, traces, console and network logs under `artifacts/` by run and journey id (3.12). Where that hook is not wired (Codex, or before it is installed), copy the runner's output into `artifacts/<run>/<JRN-id>/` yourself.

- **3.11 Yes, every journey passes:** `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug in-review --step 3.11`, then [hand off](#hand-off).
- **No:** for each failing journey, take the capability it proves (`## Journeys`, Proves column) and reopen the task serving it: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T3 --status in-progress --step 3.11` (D59). Give it a fix round, then 3.5-3.8, 3.16, 3.15, 3.9 and 3.10 again. A task that cannot continue: `set-task specs/NNN-slug T3 --status blocked --step 3.11`, then [Stops](#stops).

## 3.13-3.14 Light path without suites

When 3.1 found a suite missing (light path only), run the suite that exists and skip only the missing suite's gate (D60): 3.9 for the harness, 3.10-3.11 for the browser suite. Record each gap; it is never reported as a pass (D29):

1. Load `modules/deferred-handoff.md` with each missing suite as a `3.14 suite gap` item. It writes `deferred/<slug>.md`, sets step 3.14 and adds the path to `deferred` in `spec.md`; in that same `spec.md` write, add one line per skipped gate under `## Known gaps` with the handoff link.
2. **Only the harness exists:** once every task is `done` or `split-out` and 3.9 passes, `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug in-review --step 3.14`. **Only the browser suite exists:** 3.11 sets `in-review` as above. **Neither exists:** set `in-review` at 3.14 once every task is `done` or `split-out`, and go straight to Phase 4. Sign-off flags the gap in the 5.4 report.

## Discovered work (00.21)

Discovered work is report-only: an agent found work outside the agreed scope (a new requirement, a bug along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer) and did not fix it (D56). It reaches you as any of:

- an implementation or integration result with `status: discovered-work`;
- a non-empty `discovered_work[]` on an implementation or integration result of **any** status, `done` and `partial` included;
- a non-empty `out_of_scope_noticed` in a `profile-mini-review` return (3.7).

Never fold it into a task or brief. Load `modules/discovered-work.md` once with every entry that has arrived, each with what its "What the caller hands you" table asks: origin node `3.4` for an implementation return, `3.2` for integration, `3.7` for a mini-review; found by (the agent, task id and its return); the problem (the entry's `summary`); the evidence (its `evidence`: `path:line` or a failing test); the kind (its `kind`); and its `blocker_assessment` and `reason` as your starting assessment. It blocks the spec (`blocked_condition: "discovered work: <slug>"`), presents it to the user and records the answer.

While it waits: tasks already running finish and pass through their gates (3.4-3.8), but you merge nothing and start no new launch (3.2 or 3.3) until the user answers. When it returns at 00.28, the spec is back at `blocked_from` and you continue the wave loop unchanged: resume the reporting task on its own scope only. If it ends at 00.24 (the spec is `draft`, back to 0.3.8) or leaves the spec `blocked` for a human, this module ends; leave the worktrees in place so a later resume finds them.

## Stops

A stop halts the task. Let the rest of the wave finish its gates and merge what passed (3.16), then block the spec with a condition a human can act on: `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug blocked --step <node> --blocked "<what a human must decide or do>"`. A task record that is not `done` goes `blocked` too: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T3 --status blocked`.

| Event | Handling | Spec block step |
| --- | --- | --- |
| `profile-wrong` | Stop; never work around the profile. Quote the profile line in the condition. An existing profile changes only at 5.3 (D50). | 3.3 (3.2 for an integration batch) |
| `scope-expansion` into shared core | Not a stop: the request joins the next integration batch (3.2); resume the task once it is merged. | none |
| `scope-expansion` into another module | Work outside the task's agreed scope: handle it as [discovered work](#discovered-work-0021), kind `scope-expansion`, with the paths and the reason as evidence. `tasks.md` is rewritten only at 2.5, so the task is never widened. | 00.21 (via the module) |
| `discovered-work` | [Discovered work](#discovered-work-0021). | 00.21 (via the module) |
| Budget over at 3.15 | [3.15](#315-within-the-size-budget). | 00.21 (via the module) |
| `blocked` on a fact | Not a stop: look it up in the code, answer, resume the agent. | none |
| `blocked` on a decision | Ask the stakeholder; with no answer available, block with the decision as the condition. | 3.3 |
| Fifth fix round fails | Block with the open findings and the gate that keeps failing. | the failing gate (3.6, 3.8, 3.9, 3.11) |
| Integration `conflict` with no decision | Block with both consumers' needs. | 3.2 |

## Hand off

Remove the worktrees you created: `git worktree remove <path>` for each implementation and integration worktree, and `git branch -d <branch>` for its merged branch. Then load `modules/review-triage.md`.
