#!/usr/bin/env bash
# Suite: Codex adapter hooks (D9, D40, D66, D67): hooks/_codex-patch.sh (apply_patch parser), hooks/codex-write-guard.sh (PreToolUse
#   apply_patch), hooks/codex-pre-spawn.sh (PreToolUse .*spawn_agent) and hooks/codex-rules-sync.sh (PostToolUse apply_patch), plus
#   their wiring in hooks/codex-hooks.template.json.
# Covers: Add/Update/Delete/Move parsing, heredoc wrapper, CRLF, every parse error; write guard per path and class (spec, Tier A, Tier B),
#   multi-file deny with all reasons, Move targets, sub-agent identity from agent_id (D16), spec.md status protection (Add proposed
#   content, Update status-line comparison), worktree cwd, fail closed on unparsable payload, missing patch text, parse errors and
#   check-write.sh environment errors, static deny without jq, silence without the workflow; spawn validation of agent_type (both the
#   definition and the Codex [a-z0-9_] form) and the D66 task_name forms per type, spec-folder and profile resolution, pass-through of
#   non-workflow agents; rules sync for docs/rules.md in Add/Update/Move (not Delete), block on a bad rules.md; template commands run
#   from a sub-directory.
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

mkdir -p "$P/specs/001-demo" "$P/specs/007-checkout" "$P/specs/008-a" "$P/specs/008-b" "$P/profiles" "$P/docs/cache" "$P/src" "$P/sub/dir"
cp "$TPL/spec.md" "$P/specs/001-demo/spec.md"
cp "$TPL/tasks.md" "$P/specs/001-demo/tasks.md"
echo '# glossary' > "$P/GLOSSARY.md"
echo '# rules' > "$P/docs/rules.md"
for p in web web-ui web_ui test-harness; do echo "# $p" > "$P/profiles/$p.md"; done
echo 'specs/*/.step' > "$P/.gitignore"
git_commit_all "$P" fixture
git -C "$P" worktree add -q .claude/worktrees/agent-x -b wt-x
WT=$P/.claude/worktrees/agent-x
at() { "$ST" step specs/001-demo "$1" --cwd "$P" >/dev/null 2>&1 || echo "setup failed: step $1" >&2; }
"$ST" status specs/001-demo draft --cwd "$P" >/dev/null 2>&1

# shellcheck source=../../.agents/hooks/_codex-patch.sh
source "$H/_codex-patch.sh"
PF=$WORK/patch
parse() { printf '%s' "$1" > "$PF"; out=$(codex_patch_paths "$PF" 2>&1); rc=$?; }
NL=$'\n'
TAB=$'\t'

echo "== _codex-patch.sh"
parse $'*** Begin Patch\n*** Add File: a.txt\n+hi\n*** Update File: src/b.ts\n*** Move to: src/c.ts\n@@ ctx\n-x\n+y\n*** Delete File:  d.txt  \n*** End Patch\n'
eq "Add / Update+Move / Delete, in order, trimmed" "$out" "1${TAB}add${TAB}a.txt${NL}2${TAB}update${TAB}src/b.ts${NL}2${TAB}move${TAB}src/c.ts${NL}3${TAB}delete${TAB}d.txt"
eq "body of section 2 (Move line excluded)" "$(codex_patch_body "$PF" 2)" "@@ ctx${NL}-x${NL}+y"
eq "body of section 1" "$(codex_patch_body "$PF" 1)" "+hi"
parse $'apply_patch <<\'EOF\'\n*** Begin Patch\n*** Add File: a.txt\n+hi\n*** End Patch\nEOF\n'
eq "heredoc wrapper accepted" "$rc:$out" "0:1${TAB}add${TAB}a.txt"
parse $'*** Begin Patch\r\n*** Update File: a.txt\r\n+x\r\n*** End of File\r\n*** End Patch\r\n'
eq "CRLF and *** End of File" "$rc:$out" "0:1${TAB}update${TAB}a.txt"
perr() { # name patch regex
  parse "$2"
  # shellcheck disable=SC2034  # read by the eval'd check expression
  want_re=$3
  check "parse error: $1" '[ $rc -ne 0 ] && grep -Eq -- "$want_re" <<<"$out"' "rc=$rc out=$out"
}
perr "no Begin" $'*** Add File: a\n+x\n*** End Patch\n' "Begin Patch|before"
perr "no End" $'*** Begin Patch\n*** Add File: a\n+x\n' "End Patch"
perr "unknown header" $'*** Begin Patch\n*** Rename File: a\n*** End Patch\n' "unknown patch header"
perr "empty path" $'*** Begin Patch\n*** Add File:   \n+x\n*** End Patch\n' "empty path"
perr "Move to without Update" $'*** Begin Patch\n*** Add File: a\n*** Move to: b\n*** End Patch\n' "Move to"
perr "no file section" $'*** Begin Patch\n*** End Patch\n' "names no file"
perr "text after End" $'*** Begin Patch\n*** Add File: a\n+x\n*** End Patch\nrm -rf x\n' "after"
perr "hunk line before a header" $'*** Begin Patch\n+x\n*** Add File: a\n*** End Patch\n' "before any file header"
perr "tab in path" $'*** Begin Patch\n*** Add File: a\tb\n+x\n*** End Patch\n' "tab"
eq "patch text from a string command" "$(jq -cn '{tool_input:{command:"P"}}' | codex_patch_text)" P
eq "patch text from an argv command (last element)" "$(jq -cn '{tool_input:{command:["apply_patch","P2"]}}' | codex_patch_text)" P2
check "no command -> error" '! jq -cn "{tool_input:{}}" | codex_patch_text >/dev/null'

echo "== codex-write-guard.sh"
# wp PATCH [CWD] [EXTRA_JSON] : PreToolUse apply_patch payload (Codex 0.155.1 shape, row 5a).
wp() {
  local extra=${3:-}
  [ -n "$extra" ] || extra='{}'
  jq -cn --arg p "$1" --arg c "${2:-$P}" --argjson x "$extra" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"PreToolUse",model:"m",permission_mode:"default",turn_id:"u",
      tool_name:"apply_patch",tool_input:{command:$p},tool_use_id:"c"} + $x'
}
SUB='{"agent_id":"a1","agent_type":"implementation"}'
guard() { out=$(printf '%s' "$1" | (cd "$P" && bash "$H/codex-write-guard.sh" 2>/dev/null)); rc=$?; }
reason() { jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out"; }
expect() { # name allow|deny payload [reason-regex]
  guard "$3"
  if [ "$2" = allow ]; then
    if [ "$rc" = 0 ] && [ -z "$out" ]; then ok "$1"; else ko "$1" "rc=$rc out=$out"; fi
  elif [ "$rc" = 0 ] && [ "$(jq -r '.hookSpecificOutput.hookEventName + "/" + .hookSpecificOutput.permissionDecision' <<<"$out" 2>/dev/null)" = PreToolUse/deny ]; then
    if [ -z "${4:-}" ] || reason | grep -Eq -- "$4"; then ok "$1"; else ko "$1" "reason lacks /$4/: $(reason)"; fi
  else ko "$1" "rc=$rc out=$out"; fi
}
add() { printf '*** Begin Patch\n*** Add File: %s\n+x\n*** End Patch\n' "$1"; }
upd() { printf '*** Begin Patch\n*** Update File: %s\n@@\n-a\n+b\n*** End Patch\n' "$1"; }

at 0.3.19
expect "other tool (Bash) ignored" allow "$(wp x | jq -c '.tool_name="Bash"')"
expect "src file -> allow" allow "$(wp "$(add src/a.ts)")"
expect "docs/cache (Tier B) -> deny" deny "$(wp "$(add docs/cache/modules.md)")" "docs/cache/modules.md: .*regenerate-caches|docs/cache"
expect "multi-file: one bad path denies the patch, all reasons listed" deny \
  "$(wp $'*** Begin Patch\n*** Add File: src/ok.ts\n+x\n*** Add File: docs/cache/a.md\n+x\n*** Update File: GLOSSARY.md\n-a\n+b\n*** End Patch\n')" \
  "docs/cache/a.md: .*; GLOSSARY.md: "
check "allowed path not named in the reason" '! reason | grep -q src/ok.ts'
expect "Move to docs/cache -> deny" deny "$(wp $'*** Begin Patch\n*** Update File: src/a.ts\n*** Move to: docs/cache/a.ts\n-a\n+b\n*** End Patch\n')" "docs/cache/a.ts"
expect "Move between plain paths -> allow" allow "$(wp $'*** Begin Patch\n*** Update File: src/a.ts\n*** Move to: src/b.ts\n-a\n+b\n*** End Patch\n')"
expect "Delete specs/*/.step -> deny" deny "$(wp $'*** Begin Patch\n*** Delete File: specs/001-demo/.step\n*** End Patch\n')" "status-transition|\\.step"
expect "GLOSSARY.md at 0.3.19 -> deny (Tier A)" deny "$(wp "$(upd GLOSSARY.md)")" "GLOSSARY.md"
at 0.2.3
expect "GLOSSARY.md at 0.2.3, main -> allow" allow "$(wp "$(upd GLOSSARY.md)")"
expect "GLOSSARY.md at 0.2.3, sub-agent (agent_id) -> deny" deny "$(wp "$(upd GLOSSARY.md)" "$P" "$SUB")"
expect "src file from a sub-agent -> allow" allow "$(wp "$(add src/x.ts)" "$P" "$SUB")"
at 0.3.19
expect "spec.md body edit at 0.3.19 -> allow" allow "$(wp $'*** Begin Patch\n*** Update File: specs/001-demo/spec.md\n@@\n-light_path: false\n+light_path: false\n*** End Patch\n')"
expect "spec.md status edit -> deny" deny "$(wp $'*** Begin Patch\n*** Update File: specs/001-demo/spec.md\n@@\n-status: draft\n+status: done\n*** End Patch\n')" "status-transition"
expect "spec.md status line as unchanged -/+ pair -> allow" allow "$(wp $'*** Begin Patch\n*** Update File: specs/001-demo/spec.md\n@@\n-status: draft\n+status: draft \n-light_path: false\n+light_path: true\n*** End Patch\n')"
expect "spec.md blocked_condition added -> deny" deny "$(wp $'*** Begin Patch\n*** Update File: specs/001-demo/spec.md\n@@\n status: draft\n+blocked_condition: x\n*** End Patch\n')" "blocked_condition"
expect "spec.md sub-agent -> deny" deny "$(wp $'*** Begin Patch\n*** Update File: specs/001-demo/spec.md\n@@\n-a\n+b\n*** End Patch\n' "$P" "$SUB")"
done_spec=$(sed -e 's/^status: draft/status: done/' -e 's/^/+/' "$P/specs/001-demo/spec.md")
same_spec=$(sed -e 's/^/+/' "$P/specs/001-demo/spec.md")
expect "spec.md Add with a changed status -> deny (--proposed)" deny "$(wp "*** Begin Patch${NL}*** Add File: specs/001-demo/spec.md${NL}${done_spec}${NL}*** End Patch${NL}")" "status"
expect "spec.md Add with the same content -> allow" allow "$(wp "*** Begin Patch${NL}*** Add File: specs/001-demo/spec.md${NL}${same_spec}${NL}*** End Patch${NL}")"
at 0.3.7
expect "spec.md at 0.3.7 -> deny (step)" deny "$(wp "$(upd specs/001-demo/spec.md)")" "spec"
expect "worktree cwd, relative docs/cache -> deny" deny "$(wp "$(add docs/cache/a.md)" "$WT")" "docs/cache"
expect "worktree cwd, src -> allow" allow "$(wp "$(add src/w.ts)" "$WT")"
expect "parse error -> deny (fail closed)" deny "$(wp $'*** Begin Patch\n*** Add File: a\n')" "parse error.*fail closed"
expect "no patch text -> deny" deny "$(wp x | jq -c '.tool_input={}')" "no patch text"
guard 'not json'
check "unparsable payload -> deny" '[ "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out")" = deny ]' "$out"
NOJQ=$WORK/bin-nojq
mkdir -p "$NOJQ"
for b in bash git cat sed tr grep mktemp rm dirname basename head awk env wc sort ls date find cut stat yq; do
  command -v "$b" >/dev/null 2>&1 && ln -sf "$(command -v "$b")" "$NOJQ/$b"
done
out=$(wp "$(add src/a.ts)" | (cd "$P" && PATH="$NOJQ" "$NOJQ/bash" "$H/codex-write-guard.sh" 2>/dev/null))
check "write guard, no jq -> static deny JSON" 'grep -q "\"permissionDecision\":\"deny\"" <<<"$out" && grep -q "jq not found" <<<"$out"' "$out"
out=$(wp "$(upd GLOSSARY.md)" | PATH=/usr/bin:/bin:$(dirname "$(command -v jq)") bash "$H/codex-write-guard.sh" 2>/dev/null)
check "Tier A without yq -> deny, fail closed" 'jq -r .hookSpecificOutput.permissionDecisionReason <<<"$out" | grep -q "fail closed"' "$out"
N=$WORK/noflow
mkdir -p "$N/.agents"
cp -R "$H" "$N/.agents/hooks"
out=$(wp "$(add docs/cache/a.md)" "$N" | bash "$N/.agents/hooks/codex-write-guard.sh"); rc=$?
check "workflow not installed -> silent allow" '[ $rc -eq 0 ] && [ -z "$out" ]' "$out"

echo "== codex-pre-spawn.sh"
mkdir -p "$P/specs/007-checkout"
sp() { # agent_type task_name [cwd] : spawn payload; task_name "-" = absent
  jq -cn --arg a "$1" --arg t "$2" --arg c "${3:-$P}" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"PreToolUse",model:"m",permission_mode:"default",turn_id:"u",
      tool_name:"collaborationspawn_agent",tool_use_id:"c",
      tool_input:({agent_type:$a,message:"gAAAAA",fork_turns:"none"} + (if $t == "-" then {} else {task_name:$t} end))}'
}
spawn() { out=$(printf '%s' "$1" | (cd "$P" && bash "$H/codex-pre-spawn.sh" 2>/dev/null)); rc=$?; }
sexpect() { # name allow|deny payload [regex]
  spawn "$3"
  if [ "$2" = allow ]; then
    if [ "$rc" = 0 ] && [ -z "$out" ]; then ok "$1"; else ko "$1" "rc=$rc out=$out"; fi
  elif [ "$rc" = 0 ] && [ "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out" 2>/dev/null)" = deny ]; then
    if [ -z "${4:-}" ] || reason | grep -Eq -- "$4"; then ok "$1"; else ko "$1" "reason lacks /$4/: $(reason)"; fi
  else ko "$1" "rc=$rc out=$out"; fi
}
sexpect "other tool ignored" allow "$(sp implementation - | jq -c '.tool_name="apply_patch"')"
sexpect "non-workflow agent passes" allow "$(sp probe probe_agent)"
sexpect "no agent_type passes" allow "$(sp '' -)"
sexpect "implementation s007_t3 -> allow" allow "$(sp implementation s007_t3)"
sexpect "implementation from a worktree cwd -> allow (main checkout specs)" allow "$(sp implementation s007_t3 "$WT")"
sexpect "implementation phase 1 s007_phase_1_test_harness -> allow" allow "$(sp implementation s007_phase_1_test_harness)"
sexpect "implementation without task_name -> deny" deny "$(sp implementation -)" "missing"
sexpect "implementation probe_agent -> deny" deny "$(sp implementation probe_agent)" "not in a workflow form"
sexpect "uppercase task_name -> deny" deny "$(sp implementation S007_T3)" "lowercase"
sexpect "slash form (old D66) -> deny" deny "$(sp implementation 007-checkout/T3)" "lowercase"
sexpect "no spec folder s009 -> deny" deny "$(sp implementation s009_t1)" "0 folders"
sexpect "two spec folders s008 -> deny" deny "$(sp implementation s008_t1)" "2 folders"
sexpect "phase_1 matching two profiles (web-ui, web_ui) -> deny" deny "$(sp implementation s007_phase_1_web_ui)" "2 profiles"
sexpect "phase_1 unknown profile -> deny" deny "$(sp implementation s007_phase_1_nope)" "0 profiles"
sexpect "integration name on an implementation -> deny" deny "$(sp implementation s007_integration_web)" "implementation launch"
sexpect "integration s007_integration_web -> allow" allow "$(sp integration s007_integration_web)"
sexpect "integration s007_t3 -> deny" deny "$(sp integration s007_t3)" "integration_"
sexpect "integration without task_name -> deny" deny "$(sp integration -)" "missing"
sexpect "profile_mini_review bare s007_t3 (the implementer's name) -> deny" deny "$(sp profile_mini_review s007_t3)" "_r<round>"
sexpect "profile_mini_review (Codex form) s007_t3_r1 -> allow" allow "$(sp profile_mini_review s007_t3_r1)"
sexpect "profile_mini_review free suffix s007_t3_x -> deny" deny "$(sp profile_mini_review s007_t3_x)" "_r<round>"
sexpect "profile-mini-review (definition form) s007_t3_r2 -> allow" allow "$(sp profile-mini-review s007_t3_r2)"
sexpect "profile_mini_review phase-1 form -> deny" deny "$(sp profile_mini_review s007_phase_1_web)" "profile-mini-review"
sexpect "fact_lookup without task_name -> allow" allow "$(sp fact_lookup -)"
sexpect "retrieval s007_retrieval -> allow" allow "$(sp retrieval s007_retrieval)"
sexpect "review_standards s007_review_standards -> allow" allow "$(sp review_standards s007_review_standards)"
sexpect "review_standards s009_review_standards (no spec folder) -> deny" deny "$(sp review_standards s009_review_standards)" "0 folders"
sexpect "fact_lookup free name -> allow" allow "$(sp fact_lookup lookup_1)"
sexpect "fact_lookup s007_q1 -> allow" allow "$(sp fact_lookup s007_q1)"
sexpect "fact_lookup repeated launch s007_fact_lookup_r2 -> allow" allow "$(sp fact_lookup s007_fact_lookup_r2)"
sexpect "review_end_state repeated launch s007_review_end_state_r3 -> allow" allow "$(sp review_end_state s007_review_end_state_r3)"
sexpect "fact_lookup s009_q1 (no spec) -> deny" deny "$(sp fact_lookup s009_q1)" "0 folders"
sexpect "cache_regeneration bulk (no task_name) -> allow" allow "$(sp cache_regeneration -)"
out=$(sp implementation s007_t3 | (cd "$P" && PATH="$NOJQ" "$NOJQ/bash" "$H/codex-pre-spawn.sh" 2>/dev/null))
check "pre-spawn, no jq -> static deny JSON" 'grep -q "\"permissionDecision\":\"deny\"" <<<"$out" && grep -q "jq not found" <<<"$out"' "$out"
spawn 'nope'
check "unparsable payload -> deny" '[ "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out")" = deny ]' "$out"
out=$(sp implementation s009_t1 "$N" | bash "$N/.agents/hooks/codex-pre-spawn.sh"); rc=$?
check "workflow not installed -> silent allow" '[ $rc -eq 0 ] && [ -z "$out" ]' "$out"

echo "== codex-rules-sync.sh"
cat > "$P/docs/rules.md" <<'S'
# Rules
## Ownership

```yaml
modules:
  a:
    owns: ["src/a/**"]
    may_depend_on: []
```

## Shared core

```yaml
shared_core:
  paths: ["src/core/**"]
```
S
pp() { wp "$1" "${2:-$P}" | jq -c '.hook_event_name="PostToolUse" | .tool_response="Exit code: 0\nOutput:\nSuccess."'; }
sync() { out=$(printf '%s' "$1" | (cd "$P" && bash "$H/codex-rules-sync.sh" 2>/dev/null)); rc=$?; }
CFG=$P/tools/boundaries/dependency-cruiser.cjs
sync "$(pp "$(upd src/a.ts)")"
check "patch without rules.md -> silent, nothing generated" '[ $rc -eq 0 ] && [ -z "$out" ] && [ ! -e "$CFG" ]' "$out"
sync "$(pp "$(upd src/a.ts)" | jq -c '.tool_name="Bash"')"
check "other tool ignored" '[ -z "$out" ] && [ ! -e "$CFG" ]' "$out"
sync "$(pp $'*** Begin Patch\n*** Delete File: docs/rules.md\n*** End Patch\n')"
check "Delete of rules.md ignored" '[ -z "$out" ] && [ ! -e "$CFG" ]' "$out"
sync "$(pp $'*** Begin Patch\n*** Add File: src/x.ts\n+x\n*** Update File: docs/rules.md\n@@\n-a\n+b\n*** End Patch\n')"
check "Update of docs/rules.md (second file) -> config generated" '[ $rc -eq 0 ] && [ -z "$out" ] && [ -f "$CFG" ]' "$out"
rm -rf "$P/tools"
sync "$(pp $'*** Begin Patch\n*** Update File: docs/old.md\n*** Move to: docs/rules.md\n*** End Patch\n')"
check "Move to docs/rules.md -> config generated" '[ -f "$CFG" ]' "$out"
cp "$CFG" "$WORK/good.cjs"
printf '## Ownership\n\n```yaml\nmodules: [unclosed\n```\n' > "$P/docs/rules.md"
sync "$(pp "$(upd "$P/docs/rules.md")")"
check "bad rules.md (absolute path) -> block with reason, config untouched" \
  '[ "$(jq -r .decision <<<"$out")" = block ] && jq -r .reason <<<"$out" | grep -q Ownership && cmp -s "$WORK/good.cjs" "$CFG"' "$out"
sync "$(pp $'*** Begin Patch\n*** Update File: docs/rules.md\n')"
check "unparsable patch -> silent" '[ $rc -eq 0 ] && [ -z "$out" ]' "$out"

echo "== template wiring"
T=$H/codex-hooks.template.json
cmd_for() { jq -r --arg e "$1" --arg m "$2" '.hooks[$e][] | select(.matcher == $m) | .hooks[0].command' "$T"; }
check "PreToolUse apply_patch -> codex-write-guard.sh" 'cmd_for PreToolUse apply_patch | grep -q "hooks/codex-write-guard.sh"'
check "PreToolUse .*spawn_agent -> codex-pre-spawn.sh" 'cmd_for PreToolUse ".*spawn_agent" | grep -q "hooks/codex-pre-spawn.sh"'
check "PostToolUse apply_patch -> codex-rules-sync.sh" 'cmd_for PostToolUse apply_patch | grep -q "hooks/codex-rules-sync.sh"'
out=$(cd "$P/sub/dir" && wp "$(add docs/cache/z.md)" "$P/sub/dir" | sh -c "$(cmd_for PreToolUse apply_patch)")
check "write guard via template command, docs/cache/z.md relative to cwd sub/dir (not Tier B) -> allow" '[ -z "$out" ]' "$out"
out=$(cd "$P/sub/dir" && wp "$(add ../../docs/cache/z.md)" "$P/sub/dir" | sh -c "$(cmd_for PreToolUse apply_patch)")
eq "write guard via template command, ../../docs/cache from sub/dir -> deny" "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out")" deny
out=$(cd "$P/sub/dir" && sp implementation s009_t1 "$P/sub/dir" | sh -c "$(cmd_for PreToolUse ".*spawn_agent")")
eq "spawn check via template command from a sub-directory" "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out")" deny

shellcheck_files "shellcheck: Codex adapters" "$H/_codex-patch.sh" "$H/codex-write-guard.sh" "$H/codex-pre-spawn.sh" "$H/codex-rules-sync.sh"
finish
