# T04: Asset record matches the agent worktree build

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `assetlist.md` and `PROVENANCE.md` describe what the scaffold does now. In `assetlist.md`: the `post-implementation-audit` inventory row (around line 40) gives the matcher `implementation|integration`; the `worktree-write-guard` row (around line 47) says it keeps an implementation or integration sub-agent inside its agent worktree; D85 item 6 says Phase 1 builds and integration batches run in agent worktrees the orchestrator creates, like tasks, and drops the isolation-relaunch fallback. Rewrite these in place, with no "Amended by" note and no spec reference. In `PROVENANCE.md:21`, the worktree-write-guard note says "agent worktree" instead of "task worktree".

**Seam:** the record text, checked by `tests/lint/agent-worktree-docs.sh` (grep lint on the three `assetlist.md` places).

**Acceptance criteria:**

- [ ] The inventory row's stop-audit matcher is `implementation|integration` (escaped as the table needs).
- [ ] The guard row says "agent worktree", not "task worktree".
- [ ] One sentence of D85 item 6 names Phase 1, integration, agent worktree and orchestrator; item 6 has no fallback or isolation-relaunch text.
- [ ] None of the three carries an "Amended by spec" note.
- [ ] `PROVENANCE.md:21` says "agent worktree" for the guard.
- [ ] `tests/lint/agent-worktree-docs.sh` passes in full.

**Predicted files:** `assetlist.md`, `PROVENANCE.md`

**Phase 1 tests:** `tests/lint/agent-worktree-docs.sh`

**Size:** S (2 files, about 15 changed lines).

**Mode:** afk.

**Notes:** `assetlist.md` and `PROVENANCE.md` have no Ownership glob; root-docs is the closest module. The second stop-audit row in the hooks table (`assetlist.md:593`) is out of scope (backlog item 00010-worktree-guard-followups-disc-001).
