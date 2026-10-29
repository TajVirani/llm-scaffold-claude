#!/usr/bin/env bash
# Suite: hooks/worktree-write-guard.sh (Claude PreToolUse, Write/Edit/NotebookEdit and Bash), the worktree check in hooks/codex-write-guard.sh,
#   and their rule script feature-workflow/scripts/check-worktree-scope.sh.
# Covers: task identified from the sub-agent transcript (<parent transcript>/subagents/agent-<id>.jsonl) launch header -> confined to
#   .workflow/.worktrees/s<NNN>_t<N>; writes to the main checkout or another task's worktree denied; temp-dir writes allowed; `..` escapes;
#   relative paths; Bash needs a leading `cd <worktree> &&`; main session, other agent types, missing transcript or worktree unaffected;
#   isolation (linked-worktree cwd) confinement; integration agents; Codex task_name from session_meta; settings wiring; shellcheck.
#   JRN-002, JRN-003: a Phase 1 implementation agent (header work_type, no task_id) and an integration agent confined to their
#   agent worktrees s007_phase_1_shell_scripts and s007_integration_shell_scripts. JRN-002 to JRN-004: the result-file command
#   read from implementation.md and integration.md passes the guard from the main checkout, and run for real leaves the file in
#   the main checkout's artifacts/<id>/, where check-task-result.sh accepts it. JRN-009: read-only commands (allowlisted reads
#   joined by | or &&) pass without the leading cd; writing or exec flags, shell forms and other commands still need it.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/result-briefs.sh
source "$TESTS_DIR/fixtures/result-briefs.sh"
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
# Agent worktrees for a Phase 1 build and an integration batch, created the way the orchestrator creates them.
git -C "$P" worktree add -q .workflow/.worktrees/s007_phase_1_shell_scripts -b wf/007-demo/s007_phase_1_shell_scripts
git -C "$P" worktree add -q .workflow/.worktrees/s007_integration_shell_scripts -b wf/007-demo/s007_integration_shell_scripts
WP1=$P/.workflow/.worktrees/s007_phase_1_shell_scripts
WIG=$P/.workflow/.worktrees/s007_integration_shell_scripts

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
mk_sub p1 $'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-demo\nwork_type: shell-scripts\n```\n\nBuild the harness.'
mk_sub ig $'```yaml launch-header\ntask_type: integration\nspec_dir: .workflow/specs/007-demo\nwork_type: shell-scripts\n```\n\nBatch.'

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
AP1='{"agent_id":"p1","agent_type":"implementation"}'
AIG='{"agent_id":"ig","agent_type":"integration"}'

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
expect "task agent Bash without cd -> deny" deny "$(pl Bash 'npm test' "$P" "$A3")" "cd .*s007_t3 &&"
expect "task agent Bash cd to the main checkout -> deny" deny "$(pl Bash "cd $P && ls" "$P" "$A3")" "outside the worktree"
expect "task agent Bash cd to another worktree -> deny" deny "$(pl Bash "cd $W4 && ls" "$P" "$A3")"
expect "task agent Bash cd \$VAR -> deny (not literal)" deny "$(pl Bash 'cd "$WT" && ls' "$P" "$A3")" "not a literal path"
expect "task agent Bash 'cd dir; cmd' -> deny (needs &&)" deny "$(pl Bash "cd $W3; ls" "$P" "$A3")"
expect "task agent Bash whose cwd is already its worktree -> allow" allow "$(pl Bash 'ls' "$W3" "$A3")"
expect "task agent without a worktree: Bash -> allow" allow "$(pl Bash 'ls' "$P" "$A9")"

echo "== Claude: read-only commands without cd (JRN-009)"
for cmd in 'cat src/a.ts' 'head -n 5 src/a.ts' 'tail -n 5 src/a.ts' 'grep -n x src/a.ts' 'rg x src' 'ls src' 'wc -l src/a.ts' \
  "sed -n '1,5p' src/a.ts" "find . -name '*.ts'" 'git log --oneline -3' 'git show HEAD' 'git diff HEAD' 'git status' \
  "yq '.a' f.yaml" "jq '.a' f.json" 'cat src/a.ts | head' 'grep x src/a.ts && wc -l src/a.ts' \
  'git log --oneline | grep fix | head -n 3'; do
  expect "JRN-009 task agent read-only '$cmd' from the main checkout -> allow" allow "$(pl Bash "$cmd" "$P" "$A3")"
done
for cmd in "sed -i 's/a/b/' src/a.ts" "sed -n 'w out.txt' src/a.ts" "sed -n '/x/W out.txt' src/a.ts" 'find . -delete' \
  'find . -exec rm {} +' 'find . -execdir rm {} +' 'find . -ok rm {} +' 'find . -okdir rm {} +' 'find . -fprint out.txt' \
  "find . -fprintf out.txt '%p'" 'find . -fls out.txt' "yq -i '.a = 1' f.yaml" "jq -i '.a' f.json" 'git diff --output=out.txt' \
  'git log --output=out.txt' 'rg --pre cat x' 'rg --pre=cat x'; do
  expect "JRN-009 task agent '$cmd' (writing or exec flag) without cd -> deny with the cd hint" deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
done
NEWLINE=$'\n'
for cmd in 'cat $(echo src/a.ts)' 'cat `echo src/a.ts`' 'cat $HOME/a' 'cat <(echo x)' 'cat < src/a.ts' 'cat src/a.ts > out.txt' \
  'cat src/a.ts >> out.txt' 'cat src/a.ts; ls' 'cat src/a.ts & ls' 'cat src/a.ts || ls' $'cat src/a.ts\nls' 'cat src/a.ts | tee out.txt'; do
  expect "JRN-009 task agent shell form '${cmd//$NEWLINE/ NEWLINE }' without cd -> deny with the cd hint" deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
done
for cmd in 'echo x > src/a.ts' 'rm src/a.ts' "sed 's/a/b/' src/a.ts" 'cat src/a.ts | xargs rm' 'grep x src/a.ts && rm src/a.ts' \
  'git commit -m x' 'git checkout main'; do
  expect "JRN-009 task agent '$cmd' (not only allowlisted reads) without cd -> deny with the cd hint" deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
done

echo "== Claude: result files from the briefs (JRN-002, JRN-003, JRN-004)"
UNKNOWN_PLACEHOLDERS="" FILLED=""
# fill_placeholders TEXT AGENT_WORKTREE RESULT_ID : sets FILLED to TEXT with each <placeholder> replaced by the fixture value it
#   names; a placeholder the suite does not know is kept and added to UNKNOWN_PLACEHOLDERS (globals: a subshell would lose them).
fill_placeholders() {
  local rest=$1 out="" key lower value re='^([^<]*)<([^<>]+)>(.*)$'
  while [[ "$rest" =~ $re ]]; do
    out+=${BASH_REMATCH[1]}
    key=${BASH_REMATCH[2]}
    rest=${BASH_REMATCH[3]}
    lower=$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
      *main*) value=$P ;;
      *spec_dir* | *"spec dir"*) value=.workflow/specs/007-demo ;;
      *task_id* | *"task id"*) value=$3 ;;
      *work_type* | *"work type"*) value=shell-scripts ;;
      *worktree* | *checkout* | *launched*) value=$2 ;;
      *) value="<$key>" UNKNOWN_PLACEHOLDERS="$UNKNOWN_PLACEHOLDERS <$key>" ;;
    esac
    out+=$value
  done
  FILLED=$out$rest
}
# implementation_result ID WORKTREE : a result block check-task-result.sh accepts for ID.
implementation_result() {
  printf '%s\n' 'status: done' 'summary: "Fixture result."' "task_id: $1" "worktree: $2" 'branch: wf/007-demo/fixture' \
    'base_commit: "1a2b3c4d"' 'head_commit: "9f8e7d6c"' 'files_changed: [tests/x.sh]' 'tests_added:' \
    '  - {file: tests/x.sh, test: a case, kind: behaviour}' 'evidence:' "  toolchain: artifacts/$1/toolchain.txt (pass)" \
    'considered_not_built: []' 'profile_wrong: null' 'scope_expansion: null' 'blocked: null' 'discovered_work: []'
}
# integration_result WORKTREE : an integration block check-task-result.sh accepts.
integration_result() {
  printf '%s\n' 'status: done' 'summary: "Fixture batch."' 'work_type: shell-scripts' "worktree: $1" \
    'branch: wf/007-demo/s007_integration_shell_scripts' 'base_commit: "1a2b3c4"' 'head_commit: "5d6e7f8a"' 'requests:' \
    '  - n: 1' '    verdict: applied' '    reason: "adds a helper"' 'files_changed: [.agents/lib/workflow-paths.sh]' 'evidence:' \
    '  toolchain: artifacts/integration-shell-scripts/toolchain.txt (pass)' 'profile_wrong: null' 'blocked: null' 'discovered_work: []'
}
# result_journey JRN AGENT_LABEL AGENT_JSON DOC FILE_NAME RESULT_ID WORKTREE BODY : the brief's command passes the guard from the
#   main checkout, and run for real leaves a file check-task-result.sh accepts in the main checkout and none in the worktree copy.
result_journey() {
  local jrn=$1 label=$2 agent=$3 doc=$4 file=$5 id=$6 wt=$7 body=$8 opening cmd landed copy
  opening=$(brief_result_command "$doc" "$file")
  check "$jrn $label: ${doc##*/} has a result-file command for $file" '[ -n "$opening" ]'
  UNKNOWN_PLACEHOLDERS=""
  fill_placeholders "$opening" "$wt" "$id"
  cmd="$FILLED"$'\n'"$body"$'\nEOF'
  eq "$jrn $label: every placeholder in the command names a known value" "$UNKNOWN_PLACEHOLDERS" ""
  expect "$jrn $label: the brief's result-file command from the main checkout -> allow" allow "$(pl Bash "$cmd" "$P" "$agent")"
  landed=$P/.workflow/specs/007-demo/artifacts/$id/$file
  copy=$wt/.workflow/specs/007-demo/artifacts/$id/$file
  rm -f "$landed" "$copy"
  (cd "$P" && bash -c "$cmd") >/dev/null 2>&1
  check "$jrn $label: the command leaves $file in the main checkout's artifacts/$id/" '[ -f "$landed" ]'
  check "$jrn $label: the command leaves no $file in the worktree copy" '[ ! -e "$copy" ]'
  t "$jrn $label: check-task-result.sh accepts the file" 0 bash "$P/.agents/skills/feature-workflow/scripts/check-task-result.sh" "$landed"
}
IMPL_DOC=$P/.agents/agents/implementation.md
INTEG_DOC=$P/.agents/agents/integration.md

result_journey JRN-002 "Phase 1 agent" "$AP1" "$IMPL_DOC" implementation.yaml phase-1-shell-scripts "$WP1" \
  "$(implementation_result phase-1-shell-scripts "$WP1")"
expect "JRN-002 Phase 1 agent write inside its agent worktree -> allow" allow "$(pl Write "$WP1/tests/x.sh" "$P" "$AP1")"
expect "JRN-002 Phase 1 agent write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$P" "$AP1")" "s007_phase_1_shell_scripts"
expect "JRN-002 Phase 1 agent write to another agent worktree -> deny" deny "$(pl Write "$W3/src/a.ts" "$P" "$AP1")" "s007_phase_1_shell_scripts"
expect "JRN-002 Phase 1 agent Bash write without cd -> deny with the cd hint" deny "$(pl Bash 'touch src/x' "$P" "$AP1")" "cd .*s007_phase_1_shell_scripts &&"

result_journey JRN-003 "integration agent" "$AIG" "$INTEG_DOC" integration.yaml integration-shell-scripts "$WIG" \
  "$(integration_result "$WIG")"
expect "JRN-003 integration agent write inside its agent worktree -> allow" allow "$(pl Write "$WIG/.agents/lib/x.sh" "$P" "$AIG")"
expect "JRN-003 integration agent write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$P" "$AIG")" "s007_integration_shell_scripts"
expect "JRN-003 integration agent write to another agent worktree -> deny" deny "$(pl Write "$WP1/x.sh" "$P" "$AIG")" "s007_integration_shell_scripts"
expect "JRN-003 integration agent Bash write without cd -> deny with the cd hint" deny "$(pl Bash 'touch src/x' "$P" "$AIG")" "cd .*s007_integration_shell_scripts &&"

result_journey JRN-004 "Phase 3 task agent" "$A3" "$IMPL_DOC" implementation.yaml T3 "$W3" "$(implementation_result T3 "$W3")"

echo "== fail closed"
out=$(printf 'not json' | (cd "$P" && bash "$H/worktree-write-guard.sh" 2>/dev/null)); rc=$?
check "unparsable payload -> allow silently (main-session safe)" '[ $rc -eq 0 ] && [ -z "$out" ]' "rc=$rc out=$out"
N=$WORK/noflow
mkdir -p "$N/.agents/hooks" && cp "$H/worktree-write-guard.sh" "$N/.agents/hooks/"
# The hook exits before reading stdin here, so the payload comes from a file: a pipe would let the writer die of SIGPIPE.
pl Write "$P/src/a.ts" "$P" "$A3" > "$WORK/noflow.json"
out=$(bash "$N/.agents/hooks/worktree-write-guard.sh" < "$WORK/noflow.json" 2>/dev/null); rc=$?
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
# shellcheck disable=SC2034  # TPL is read inside the eval-ed check strings below
TPL=$P/.agents/hooks/claude-settings.template.json
check "template: PreToolUse Bash|Write|Edit|NotebookEdit runs worktree-write-guard.sh" \
  'jq -e "[.hooks.PreToolUse[] | select(.matcher == \"Bash|Write|Edit|NotebookEdit\") | .hooks[].command] | any(test(\"hooks/worktree-write-guard.sh\"))" "$TPL" >/dev/null'
check "manifest ships the hook and the feature-workflow skill (rule script)" 'grep -qx "hooks/worktree-write-guard.sh" "$P/.agents/install-manifest.txt" && grep -qx "skills/feature-workflow" "$P/.agents/install-manifest.txt"'
check "hook and script are executable" '[ -x "$H/worktree-write-guard.sh" ] && [ -x "$SCOPE" ]'
shellcheck_files "shellcheck: worktree guard" "$H/worktree-write-guard.sh" "$SCOPE"

finish
