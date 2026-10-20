#!/usr/bin/env bash
# File: Hook (Claude adapter): protect Tier A authored context.
# Goals:
#   - Guard .workflow/GLOSSARY.md, .workflow/capabilities.md, .workflow/rules.md, .workflow/decisions/, .workflow/profiles/
#   - Allow only at the step marker's gates (D51): .workflow/GLOSSARY.md at 0.2.3, 0.3.15, 0.4.3 or 5.3; other Tier A (capabilities.md, rules.md, decisions/) at 0.3.7, 5.3 or 5.7; .workflow/profiles/ created at 00.19 or 5.3, edited only at 5.3; deny when the payload carries agent_id, which only sub-agent calls carry (D16; verified 2.1.300)
#   - Redirect anything else to a 5.2 proposal in .workflow/specs/NNN-slug/proposals.md (D21)
# Triggers/inputs: PreToolUse JSON for Write/Edit/NotebookEdit. Rule logic in skills/feature-workflow/scripts/check-write.sh (D9), which reads .workflow/specs/NNN-slug/.step (D16). Paths from the payload `cwd` (D18).
# Outputs/handoff: Allow, or deny.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh, D36): PreToolUse, matcher "Write|Edit|NotebookEdit" (no MultiEdit tool exists; verified 2.1.300, PLAN/hook-verification.md).
# Plan refs: Tier A (00.1-00.4, 00.17); assetlist D9, D16, D21.
# Notes: Accident prevention only: Bash writes bypass this hook. There is no hard limit for Tier A: the main session writes it at approved steps, so no permission deny rule can apply (D16, D36). The .step marker this guard trusts is hard-protected by the deny rule Edit(.workflow/specs/*/.step) (D36).
# Implementation: thin adapter; body in the sourced helper _guard-common.sh (same folder). Fails closed: a check-write.sh usage/env error denies.

set -euo pipefail

# shellcheck source=_guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_guard-common.sh"
run_guard tier-a 0
