#!/usr/bin/env bash
# File: Hook (Codex adapter): validate the plaintext fields of every workflow sub-agent spawn.
# Goals:
#   - Codex encrypts the spawn `message` (verified on 0.155.1), so the launch header cannot be read or rewritten as pre-launch.sh does on
#     Claude. What is plaintext is `agent_type` and `task_name` (and `model`); this hook checks those and denies a malformed workflow spawn.
#   - The orchestrator still builds the message and model with resolve-launch.sh (orchestrator mode); this hook is the backstop for the
#     task_name, which the Codex stop audit (post-implementation-audit.sh) relies on to find the task.
# Behaviour:
#   - tool_name not ending in spawn_agent (Codex reports `collaborationspawn_agent`): exit 0, no output.
#   - agent_type empty, or not a workflow task type: exit 0 (built-in and user agents pass through). Workflow types are the keys of
#     resolve-launch.sh --requirements; a Codex agent_type matches a type either as written or in its Codex form enc(type) (fact-lookup ->
#     fact_lookup), which is the name generate-codex-agents.sh writes.
#   - No .agents/skills/feature-workflow in the project root: exit 0 (workflow not installed).
#   - task_name (Codex accepts only [a-z0-9_], no `/`; enc = lowercase, every character outside [a-z0-9] -> _):
#       implementation        s<NNN>_t<N> (task, 3.3) or s<NNN>_phase_1_<enc(work_type)> (Phase 1, 1.2/1.3); required
#       integration           s<NNN>_integration_<enc(work_type)>; required
#       profile-mini-review   s<NNN>_t<N>_r<round> (3.7 review round; the bare s<NNN>_t<N> is the implementer's name); required
#       other workflow types  optional: when it starts with s<NNN>_ the spec folder is checked, when it starts with i<NNN>_ (a launch
#                             from an initiative, e.g. i004_research) the initiative is checked; any other valid name passes (a
#                             repeated Phase 0/4 launch adds _r<round>, e.g. s007_fact_lookup_r2, i004_research_r2)
#     s<NNN> must resolve to exactly one folder .workflow/specs/<NNN>-*; i<NNN> to exactly one initiative, either a folder
#     .workflow/initiatives/<NNN>-* in the main checkout or a branch initiative/<NNN>-* (local or origin); a <enc(work_type)> must equal enc() of exactly one .workflow/profiles/<wt>.md.
#   - Any failed check: deny with the reason. jq missing, unreadable payload, or the task-type table not readable: deny, fail closed.
# Outputs/handoff: stdout is nothing (allow) or exactly one deny JSON:
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"codex-pre-spawn: ..."}}
#   Exit code always 0.
# Triggers/inputs: PreToolUse payload for the spawn tool: tool_input {agent_type, message (encrypted), task_name, fork_turns?, model?}.
#   Project root from the payload `cwd` (no project-dir variable on Codex), normalised to the main checkout (git --git-common-dir).
# Wiring: codex-hooks.template.json: PreToolUse, matcher ".*spawn_agent" (full-match regex; `spawn_agent` alone does not fire).
# Notes: The model is not validated here: a toml without `model` takes the spawn value, and the orchestrator passes the
#   resolve-launch.sh model. It is unverified whether Codex loads hyphenated agent names, hence the enc() form that generate-codex-agents.sh writes.
# Sources: first-party; pre-launch.sh (task-type table, deny shape, root normalisation); post-implementation-audit.sh (codex_enc, task_name parse).
# Requires: bash 3.2+, jq, git (optional; needed to find an initiative that exists only on its branch); resolve-launch.sh --requirements (jq only).

set -euo pipefail

deny_raw() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"codex-pre-spawn: environment error: jq not found; install jq to spawn sub-agents in this project (fail closed)"}}'
  exit 0
}
deny() {
  jq -cn --arg r "codex-pre-spawn: $1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}
env_deny() { deny "environment error (fail closed): $1"; }

command -v jq >/dev/null 2>&1 || deny_raw

payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 || env_deny "PreToolUse payload on stdin is not a JSON object"

case "$(jq -r '.tool_name // "" | strings' <<<"$payload")" in *spawn_agent) ;; *) exit 0 ;; esac
agent_type=$(jq -r '.tool_input.agent_type // "" | strings' <<<"$payload")
[ -n "$agent_type" ] || exit 0
task_name=$(jq -r '.tool_input.task_name // "" | strings' <<<"$payload")

root=$(jq -r '.cwd // "" | strings' <<<"$payload")
[ -n "$root" ] && [ -d "$root" ] || root=$PWD
root=$(cd "$root" && pwd)
if common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  root=$(dirname "$common")
fi
[ -d "$root/.agents/skills/feature-workflow" ] || exit 0
# Workflow paths; sourced once the workflow is known to be installed.
# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"
resolver=$root/.agents/skills/feature-workflow/scripts/resolve-launch.sh
[ -f "$resolver" ] || env_deny "${resolver#"$root"/} not found although .agents/skills/feature-workflow exists; reinstall the scaffold"

codex_enc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_'; }

types=$(bash "$resolver" --requirements 2>/dev/null | jq -r 'keys[]' 2>/dev/null) \
  || env_deny "could not read the task-type table from resolve-launch.sh --requirements"
[ -n "$types" ] || env_deny "resolve-launch.sh --requirements returned no task types"
type=""
while IFS= read -r t; do
  if [ "$agent_type" = "$t" ] || [ "$agent_type" = "$(codex_enc "$t")" ]; then type=$t; break; fi
done <<<"$types"
[ -n "$type" ] || exit 0

FORMS="implementation: s<NNN>_t<N> or s<NNN>_phase_1_<work_type>; integration: s<NNN>_integration_<work_type>; profile-mini-review: s<NNN>_t<N>_r<round>; a launch from an initiative: i<NNN>_<task_type>[_r<round>]"
bad() { deny "spawn of '$agent_type' refused: task_name '$task_name' $1 ($FORMS; enc: lowercase, non [a-z0-9] -> _)"; }

if [ -z "$task_name" ]; then
  case "$type" in
    implementation | integration | profile-mini-review) bad "is missing; the stop audit finds the task from it" ;;
    *) exit 0 ;;
  esac
fi
grep -Eq '^[a-z0-9_]+$' <<<"$task_name" || bad "must use only lowercase letters, digits and underscores (Codex rejects anything else)"

# spec_folder NNN : exactly one .workflow/specs/<NNN>-* in the main checkout.
spec_folder() {
  local d n=0
  for d in "$root/$WF_SPECS/$1"-*/; do [ -d "$d" ] && n=$((n + 1)); done
  [ "$n" -eq 1 ] || bad "names spec s$1, but $n folders match $WF_SPECS/$1-* (need exactly one)"
}
# initiative_folder NNN : exactly one initiative <NNN>-*, as a folder in the main checkout or as an initiative/<NNN>-* branch (local or
# origin); an initiative still in exploration exists only on its branch until it merges.
initiative_folder() {
  local d n
  # grep -c exits 1 when it counts zero; the || true after the substitution keeps that a count of 0 for the check below, because an
  # exit 1 here would end the hook before the deny and let the spawn through.
  n=$(
    {
      for d in "$root/$WF_INITIATIVES/$1"-*/; do [ -d "$d" ] && basename "$d"; done
      # git is optional: outside a repository there are no branch names, and the folder scan above still counts.
      { git -C "$root" for-each-ref --format='%(refname:lstrip=2)' "refs/heads/initiative/$1-*" "refs/remotes/origin/initiative/$1-*" 2>/dev/null || true; } \
        | sed -e 's|^origin/||' -e 's|^initiative/||'
    } | sort -u | grep -c .
  ) || true
  [ "${n:-0}" -eq 1 ] || bad "names initiative i$1, but ${n:-0} initiatives match $WF_INITIATIVES/$1-* or initiative/$1-* (need exactly one)"
}
# work_type ENC : exactly one .workflow/profiles/<wt>.md with enc(wt) = ENC.
work_type() {
  local p n=0
  for p in "$root/$WF_PROFILES"/*.md; do
    [ -f "$p" ] || continue
    [ "$(codex_enc "$(basename "$p" .md)")" = "$1" ] && n=$((n + 1))
  done
  [ "$n" -eq 1 ] || bad "names work type '$1', but $n profiles under $WF_PROFILES/ encode to it (need exactly one)"
}

num="" rest="" initiative_num=""
if [[ "$task_name" =~ ^s([0-9]+)_(.+)$ ]]; then
  num=${BASH_REMATCH[1]} rest=${BASH_REMATCH[2]}
elif [[ "$task_name" =~ ^i([0-9]+)_.+$ ]]; then
  initiative_num=${BASH_REMATCH[1]}
fi

case "$type" in
  implementation)
    [ -n "$num" ] || bad "is not in a workflow form"
    if [[ "$rest" =~ ^t[0-9]+$ ]]; then
      spec_folder "$num"
    elif [[ "$rest" =~ ^phase_1_([a-z0-9_]+)$ ]]; then
      wt=${BASH_REMATCH[1]}
      spec_folder "$num"
      work_type "$wt"
    else
      bad "is not s<NNN>_t<N> or s<NNN>_phase_1_<work_type> for an implementation launch"
    fi
    ;;
  integration)
    [[ "$rest" =~ ^integration_([a-z0-9_]+)$ ]] || bad "is not s<NNN>_integration_<work_type> for an integration launch"
    wt=${BASH_REMATCH[1]}
    spec_folder "$num"
    work_type "$wt"
    ;;
  profile-mini-review)
    [[ "$rest" =~ ^t[0-9]+_r[0-9]+$ ]] || bad "is not s<NNN>_t<N>_r<round> for a profile-mini-review launch"
    spec_folder "$num"
    ;;
  *)
    [ -z "$num" ] || spec_folder "$num"
    [ -z "$initiative_num" ] || initiative_folder "$initiative_num"
    ;;
esac
exit 0
