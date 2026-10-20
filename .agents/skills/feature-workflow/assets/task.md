<!--
File: Template for one task file, .workflow/specs/NNN-slug/tasks/Tnn-<slug>.md: the body of one task (D85). The record (status, edges, branch, size) lives in the tasks.md index frontmatter; this file holds what the implementer reads. One file per task, never one combined file.
Written by modules/task-breakdown.md at 2.5, or by modules/discovery.md at 0.3.20 on the light path (T01 only), together with the index. Read by the implementation agent from its task worktree (3.3) and by the orchestrator for briefs and 3.2 shared-core requests.
Name: `T<nn>-<slug>.md`, `<nn>` the task number zero-padded to two digits (T01, T02, ...), `<slug>` lowercase kebab-case from the title. The index record's `file` key names this path relative to the spec folder; its `branch` key is `task/NNN-slug/T<nn>-<slug>`.
Sources: per-ticket fields (what to build, blocked by, acceptance criteria) and "one file per ticket, numbered blockers-first, never a single combined file" adapted from mattpocock/skills/skills/engineering/to-tickets/SKILL.md@49dd158 (MIT, local-ticket-template). Predicted files, size points, mode and the "Notes" request are first-party (assetlist D85, D28).
Writing rules: no section left empty (write "None." instead); predicted files name paths or globs, never code; keep the frontmatter-free form (the index is the only machine-read file). Delete this comment in the finished file.
-->

# T<nn>: <title>

Index: [../tasks.md](../tasks.md) · Blocked by: <ids and titles from `depends_on`, or "None (can start immediately)"> · Parallel with: <ids from `parallel_with`, or "None">

**What to build:** <the end-to-end behaviour this task makes work, from the user's perspective, not a layer-by-layer list.>

**Seam:** <the interface under test and how the tests drive it (2.3).>

**Acceptance criteria:**

- [ ] <specific, independently verifiable criterion>

**Predicted files:** <the paths or globs this task will create or change, tests included; the same list as the record's `predicted_files`. Phase 1 harness and suite files that already exist are listed only when this task edits them.>

**Phase 1 tests:** <the Phase 1 tests this task turns green, the same selectors as the record's `tests` (2.5), or "None.". Every other task's Phase 1 tests are excluded from this task's `test` run.>

**Size:** <S | M | L> (<files> files, about <est_lines> changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** <afk | hitl>. <For hitl: the human decision, credential or manual step needed mid-task, and when.>

**Notes:** <shared-core change requested (touches_core: the change at the shared-core interface and the contract its consumer needs), the migration it carries from data-model.md, an approved parallel overlap and why it is safe, or "None.">
