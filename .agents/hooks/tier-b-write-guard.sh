#!/usr/bin/env bash
# File: Hook (Claude adapter): protect Tier B generated caches.
# Goals:
#   - Deny every Write/Edit under .workflow/cache/, including from the `cache-regeneration` agent, which writes to staging and publishes through publish-cache.sh
#   - Point the writer at the regenerate-caches skill: the agent writes to a staging path and skills/regenerate-caches/scripts/publish-cache.sh stamps and moves it in
# Triggers/inputs: PreToolUse JSON for Write/Edit/NotebookEdit. Rule logic in skills/feature-workflow/scripts/check-write.sh; paths from the payload `cwd` (in a worktree-isolated sub-agent cwd is the worktree, $CLAUDE_PROJECT_DIR the main checkout, verified 2.1.300). No agent identity needed.
# Outputs/handoff: Deny with pointer, or allow (path outside .workflow/cache/).
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh): PreToolUse, matcher "Write|Edit|NotebookEdit" (no MultiEdit tool exists; verified 2.1.300).
# Notes: The hard limit is the deny rule Edit(.workflow/cache/**) in claude-settings.template.json, which also covers Bash redirects and recognized file commands; this hook adds the pointer to regenerate-caches.
# Implementation: thin adapter; body in the sourced helper _guard-common.sh (same folder). Fails closed: a check-write.sh usage/env error denies.

set -euo pipefail

# shellcheck source=_guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_guard-common.sh"
run_guard tier-b 0
