#!/usr/bin/env bash
# Suite: hooks/codex-pre-spawn.sh (PreToolUse .*spawn_agent) for spawns from an initiative; JRN-008 "Launch from an initiative"
#   (Codex part).
# Covers: the i<NNN>_<enc(type)> task-name form keyed to an initiative folder accepted for research and the other Phase 0 types;
#   s<NNN>_research denied with a reason when no spec folder matches; an i<NNN> naming no initiative folder denied; spec task
#   names unchanged.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

new_workdir
P=$WORK/proj
large_path_repo "$P"
seed_initiative "$P" 001 storage-overhaul
mkdir -p "$P/.workflow/specs/007-checkout"
H=$P/.agents/hooks

# spawn_payload AGENT_TYPE TASK_NAME : the Codex spawn payload (the message is encrypted on Codex, so only these fields are plaintext).
spawn_payload() {
  jq -cn --arg a "$1" --arg t "$2" --arg c "$P" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"PreToolUse",model:"m",permission_mode:"default",turn_id:"u",
      tool_name:"collaborationspawn_agent",tool_use_id:"c",tool_input:{agent_type:$a,message:"gAAAAA",fork_turns:"none",task_name:$t}}'
}
# expect NAME allow|deny AGENT_TYPE TASK_NAME [REASON_REGEX]
expect() {
  local out rc reason
  out=$(spawn_payload "$3" "$4" | (cd "$P" && bash "$H/codex-pre-spawn.sh" 2>/dev/null))
  rc=$?
  reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out" 2>/dev/null)
  if [ "$2" = allow ]; then
    if [ "$rc" = 0 ] && [ -z "$out" ]; then ok "$1"; else ko "$1" "rc=$rc out=$out"; fi
  elif [ "$rc" = 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" 2>/dev/null)" = deny ]; then
    if [ -z "${5:-}" ] || grep -qE -- "$5" <<<"$reason"; then ok "$1"; else ko "$1" "reason lacks /$5/: $reason"; fi
  else ko "$1" "rc=$rc out=$out"; fi
}

check "JRN-008 research is a workflow task type" 'bash "$P/.agents/skills/feature-workflow/scripts/resolve-launch.sh" --requirements | jq -e "has(\"research\")" >/dev/null'
expect "JRN-008 research i001_research is accepted" allow research i001_research
expect "JRN-008 research s001_research is denied with a reason" deny research s001_research "s001|spec"
expect "JRN-008 research i002_research (no such initiative) is denied" deny research i002_research "i002|initiative"
expect "JRN-008 research in a repeated round i001_research_r2 is accepted" allow research i001_research_r2
expect "JRN-008 fact_lookup i001_fact_lookup is accepted" allow fact_lookup i001_fact_lookup
expect "JRN-008 fact_lookup i009_fact_lookup (no such initiative) is denied" deny fact_lookup i009_fact_lookup "i009|initiative"
expect "JRN-008 research s007_research for a spec folder is accepted" allow research s007_research
expect "JRN-008 implementation s007_t3 is unchanged" allow implementation s007_t3

shellcheck_files "JRN-008 shellcheck codex-pre-spawn.sh" "$H/codex-pre-spawn.sh"
finish
