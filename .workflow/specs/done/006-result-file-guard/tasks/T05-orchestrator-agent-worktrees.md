# T05: Orchestrator steps launch Phase 1 and integration in agent worktrees

Index: [../tasks.md](../tasks.md) · Blocked by: T3 (Agent briefs write the result file to the main checkout; T05 owns `tests/lint/agent-worktree-docs.sh`, which also holds T3's cases) · Parallel with: None

**What to build:** On both hosts, the orchestrator creates the **Agent worktree** for each Phase 1 build and integration batch itself, and checks every merge with the artifacts gate. Changes to `modules/verification-setup.md` (1.2-1.4 and "Launching a Phase 1 build") and `modules/implementation-orchestrator.md`:
- **Launch.** The launch table, the 3.2 integration launch and the Claude launch notes launch without `isolation`. Before the launch, create the worktree with `git worktree add .workflow/.worktrees/<name> -b wf/NNN-slug/<name> spec/NNN-slug`, where `<name>` is `s<NNN>_phase_1_<enc(work_type)>` or `s<NNN>_integration_<enc(work_type)>`. Name it in the brief as the directory the agent works in.
- **Reuse.** A relaunch or fix round reuses the existing worktree. 1.3 forks only after the 1.2 merge.
- **Merge.** Merge `wf/NNN-slug/<name>`, the branch read from the result file. Never read `worktreeBranch`.
- **Cleanup.** After the merge, remove the worktree and delete the branch.
- **Fallback removed.** The isolation fallback paragraph and the `"worktree": {"baseRef": "head"}` instruction go. An agent that keeps getting denied becomes a blocked task.
- **Gate.** `.agents/skills/feature-workflow/scripts/check-merge-artifacts.sh --spec-dir .workflow/specs/NNN-slug --rev <branch or commit>` runs before each of the five merge sites: 1.2, 1.3, the 3.2 integration merge, the 3.16 task merge and the light-path `--ff-only`. Each call is its own command, never piped. A refusal goes back to the agent to drop the `artifacts/` change.

**Seam:** The doc text, checked clause by clause by `tests/lint/agent-worktree-docs.sh` (JRN-008).

**Acceptance criteria:**

- [ ] No clause tells the orchestrator to launch with `isolation: "worktree"`, to set a worktree `baseRef`, to keep an isolation fallback, or to read `worktreeBranch`. Sentences saying never to do so are fine.
- [ ] Both files create the Phase 1 or integration worktree on a `wf/` branch off the spec branch. Both merge that branch, remove the worktree and delete the branch after the merge.
- [ ] The gate runs, with `--rev` and unpiped, before the 1.2/1.3, 3.2, 3.16 and light-path merges.
- [ ] `tests/lint/agent-worktree-docs.sh` passes in full (with T3 merged). Agent-docs lint passes, including the step-list pin; no step id is added or renumbered.

**Predicted files:** `.agents/skills/feature-workflow/modules/verification-setup.md`, `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`

**Phase 1 tests:** `tests/lint/agent-worktree-docs.sh`

**Size:** S (2 files, about 120 changed lines).

**Mode:** afk.

**Notes:**
- Keep edits to these two modules and to what the spec scopes. Spec 009 later splits `implementation-orchestrator.md` and moves launch rules into `references/launching.md`.
- The gate is a step inside existing nodes (1.2, 1.3, 3.2, 3.16), so `references/steps.tsv` needs no new row.
- The T3 → T05 edge exists for test ownership.
