# T08: Tracker adoption

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Shared host choice and path rewrite), T2 (Tracker link keys), T4 (Done folder accepts old_ names), T5 (Tracker script), T6 (Tracker setup; both change `SKILL.md`) · Parallel with: None

**What to build:** `.agents/skills/issue-tracking/scripts/tracker-adoption.sh [--cwd DIR]` moves a project already under way onto the tracker in one run.

**Active specs:** for each one, the script files a **Tracker issue** (`issue-tracker.sh create-spec` and `fill`) and renames the spec to the issue number padded to five digits. The rename covers its folder, its backlog list, its spec branch, its spec worktree, `spec_branch`, the task records' `branch` fields and every `.workflow/` reference. It also writes `tracker_issue` and keeps the step marker.

**Remote and refusals:**

- A renamed branch whose old one was pushed is pushed under the new name. The old remote branch and its task PRs are reported, never deleted.
- A spec with a live task worktree is refused and left exactly as it was, while the others still run.

**Done specs:** renamed `done/old_NNN-slug`, their backlog lists `old_NNN-slug.md`, with references rewritten (retrospective and ADR file names stay). They get no issue.

Exits: 0 when every spec is adopted; 1 when any is refused; 2 for usage or environment. `SKILL.md` gets the adoption section.

**Seam:** the `tracker-adoption.sh` CLI on the adoption fixture project (working tree, branches, worktrees and a local bare `origin`), in `tests/scripts/tracker-adoption.sh`, plus the JRN-013 lint. Catches missed renames, broken links, remote deletions and a refused spec that changed. It misses a real remote host: D17 allows fakes and a local bare repo only.

**Acceptance criteria:**

- [ ] JRN-011: the draft and the past-1.1 spec are renamed to their issue numbers everywhere, and their `tracker_issue` holds the URL. The renamed branch is committed and pushed; the old remote branch is left and reported. The live-worktree spec is refused unchanged. The Done specs and their lists are prefixed `old_`. The review lessons still validate, and every relative `.workflow/` link resolves.
- [ ] JRN-012: `move-to-done.sh --check` accepts the renamed Done spec and reads its `old_` backlog list.
- [ ] JRN-013: the script uses the shared lib path rewrite (no rollback copy of its own) and the shared host choice. `tests/lint/shared-tracker-logic.sh` passes, together with T1's callers.
- [ ] The suite ends with `shellcheck_files` over the script.

**Predicted files:** `.agents/skills/issue-tracking/scripts/tracker-adoption.sh`, `.agents/skills/issue-tracking/SKILL.md`.

**Phase 1 tests:** `tests/scripts/tracker-adoption.sh`, `tests/lint/shared-tracker-logic.sh`.

**Size:** M (2 files, about 400 changed lines); kept as one task at 2.1 (D26).

**Mode:** afk.

**Notes:** Migrations M3 and M4 from data-model.md, in that order (Done specs first). D16: nothing on the remote is deleted. D20/D21: the renames go through the shared lib rewrite from T1, which already handles `NAME` to `NEW`, `done/NAME` to `done/old_NAME` and backlog list names. If it falls short, return `scope-expansion` naming the lib change; do not copy the logic.
