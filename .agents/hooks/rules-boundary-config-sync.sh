#!/usr/bin/env bash
# File: Hook (Claude adapter): keep the import-boundary config in step with .workflow/rules.md.
# Goals:
#   - Re-run skills/project-setup/scripts/generate-boundary-config.sh, which emits per-language config under .workflow/tools/boundaries/
#   - Fail if the fenced yaml ownership/shared-core blocks do not parse
# Triggers/inputs: PostToolUse JSON for Write/Edit/NotebookEdit (tool_input.file_path, or notebook_path for NotebookEdit). Paths from the payload
#   `cwd`. Acts only when the written file is .workflow/rules.md of the main checkout (git rev-parse --git-common-dir) or of the checkout the
#   cwd is in (a worktree); the generator then runs for that project root, so the config lands next to the rules.md that changed.
# Codex equivalent: codex-rules-sync.sh (PostToolUse `apply_patch` adapter for the same regeneration).
# Behaviour:
#   - Other tools or paths, or no .agents/skills/project-setup/scripts/generate-boundary-config.sh in the main checkout: exit 0, no output.
#   - Generator exit 0 (config written or already current): exit 0, no output.
#   - Exit 2 (rules.md does not parse or validate): {"decision":"block","reason":...}. The write has already happened; PostToolUse "block"
#     hands the reason to Claude so it fixes .workflow/rules.md (and .workflow/tools/boundaries/ stays at the last good render).
#   - Exit 3 (yq v4 or jq missing) or any other failure: {"systemMessage":...} warning for the user; Claude cannot fix the environment.
# Outputs/handoff: stdout is nothing, the block JSON, or the systemMessage JSON; exit code always 0. Regenerated .workflow/tools/boundaries/ config.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh): PostToolUse, matcher "Write|Edit|NotebookEdit" (no MultiEdit tool exists; verified 2.1.300).
# Notes: Codex: codex-rules-sync.sh hands this script an equivalent payload after an apply_patch to rules.md; sign-off (5.3) also calls the generator directly. A Bash write to rules.md does not fire this hook
#   (verified 2.1.300); the boundary key's --check run or a later rules.md edit catches the drift.
# Sources: first-party; hooks reference https://code.claude.com/docs/en/hooks (PostToolUse decision "block" + reason, systemMessage).
# Requires: bash, jq, git (optional); the generator needs mikefarah yq v4.

set -euo pipefail

# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"

command -v jq >/dev/null 2>&1 || exit 0
payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 || exit 0

case "$(jq -r '.tool_name // "" | strings' <<<"$payload")" in Write|Edit|NotebookEdit) ;; *) exit 0 ;; esac
path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // "" | strings' <<<"$payload")
[ -n "$path" ] || exit 0
case "$path" in "$WF_RULES" | */"$WF_RULES") ;; *) exit 0 ;; esac

cwd=$(jq -r '.cwd // "" | strings' <<<"$payload")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
cwd=$(cd "$cwd" && pwd -P)
case "$path" in /*) ;; *) path=$cwd/$path ;; esac
[ -d "$(dirname "$path")" ] || exit 0
path=$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")

main_root=$cwd top=$cwd
if common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  main_root=$(cd "$(dirname "$common")" && pwd -P)
  top=$(cd "$(git -C "$cwd" rev-parse --show-toplevel)" && pwd -P)
fi

project=""
for root in "$main_root" "$top"; do
  if [ "$path" = "$root/$WF_RULES" ]; then project=$root; break; fi
done
[ -n "$project" ] || exit 0

generator=$main_root/.agents/skills/project-setup/scripts/generate-boundary-config.sh
[ -f "$generator" ] || exit 0

rc=0
err=$(bash "$generator" "$project" 2>&1 >/dev/null) || rc=$?
case "$rc" in
  0) exit 0 ;;
  2)
    jq -cn --arg e "$err" --arg r "$WF_RULES" --arg b "$WF_BOUNDARIES" '{decision: "block", reason: ($r + " was written, but its boundary rules do not parse, so " + $b + "/ was not regenerated:\n" + $e + "\nFix the fenced yaml blocks under the \"## Ownership\" and \"## Shared core\" headings of " + $r + ", then save it again.")}'
    ;;
  *)
    jq -cn --arg e "$err" --arg b "$WF_BOUNDARIES" --argjson rc "$rc" '{systemMessage: ("rules-boundary-config-sync: generate-boundary-config.sh failed (exit \($rc)); " + $b + "/ may be stale: " + $e)}'
    ;;
esac
exit 0
