# T06: Shared-core and per-task gates step files

Index: [../tasks.md](../tasks.md) · Blocked by: T4 (Launching reference) · Parallel with: T5

**What to build:** The two parts of the implementation orchestrator that run only at specific moments get their own step files. 3.2 (shared-core integration batches) moves to `modules/implementation-shared-core.md` (D16); 3.4–3.8 with result routing move to `modules/implementation-gates.md` (D25). The rest stays in `implementation-orchestrator.md` for now (T8 splits it), which loads each new file at the step that needs it. Every link they carry into Evidence and the ledger, Stops and Discovered work keeps resolving (`implementation-orchestrator.md#…` until T8), plain-text "as 3.16 does" and "as at 3.5-3.6" references stay true, and the launching section's links into 3.2 and `#per-task-gates-34-38` are re-pointed.

**Seam:** the step files as loaded text: `lint/md-links`, and the existing pins that name the moved text (`tests/lint/agent-worktree-docs.sh` check-merge-artifacts before the 3.2 merge, `tests/lint/review-escalation-docs.sh` "**Current work.**", `tests/scripts/run-toolchain.sh` the toolchain tree sentence), re-pointed to the new files.

**Acceptance criteria:**

- [ ] 3.2 is held only by `implementation-shared-core.md`, and 3.4–3.8 only by `implementation-gates.md`, under the "holds" definition at the top of `tests/lint/step-routing.sh`.
- [ ] The orchestrator says where each is loaded (3.2 between waves; the gates after each task returns).
- [ ] `lint/md-links`, `lint/step-list`, `lint/upstream-lineage` and every other existing suite pass, re-pointed only where they name the moved text.
- [ ] `PROVENANCE.md` names both new files; `upstream-lineage.json` entries for moved orchestrator text name the file the text now lives in.

**Predicted files:** `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`, `.agents/skills/feature-workflow/modules/implementation-shared-core.md`, `.agents/skills/feature-workflow/modules/implementation-gates.md`, `PROVENANCE.md`, `upstream-lineage.json`, `tests/lint/agent-worktree-docs.sh`, `tests/lint/review-escalation-docs.sh`, `tests/scripts/run-toolchain.sh`

**Phase 1 tests:** None.

**Size:** M (8 files, about 250 changed lines).

**Mode:** afk.

**Notes:** Shares `PROVENANCE.md` and `upstream-lineage.json` with T5 under an approved `parallel_with` (different entries; merged in id order).
