---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "4.4"
discovered_at: 2026-10-29
status: promoted
promoted_to: .workflow/specs/00010-worktree-guard-followups
kind: bug
---

# Read-only yq allow entry also permits in-place edits

## Problem

The shipped Claude settings allow `Bash(yq --front-matter=extract:*)` without a prompt. That prefix also matches `yq --front-matter=extract -i ...`, an in-place frontmatter rewrite. A recorded pitfall says this exact call once dropped a backlog item's body, and its "Prevented by" is still "none yet".

## Evidence

- `.agents/hooks/claude-settings.template.json:130` and `.claude/settings.json:141`, unchanged since baseline `e049f4d`.
- Review pass 1, `.workflow/specs/006-result-file-guard/artifacts/review/pass-1/review-lessons.yaml` RL-1 (triage F5).

## Why not a blocker

Pre-existing, and outside every hunk of spec 006. Narrowing the allow list changes what installed settings permit, which needs its own ruling. CAP-NEW-result-file-write and CAP-NEW-worktree-read-commands are unaffected.

## Suggested scope and size

- Scope: narrow the allow entry so an in-place `-i` write prompts (or deny `yq ... -i` on workflow files), in the template and this repo's settings, with an install test. Record it as the pitfall's prevention.
- Size: 1 task in hooks, 2 to 3 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Triage, review pass 1)
