#!/usr/bin/env bash
# File: Hook (Claude adapter): keep an implementation or integration sub-agent inside its agent worktree.
# Goals:
#   - A Claude implementation agent (Phase 3 task or Phase 1) and an integration agent are launched WITHOUT `isolation` (the Agent tool
#     has no working-directory input) and work in the agent worktree the orchestrator created under .workflow/.worktrees/. Only the brief
#     keeps them there, so parallel agents could edit the spec checkout, the main checkout or each other's worktrees. This hook denies, for those agents, a
#     Write/Edit/NotebookEdit outside the worktree and a Bash command that does not start with `cd <worktree> &&` (the brief's rule).
#     Main-session calls are not confined.
# Triggers/inputs: PreToolUse JSON for Write|Edit|NotebookEdit and Bash. Confines only when the payload carries agent_id (sub-agent calls
#   only; verified 2.1.300) and agent_type is implementation or integration.
#   The task comes from the launch header: PreToolUse carries no prompt and its transcript_path is the PARENT's transcript, so the
#   sub-agent transcript is <transcript_path without .jsonl>/subagents/agent-<agent_id>.jsonl (the layout SubagentStop reports as
#   agent_transcript_path, verified 2.1.300). Its first user message is parsed with resolve-launch.sh --parse-header, as
#   post-implementation-audit.sh does. The header names the agent worktree through lib/workflow-paths.sh wf_agent_worktree_name, with
#   spec_dir .workflow/specs/<NNN>-<slug>:
#     task_id T<N>                                  s<NNN>_t<N>                    Phase 3 task
#     implementation header, work_type, no task_id  s<NNN>_phase_1_<enc(work_type)>  Phase 1 (1.2, 1.3)
#     integration header, work_type                 s<NNN>_integration_<enc(work_type)>
#   enc is wf_enc: lowercase, every byte outside [a-z0-9] -> _ (the Codex task_name form).
# Behaviour (rule logic in skills/feature-workflow/scripts/check-worktree-scope.sh):
#   - No workflow installed (no check-worktree-scope.sh next to the hooks): allow silently.
#   - Workflow installed, jq missing: a static, hand-written deny JSON naming jq. A payload that is not a JSON object: deny, main-session
#     calls included, since the hook cannot tell who is calling.
#   - Not a sub-agent, or another agent type: allow silently.
#   - An implementation or integration sub-agent: always checked with check-worktree-scope.sh --confined.
#     - A header the lib cannot name (e.g. a spec_dir that is not a <NNN>-<slug> folder): deny every call with the lib's reason, fail
#       closed, with or without isolation.
#     - A Write/Edit/NotebookEdit of the agent's own result file under the spec's artifacts/ (the path its launch header names, per
#       check-worktree-scope.sh): allow, even when the named agent worktree is missing. Every other path outside the worktree is denied.
#     - The named agent worktree exists: confine to it. Otherwise, a cwd in an isolation worktree (a launch with isolation: "worktree"; a spec worktree does not count): confine to
#       that worktree. Otherwise (the named agent worktree is missing, transcript not found, launch header missing or not parsed, cwd outside any git
#       repository): deny every call, reads and temp-dir writes included; the reason names the cause, with the transcript or header cause
#       the hook found added to the scope check's reason.
#   - check-worktree-scope.sh exit 0: allow (no output); exit 2: deny with its reason; any other exit: deny, fail closed.
# Outputs/handoff: stdout is nothing or one deny JSON {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",...}}; exit 0.
# Wiring: claude-settings.template.json: PreToolUse, one group with matcher "Bash|Write|Edit|NotebookEdit" (install.sh merges hook commands
#   per event, so the same command in two groups of one event would be installed only once). Codex: hooks/codex-write-guard.sh applies the
#   same check to apply_patch paths, with the worktree named by the spawn task_name.
# Notes: Accident prevention only, like the other guards: a Bash command can still reach outside after its leading cd.
# Sources: first-party; hooks/post-implementation-audit.sh (transcript header parse), hooks/workflow-write-guard.sh (deny shape),
#   lib/workflow-paths.sh (agent worktree names).
# Requires: bash 3.2+, jq, git; resolve-launch.sh needs mikefarah yq v4.

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
if ! command -v jq >/dev/null 2>&1; then
  # Written by hand because deny_json builds its JSON with jq, which is the tool that is missing here.
  DECIDED=1
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"worktree guard error (denying, fail closed): jq not found; install jq so the guard can read the tool call"}}'
  exit 0
fi
# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$here" && pwd)/../lib/workflow-paths.sh"

input=$(cat)
jq -e 'type == "object"' <<<"$input" >/dev/null 2>&1 ||
  deny_json "worktree guard error (denying, fail closed): the PreToolUse payload is not a JSON object, so the guard cannot tell who is calling"
agent_id=$(jq -r '.agent_id // "" | strings' <<<"$input")
[ -n "$agent_id" ] || exit 0
agent_type=$(jq -r '.agent_type // "" | strings' <<<"$input")
case "$agent_type" in implementation|integration) ;; *) exit 0 ;; esac
CONFINED=1

tool=$(jq -r '.tool_name // "" | strings' <<<"$input")
cwd=$(jq -r '.cwd // "" | strings' <<<"$input")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}

TMP=$(mktemp -d "${TMPDIR:-/tmp}/worktree-guard.XXXXXX")

# The worktree name from the sub-agent's launch header. When it cannot be found, name stays empty and
# name_missing_cause says why, so the deny reason can tell the orchestrator what to fix.
name=""
name_missing_cause=""
parent=$(jq -r '.transcript_path // "" | strings' <<<"$input")
transcript=$(jq -r '.agent_transcript_path // "" | strings' <<<"$input")
[ -n "$transcript" ] || { [ -z "$parent" ] || transcript=${parent%.jsonl}/subagents/agent-$agent_id.jsonl; }
if [ -z "$transcript" ]; then
  name_missing_cause="sub-agent transcript not found: the payload names no transcript_path"
elif [ ! -f "$transcript" ]; then
  name_missing_cause="sub-agent transcript not found: $transcript"
else
  head -n 200 "$transcript" | jq -rs '
    [ .[] | select(type == "object" and .type == "user" and (.isMeta != true) and (.message.role // "user") == "user")
          | .message.content
          | if type == "string" then .
            elif type == "array" then ([ .[] | select(type == "object" and .type == "text") | .text ] | join("\n"))
            else "" end
          | select(. != "") ]
    | first // empty' >"$TMP/prompt" 2>/dev/null || : >"$TMP/prompt"
  if [ ! -s "$TMP/prompt" ]; then
    name_missing_cause="launch header not parsed: the sub-agent transcript $transcript has no first user message"
  elif ! header=$(bash "$scripts/resolve-launch.sh" --parse-header --task-type "$agent_type" --prompt-file "$TMP/prompt" 2>"$TMP/header-err"); then
    name_missing_cause="launch header not parsed: $(cat "$TMP/header-err")"
  else
    spec_dir=$(jq -r '.spec_dir // ""' <<<"$header")
    task_id=$(jq -r '.task_id // ""' <<<"$header")
    work_type=$(jq -r '.work_type // ""' <<<"$header")
    if [ -n "$task_id" ]; then
      kind=task value=$task_id
    elif [ "$agent_type" = implementation ]; then
      kind=phase_1 value=$work_type
    else
      kind=integration value=$work_type
    fi
    name=$(wf_agent_worktree_name "$spec_dir" "$kind" "$value" 2>"$TMP/name-err") ||
      deny_json "worktree guard: cannot name this agent's worktree from its launch header (denying, fail closed): $(cat "$TMP/name-err")"
  fi
fi

args=(--cwd "$cwd" --confined)
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
[ -z "$name_missing_cause" ] || reason="$reason (no agent worktree name: $name_missing_cause)"
deny_json "$reason"
