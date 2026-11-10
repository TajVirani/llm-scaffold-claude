#!/usr/bin/env bash
# File: Hook (Claude adapter): the write guard for workflow files, one check-write.sh call per Write, Edit or NotebookEdit.
# Goals:
#   - Single writer for spec.md, tasks.md and the per-task bodies under tasks/: spec.md only at the steps check-write.sh lists, with
#     status and blocked_condition changed only through status-transition.sh; tasks.md and tasks/** only at 2.5 or 0.3.20.
#   - The step markers (.workflow/specs/*/.step, .workflow/initiatives/*/.step), the Done folder and the work-backlog: as check-write.sh rules.
#   - Tier A (.workflow/GLOSSARY.md, .workflow/capabilities.md, .workflow/rules.md, .workflow/decisions/, .workflow/profiles/,
#     .workflow/review-lessons.md): only at the step marker's gates, else redirect to a 5.2 proposal.
#   - Deny every guarded path when the payload carries agent_id: only calls made inside a sub-agent carry agent_id/agent_type,
#     main-session calls carry neither (verified 2.1.300).
# Triggers/inputs: PreToolUse JSON for Write/Edit/NotebookEdit. Rule logic in skills/feature-workflow/scripts/check-write.sh (every path
#   class in one call), which reads the gitignored step markers. Paths from the payload `cwd`.
# Behaviour:
#   - No skills/feature-workflow next to this hooks folder (project has no workflow): allow silently.
#   - Path = tool_input.file_path or tool_input.notebook_path; none: allow.
#   - --agent = agent_type (else agent_id) only when the payload carries agent_id.
#   - --proposed, the post-write content check-write.sh needs to see a spec.md status change: Write = tool_input.content; Edit =
#     old_string -> new_string applied to the current file (all occurrences with replace_all); NotebookEdit: none.
#   - check-write.sh exit 0: allow (no output); exit 2: deny with its stderr; any other exit (usage/env error): deny, fail closed.
#   - jq missing, an unparsable payload, or any failure before a decision (a non-zero exit under set -e): a deny JSON and exit 0
#     (hand-written when jq is missing), so the hook never fails open with a non-blocking error.
# Outputs/handoff: stdout is nothing or one deny JSON {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",...}}; exit 0.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh): PreToolUse, matcher
#   "Write|Edit|NotebookEdit" (no MultiEdit tool exists; verified 2.1.300). Codex: hooks/codex-write-guard.sh makes the same
#   check-write.sh call for each apply_patch path.
# Notes: Accident prevention only: Bash writes bypass this hook. The .step markers it trusts are hard-protected by the deny rules
#   Edit(.workflow/specs/*/.step) and Edit(.workflow/initiatives/*/.step); spec.md and Tier A have no hard limit, since the main
#   session writes them at approved steps.
# Sources: first-party; static fallback pattern from hooks/pre-launch.sh (deny_raw).

set -euo pipefail

DECIDED=0
TMP=""

# deny_static REASON : a hand-written deny JSON, usable without jq; REASON must hold no `"` or `\`.
deny_static() {
  DECIDED=1
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"write guard error (denying, fail closed): %s"}}\n' "$1"
  exit 0
}

# deny_json REASON : the deny JSON for REASON, built with jq.
deny_json() {
  DECIDED=1
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' 2>/dev/null ||
    deny_static "the guard failed before reaching a decision"
  exit 0
}

# on_exit : remove the scratch dir; a non-zero exit with no decision yet becomes a deny (fail closed).
# shellcheck disable=SC2329 # invoked by the EXIT trap
on_exit() {
  local rc=$?
  [[ -z "$TMP" ]] || rm -rf "$TMP"
  if [[ $rc -ne 0 && $DECIDED -eq 0 ]]; then deny_static "the guard failed before reaching a decision"; fi
}
trap on_exit EXIT

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script=$here/../skills/feature-workflow/scripts/check-write.sh
[[ -f "$script" ]] || exit 0

input=$(cat)
command -v jq >/dev/null 2>&1 || deny_static "jq not found; install jq to write files in this project"
printf '%s' "$input" | jq -e 'type == "object"' >/dev/null 2>&1 || deny_json "write guard: unparsable hook payload; denying (fail closed)"

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[[ -n "$path" ]] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[[ -n "$cwd" ]] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty')
agent_type=$(printf '%s' "$input" | jq -r '.agent_type // empty')

args=(--cwd "$cwd" --path "$path")
[[ -z "$agent_id" ]] || args+=(--agent "${agent_type:-$agent_id}")

TMP=$(mktemp -d)
if [[ "$tool" != NotebookEdit ]]; then
  cur=/dev/null abs=$path
  [[ "$abs" == /* ]] || abs="$cwd/$abs"
  [[ ! -f "$abs" ]] || cur=$abs
  if [[ "$tool" == Write ]]; then
    printf '%s' "$input" | jq -j '.tool_input.content // ""' >"$TMP/proposed"
  elif [[ "$tool" == Edit ]]; then
    printf '%s' "$input" | jq -j --rawfile c "$cur" '
      .tool_input as $t
      | if ($t.old_string // "") == "" then ($t.new_string // "")
        elif ($t.replace_all // false) then ($c | split($t.old_string) | join($t.new_string))
        else ($c | split($t.old_string)) as $p | $p[0] + $t.new_string + ($p[1:] | join($t.old_string)) end' >"$TMP/proposed" ||
      deny_json "write guard: could not compute the proposed content; denying (fail closed)"
  fi
  [[ ! -f "$TMP/proposed" ]] || args+=(--proposed "$TMP/proposed")
fi

rc=0
"$script" "${args[@]}" >/dev/null 2>"$TMP/err" || rc=$?
[[ $rc -ne 0 ]] || exit 0
reason=$(cat "$TMP/err")
[[ -n "$reason" ]] || reason="check-write.sh exited $rc"
[[ $rc -eq 2 ]] || reason="write guard error (denying, fail closed): $reason"
deny_json "$reason"
