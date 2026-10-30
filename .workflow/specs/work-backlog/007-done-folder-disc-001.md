---
origin_spec: .workflow/specs/007-done-folder
origin_step: "3.4"
discovered_at: 2026-10-30
status: open
kind: decision
---

# One script form for the 6.13 initiative link rewrite

## Problem

When large-path 6.13 closes an initiative, it rewrites the initiative's links to emitted specs that have moved into the Done folder. The rewrite is a `sed` loop written into the 6.13 doc block, while the same path rewrite for every other `.workflow/` file lives in `move-to-done.sh`. So the rewrite rules are kept in two places, and they can drift apart.

## Evidence

- T4 implementation result (`.workflow/specs/007-done-folder/artifacts/T4/implementation.yaml`, `discovered_work[0]`): "6.13 must rewrite the initiative's links to specs moved into done/, but move-to-done.sh offers no form for that (--check, <spec-dir>, --sweep only). T4 put a sed loop in the 6.13 doc block".
- `.agents/skills/feature-workflow/modules/large-path.md` § 6.13, the rewrite loop (T4 commit `c863498`).
- Also seen: .workflow/specs/007-done-folder, 4.4: no harness suite runs the 6.13 rewrite block; the only evidence is a text check in `tests/lint/done-folder-docs.sh` and T4's stdin probe (review-end-state pass 1, `not_verifiable`). A script mode would bring a suite case with it.

## Why not a blocker

The doc loop meets D10: T4 tried it in a throwaway repo, where it rewrote only specs in `done/` on main and left a longer name with the same prefix alone. CAP-NEW-done-folder and JRN-001 to JRN-007 do not depend on which form 6.13 uses. T5's header names only sign-off 5.7 and 5.8 as callers.

## Suggested scope and size

- Scope: add a `move-to-done.sh` mode that rewrites one moved spec's links inside a given folder (the initiative folder), and have 6.13 call it in place of the loop. Covers the script, its suite and the 6.13 block; leaves the move itself unchanged.
- Size: one or two tasks in feature-workflow, about 3 files; well within the 10-task, 30-file budget.

## Links

- Origin spec: [spec.md](../007-done-folder/spec.md)
- Design log entry: [design-log.md](../007-done-folder/design-log.md) (section 2026-10-30 Discovered work: initiative-link-rewrite-form)
