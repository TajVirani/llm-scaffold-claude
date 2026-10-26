---
origin_spec: .workflow/specs/003-bash-cache-extractor
origin_step: "4.4"
discovered_at: 2026-10-26
status: promoted
kind: decision
promoted_to: .workflow/specs/008-agents-skill-dependencies
---

# The agents module reaches skills that its ownership entry does not allow

## Problem

The `cache-regeneration` agent runs regenerate-caches scripts and visual-change-report's Mermaid validator by `skills/<name>/` path. `.workflow/rules.md` Ownership lets the agents module depend only on feature-workflow, and it counts a `skills/<name>/` path reference as a dependency. So the agent breaks the ownership map, and nothing enforces it.

## Evidence

- `.agents/agents/cache-regeneration.md:36` (`S=.agents/skills/regenerate-caches/scripts`, already at baseline `86609a6`), `:85` and `:88` (visual-change-report paths).
- `.workflow/rules.md:79-81`: `agents: owns: [".agents/agents/**"] may_depend_on: [feature-workflow]`.
- Found by review-standards, review pass 2 (RS-3, triage F8): `.workflow/specs/003-bash-cache-extractor/artifacts/review/pass-2/review-standards.yaml`.

## Why not a blocker

The dependency predates spec 003; this change only adds calls through the same path (`build-architecture.sh --print-generator`). No capability success line or journey depends on the ownership map, and no boundary tool checks it for bash.

## Suggested scope and size

- Scope: a decision, then one change. Either add `regenerate-caches` and `standalone-skills` to `agents.may_depend_on` in `.workflow/rules.md` (and regenerate the boundary config), or move the script calls out of the agent definition into the regenerate-caches skill.
- Size: 1 task, well under the default budget of 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../003-bash-cache-extractor/spec.md)
- Design log entry: [design-log.md](../003-bash-cache-extractor/design-log.md) (section 2026-10-26 Discovered work: agents-module-dependencies)
