---
origin_spec: .workflow/specs/00010-worktree-guard-followups
created: 2026-10-30
---

# Asset list stop-audit row

**Summary:** The asset list's hooks-table row for the stop audit describes the hook as it runs today, for implementation and integration agents.
**Mode:** AFK
**Origin:** [00010-worktree-guard-followups](../specs/00010-worktree-guard-followups/spec.md), 5.9 work-backlog item `00010-worktree-guard-followups-disc-001.md` (found at 1.2), design-log entry 2026-10-30 Sign-off: stakeholder approval (5.5)

## Goal

The asset list's hooks-table row for the stop audit describes the hook as it runs today, for implementation and integration agents.

## Background

Spec 00010 rewrote the asset list's inventory row, guard row and D85 item 6 in place to match spec 006, and the stakeholder kept that rewrite to the rows the work items named. A second stop-audit row in the hooks table was found during the build and moved to the shelf at sign-off rather than growing the spec.

Problem, from the work item: `assetlist.md` has a second `post-implementation-audit` row, in the hooks table, that still says the stop audit runs for implementation agents only. The stop audit now runs for implementation and integration agents, so this row misleads a maintainer reading the record after spec 00010 corrects the inventory row.

**Current behaviour:** the hooks-table row says the stop audit runs on `SubagentStop` for `implementation` only.

**Desired behaviour:** the row says the stop audit runs for implementation and integration agents (matcher `implementation|integration`), rewritten in place.

## Constraints

- `assetlist.md` is rewritten in place to describe current behaviour, with no "Amended by" note or spec reference (design-log D8).

## Decisions already made

- Moved to the shelf at sign-off (design-log 2026-10-30 Sign-off entry in [.workflow/specs/00010-worktree-guard-followups/design-log.md](../specs/00010-worktree-guard-followups/design-log.md)).

## Evidence

- `assetlist.md:593` (hooks table): "SubagentStop for `implementation`" and "`SubagentStop` (filter to `implementation` in script)".
- Phase 1 build result, `.workflow/specs/00010-worktree-guard-followups/artifacts/phase-1-test-harness/implementation.yaml` `discovered_work[0]`.
- `.agents/hooks/claude-settings.template.json` SubagentStop matcher is `implementation|integration`.
- Commit at shelving: `f276ea1`.

## Acceptance criteria

- [ ] The hooks-table stop-audit row names implementation and integration agents and the matcher `implementation|integration`.
- [ ] The row carries no "Amended by" note.

## Out of scope

- Other rows of the asset list.
