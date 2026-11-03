# T10: Step-file tracker calls and Sign-off PR link

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Shared host choice and path rewrite; both change `sign-off.md`), T2 (Tracker link keys), T3 (next-spec-number.sh; frees start-load bytes), T7 (project-setup tracker step), T9 (Package the issue-tracking skill) · Parallel with: None

**What to build:** The workflow moves each **Tracker issue** through the **Issue flow** at the agreed steps (D5-D7, D15, D22). Every call runs unconditionally and prints `skipped: no tracker` on a project without one.

Calls added to the step files:

- **Spec issue body:** `issue-tracker.sh fill` at 0.3.19, at 0.6 (0.3.20 on the light path) and at sign-off.
- **Task issues:** at 2.5 and 0.3.20, `issue-tracker.sh create-task` for each task, followed by `status-transition.sh set-task ... --issue <url>`.
- **Moving forward:** `issue-tracker.sh move <url> in_progress` at 3.1 (the spec issue) and 3.3 (each task issue). `move <url> done` at 3.16 (each merged task) and at 5.8 (the spec issue, local merge).
- **Back on a reopen:** `move <url> in_progress` for a reopened task at 3.9, 3.11 and 4.7.

The Sign-off PR's "Link to issue" guidance in `assets/pr-template.md` gives the `tracker_issue` URL and `Closes #<n>`, and keeps today's stub with no tracker. Sign-off 5.4 appends the URL and `Closes #<n>` as the last lines of a project-template body; `check-pr-body.sh` is unchanged. `references/conventions.md` names Tracker adoption as the second path-only rewriter in the guarded-writes table.

Both loads stay within ADR-0004: the new-feature start at or under 45,000 bytes, the implementation resume at or under 55,000. The resume has little headroom, so keep each call to one line in `implementation-waves.md`.

**Seam:** the step-file docs lint (`tests/lint/issue-tracking-docs.sh`, which matches each call by script name and command under its step id) and the sign-off-pr suite with `check-pr-body.sh` (`tests/scripts/sign-off-pr.sh`). Catches a missing or misplaced call and a PR body the checker rejects. It misses whether an agent follows the steps at run time.

**Acceptance criteria:**

- [ ] JRN-005, JRN-006 and JRN-007: every call above is present under its step, with the command and stage the lint expects.
- [ ] JRN-001 docs check: 0.1.1 calls `next-spec-number.sh` (written by T03; the test is in this suite).
- [ ] JRN-014: the project-setup step (T07) and the manifest and PROVENANCE lines (T09) are present, so the whole `lint/issue-tracking-docs` suite passes.
- [ ] JRN-009: the template's tracker form and the 5.4 project-template ending pass `check-pr-body.sh`, and the no-tracker stub still passes.
- [ ] JRN-015: `tests/run-all.sh --suite lint/workflow-load-size` passes.
- [ ] JRN-016: `tests/run-all.sh` passes every suite once this, the last task, is merged.

**Predicted files:** `.agents/skills/feature-workflow/modules/questioning-loop.md`, `.agents/skills/feature-workflow/modules/discovery-impact.md`, `.agents/skills/feature-workflow/modules/task-breakdown.md`, `.agents/skills/feature-workflow/modules/implementation-setup.md`, `.agents/skills/feature-workflow/modules/implementation-waves.md`, `.agents/skills/feature-workflow/modules/implementation-finish.md`, `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/references/conventions.md`, `.agents/skills/feature-workflow/assets/pr-template.md`.

**Phase 1 tests:** `tests/lint/issue-tracking-docs.sh`, `tests/scripts/sign-off-pr.sh`.

**Size:** M (9 files, about 180 changed lines).

**Mode:** afk.

**Notes:** `references/conventions.md` is in both load points, and the start load had about 34 bytes spare before T03. Measure both loads after each edit. The 4.7 rework entry is in `implementation-waves.md`; 3.11 is in `implementation-finish.md`.
