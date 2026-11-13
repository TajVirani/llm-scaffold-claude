---
origin_spec: .workflow/specs/done/00015-worktree-provisioning
created: 2026-11-12
---

# Usage exit code of the workflow settings reader

**Summary:** The script that reads a project's workflow settings exits 1 on a usage error, where its sibling scripts exit 2.
**Mode:** HITL
**Origin:** [00015-worktree-provisioning](../specs/done/00015-worktree-provisioning/spec.md), 0.3.17 scope decision, design-log entry 2026-11-12 Scope decision: usage exit code of the settings reader

## Goal

Every workflow script reports a usage or environment error with the same exit code, so a caller can tell "you called me wrong" from "the answer is no" the same way everywhere.

## Background

The module audit for worktree setup noticed the difference while listing the exit-code conventions a new script must follow. It was shelved because changing an exit code is a contract change for every caller of the settings reader, which is outside a spec about setting up worktrees.

**Current behaviour:** the settings reader exits 1 for a usage error, an unknown setting and an invalid value; it has no exit 2. Scripts beside it exit 2 for usage and environment errors and keep 1 for a refusal or a failed check.

**Desired behaviour:** the settings reader exits 2 for a usage error and an unknown setting, and keeps a distinct code for an invalid value in the project's rules file. Each caller handles the new code.

## Constraints

- Existing callers depend on exit 1 today; each must be checked and changed in the same change.

## Decisions already made

- Shelved, not folded into worktree setup (design-log Scope decision in [.workflow/specs/done/00015-worktree-provisioning/design-log.md](../specs/done/00015-worktree-provisioning/design-log.md)).

## Evidence

- Usage and invalid values exit 1, with no exit 2, at `.agents/skills/feature-workflow/scripts/rules-setting.sh:33-34,49` as of commit `7bf841f`.
- Sibling conventions: `.agents/skills/feature-workflow/scripts/spec-worktree.sh:23-28` and `.agents/skills/feature-workflow/scripts/run-toolchain.sh:84-86` as of commit `7bf841f`.

## Acceptance criteria

- [ ] A call with a bad argument or an unknown setting exits 2.
- [ ] Every caller of the settings reader still stops with the reader's message on that error.
- [ ] The harness has a case for each exit code.

## Out of scope

- Making exit codes uniform across every other workflow script.
