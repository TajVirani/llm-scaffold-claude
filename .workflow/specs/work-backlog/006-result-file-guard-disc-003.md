---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "3.7"
discovered_at: 2026-10-29
status: promoted
promoted_to: .workflow/specs/00010-worktree-guard-followups
kind: decision
---

# Worktree guard allows when it cannot confine

## Problem

The worktree guard lets a non-isolated implementation or integration agent write into the main checkout in two cases where it cannot establish confinement:
- The launch header cannot be parsed.
- The worktree named for the launch does not exist.

Both are documented as "allow" in the guard's Behaviour text. The shell-scripts profile says guard hooks fail closed on a helper error. Which rule wins is undecided.

## Evidence

- `.agents/hooks/worktree-write-guard.sh:92-93`: the header parse runs with `2>/dev/null` and an `if` fallback, so a parse error leaves no worktree name. Behaviour, `:23-24`: no header or no worktree, allow. Line numbers are at T1 head `9e706b7`.
- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:101-104`: rule 3 allows every write when the named worktree is missing and the cwd is the main checkout.
- `.workflow/profiles/shell-scripts.md:25`: "Guard hooks fail closed: on an unparsable payload or a helper error they print the host's deny JSON and exit 0."
- T1 mini-review round 3, `.workflow/specs/006-result-file-guard/artifacts/T1/mini-review.yaml` `out_of_scope_noticed` (two decision entries).

## Why not a blocker

Both paths predate spec 006 for Phase 3 tasks. T1 only applies the same rule to Phase 1 and integration launches. The stop audit still warns after the stop when the worktree is missing. CAP-NEW-result-file-write's success line and JRN-002 to JRN-004 hold for launches whose header parses and whose worktree exists, which is every launch the orchestrator makes.

## Suggested scope and size

- Scope: decide deny or allow for each of the two cases. Then align the guard, the scope check, the Behaviour text and the profile line, with negative cases in `tests/hooks/worktree-guard.sh`. Leave isolation launches (linked-worktree cwd) as they are.
- Size: 1 to 2 tasks in hooks and feature-workflow, about 4 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: guard-allows-without-confinement)
