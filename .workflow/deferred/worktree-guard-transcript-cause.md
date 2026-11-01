---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
created: 2026-10-30
---

# Worktree guard transcript cause

**Summary:** When a confined sub-agent's transcript is not valid JSON, the worktree guard's deny reason says so.
**Mode:** AFK
**Origin:** [00010-worktree-guard-followups](../specs/done/00010-worktree-guard-followups/spec.md), 5.9 work-backlog item `00010-worktree-guard-followups-disc-003.md` (found at 3.7), design-log entry 2026-10-30 Sign-off: stakeholder approval (5.5)

## Goal

When a confined sub-agent's transcript is not valid JSON, the worktree guard's deny reason says so.

## Background

Spec 00010 made the guard deny a confined agent whose launch header cannot be read and name the cause. A transcript that exists but does not parse is reported with the empty-first-message cause, which points the orchestrator at the wrong fault. The deny itself is correct.

Problem, from the work item: When a confined sub-agent's transcript is not valid JSON, the worktree guard still denies, but its reason says the transcript has no first user message. That sends the orchestrator looking for the wrong fault.

**Current behaviour:** a malformed transcript is denied with "has no first user message".

**Desired behaviour:** the reason names an unparsable transcript, distinct from an empty first message.

## Constraints

- Fail closed when no agent worktree can be established (design-log D3).

## Decisions already made

- Moved to the shelf at sign-off (design-log 2026-10-30 Sign-off entry in [.workflow/specs/done/00010-worktree-guard-followups/design-log.md](../specs/done/00010-worktree-guard-followups/design-log.md)).

## Evidence

- `.agents/hooks/worktree-write-guard.sh:108`, `:110` (jq's stderr discarded, then the empty-prompt cause), at T2 head `bb1b749`.
- T2 mini-review, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed[1]`.
- Commit at shelving: `f276ea1`.

## Acceptance criteria

- [ ] A guard case with a malformed transcript expects a reason naming the parse failure.
- [ ] The existing missing-transcript and empty-message causes are unchanged.

## Out of scope

- The live-payload question in `subagent-missing-transcript-path.md`.
