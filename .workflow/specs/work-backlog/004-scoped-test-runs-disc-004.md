---
origin_spec: .workflow/specs/004-scoped-test-runs
origin_step: "4.4"
discovered_at: 2026-10-22
status: dismissed
kind: bug
---

# Workflow-data commits carry other specs' files

## Problem

`commit-workflow-data.sh` stages everything under the workflow root except other spec and initiative folders. Tier A and shelf files written for another in-flight spec (an ADR, deferred items, work-backlog items) are therefore committed on whichever spec branch commits workflow data next, and reach main with that spec, even while the spec they belong to is still an untracked draft.

## Evidence

- `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh:6-7` (staging scope), as of commit `9fe4e82d5435bd769bfe58f9e39b65d63ae3b662`.
- Commit `af43dbe` ("Workflow data for 004-scoped-test-runs: wave 1 merged") added `.workflow/decisions/adr/0002-review-lessons-placement.md` (status accepted, spec 002), `.workflow/deferred/boundary-check-wording.md` (origin 003), `.workflow/deferred/retrospective-template-drift.md` (origin 002) and `001-large-path-disc-002..004.md`; specs 002 and 003 were untracked.
- Reported by review-standards RS-2 and review-end-state RE-1, triage F2 of 004-scoped-test-runs pass 1.

## Why not a blocker

CAP-001 touches `tests/` only and is unaffected. The stakeholder chose to ship the carried files with 004 as they are.

## Suggested scope and size

- Scope: limit the staging to files the current spec wrote or owns (its folder, items whose `origin_spec` is this spec, Tier A files written at this spec's guarded steps), or record each Tier A write's owning spec so the script can filter; cover it in the commit-workflow-data suite.
- Size: one or two tasks in feature-workflow plus tests; inside the defaults.

## Links

- Origin spec: [spec.md](../004-scoped-test-runs/spec.md)
- Design log entry: [design-log.md](../004-scoped-test-runs/design-log.md) (section 2026-10-22 Discovered work: workflow-data-cross-spec-commit)
- Dismissed at 5.9: "This is acceptable".
