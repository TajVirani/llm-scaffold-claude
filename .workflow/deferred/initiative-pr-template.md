---
origin_spec: .workflow/specs/done/008-pr-description-template
created: 2026-10-29
---

# Initiative PR template

**Summary:** Give the initiative PR into main (large path, 6.11/6.13) a filled PR template, as the Sign-off PR gets one.
**Mode:** HITL
**Origin:** [008-pr-description-template](../specs/done/008-pr-description-template/spec.md), 0.3.17 scope decision (module-audit, out of scope noticed), design-log entry 2026-10-29 Scope decision: initiative PR template

## Goal

A reviewer of an initiative PR sees its intent, what was planned, and how to undo it in the PR description, just as on a Sign-off PR.

## Background

Spec 008 adds the PR template to the Sign-off PR only. The initiative PR is a separate path: it merges an initiative's planning records, not built code. Several template sections (how to test, blast radius) may not apply to it, so the right shape needs its own decision.

**Current behaviour:** The initiative PR's description is just its title; no body is passed.

**Desired behaviour:** The initiative PR carries a filled description whose sections fit a planning merge, with the same evidence-not-claims rule.

## Constraints

- Reuse the PR template and its check script where the sections fit; do not fork a second template without reason.

## Decisions already made

- The PR template covers the Sign-off PR only (spec 008 Non-goals, [.workflow/specs/done/008-pr-description-template/spec.md](../specs/done/008-pr-description-template/spec.md)).

## Evidence

- The initiative PR uses `open-task-pr.sh` generic mode with no `--body`, so the body defaults to the title: `.agents/skills/feature-workflow/modules/large-path.md:218-221` and `.agents/skills/feature-workflow/scripts/open-task-pr.sh:121-123` as of commit `02bc218`.

## Acceptance criteria

- [ ] An initiative PR into main opens with a filled description, not just its title.
- [ ] The description's sections are checked by script before the PR opens.

## Out of scope

- Task PR bodies (3.16).
