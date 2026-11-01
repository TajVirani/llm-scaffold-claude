---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
origin_step: "3.7"
discovered_at: 2026-10-30
status: moved-to-deferred
kind: bug
---

# Worktree guard errors before confinement are not denied

## Problem

The worktree guard's exit trap denies on an unexpected error only after it knows the call comes from an implementation or integration sub-agent. A failure before that point (sourcing the shared paths library, reading stdin) ends the hook with a non-zero exit, which the host treats as a non-blocking error, so the call goes through. The sibling write guards deny on any failure before a decision.

## Evidence

- `.agents/hooks/worktree-write-guard.sh:56`, `:72`, `:74`, `:81` (exit trap gated on `CONFINED`; library source and stdin read before it), at T2 head `bb1b749`.
- T2 mini-review, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed[0]`.
- `_guard-common.sh` denies on any failure before a decision (its header, line 11).

## Why not a blocker

Pre-existing and untouched by spec 00010; reachable only with a partial install where `.agents/lib/` is missing while `check-worktree-scope.sh` exists. CAP-007's success line (JRN-001 to JRN-003) is met for every installed layout.

## Suggested scope and size

- Scope: arm the fail-closed trap from the start once the workflow is known to be installed, keeping the silent allow for main-session and other-agent calls that parse; add a partial-install case to `tests/hooks/worktree-guard.sh`.
- Size: 1 task in hooks, 2 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../done/00010-worktree-guard-followups/spec.md)
- Design log entry: [design-log.md](../done/00010-worktree-guard-followups/design-log.md) (section 2026-10-30 Discovered work: T2 mini-review notes)
- Deferred file: [.workflow/deferred/worktree-guard-early-errors.md](../../deferred/worktree-guard-early-errors.md)
