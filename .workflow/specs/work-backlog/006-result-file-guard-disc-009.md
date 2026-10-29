---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "4.4"
discovered_at: 2026-10-29
status: open
kind: refactor
---

# Asset list still describes the isolation launch

## Problem

`assetlist.md`, the scaffold's decision record for its assets, still describes behaviour spec 006 removed. It gives the stop-audit matcher as `implementation`. It also says Phase 1 builds and integration batches keep their existing worktree handling, with the isolation-relaunch fallback. Neither has the "Amended by" note the file uses elsewhere.

## Evidence

- `assetlist.md:40` ("`SubagentStop`, matcher `implementation` (script also filters)") and `assetlist.md:234` (D85 item 6, the isolation fallback), at spec-branch commit `5fdfb89`.
- `.agents/hooks/claude-settings.template.json` SubagentStop matcher is now `implementation|integration`. `.workflow/specs/006-result-file-guard/design-log.md` D5: "Remove the fallback".
- Review pass 1, `.workflow/specs/006-result-file-guard/artifacts/review/pass-1/review-standards.yaml` RS-2 (triage F4).

## Why not a blocker

`assetlist.md` is scaffold-only and never installed, so no target project is affected. It misleads only a maintainer reading the record. Every capability and journey of spec 006 is unaffected.

## Suggested scope and size

- Scope: amend the stop-audit row and D85 item 6 with an "Amended by spec 006" note giving the new matcher, the orchestrator-made Phase 1 and integration worktrees, and the removed fallback.
- Size: 1 task, 1 file; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Triage, review pass 1)
