---
origin_spec: .workflow/specs/00010-worktree-guard-followups
origin_step: "3.7"
discovered_at: 2026-10-30
status: moved-to-deferred
kind: bug
---

# Malformed sub-agent transcript gets the wrong deny cause

## Problem

When a confined sub-agent's transcript is not valid JSON, the worktree guard still denies, but its reason says the transcript has no first user message. That sends the orchestrator looking for the wrong fault.

## Evidence

- `.agents/hooks/worktree-write-guard.sh:108`, `:110` (jq's stderr discarded, then the empty-prompt cause), at T2 head `bb1b749`.
- T2 mini-review, `.workflow/specs/00010-worktree-guard-followups/artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed[1]`.

## Why not a blocker

The call is denied either way, so CAP-007's fail-closed success line holds; only the cause text is wrong, and only for a malformed transcript, a case JRN-001 does not list.

## Suggested scope and size

- Scope: tell an unparsable transcript apart from an empty first message in the deny reason; one guard case with a malformed transcript.
- Size: 1 task in hooks, 2 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../00010-worktree-guard-followups/spec.md)
- Design log entry: [design-log.md](../00010-worktree-guard-followups/design-log.md) (section 2026-10-30 Discovered work: T2 mini-review notes)
- Deferred file: [.workflow/deferred/worktree-guard-transcript-cause.md](../../deferred/worktree-guard-transcript-cause.md)
