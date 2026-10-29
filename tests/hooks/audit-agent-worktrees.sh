#!/usr/bin/env bash
# Suite: hooks/post-implementation-audit.sh (SubagentStop) for Claude Phase 1 and integration launches in agent worktrees, and the
#   SubagentStop wiring in hooks/claude-settings.template.json and this repo's .claude/settings.json.
# Covers: JRN-005: a Claude Phase 1 implementation stop runs the toolchain in .workflow/.worktrees/s<NNN>_phase_1_<enc(work_type)>
#   with --skip test; an integration stop runs the full toolchain in .workflow/.worktrees/s<NNN>_integration_<enc(work_type)> and a
#   failing run blocks it; with the agent worktree missing either stop is allowed with a warning and the toolchain is not run; the
#   SubagentStop matcher covers implementation and integration. run-toolchain.sh is replaced in the fixture by a stand-in that
#   records its arguments, so the suite sees where and how the hook runs it.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/claude-settings.sh
source "$TESTS_DIR/fixtures/claude-settings.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
H=$P/.agents/hooks
mkdir -p "$P/.workflow/specs/007-demo" "$P/.workflow/profiles"
printf '%s\n' '---' 'status: in-progress' 'baseline_revision: ""' 'light_path: false' 'followup_review_recommended: false' \
  'deferred: []' '---' '# Demo' > "$P/.workflow/specs/007-demo/spec.md"
printf '%s\n' '## Toolchain' '' '```yaml' 'lint: "true"' 'test: "true"' '```' > "$P/.workflow/profiles/shell-scripts.md"
cp "$P/.workflow/profiles/shell-scripts.md" "$P/.workflow/profiles/test-harness.md"
printf '%s\n' '.workflow/.worktrees/' > "$P/.gitignore"

# The stand-in toolchain: appends one line per call, its arguments joined by spaces, to RUN_LOG; exits TOOLCHAIN_EXIT.
RUN_LOG=$WORK/toolchain-runs.log
cat > "$P/.agents/skills/feature-workflow/scripts/run-toolchain.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> '$RUN_LOG'
if [ "\$(cat '$WORK/toolchain-exit')" != 0 ]; then
  printf '%s\n' '{"digest":"[lint] stand-in failure"}'
  exit 1
fi
exit 0
EOF
echo 0 > "$WORK/toolchain-exit"
git_commit_all "$P" fixture
git -C "$P" worktree add -q .workflow/.worktrees/s007_phase_1_shell_scripts -b wf/007-demo/s007_phase_1_shell_scripts
git -C "$P" worktree add -q .workflow/.worktrees/s007_integration_shell_scripts -b wf/007-demo/s007_integration_shell_scripts
WP1=$(cd "$P/.workflow/.worktrees/s007_phase_1_shell_scripts" && pwd -P)
WIG=$(cd "$P/.workflow/.worktrees/s007_integration_shell_scripts" && pwd -P)

mk_transcript() { # file prompt
  jq -cn --arg p "$2" '{type:"user",isSidechain:true,message:{role:"user",content:$p}}' > "$1"
  jq -cn '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:"ok"}]}}' >> "$1"
}
# stop_payload TRANSCRIPT AGENT_TYPE : a Claude SubagentStop payload whose cwd is the main checkout (a launch without isolation).
stop_payload() {
  jq -cn --arg t "$1" --arg at "$2" --arg c "$P" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,agent_id:"a1",agent_type:$at,agent_transcript_path:$t,last_assistant_message:"done",stop_hook_active:false,hook_event_name:"SubagentStop"}'
}
mk_transcript "$WORK/p1.jsonl" $'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-demo\nwork_type: shell-scripts\n```\n\nBuild the harness.'
mk_transcript "$WORK/p1-missing.jsonl" $'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/007-demo\nwork_type: test-harness\n```\n\nBuild the harness.'
mk_transcript "$WORK/ig.jsonl" $'```yaml launch-header\ntask_type: integration\nspec_dir: .workflow/specs/007-demo\nwork_type: shell-scripts\n```\n\nBatch.'
mk_transcript "$WORK/ig-missing.jsonl" $'```yaml launch-header\ntask_type: integration\nspec_dir: .workflow/specs/007-demo\nwork_type: test-harness\n```\n\nBatch.'

# audit TRANSCRIPT AGENT_TYPE : run the hook; sets OUT to its stdout, RC to its exit code and RUNS to the stand-in's log.
audit() {
  : > "$RUN_LOG"
  OUT=$(stop_payload "$1" "$2" | (cd "$P" && bash "$H/post-implementation-audit.sh" 2>/dev/null))
  RC=$?
  RUNS=$(cat "$RUN_LOG")
}
# run_cwd : the --cwd value of the single recorded toolchain run.
run_cwd() { awk '{ for (i = 1; i < NF; i++) if ($i == "--cwd") print $(i + 1) }' <<<"$RUNS"; }

echo "== Phase 1 launch (JRN-005)"
audit "$WORK/p1.jsonl" implementation
eq "JRN-005 Phase 1 stop with its agent worktree present runs the toolchain once" "$(grep -c . <<<"$RUNS")" 1
eq "JRN-005 Phase 1 stop runs the toolchain in s007_phase_1_shell_scripts" "$(run_cwd)" "$WP1"
check "JRN-005 Phase 1 stop passes --skip test" '[[ " $RUNS " == *" --skip test "* ]]' "$RUNS"
check "JRN-005 Phase 1 stop with a passing toolchain is allowed silently" '[ "$RC" = 0 ] && [ -z "$OUT" ]' "rc=$RC out=$OUT"

audit "$WORK/p1-missing.jsonl" implementation
eq "JRN-005 Phase 1 stop with its agent worktree missing does not run the toolchain" "$RUNS" ""
check "JRN-005 Phase 1 stop with its agent worktree missing is allowed with a warning" \
  '[ "$RC" = 0 ] && [ -z "$(jq -r ".decision // empty" <<<"$OUT")" ] && jq -r ".systemMessage // empty" <<<"$OUT" | grep -q "s007_phase_1_test_harness"' \
  "rc=$RC out=$OUT"

echo "== integration launch (JRN-005)"
audit "$WORK/ig.jsonl" integration
eq "JRN-005 integration stop with its agent worktree present runs the toolchain once" "$(grep -c . <<<"$RUNS")" 1
eq "JRN-005 integration stop runs the toolchain in s007_integration_shell_scripts" "$(run_cwd)" "$WIG"
check "JRN-005 integration stop runs the full toolchain (no --skip)" '[ -n "$RUNS" ] && [[ " $RUNS " != *" --skip "* ]]' "$RUNS"
echo 1 > "$WORK/toolchain-exit"
audit "$WORK/ig.jsonl" integration
check "JRN-005 integration stop with a failing toolchain is blocked" '[ "$(jq -r ".decision // empty" <<<"$OUT")" = block ]' "rc=$RC out=$OUT"
echo 0 > "$WORK/toolchain-exit"

audit "$WORK/ig-missing.jsonl" integration
eq "JRN-005 integration stop with its agent worktree missing does not run the toolchain" "$RUNS" ""
check "JRN-005 integration stop with its agent worktree missing is allowed with a warning" \
  '[ "$RC" = 0 ] && [ -z "$(jq -r ".decision // empty" <<<"$OUT")" ] && jq -r ".systemMessage // empty" <<<"$OUT" | grep -q "s007_integration_test_harness"' \
  "rc=$RC out=$OUT"

echo "== other agents still skipped"
audit "$WORK/ig.jsonl" fact-lookup
check "a fact-lookup stop is ignored" '[ "$RC" = 0 ] && [ -z "$OUT" ] && [ -z "$RUNS" ]' "rc=$RC out=$OUT runs=$RUNS"

echo "== SubagentStop wiring (JRN-005)"
# matcher_covers SETTINGS AGENT_TYPE : true when a SubagentStop group running the stop audit matches AGENT_TYPE.
# shellcheck disable=SC2329  # called from the eval'd check strings below
matcher_covers() {
  local m
  while IFS= read -r m; do
    if matcher_matches "$m" "$2"; then return 0; fi
  done < <(stop_audit_matchers "$1")
  return 1
}
TPL=$P/.agents/hooks/claude-settings.template.json
for agent in implementation integration; do
  check "JRN-005 template SubagentStop matcher covers $agent" 'matcher_covers "$TPL" "$agent"' "$(jq -c .hooks.SubagentStop "$TPL")"
  check "JRN-005 this repo's .claude/settings.json SubagentStop matcher covers $agent" 'matcher_covers "$REPO_ROOT/.claude/settings.json" "$agent"' \
    "$(jq -c .hooks.SubagentStop "$REPO_ROOT/.claude/settings.json")"
done
check "template SubagentStop matcher does not cover fact-lookup" '! matcher_covers "$TPL" fact-lookup'
eq "JRN-005 template has one SubagentStop group running the stop audit" "$(stop_audit_matchers "$TPL" | grep -c '')" 1
eq "JRN-005 this repo's .claude/settings.json has one SubagentStop group running the stop audit" \
  "$(stop_audit_matchers "$REPO_ROOT/.claude/settings.json" | grep -c '')" 1

shellcheck_files "shellcheck: post-implementation-audit.sh, this suite and fixtures/claude-settings.sh" "$H/post-implementation-audit.sh" \
  "${BASH_SOURCE[0]}" "$TESTS_DIR/fixtures/claude-settings.sh"
finish
