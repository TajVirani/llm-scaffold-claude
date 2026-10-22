---
origin_spec: .workflow/specs/002-review-lessons
created: 2026-10-21
---

# Retrospective template drift

**Summary:** Two notes in the retrospective document template contradict the retrospective skill: its header comment lists rules and profiles among the Tier A files the skill writes, and its Model observations text names a project-root `agent-overrides.yaml` instead of the one under `.workflow/`.
**Mode:** AFK
**Origin:** [.workflow/specs/002-review-lessons](../specs/002-review-lessons/spec.md), 0.3.17 scope decision, design-log entry 2026-10-21 Scope decision: retrospective template drift

## Goal

A reader of the retrospective template learns the same facts the skill applies: which Tier A files the skill writes, and where a model override proposal goes.

## Background

The module audit for the review-lessons feature noticed both lines while reading the owning module. They sit outside that feature's scope: it adds a destination and does not re-audit the template's prose, and fixing text the feature does not touch would widen its diff with nothing to test it.

**Current behaviour:** the template comment says Tier A writes (pitfalls.md, rules, profiles) go through 5.7, while the skill says it never edits rules or profiles; the Model observations text points at `<project>/agent-overrides.yaml`, while routing writes `.workflow/agent-overrides.yaml`.

**Desired behaviour:** the template names only the Tier A files the skill writes, and the `.workflow/agent-overrides.yaml` path.

## Constraints

- The retrospective skill never edits `rules.md`, profiles, skills or agent definitions; the fix is to the template text only.

## Decisions already made

- The review-lessons feature adds `.workflow/review-lessons.md` to the Tier A files the retrospective writes at 5.7 (D1 and D7 in [.workflow/specs/002-review-lessons/design-log.md](../specs/002-review-lessons/design-log.md)); the corrected comment should name it too.

## Evidence

- The template comment lists rules and profiles as 5.7 Tier A writes, at `.agents/skills/retrospective/assets/retrospective.md:13` as of commit `6704f9384d7756d89752a831d12f364ba6f4aab1`; the skill's never-list is at `.agents/skills/retrospective/SKILL.md:34`, same commit.
- The Model observations text names `<project>/agent-overrides.yaml`, at `.agents/skills/retrospective/assets/retrospective.md:85`; routing uses `.workflow/agent-overrides.yaml`, at `.agents/skills/retrospective/modules/routing.md:52`, same commit.

## Acceptance criteria

- [ ] The template's header comment names only the Tier A files the skill writes.
- [ ] The Model observations text names `.workflow/agent-overrides.yaml`.
- [ ] `tests/run-all.sh` passes.

## Out of scope

- Any change to what the retrospective writes or routes.
