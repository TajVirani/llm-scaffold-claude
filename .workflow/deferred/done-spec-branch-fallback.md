---
origin_spec: .workflow/specs/done/00014-tracker-issue-spec-ids
created: 2026-11-02
---

# Done spec branch fallback

**Summary:** The fallback spec-branch name built from a spec folder includes `done/` when the folder is in the Done folder.
**Mode:** AFK
**Origin:** [00014-tracker-issue-spec-ids](../specs/done/00014-tracker-issue-spec-ids/spec.md), 0.3.17 scope decision, design-log entry 2026-11-02 Scope decision: done-spec-branch-fallback

## Goal

The fallback spec-branch name for any spec folder, in the Done folder or not, is `spec/<folder name>`.

## Background

Found by the module audit for spec 00014. No step runs these scripts on a Done spec today, so it is not a live failure and was kept out of 00014's scope.

**Current behaviour:** The fallback is built by stripping `specs/` from the folder path, so a Done spec gives `spec/done/NNN-slug`.

**Desired behaviour:** The fallback uses the folder's base name, giving `spec/NNN-slug`.

## Evidence

- `.agents/skills/feature-workflow/scripts/open-task-pr.sh:129,139` and `.agents/skills/feature-workflow/scripts/status-transition.sh:355`, as of commit `7b50de2`.

## Acceptance criteria

- [ ] With `spec_branch` empty, a Done-folder spec resolves its branch as `spec/<folder name>`.
- [ ] A test covers both a top-level and a Done-folder spec.

## Out of scope

- Allowing launches or task PRs against Done specs (see `launch-against-done-spec.md`).
