---
origin_spec: .workflow/specs/008-pr-description-template
created: 2026-10-29
---

# Workflow settings home

**Summary:** Keep all project-wide workflow settings (behaviour settings and model choices) in one central place.
**Mode:** HITL
**Origin:** [008-pr-description-template](../specs/008-pr-description-template/spec.md), 0.3.17 scope decision, design-log entry 2026-10-29 Deep dive: where the use-or-ignore answer is saved

## Goal

A person or agent finds every project-wide workflow setting in one place, reads it through one interface, and knows one rule for when it may change.

## Background

Spec 008 needed to save one project-wide choice (whether the Sign-off PR uses the project's own PR template). Looking for where to put it showed that settings live in several homes with different write rules. 008 added its key to the existing behaviour-settings block; unifying the homes is a wider change to the workflow's Tier A rules and was kept out of scope.

**Current behaviour:** Behaviour settings (`task_review`, `main_branch`, and from 008 `pr_template`) are a YAML block under `## Workflow settings` in `.workflow/rules.md`, which is Tier A and changes only at sign-off approval. Model choices live in one file per task type under `.workflow/model-map/` plus `.workflow/agent-overrides.yaml`, which are unguarded and written mid-flow. Spec state lives per spec in `spec.md` and its `.step` marker.

**Desired behaviour:** One settings home (file or folder) holds every project-wide setting, read through one script, with a stated rule for which settings need approval and which can be saved the moment the stakeholder answers. Existing projects migrate without losing values.

## Constraints

- Spec state (`status`, `.step`) stays per spec and changes only through `status-transition.sh`; it is not a setting.
- Model precedence (override, then agent definition, then model map) must be kept.
- Target projects already have these files; `install.sh` and `project-setup` must migrate or keep reading them.

## Decisions already made

- 008 keeps `pr_template` in the rules.md Workflow settings block for now (design-log D9 in [.workflow/specs/008-pr-description-template/design-log.md](../specs/008-pr-description-template/design-log.md)).

## Evidence

- Behaviour settings are read from the rules.md block by `.agents/skills/feature-workflow/scripts/rules-setting.sh:42-48, 86-98` as of commit `02bc218`.
- rules.md is Tier A, writable only at 0.3.7, 5.3, 5.7: `.agents/skills/feature-workflow/scripts/check-write.sh:75` as of commit `02bc218`.
- Model precedence is resolved in `.agents/skills/feature-workflow/scripts/resolve-launch.sh` from `.workflow/agent-overrides.yaml` and `.workflow/model-map/<type>.md` as of commit `02bc218`.

## Acceptance criteria

- [ ] Every project-wide workflow setting is listed in one home, with its default and allowed values.
- [ ] One script reads any setting by key.
- [ ] Each setting states whether changing it needs approval, and the write guard follows that.
- [ ] An existing project's values survive the upgrade.

## Out of scope

- Per-spec state (`status`, `.step`, task records).
- Changing what any setting does.
