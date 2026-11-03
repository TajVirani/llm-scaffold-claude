# T07: project-setup tracker step

Index: [../tasks.md](../tasks.md) · Blocked by: T6 (Tracker setup) · Parallel with: None

**What to build:** project-setup gains a tracker step: it runs `.agents/skills/issue-tracking/scripts/tracker-setup.sh check`, asks the stakeholder in one question whether to use the tracker and which three labels make the issue flow (recommending the defaults), and then runs `save` (with `--create-labels` only after they confirm) or `save --none`. It follows the existing "create only when absent, report as kept" pattern, so a project that already has `.workflow/issue-tracking.yaml` keeps it. On a project already under way, the step points to the `issue-tracking` skill's Tracker adoption instead.

**Seam:** the project-setup step text, checked by the JRN-014 docs lint in `tests/lint/issue-tracking-docs.sh` (T10 owns the suite).

**Acceptance criteria:**

- [ ] A project-setup step calls `tracker-setup.sh check` and then `tracker-setup.sh save`, matching the lint's `tracker-setup.sh <check|save>` pattern.
- [ ] The step creates the settings file only when absent and reports an existing one as kept.
- [ ] `tests/run-all.sh --suite lint/frontmatter --suite lint/md-links` pass.

**Predicted files:** `.agents/skills/project-setup/SKILL.md`, `.agents/skills/project-setup/modules/files.md`.

**Phase 1 tests:** None. The JRN-014 test turns green in `tests/lint/issue-tracking-docs.sh`, owned by T10.

**Size:** S (2 files, about 40 changed lines).

**Mode:** afk.

**Notes:** None.
