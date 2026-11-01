# 3.2 Integration batches, one work type each

The [implementation orchestrator](implementation-orchestrator.md) loads this step file before a wave's launches when the wave has shared-core change requests. Every command runs in the spec checkout, as the orchestrator says. Once every batch is merged or handled, go back to the orchestrator's [wave start](implementation-orchestrator.md#wave-start-task-branches-and-worktrees).

Before launching the wave, collect its shared-core change requests: the **Notes** request of every frontier task with `touches_core: true`, plus shared-core requests from `scope-expansion` results. Group them by the requesting task's `work_type`, one batch per work type, so each launch carries exactly one profile. Launch the batches one at a time (header `task_type: integration`, `spec_dir`, `work_type`); each brief is a numbered list of requests, each stating the change and the contract its consumer needs, without task context.

**The integration worktree.** Before launching a batch, from the spec checkout, create its worktree on a `wf/` branch off the spec-branch tip. `<name>` is `s<NNN>_integration_<enc(work_type)>`, for example `s007_integration_web` (`enc` lowercases and turns every character outside `[a-z0-9]` into `_`), the name the worktree guard finds it by:

```bash
git worktree add .workflow/.worktrees/<name> -b wf/NNN-slug/<name> spec/NNN-slug
```

`.workflow/.worktrees/` is gitignored. Name the worktree's absolute path in the brief as the directory the agent works in. A resumed batch or a fix round reuses the worktree. The merge removes it, so a later batch of the same work type creates it again off the new spec-branch tip.

When a batch returns, check its result file ([Reading a result file](implementation-orchestrator.md#evidence-and-the-ledger)) and route on the printed table:

```bash
.agents/skills/feature-workflow/scripts/check-task-result.sh .workflow/specs/NNN-slug/artifacts/integration-<work_type>/integration.yaml
```

- **Batch `status`** (top level; `.agents/agents/integration.md` "Return"). `done` or `partial`: handle each request by its verdict below (`partial` means some requests were rejected or conflict). `discovered-work`: out-of-scope work stopped the batch and nothing was applied; go to [Discovered work](implementation-orchestrator.md#discovered-work-0021) at step 3.2 with its `discovered_work[]` entries. `profile-wrong`: a [stop](implementation-orchestrator.md#stops) at step 3.2, quoting `profile_wrong.line`. `blocked`: read `blocked.reason`; a fact you look up and resume the agent, a decision you put to the stakeholder, or block the spec at step 3.2 when no answer is available.
- **`discovered_work[]`.** A non-empty list goes to [Discovered work](implementation-orchestrator.md#discovered-work-0021) at step 3.2 whatever the status, `done` and `partial` included. While that module has the spec `blocked`, hold this batch's merge as 3.16 does; merge the `applied` work once it returns at 00.28.
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
