---
origin_spec: .workflow/specs/001-large-path
created: 2026-10-22
---

# First live run of the large path

**Summary:** The large path's journeys are proven by harness suites that replay the module's command sequences; no orchestrator has yet followed the module on a real initiative.
**Mode:** HITL
**Origin:** [001-large-path](../specs/001-large-path/spec.md), 4.8 review finding (gap F12), design-log entry 2026-10-22 Triage, review pass 1

## Goal

One real initiative has been converted, explored across at least two sessions, emitted a slice as a spec, reached `planned`, and closed, by an orchestrator following the module, and every place the run departed from the module or the suites is recorded.

## Background

The module is prose that an agent follows. The suites are the executable form of its steps and pass, but the only proof that an orchestrator does what the suites replay is a live run. The review lens could not verify that, so it is shelved as the first use of the feature.

**Current behaviour:** the suites pass; the module has not been run end to end on a real subject.

**Desired behaviour:** a live run with its discrepancies logged in that initiative's design log and fed back into the module or the suites.

## Constraints

- The run plans only; it never builds inside the initiative.

## Decisions already made

- Every request still starts as a spec; conversion happens from the questioning loop ([design-log.md](../specs/001-large-path/design-log.md) D2, D10).

## Evidence

- The eight journey suites under `tests/scripts/` and `tests/hooks/` and the fixture `tests/fixtures/initiative.sh`, as of commit `291e55289f399f767e7403715e14b73ffa5a7ccd`; the review-end-state lens's `not_verifiable` entry in `artifacts/review/pass-1/review-end-state.yaml`.

## Acceptance criteria

- [ ] One initiative in this repo has passed through conversion, at least one research launch left pending across a session end, one emission, `planned`, and `done`.
- [ ] Each step that differed from the module or the suites is recorded as a retrospective note or a work item.

## Out of scope

- Cross-spec delivery of the emitted specs (a non-goal of the origin spec).
