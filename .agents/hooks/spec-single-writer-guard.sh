#!/usr/bin/env bash
# File: Hook (Claude adapter): enforce the single-writer rule on spec.md, tasks.md and the per-task bodies under tasks/.
# Goals:
#   - Allow writes to .workflow/specs/*/spec.md only at 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9 or 00.29 (D69); status edits go only through status-transition.sh
#   - Allow writes to .workflow/specs/*/tasks.md and .workflow/specs/*/tasks/** (per-task bodies, D85) only at 2.5 or 0.3.20; later record changes go through status-transition.sh set-task
#   - Deny when the payload carries agent_id: only calls made inside a sub-agent carry agent_id/agent_type, main-session calls carry neither (D16; verified 2.1.300)
#   - Otherwise block and explain
# Triggers/inputs: PreToolUse JSON for Write/Edit/NotebookEdit; path filtered in script. Rule logic in skills/feature-workflow/scripts/check-write.sh (D9), which reads the gitignored step marker .workflow/specs/NNN-slug/.step (D16). Paths from the payload `cwd` (D18).
# Outputs/handoff: Allow, or deny with explanation.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh, D36): PreToolUse, matcher "Write|Edit|NotebookEdit" (no MultiEdit tool exists; verified 2.1.300, PLAN/hook-verification.md).
# Plan refs: 0.1.4, 2.5, 0.3.20; assetlist D9, D16, D45, D85.
# Notes: Accident prevention only: Bash writes bypass this hook. There is no hard limit for spec.md: the main session writes it at approved steps, so no permission deny rule can apply (D16, D36). The .step marker this guard trusts is hard-protected by the deny rule Edit(.workflow/specs/*/.step) (D36).
# Implementation: thin adapter; body in the sourced helper _guard-common.sh (same folder). Fails closed: a check-write.sh usage/env error denies.

set -euo pipefail

# shellcheck source=_guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_guard-common.sh"
run_guard spec 1
