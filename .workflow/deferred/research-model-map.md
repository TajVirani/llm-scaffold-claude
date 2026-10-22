---
origin_spec: .workflow/specs/001-large-path
created: 2026-10-22
---

# A model for the research task type in this repo

**Summary:** This repo has no `.workflow/model-map/research.md`, so the first research launch from an initiative here stops at the 00.14 "no model assigned" deny until a human picks one.
**Mode:** HITL
**Origin:** [001-large-path](../specs/001-large-path/spec.md), 4.8 review finding (gap F10), design-log entry 2026-10-22 Triage, review pass 1

## Goal

A research launch from an initiative in this repo resolves its model without stopping, from a model-map entry the stakeholder chose.

## Background

The spec assumed this repo would record the research model in its model map, but the task that added the agent left the entry to the 00.14 flow at the first real launch, and no launch happened during the feature. The choice of model tier is the stakeholder's, so the entry was not written by an agent.

**Current behaviour:** `resolve-launch.sh` finds no `models:` in the agent definition and no `.workflow/model-map/research.md`, and denies the launch with 00.14.

**Desired behaviour:** `.workflow/model-map/research.md` exists with a tier and a host alias per host, and a research launch resolves its model like every other task type.

## Constraints

- Agent definitions are scaffold-owned and never pinned to a model in a target project; the project's choice lives in the model map or in `agent-overrides.yaml`.

## Decisions already made

- The research task type takes `spec_dir` only and gets its model through the existing 00.14 flow at first launch (design-log Assumptions, [spec.md](../specs/001-large-path/spec.md)).

## Evidence

- No `.workflow/model-map/research.md` at commit `291e55289f399f767e7403715e14b73ffa5a7ccd`; the model-map folder holds entries for every other task type.

## Acceptance criteria

- [ ] `.workflow/model-map/research.md` exists, in the shape of its siblings, with a tier and `claude` and `codex` aliases.
- [ ] `resolve-launch.sh --task-type research` with an initiative folder as `spec_dir` returns a model in this repo.

## Out of scope

- Choosing the model in target projects: their own 00.14 flow handles it.
