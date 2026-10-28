---
origin_spec: .workflow/specs/005-cache-build-followups
origin_step: "3.2"
discovered_at: 2026-10-28
status: open
kind: bug
---

# Worktree guard blocks a sub-agent's own result file

## Problem

An integration or implementation sub-agent must write its result file (`integration.yaml`, `implementation.yaml`) under the spec's `artifacts/` in the main checkout, but the worktree write guard confines it to its worktree and denies that write. The agent finishes its work but cannot file its result, so the orchestrator has nothing to check without retyping the agent's block.

## Evidence

- Integration batch `integration-shell-scripts`, spec 005 step 3.2, agent report quoted: "Both the Write tool and Bash refused `.../.workflow/specs/005-cache-build-followups/artifacts/integration-shell-scripts/integration.yaml` because it is outside the worktree."
- `.agents/hooks/worktree-write-guard.sh:15-16` confines an isolation-launch agent to its linked worktree; `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` has no exception for `.workflow/specs/<spec>/artifacts/<id>/` (grep for `artifacts` finds nothing).
- `run-toolchain.sh` evidence in the same folder was written (it runs outside the guard), so only the agent's own Write/Edit/Bash writes are blocked.

## Why not a blocker

Spec 005's capabilities (CAP-004, CAP-005) and journeys JRN-001 to JRN-008 do not depend on the guard. Workaround agreed by the stakeholder at 3.2: each agent writes its result file at the same relative path inside its worktree, the main session copies it to the main checkout and runs `check-task-result.sh` on it.

## Suggested scope and size

- Scope: let `check-worktree-scope.sh` admit a write to `<main checkout>/.workflow/specs/<spec>/artifacts/<own task id or integration-<work_type>>/` for the agent's own result files, with suite cases in `tests/hooks/` for allow and deny; leave the rest of the confinement as is.
- Size: 1 task, 1 module (feature-workflow, plus a hook suite); well within 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../005-cache-build-followups/spec.md)
- Design log entry: [design-log.md](../005-cache-build-followups/design-log.md) (section 2026-10-28 Discovered work: result-file guard)
