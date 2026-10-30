# T03: project-setup asks `pr_template`

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** When project-setup writes `.workflow/rules.md` and the project has a host PR/MR template at `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md` or `.gitlab/merge_request_templates/*.md` (D15), it asks once which template Sign-off PRs follow, offering each found path plus `workflow` (D14), and records the answer as `pr_template`. With no host template it asks nothing. The rules.md template documents the key in its Workflow settings block.

**Seam:** Text checks of project-setup (`SKILL.md` or `modules/*.md` name `pr_template` and `pull_request_template`) and of `assets/docs/rules.md` (the `## Workflow settings` section names `pr_template`), in `tests/scripts/sign-off-pr.sh` (owned by T4), plus the JRN-004 case that the template still reads `workflow`.

**Acceptance criteria:**

- [ ] project-setup states the search locations, the one question with each found path plus `workflow`, where the answer is written, and that nothing is asked without a host template.
- [ ] The rules.md template's Workflow settings block documents `pr_template` (`workflow` default, or a repo-relative template path) without setting a value that changes the default read; `rules-setting.sh pr_template --rules <template>` still prints `workflow`.
- [ ] The question respects project-setup's rule that content changes to rules.md go through `project-standards` and its approval ledger, or states why this one write is an exception.
- [ ] Agent-docs lint suites pass.

**Predicted files:** `.agents/skills/project-setup/SKILL.md`, `.agents/skills/project-setup/modules/files.md`, `.agents/skills/project-setup/assets/docs/rules.md`

**Phase 1 tests:** None. Its three JRN-006 cases sit in `tests/scripts/sign-off-pr.sh`, which T4 owns (test selectors are per suite); T4 depends on T3 so they run green there.

**Size:** S (3 files, about 30 changed lines).

**Mode:** afk.

**Notes:** project-setup may depend on feature-workflow (`.workflow/rules.md` Ownership). Keep the default read by leaving the key commented or documenting it in prose.
