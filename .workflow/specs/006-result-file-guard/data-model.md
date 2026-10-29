# Data model: Sub-agents can write their own result file

Spec: [spec.md](spec.md) · Placement: lib, feature-workflow, hooks, agents (design-log 2026-10-29 Questioning round 3, D9; Placement check re-run)

## Summary

No persisted data or schema changes. The parts are script interfaces, hook wiring, orchestrator steps and agent briefs.

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| `.agents/lib/workflow-paths.sh`: `wf_` encoder (`LC_ALL=C`, lowercase, every byte outside `[a-z0-9]` → `_`) and **Agent worktree** name builder (`s<NNN>_t<N>`, `s<NNN>_phase_1_<enc>`, `s<NNN>_integration_<enc>`) | interface | create | lib |
| `WF_WORKTREES`, `wf_main_root`, `wf_norm_folder` | interface | unchanged | lib |
| `codex_enc` in `codex-pre-spawn.sh` (worktree segments and agent-type names) | interface | refactor (calls the lib encoder) | hooks |
| `post-implementation-audit.sh`: `codex_enc` copy; Claude worktree lookup for Phase 1 and integration; `agent_type` filter widened to `integration` | interface | refactor / extend | hooks |
| `worktree-write-guard.sh`: `--worktree-name` derived for Phase 1 and integration headers | interface | extend | hooks |
| `claude-settings.template.json` SubagentStop matcher (`implementation` → implementation and integration) and its `.md` | interface | extend | hooks |
| This repo's `.claude/settings.json` SubagentStop matcher (hand-kept in step with the template) | field | extend | (repo config) |
| `codex-write-guard.sh` | interface | unchanged | hooks |
| `check-worktree-scope.sh` command rule: read-only allowlist with per-tool flag and shell-form denylists | interface | extend | feature-workflow |
| `check-worktree-scope.sh` path rule, exit codes 0/2/1, CLI | interface | unchanged | feature-workflow |
| New artifacts merge-gate script (input: spec dir and a branch or commit; diff from the merge-base with the spec branch; refuses any add/modify/delete under `<spec_dir>/artifacts/`) | interface | create | feature-workflow |
| `verification-setup.md` 1.2/1.3 Claude launch, worktree lifecycle and merge | interface | extend | feature-workflow |
| `implementation-orchestrator.md` launch table (integration), isolation fallback (removed), 3.2 and 3.16 gate calls, integration worktree on Claude | interface | refactor | feature-workflow |
| `check-task-result.sh`, `resolve-launch.sh` | interface | unchanged | feature-workflow |
| `implementation.md`, `integration.md` result-file write step (absolute main-checkout path, agent worktree) | interface | extend | agents |
| `profile-mini-review.md` | interface | unchanged | agents |
| Result file shapes (`implementation.yaml`, `integration.yaml`, `mini-review.yaml`) | entity | unchanged | feature-workflow |

## Entities

### Agent worktree (create, for Phase 1 and integration on Claude)

The git worktree the orchestrator creates for one coding launch; the worktree guard confines the agent to it.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| name | string | yes | `s<NNN>_t<N>` \| `s<NNN>_phase_1_<enc(work_type)>` \| `s<NNN>_integration_<enc(work_type)>`; `[a-z0-9_]` only; byte-identical to the Codex `task_name` (CAP-NEW-result-file-write) | extend (two forms new on Claude) |
| path | string | yes | `<main checkout>/.workflow/.worktrees/<name>` | unchanged |
| branch | string | yes | Phase 3: `task/NNN-slug/Tnn-<slug>`; Phase 1 and integration: `wf/NNN-slug/<name>`, forked from the spec-branch tip (D14) | extend |

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| absent | launch (1.2, 1.3, 3.2) | created | spec branch checked out in the main checkout; 1.3 only after the 1.2 merge |
| created | relaunch or fix round | created (reused) | worktree exists |
| created | merge passes the artifacts gate | removed (worktree and branch) | gate exit 0 |
| created | gate refuses | created | fix round tells the agent to drop the `artifacts/` change |

**Invalid states ruled out:** an agent writing a result file is never isolation-launched (the fallback is removed). Still representable: a worktree left behind after an aborted session; cleanup on resume follows the existing reuse rule.

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | SubagentStop matcher widened to integration in the Claude settings template; target projects pick it up on the next `install.sh` run, this repo by hand | extend | yes (restore the matcher) | - | none; the upgrade must not leave a duplicate SubagentStop entry |
