---
origin_spec: .workflow/specs/00014-tracker-issue-spec-ids
created: 2026-11-02
---

# Initiative tracker issues

**Summary:** File initiatives and their slices as tracker issues, and number initiatives and converted specs from the tracker.
**Mode:** HITL
**Origin:** [00014-tracker-issue-spec-ids](../specs/00014-tracker-issue-spec-ids/spec.md), 0.3.17 scope decision, design-log entry 2026-11-02 Scope decision: initiative-tracker-issues

## Goal

On a project with a tracker, an initiative has a parent tracker issue above its slices' spec issues, and its number, like a spec's, comes from the tracker.

## Background

Spec 00014 makes the tracker the source of spec numbers and files specs and tasks. The stakeholder named initiatives and slices as later work built on it (00014 design-log, Deeper prompt, Downstream). The large path keeps local numbering and has no step to close or re-point the issue of a spec converted into an initiative.

**Current behaviour:** Initiative numbers come from a local scan; a spec converted into an initiative keeps its consumed number, and on a tracker its issue stays open with nothing pointing at the initiative.

**Desired behaviour:** An initiative is filed as a tracker issue that its slices' spec issues sit under; conversion re-points or closes the converted spec's issue; initiative numbers cannot collide between people.

## Decisions already made

- Spec issues sit under no parent in 00014; the design leaves room for one (design-log D3 in [.workflow/specs/00014-tracker-issue-spec-ids/design-log.md](../specs/00014-tracker-issue-spec-ids/design-log.md)).

## Evidence

- Initiative numbering scan at `.agents/skills/feature-workflow/modules/large-path.md:71`; converted spec number kept at `large-path.md:89`, as of commit `7b50de2`.

## Acceptance criteria

- [ ] An initiative on a tracker project gets a tracker issue; each emitted slice's spec issue is its child.
- [ ] Converting a spec into an initiative closes or re-points the spec's issue.
- [ ] A project with no tracker keeps today's initiative numbering.

## Out of scope

- Spec and task issues (spec 00014).
