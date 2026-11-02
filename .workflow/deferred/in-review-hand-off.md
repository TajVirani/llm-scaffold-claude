---
origin_spec: .workflow/specs/done/009-slim-workflow-context
created: 2026-11-01
---

# Hand-off on every route to review

**Summary:** Every route by which implementation sets `in-review` runs the hand-off: agent worktree cleanup and the last workflow-data commit before review starts.
**Mode:** AFK
**Origin:** [009-slim-workflow-context](../specs/done/009-slim-workflow-context/spec.md), 0.3.17 scope decision, design-log entry 2026-11-01 Scope decision: hand-off on every route to review

## Goal

However Phase 3 ends, the spec branch holds the evidence the last gates wrote and no implementation or integration worktree is left behind when review starts.

## Background

The orchestrator's 3.11 exit links to the hand-off, which removes leftover agent worktrees and commits the workflow data. The light-path exits at 3.14 (only the harness exists, or neither suite exists) set `in-review` and "go straight to Phase 4" without naming the hand-off. Found by the module audit for 009, which splits the orchestrator into step files but must keep its behaviour unchanged, so the gap is carried over as is and shelved here.

**Current behaviour:** on a light-path spec missing a suite, the 3.14 exit sets `in-review` and loads review without the cleanup or the workflow-data commit.

**Desired behaviour:** the 3.14 exits run the hand-off as the 3.11 exit does.

## Constraints

- Status transitions stay as `status-transition.sh` allows them today.

## Evidence

- 3.11 links the hand-off at `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:285`; the 3.14 exits at `:303` do not; the hand-off is at `:341-343`, as of commit `7a9b852926ecbc03b00ebf8408c2b2230341c72a`. Reported by module-audit; can wait.

## Acceptance criteria

- [ ] Each 3.14 exit names the hand-off before review loads.
- [ ] A light-path run without a browser suite ends Phase 3 with no agent worktree left under `.workflow/.worktrees/` and the workflow data committed.

## Out of scope

- Changing what the hand-off itself does.
