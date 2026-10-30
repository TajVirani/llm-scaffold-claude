---
origin_spec: .workflow/specs/00010-worktree-guard-followups
origin_step: "3.7"
discovered_at: 2026-10-30
status: open
kind: refactor
---

# Worktree guard resolves its own folder two ways

## Problem

The worktree guard finds its hooks folder with a plain `cd` on one line and with `cd -P` a few lines later, so a symlinked install could resolve the feature-workflow scripts and the shared library from different places. The shell-scripts profile asks sibling paths to be resolved one way.

## Evidence

- `.agents/hooks/worktree-write-guard.sh:63-64` (plain `cd`) and `:72` (`cd -P`), at T2 head `bb1b749`.
- T2 mini-review, `.workflow/specs/00010-worktree-guard-followups/artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed[3]`.

## Why not a blocker

Pre-existing and untouched by spec 00010; no failure was found, and every installed layout the suites cover resolves both the same way.

## Suggested scope and size

- Scope: resolve the hooks folder once with `cd -P` and derive both paths from it.
- Size: 1 task in hooks, 1 file; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../00010-worktree-guard-followups/spec.md)
- Design log entry: [design-log.md](../00010-worktree-guard-followups/design-log.md) (section 2026-10-30 Discovered work: T2 mini-review notes)
