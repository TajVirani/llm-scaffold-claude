#!/usr/bin/env bash
# File: Hook (Codex adapter): the three write guards (spec-single-writer, Tier A, Tier B) for Codex's `apply_patch` tool.
# Goals:
#   - Codex sends a file edit as `apply_patch` with the patch text in tool_input.command, not a file_path (verified 0.155.1, row 5a), so the
#     Claude guards (_guard-common.sh) would see no path and allow. This adapter splits the patch into its paths and runs, for each path,
#     skills/feature-workflow/scripts/check-write.sh with --only spec, --only tier-a and --only tier-b: the same rules the three Claude
#     guards apply (D9, D16, D17, D21).
#   - Deny the whole patch when any path is denied. Codex applies a PreToolUse deny, and deny wins over an allow from another hook (row 5b).
# Behaviour:
#   - tool_name other than apply_patch: exit 0, no output. No skills/feature-workflow next to this hooks folder: exit 0 (workflow not installed).
#   - Paths: `*** Add File:`, `*** Update File:`, `*** Delete File:` and `*** Move to:` (parsed by the sourced _codex-patch.sh). Each is checked
#     as given; relative paths resolve against the payload `cwd` (Codex has no project-dir variable, row 8).
#   - --agent = agent_type (else agent_id) only when the payload carries agent_id: Codex adds agent_id/agent_type only inside a sub-agent (row 5a, D16).
#   - specs/*/spec.md (status and blocked_condition change only through status-transition.sh):
#       Add File: the `+` lines are the proposed content, passed as check-write.sh --proposed (a new spec.md must say status: draft).
#       Update File: the hunks are not applied. Instead the `-` and `+` lines of top-level `status:` / `blocked_condition:` keys are compared;
#       any difference denies. Conservative: a body line that starts with `status:` and is edited also denies.
#   - check-write.sh exit 0 for every path and class: allow (no output). Exit 2: deny with every denied path's reason. Any other exit, an
#     unparsable payload, a missing or unparsable patch: deny, fail closed.
#   - jq missing, or any failure before a decision: a static, hand-written deny JSON and exit 0 (as _guard-common.sh does).
# Outputs/handoff: stdout is nothing or exactly one deny JSON (same shape as Claude's; verified on Codex, row 5b):
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}. Exit code always 0.
# Wiring: codex-hooks.template.json (written to <target>/.codex/hooks.json by install.sh): PreToolUse, matcher "apply_patch".
# Plan refs: assetlist D9, D16, D17, D21, D40, D67; PLAN/hook-verification-codex.md rows 5a, 5b, 8.
# Notes: Accident prevention only, as on Claude. Shell writes do not reach this hook; the hard limit for docs/cache is the permissions profile in
#   codex-config.template.toml (rows 7a, 7b). specs/*/.step has no Codex hard limit (G7), so this guard is its only file-tool protection.
# Sources: first-party; check-write.sh CLI; _guard-common.sh (fail-closed pattern); PLAN/hook-verification-codex/hooks/pre_edit_deny.sh (deny shape).
# Requires: bash 3.2+, jq, awk; check-write.sh needs mikefarah yq v4 for Tier A and --proposed (D38).

set -euo pipefail

DECIDED=0
TMP=""

deny_static_nojq() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"codex write guard error (denying, fail closed): jq not found; install jq to write files in this project"}}'
}
deny_static_error() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"codex write guard error (denying, fail closed): the guard failed before reaching a decision"}}'
}
deny_json() {
  DECIDED=1
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' 2>/dev/null \
    || deny_static_error
  exit 0
}
# shellcheck disable=SC2329 # invoked by the EXIT trap
on_exit() {
  local rc=$?
  [ -z "$TMP" ] || rm -rf "$TMP"
  if [ "$rc" -ne 0 ] && [ "$DECIDED" -eq 0 ]; then
    DECIDED=1
    deny_static_error
    exit 0
  fi
}
trap on_exit EXIT

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script=$here/../skills/feature-workflow/scripts/check-write.sh
[ -f "$script" ] || exit 0
# shellcheck source=_codex-patch.sh
source "$here/_codex-patch.sh"

input=$(cat)
if ! command -v jq >/dev/null 2>&1; then
  DECIDED=1
  deny_static_nojq
  exit 0
fi
jq -e 'type == "object"' <<<"$input" >/dev/null 2>&1 || deny_json "codex write guard: unparsable hook payload; denying (fail closed)"
[ "$(jq -r '.tool_name // "" | strings' <<<"$input")" = apply_patch ] || exit 0

cwd=$(jq -r '.cwd // "" | strings' <<<"$input")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=$PWD
agent_id=$(jq -r '.agent_id // "" | strings' <<<"$input")
agent_type=$(jq -r '.agent_type // "" | strings' <<<"$input")

TMP=$(mktemp -d "${TMPDIR:-/tmp}/codex-write-guard.XXXXXX")
codex_patch_text <<<"$input" >"$TMP/patch" \
  || deny_json "codex write guard: apply_patch payload has no patch text in tool_input.command; denying (fail closed)"
codex_patch_paths "$TMP/patch" >"$TMP/paths" 2>"$TMP/perr" \
  || deny_json "codex write guard: $(tr '\n' ' ' <"$TMP/perr" | sed 's/ *$//'); denying (fail closed)"

is_spec_md() {
  local l
  l=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$l" in */specs/work-backlog/* | specs/work-backlog/*) return 1 ;; esac
  printf '%s' "$l" | grep -Eq '(^|/)specs/[^/]+/spec\.md$'
}

# status_keys <sign> : the top-level status/blocked_condition lines of one sign (- or +) in $TMP/body, sorted.
status_keys() {
  sed -nE "s/^[$1](status|blocked_condition)[[:space:]]*:/\\1:/p" "$TMP/body" | sed 's/[[:space:]]*$//' | LC_ALL=C sort
}

reasons=()
while IFS=$'\t' read -r idx op path; do
  [ -n "$path" ] || continue
  proposed=""
  if is_spec_md "$path"; then
    codex_patch_body "$TMP/patch" "$idx" >"$TMP/body"
    if [ "$op" = add ]; then
      sed -n 's/^+//p' "$TMP/body" >"$TMP/proposed.$idx"
      proposed=$TMP/proposed.$idx
    elif [ "$op" = update ] && [ "$(status_keys -)" != "$(status_keys +)" ]; then
      reasons+=("$path: the patch changes status or blocked_condition; only status-transition.sh may change them (use status-transition.sh, then patch the rest)")
      continue
    fi
  fi
  for only in spec tier-a tier-b; do
    args=(--cwd "$cwd" --path "$path" --only "$only")
    [ -z "$agent_id" ] || args+=(--agent "${agent_type:-$agent_id}")
    [ -z "$proposed" ] || [ "$only" != spec ] || args+=(--proposed "$proposed")
    rc=0
    "$script" "${args[@]}" >/dev/null 2>"$TMP/err" || rc=$?
    [ "$rc" -ne 0 ] || continue
    reason=$(tr '\n' ' ' <"$TMP/err" | sed 's/ *$//')
    [ -n "$reason" ] || reason="check-write.sh exited $rc"
    [ "$rc" -eq 2 ] || reason="write guard error (denying, fail closed): $reason"
    reasons+=("$path: $reason")
    break
  done
done <"$TMP/paths"

[ "${#reasons[@]}" -eq 0 ] && exit 0
joined=$(printf '%s; ' "${reasons[@]}")
deny_json "apply_patch denied: ${joined%; }"
