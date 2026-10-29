---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "4.4"
discovered_at: 2026-10-29
status: open
kind: refactor
---

# Worktree guard messages say task worktree

## Problem

The worktree scope check's deny and allow messages, and the `# File:` lines of the scope check and the worktree guard, call the agent's worktree a "task worktree". Phase 1 builds and integration batches now pass through the same guard, and the glossary lists "Task worktree" as an _Avoid_ alias for **Agent worktree** ("Phase 1 and integration are not tasks"). So a denied Phase 1 or integration agent is told it works in a task worktree.

## Evidence

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:2`, `:114`, `:125`, `:234` ("this agent works only in its task worktree $root"); `.agents/hooks/worktree-write-guard.sh:2`, at spec-branch commit `5fdfb89`.
- `.workflow/GLOSSARY.md`, Agent worktree, _Avoid_: "Task worktree (Phase 1 and integration are not tasks)".
- Review pass 1, `.workflow/specs/006-result-file-guard/artifacts/review/pass-1/review-standards.yaml` RS-1 (triage F3).

## Why not a blocker

Wording only. The deny still names the right absolute path and the right `cd <root> &&` fix, so the agent can recover. CAP-NEW-result-file-write and JRN-002 to JRN-004 are unaffected.

## Suggested scope and size

- Scope: replace "task worktree" with "agent worktree" in those messages and headers, and update any test that matches the message text.
- Size: 1 task in feature-workflow and hooks, about 3 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Triage, review pass 1)
