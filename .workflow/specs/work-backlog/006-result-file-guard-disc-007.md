---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "3.7"
discovered_at: 2026-10-29
status: promoted
promoted_to: .workflow/specs/00010-worktree-guard-followups
kind: bug
---

# Re-run checks in the upgrade suite ignore the exit code

## Problem

Three checks in the `install.sh` upgrade suite assert that a re-run writes nothing, but not that the re-run succeeded. A re-run that refused with exit 1 also writes nothing, so a regression that makes re-runs refuse would pass them.

## Evidence

- `tests/scripts/install-upgrade.sh:280-281` (JRN-011 third run) and `:408-409` (two-template-groups re-run), at T6 head `b78d868`.
- T6 mini-review round 5, `.workflow/specs/006-result-file-guard/artifacts/T6/mini-review.yaml` `out_of_scope_noticed`.

## Why not a blocker

The install behaviour is unaffected: today's re-runs exit 0, and JRN-011's idempotence holds. Only the checks' strength is short.

## Suggested scope and size

- Scope: assert exit 0 on each "re-run writes nothing" check in `tests/scripts/install-upgrade.sh`. This could go with the suite split in `006-result-file-guard-disc-001`.
- Size: 1 task in tests, 1 file; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: rerun-checks-ignore-exit)
