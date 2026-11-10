---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
created: 2026-10-30
---

# Worktree guard early errors

**Summary:** The worktree guard denies, rather than lets through, a call it cannot decide because it failed before reading who is calling.
**Mode:** AFK
**Origin:** [00010-worktree-guard-followups](../specs/done/00010-worktree-guard-followups/spec.md), 5.9 work-backlog item `00010-worktree-guard-followups-disc-002.md` (found at 3.7), design-log entry 2026-10-30 Sign-off: stakeholder approval (5.5)

## Goal

The worktree guard denies, rather than lets through, a call it cannot decide because it failed before reading who is calling.

## Background

The guard arms its fail-closed exit trap only once it knows the caller is a confined sub-agent. Spec 00010 made the guard fail closed for unconfinable agents, an unparsable payload and a missing jq, but left the earlier steps (loading the shared paths library, reading the payload) as they were; it is reachable only with a partial install.

Problem, from the work item: The worktree guard's exit trap denies on an unexpected error only after it knows the call comes from an implementation or integration sub-agent. A failure before that point (sourcing the shared paths library, reading stdin) ends the hook with a non-zero exit, which the host treats as a non-blocking error, so the call goes through. The sibling write guards deny on any failure before a decision.

**Current behaviour:** a failure while loading the shared library or reading stdin ends the hook with a non-zero exit, which the host treats as a non-blocking error, so the call goes through.

**Desired behaviour:** any failure after the workflow is known to be installed gives a deny, as the three write guards do; main-session and other-agent calls that parse are still allowed silently.

## Constraints

- Hooks stay thin adapters with bash 3.2 (ADR-0001, `.workflow/rules.md` Required versions).

## Decisions already made

- Moved to the shelf at sign-off (design-log 2026-10-30 Sign-off entry in [.workflow/specs/done/00010-worktree-guard-followups/design-log.md](../specs/done/00010-worktree-guard-followups/design-log.md)).

## Evidence

- `.agents/hooks/worktree-write-guard.sh:56`, `:72`, `:74`, `:81` (exit trap gated on `CONFINED`; library source and stdin read before it), at T2 head `bb1b749`.
- T2 mini-review, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed[0]`.
- `workflow-write-guard.sh` denies on any failure before a decision (its header, Behaviour).
- Commit at shelving: `f276ea1`.

## Acceptance criteria

- [ ] With `.agents/lib/` missing but the feature-workflow scripts present, a confined agent's call is denied.
- [ ] Main-session calls that parse are still allowed silently.

## Out of scope

- Codex adapters.
