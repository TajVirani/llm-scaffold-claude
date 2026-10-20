#!/usr/bin/env bash
# File: Hook (Claude adapter): keep an implementation or integration sub-agent inside its task worktree (D85).
# Goals:
#   - Since D85 a Claude Phase 3 implementation agent is launched WITHOUT `isolation` (the Agent tool has no working-directory input) and works
#     in the worktree the orchestrator created, .workflow/.worktrees/s<NNN>_t<N>. Only the brief keeps it there, so parallel agents could edit the
#     main checkout or each other's worktrees. This hook denies, for those agents, a Write/Edit/NotebookEdit outside the worktree and a Bash
#     command that does not start with `cd <worktree> &&` (the brief's rule). Main-session calls are never affected.
# Triggers/inputs: PreToolUse JSON for Write|Edit|NotebookEdit and Bash. Acts only when the payload carries agent_id (sub-agent calls only;
#   verified 2.1.300, PLAN/hook-verification.md T2) and agent_type is implementation or integration.
#   The task comes from the launch header (D37): PreToolUse carries no prompt and its transcript_path is the PARENT's transcript, so the
#   sub-agent transcript is <transcript_path without .jsonl>/subagents/agent-<agent_id>.jsonl (the layout SubagentStop reports as
#   agent_transcript_path, PLAN/hook-verification.md T2). Its first user message is parsed with resolve-launch.sh --parse-header, as
#   post-implementation-audit.sh does; spec_dir .workflow/specs/<NNN>-<slug> and task_id T<N> give the worktree name s<NNN>_t<N>.
# Behaviour (rule logic in skills/feature-workflow/scripts/check-worktree-scope.sh, D9):
#   - Worktree .workflow/.worktrees/s<NNN>_t<N> exists: confine to it. Otherwise, a linked-worktree cwd (isolation launch, Phase 1, integration):
#     confine to that worktree. Otherwise (no header, no task_id, no worktree, transcript not found): allow.
#   - check-worktree-scope.sh exit 0: allow (no output); exit 2: deny with its reason; any other exit: deny, fail closed.
#   - Not a sub-agent, another agent type, no workflow installed, or jq missing: allow silently (the other guards handle jq).
# Outputs/handoff: stdout is nothing or one deny JSON {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",...}}; exit 0.
# Wiring: claude-settings.template.json: PreToolUse, one group with matcher "Bash|Write|Edit|NotebookEdit" (install.sh merges hook commands
#   per event, so the same command in two groups of one event would be installed only once). Codex: hooks/codex-write-guard.sh applies the
#   same check to apply_patch paths, with the worktree named by the spawn task_name.
# Plan refs: 3.3; assetlist D9, D16, D18, D37, D85.
# Notes: Accident prevention only, like the other guards: a Bash command can still reach outside after its leading cd.
# Sources: first-party; hooks/post-implementation-audit.sh (transcript header parse), hooks/_guard-common.sh (deny shape).
# Requires: bash 3.2+, jq, git; resolve-launch.sh needs mikefarah yq v4 (D38).

set -euo pipefail

DECIDED=0
deny_json() {
  DECIDED=1
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}
CONFINED=0
TMP=""
# shellcheck disable=SC2329 # invoked by the EXIT trap
on_exit() {
  local rc=$?
  [ -z "$TMP" ] || rm -rf "$TMP"
  if [ "$rc" -ne 0 ] && [ "$DECIDED" -eq 0 ] && [ "$CONFINED" -eq 1 ]; then
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"worktree guard error (denying, fail closed): the guard failed before reaching a decision"}}'
    exit 0
  fi
}
trap on_exit EXIT

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
scripts=$here/../skills/feature-workflow/scripts
[ -f "$scripts/check-worktree-scope.sh" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$here" && pwd)/../lib/workflow-paths.sh"

input=$(cat)
jq -e 'type == "object"' <<<"$input" >/dev/null 2>&1 || exit 0
agent_id=$(jq -r '.agent_id // "" | strings' <<<"$input")
[ -n "$agent_id" ] || exit 0
agent_type=$(jq -r '.agent_type // "" | strings' <<<"$input")
case "$agent_type" in implementation|integration) ;; *) exit 0 ;; esac
CONFINED=1

tool=$(jq -r '.tool_name // "" | strings' <<<"$input")
cwd=$(jq -r '.cwd // "" | strings' <<<"$input")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}

TMP=$(mktemp -d "${TMPDIR:-/tmp}/worktree-guard.XXXXXX")

# The worktree name from the sub-agent's launch header; empty when it cannot be found.
name=""
parent=$(jq -r '.transcript_path // "" | strings' <<<"$input")
transcript=$(jq -r '.agent_transcript_path // "" | strings' <<<"$input")
[ -n "$transcript" ] || { [ -z "$parent" ] || transcript=${parent%.jsonl}/subagents/agent-$agent_id.jsonl; }
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  head -n 200 "$transcript" | jq -rs '
    [ .[] | select(type == "object" and .type == "user" and (.isMeta != true) and (.message.role // "user") == "user")
          | .message.content
          | if type == "string" then .
            elif type == "array" then ([ .[] | select(type == "object" and .type == "text") | .text ] | join("\n"))
            else "" end
          | select(. != "") ]
    | first // empty' >"$TMP/prompt" 2>/dev/null || : >"$TMP/prompt"
  if [ -s "$TMP/prompt" ] &&
    header=$(bash "$scripts/resolve-launch.sh" --parse-header --task-type "$agent_type" --prompt-file "$TMP/prompt" 2>/dev/null); then
    spec_dir=$(jq -r '.spec_dir // ""' <<<"$header")
    task_id=$(jq -r '.task_id // ""' <<<"$header")
    spec_num=${spec_dir%/}; spec_num=${spec_num##*/}; spec_num=${spec_num%%-*}
    if [[ "$spec_num" =~ ^[0-9]+$ ]] && [[ "$task_id" =~ ^T[0-9]+$ ]]; then
      name=s${spec_num}_t${task_id#T}
    fi
  fi
fi

args=(--cwd "$cwd")
[ -z "$name" ] || args+=(--worktree-name "$name")
case "$tool" in
  Bash) args+=(--command "$(jq -r '.tool_input.command // "" | strings' <<<"$input")") ;;
  Write|Edit|NotebookEdit)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // "" | strings' <<<"$input")
    [ -n "$path" ] || exit 0
    args+=(--path "$path")
    ;;
  *) exit 0 ;;
esac

rc=0
bash "$scripts/check-worktree-scope.sh" "${args[@]}" >/dev/null 2>"$TMP/err" || rc=$?
[ "$rc" -ne 0 ] || exit 0
reason=$(cat "$TMP/err")
[ -n "$reason" ] || reason="check-worktree-scope.sh exited $rc"
[ "$rc" -eq 2 ] || reason="worktree guard error (denying, fail closed): $reason"
deny_json "$reason"
