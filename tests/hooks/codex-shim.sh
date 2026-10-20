#!/usr/bin/env bash
# Suite: Codex shim (D9, D66, D67): the Codex task_name path of hooks/post-implementation-audit.sh, hooks/codex-hooks.template.json
#   and hooks/codex-config.template.toml.
# Covers: task lookup from the session_meta agent_path of a Codex rollout (top-level and source.subagent fallback, nested paths),
#   s<NNN>_t<N> and s<NNN>_phase_1_<wt> forms, the toolchain running in .workflow/.worktrees/<task_name> (warning when absent), block / pass
#   with evidence in the main checkout, the forked parent prompt being
#   ignored, warnings for unparseable names, missing or ambiguous specs and profiles, integration names, and the Claude path still
#   working; template JSON shape, matchers limited to the verified set, commands that resolve the project root from a sub-directory
#   with and without a shell; the permissions profile shape, plus a live `codex sandbox` check when codex is installed (free, no model).
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose (they use EV, WARN)
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
B=$WORK
P=$B/proj
copy_agents "$P"
cd "$P" || exit 1
git init -q -b main && git config user.email t@t.invalid && git config user.name tester
mkdir -p .workflow/specs/007-checkout .workflow/specs/008-a .workflow/specs/008-b .workflow/profiles sub/dir
cat > .workflow/specs/007-checkout/spec.md <<'S'
---
status: in-progress
baseline_revision: ""
light_path: false
followup_review_recommended: false
deferred: []
---
# Checkout
S
cat > .workflow/specs/007-checkout/tasks.md <<'S'
---
tasks:
  - id: T3
    title: "a"
    status: in-progress
    capability: CAP-NEW-x
    depends_on: []
    touches_core: false
    work_type: web
    module: m
    seam: s
---
S
cat > .workflow/profiles/web.md <<'S'
# web
## Toolchain

```yaml
lint: "test -f lint-ok"
typecheck: ""
format: "true"
boundary: ""
e2e: ""
```
S
cat > .workflow/profiles/harness.md <<'S'
## Toolchain

```yaml
lint: "true"
```
S
cp .workflow/profiles/harness.md .workflow/profiles/web-ui.md
cp .workflow/profiles/harness.md .workflow/profiles/web_ui.md
printf '.workflow/.worktrees/\n' > .gitignore
git add -A >/dev/null && git commit -qm init
# Codex worktrees, as the orchestrator creates them: .workflow/.worktrees/<task_name>, branch wf/<NNN-slug>/<task_name>.
for n in s007_t3 s007_phase_1_harness s007_phase_1_redtest; do
  git worktree add -q ".workflow/.worktrees/$n" -b "wf/007-checkout/$n" >/dev/null 2>&1
done
WT3=$P/.workflow/.worktrees/s007_t3

H=$P/.agents/hooks
# Codex rollout: session_meta first (agent_path = /root/<task_name>), then the forked parent history, whose first user message
# carries a launch header for a DIFFERENT task, to prove the Codex path never reads it.
mk_rollout() { # file agent_path [style: top|source]
  if [ "${3:-top}" = top ]; then
    jq -cn --arg a "$2" '{type:"session_meta",payload:{id:"c1",forked_from_id:"p1",agent_path:$a,agent_role:"implementation",
      source:{subagent:{thread_spawn:{parent_thread_id:"p1",depth:1,agent_path:$a,agent_role:"implementation"}}}}}' > "$1"
  else
    jq -cn --arg a "$2" '{type:"session_meta",payload:{id:"c1",source:{subagent:{thread_spawn:{agent_path:$a,agent_role:"implementation"}}}}}' > "$1"
  fi
  jq -cn '{type:"response_item",payload:{type:"message",role:"user",content:[{type:"input_text",text:"```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/008-a\ntask_id: T9\n```"}]}}' >> "$1"
  jq -cn '{type:"response_item",payload:{type:"agent_message",content:{type:"encrypted_content",encrypted_content:"gAAAAA"}}}' >> "$1"
}
stop() { # transcript active [agent_type]
  jq -cn --arg t "$1" --argjson a "$2" --arg at "${3:-implementation}" --arg c "$P" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"SubagentStop",model:"m",permission_mode:"default",turn_id:"u",
      agent_id:"c1",agent_type:$at,agent_transcript_path:$t,last_assistant_message:"done",stop_hook_active:$a}' \
    | bash "$H/post-implementation-audit.sh" 2>/dev/null
}
EV=$P/.workflow/specs/007-checkout/artifacts/T3
WARN=$P/.workflow/specs/007-checkout/artifacts/audit-warnings.jsonl

echo "== Codex task_name -> task"
mk_rollout "$B/t3.jsonl" /root/s007_t3
out=$(stop "$B/t3.jsonl" false)
check "s007_t3, failing lint -> block with digest" '[ "$(jq -r .decision <<<"$out")" = block ] && [ -n "$(jq -r .reason <<<"$out")" ]' "$out"
check "evidence under .workflow/specs/007-checkout/artifacts/T3 (task from task_name, not the forked header)" \
  '[ "$(jq -r .status "$EV/toolchain.json")" = fail ] && [ ! -e "$P/.workflow/specs/008-a/artifacts" ]'
out=$(stop "$B/t3.jsonl" true)
check "loop counter works on Codex (stop_hook_active)" '[ "$(jq .count "$EV/audit-loop.json")" = 2 ]' "$out"
touch lint-ok
out=$(stop "$B/t3.jsonl" false)
check "lint-ok only in the main checkout -> still fails (toolchain runs in the worktree)" '[ "$(jq -r .decision <<<"$out")" = block ]' "$out"
rm -f lint-ok
touch "$WT3/lint-ok"
out=$(stop "$B/t3.jsonl" true); rc=$?
check "passing toolchain in .workflow/.worktrees/s007_t3 -> silent allow" '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r .status "$EV/toolchain.json")" = pass ] && [ ! -f "$EV/audit-loop.json" ]' "$out"
eq "toolchain.json cwd is the worktree; evidence stays in the main checkout" "$(jq -r .cwd "$EV/toolchain.json")" "$(cd "$WT3" && pwd)"
check "no evidence written inside the worktree" '[ ! -e "$WT3/.workflow/specs/007-checkout/artifacts" ]'
rm -f "$WT3/lint-ok"
mk_rollout "$B/src.jsonl" /root/s007_t3 source
out=$(stop "$B/src.jsonl" false)
eq "agent_path from payload.source.subagent.thread_spawn" "$(jq -r .decision <<<"$out")" block
mk_rollout "$B/nested.jsonl" /root/lead/s007_t3
out=$(stop "$B/nested.jsonl" false)
eq "nested agent_path: last segment is the task_name" "$(jq -r .decision <<<"$out")" block
mk_rollout "$B/p1.jsonl" /root/s007_phase_1_harness
out=$(stop "$B/p1.jsonl" false); rc=$?
check "s007_phase_1_harness -> toolchain under artifacts/phase-1-harness" \
  '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r .status "$P/.workflow/specs/007-checkout/artifacts/phase-1-harness/toolchain.json")" = pass ]' "$out"
sed 's/^lint: "true"/lint: "true"\ntest: "false"/' .workflow/profiles/harness.md > .workflow/profiles/redtest.md
mk_rollout "$B/p1r.jsonl" /root/s007_phase_1_redtest
out=$(stop "$B/p1r.jsonl" false); rc=$?
check "Codex phase 1 with failing test key -> allowed, test skipped (D70)" \
  '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r ".results[]|select(.key==\"test\")|.status" "$P/.workflow/specs/007-checkout/artifacts/phase-1-redtest/toolchain.json")" = skipped ]' "$out"

echo "== Codex warnings (stop allowed)"
mk_rollout "$B/t4.jsonl" /root/s007_t4
out=$(stop "$B/t4.jsonl" false)
check "no .workflow/.worktrees/s007_t4 -> warning, toolchain not run, audit.json filed" \
  '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && jq -r .systemMessage <<<"$out" | grep -q "no worktree" &&
   [ "$(jq -r .outcome "$P/.workflow/specs/007-checkout/artifacts/T4/audit.json")" = warning ] && [ ! -f "$P/.workflow/specs/007-checkout/artifacts/T4/toolchain.json" ]' "$out"
mk_rollout "$B/p1n.jsonl" /root/s007_phase_1_web
out=$(stop "$B/p1n.jsonl" false)
check "Phase 1 without a worktree -> warning filed under artifacts/phase-1-web" \
  'jq -r .systemMessage <<<"$out" | grep -q "no worktree" && [ "$(jq -r .outcome "$P/.workflow/specs/007-checkout/artifacts/phase-1-web/audit.json")" = warning ]' "$out"
mk_rollout "$B/amb.jsonl" /root/s007_phase_1_web_ui
out=$(stop "$B/amb.jsonl" false)
check "phase_1 name matching two profiles (web-ui, web_ui) -> warning" \
  '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && jq -r .systemMessage <<<"$out" | grep -q "2 profiles"' "$out"
mk_rollout "$B/bad.jsonl" /root/probe_agent
out=$(stop "$B/bad.jsonl" false)
check "unparseable task_name -> warning, no block" \
  '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && jq -r .systemMessage <<<"$out" | grep -q "probe_agent"' "$out"
mk_rollout "$B/nospec.jsonl" /root/s009_t1
out=$(stop "$B/nospec.jsonl" false)
check "no spec folder for s009 -> warning" 'jq -r .systemMessage <<<"$out" | grep -q "0 spec folders"' "$out"
mk_rollout "$B/two.jsonl" /root/s008_t1
out=$(stop "$B/two.jsonl" false)
check "two spec folders for s008 -> warning" 'jq -r .systemMessage <<<"$out" | grep -q "2 spec folders"' "$out"
rm -f "$WARN"
mk_rollout "$B/int.jsonl" /root/s007_integration_web
out=$(stop "$B/int.jsonl" false)
check "integration name on an implementation agent -> warning filed under the spec" \
  '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && grep -q integration "$WARN"' "$out"
rm -f "$WARN"
mk_rollout "$B/odd.jsonl" /root/s007_x1
out=$(stop "$B/odd.jsonl" false)
check "unknown suffix -> warning filed under the spec" '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && grep -q s007_x1 "$WARN"' "$out"
out=$(stop "$B/t3.jsonl" false integration)
eq "integration agent type is skipped" "$out" ""

echo "== Claude path unchanged"
jq -cn '{type:"user",message:{role:"user",content:"```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-checkout\ntask_id: T3\n```\n\nGo."}}' > "$B/claude.jsonl"
out=$(stop "$B/claude.jsonl" false)
eq "Claude transcript (no session_meta) -> header path, block" "$(jq -r .decision <<<"$out")" block

echo "== codex-hooks.template.json"
T=$H/codex-hooks.template.json
check "valid JSON object with hooks" 'jq -e ".hooks | type == \"object\"" "$T" >/dev/null'
eq "events" "$(jq -r '.hooks | keys | join(",")' "$T")" "PostToolUse,PreToolUse,SessionStart,SubagentStop"
eq "matchers only from the verified full-match set" \
  "$(jq -r '[.hooks[][] | .matcher // empty | select(IN("Bash", "apply_patch", ".*spawn_agent") | not)] | length' "$T")" 0
check "no CLAUDE_PROJECT_DIR in commands (Codex sets no project-dir variable)" '! jq -r ".hooks[][].hooks[].command" "$T" | grep -q CLAUDE_PROJECT_DIR'
missing=""
for s in $(jq -r '.hooks[][].hooks[].command | capture("hooks/(?<s>[A-Za-z0-9_.-]+\\.sh)").s' "$T"); do
  [ -x "$H/$s" ] || missing="$missing $s"
done
eq "every referenced script exists and is executable" "$missing" ""
check "timeouts set on every hook" '[ "$(jq "[.hooks[][].hooks[] | select((.timeout // 0) <= 0)] | length" "$T")" = 0 ]'
cmd=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$T")
payload=$(jq -cn --arg c "$P/sub/dir" '{session_id:"s",transcript_path:null,cwd:$c,hook_event_name:"SessionStart",model:"m",source:"startup"}')
out=$(cd "$P/sub/dir" && printf '%s' "$payload" | sh -c "$cmd")
check "SessionStart command via sh -c from a sub-directory finds the project hooks" \
  'jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q 007-checkout' "$out"
if command -v python3 >/dev/null 2>&1; then
  out=$(cd "$P/sub/dir" && printf '%s' "$payload" | python3 -c 'import shlex, subprocess, sys; sys.exit(subprocess.call(shlex.split(sys.argv[1])))' "$cmd")
  check "same command without a shell (argv split)" 'jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q 007-checkout' "$out"
else
  skip "same command without a shell (argv split)" "python3 not installed"
fi
cmd=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].command' "$T")
out=$(cd "$P/sub/dir" && jq -cn '{tool_name:"Bash",tool_input:{command:"git reset --hard"},cwd:"x",hook_event_name:"PreToolUse"}' | sh -c "$cmd")
eq "PreToolUse Bash -> block-destructive-git denies on a Codex payload" "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out")" deny

echo "== codex-config.template.toml"
C=$H/codex-config.template.toml
cj=$(yq -p toml -o json -I=0 '.' "$C" 2>/dev/null)
check "parses as TOML" '[ -n "$cj" ]'
eq "default_permissions" "$(jq -r .default_permissions <<<"$cj")" workflow
eq "extends :workspace (else every sandboxed shell aborts)" "$(jq -r .permissions.workflow.extends <<<"$cj")" ":workspace"
eq ".workflow/cache read-only" "$(jq -r '.permissions.workflow.filesystem[":workspace_roots"][".workflow/cache"]' <<<"$cj")" read
eq "no glob entries (0.155.1 allows only deny on globs)" \
  "$(jq -r '[.permissions.workflow.filesystem[":workspace_roots"] | keys[] | select(test("[*?\\[]"))] | length' <<<"$cj")" 0
check "no model key anywhere" '! grep -Eq "^[[:space:]]*model[[:space:]]*=" "$C"'

if command -v codex >/dev/null 2>&1; then
  S=$B/sbx
  mkdir -p "$S/.workflow/cache" "$S/.codex"
  git init -q "$S"
  cp "$C" "$S/.codex/config.toml"
  printf 'echo ok > a.txt; echo x > .workflow/cache/b.txt; echo rc=$?\n' > "$B/probe.sh"
  out=$(cd "$S" && codex sandbox -P workflow -C "$S" -c "projects={\"$S\"={trust_level=\"trusted\"}}" -- /bin/sh "$B/probe.sh" 2>&1); rc=$?
  if [ $rc -eq 0 ] && [ -f "$S/a.txt" ]; then
    check "codex sandbox: workspace write ok, .workflow/cache write blocked" '[ ! -f "$S/.workflow/cache/b.txt" ] && grep -q "rc=1" <<<"$out"' "$out"
  else
    skip "codex sandbox live check" "codex sandbox could not run here (rc=$rc)"
  fi
else
  skip "codex sandbox live check" "codex not installed"
fi

shellcheck_files "shellcheck: post-implementation-audit.sh, generate-codex-agents.sh" "$H/post-implementation-audit.sh" "$H/generate-codex-agents.sh"
finish
