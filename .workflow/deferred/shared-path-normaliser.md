---
origin_spec: .workflow/specs/001-large-path
created: 2026-10-21
---

# Shared path normaliser

**Summary:** One helper that resolves and validates a workflow folder path (`.workflow/specs/NNN-slug`, `.workflow/initiatives/NNN-slug`) for every workflow script, replacing the per-script copies.
**Mode:** AFK
**Origin:** [001-large-path](../specs/001-large-path/spec.md), 0.3.17 scope decision, design-log entry 2026-10-21 Scope decision: shared path normaliser

## Goal

Every script that takes a workflow folder path validates it the same way, from one place, so adding a new folder kind (an initiative) is one change rather than one per script.

## Background

The feature-workflow scripts follow the convention that each script is self-contained and sources only the path constants from the shared library, so the path normaliser and main-checkout resolver are copied into each script that needs them. The large path adds a fifth copy for initiative folders. Replacing the copies with a shared helper changes that convention and touches the shared core, which only the integration agent changes and which deserves its own decision; it is not needed for the large path to work.

**Current behaviour:** four scripts carry their own copy of the spec-folder normaliser and main-checkout resolver; the large path adds a fifth for initiatives.

**Desired behaviour:** one helper in the shared library resolves a workflow folder path, accepts the spec and initiative folder shapes, rejects anything else with the same message, and every script sources it.

## Constraints

- The shared library is shared core: it changes only through the integration agent, between batches.
- bash 3.2, no bash 4 constructs; shellcheck clean.
- The self-contained-scripts convention is a recorded constraint of the module; revising it needs a design-log or ADR entry, not a silent change.

## Decisions already made

- D1 placement: the large path is owned by feature-workflow (design-log in [.workflow/specs/001-large-path/design-log.md](../specs/001-large-path/design-log.md)).
- Module audit constraint: scripts are self-contained; helpers are copied per script; only `workflow-paths.sh` is sourced.

## Evidence

- Copies of the normaliser at `.agents/skills/feature-workflow/scripts/status-transition.sh:121-145`, `.agents/skills/feature-workflow/scripts/budget-check.sh:78-98`, `.agents/skills/feature-workflow/scripts/task-waves.sh:60-74`, `.agents/skills/feature-workflow/scripts/open-task-pr.sh:62` as of commit `0a662df5d1046bd2984be858e813992a7fb36eb7`. Reported by module-audit; can wait.

## Acceptance criteria

- [ ] One helper under `.agents/lib/` resolves and validates a workflow folder path for both folder kinds.
- [ ] The per-script copies are removed and every caller sources the helper.
- [ ] Tests cover a spec path, an initiative path, an absolute path under the main checkout and a rejected path.
- [ ] `tests/run-all.sh` passes and shellcheck is clean.

## Out of scope

- Changing the path constants or their names.
- Any behaviour of the scripts beyond path validation.
