---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "3.7"
discovered_at: 2026-10-29
status: open
kind: decision
---

# One digit rule for spec folder numbers

## Problem

The scripts disagree on how many digits a spec folder number may have. The agent worktree name builder needs three or more, as the folder normaliser does. The launch-header check and the worktree guard before spec 006 accepted any count. So a Phase 3 task in a folder such as `12-foo` was confined before 006 and now gets no worktree name. After T1's fix round the guard denies such a launch with the lib's reason.

## Evidence

- `.agents/lib/workflow-paths.sh:135` (`${#spec_number} -lt 3` in `wf_agent_worktree_name`, commit `4b66751`).
- `git show 4b66751:.agents/hooks/worktree-write-guard.sh:87-88`: the pre-change guard's `^[0-9]+$` test.
- T1 mini-review round 2, `.workflow/specs/006-result-file-guard/artifacts/T1/mini-review-r2.yaml` `out_of_scope_noticed`: "wf_agent_worktree_name needs three or more digits in the spec folder number, as wf_norm_folder does, while resolve-launch and the pre-change guard accepted any digit count."

## Why not a blocker

Every spec folder in this repo and every folder the workflow creates has three digits, so no current spec hits it. CAP-NEW-result-file-write and JRN-001 to JRN-005 use three-digit folders and are unaffected.

## Suggested scope and size

- Scope: decide one rule (three or more digits everywhere, or any digits everywhere), then apply it in `resolve-launch.sh --parse-header` and the lib so a malformed folder is refused at launch, not at the first write. Leave name formats unchanged.
- Size: 1 to 2 tasks in feature-workflow and lib, about 3 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: spec-folder-digit-rule)
