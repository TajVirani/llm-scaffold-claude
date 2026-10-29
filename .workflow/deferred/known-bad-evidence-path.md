---
origin_spec: .workflow/specs/006-result-file-guard
created: 2026-10-29
---

# Known-bad evidence path

**Summary:** Evidence from the 1.4 known-bad runs lands in the main checkout's spec folder, not in the throwaway worktree the runs use.
**Mode:** AFK
**Origin:** [006-result-file-guard](../specs/006-result-file-guard/spec.md), 0.3.17 scope decision, design-log entry 2026-10-29 Scope decision: known-bad evidence path

## Goal

After step 1.4, `<spec_dir>/artifacts/phase-1-known-bad/` in the main checkout holds the known-bad run records and logs.

## Background

Found by the feature-workflow module audit for spec 006. It concerns Phase 1 evidence placement, not result files or the merge gate.

**Current behaviour:** the 1.4 runs happen in a scratch worktree, but the example commands write evidence to a relative spec-folder path, which resolves inside that worktree; the worktree is then removed with `--force`, taking the evidence with it unless the orchestrator writes it elsewhere.

**Desired behaviour:** the 1.4 instructions name the main checkout's spec folder as the evidence destination, so the records survive the worktree's removal.

## Evidence

- `.agents/skills/feature-workflow/modules/verification-setup.md:98-103`, as of commit `02bc218`.

## Acceptance criteria

- [ ] The 1.4 instructions write every evidence file to an absolute main-checkout path.
- [ ] A dry run of 1.4 leaves the record in `<spec_dir>/artifacts/phase-1-known-bad/` after the scratch worktree is removed.

## Out of scope

- Result files and the artifacts merge gate (spec 006).
