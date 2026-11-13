# T01: Settings keys

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A project can declare three commands in the `## Workflow settings` block of its `.workflow/rules.md`: `worktree_setup`, `services_up` and `services_down`. `rules-setting.sh <key>` prints the declared command, or an empty line when the key is absent. Contract: [data-model.md](../data-model.md) § Workflow settings.

**Seam:** the `rules-setting.sh <key> [--cwd <dir>]` command line, driven by the settings cases at the top of `tests/scripts/worktree-setup.sh`.

**Acceptance criteria:**

- [ ] `rules-setting.sh worktree_setup`, `services_up` and `services_down` each print an empty value and exit 0 in a project whose rules file sets none of them.
- [ ] Each prints the command its rules file sets, whole, including spaces, quotes and `&&`.
- [ ] A sequence or map value for any of the three is rejected as it is for the existing keys.
- [ ] The usage text and the unknown-key message name the three new keys.
- [ ] `task_review`, `main_branch` and `pr_template` behave as before: `tests/run-all.sh --suite scripts/task-breakdown` passes unchanged.
- [ ] In `tests/run-all.sh --suite scripts/worktree-setup`, the four cases under "the three new settings read through rules-setting.sh" pass. The rest of that suite stays red until T3.

**Predicted files:** `.agents/skills/feature-workflow/scripts/rules-setting.sh`

**Phase 1 tests:** None. The four settings cases live in `tests/scripts/worktree-setup.sh`, which T3 owns; run that suite by name to see them pass.

**Size:** S (1 file, about 30 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** The settings reader exits 1 for a usage error; leave that as it is (shelved in `.workflow/deferred/rules-setting-usage-exit-code.md`). The one place to add a key is `setting_spec`, plus the two key lists in messages.
