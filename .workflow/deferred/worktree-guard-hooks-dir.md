---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
created: 2026-10-30
---

# Worktree guard hooks folder

**Summary:** The worktree guard resolves its own hooks folder one way, so the feature-workflow scripts and the shared library come from the same place.
**Mode:** AFK
**Origin:** [00010-worktree-guard-followups](../specs/done/00010-worktree-guard-followups/spec.md), 5.9 work-backlog item `00010-worktree-guard-followups-disc-004.md` (found at 3.7), design-log entry 2026-10-30 Sign-off: stakeholder approval (5.5)

## Goal

The worktree guard resolves its own hooks folder one way, so the feature-workflow scripts and the shared library come from the same place.

## Background

The guard finds its folder with a plain `cd` on one line and with `cd -P` a few lines later. No failure was found; a symlinked install could resolve the two differently. Out of spec 00010's scope, which did not touch those lines.

Problem, from the work item: The worktree guard finds its hooks folder with a plain `cd` on one line and with `cd -P` a few lines later, so a symlinked install could resolve the feature-workflow scripts and the shared library from different places. The shell-scripts profile asks sibling paths to be resolved one way.

**Current behaviour:** two lines resolve the hooks folder, one following symlinks and one not.

**Desired behaviour:** one resolution with `cd -P`, both paths derived from it.

## Constraints

- The shell-scripts profile's sibling-path rule.

## Decisions already made

- Moved to the shelf at sign-off (design-log 2026-10-30 Sign-off entry in [.workflow/specs/done/00010-worktree-guard-followups/design-log.md](../specs/done/00010-worktree-guard-followups/design-log.md)).

## Evidence

- `.agents/hooks/worktree-write-guard.sh:63-64` (plain `cd`) and `:72` (`cd -P`), at T2 head `bb1b749`.
- T2 mini-review, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed[3]`.
- Commit at shelving: `f276ea1`.

## Acceptance criteria

- [ ] The hooks folder is resolved once with `cd -P` and both paths derive from it.
- [ ] `tests/hooks/worktree-guard.sh` still passes.

## Out of scope

- Other hooks' path resolution (see `main-checkout-resolver.md`).
