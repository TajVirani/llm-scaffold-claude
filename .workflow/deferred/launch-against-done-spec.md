---
origin_spec: .workflow/specs/007-done-folder
created: 2026-10-30
---

# Launching a sub-agent against a finished spec

**Summary:** A sub-agent launch whose `spec_dir` names a spec in the Done folder is refused, so nothing can launch an agent for a finished spec.
**Mode:** HITL
**Origin:** [007-done-folder](../specs/007-done-folder/spec.md), 0.3.17 scope decision, design-log entry 2026-10-30 Scope decision: launch against a finished spec

## Goal

Work that legitimately runs on a finished spec, such as a standalone retrospective asked for later, can launch its sub-agents with the spec's Done folder path as `spec_dir`, while launches that would change a finished spec stay refused.

## Background

Spec 007 moves a finished spec into the **Done folder** (`.workflow/specs/done/NNN-slug/`) at sign-off 5.8. Every sub-agent launch in sign-off runs before the move, so 007 does not need a launch against a moved spec. The launch header's `spec_dir` format accepts only a direct child of `.workflow/specs/`, so any later launch against a moved spec is refused. Which task types should be allowed then is a decision nobody has made, so it was shelved.

**Current behaviour:** a launch header with `spec_dir: .workflow/specs/done/NNN-slug` is refused as malformed, on Claude Code and on Codex.

**Desired behaviour:** a read-only launch (for example the agents a standalone retrospective or a fact lookup needs) is accepted for a spec in the Done folder; a launch that would write into it (coding, integration, Phase 1 builds) is refused with a message that says the spec is finished.

## Constraints

- Every Write/Edit under `.workflow/specs/done/**` stays denied (007 D11).
- Spec numbers have any digit count.

## Decisions already made

- The move happens at 5.8, after every sign-off launch (D2, D14 in [.workflow/specs/007-done-folder/design-log.md](../specs/007-done-folder/design-log.md)).

## Evidence

- `resolve-launch.sh` requires `spec_dir` to match `^.workflow/specs/[0-9]+-[A-Za-z0-9._-]+/?$`, at `.agents/skills/feature-workflow/scripts/resolve-launch.sh:101-103` as of commit `9e971ade158b5e92da93bf2b150fd68dd55d7e9e` (module-audit refresh, 2026-10-30).

## Acceptance criteria

- [ ] A read-only task type launched with a Done folder `spec_dir` passes the launch check.
- [ ] A coding, integration or Phase 1 launch with a Done folder `spec_dir` is refused, and the message names the spec as finished.
- [ ] The Codex spawn check (`s<NNN>_...` names) resolves a spec number that lives only in the Done folder the same way.

## Out of scope

- Moving specs into the Done folder, and the write deny on it (spec 007).
- Reopening a finished spec for new work: that is new work, sized from scratch.
