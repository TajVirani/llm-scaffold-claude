---
origin_spec: .workflow/specs/done/006-result-file-guard
created: 2026-10-29
---

# Codex spawn profile lookup

**Summary:** The Codex pre-spawn check and the stop audit resolve a Phase 1 work type against the same set of profiles.
**Mode:** AFK
**Origin:** [006-result-file-guard](../specs/done/006-result-file-guard/spec.md), 0.3.17 scope decision, design-log entry 2026-10-29 Scope decision: Codex spawn profile lookup

## Goal

A Codex Phase 1 spawn whose work type has a profile is accepted at spawn exactly when the stop audit would accept it.

## Background

Found by the hooks module audit for spec 006. Codex only and unchanged by spec 006, which keeps `codex-pre-spawn.sh` behaviour apart from sharing the encoder.

**Current behaviour:** the pre-spawn hook resolves an encoded work type only against profiles in the main checkout, while the stop audit also searches the agent worktree's profiles. A profile added inside a Phase 1 worktree passes the audit lookup but is denied at spawn.

**Desired behaviour:** both hooks use the same profile search, and the case where a profile exists only in the worktree is decided once and documented.

## Constraints

- Hooks stay thin adapters over shared scripts (ADR-0001).
- `codex-pre-spawn.sh` sources the library only after confirming the workflow is installed.

## Evidence

- Main-checkout-only lookup: `.agents/hooks/codex-pre-spawn.sh:117`; worktree lookup: `.agents/hooks/post-implementation-audit.sh:143`, as of commit `02bc218`.

## Acceptance criteria

- [ ] A suite case with a profile present only in the Phase 1 worktree gives the same verdict at spawn and at stop.

## Out of scope

- Name parsing in general (`.workflow/deferred/worktree-name-parser.md`).
