#!/usr/bin/env bash
# Suite: hooks/worktree-write-guard.sh (Claude PreToolUse, Write/Edit/NotebookEdit and Bash), the worktree check in hooks/codex-write-guard.sh,
#   and their rule script feature-workflow/scripts/check-worktree-scope.sh.
# Covers: task identified from the sub-agent transcript (<parent transcript>/subagents/agent-<id>.jsonl) launch header -> confined to
#   .workflow/.worktrees/s<NNN>_t<N>; writes to the main checkout or another task's worktree denied; temp-dir writes allowed; `..` escapes;
#   relative paths; Bash needs a leading `cd <worktree> &&`; main session, other agent types, missing transcript or worktree unaffected;
#   isolation (linked-worktree cwd) confinement; integration agents; Codex task_name from session_meta; settings wiring; shellcheck.
#   JRN-002, JRN-003: a Phase 1 implementation agent (header work_type, no task_id) and an integration agent confined to their
#   agent worktrees s007_phase_1_shell_scripts and s007_integration_shell_scripts. JRN-002 to JRN-004: the result-file command
#   read from implementation.md and integration.md starts with `cd <agent worktree> &&` (a launch-checkout placeholder fills as
#   the main checkout), passes the guard from the main checkout, and run for real leaves the file in
#   the main checkout's artifacts/<id>/, where check-task-result.sh accepts it. JRN-009: read-only commands (allowlisted reads
#   joined by | or &&) pass without the leading cd; writing or exec flags, shell forms and other commands still need it.
#   Fail closed: an implementation or integration agent whose agent worktree cannot be established (the named agent worktree
#   is missing, sub-agent transcript missing, launch header missing or not valid YAML, cwd outside any git repo) is denied every
#   call, reads and temp-dir writes included, with a reason naming the cause; JRN-002 an isolation (linked-worktree cwd) launch
#   with its agent worktree missing or not named stays confined to its cwd worktree; a payload that is not a JSON object, and a
#   PATH without jq, get a deny JSON; JRN-004 check-worktree-scope.sh --confined exits 2 when no root is found and exit 0 without
#   it, so the Codex guard is unchanged; JRN-005 deny and allow messages, both scripts' # File: lines and --help say "agent
#   worktree" and name the Phase 1 and integration shapes, and implementation-orchestrator.md says a missing agent worktree is
#   denied; JRN-006 a `$` or backtick inside single quotes passes the read-only check, and one outside them, a backslash or an
#   unterminated quote still needs the cd.
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
# judge NAME allow|deny [REASON_REGEX] : passes when the last guard run (out, rc) made that decision; allow means exit 0 and no output.
judge() {
  if [ "$2" = allow ]; then
    if [ "$rc" = 0 ] && [ -z "$out" ]; then ok "$1"; else ko "$1" "rc=$rc out=$out"; fi
  elif [ "$rc" = 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" 2>/dev/null)" = deny ]; then
    if [ -z "${3:-}" ] || reason | grep -Eq -- "$3"; then ok "$1"; else ko "$1" "reason lacks /$3/: $(reason)"; fi
  else ko "$1" "rc=$rc out=$out"; fi
}
expect() { guard "$3"; judge "$1" "$2" "${4:-}"; } # name allow|deny payload [reason-regex]

# The cause each deny reason must name when an agent's worktree cannot be established.
WORKTREE_MISSING='(does not exist|missing|not found)'
TRANSCRIPT_MISSING='transcript.*(not found|missing|does not exist)'
HEADER_NOT_PARSED='[Hh]eader.*(not parsed|unparsable|parse|malformed|missing|not found|invalid)|no launch header'
NOT_IN_GIT_REPO='not (in|inside) a git repo'

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
expect "JRN-001 task without a worktree on disk -> deny naming the missing worktree" deny "$(pl Write "$P/src/a.ts" "$P" "$A9")" \
  "s007_t9.*$WORKTREE_MISSING"
expect "JRN-001 sub-agent transcript missing -> deny naming the transcript" deny "$(pl Write "$P/src/a.ts" "$P" "$NOTR")" "$TRANSCRIPT_MISSING"
expect "other agent type (fact-lookup) -> allow" allow "$(pl Write "$P/src/a.ts" "$P" '{"agent_id":"a3","agent_type":"fact-lookup"}')"
ATP=$(jq -cn --arg t "$TR/sess/subagents/agent-a3.jsonl" '{agent_id:"q",agent_type:"implementation",agent_transcript_path:$t}')
expect "agent_transcript_path in the payload is used when present" deny "$(pl Write "$P/src/a.ts" "$P" "$ATP")"

echo "== Claude: isolation and integration (linked-worktree cwd)"
expect "JRN-002 isolation agent (agent worktree missing) write in its cwd worktree -> allow" allow "$(pl Write "$ISO/src/a.ts" "$ISO" "$A9")"
expect "JRN-002 isolation agent (agent worktree missing) write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$ISO" "$A9")" "agent-iso"
expect "JRN-002 integration agent write to the main checkout -> deny" deny "$(pl Write "$P/src/core.ts" "$ISO" "$AI")"
expect "JRN-002 integration agent write in its worktree -> allow" allow "$(pl Write "$ISO/src/core.ts" "$ISO" "$AI")"
mk_sub nohdr $'Build T5. This prompt carries no launch header.'
NOHEADER='{"agent_id":"nohdr","agent_type":"implementation"}'
expect "JRN-002 isolation agent with no launch header: write in its cwd worktree -> allow" allow "$(pl Write "$ISO/src/a.ts" "$ISO" "$NOHEADER")"
expect "JRN-002 isolation agent with no launch header: write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$ISO" "$NOHEADER")" "agent-iso"

echo "== Claude: an agent whose worktree cannot be established is denied every call (JRN-001)"
mk_sub badyaml $'```yaml launch-header\ntask_type: implementation\nspec_dir: [unclosed\n```\n\nBuild T5.'
BADHEADER='{"agent_id":"badyaml","agent_type":"implementation"}'
# unconfinable_journey LABEL AGENT_JSON CAUSE_REGEX : from the main checkout, a write there, a write to a temp dir, a read and a
#   redirecting Bash command are each denied with a reason matching CAUSE_REGEX.
unconfinable_journey() {
  local label=$1 agent=$2 cause=$3
  expect "JRN-001 $label: Write to the main checkout -> deny naming the cause" deny "$(pl Write "$P/src/a.ts" "$P" "$agent")" "$cause"
  expect "JRN-001 $label: Write to a temp dir outside the repo -> deny naming the cause" deny \
    "$(pl Write "$WORK/scratch.txt" "$P" "$agent")" "$cause"
  expect "JRN-001 $label: read-only Bash 'cat f' -> deny naming the cause" deny "$(pl Bash 'cat f' "$P" "$agent")" "$cause"
  expect "JRN-001 $label: Bash 'ls -la > x' -> deny naming the cause" deny "$(pl Bash 'ls -la > x' "$P" "$agent")" "$cause"
}
unconfinable_journey "task agent whose worktree s007_t9 is missing" "$A9" "s007_t9.*$WORKTREE_MISSING"
unconfinable_journey "task agent whose sub-agent transcript is missing" "$NOTR" "$TRANSCRIPT_MISSING"
unconfinable_journey "task agent whose first message has no launch header" "$NOHEADER" "$HEADER_NOT_PARSED"
unconfinable_journey "task agent whose launch header is not valid YAML" "$BADHEADER" "$HEADER_NOT_PARSED"
unconfinable_journey "integration agent whose worktree s007_integration_web is missing" "$AI" "s007_integration_web.*$WORKTREE_MISSING"
OUTSIDE=$WORK/outside-any-repo
mkdir -p "$OUTSIDE"
expect "JRN-001 task agent whose cwd is outside any git repo: Write there -> deny naming the cause" deny \
  "$(pl Write "$OUTSIDE/a.ts" "$OUTSIDE" "$A3")" "$NOT_IN_GIT_REPO"
expect "JRN-001 task agent whose cwd is outside any git repo: Bash 'cat f' -> deny naming the cause" deny \
  "$(pl Bash 'cat f' "$OUTSIDE" "$A3")" "$NOT_IN_GIT_REPO"

echo "== Claude: Bash"
expect "task agent Bash with cd <worktree> && -> allow" allow "$(pl Bash "cd $W3 && git status" "$P" "$A3")"
expect "task agent Bash with quoted cd into a subdir -> allow" allow "$(pl Bash "cd \"$W3/src\" && ls" "$P" "$A3")"
expect "task agent Bash without cd -> deny" deny "$(pl Bash 'npm test' "$P" "$A3")" "cd .*s007_t3 &&"
expect "task agent Bash cd to the main checkout -> deny" deny "$(pl Bash "cd $P && ls" "$P" "$A3")" "outside the worktree"
expect "task agent Bash cd to another worktree -> deny" deny "$(pl Bash "cd $W4 && ls" "$P" "$A3")"
expect "task agent Bash cd \$VAR -> deny (not literal)" deny "$(pl Bash 'cd "$WT" && ls' "$P" "$A3")" "not a literal path"
expect "task agent Bash 'cd dir; cmd' -> deny (needs &&)" deny "$(pl Bash "cd $W3; ls" "$P" "$A3")"
expect "task agent Bash whose cwd is already its worktree -> allow" allow "$(pl Bash 'ls' "$W3" "$A3")"
expect "JRN-001 task agent without a worktree: Bash -> deny naming the missing worktree" deny "$(pl Bash 'ls' "$P" "$A9")" \
  "s007_t9.*$WORKTREE_MISSING"

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
for cmd in 'jq -r .a f.json' 'jq -s . f.json' "yq -P '.a' f.yaml" "rg --pre-glob '*.gz' x src" 'git status --short && ls -la'; do
  expect "JRN-009 task agent read-only edge '$cmd' from the main checkout -> allow" allow "$(pl Bash "$cmd" "$P" "$A3")"
done
for cmd in 'cat src/a.ts |' '| cat src/a.ts' 'cat src/a.ts &&' 'cat src/a.ts && && ls' 'cat src/a.ts |& head' 'git -C src log' \
  "yq -s '.a' f.yaml" "yq --split-exp '.a' f.yaml" "yq --inplace '.a = 1' f.yaml" "sed -n '1p' --in-place src/a.ts" \
  "sed -n 'w/tmp/out.txt' src/a.ts" "sed -n 's/a/b/w out.txt' src/a.ts" 'find . -fprint0 out.txt' $'cat src/a.ts\r'; do
  expect "JRN-009 task agent edge '${cmd//$'\r'/ CR}' without cd -> deny with the cd hint" deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
done
for cmd in "sed -n 'wout.txt' src/a.ts" "sed -n '1wout.txt' src/a.ts" "sed -n '1,5wout.txt' src/a.ts" "sed -n '/x/,/y/Wout.txt' src/a.ts" \
  "sed -n '1{p}wout.txt' src/a.ts" "sed -n '/x/{wout.txt' src/a.ts" "sed -n '1!wout.txt' src/a.ts" \
  "sed -n '1 wout.txt' src/a.ts" "sed -n 's/a/b/wout.txt' src/a.ts" "sed -n 's/a/b/gpWout.txt' src/a.ts" "sed -n -e 1wout.txt src/a.ts"; do
  expect "JRN-009 task agent sed write with the file name attached '$cmd' without cd -> deny with the cd hint" deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
done
for cmd in "sed -n 'sxaxbxwout.txt' f" "sed -n '\\xaxwout.txt' f" 'sed -n -f script.sed f' "sed -n '1e touch x' f" \
  "sed -n '/[/]wout.txt/p' f" "sed -n 1p -i f" "sed -n '1p' 'f' -e '1wout.txt'"; do
  expect "JRN-009 task agent sed script that is not only addresses and p '$cmd' without cd -> deny with the cd hint" deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
done
for cmd in "sed -n '/w/p' f" "sed -n '1,5p' src/view.ts" "sed -n -e '1p' -e '5p' f" "sed -n '/a b/,/c/!p' words.txt" 'sed -nE 3p f'; do
  expect "JRN-009 task agent sed print-only script '$cmd' from the main checkout -> allow" allow "$(pl Bash "$cmd" "$P" "$A3")"
done

echo "== Claude: \$ and backticks inside single quotes in read-only commands (JRN-006)"
for cmd in "sed -n '\$p' f" "sed -n -e '1p' -e '\$p' f" "grep 'x\$' f" "grep 'a' f | tail -n 1" "grep '\`' f"; do
  expect "JRN-006 task agent read-only '$cmd' (\$ or backtick only inside single quotes) from the main checkout -> allow" allow \
    "$(pl Bash "$cmd" "$P" "$A3")"
done
for cmd in 'grep "x$" f' 'cat $HOME/f' 'grep \$ f' 'grep `id` f' "grep 'a'\\''\$' f" "grep 'x\$ f"; do
  expect "JRN-006 task agent '$cmd' (\$, backtick or backslash outside single quotes, or an open quote) without cd -> deny with the cd hint" \
    deny "$(pl Bash "$cmd" "$P" "$A3")" "cd .*s007_t3 &&"
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
      *launched*) value=$P ;; # agents launch without isolation from the main checkout
      *worktree* | *checkout*) value=$2 ;;
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
  check "$jrn $label: the command's leading cd names the agent worktree, not the launch or main checkout" \
    '[[ "$FILLED" == "cd $wt && "* ]]' "command: ${FILLED%%$'\n'*}"
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
mk_sub bad $'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-_bad\ntask_id: T1\nwork_type: web\n```\n\nBuild T1.'
expect "JRN-002 (T1) task agent whose spec folder the worktree name rule rejects: write to the main checkout -> deny naming the reason" \
  deny "$(pl Write "$P/src/a.ts" "$P" '{"agent_id":"bad","agent_type":"implementation"}')" "spec dir must be a folder named NNN-slug: .workflow/specs/007-_bad"

result_journey JRN-003 "integration agent" "$AIG" "$INTEG_DOC" integration.yaml integration-shell-scripts "$WIG" \
  "$(integration_result "$WIG")"
expect "JRN-003 integration agent write inside its agent worktree -> allow" allow "$(pl Write "$WIG/.agents/lib/x.sh" "$P" "$AIG")"
expect "JRN-003 integration agent write to the main checkout -> deny" deny "$(pl Write "$P/src/a.ts" "$P" "$AIG")" "s007_integration_shell_scripts"
expect "JRN-003 integration agent write to another agent worktree -> deny" deny "$(pl Write "$WP1/x.sh" "$P" "$AIG")" "s007_integration_shell_scripts"
expect "JRN-003 integration agent Bash write without cd -> deny with the cd hint" deny "$(pl Bash 'touch src/x' "$P" "$AIG")" "cd .*s007_integration_shell_scripts &&"

result_journey JRN-004 "Phase 3 task agent" "$A3" "$IMPL_DOC" implementation.yaml T3 "$W3" "$(implementation_result T3 "$W3")"

echo "== fail closed (JRN-003)"
for payload in 'not json' '[1,2]'; do
  guard "$payload"
  judge "JRN-003 payload '$payload' that is not a JSON object -> deny JSON, exit 0" deny
done
NOJQ=$WORK/bin-without-jq
mkdir -p "$NOJQ"
for tool in bash git cat head tail mktemp rm rmdir dirname basename mkdir tr sed awk grep env ls cp mv ln wc sort cut readlink uname date; do
  tool_path=$(command -v "$tool" 2>/dev/null) || continue
  case "$tool_path" in /*) ln -s "$tool_path" "$NOJQ/$tool" ;; esac
done
check "JRN-003 fixture: the jq-less PATH has bash and git but no jq" \
  '[ -x "$NOJQ/bash" ] && [ -x "$NOJQ/git" ] && ! (PATH=$NOJQ; command -v jq >/dev/null 2>&1)'
# The hook may exit before reading stdin, so the payload comes from a file: a pipe would let the writer die of SIGPIPE.
pl Write "$P/src/a.ts" "$P" "$A3" > "$WORK/nojq.json"
out=$(cd "$P" && env PATH="$NOJQ" "$NOJQ/bash" "$H/worktree-write-guard.sh" < "$WORK/nojq.json" 2>/dev/null); rc=$?
judge "JRN-003 jq not on PATH, workflow installed -> static deny JSON naming jq, exit 0" deny 'jq'
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
eq "JRN-004 cwd outside any repo without --confined -> allow" "$rc" 0
# scope ARGS... : runs check-worktree-scope.sh; sets scope_rc, scope_out (stdout) and scope_err (stderr).
scope() {
  scope_rc=0
  scope_out=$(bash "$SCOPE" "$@" 2>"$WORK/scope-err") || scope_rc=$?
  scope_err=$(cat "$WORK/scope-err")
}
scope --cwd "$P" --worktree-name s007_t9 --path "$P/a" --confined
check "JRN-004 --confined, agent worktree missing -> exit 2 with a reason on stderr" '[ "$scope_rc" = 2 ] && [ -n "$scope_err" ]' \
  "rc=$scope_rc err=$scope_err"
scope --cwd "$P" --worktree-name s007_t9 --path "$P/a"
eq "JRN-004 agent worktree missing, not --confined -> exit 0 as before" "$scope_rc" 0
scope --cwd "$P" --path "$P/a" --confined
check "JRN-004 --confined with no --worktree-name, main-checkout cwd -> exit 2 with a reason on stderr" \
  '[ "$scope_rc" = 2 ] && [ -n "$scope_err" ]' "rc=$scope_rc err=$scope_err"
scope --cwd "$WORK" --worktree-name s007_t3 --path "$WORK/a" --confined
check "JRN-004 --confined, cwd outside any repo -> exit 2 naming the cause" \
  '[ "$scope_rc" = 2 ] && grep -Eq "$NOT_IN_GIT_REPO" <<<"$scope_err"' "rc=$scope_rc err=$scope_err"
scope --cwd "$ISO" --worktree-name s007_t9 --path "$ISO/a" --confined
eq "JRN-004 --confined, agent worktree missing, cwd in a linked worktree -> exit 0 (confined to it)" "$scope_rc" 0

echo "== agent worktree wording (JRN-005)"
# deny_wording LABEL ARGS... : the scope check denies with a reason that says "agent worktree" and never "task worktree".
deny_wording() {
  local label=$1
  shift
  scope "$@"
  check "JRN-005 $label -> deny reason says agent worktree, not task worktree" \
    '[ "$scope_rc" = 2 ] && grep -qi "agent worktree" <<<"$scope_err" && ! grep -qi "task worktree" <<<"$scope_err"' \
    "rc=$scope_rc err=$scope_err"
}
deny_wording "write outside the worktree" --cwd "$P" --worktree-name s007_t3 --path "$P/src/a.ts"
deny_wording "Bash without a leading cd" --cwd "$P" --worktree-name s007_t3 --command 'npm test'
deny_wording "cd to a path that is not literal" --cwd "$P" --worktree-name s007_t3 --command 'cd "$WT" && npm test'
deny_wording "cd to a relative path" --cwd "$P" --worktree-name s007_t3 --command 'cd src && npm test'
deny_wording "cd outside the worktree" --cwd "$P" --worktree-name s007_t3 --command "cd $P && npm test"
deny_wording "--confined with no confinement root" --cwd "$P" --worktree-name s007_t9 --path "$P/src/a.ts" --confined
# allow_wording LABEL ARGS... : the scope check allows with a message that never says "task worktree".
allow_wording() {
  local label=$1
  shift
  scope "$@"
  check "JRN-005 $label -> allow message never says task worktree" '[ "$scope_rc" = 0 ] && ! grep -qi "task worktree" <<<"$scope_out"' \
    "rc=$scope_rc out=$scope_out"
}
allow_wording "agent worktree missing, not --confined" --cwd "$P" --worktree-name s007_t9 --path "$P/src/a.ts"
allow_wording "write inside the worktree" --cwd "$P" --worktree-name s007_t3 --path "$W3/a.ts"
allow_wording "Bash with cd into the worktree" --cwd "$P" --worktree-name s007_t3 --command "cd $W3 && npm test"
allow_wording "read-only command" --cwd "$P" --worktree-name s007_t3 --command 'cat f'
for script in "$SCOPE" "$H/worktree-write-guard.sh"; do
  file_line=$(sed -n 2p "$script")
  check "JRN-005 ${script##*/}: the # File: line never says task worktree" \
    '[[ "$file_line" == "# File:"* ]] && ! grep -qi "task worktree" <<<"$file_line"' "$file_line"
done
scope_help=$(bash "$SCOPE" --help 2>&1)
for shape in 's<NNN>_t<N>' 's<NNN>_phase_1_' 's<NNN>_integration_'; do
  check "JRN-005 check-worktree-scope.sh --help names the agent worktree shape $shape" 'grep -qF -- "$shape" <<<"$scope_help"' \
    "--help lacks $shape: $(grep -F -- '--worktree-name' <<<"$scope_help")"
done
# One sentence must hold all three phrases: the doc already has separate sentences about the stop audit's warning for a
#   missing worktree and about agents that keep getting denied, and neither says a missing worktree is denied.
# shellcheck disable=SC2034  # read inside the eval'd check string below
missing_worktree_denied=$(awk '{
    n = split($0, sentences, /\. /)
    for (i = 1; i <= n; i++) {
      s = tolower(sentences[i])
      if (s ~ /agent worktree/ && s ~ /missing/ && s ~ /denied|denies/) print NR ": " sentences[i]
    }
  }' "$P/.agents/skills/feature-workflow/modules/implementation-orchestrator.md")
check "JRN-005 implementation-orchestrator.md says a confined agent whose agent worktree is missing is denied" \
  '[ -n "$missing_worktree_denied" ]' "no sentence names a missing agent worktree as denied"

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
cexpect() { cguard "$3"; judge "$1" "$2" "${4:-}"; } # name allow|deny payload [regex]
cexpect "Codex task agent: patch inside its worktree (relative) -> allow" allow "$(wp "$(add .workflow/.worktrees/s007_t3/src/a.ts)" "$WORK/rollout-t3.jsonl")"
cexpect "Codex task agent: patch in the main checkout -> deny" deny "$(wp "$(add src/a.ts)" "$WORK/rollout-t3.jsonl")" "src/a.ts: worktree guard"
cexpect "Codex task agent: patch in another worktree -> deny" deny "$(wp "$(add "$W4/a.ts")" "$WORK/rollout-t3.jsonl")"
cexpect "JRN-004 Codex task agent without a worktree -> allow (Codex unchanged)" allow "$(wp "$(add src/a.ts)" "$WORK/rollout-t9.jsonl")"
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
