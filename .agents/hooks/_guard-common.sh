#!/usr/bin/env bash
# File: Sourced helper (not a hook) shared by spec-single-writer-guard.sh, tier-a-write-guard.sh and tier-b-write-guard.sh.
# Purpose: Thin adapter body (D9): parse the PreToolUse payload, call skills/feature-workflow/scripts/check-write.sh with the guard's --only class, translate its exit code to Claude's deny JSON.
# Usage: source it, then call `run_guard <spec|tier-a|tier-b> <with-proposed: 0|1>`.
# Behaviour:
#   - No skills/feature-workflow next to this hooks folder (project has no workflow): allow silently.
#   - Path = tool_input.file_path or tool_input.notebook_path; none: allow.
#   - --agent = agent_type (else agent_id) only when the payload carries agent_id (D16).
#   - with-proposed=1: builds the post-write content for spec.md detection: Write = tool_input.content; Edit = old_string -> new_string applied to the current file (all occurrences with replace_all); NotebookEdit: none.
#   - check-write.sh exit 0: allow (no output); exit 2: deny with its stderr; any other exit (usage/env error, unparsable payload): deny, fail closed.
#   - jq missing, or any failure before a decision (a non-zero exit under set -e): a static, hand-written deny JSON and exit 0,
#     as pre-launch.sh does, so the hook never fails open with a non-blocking error.
# Plan refs: assetlist D9, D16, D17, D18, D36; PLAN/hook-verification.md.
# Sources: first-party; deny JSON shape from PLAN/hook-verification/hooks/pre_write_deny.sh; static fallback pattern from hooks/pre-launch.sh (deny_raw).

GUARD_DECIDED=0
GUARD_TMPDIR=""

# Static denies: hand-written JSON with fixed reasons, usable without jq.
deny_static_nojq() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"write guard error (denying, fail closed): jq not found; install jq to write files in this project"}}'
}
deny_static_error() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"write guard error (denying, fail closed): the guard failed before reaching a decision"}}'
}

deny_json() {
  GUARD_DECIDED=1
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' 2>/dev/null \
    || deny_static_error
  exit 0
}

# EXIT trap: remove the scratch dir; a non-zero exit with no decision yet becomes a static deny (fail closed).
guard_on_exit() {
  local rc=$?
  [[ -z "$GUARD_TMPDIR" ]] || rm -rf "$GUARD_TMPDIR"
  if [[ $rc -ne 0 && $GUARD_DECIDED -eq 0 ]]; then
    GUARD_DECIDED=1
    deny_static_error
    exit 0
  fi
}

run_guard() {
  local only=$1 with_proposed=$2
  local here script input tool path cwd agent_id agent_type tmpdir rc reason
  trap guard_on_exit EXIT
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  script="$here/../skills/feature-workflow/scripts/check-write.sh"
  [[ -f "$script" ]] || exit 0
  # Workflow paths (D81), for guards that need them; sourced only once the workflow is known to be installed.
  # shellcheck source=../lib/workflow-paths.sh
  . "$(cd -P "$here" && pwd)/../lib/workflow-paths.sh"

  input=$(cat)
  if ! command -v jq >/dev/null 2>&1; then
    GUARD_DECIDED=1
    deny_static_nojq
    exit 0
  fi
  printf '%s' "$input" | jq -e . >/dev/null 2>&1 || deny_json "$only write guard: unparsable hook payload; denying (fail closed)"

  tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
  path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
  [[ -n "$path" ]] || exit 0
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
  [[ -n "$cwd" ]] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
  agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty')
  agent_type=$(printf '%s' "$input" | jq -r '.agent_type // empty')

  local args=(--cwd "$cwd" --path "$path" --only "$only")
  [[ -z "$agent_id" ]] || args+=(--agent "${agent_type:-$agent_id}")

  tmpdir=$(mktemp -d)
  GUARD_TMPDIR=$tmpdir
  if [[ "$with_proposed" == 1 && "$tool" != NotebookEdit ]]; then
    local cur=/dev/null abs=$path
    [[ "$abs" == /* ]] || abs="$cwd/$abs"
    [[ -f "$abs" ]] && cur=$abs
    if [[ "$tool" == Write ]]; then
      printf '%s' "$input" | jq -j '.tool_input.content // ""' >"$tmpdir/proposed"
    elif [[ "$tool" == Edit ]]; then
      printf '%s' "$input" | jq -j --rawfile c "$cur" '
        .tool_input as $t
        | if ($t.old_string // "") == "" then ($t.new_string // "")
          elif ($t.replace_all // false) then ($c | split($t.old_string) | join($t.new_string))
          else ($c | split($t.old_string)) as $p | $p[0] + $t.new_string + ($p[1:] | join($t.old_string)) end' >"$tmpdir/proposed" ||
        deny_json "$only write guard: could not compute the proposed content; denying (fail closed)"
    fi
    [[ ! -f "$tmpdir/proposed" ]] || args+=(--proposed "$tmpdir/proposed")
  fi

  rc=0
  "$script" "${args[@]}" >/dev/null 2>"$tmpdir/err" || rc=$?
  [[ $rc -ne 0 ]] || exit 0
  reason=$(cat "$tmpdir/err")
  [[ -n "$reason" ]] || reason="check-write.sh exited $rc"
  [[ $rc -eq 2 ]] || reason="write guard error (denying, fail closed): $reason"
  deny_json "$reason"
}
