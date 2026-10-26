---
generated_at_commit: e530f63f7103b9286d32d21f6b9f75055ef8c5d8
generated_at: "2026-10-26T15:23:01Z"
scope:
  - ".agents/README.md"
  - ".agents/agents"
  - ".agents/hooks"
  - ".agents/install-manifest.txt"
  - ".agents/lib"
  - ".agents/output-styles"
  - ".agents/skills/data-structure-audit"
  - ".agents/skills/deeper-prompt"
  - ".agents/skills/deps-audit"
  - ".agents/skills/deps-update"
  - ".agents/skills/design-pattern-doc"
  - ".agents/skills/domain-modeling"
  - ".agents/skills/feature-workflow"
  - ".agents/skills/glab"
  - ".agents/skills/handoff"
  - ".agents/skills/pr-quality"
  - ".agents/skills/pr-review-data"
  - ".agents/skills/project-setup"
  - ".agents/skills/project-standards"
  - ".agents/skills/regenerate-caches"
  - ".agents/skills/retrospective"
  - ".agents/skills/visual-change-report"
  - ".agents/skills/writing-for-agents"
  - "AGENTS.md"
  - "README.md"
  - "install.sh"
  - "scripts"
  - "tests"
cache_type: modules
generator: "cache-regeneration"
---
# Modules

## .agents/hooks

- Purpose: Checks Claude and Codex tool calls and sub-agent launches against the workflow rules, denying disallowed writes, destructive git commands and malformed launches, and runs the boundary-config sync, toolchain audit, evidence capture and resume offer around them.
- Files:
  - `.agents/hooks/_codex-patch.sh`
  - `.agents/hooks/_guard-common.sh`
  - `.agents/hooks/block-destructive-git.sh`
  - `.agents/hooks/codex-pre-spawn.sh`
  - `.agents/hooks/codex-rules-sync.sh`
  - `.agents/hooks/codex-write-guard.sh`
  - `.agents/hooks/evidence-capture.sh`
  - `.agents/hooks/generate-codex-agents.sh`
  - `.agents/hooks/post-implementation-audit.sh`
  - `.agents/hooks/pre-launch.sh`
  - `.agents/hooks/rules-boundary-config-sync.sh`
  - `.agents/hooks/session-start-resume.sh`
  - `.agents/hooks/spec-single-writer-guard.sh`
  - `.agents/hooks/tier-a-write-guard.sh`
  - `.agents/hooks/tier-b-write-guard.sh`
  - `.agents/hooks/worktree-write-guard.sh`
- Depends on:
  - `.agents/lib`
  - `.agents/skills/feature-workflow`
  - `.agents/skills/project-setup`
- Used by:
  - `install.sh`
  - `tests`
- Public interface:
  - `codex_patch_body` (function)
  - `codex_patch_paths` (function)
  - `codex_patch_text` (function)
  - `deny_json` (function)
  - `deny_static_error` (function)
  - `deny_static_nojq` (function)
  - `guard_on_exit` (function)
  - `run_guard` (function)

## .agents/lib

- Purpose: Defines the paths of workflow data under one workflow folder for hooks and skill scripts to source.
- Files:
  - `.agents/lib/workflow-paths.sh`
- Depends on: none
- Used by:
  - `.agents/hooks`
  - `.agents/skills/data-structure-audit`
  - `.agents/skills/feature-workflow`
  - `.agents/skills/project-setup`
  - `.agents/skills/regenerate-caches`
  - `install.sh`
  - `tests`
- Public interface:
  - `wf_path` (function)

## .agents/skills/data-structure-audit

- Purpose: Prints the files changed since the last audited commits and records the current commit as audited.
- Files:
  - `.agents/skills/data-structure-audit/scripts/audit_scope.sh`
- Depends on:
  - `.agents/lib`
- Used by: none
- Public interface: Not generated: no tsconfig.json.

## .agents/skills/feature-workflow

- Purpose: Checks, writes and reports the state of specs, tasks, initiatives, launches and writes for the workflow orchestrator.
- Files:
  - `.agents/skills/feature-workflow/scripts/budget-check.sh`
  - `.agents/skills/feature-workflow/scripts/check-review-findings.sh`
  - `.agents/skills/feature-workflow/scripts/check-task-result.sh`
  - `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`
  - `.agents/skills/feature-workflow/scripts/check-write.sh`
  - `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh`
  - `.agents/skills/feature-workflow/scripts/initiative-transition.sh`
  - `.agents/skills/feature-workflow/scripts/open-task-pr.sh`
  - `.agents/skills/feature-workflow/scripts/resolve-launch.sh`
  - `.agents/skills/feature-workflow/scripts/review-lessons.sh`
  - `.agents/skills/feature-workflow/scripts/rules-setting.sh`
  - `.agents/skills/feature-workflow/scripts/run-toolchain.sh`
  - `.agents/skills/feature-workflow/scripts/status-transition.sh`
  - `.agents/skills/feature-workflow/scripts/step-progress.sh`
  - `.agents/skills/feature-workflow/scripts/task-waves.sh`
- Depends on:
  - `.agents/lib`
- Used by:
  - `.agents/hooks`
  - `tests`
- Public interface: Not generated: no tsconfig.json.

## .agents/skills/project-setup

- Purpose: Generates import-boundary tool config from the Ownership and Shared core blocks of `.workflow/rules.md`.
- Files:
  - `.agents/skills/project-setup/scripts/generate-boundary-config.sh`
- Depends on:
  - `.agents/lib`
- Used by:
  - `.agents/hooks`
  - `.agents/skills/regenerate-caches`
- Public interface: Not generated: no tsconfig.json.

## .agents/skills/regenerate-caches

- Purpose: Builds, checks, stamps and publishes the Tier B caches from the file graphs its extractors print.
- Files:
  - `.agents/skills/regenerate-caches/scripts/build-architecture.sh`
  - `.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh`
  - `.agents/skills/regenerate-caches/scripts/check-staged-cache.sh`
  - `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`
  - `.agents/skills/regenerate-caches/scripts/extractors/dependency-cruiser.sh`
  - `.agents/skills/regenerate-caches/scripts/publish-cache.sh`
- Depends on:
  - `.agents/lib`
  - `.agents/skills/project-setup`
- Used by: none
- Public interface: Not generated: no tsconfig.json.

## install.sh

- Purpose: Installs the `.agents/` payload and the Claude and Codex host shims into a target project.
- Files:
  - `install.sh`
- Depends on:
  - `.agents/hooks`
  - `.agents/lib`
- Used by:
  - `tests`
- Public interface: Not generated: no tsconfig.json.

## scripts

- Purpose: Shows what changed upstream since the commit each `upstream-lineage.json` entry is based on.
- Files:
  - `scripts/upstream-diff.sh`
- Depends on: none
- Used by:
  - `tests`
- Public interface: Not generated: no tsconfig.json.

## tests

- Purpose: Runs the test suites for the scaffold's hooks, scripts, installer and lint checks and prints a summary.
- Files:
  - `tests/fixtures/graph-extractors.sh`
  - `tests/fixtures/initiative.sh`
  - `tests/fixtures/review-lessons.sh`
  - `tests/hooks/audit-sync-resume.sh`
  - `tests/hooks/block-destructive-git.sh`
  - `tests/hooks/codex-adapters.sh`
  - `tests/hooks/codex-pre-spawn-initiative.sh`
  - `tests/hooks/codex-shim.sh`
  - `tests/hooks/evidence-capture.sh`
  - `tests/hooks/initiative-write-guards.sh`
  - `tests/hooks/pre-launch.sh`
  - `tests/hooks/session-start-initiatives.sh`
  - `tests/hooks/worktree-guard.sh`
  - `tests/hooks/write-guards.sh`
  - `tests/lib/common.sh`
  - `tests/lint/frontmatter.sh`
  - `tests/lint/review-lessons.sh`
  - `tests/lint/step-list.sh`
  - `tests/lint/symlinks.sh`
  - `tests/lint/upstream-lineage.sh`
  - `tests/run-all.sh`
  - `tests/scripts/budget-check.sh`
  - `tests/scripts/build-architecture.sh`
  - `tests/scripts/cache-bash-project.sh`
  - `tests/scripts/cache-boundary-check.sh`
  - `tests/scripts/cache-js-unchanged.sh`
  - `tests/scripts/cache-missing-extractor-key.sh`
  - `tests/scripts/cache-mixed-extractors.sh`
  - `tests/scripts/cache-scripts.sh`
  - `tests/scripts/check-review-findings.sh`
  - `tests/scripts/check-task-result.sh`
  - `tests/scripts/check-write-paths.sh`
  - `tests/scripts/check-write-tier-a.sh`
  - `tests/scripts/commit-workflow-data.sh`
  - `tests/scripts/extractor-bash.sh`
  - `tests/scripts/generate-boundary-config.sh`
  - `tests/scripts/generate-codex-agents.sh`
  - `tests/scripts/graph-extractor-selection.sh`
  - `tests/scripts/initiative-conversion.sh`
  - `tests/scripts/initiative-emission.sh`
  - `tests/scripts/initiative-merge.sh`
  - `tests/scripts/initiative-transition.sh`
  - `tests/scripts/install-claude-settings.sh`
  - `tests/scripts/install-codex-config.sh`
  - `tests/scripts/install-codex-tui.sh`
  - `tests/scripts/install-hosts.sh`
  - `tests/scripts/install-payload.sh`
  - `tests/scripts/install-upgrade.sh`
  - `tests/scripts/resolve-launch-initiative.sh`
  - `tests/scripts/resolve-launch.sh`
  - `tests/scripts/review-lessons.sh`
  - `tests/scripts/run-all-selection.sh`
  - `tests/scripts/run-toolchain.sh`
  - `tests/scripts/status-transition-specs.sh`
  - `tests/scripts/status-transition-tasks.sh`
  - `tests/scripts/step-progress.sh`
  - `tests/scripts/task-breakdown.sh`
  - `tests/scripts/upstream-diff.sh`
- Depends on:
  - `.agents/hooks`
  - `.agents/lib`
  - `.agents/skills/feature-workflow`
  - `install.sh`
  - `scripts`
- Used by: none
- Public interface:
  - `check` (function)
  - `copy_agents` (function)
  - `eq` (function)
  - `finish` (function)
  - `git_commit_all` (function)
  - `git_init_repo` (function)
  - `have_shellcheck` (function)
  - `ko` (function)
  - `make_fixture_repo` (function)
  - `new_workdir` (function)
  - `ok` (function)
  - `preflight` (function)
  - `shellcheck_files` (function)
  - `skip` (function)
  - `t` (function)
  - `xfail` (function)
