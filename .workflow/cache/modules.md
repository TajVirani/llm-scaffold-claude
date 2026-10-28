---
generated_at_commit: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
generated_at: "2026-10-28T20:06:35Z"
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

- Purpose: Runs as Claude and Codex hooks that guard file writes, block destructive git commands, validate sub-agent launches, capture evidence and offer to resume in-flight work, plus a generator for Codex agent files.
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

- Purpose: Defines where workflow data lives in a target project and which repo paths count as tests, as sourced shell helpers.
- Files:
  - `.agents/lib/test-paths.sh`
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
  - `wf_default_test_patterns` (function)
  - `wf_is_test_path` (function)
  - `wf_load_test_patterns` (function)
  - `wf_main_root` (function)
  - `wf_norm_folder` (function)
  - `wf_path` (function)
  - `wf_profile_test_patterns` (function)
  - `wf_toolchain_block` (function)

## .agents/skills/data-structure-audit

- Purpose: Prints the files changed since the last audited commits and records the current HEAD as audited.
- Files:
  - `.agents/skills/data-structure-audit/scripts/audit_scope.sh`
- Depends on:
  - `.agents/lib`
- Used by: none
- Public interface: Not generated: no tsconfig.json.

## .agents/skills/feature-workflow

- Purpose: Provides the feature-workflow helper scripts that check writes, launches, results, findings and size budgets, write status and step markers, run toolchains, derive task waves, open PRs and commit workflow data.
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

- Purpose: Generates import-boundary tool config from the Ownership and Shared core blocks of .workflow/rules.md.
- Files:
  - `.agents/skills/project-setup/scripts/generate-boundary-config.sh`
- Depends on:
  - `.agents/lib`
- Used by:
  - `.agents/hooks`
  - `.agents/skills/regenerate-caches`
- Public interface: Not generated: no tsconfig.json.

## .agents/skills/regenerate-caches

- Purpose: Builds, checks, stamps and publishes the Tier B caches from the file graph that its graph extractors print.
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
- Used by:
  - `tests`
- Public interface: Not generated: no tsconfig.json.

## install.sh

- Purpose: Installs the .agents/ payload named by .agents/install-manifest.txt and the host shims into a target project.
- Files:
  - `install.sh`
- Depends on:
  - `.agents/hooks`
  - `.agents/lib`
- Used by:
  - `tests`
- Public interface: Not generated: no tsconfig.json.

## scripts

- Purpose: Shows what changed upstream for each upstream-lineage.json entry since the commit the local file was based on.
- Files:
  - `scripts/upstream-diff.sh`
- Depends on: none
- Used by:
  - `tests`
- Public interface: Not generated: no tsconfig.json.

## tests

- Purpose: Runs the scaffold's test suites for scripts, hooks and lint with shared test helpers and fixtures.
- Files:
  - `tests/fixtures/architecture-oracle.sh`
  - `tests/fixtures/graph-extractors.sh`
  - `tests/fixtures/initiative.sh`
  - `tests/fixtures/review-lessons.sh`
  - `tests/fixtures/workflow-folders.sh`
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
  - `tests/scripts/cache-repo-architecture.sh`
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
  - `tests/scripts/lib-test-paths.sh`
  - `tests/scripts/lib-workflow-paths.sh`
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
  - `.agents/skills/regenerate-caches`
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
