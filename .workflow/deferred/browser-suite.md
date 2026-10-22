---
origin_spec: .workflow/specs/004-scoped-test-runs
created: 2026-10-22
---

# Browser suite for this repo

**Summary:** This repo has no browser suite, so the light path's 3.10-3.11 browser gate is skipped.
**Mode:** HITL
**Origin:** [004-scoped-test-runs](../specs/004-scoped-test-runs/spec.md), 3.14 suite gap, design-log entry 2026-10-22 Suite gap: browser suite

## Goal

Either the repo has a browser suite the 3.10 gate can run, or a recorded decision says this repo never needs one, so later light-path specs stop logging the same gap.

## Background

The scaffold is bash scripts plus markdown, with no web UI for a browser to drive. The light path skips the browser gate when no browser-suite profile exists and records the skip as a gap, never as a pass.

**Current behaviour:** there is no `e2e-browser` work profile; every light-path spec skips 3.10-3.11.

**Desired behaviour:** a human decides whether a browser suite applies to this repo; if not, the decision is written where 3.13 can read it.

## Constraints

- `tests/run-all.sh` run by hand is the whole gate; CI is deferred ([ADR-0001](../decisions/adr/0001-project-baseline.md)).

## Evidence

- No `.workflow/profiles/e2e-browser.md` as of commit `af43dbe62290f644542244128f546a3b9d969ed3`.

## Acceptance criteria

- [ ] A stakeholder decision on whether this repo needs a browser suite is recorded (ADR or rules line).
- [ ] If none is needed, the light path no longer records a browser-suite gap for this repo.

## Out of scope

- The harness gate (3.9), which ran and passed for 004-scoped-test-runs.
