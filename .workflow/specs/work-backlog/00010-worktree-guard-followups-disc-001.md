---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
origin_step: "1.2"
discovered_at: 2026-10-30
status: moved-to-deferred
kind: bug
---

# Second stop-audit row in the asset list says implementation only

## Problem

`assetlist.md` has a second `post-implementation-audit` row, in the hooks table, that still says the stop audit runs for implementation agents only. The stop audit now runs for implementation and integration agents, so this row misleads a maintainer reading the record after spec 00010 corrects the inventory row.

## Evidence

- `assetlist.md:593` (hooks table): "SubagentStop for `implementation`" and "`SubagentStop` (filter to `implementation` in script)".
- Phase 1 build result, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/phase-1-test-harness/implementation.yaml` `discovered_work[0]`.
- `.agents/hooks/claude-settings.template.json` SubagentStop matcher is `implementation|integration`.

## Why not a blocker

Spec 00010's D8 rewrites `assetlist.md:40`, `:47` and D85 item 6; this row is outside that list. `assetlist.md` is scaffold-only and never installed, and no capability or journey of 00010 (CAP-007, CAP-008, CAP-NEW-extract-write-deny, JRN-001 to JRN-009) depends on it.

## Suggested scope and size

- Scope: rewrite the hooks-table row in place to say the stop audit runs for implementation and integration agents, with no "Amended by" note (the stakeholder's D8 rule for this file). Leave the rest of the table alone.
- Size: 1 task, 1 file; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../done/00010-worktree-guard-followups/spec.md)
- Design log entry: [design-log.md](../done/00010-worktree-guard-followups/design-log.md) (section 2026-10-30 Discovered work: assetlist-second-audit-row)
- Deferred file: [.workflow/deferred/asset-list-stop-audit-row.md](../../deferred/asset-list-stop-audit-row.md)
