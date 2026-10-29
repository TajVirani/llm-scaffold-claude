---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "3.7"
discovered_at: 2026-10-29
status: open
kind: bug
---

# Scope check lets GNU sed run a command

## Problem

The worktree scope check treats `sed -n` as a read-only command. GNU sed's `e` command runs a shell command, so `sed -n '1e touch x' file` from the main checkout passes as a read without the leading `cd`. BSD sed on macOS rejects `e`, so only GNU sed hosts are exposed.

## Evidence

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:133` and `:140` at T4 head `9e56a79`. The sed write check denies `w`, `W` and `-i` but not `e`.
- T4 mini-review round 1, `.workflow/specs/006-result-file-guard/artifacts/T4/mini-review-r1.yaml` `out_of_scope_noticed`: "sed -n '1e touch x' src/a.ts is allowed with no cd."
- T4 result `considered_not_built`: a regex for `e` would deny most `sed -n` reads.

## Why not a blocker

CAP-NEW-worktree-read-commands lists the sed forms to deny (`w`, `W`, `-i`), and `e` is not among them. JRN-009 is met without it. The check is accident prevention, not a sandbox.

## Suggested scope and size

- Scope: deny a sed script that uses the `e` command (or any sed script that is not a plain address-and-`p` form), with negative cases in `tests/hooks/worktree-guard.sh`. Leave the other allowlisted tools alone.
- Size: 1 task in feature-workflow, 2 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: gnu-sed-exec-command)
