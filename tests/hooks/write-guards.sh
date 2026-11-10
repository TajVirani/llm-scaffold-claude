#!/usr/bin/env bash
# Suite: hooks/workflow-write-guard.sh: the thin PreToolUse adapter over feature-workflow/scripts/check-write.sh.
# Covers: one check-write.sh call per write, covering spec-class and Tier A paths alike; the settings template
#   wires it as the one write hook; main session vs sub-agent (agent_id), Write / Edit / NotebookEdit payloads, status edits denied through the
#   proposed-content check, Tier A steps and glossary / profile rules, the review-lessons file at 5.7 only (JRN-004),
#   worktree cwd, CLAUDE_PROJECT_DIR fallback, fail-closed on bad payload / no jq (static deny) / failure before a decision / no yq / non-repo cwd,
#   and silence in a project that does not have the workflow installed.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
H=$P/.agents/hooks
ST="$P/.agents/skills/feature-workflow/scripts/status-transition.sh"
TPL="$P/.agents/skills/feature-workflow/assets"

mkdir -p "$P/.workflow/specs/001-demo" "$P/.workflow/specs/work-backlog" "$P/.workflow/profiles" "$P/.workflow/decisions/adr" "$P/src"
cp "$TPL/spec.md" "$P/.workflow/specs/001-demo/spec.md"
cp "$TPL/tasks.md" "$P/.workflow/specs/001-demo/tasks.md"
echo '# glossary' > "$P/.workflow/GLOSSARY.md"
echo '# rules' > "$P/.workflow/rules.md"
echo '# profile' > "$P/.workflow/profiles/frontend.md"
echo '.workflow/specs/*/.step' > "$P/.gitignore"
git_commit_all "$P" fixture
git -C "$P" worktree add -q .claude/worktrees/agent-x -b wt-x
WT=$P/.claude/worktrees/agent-x

# at STEP : move the demo spec's step marker (status-transition.sh is the only legal writer).
at() { "$ST" step .workflow/specs/001-demo "$1" --cwd "$P" >/dev/null 2>&1 || echo "setup failed: step $1" >&2; }
"$ST" status .workflow/specs/001-demo draft --cwd "$P" >/dev/null 2>&1

# payload TOOL PATH [CWD] [EXTRA_JSON]: PreToolUse payload for a main-session call; EXTRA merges into the top level.
payload() {
  local tool=$1 path=$2 cwd=${3:-$P} extra=${4:-}
  [ -n "$extra" ] || extra='{}'
  jq -cn --arg tool "$tool" --arg p "$path" --arg c "$cwd" --argjson x "$extra" '
    {session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"PreToolUse",tool_name:$tool,tool_use_id:"u",
     tool_input:(if $tool=="NotebookEdit" then {notebook_path:$p,new_source:"x"} else {file_path:$p,content:"x"} end)} + $x'
}
SUB='{"agent_id":"a1","agent_type":"implementation"}'

# guard NAME PAYLOAD : run a guard hook; sets out (stdout) and rc.
guard() { out=$(printf '%s' "$2" | (cd "$P" && bash "$H/$1.sh" 2>/dev/null)); rc=$?; }
is_deny() { [ "$rc" = 0 ] && jq -e '.hookSpecificOutput.hookEventName=="PreToolUse" and .hookSpecificOutput.permissionDecision=="deny"' <<<"$out" >/dev/null 2>&1; }
is_allow() { [ "$rc" = 0 ] && [ -z "$out" ]; }
reason() { jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out"; }
# expect NAME allow|deny GUARD PAYLOAD [REASON_REGEX]
expect() {
  local name=$1 want=$2 g=$3 pl=$4 pat=${5:-}
  guard "$g" "$pl"
  if [ "$want" = allow ]; then
    if is_allow; then ok "$name"; else ko "$name" "rc=$rc out=$out"; fi
  elif is_deny; then
    if [ -z "$pat" ] || reason | grep -qE -- "$pat"; then ok "$name"; else ko "$name" "reason lacks /$pat/: $(reason)"; fi
  else ko "$name" "rc=$rc out=$out"; fi
}
# Spec-class and Tier A paths go through the same hook; the two names keep each case's intent readable.
SPECG=workflow-write-guard
TIERA=workflow-write-guard

echo "== main session vs sub-agent: spec.md"
at 0.3.19
expect "spec.md at 0.3.19, main (Write, status unchanged)" allow $SPECG "$(payload Write .workflow/specs/001-demo/spec.md | jq -c --rawfile c "$P/.workflow/specs/001-demo/spec.md" '.tool_input.content=$c')"
expect "spec.md at 0.3.19, main, relative path in cwd" allow $SPECG "$(payload Write .workflow/specs/001-demo/spec.md | jq -c --rawfile c "$P/.workflow/specs/001-demo/spec.md" '.tool_input.content=$c')"
expect "spec.md at 0.3.19, absolute path (Edit of a body line)" allow $SPECG "$(payload Edit "$P/.workflow/specs/001-demo/spec.md" | jq -c '.tool_input={file_path:.tool_input.file_path,old_string:"light_path: false",new_string:"light_path: false"}')"
expect "spec.md at 0.3.19, sub-agent" deny $SPECG "$(payload Write .workflow/specs/001-demo/spec.md "$P" "$SUB")" "sub-agent|0\.3\.19|spec"
expect "spec.md at 0.3.19, sub-agent with agent_id only" deny $SPECG "$(payload Write .workflow/specs/001-demo/spec.md "$P" '{"agent_id":"a2"}')"
at 0.3.7
expect "spec.md at 0.3.7, main" deny $SPECG "$(payload Write .workflow/specs/001-demo/spec.md)"
at 0.3.19

echo "== spec.md: status edits"
orig=$(cat "$P/.workflow/specs/001-demo/spec.md")
done_content=${orig/status: draft/status: done}
expect "Write that changes status denied" deny $SPECG "$(payload Write .workflow/specs/001-demo/spec.md | jq -c --arg c "$done_content" '.tool_input.content=$c')" "status"
expect "Write that keeps status allowed" allow $SPECG "$(payload Write .workflow/specs/001-demo/spec.md | jq -c --arg c "$orig" '.tool_input.content=$c')"
expect "Edit status line draft -> done denied" deny $SPECG "$(payload Edit .workflow/specs/001-demo/spec.md | jq -c '.tool_input={file_path:".workflow/specs/001-demo/spec.md",old_string:"status: draft",new_string:"status: done"}')" "status"
expect "Edit body line allowed" allow $SPECG "$(payload Edit .workflow/specs/001-demo/spec.md | jq -c '.tool_input={file_path:".workflow/specs/001-demo/spec.md",old_string:"light_path: false",new_string:"light_path: false # edited"}')"
expect "Edit replace_all touching status denied" deny $SPECG "$(payload Edit .workflow/specs/001-demo/spec.md | jq -c '.tool_input={file_path:".workflow/specs/001-demo/spec.md",old_string:"draft",new_string:"done",replace_all:true}')"
expect "Edit blocked_condition added denied" deny $SPECG "$(payload Edit .workflow/specs/001-demo/spec.md | jq -c '.tool_input={file_path:".workflow/specs/001-demo/spec.md",old_string:"light_path: false",new_string:"light_path: false\nblocked_condition: x"}')"
expect "NotebookEdit on spec.md at 0.3.19 (no proposed check)" allow $SPECG "$(payload NotebookEdit .workflow/specs/001-demo/spec.md)"
at 0.3.7
expect "NotebookEdit on spec.md at 0.3.7 denied" deny $SPECG "$(payload NotebookEdit .workflow/specs/001-demo/spec.md)"
at 0.3.19

echo "== spec guard: other spec-class paths"
expect ".step Write denied for main" deny $SPECG "$(payload Write .workflow/specs/001-demo/.step)" "status-transition|\.step"
expect ".step Edit denied for sub-agent" deny $SPECG "$(payload Edit .workflow/specs/001-demo/.step "$P" "$SUB")"
at 2.5
expect "tasks.md at 2.5, main" allow $SPECG "$(payload Write .workflow/specs/001-demo/tasks.md)"
expect "tasks.md at 2.5, sub-agent" deny $SPECG "$(payload Write .workflow/specs/001-demo/tasks.md "$P" "$SUB")"
at 3.1
expect "tasks.md at 3.1 denied with set-task pointer" deny $SPECG "$(payload Write .workflow/specs/001-demo/tasks.md)" "set-task"
at 00.26
expect "work-backlog list at 00.26, main" allow $SPECG "$(payload Write .workflow/specs/work-backlog/001-demo.md)"
expect "work-backlog list at 00.26, sub-agent" deny $SPECG "$(payload Write .workflow/specs/work-backlog/001-demo.md "$P" "$SUB")"
expect "work-backlog misnamed item denied" deny $SPECG "$(payload Write .workflow/specs/work-backlog/notes.md)"
at 3.1
expect "work-backlog list at 3.1 denied" deny $SPECG "$(payload Write .workflow/specs/work-backlog/001-demo.md)" "00\.26"
expect "the same hook denies a Tier A path at 3.1" deny $SPECG "$(payload Write .workflow/GLOSSARY.md)" "proposals\.md"
expect "source file allowed" allow $SPECG "$(payload Write src/app.ts)"
expect "spec guard: feature without marker denied" deny $SPECG "$(payload Write .workflow/specs/004-new/spec.md)"

echo "== Tier A guard"
at 0.2.3
expect ".workflow/GLOSSARY.md at 0.2.3, main" allow $TIERA "$(payload Write .workflow/GLOSSARY.md)"
expect ".workflow/GLOSSARY.md at 0.2.3, sub-agent" deny $TIERA "$(payload Write .workflow/GLOSSARY.md "$P" "$SUB")"
expect "nested .workflow/GLOSSARY-MAP.md at 0.2.3, main" allow $TIERA "$(payload Write src/a/GLOSSARY-MAP.md)"
at 3.1
expect ".workflow/GLOSSARY.md at 3.1 denied with proposals.md pointer" deny $TIERA "$(payload Write .workflow/GLOSSARY.md)" "proposals\.md"
expect ".workflow/rules.md at 3.1 denied" deny $TIERA "$(payload Edit .workflow/rules.md)"
expect ".workflow/decisions adr at 3.1 denied" deny $TIERA "$(payload Write .workflow/decisions/adr/0001-x.md)"
at 0.3.7
expect ".workflow/rules.md at 0.3.7 allowed" allow $TIERA "$(payload Edit .workflow/rules.md)"
expect ".workflow/decisions adr at 0.3.7 allowed" allow $TIERA "$(payload Write .workflow/decisions/adr/0001-x.md)"
for s in 0.2.3 0.3.15 0.4.3; do
  at $s
  expect ".workflow/rules.md at $s denied" deny $TIERA "$(payload Edit .workflow/rules.md)" "0\.3\.7 5\.3 5\.7"
  expect ".workflow/decisions adr at $s denied" deny $TIERA "$(payload Write .workflow/decisions/adr/0001-x.md)"
done
for s in 5.3 5.7; do
  at $s
  expect ".workflow/rules.md at $s allowed" allow $TIERA "$(payload Edit .workflow/rules.md)"
  expect ".workflow/decisions adr at $s allowed" allow $TIERA "$(payload Write .workflow/decisions/adr/0001-x.md)"
done
at 0.3.7
expect ".workflow/GLOSSARY.md at 0.3.7 denied" deny $TIERA "$(payload Write .workflow/GLOSSARY.md)"
expect "existing profile at 0.3.7 denied" deny $TIERA "$(payload Write .workflow/profiles/frontend.md)"
at 5.3
expect "existing profile at 5.3 allowed" allow $TIERA "$(payload Write .workflow/profiles/frontend.md)"
expect "new profile at 5.3 allowed" allow $TIERA "$(payload Write .workflow/profiles/backend.md)"
expect "existing profile at 5.3, sub-agent denied" deny $TIERA "$(payload Write .workflow/profiles/frontend.md "$P" "$SUB")"
at 00.19
expect "new profile at 00.19 allowed" allow $TIERA "$(payload Write .workflow/profiles/backend.md)"
expect "existing profile at 00.19 denied" deny $TIERA "$(payload Write .workflow/profiles/frontend.md)" "5\.3"
expect "the same hook denies spec.md at 00.19" deny $TIERA "$(payload Write .workflow/specs/001-demo/spec.md)" "spec\.md is written only at"
expect "NotebookEdit on Tier A path follows the same rule" deny $TIERA "$(payload NotebookEdit .workflow/rules.md)"
at 0.3.7
expect "NotebookEdit on .workflow/rules.md at 0.3.7 allowed" allow $TIERA "$(payload NotebookEdit .workflow/rules.md)"

echo "== Tier A guard: JRN-004, the review-lessons file"
at 5.7
expect "JRN-004 review-lessons.md at 5.7 allowed" allow $TIERA "$(payload Write .workflow/review-lessons.md)"
for s in 0.3.7 5.3; do
  at $s
  expect "JRN-004 review-lessons.md at $s denied" deny $TIERA "$(payload Write .workflow/review-lessons.md)" "5\.7"
done

echo "== Tier A guard: no feature in flight"
yq --front-matter=process -i '.status="done"' "$P/.workflow/specs/001-demo/spec.md"
expect "no feature in flight: main allowed" allow $TIERA "$(payload Write .workflow/rules.md)"
expect "no feature in flight: sub-agent denied" deny $TIERA "$(payload Write .workflow/rules.md "$P" "$SUB")"
yq --front-matter=process -i '.status="draft"' "$P/.workflow/specs/001-demo/spec.md"

echo "== paths no guard owns"
at 5.3
expect "source file allowed" allow $TIERA "$(payload Write src/app.ts)"
expect "path outside repo allowed" allow $TIERA "$(payload Write /etc/hosts)"
expect "no path (e.g. other tool input) allowed" allow $TIERA '{"cwd":"'"$P"'","tool_name":"Write","tool_input":{}}'

echo "== worktree cwd"
at 0.3.19
expect "spec.md from worktree cwd, main session, step read from main checkout" allow $SPECG "$(payload Write "$WT/.workflow/specs/001-demo/spec.md" "$WT" | jq -c --rawfile c "$P/.workflow/specs/001-demo/spec.md" '.tool_input.content=$c')"
expect "spec.md from worktree cwd, sub-agent" deny $SPECG "$(payload Write "$WT/.workflow/specs/001-demo/spec.md" "$WT" "$SUB")"
expect "relative spec.md path resolves against worktree cwd (Edit)" allow $SPECG "$(payload Edit .workflow/specs/001-demo/spec.md "$WT" | jq -c '.tool_input={file_path:".workflow/specs/001-demo/spec.md",old_string:"light_path: false",new_string:"light_path: false"}')"
at 3.1
expect "spec.md from worktree at 3.1 denied" deny $SPECG "$(payload Write "$WT/.workflow/specs/001-demo/spec.md" "$WT")"
expect "Tier A path in worktree, sub-agent denied" deny $TIERA "$(payload Write "$WT/.workflow/rules.md" "$WT" "$SUB")"
out=$(payload Write .workflow/specs/001-demo/.step "" | jq -c 'del(.cwd)' | (cd / && CLAUDE_PROJECT_DIR="$P" bash "$H/$SPECG.sh" 2>/dev/null)); rc=$?
if is_deny; then ok "no cwd in payload: CLAUDE_PROJECT_DIR fallback"; else ko "no cwd in payload: CLAUDE_PROJECT_DIR fallback" "rc=$rc out=$out"; fi

echo "== fail closed"
guard "$SPECG" 'not json'
if is_deny && reason | grep -q 'unparsable'; then ok "invalid payload denied"; else ko "invalid payload denied" "rc=$rc out=$out"; fi
guard "$SPECG" ''
if is_deny; then ok "empty payload denied"; else ko "empty payload denied" "rc=$rc out=$out"; fi
# A PATH with the usual tools but no jq.
NOJQ=$WORK/bin-nojq
mkdir -p "$NOJQ"
for b in bash git cat sed tr grep mktemp rm dirname basename head awk env wc sort ls date find cut stat yq; do
  command -v "$b" >/dev/null 2>&1 && ln -sf "$(command -v "$b")" "$NOJQ/$b"
done
out=$(payload Write .workflow/specs/001-demo/.step | (cd "$P" && PATH="$NOJQ" "$NOJQ/bash" "$H/$SPECG.sh" 2>/dev/null)); rc=$?
# Without jq the guard cannot parse the payload; it emits a static deny (like pre-launch.sh) instead of failing open.
if is_deny && grep -q 'write guard error (denying, fail closed): jq not found' <<<"$out"; then ok "no jq: static deny (fail closed)"; else ko "no jq: static deny (fail closed)" "rc=$rc out=$out"; fi
out=$(payload Write .workflow/GLOSSARY.md | (cd "$P" && PATH="$NOJQ" "$NOJQ/bash" "$H/$TIERA.sh" 2>/dev/null)); rc=$?
if is_deny; then ok "Tier A path, no jq: static deny"; else ko "Tier A path, no jq: static deny" "rc=$rc out=$out"; fi
# A failure before any decision (here a mktemp that fails) is a static deny too, not a non-zero exit.
FAILMK=$WORK/bin-failmk
mkdir -p "$FAILMK"
printf '#!/bin/sh\nexit 1\n' >"$FAILMK/mktemp"
chmod +x "$FAILMK/mktemp"
at 0.3.19
out=$(payload Write .workflow/specs/001-demo/spec.md | (cd "$P" && PATH="$FAILMK:$PATH" bash "$H/$SPECG.sh" 2>/dev/null)); rc=$?
if is_deny && reason | grep -q 'failed before reaching a decision'; then ok "failure before a decision (mktemp): static deny"; else ko "failure before a decision (mktemp): static deny" "rc=$rc out=$out"; fi
NOYQ=$WORK/bin-noyq
mkdir -p "$NOYQ"
for b in bash jq git cat sed tr grep mktemp rm dirname basename head awk env wc sort ls date find cut stat; do
  command -v "$b" >/dev/null 2>&1 && ln -sf "$(command -v "$b")" "$NOYQ/$b"
done
at 0.3.7
out=$(payload Write .workflow/rules.md | (cd "$P" && PATH="$NOYQ" "$NOYQ/bash" "$H/$TIERA.sh" 2>/dev/null)); rc=$?
if is_deny && reason | grep -q 'fail closed'; then ok "Tier A check without yq: denied (fail closed)"; else ko "Tier A check without yq: denied (fail closed)" "rc=$rc out=$out"; fi
NOGIT=$WORK/not-a-repo
mkdir -p "$NOGIT"
expect "cwd outside any git repo: path is not in a workflow project, allowed" allow $TIERA "$(payload Write .workflow/rules.md "$NOGIT")"

echo "== project without the workflow installed"
NW=$WORK/nowf
mkdir -p "$NW/.agents/hooks"
cp "$H/$SPECG.sh" "$NW/.agents/hooks/"
# The guards exit before reading stdin here, so the payload comes from a file: a pipe would let the writer die of SIGPIPE.
payload Write .workflow/rules.md "$NW" > "$WORK/nowf.json"
out=$(bash "$NW/.agents/hooks/$SPECG.sh" < "$WORK/nowf.json" 2>/dev/null); rc=$?
if is_allow; then ok "no feature-workflow skill -> silent allow"; else ko "no feature-workflow skill -> silent allow" "rc=$rc out=$out"; fi

echo "== one check-write.sh call per write"
# A copy of the hook beside a check-write.sh stub that records its arguments and denies, so the calls can be counted.
CW1=$WORK/one-call
mkdir -p "$CW1/.agents/hooks" "$CW1/.agents/skills/feature-workflow/scripts"
cp "$H/$SPECG.sh" "$CW1/.agents/hooks/"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/calls"\necho "deny: stub" >&2\nexit 2\n' "$CW1" > "$CW1/.agents/skills/feature-workflow/scripts/check-write.sh"
chmod +x "$CW1/.agents/skills/feature-workflow/scripts/check-write.sh"
for target in .workflow/specs/001-demo/spec.md .workflow/rules.md; do
  : > "$CW1/calls"
  out=$(payload Write "$target" | bash "$CW1/.agents/hooks/$SPECG.sh" 2>/dev/null); rc=$?
  eq "$target: one check-write.sh call" "$(wc -l < "$CW1/calls" | tr -d ' ')" 1
  check "$target: the call passes --proposed" 'grep -q -- "--proposed" "$CW1/calls"' "$(cat "$CW1/calls")"
  if is_deny && reason | grep -q 'deny: stub'; then ok "$target: the stub's deny reason is passed on"; else ko "$target: the stub's deny reason is passed on" "rc=$rc out=$out"; fi
done
SETTINGS_TPL=$H/claude-settings.template.json
eq "the template's Write|Edit|NotebookEdit PreToolUse group runs only workflow-write-guard.sh" \
  "$(jq -r '[.hooks.PreToolUse[] | select(.matcher == "Write|Edit|NotebookEdit") | .hooks[].command] | join(",")' "$SETTINGS_TPL")" \
  '"$CLAUDE_PROJECT_DIR"/.agents/hooks/workflow-write-guard.sh'
check "the manifest ships workflow-write-guard.sh and none of the hooks it replaced" \
  'grep -qx "hooks/workflow-write-guard.sh" "$P/.agents/install-manifest.txt" && ! grep -qE "spec-single-writer-guard|tier-a-write-guard|_guard-common" "$P/.agents/install-manifest.txt"'


echo "== workflow-paths.sh constants"
# lib_eval EXPR : source the path library in a clean shell and print EXPR's expansion.
lib_eval() { bash -c '. "$1"; eval "printf %s \"$2\""' _ "$H/../lib/workflow-paths.sh" "$1"; }
eq "WF_SPECS is the repo-relative specs root" "$(lib_eval '$WF_SPECS')" ".workflow/specs"
eq "WF_INITIATIVES is the repo-relative initiatives root" "$(lib_eval '$WF_INITIATIVES')" ".workflow/initiatives"
eq "WF_REVIEW_LESSONS is the repo-relative review-lessons file" "$(lib_eval '$WF_REVIEW_LESSONS')" ".workflow/review-lessons.md"
eq "wf_path joins the project root and WF_INITIATIVES" "$(lib_eval "\$(wf_path $P/ \"\$WF_INITIATIVES\")")" "$P/.workflow/initiatives"
eq "an initiative's .step pattern builds from WF_INITIATIVES" "$(lib_eval '$WF_INITIATIVES/*/.step')" ".workflow/initiatives/*/.step"

shellcheck_files "shellcheck: write guard, workflow-paths.sh" "$H/../lib/workflow-paths.sh" "$H/$SPECG.sh"
finish
