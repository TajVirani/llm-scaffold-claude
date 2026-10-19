#!/usr/bin/env bash
# Suite: hooks/pre-launch.sh (PreToolUse on Agent/Task).
# Covers: non-Agent and non-workflow launches pass silently, valid launches get the full updatedInput rewrite
#   (model, header, profile), legacy Task tool name, deny paths (missing header, task_type mismatch, unresolved model,
#   env error with no yq, no jq, invalid payload), worktree cwd (D18), CLAUDE_PROJECT_DIR fallback, workflow absent / not set up.
# shellcheck disable=SC2016,SC2015  # jq programs use single quotes; A && B || C is deliberate in ok/ko lines
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
T=$WORK
FX=$T/proj
mkdir -p "$FX"
copy_agents "$FX"
HOOK=$FX/.agents/hooks/pre-launch.sh
mkdir -p "$FX/model-map" "$FX/profiles" "$FX/specs/001-demo"
cat > "$FX/model-map/implementation.md" <<'M'
---
tier: strong
claude: opus
codex: <alias>
---
# implementation
M
cat > "$FX/model-map/retrieval.md" <<'M'
---
tier: cheap
claude: haiku
---
M
cat > "$FX/profiles/frontend-react.md" <<'M'
# Profile: frontend-react
PROFILE-MARKER-XYZ
## Mini-review checklist
- item
M
cat > "$FX/specs/001-demo/tasks.md" <<'M'
---
tasks:
  - id: T3
    title: "x"
    status: pending
    capability: CAP-001
    depends_on: []
    touches_core: false
    work_type: frontend-react
    module: "m"
    seam: "s"
---
M
git_init_repo "$FX"
git_commit_all "$FX" init

HDR=$'```yaml launch-header\ntask_type: implementation\nspec_dir: specs/001-demo\ntask_id: T3\n```\nDo the task.'
payload() { # tool_name subagent_type prompt cwd [extra-json]
  local x=${5:-}; [ -n "$x" ] || x='{}'
  jq -cn --arg t "$1" --arg s "$2" --arg p "$3" --arg c "$4" --argjson x "$x" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"PreToolUse",tool_name:$t,tool_use_id:"u",
      tool_input:({description:"d",prompt:$p,subagent_type:$s,run_in_background:false} + $x)}'
}
run() { out=$(printf '%s' "$1" | (cd "${2:-$FX}" && env -u CLAUDE_PROJECT_DIR bash "$HOOK")); rc=$?; }

# 1 non-Agent tool
run "$(jq -cn --arg c "$FX" '{cwd:$c,tool_name:"Bash",tool_input:{command:"ls"}}')"
[ $rc = 0 ] && [ -z "$out" ] && ok "non-Agent tool silent" || ko "non-Agent" "rc=$rc out=$out"

# 2 non-workflow subagents
for s in Explore general-purpose; do
  run "$(payload Agent $s "find stuff" "$FX")"
  [ $rc = 0 ] && [ -z "$out" ] && ok "non-workflow $s silent" || ko "non-workflow $s" "rc=$rc out=$out"
done

# 3 valid implementation launch (with isolation + run_in_background true)
run "$(payload Agent implementation "$HDR" "$FX" '{"isolation":"worktree","run_in_background":true}')"
if [ $rc = 0 ] && jq -e --arg hdr "$HDR" '
  .hookSpecificOutput.hookEventName=="PreToolUse" and .hookSpecificOutput.permissionDecision=="allow"
  and (.hookSpecificOutput.updatedInput | keys | sort | join(",")) == "description,isolation,model,prompt,run_in_background,subagent_type"
  and .hookSpecificOutput.updatedInput.description=="d"
  and .hookSpecificOutput.updatedInput.subagent_type=="implementation"
  and .hookSpecificOutput.updatedInput.run_in_background==true
  and .hookSpecificOutput.updatedInput.isolation=="worktree"
  and .hookSpecificOutput.updatedInput.model=="opus"
  and (.hookSpecificOutput.updatedInput.prompt | startswith("```yaml launch-header\ntask_type: implementation"))
  and (.hookSpecificOutput.updatedInput.prompt | contains("PROFILE-MARKER-XYZ"))
  and (.hookSpecificOutput.updatedInput.prompt | endswith("Do the task."))' <<<"$out" >/dev/null
then ok "valid implementation launch -> allow + full updatedInput"; else ko "valid implementation" "rc=$rc out=$out"; fi
[ "$(printf '%s' "$out" | wc -l | tr -d ' ')" -le 1 ] && ok "single-line stdout" || ko "stdout" "multi-line"

# 3b legacy Task tool name, retrieval (no profile, prompt unchanged)
RH=$'```yaml launch-header\ntask_type: retrieval\nspec_dir: specs/001-demo\n```\nPull docs.'
run "$(payload Task retrieval "$RH" "$FX")"
jq -e --arg p "$RH" '.hookSpecificOutput.permissionDecision=="allow" and .hookSpecificOutput.updatedInput.prompt==$p and .hookSpecificOutput.updatedInput.model=="haiku"' <<<"$out" >/dev/null \
  && ok "legacy Task + retrieval: prompt unchanged, model set" || ko "Task retrieval" "$out"

# 4 missing header deny
run "$(payload Agent implementation "Just do it" "$FX")"
jq -e '.hookSpecificOutput.permissionDecision=="deny" and (.hookSpecificOutput.permissionDecisionReason|test("no launch header"))' <<<"$out" >/dev/null \
  && ok "missing header -> deny" || ko "missing header" "rc=$rc $out"

# 4b task_type mismatch
run "$(payload Agent integration "$HDR" "$FX")"
jq -e '.hookSpecificOutput.permissionDecision=="deny" and (.hookSpecificOutput.permissionDecisionReason|test("disagrees"))' <<<"$out" >/dev/null \
  && ok "task_type mismatch -> deny" || ko "mismatch" "$out"

# 5 model unresolved deny (fact-lookup has no model-map)
FH=$'```yaml launch-header\ntask_type: fact-lookup\nspec_dir: specs/001-demo\n```\nq'
run "$(payload Agent fact-lookup "$FH" "$FX")"
jq -e '.hookSpecificOutput.permissionDecision=="deny" and (.hookSpecificOutput.permissionDecisionReason|test("00.14"))' <<<"$out" >/dev/null \
  && ok "model unresolved -> deny 00.14" || ko "00.14" "$out"

# 6 resolve env error deny (yq missing: PATH without yq)
NOYQ=$T/noyq; mkdir -p "$NOYQ"; for b in bash jq git cat sed tr grep mktemp rm dirname head awk env wc; do ln -sf "$(command -v $b)" "$NOYQ/$b"; done
out=$(payload Agent implementation "$HDR" "$FX" | (cd "$FX" && env -u CLAUDE_PROJECT_DIR PATH="$NOYQ" "$NOYQ/bash" "$HOOK")); rc=$?
jq -e '.hookSpecificOutput.permissionDecision=="deny" and (.hookSpecificOutput.permissionDecisionReason|test("environment error.*exited 1.*yq"))' <<<"$out" >/dev/null \
  && ok "resolve env error (no yq) -> deny fail closed" || ko "env error" "rc=$rc $out"

# 6b jq missing -> static deny
NOJQ=$T/nojq; mkdir -p "$NOJQ"; for b in bash cat; do ln -sf "$(command -v $b)" "$NOJQ/$b"; done
out=$(payload Agent Explore x "$FX" | PATH="$NOJQ" "$NOJQ/bash" "$HOOK"); rc=$?
printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision=="deny"' >/dev/null && ok "jq missing -> valid deny JSON" || ko "nojq" "$out"

# 6c invalid payload
run "not json"
jq -e '.hookSpecificOutput.permissionDecision=="deny"' <<<"$out" >/dev/null && ok "invalid payload -> deny" || ko "invalid payload" "$out"

# 7 worktree cwd (payload cwd is the worktree, hook pwd elsewhere, no CLAUDE_PROJECT_DIR)
( cd "$FX" && git worktree add -q .claude/worktrees/agent-abc -b wt-abc 2>/dev/null )
WT=$FX/.claude/worktrees/agent-abc
run "$(payload Agent implementation "$HDR" "$WT")" /
jq -e '.hookSpecificOutput.permissionDecision=="allow" and .hookSpecificOutput.updatedInput.model=="opus"' <<<"$out" >/dev/null \
  && ok "worktree cwd resolves to main checkout" || ko "worktree" "$out"

# 7b no cwd in payload -> CLAUDE_PROJECT_DIR fallback
out=$(payload Agent implementation "$HDR" "" | jq -c 'del(.cwd)' | (cd / && CLAUDE_PROJECT_DIR="$FX" bash "$HOOK")); rc=$?
jq -e '.hookSpecificOutput.permissionDecision=="allow"' <<<"$out" >/dev/null && ok "no cwd -> CLAUDE_PROJECT_DIR fallback" || ko "fallback" "$out"

# 8 project without the workflow installed -> silent
NW=$T/nowf; mkdir -p "$NW/.agents/hooks"; cp "$HOOK" "$NW/.agents/hooks/"
out=$(payload Agent implementation "$HDR" "$NW" | bash "$NW/.agents/hooks/pre-launch.sh"); rc=$?
[ $rc = 0 ] && [ -z "$out" ] && ok "workflow absent -> silent" || ko "no workflow" "rc=$rc $out"

# 8b workflow installed but project not set up (no model-map/profiles) -> deny 00.14
NS=$T/nosetup; mkdir -p "$NS"; cp -R "$AGENTS_SRC" "$NS/.agents"; mkdir -p "$NS/specs/001-demo"; cp "$FX/specs/001-demo/tasks.md" "$NS/specs/001-demo/"
out=$(payload Agent implementation "$HDR" "$NS" | bash "$NS/.agents/hooks/pre-launch.sh"); rc=$?
jq -e '.hookSpecificOutput.permissionDecision=="deny" and (.hookSpecificOutput.permissionDecisionReason|test("00.14"))' <<<"$out" >/dev/null \
  && ok "workflow not set up -> deny 00.14" || ko "not set up" "$out"

# 9 timing
s=$(date +%s); for _ in 1 2 3; do run "$(payload Agent implementation "$HDR" "$FX")"; done; e=$(date +%s)
echo "INFO 3 allow runs took $((e-s))s"


shellcheck_files "shellcheck: pre-launch.sh" "$HOOK"
finish
