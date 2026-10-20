#!/usr/bin/env bash
# Suite: hooks/worktree-write-guard.sh (Claude PreToolUse, Write/Edit/NotebookEdit and Bash), the worktree check in hooks/codex-write-guard.sh,
#   and their rule script feature-workflow/scripts/check-worktree-scope.sh.
# Covers: task identified from the sub-agent transcript (<parent transcript>/subagents/agent-<id>.jsonl) launch header -> confined to
#   .workflow/.worktrees/s<NNN>_t<N>; writes to the main checkout or another task's worktree denied; temp-dir writes allowed; `..` escapes;
#   relative paths; Bash needs a leading `cd <worktree> &&`; main session, other agent types, missing transcript or worktree unaffected;
#   isolation (linked-worktree cwd) confinement; integration agents; Codex task_name from session_meta; settings wiring; shellcheck.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
H=$P/.agents/hooks
SCOPE=$P/.agents/skills/feature-workflow/scripts/check-worktree-scope.sh
mkdir -p "$P/.workflow/specs/007-demo" "$P/src"
echo '.workflow/.worktrees/' > "$P/.gitignore"
git_commit_all "$P" fixture
git -C "$P" worktree add -q .workflow/.worktrees/s007_t3 -b task/007-demo/T03-a
git -C "$P" worktree add -q .workflow/.worktrees/s007_t4 -b task/007-demo/T04-b
git -C "$P" worktree add -q .claude/worktrees/agent-iso -b wt-iso
W3=$P/.workflow/.worktrees/s007_t3
W4=$P/.workflow/.worktrees/s007_t4
ISO=$P/.claude/worktrees/agent-iso

# Parent transcript /<dir>/sess.jsonl; the sub-agent's at /<dir>/sess/subagents/agent-<id>.jsonl.
TR=$WORK/tr
mkdir -p "$TR/sess/subagents"
mk_sub() { # agent_id prompt
  {
    jq -cn --arg p "$2" '{type:"user",isSidechain:true,message:{role:"user",content:$p}}'
    jq -cn '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:"ok"}]}}'
  } > "$TR/sess/subagents/agent-$1.jsonl"
}
mk_sub a3 $'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-demo\ntask_id: T3\nwork_type: web\n```\n\nBuild T3.'
mk_sub a9 $'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-demo\ntask_id: T9\n```\n\nBuild T9 (no worktree).'
mk_sub ai $'```yaml launch-header\ntask_type: integration\nspec_dir: .workflow/specs/007-demo\nwork_type: web\n```\n\nBatch.'

# pl TOOL ARG [CWD] [EXTRA] : PreToolUse payload; ARG is the file path, or the command for Bash.
pl() {
  local x=${4:-}
  [ -n "$x" ] || x='{}'
  jq -cn --arg t "$1" --arg a "$2" --arg c "${3:-$P}" --arg tp "$TR/sess.jsonl" --argjson x "$x" '
    {session_id:"sess",transcript_path:$tp,cwd:$c,hook_event_name:"PreToolUse",tool_name:$t,tool_use_id:"u",
     tool_input:(if $t=="Bash" then {command:$a} elif $t=="NotebookEdit" then {notebook_path:$a,new_source:"x"} else {file_path:$a,content:"x"} end)} + $x'
}
A3='{"agent_id":"a3","agent_type":"implementation"}'
A9='{"agent_id":"a9","agent_type":"implementation"}'
AI='{"agent_id":"ai","agent_type":"integration"}'
NOTR='{"agent_id":"zz","agent_type":"implementation"}'

guard() { out=$(printf '%s' "$1" | (cd "$P" && bash "$H/worktree-write-guard.sh" 2>/dev/null)); rc=$?; }
reason() { jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out"; }
expect() { # name allow|deny payload [reason-regex]
  guard "$3"
  if [ "$2" = allow ]; then
    if [ "$rc" = 0 ] && [ -z "$out" ]; then ok "$1"; else ko "$1" "rc=$rc out=$out"; fi
  elif [ "$rc" = 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" 2>/dev/null)" = deny ]; then
    if [ -z "${4:-}" ] || reason | grep -Eq -- "$4"; then ok "$1"; else ko "$1" "reason lacks /$4/: $(reason)"; fi
  else ko "$1" "rc=$rc out=$out"; fi
}

echo "== Claude: file tools"
expect "main session write to the main checkout -> allow" allow "$(pl Write "$P/src/a.ts")"
expect "main session Bash without cd -> allow" allow "$(pl Bash 'git status')"
expect "task agent write inside its worktree -> allow" allow "$(pl Write "$W3/src/a.ts" "$P" "$A3")"
expect "task agent Edit in a new subdir of its worktree -> allow" allow "$(pl Edit "$W3/new/deep/f.ts" "$P" "$A3")"
expect "task agent write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$P" "$A3")" "s007_t3.*denied write outside it"
expect "task agent write to another task's worktree -> deny" deny "$(pl Write "$W4/src/a.ts" "$P" "$A3")" "outside"
expect "task agent '..' escape from its worktree -> deny" deny "$(pl Write "$W3/../s007_t4/x.ts" "$P" "$A3")"
expect "task agent relative path (resolves to the main checkout) -> deny" deny "$(pl Write "src/a.ts" "$P" "$A3")"
expect "task agent NotebookEdit outside -> deny" deny "$(pl NotebookEdit "$P/n.ipynb" "$P" "$A3")"
expect "task agent write to a temp dir outside the repo -> allow" allow "$(pl Write "$WORK/scratch.txt" "$P" "$A3")"
expect "task without a worktree on disk -> allow (nothing to confine to)" allow "$(pl Write "$P/src/a.ts" "$P" "$A9")"
expect "sub-agent transcript missing -> allow" allow "$(pl Write "$P/src/a.ts" "$P" "$NOTR")"
expect "other agent type (fact-lookup) -> allow" allow "$(pl Write "$P/src/a.ts" "$P" '{"agent_id":"a3","agent_type":"fact-lookup"}')"
ATP=$(jq -cn --arg t "$TR/sess/subagents/agent-a3.jsonl" '{agent_id:"q",agent_type:"implementation",agent_transcript_path:$t}')
expect "agent_transcript_path in the payload is used when present" deny "$(pl Write "$P/src/a.ts" "$P" "$ATP")"

echo "== Claude: isolation and integration (linked-worktree cwd)"
expect "isolation agent (no named worktree) write in its cwd worktree -> allow" allow "$(pl Write "$ISO/src/a.ts" "$ISO" "$A9")"
expect "isolation agent write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$ISO" "$A9")" "agent-iso"
expect "integration agent write to the main checkout -> deny" deny "$(pl Write "$P/src/core.ts" "$ISO" "$AI")"
expect "integration agent write in its worktree -> allow" allow "$(pl Write "$ISO/src/core.ts" "$ISO" "$AI")"

echo "== Claude: Bash"
expect "task agent Bash with cd <worktree> && -> allow" allow "$(pl Bash "cd $W3 && git status" "$P" "$A3")"
expect "task agent Bash with quoted cd into a subdir -> allow" allow "$(pl Bash "cd \"$W3/src\" && ls" "$P" "$A3")"
expect "task agent Bash without cd -> deny" deny "$(pl Bash 'git status' "$P" "$A3")" "cd .*s007_t3 &&"
expect "task agent Bash cd to the main checkout -> deny" deny "$(pl Bash "cd $P && ls" "$P" "$A3")" "outside the worktree"
expect "task agent Bash cd to another worktree -> deny" deny "$(pl Bash "cd $W4 && ls" "$P" "$A3")"
expect "task agent Bash cd \$VAR -> deny (not literal)" deny "$(pl Bash 'cd "$WT" && ls' "$P" "$A3")" "not a literal path"
expect "task agent Bash 'cd dir; cmd' -> deny (needs &&)" deny "$(pl Bash "cd $W3; ls" "$P" "$A3")"
expect "task agent Bash whose cwd is already its worktree -> allow" allow "$(pl Bash 'ls' "$W3" "$A3")"
expect "task agent without a worktree: Bash -> allow" allow "$(pl Bash 'ls' "$P" "$A9")"

echo "== fail closed"
out=$(printf 'not json' | (cd "$P" && bash "$H/worktree-write-guard.sh" 2>/dev/null)); rc=$?
check "unparsable payload -> allow silently (main-session safe)" '[ $rc -eq 0 ] && [ -z "$out" ]' "rc=$rc out=$out"
N=$WORK/noflow
mkdir -p "$N/.agents/hooks" && cp "$H/worktree-write-guard.sh" "$N/.agents/hooks/"
out=$(printf '%s' "$(pl Write "$P/src/a.ts" "$P" "$A3")" | bash "$N/.agents/hooks/worktree-write-guard.sh" 2>/dev/null); rc=$?
check "no workflow installed -> silent" '[ $rc -eq 0 ] && [ -z "$out" ]' "rc=$rc out=$out"

echo "== check-worktree-scope.sh CLI"
rc=0; bash "$SCOPE" --cwd "$P" >/dev/null 2>&1 || rc=$?
eq "no --path or --command -> exit 1" "$rc" 1
rc=0; bash "$SCOPE" --cwd "$P" --worktree-name ../x --path a >/dev/null 2>&1 || rc=$?
eq "worktree name with a slash -> exit 1" "$rc" 1
rc=0; bash "$SCOPE" --cwd "$WORK" --worktree-name s007_t3 --path "$WORK/a" >/dev/null 2>&1 || rc=$?
eq "cwd outside any repo -> allow" "$rc" 0

echo "== Codex: codex-write-guard.sh worktree check"
mk_rollout() { # file task_name
  jq -cn --arg n "$2" '{type:"session_meta",payload:{agent_path:("/root/" + $n)}}' > "$1"
}
mk_rollout "$WORK/rollout-t3.jsonl" s007_t3
mk_rollout "$WORK/rollout-t9.jsonl" s007_t9
wp() { # patch transcript
  jq -cn --arg p "$1" --arg c "$P" --arg tp "$2" \
    '{session_id:"s",transcript_path:$tp,cwd:$c,hook_event_name:"PreToolUse",model:"m",permission_mode:"default",turn_id:"u",
      tool_name:"apply_patch",tool_input:{command:$p},tool_use_id:"c",agent_id:"a1",agent_type:"implementation"}'
}
add() { printf '*** Begin Patch\n*** Add File: %s\n+x\n*** End Patch\n' "$1"; }
cguard() { out=$(printf '%s' "$1" | (cd "$P" && bash "$H/codex-write-guard.sh" 2>/dev/null)); rc=$?; }
cexpect() { # name allow|deny payload [regex]
  cguard "$3"
  if [ "$2" = allow ]; then
    if [ "$rc" = 0 ] && [ -z "$out" ]; then ok "$1"; else ko "$1" "rc=$rc out=$out"; fi
  elif [ "$rc" = 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" 2>/dev/null)" = deny ]; then
    if [ -z "${4:-}" ] || reason | grep -Eq -- "$4"; then ok "$1"; else ko "$1" "reason lacks /$4/: $(reason)"; fi
  else ko "$1" "rc=$rc out=$out"; fi
}
cexpect "Codex task agent: patch inside its worktree (relative) -> allow" allow "$(wp "$(add .workflow/.worktrees/s007_t3/src/a.ts)" "$WORK/rollout-t3.jsonl")"
cexpect "Codex task agent: patch in the main checkout -> deny" deny "$(wp "$(add src/a.ts)" "$WORK/rollout-t3.jsonl")" "src/a.ts: worktree guard"
cexpect "Codex task agent: patch in another worktree -> deny" deny "$(wp "$(add "$W4/a.ts")" "$WORK/rollout-t3.jsonl")"
cexpect "Codex task agent without a worktree -> allow" allow "$(wp "$(add src/a.ts)" "$WORK/rollout-t9.jsonl")"
cexpect "Codex transcript without session_meta -> allow" allow "$(wp "$(add src/a.ts)" "$TR/sess.jsonl")"
out=$(jq -cn --arg p "$(add src/a.ts)" --arg c "$P" --arg tp "$WORK/rollout-t3.jsonl" \
  '{session_id:"s",transcript_path:$tp,cwd:$c,hook_event_name:"PreToolUse",tool_name:"apply_patch",tool_input:{command:$p}}' \
  | (cd "$P" && bash "$H/codex-write-guard.sh" 2>/dev/null)); rc=$?
check "Codex main session (no agent_id) unaffected" '[ $rc -eq 0 ] && [ -z "$out" ]' "rc=$rc out=$out"

echo "== wiring"
TPL=$P/.agents/hooks/claude-settings.template.json
check "template: PreToolUse Bash|Write|Edit|NotebookEdit runs worktree-write-guard.sh" \
  'jq -e "[.hooks.PreToolUse[] | select(.matcher == \"Bash|Write|Edit|NotebookEdit\") | .hooks[].command] | any(test(\"hooks/worktree-write-guard.sh\"))" "$TPL" >/dev/null'
check "manifest ships the hook and the feature-workflow skill (rule script)" 'grep -qx "hooks/worktree-write-guard.sh" "$P/.agents/install-manifest.txt" && grep -qx "skills/feature-workflow" "$P/.agents/install-manifest.txt"'
check "hook and script are executable" '[ -x "$H/worktree-write-guard.sh" ] && [ -x "$SCOPE" ]'
shellcheck_files "shellcheck: worktree guard" "$H/worktree-write-guard.sh" "$SCOPE"

finish
