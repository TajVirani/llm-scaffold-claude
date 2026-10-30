# T03: Agent briefs write the result file to the main checkout

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The result-file step in `.agents/agents/implementation.md` (Phase 1 and Phase 3) and `.agents/agents/integration.md` names an absolute main-checkout path: `<main checkout>/<spec_dir>/artifacts/<id>/<file>.yaml`. An agent working in its **Agent worktree** therefore files its **Result file** in the main checkout, never in the worktree copy, and never adds it to its branch. The command stays one the worktree guard allows from a main-checkout cwd. The briefs also say the result file is the one write allowed outside the worktree, and that it is never committed.

**Seam:** The brief's result-file command, extracted from the doc at test time and run under the guard:
- `tests/hooks/worktree-guard.sh` JRN-002 to JRN-004, owned by T04;
- the brief-path cases in `tests/lint/agent-worktree-docs.sh` JRN-008, owned by T05.

**Acceptance criteria:**

- [ ] Both briefs give an absolute main-checkout target for the `cat >` (or equivalent) write, so the JRN-008 brief-path cases pass.
- [ ] The command each brief prescribes is allowed by the guard for a Phase 1, an integration and a Phase 3 payload with the cwd in the main checkout. The file lands in the main checkout's `artifacts/<id>/`, where `check-task-result.sh` accepts it (JRN-002 to JRN-004).
- [ ] Neither brief tells the agent to commit or stage anything under `artifacts/`.
- [ ] `profile-mini-review.md` is unchanged.
- [ ] Agent-docs lint passes.

**Predicted files:** `.agents/agents/implementation.md`, `.agents/agents/integration.md`

**Phase 1 tests:** None. Its cases sit in suites owned by T04 and T05.

**Size:** S (2 files, about 20 changed lines).

**Mode:** afk.

**Notes:** Codex tomls are generated from these files. Do not hand-edit them; regenerate only if the agent-docs toolchain asks for it.
