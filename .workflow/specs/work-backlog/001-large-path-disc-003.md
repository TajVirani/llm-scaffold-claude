---
origin_spec: .workflow/specs/001-large-path
origin_step: "3.7"
discovered_at: 2026-10-22
status: open
kind: refactor
---

# One place to find an initiative by its branch

## Problem

Two hooks each carry their own copy of the rules for finding an initiative that is not on disk: list the `initiative/NNN-*` branches locally and on origin, pick the one that matches, and read its `initiative.md` from the branch tip with `git show`. The copies agree today, and a later change to one of them can drift from the other without any test noticing, because each hook's suite pins only its own copy.

## Evidence

- `.agents/hooks/codex-pre-spawn.sh:100-110` (`initiative_folder`), on the T6 task branch merged into `spec/001-large-path` at wave 2.
- `.agents/hooks/session-start-resume.sh:64-72` (`initiative_names`) and `:126-135` (`initiative_ref`), same branch.
- Reported by the T6 profile-mini-review return, round 2 (`out_of_scope_noticed`, kind refactor, can-wait).

## Why not a blocker

Behaviour is unchanged and both hook suites pin it (`tests/hooks/session-start-initiatives.sh`, `tests/hooks/codex-pre-spawn-initiative.sh`). No capability or journey of 001-large-path depends on where the rule lives.

## Suggested scope and size

- Scope: one sourced helper in `.agents/lib/` (shared core, so an integration batch) that resolves an initiative name or number to its folder, local branch or origin branch, with its own suite; both hooks call it. Same theme as the shelved [shared-path-normaliser](../../deferred/shared-path-normaliser.md) item, which could be picked up in the same spec.
- Size: one integration batch plus one task in the hooks module touching two hooks and three suites, inside the 10-task and 30-file defaults.

## Links

- Origin spec: [spec.md](../001-large-path/spec.md)
- Design log entry: [design-log.md](../001-large-path/design-log.md) (section 2026-10-22 Discovered work: initiative-branch-lookup-duplicated)
