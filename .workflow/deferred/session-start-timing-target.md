---
origin_spec: .workflow/specs/001-large-path
created: 2026-10-22
---

# A timing target for the session-start hook

**Summary:** The session-start hook now reads initiative branch tips with `git show` and checks emitted specs against the main ref, and no wall-time target was set or measured for it.
**Mode:** AFK
**Origin:** [001-large-path](../specs/001-large-path/spec.md), 4.8 review finding (gap F13), design-log entry 2026-10-22 Triage, review pass 1

## Goal

The hook's running time has a measured ceiling in a fixture with several specs, initiatives and handoffs, well inside the hook's 10 second timeout, or a recorded decision that none is needed.

## Background

At 1.1 the stakeholder chose not to set a performance target, since the stack has no profiler and the hook timeout is the only ceiling. The targets lens therefore reports the row as not measurable, which the workflow records as a gap rather than a pass.

**Current behaviour:** the hook's time is not measured; the Targets table carries the row with "not measured" in place of a command.

**Desired behaviour:** a suite or target command prints the hook's elapsed time in a known fixture, and a threshold is recorded, or the stakeholder records that the timeout is the only ceiling they want.

## Constraints

- Hooks keep a 10 second timeout in the settings templates.

## Decisions already made

- No performance target for this spec (1.1, 2026-10-22, [design-log.md](../specs/001-large-path/design-log.md)).

## Evidence

- `verification-plan.md` Targets row 5 and `artifacts/review/pass-1/review-targets.yaml` (`result: not_measurable`), as of commit `291e55289f399f767e7403715e14b73ffa5a7ccd`.

## Acceptance criteria

- [ ] A command prints the hook's wall time in a fixture with three specs, three initiatives (one only on its branch) and two handoffs, and a threshold is recorded in a verification plan, or
- [ ] a decision record states that the hook timeout is the only ceiling.

## Out of scope

- Optimising the hook before a measurement exists.
