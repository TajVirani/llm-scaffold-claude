# Proposals: Tracker issues as spec IDs

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Rules

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/rules.md` § Ownership | Add module `issue-tracking: { owns: [".agents/skills/issue-tracking/**"], may_depend_on: [lib, feature-workflow] }`; add `issue-tracking` to `may_depend_on` of `feature-workflow` and `project-setup` | Without it the new skill's paths have no owner, so 0.3.3 cannot place later changes to it, and review 4.1 flags feature-workflow and project-setup calling its scripts as forbidden dependencies | design-log D2, 0.3.5 conflict check | proposed | |
