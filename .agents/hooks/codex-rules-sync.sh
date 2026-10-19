#!/usr/bin/env bash
# File: Hook (Codex adapter): keep the import-boundary config in step with docs/rules.md after an `apply_patch` (D9, D15, D20, D40).
# Goals:
#   - Codex edits files through `apply_patch` (patch text in tool_input.command, row 5a), which rules-boundary-config-sync.sh does not read.
#     This adapter finds the patch's paths and, when one of them is a docs/rules.md, hands rules-boundary-config-sync.sh an equivalent
#     Write payload for that path, so the generator call, the project-root checks and the outputs stay in one place.
# Behaviour:
#   - tool_name other than apply_patch, jq missing, unparsable payload or patch: exit 0, no output (a PostToolUse hook cannot undo the write;
#     the patch was already allowed by codex-write-guard.sh, which fails closed on the same parse).
#   - Paths considered: `*** Add File:`, `*** Update File:` and `*** Move to:` (a deleted rules.md has nothing to generate from). The first
#     one whose basename is rules.md under a docs/ folder is passed on; rules-boundary-config-sync.sh then acts only when it is the
#     docs/rules.md of the main checkout or of the cwd's worktree.
#   - Output is rules-boundary-config-sync.sh's: nothing, {"decision":"block","reason":...} (rules.md does not parse; the reason goes back
#     to the model), or {"systemMessage":...} (environment error). Exit code always 0.
# Wiring: codex-hooks.template.json: PostToolUse, matcher "apply_patch".
# Plan refs: 00.3, 3.5; assetlist D9, D15, D20, D40, D67; PLAN/hook-verification-codex.md row 5a.
# Notes: Not verified live on Codex: that PostToolUse {"decision":"block"} feeds the reason back and that systemMessage is shown (the hooks
#   doc says both work). Sign-off 5.3 also runs generate-boundary-config.sh directly, which covers both.
# Sources: first-party; rules-boundary-config-sync.sh; _codex-patch.sh.
# Requires: bash 3.2+, jq, awk; the generator needs mikefarah yq v4 (D38).

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=_codex-patch.sh
source "$here/_codex-patch.sh"

command -v jq >/dev/null 2>&1 || exit 0
payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 || exit 0
[ "$(jq -r '.tool_name // "" | strings' <<<"$payload")" = apply_patch ] || exit 0

tmp=$(mktemp "${TMPDIR:-/tmp}/codex-rules-sync.XXXXXX")
trap 'rm -f "$tmp"' EXIT
codex_patch_text <<<"$payload" >"$tmp" || exit 0
paths=$(codex_patch_paths "$tmp" 2>/dev/null) || exit 0

path=""
while IFS=$'\t' read -r _ op p; do
  [ "$op" != delete ] || continue
  case "$p" in docs/rules.md | */docs/rules.md) path=$p; break ;; esac
done <<<"$paths"
[ -n "$path" ] || exit 0

jq -c --arg p "$path" '{session_id, cwd, hook_event_name, tool_name: "Write", tool_input: {file_path: $p}}' <<<"$payload" \
  | bash "$here/rules-boundary-config-sync.sh"
