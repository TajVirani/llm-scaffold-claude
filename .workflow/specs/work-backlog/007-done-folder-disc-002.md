---
origin_spec: .workflow/specs/007-done-folder
origin_step: "4.4"
discovered_at: 2026-10-30
status: open
kind: bug
---

# Integration commits follow the commit subject rule

## Problem

The integration agent's definition tells it to commit one message per applied request, naming the request number. It never states that commit subjects are Conventional Commits, which the project's commit rule requires and the implementation agent's definition does state. So integration commits follow the rule only by chance: the shared-core batch in spec 007 produced two that do not.

## Evidence

- `.agents/agents/integration.md:71` ("Commit in your worktree, one commit per applied request where practical, each message naming the request number.") vs `.agents/agents/implementation.md:81` ("Commit subjects are Conventional Commits ... never a bare task id"), as of commit `b8150ec`.
- Commits `efd0c38` and `131f786` on `spec/007-done-folder` (integration batch `integration-shell-scripts`): subjects without a type prefix. Reported by review-standards, pass 1 (RS-1, RS-2).
- Also seen: .workflow/specs/007-done-folder, 4.4: implementation commit `5874348` uses the type `perf`, outside the six types the commit rule allows (review-standards pass 3, RS-1); review-lessons pass 3 (RL-1) matched the integration commits to the retrospective 004 lesson on Conventional Commits subjects.

## Why not a blocker

CAP-NEW-done-folder and JRN-001 to JRN-007 do not depend on commit subjects; the two commits are already merged on the spec branch, and the gap affects only future integration batches.

## Suggested scope and size

- Scope: state the Conventional Commits subject rule in the integration agent's definition (and its generated Codex toml), the same way the implementation definition does; optionally a lint that checks agent definitions name it. Leaves past commits as they are.
- Size: one task in the agents module, 1-3 files; well within the 10-task, 30-file budget.

## Links

- Origin spec: [spec.md](../007-done-folder/spec.md)
- Design log entry: [design-log.md](../007-done-folder/design-log.md) (section 2026-10-30 Triage, review pass 1)
