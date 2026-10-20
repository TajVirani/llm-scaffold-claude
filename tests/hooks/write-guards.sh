#!/usr/bin/env bash
# Suite: hooks/spec-single-writer-guard.sh, hooks/tier-a-write-guard.sh, hooks/tier-b-write-guard.sh (and the sourced
#   _guard-common.sh): thin PreToolUse adapters over feature-workflow/scripts/check-write.sh.
# Covers: main session vs sub-agent (agent_id), Write / Edit / NotebookEdit payloads, status edits denied through the
#   proposed-content check, Tier A steps and glossary / profile rules, .workflow/cache always denied,
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

mkdir -p "$P/.workflow/specs/001-demo" "$P/.workflow/specs/work-backlog" "$P/.workflow/profiles" "$P/.workflow/cache" "$P/.workflow/decisions/adr" "$P/src"
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
SPECG=spec-single-writer-guard
TIERA=tier-a-write-guard
TIERB=tier-b-write-guard

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
expect "work-backlog item at 00.26, main" allow $SPECG "$(payload Write .workflow/specs/work-backlog/001-demo-disc-001.md)"
expect "work-backlog item at 00.26, sub-agent" deny $SPECG "$(payload Write .workflow/specs/work-backlog/001-demo-disc-001.md "$P" "$SUB")"
expect "work-backlog misnamed item denied" deny $SPECG "$(payload Write .workflow/specs/work-backlog/notes.md)"
at 3.1
expect "work-backlog item at 3.1 denied" deny $SPECG "$(payload Write .workflow/specs/work-backlog/001-demo-disc-001.md)" "00\.26"
expect "spec guard ignores Tier A path" allow $SPECG "$(payload Write .workflow/GLOSSARY.md)"
expect "spec guard ignores Tier B path" allow $SPECG "$(payload Write .workflow/cache/modules.md)"
expect "spec guard ignores source file" allow $SPECG "$(payload Write src/app.ts)"
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
expect "Tier A guard ignores spec.md" allow $TIERA "$(payload Write .workflow/specs/001-demo/spec.md)"
expect "Tier A guard ignores .workflow/cache" allow $TIERA "$(payload Write .workflow/cache/modules.md)"
expect "NotebookEdit on Tier A path follows the same rule" deny $TIERA "$(payload NotebookEdit .workflow/rules.md)"
at 0.3.7
expect "NotebookEdit on .workflow/rules.md at 0.3.7 allowed" allow $TIERA "$(payload NotebookEdit .workflow/rules.md)"

echo "== Tier A guard: no feature in flight"
yq --front-matter=process -i '.status="done"' "$P/.workflow/specs/001-demo/spec.md"
expect "no feature in flight: main allowed" allow $TIERA "$(payload Write .workflow/rules.md)"
expect "no feature in flight: sub-agent denied" deny $TIERA "$(payload Write .workflow/rules.md "$P" "$SUB")"
yq --front-matter=process -i '.status="draft"' "$P/.workflow/specs/001-demo/spec.md"

echo "== Tier B guard"
at 5.3
expect ".workflow/cache denied for main" deny $TIERB "$(payload Write .workflow/cache/modules.md)" "regenerate-caches|publish-cache"
expect ".workflow/cache denied for sub-agent" deny $TIERB "$(payload Write .workflow/cache/modules.md "$P" '{"agent_id":"a3","agent_type":"cache-regeneration"}')"
expect ".workflow/cache nested path denied" deny $TIERB "$(payload Edit .workflow/cache/x/y.md)"
expect ".workflow/cache via .. denied" deny $TIERB "$(payload Write src/../.workflow/cache/flows.md)"
expect ".workflow/cache absolute path denied" deny $TIERB "$(payload Write "$P/.workflow/cache/modules.md")"
expect ".workflow/cache NotebookEdit denied" deny $TIERB "$(payload NotebookEdit .workflow/cache/n.ipynb)"
expect ".workflow/cache case-insensitive" deny $TIERB "$(payload Write .Workflow/Cache/a.md)"
expect "docs/cachex is not Tier B" allow $TIERB "$(payload Write docs/cachex.md)"
expect "source file allowed" allow $TIERB "$(payload Write src/app.ts)"
expect "path outside repo allowed" allow $TIERB "$(payload Write /etc/hosts)"
expect "no path (e.g. other tool input) allowed" allow $TIERB '{"cwd":"'"$P"'","tool_name":"Write","tool_input":{}}'
expect "Tier B guard ignores Tier A path" allow $TIERB "$(payload Write .workflow/rules.md)"

echo "== worktree cwd"
at 0.3.19
expect "spec.md from worktree cwd, main session, step read from main checkout" allow $SPECG "$(payload Write "$WT/.workflow/specs/001-demo/spec.md" "$WT" | jq -c --rawfile c "$P/.workflow/specs/001-demo/spec.md" '.tool_input.content=$c')"
expect "spec.md from worktree cwd, sub-agent" deny $SPECG "$(payload Write "$WT/.workflow/specs/001-demo/spec.md" "$WT" "$SUB")"
expect "relative spec.md path resolves against worktree cwd (Edit)" allow $SPECG "$(payload Edit .workflow/specs/001-demo/spec.md "$WT" | jq -c '.tool_input={file_path:".workflow/specs/001-demo/spec.md",old_string:"light_path: false",new_string:"light_path: false"}')"
at 3.1
expect "spec.md from worktree at 3.1 denied" deny $SPECG "$(payload Write "$WT/.workflow/specs/001-demo/spec.md" "$WT")"
expect ".workflow/cache in worktree denied" deny $TIERB "$(payload Write "$WT/.workflow/cache/a.md" "$WT" "$SUB")"
expect "Tier A path in worktree, sub-agent denied" deny $TIERA "$(payload Write "$WT/.workflow/rules.md" "$WT" "$SUB")"
out=$(payload Write .workflow/cache/a.md "" | jq -c 'del(.cwd)' | (cd / && CLAUDE_PROJECT_DIR="$P" bash "$H/$TIERB.sh" 2>/dev/null)); rc=$?
if is_deny; then ok "no cwd in payload: CLAUDE_PROJECT_DIR fallback"; else ko "no cwd in payload: CLAUDE_PROJECT_DIR fallback" "rc=$rc out=$out"; fi

echo "== fail closed"
for g in $SPECG $TIERA $TIERB; do
  guard "$g" 'not json'
  if is_deny && reason | grep -q 'unparsable'; then ok "$g: invalid payload denied"; else ko "$g: invalid payload denied" "rc=$rc out=$out"; fi
  guard "$g" ''
  if is_deny; then ok "$g: empty payload denied"; else ko "$g: empty payload denied" "rc=$rc out=$out"; fi
done
# A PATH with the usual tools but no jq.
NOJQ=$WORK/bin-nojq
mkdir -p "$NOJQ"
for b in bash git cat sed tr grep mktemp rm dirname basename head awk env wc sort ls date find cut stat yq; do
  command -v "$b" >/dev/null 2>&1 && ln -sf "$(command -v "$b")" "$NOJQ/$b"
done
out=$(payload Write .workflow/cache/a.md | (cd "$P" && PATH="$NOJQ" "$NOJQ/bash" "$H/$TIERB.sh" 2>/dev/null)); rc=$?
# Without jq the guard cannot parse the payload; it emits a static deny (like pre-launch.sh) instead of failing open.
if is_deny && grep -q 'write guard error (denying, fail closed): jq not found' <<<"$out"; then ok "no jq: static deny (fail closed)"; else ko "no jq: static deny (fail closed)" "rc=$rc out=$out"; fi
for g in $SPECG $TIERA; do
  out=$(payload Write .workflow/GLOSSARY.md | (cd "$P" && PATH="$NOJQ" "$NOJQ/bash" "$H/$g.sh" 2>/dev/null)); rc=$?
  if is_deny; then ok "$g: no jq, static deny"; else ko "$g: no jq, static deny" "rc=$rc out=$out"; fi
done
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
cp "$H"/_guard-common.sh "$H"/*-guard.sh "$NW/.agents/hooks/"
for g in $SPECG $TIERA $TIERB; do
  out=$(payload Write .workflow/cache/modules.md "$NW" | bash "$NW/.agents/hooks/$g.sh" 2>/dev/null); rc=$?
  if is_allow; then ok "$g: no feature-workflow skill -> silent allow"; else ko "$g: no feature-workflow skill -> silent allow" "rc=$rc out=$out"; fi
done

shellcheck_files "shellcheck: write guards, workflow-paths.sh" "$H/../lib/workflow-paths.sh" "$H/_guard-common.sh" "$H/$SPECG.sh" "$H/$TIERA.sh" "$H/$TIERB.sh"
finish
