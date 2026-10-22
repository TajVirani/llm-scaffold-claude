---
origin_spec: .workflow/specs/001-large-path
created: 2026-10-21
---

# Scoped final commit at sign-off

**Summary:** The sign-off step that commits what is left on the spec branch scopes what it stages, so an untracked draft spec or initiative folder in the working tree is not swept into the finished spec's last commit.
**Mode:** AFK
**Origin:** [001-large-path](../specs/001-large-path/spec.md), 0.3.17 scope decision, design-log entry 2026-10-21 Scope decision: scoped final commit at sign-off

## Goal

A spec's last commit before its PR contains only that spec's files and the files its tasks changed, whatever else sits untracked in the working tree.

## Background

Untracked spec folders travel across every branch switch, and the earlier commits of a spec (verification setup, task breakdown) stage only the spec's own folder for that reason. The sign-off step that commits "what is left" names no scope, so a draft spec started in the same checkout is staged with it. The behaviour predates the large path, which only raises the odds by adding emitted spec folders that stay untracked until their own branch exists. Shelved because sign-off is outside the large path's changes and the fix is independent of it.

**Current behaviour:** the final sign-off commit stages everything untracked in the working tree, including other specs' draft folders.

**Desired behaviour:** the final sign-off commit stages the spec's own folder and the paths the feature changed, and reports any untracked workflow folder it left alone.

## Constraints

- The spec branch's commits stay folder-scoped, as verification setup and task breakdown already are.
- Sign-off wording changes go through the feature workflow like any other module edit.

## Decisions already made

- D22 in [.workflow/specs/001-large-path/design-log.md](../specs/001-large-path/design-log.md): initiative commits are limited to the initiative folder, so the large path never relies on an unscoped commit.

## Evidence

- Unscoped final commit at `.agents/skills/feature-workflow/modules/sign-off.md:129`, against the folder-scoped adds at `.agents/skills/feature-workflow/modules/verification-setup.md:123-124` and `.agents/skills/feature-workflow/modules/task-breakdown.md:119`, as of commit `0a662df5d1046bd2984be858e813992a7fb36eb7`. Reported by module-audit; can wait.

## Acceptance criteria

- [ ] The sign-off module names the paths its final commit stages.
- [ ] With an untracked draft spec folder present, a sign-off dry run leaves it unstaged and says so.
- [ ] `tests/run-all.sh` passes.

## Out of scope

- Any change to how draft specs are stored before their branch exists.
