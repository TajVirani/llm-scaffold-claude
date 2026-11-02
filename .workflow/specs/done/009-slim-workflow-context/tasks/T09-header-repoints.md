# T09: Script and asset headers re-pointed

Index: [../tasks.md](../tasks.md) · Blocked by: T8 (Setup, waves and finish step files; orchestrator removed) · Parallel with: None

**What to build:** No script or template header names a step file that no longer exists. The header comments of the feature-workflow scripts that name `implementation-orchestrator.md` (`budget-check.sh`, `check-merge-artifacts.sh`, `check-task-result.sh`, `commit-workflow-data.sh`, `open-task-pr.sh`, `rules-setting.sh`, `status-transition.sh`, `task-waves.sh`, `spec-worktree.sh`) and of `assets/task.md` and `assets/tasks.md` name the step file that now holds the step they refer to (spec Assumptions). Comments only: no behaviour changes.

**Seam:** `grep -rn 'implementation-orchestrator' .agents` prints nothing; the shell-scripts lint and every existing suite still pass.

**Acceptance criteria:**

- [ ] `grep -rn 'implementation-orchestrator\|small-path\.md' .agents` prints nothing.
- [ ] Each re-pointed header names the step file that holds the step it mentions.
- [ ] The shell-scripts profile lint (shellcheck and the comment lint) passes, and `tests/run-all.sh` passes apart from `lint/workflow-load-size` (T10's).

**Predicted files:** `.agents/skills/feature-workflow/scripts/budget-check.sh`, `.agents/skills/feature-workflow/scripts/check-merge-artifacts.sh`, `.agents/skills/feature-workflow/scripts/check-task-result.sh`, `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh`, `.agents/skills/feature-workflow/scripts/open-task-pr.sh`, `.agents/skills/feature-workflow/scripts/rules-setting.sh`, `.agents/skills/feature-workflow/scripts/status-transition.sh`, `.agents/skills/feature-workflow/scripts/task-waves.sh`, `.agents/skills/feature-workflow/scripts/spec-worktree.sh`, `.agents/skills/feature-workflow/assets/task.md`, `.agents/skills/feature-workflow/assets/tasks.md`

**Phase 1 tests:** None.

**Size:** M (11 files, about 25 changed lines).

**Mode:** afk.

**Notes:** Classified as shell-scripts work at 3.1 (most files are scripts); the two asset headers are comment lines in the same change.
