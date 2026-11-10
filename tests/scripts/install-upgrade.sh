#!/usr/bin/env bash
# Suite: install.sh (repo root): upgrade and project-owned files.
# Covers: upgrade that overwrites a changed file and removes a file dropped from the manifest while keeping files no
#   install shipped; project-owned files untouched by install, --force and upgrade (incl. .workflow/design-pattern-doc/
#   and .workflow/pr-quality/); .gitignore user lines kept. JRN-006: a project installed with the template whose stop audit
#   matched only implementation agents is left, after an upgrade, with one SubagentStop entry matching implementation and integration,
#   and with the retired write-guard hooks (spec-single-writer, tier-a, tier-b) removed, workflow-write-guard.sh wired in their place
#   and a user hook that shared their group kept, a re-run changing and printing nothing more; a .gitignore line an
#   earlier install wrote in its block and this one does not (.workflow/.cache-staging/) removed, the user line kept, the
#   summary naming it, and a re-run changing and printing nothing.
#   Matcher resolution on an upgrade to a template whose stop audit matches implementation|integration, from an old install
#   with user groups: JRN-011 without a terminal (template-only group merged, mixed group kept, also when its own hook is
#   a prompt hook, match-all and covering groups untouched, a Warnings line per merged or kept group, a third run writes
#   nothing); JRN-012 --matchers=merge|replace|keep
#   (one Warnings line per group, naming the mode), a bad mode, --dry-run with and without --matchers (writes nothing,
#   previews, never reads stdin), --force alone, a matcher that is not a plain alternation never merged (also under a
#   match-all template), a group running commands of two template groups (rewritten into the template's groups with the
#   template's hook settings in every mode; kept with a warning when it also runs a user hook), --matchers with no value,
#   a match-all template matcher dropped on merge and replace, a Codex hooks.json group under the same rule, a non-string
#   matcher kept with one Warnings line (also with --matchers=replace), a template matcher that is not a plain alternation
#   never merged; JRN-013 the prompt at a pseudo-terminal (script(1); skipped when no form of it works): its text, Enter
#   merges, r replaces, k keeps, a mixed group's prompt lists every hook, Enter keeps under a non-plain template matcher.
#   JRN-008: the upgrade re-run, the JRN-011 third run and the two-template-groups re-run each exit 0 as well as writing nothing.
# The scaffold under test is a copy of this repo's install.sh and .agents/ inside the fixture, so the repo is never written.
# Every install.sh run reads stdin from /dev/null, an open pipe or a pseudo-terminal, never from the caller's terminal, and
# the runs that could wait on input are killed after 20 s, so a prompting installer cannot hang the suite.
# Env: TEST_BASH=<bash binary> runs install.sh under another bash (default: bash).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/claude-settings.sh
source "$TESTS_DIR/fixtures/claude-settings.sh"
preflight
TEST_BASH=${TEST_BASH:-bash}

new_workdir
SC=$WORK/scaffold
mkdir -p "$SC"
cp "$REPO_ROOT/install.sh" "$SC/install.sh"
copy_agents "$SC"
git_init_repo "$SC"
git_commit_all "$SC" scaffold
# INST_FROM SCAFFOLD ARGS... : runs SCAFFOLD's install.sh with no input; INST runs the scaffold under test.
INST_FROM() {
  local scaffold=$1
  shift
  "$TEST_BASH" "$scaffold/install.sh" "$@" </dev/null
}
INST() { INST_FROM "$SC" "$@"; }

# snap DIR : one line per file (cksum) and symlink (target) outside .git, sorted.
snap() {
  (cd "$1" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r f; do
    if [ -L "$f" ]; then printf '%s -> %s\n' "$f" "$(readlink "$f")"; else cksum "$f"; fi
  done)
}
new_target() { rm -rf "$1"; git_init_repo "$1"; }
# clone_target SOURCE DEST : DEST becomes a copy of the target SOURCE (its .claude symlinks stay links).
clone_target() { rm -rf "$2"; cp -R "$1" "$2"; }

# The five readers below are called from check expressions, which shellcheck cannot see into.
# warning_lines OUTPUT : the "  - " lines of the Warnings block in install.sh output.
# shellcheck disable=SC2329
warning_lines() { printf '%s\n' "$1" | awk '/^Warnings:/ { w = 1; next } w && /^  - / { print; next } { w = 0 }'; }
# shellcheck disable=SC2329
warned_about() { warning_lines "$1" | grep -qF -- "$2"; }
# warned_once OUTPUT STRING... : true when exactly one Warnings line names the first STRING, and it holds every STRING.
# shellcheck disable=SC2329  # called from check expressions, which shellcheck cannot see into
warned_once() {
  local out=$1 lines
  shift
  lines=$(warning_lines "$out" | grep -F -- "$1")
  [ "$(printf '%s\n' "$lines" | grep -c .)" = 1 ] && contains_all "$lines" "$@"
}
# contains_all TEXT STRING... : true when TEXT contains every STRING.
# shellcheck disable=SC2329
contains_all() {
  local text=$1 s
  shift
  for s in "$@"; do printf '%s\n' "$text" | grep -qF -- "$s" || return 1; done
}
# mentions_words TEXT WORD... : true when TEXT has every WORD as a whole word, in any case.
# shellcheck disable=SC2329
mentions_words() {
  local text=$1 w
  shift
  for w in "$@"; do printf '%s\n' "$text" | grep -qiw -- "$w" || return 1; done
}

# The bounded runs below feed CMD from a pipe that hold_open keeps open until CMD's exit code is in a file, so CMD can
# wait on input without ever seeing the end of it. bash's wait on a background pipeline waits for every process in it,
# so the feeder must be stopped (the file created) before the pipeline is reaped.
RUN_SEQ=0
# shellcheck disable=SC2016  # the wrapper's script, run by bash -c
RECORD_RC='rc_file=$1; shift; "$@"; echo "$?" >"$rc_file"'
# hold_open RC_FILE [LINE] : prints LINE and a newline when LINE is given, then keeps stdout open until RC_FILE exists.
hold_open() {
  [ $# -lt 2 ] || printf '%s\n' "$2"
  while [ ! -e "$1" ]; do sleep 0.1; done
}
# finish_run PID SECS RC_FILE : waits up to SECS for the background pipeline ending in PID, killing PID on timeout; then
#   ends its feeder and reaps it. Sets RUN_RC to the exit code in RC_FILE, 124 when killed, "none" when none was written.
finish_run() {
  local pid=$1 secs=$2 rc_file=$3 ticks=0
  RUN_RC=""
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$ticks" -ge $((secs * 10)) ]; then
      kill "$pid" 2>/dev/null
      RUN_RC=124
      break
    fi
    sleep 0.1
    ticks=$((ticks + 1))
  done
  [ -n "$RUN_RC" ] || RUN_RC=$(cat "$rc_file" 2>/dev/null || echo none)
  touch "$rc_file"
  wait
}
# run_with_open_stdin SECS OUT CMD... : runs CMD with stdin an empty pipe that stays open, so any read waits; output to OUT.
#   Killed after SECS. Sets RUN_RC as finish_run does.
run_with_open_stdin() {
  local secs=$1 out=$2 rc_file
  shift 2
  RUN_SEQ=$((RUN_SEQ + 1))
  rc_file=$WORK/run-$RUN_SEQ.rc
  hold_open "$rc_file" | "$TEST_BASH" -c "$RECORD_RC" record-rc "$rc_file" "$@" >"$out" 2>&1 &
  finish_run $! "$secs" "$rc_file"
}

# The form of script(1) that gives a command a pseudo-terminal on this host: util-linux (Linux) or bsd (macOS); "" for none.
PTY_FORM=""
# pty_script_args RC_FILE CMD... : sets PTY_ARGS to the script(1) arguments, in the PTY_FORM form, that run CMD on a
#   pseudo-terminal and then write its exit code to RC_FILE (script(1) does not pass it on everywhere).
pty_script_args() {
  local rc_file=$1
  shift
  set -- "$TEST_BASH" -c "$RECORD_RC" record-rc "$rc_file" "$@"
  case "$PTY_FORM" in
    util-linux) PTY_ARGS=(-qec "$(printf '%q ' "$@")" /dev/null) ;;
    bsd) PTY_ARGS=(-q /dev/null "$@") ;;
  esac
}
# run_on_pty SECS ANSWER OUT CMD... : runs CMD on a pseudo-terminal, typing ANSWER and Enter, the terminal output in OUT.
#   The typed line waits in the terminal until CMD reads it. macOS script(1) passes the end of its own input straight to
#   CMD and does not exit before its input ends, which is why the input must stay open until CMD has finished.
#   Killed after SECS. Sets RUN_RC as finish_run does.
run_on_pty() {
  local secs=$1 answer=$2 out=$3 rc_file
  shift 3
  RUN_SEQ=$((RUN_SEQ + 1))
  rc_file=$WORK/pty-$RUN_SEQ.rc
  pty_script_args "$rc_file" "$@"
  hold_open "$rc_file" "$answer" | script "${PTY_ARGS[@]}" >"$out" 2>&1 &
  finish_run $! "$secs" "$rc_file"
}
# detect_pty_form : sets PTY_FORM to the first script(1) form that gives a command a terminal on stdin and stdout.
detect_pty_form() {
  command -v script >/dev/null 2>&1 || return 1
  for PTY_FORM in util-linux bsd; do
    run_on_pty 10 "" "$WORK/pty-probe.out" "$TEST_BASH" -c 'test -t 0 && test -t 1 && echo on-a-terminal'
    if [ "$RUN_RC" = 0 ] && grep -q on-a-terminal "$WORK/pty-probe.out"; then return 0; fi
  done
  PTY_FORM=""
  return 1
}

echo "== upgrade: overwrite changed files, remove files dropped from the manifest"
U=$WORK/up
new_target "$U"
INST "$U" >/dev/null 2>&1
mkdir -p "$U/.workflow"
echo '{"commit":"abc"}' >"$U/.workflow/data-structure-audit-state.jsonl"
echo "local edit" >>"$U/.agents/skills/feature-workflow/SKILL.md"
echo "user note" >"$U/.agents/skills/deps-audit/NOTES.local.md"
cp -R "$SC" "$WORK/sc2"
sed -i.bak '/^skills\/glab$/d; /^skills\/deps-audit$/d' "$WORK/sc2/.agents/install-manifest.txt"
rm -f "$WORK/sc2/.agents/install-manifest.txt.bak"
out=$("$TEST_BASH" "$WORK/sc2/install.sh" "$U" 2>&1 </dev/null)
eq "upgrade exits 0" "$?" 0
check "dropped skill removed (dir gone)" '[ ! -e "$U/.agents/skills/glab" ]'
check "dropped skill files removed, user file in it kept" '[ ! -e "$U/.agents/skills/deps-audit/SKILL.md" ] && [ -f "$U/.agents/skills/deps-audit/NOTES.local.md" ]'
check "removal reported" 'printf "%s" "$out" | grep -q "remove .agents/skills/glab/SKILL.md"'
check "locally edited scaffold file overwritten" 'cmp -s "$U/.agents/skills/feature-workflow/SKILL.md" "$SC/.agents/skills/feature-workflow/SKILL.md"'
check "file no install shipped is kept" '[ -f "$U/.workflow/data-structure-audit-state.jsonl" ]'
check "VERSION no longer lists the dropped skill" '! grep -q "^skills/glab/" "$U/.agents/VERSION" && grep -q "^skills/feature-workflow/SKILL.md$" "$U/.agents/VERSION"'
before=$(snap "$U")
"$TEST_BASH" "$WORK/sc2/install.sh" "$U" >/dev/null 2>&1 </dev/null
eq "JRN-008 the upgrade re-run exits 0" "$?" 0
eq "upgrade re-run changes nothing" "$(snap "$U")" "$before"

echo "== project-owned files untouched; .gitignore user lines kept"
P=$WORK/owned
new_target "$P"
mkdir -p "$P/.workflow/profiles" "$P/.workflow/decisions" "$P/.workflow/design-pattern-doc" "$P/.workflow/pr-quality" "$P/.workflow/deferred" "$P/.workflow/specs/001-x"
echo "implementation: {tier: strong, claude: opus}" >"$P/.workflow/model-map.yaml"
echo "p" >"$P/.workflow/profiles/web.md"
echo "g" >"$P/.workflow/GLOSSARY.md"
echo "r" >"$P/.workflow/rules.md"
echo "a" >"$P/.workflow/decisions/0001.md"
echo "c" >"$P/.workflow/design-pattern-doc/conventions.md"
echo "q" >"$P/.workflow/pr-quality/my-check.md"
echo "d" >"$P/.workflow/deferred/x.md"
echo "s" >"$P/.workflow/specs/001-x/spec.md"
printf 'node_modules/\n*.log' >"$P/.gitignore"
owned() { (cd "$P" && cksum .workflow/model-map.yaml .workflow/profiles/web.md .workflow/GLOSSARY.md .workflow/rules.md .workflow/decisions/0001.md .workflow/design-pattern-doc/conventions.md .workflow/pr-quality/my-check.md .workflow/deferred/x.md .workflow/specs/001-x/spec.md); }
before=$(owned)
INST "$P" >/dev/null 2>&1
INST "$P" --force >/dev/null 2>&1
"$TEST_BASH" "$WORK/sc2/install.sh" "$P" --force >/dev/null 2>&1 </dev/null
eq "project-owned files byte-identical after install, --force and upgrade" "$(owned)" "$before"
check "project-owned .workflow/ gained no files" '[ "$(find "$P/.workflow" -type f | wc -l | tr -d " ")" = 9 ]'
check ".gitignore user lines kept, block added once" 'grep -qx "node_modules/" "$P/.gitignore" && grep -qx "\*.log" "$P/.gitignore" && [ "$(grep -c "^.workflow/specs/\*/.step$" "$P/.gitignore")" = 1 ] && [ "$(grep -c "^.workflow/initiatives/\*/.step$" "$P/.gitignore")" = 1 ]'

echo "== upgrade from the template whose stop audit matched only implementation agents (JRN-006)"
SCO=$WORK/sc-old
cp -R "$SC" "$SCO"
use_old_claude_settings "$SCO"
O=$WORK/old-install
new_target "$O"
INST_FROM "$SCO" "$O" --host claude >/dev/null 2>&1
OS=$O/.claude/settings.json
eq "JRN-006 the old install's stop audit matches implementation only" "$(stop_audit_matchers "$OS")" implementation
# The old template still wires the write guards the merged write guard replaced; a user hook shares their group.
RETIRED_GUARDS="spec-single-writer-guard.sh tier-a-write-guard.sh tier-b-write-guard.sh"
USER_WRITE_HOOK=./scripts/user-write-hook.sh
add_user_hook "$OS" PreToolUse tier-a-write-guard.sh "$USER_WRITE_HOOK"
t "JRN-006 the upgrade exits 0" 0 INST "$O" --host claude
for retired in $RETIRED_GUARDS; do
  eq "the upgrade removes the retired hook $retired" "$(group_matchers "$OS" PreToolUse "$retired")" ""
done
eq "the upgrade wires workflow-write-guard.sh under Write|Edit|NotebookEdit" \
  "$(group_matchers "$OS" PreToolUse workflow-write-guard.sh)" 'Write|Edit|NotebookEdit'
eq "the user hook that shared the retired hooks' group is kept under its matcher" \
  "$(group_matchers "$OS" PreToolUse "$USER_WRITE_HOOK")" 'Write|Edit|NotebookEdit'
eq "JRN-006 after the upgrade: one SubagentStop entry in all" "$(jq '.hooks.SubagentStop | length' "$OS")" 1
eq "JRN-006 after the upgrade: one SubagentStop group runs the stop audit" "$(stop_audit_matchers "$OS" | grep -c '')" 1
for agent in implementation integration; do
  check "JRN-006 after the upgrade: the stop audit matcher matches $agent" 'matcher_matches "$(stop_audit_matchers "$OS")" "$agent"' \
    "$(jq -c .hooks.SubagentStop "$OS")"
done
before=$(snap "$O")
out=$(INST "$O" --host claude 2>&1)
eq "a re-run after removing the retired hooks exits 0" "$?" 0
eq "...and changes nothing" "$(snap "$O")" "$before"
check "...and prints no upgrade summary" '! grep -q "^Upgrade from an older install" <<<"$out"' "$out"

echo "== a .gitignore line an earlier install wrote in the block and this one no longer does"
G=$WORK/gitignore-retired
new_target "$G"
INST "$G" --host claude >/dev/null 2>&1
printf 'node_modules/\n' >>"$G/.gitignore"
awk '$0 == ".workflow/.worktrees/" { print ".workflow/.cache-staging/" } { print }' "$G/.gitignore" >"$WORK/gi.tmp" && mv "$WORK/gi.tmp" "$G/.gitignore"
check "the fixture has the retired line inside the block" 'grep -qx ".workflow/.cache-staging/" "$G/.gitignore"'
out=$(INST "$G" --host claude 2>&1)
eq "the upgrade exits 0" "$?" 0
check "the retired line is gone" '! grep -q "cache-staging" "$G/.gitignore"'
check "the user line after the block is kept" 'grep -qx "node_modules/" "$G/.gitignore"'
check "the summary names the line" 'grep -qF "the .gitignore line(s) .workflow/.cache-staging/" <<<"$out"' "$out"
before=$(snap "$G")
out=$(INST "$G" --host claude 2>&1)
eq "a re-run changes nothing" "$(snap "$G")" "$before"
check "a re-run prints no summary" '! grep -q "^Upgrade from an older install" <<<"$out"' "$out"

echo "== matcher resolution fixtures: the template upgraded to and the old install"
# The template the upgrade goes to gets its stop audit widened here, so these cases hold whether or not the repo's own
# template has been widened yet.
SCW=$WORK/sc-widened
cp -R "$SC" "$SCW"
widen_stop_audit_matcher "$SCW/.agents/hooks/claude-settings.template.json"
INSTW() { INST_FROM "$SCW" "$@"; }
OLD_BASE=$WORK/old-base
new_target "$OLD_BASE"
INST_FROM "$SCO" "$OLD_BASE" --host claude >/dev/null 2>&1
STOP_AUDIT=post-implementation-audit.sh
USER_STOP_HOOK=./scripts/notify-stop.sh
eq "the widened template's stop audit matches implementation|integration" \
  "$(stop_audit_matchers "$SCW/.agents/hooks/claude-settings.template.json")" 'implementation|integration'
FOO_BASE=$WORK/foo-base
clone_target "$OLD_BASE" "$FOO_BASE"
set_group_matcher "$FOO_BASE/.claude/settings.json" SubagentStop "$STOP_AUDIT" 'implementation|foo'
eq "the implementation|foo target's stop audit matcher" "$(stop_audit_matchers "$FOO_BASE/.claude/settings.json")" 'implementation|foo'

echo "== no terminal: template-only group merged, mixed group kept, match-all and covering groups untouched (JRN-011)"
N=$WORK/no-terminal
NS=$N/.claude/settings.json
clone_target "$OLD_BASE" "$N"
add_stop_audit_group "$NS" reviewer "$USER_STOP_HOOK"
drop_group_matcher "$NS" PostToolUseFailure evidence-capture.sh
set_group_matcher "$NS" PostToolUse evidence-capture.sh '*'
set_group_matcher "$NS" PreToolUse pre-launch.sh ''
set_group_matcher "$NS" PreToolUse worktree-write-guard.sh 'NotebookEdit|Edit|Write|Bash|MultiEdit'
match_all_groups() {
  group_json "$NS" PostToolUseFailure evidence-capture.sh
  group_json "$NS" PostToolUse evidence-capture.sh
  group_json "$NS" PreToolUse pre-launch.sh
}
mixed_before=$(group_json "$NS" SubagentStop "$USER_STOP_HOOK")
match_all_before=$(match_all_groups)
covering_before=$(group_json "$NS" PreToolUse worktree-write-guard.sh)
check "JRN-011 the fixture has three match-all groups: no matcher, \"*\" and \"\"" \
  '[ "$(printf "%s\n" "$match_all_before" | jq -s -c "map(.matcher)")" = "[null,\"*\",\"\"]" ]' "$match_all_before"
out=$(INSTW "$N" --host claude 2>&1)
eq "JRN-011 the upgrade without a terminal exits 0" "$?" 0
eq "JRN-011 the template-only stop-audit group is merged to implementation|integration, the mixed group keeps reviewer" \
  "$(group_matchers "$NS" SubagentStop "$STOP_AUDIT")" "$(printf '%s\n%s' 'implementation|integration' reviewer)"
eq "JRN-011 no SubagentStop group is added" "$(jq '.hooks.SubagentStop | length' "$NS")" 2
eq "JRN-011 one SubagentStop group runs the stop audit alone" \
  "$(jq '[.hooks.SubagentStop[] | select(.hooks | length == 1 and (.[0].command | contains("post-implementation-audit.sh")))] | length' "$NS")" 1
eq "JRN-011 the mixed group is kept as it was" "$(group_json "$NS" SubagentStop "$USER_STOP_HOOK")" "$mixed_before"
eq "JRN-011 the match-all groups are untouched" "$(match_all_groups)" "$match_all_before"
eq "JRN-011 the covering group is untouched" "$(group_json "$NS" PreToolUse worktree-write-guard.sh)" "$covering_before"
check "JRN-011 a Warnings line names the merged matcher implementation|integration" \
  'warned_about "$out" "implementation|integration"' "$out"
check "JRN-011 a Warnings line names the kept mixed group's matcher reviewer" 'warned_about "$out" reviewer' "$out"
check "JRN-011 no Warnings line names a hook of a match-all or covering group" \
  '! warning_lines "$out" | grep -qE "evidence-capture|pre-launch|worktree-write-guard"' "$out"
before=$(snap "$N")
INSTW "$N" --host claude >/dev/null 2>&1
eq "JRN-008 the JRN-011 third run exits 0" "$?" 0
eq "JRN-011 a third run writes nothing" "$(snap "$N")" "$before"

echo "== --matchers answers every group; --dry-run previews; --force alone; a non-plain matcher (JRN-012)"
for mode_and_matcher in 'merge implementation|foo|integration' 'replace implementation|integration' 'keep implementation|foo'; do
  mode=${mode_and_matcher%% *}
  want=${mode_and_matcher#* }
  X=$WORK/matchers-$mode
  clone_target "$FOO_BASE" "$X"
  out=$(INSTW "$X" --host claude "--matchers=$mode" 2>&1)
  eq "JRN-012 --matchers=$mode exits 0" "$?" 0
  eq "JRN-012 --matchers=$mode leaves the stop-audit matcher $want" \
    "$(group_matchers "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")" "$want"
  check "JRN-012 --matchers=$mode: one Warnings line names the stop-audit group, the mode and the matcher $want" \
    'warned_once "$out" "$STOP_AUDIT" "--matchers=$mode" "$want"' "$out"
done

X=$WORK/matchers-bogus
clone_target "$FOO_BASE" "$X"
before=$(snap "$X")
out=$(INSTW "$X" --host claude --matchers=bogus 2>&1)
eq "JRN-012 --matchers=bogus exits 2" "$?" 2
check "JRN-012 the --matchers=bogus error names merge, replace and keep" 'mentions_words "$out" merge replace keep' "$out"
eq "JRN-012 --matchers=bogus writes nothing" "$(snap "$X")" "$before"

for dry_case in 'default implementation|foo|integration' 'replace implementation|integration'; do
  mode=${dry_case%% *}
  want=${dry_case#* }
  X=$WORK/dry-$mode
  clone_target "$FOO_BASE" "$X"
  before=$(snap "$X")
  if [ "$mode" = default ]; then
    label="--dry-run without --matchers"
    run_with_open_stdin 20 "$X.out" "$TEST_BASH" "$SCW/install.sh" "$X" --host claude --dry-run
  else
    label="--dry-run --matchers=$mode"
    run_with_open_stdin 20 "$X.out" "$TEST_BASH" "$SCW/install.sh" "$X" --host claude --dry-run "--matchers=$mode"
  fi
  out=$(cat "$X.out")
  eq "JRN-012 $label ends within 20 s on an open, empty stdin, with exit 0" "$RUN_RC" 0
  eq "JRN-012 $label writes nothing" "$(snap "$X")" "$before"
  check "JRN-012 $label previews the matcher $want" 'printf "%s\n" "$out" | grep -qF -- "$want"' "$out"
done

X=$WORK/force-alone
clone_target "$FOO_BASE" "$X"
t "JRN-012 --force alone exits 0" 0 INSTW "$X" --host claude --force
eq "JRN-012 --force alone sets the matcher as the no-terminal rule does (merged)" \
  "$(group_matchers "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")" 'implementation|foo|integration'

NON_PLAIN_BASE=$WORK/non-plain-base
clone_target "$OLD_BASE" "$NON_PLAIN_BASE"
set_group_matcher "$NON_PLAIN_BASE/.claude/settings.json" SubagentStop "$STOP_AUDIT" '(a|b)c'
for how in no-terminal matchers-merge; do
  X=$WORK/non-plain-$how
  clone_target "$NON_PLAIN_BASE" "$X"
  if [ "$how" = no-terminal ]; then
    out=$(INSTW "$X" --host claude 2>&1)
  else
    out=$(INSTW "$X" --host claude --matchers=merge 2>&1)
  fi
  got=$(group_matchers "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")
  check "JRN-012 the non-plain matcher (a|b)c is kept ($how)" '[ "$got" = "(a|b)c" ]' "got=$got"
  if [ "$how" = no-terminal ]; then
    check "JRN-012 a Warnings line names the non-plain matcher (a|b)c (no terminal)" 'warned_about "$out" "(a|b)c"' "$out"
  fi
done

echo "== a group running two template groups' commands; a non-plain matcher under a match-all template (JRN-012)"
# SPLIT_BASE's Write|Edit|NotebookEdit group also runs the git guard, whose template group is Bash, and its SessionStart
# group is narrowed to a matcher that is not a plain | list, while the template's SessionStart group matches everything.
GIT_GUARD=block-destructive-git.sh
WRITE_GUARD=workflow-write-guard.sh
SESSION_MATCHER='^(startup|resume)$'
SPLIT_BASE=$WORK/split-base
# A current install, so the group's write guard is one the template still ships rather than a retired one the upgrade removes.
new_target "$SPLIT_BASE"
INSTW "$SPLIT_BASE" --host claude >/dev/null 2>&1
edit_settings "$SPLIT_BASE/.claude/settings.json" '
  [.hooks.PreToolUse[] | select(runs($git)) | .hooks[]] as $git_hooks
  | .hooks.PreToolUse |= (map(select(runs($git) | not)) | map(if runs($write) then .hooks += $git_hooks else . end))' \
  --arg git "$GIT_GUARD" --arg write "$WRITE_GUARD"
set_group_matcher "$SPLIT_BASE/.claude/settings.json" SessionStart session-start-resume.sh "$SESSION_MATCHER"
eq "the split fixture runs the git guard in the Write|Edit|NotebookEdit group" \
  "$(group_matchers "$SPLIT_BASE/.claude/settings.json" PreToolUse "$GIT_GUARD")" 'Write|Edit|NotebookEdit'
# pre_tool_use_is_the_templates SETTINGS : true when PreToolUse has the template's four groups and no command twice.
# shellcheck disable=SC2329  # called from check expressions, which shellcheck cannot see into
pre_tool_use_is_the_templates() {
  jq -e '.hooks.PreToolUse | length == 4 and ([.[].hooks[].command] | length == (unique | length))' "$1" >/dev/null
}
# warned_together OUTPUT STRING... : true when one Warnings line holds every STRING.
# shellcheck disable=SC2329  # called from check expressions, which shellcheck cannot see into
warned_together() {
  local line
  while IFS= read -r line; do contains_all "$line" "${@:2}" && return 0; done < <(warning_lines "$1")
  return 1
}
# A rewritten group's hooks take the template's hook objects, so a timeout of the user's is replaced; the warning says so.
# shellcheck disable=SC2034  # read by a check expression, which shellcheck cannot see into
TEMPLATE_HOOK_SETTINGS="with the template hook settings"
for split_case in 'no-terminal kept' 'merge kept' 'replace dropped' 'keep kept'; do
  how=${split_case%% *}
  session_start_outcome=${split_case#* }
  X=$WORK/split-$how
  XS=$X/.claude/settings.json
  clone_target "$SPLIT_BASE" "$X"
  if [ "$how" = no-terminal ]; then
    out=$(INSTW "$X" --host claude 2>&1)
  else
    out=$(INSTW "$X" --host claude "--matchers=$how" 2>&1)
  fi
  eq "JRN-012 two template groups in one group ($how): exits 0" "$?" 0
  eq "JRN-012 two template groups in one group ($how): the git guard runs under the template's Bash" \
    "$(group_matchers "$XS" PreToolUse "$GIT_GUARD")" Bash
  eq "JRN-012 two template groups in one group ($how): the write guard runs under the template's Write|Edit|NotebookEdit" \
    "$(group_matchers "$XS" PreToolUse "$WRITE_GUARD")" 'Write|Edit|NotebookEdit'
  check "JRN-012 two template groups in one group ($how): PreToolUse has one group per template group, no command twice" \
    'pre_tool_use_is_the_templates "$XS"' "$(jq -c .hooks.PreToolUse "$XS")"
  check "JRN-012 two template groups in one group ($how): one Warnings line names PreToolUse, its commands and the template hook settings" \
    'warned_once "$out" "$GIT_GUARD" hooks.PreToolUse "$WRITE_GUARD" "$TEMPLATE_HOOK_SETTINGS"' "$out"
  if [ "$session_start_outcome" = kept ]; then
    eq "JRN-012 the non-plain SessionStart matcher under a match-all template is kept ($how)" \
      "$(group_matchers "$XS" SessionStart session-start-resume.sh)" "$SESSION_MATCHER"
    check "JRN-012 a Warnings line names the kept SessionStart matcher ($how)" 'warned_about "$out" "$SESSION_MATCHER"' "$out"
  else
    eq "JRN-012 --matchers=replace drops the non-plain SessionStart matcher for the match-all template" \
      "$(group_matchers "$XS" SessionStart session-start-resume.sh)" '<none>'
  fi
done
before=$(snap "$WORK/split-no-terminal")
INSTW "$WORK/split-no-terminal" --host claude >/dev/null 2>&1
eq "JRN-008 two template groups in one group: the re-run exits 0" "$?" 0
eq "JRN-012 two template groups in one group: a re-run writes nothing" "$(snap "$WORK/split-no-terminal")" "$before"

USER_PRE_HOOK=./scripts/user-pre-tool.sh
SPLIT_MIXED_BASE=$WORK/split-mixed-base
clone_target "$SPLIT_BASE" "$SPLIT_MIXED_BASE"
add_user_hook "$SPLIT_MIXED_BASE/.claude/settings.json" PreToolUse "$GIT_GUARD" "$USER_PRE_HOOK"
pre_tool_use_before=$(jq -c .hooks.PreToolUse "$SPLIT_MIXED_BASE/.claude/settings.json")
for how in no-terminal replace; do
  X=$WORK/split-mixed-$how
  clone_target "$SPLIT_MIXED_BASE" "$X"
  if [ "$how" = no-terminal ]; then
    out=$(INSTW "$X" --host claude 2>&1)
  else
    out=$(INSTW "$X" --host claude "--matchers=$how" 2>&1)
  fi
  eq "JRN-012 two template groups and a user hook in one group ($how): PreToolUse is kept as it was" \
    "$(jq -c .hooks.PreToolUse "$X/.claude/settings.json")" "$pre_tool_use_before"
  check "JRN-012 two template groups and a user hook in one group ($how): a Warnings line names the group's hooks" \
    'warned_together "$out" hooks.PreToolUse "$GIT_GUARD" "$WRITE_GUARD" "$USER_PRE_HOOK"' "$out"
done

echo "== edges: --matchers with no value, a match-all template matcher, a Codex hooks.json group, a non-string matcher (JRN-012)"
X=$WORK/matchers-no-value
clone_target "$FOO_BASE" "$X"
before=$(snap "$X")
t "JRN-012 --matchers with no value exits 2" 2 INSTW "$X" --host claude --matchers
eq "JRN-012 --matchers with no value writes nothing" "$(snap "$X")" "$before"
for empty_form in '--matchers=' "--matchers ''"; do
  if [ "$empty_form" = '--matchers=' ]; then
    X=$WORK/matchers-empty-joined
    clone_target "$FOO_BASE" "$X"
    before=$(snap "$X")
    out=$(INSTW "$X" --host claude --matchers= 2>&1)
  else
    X=$WORK/matchers-empty-argument
    clone_target "$FOO_BASE" "$X"
    before=$(snap "$X")
    out=$(INSTW "$X" --host claude --matchers '' 2>&1)
  fi
  eq "JRN-012 $empty_form exits 2" "$?" 2
  check "JRN-012 the $empty_form error names merge, replace and keep" 'mentions_words "$out" merge replace keep' "$out"
  eq "JRN-012 $empty_form writes nothing" "$(snap "$X")" "$before"
done

SCM=$WORK/sc-match-all
cp -R "$SC" "$SCM"
drop_group_matcher "$SCM/.agents/hooks/claude-settings.template.json" SubagentStop "$STOP_AUDIT"
for mode in merge replace; do
  X=$WORK/match-all-template-$mode
  clone_target "$FOO_BASE" "$X"
  INST_FROM "$SCM" "$X" --host claude "--matchers=$mode" >/dev/null 2>&1
  eq "JRN-012 a match-all template matcher: --matchers=$mode drops the stop-audit group's matcher" \
    "$(group_matchers "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")" '<none>'
done

X=$WORK/codex-hooks
new_target "$X"
INSTW "$X" --host codex >/dev/null 2>&1
set_group_matcher "$X/.codex/hooks.json" PreToolUse block-destructive-git.sh Read
out=$(INSTW "$X" --host codex 2>&1)
eq "JRN-012 a Codex hooks.json group follows the same rule: Read with the template's Bash merges to Read|Bash" \
  "$(group_matchers "$X/.codex/hooks.json" PreToolUse block-destructive-git.sh)" 'Read|Bash'
check "JRN-012 a Warnings line names the merged Codex matcher Read|Bash" 'warned_about "$out" "Read|Bash"' "$out"

NON_STRING_BASE=$WORK/non-string-base
clone_target "$OLD_BASE" "$NON_STRING_BASE"
edit_settings "$NON_STRING_BASE/.claude/settings.json" '.hooks.SubagentStop |= map(if runs($c) then .matcher = 5 else . end)' \
  --arg c "$STOP_AUDIT"
non_string_before=$(jq -c .hooks.SubagentStop "$NON_STRING_BASE/.claude/settings.json")
for how in no-terminal replace; do
  X=$WORK/non-string-$how
  clone_target "$NON_STRING_BASE" "$X"
  if [ "$how" = no-terminal ]; then
    out=$(INSTW "$X" --host claude 2>&1)
  else
    out=$(INSTW "$X" --host claude "--matchers=$how" 2>&1)
  fi
  eq "JRN-012 a non-string matcher is left alone ($how)" "$(jq -c .hooks.SubagentStop "$X/.claude/settings.json")" "$non_string_before"
  check "JRN-012 one Warnings line names the non-string matcher's event and hooks and says why it is kept ($how)" \
    'warned_once "$out" "$STOP_AUDIT" hooks.SubagentStop "not a string"' "$out"
done

X=$WORK/prompt-hook
clone_target "$OLD_BASE" "$X"
edit_settings "$X/.claude/settings.json" \
  '.hooks.SubagentStop |= map(if runs($c) then .hooks += [{type: "prompt", prompt: "Check the summary"}] else . end)' \
  --arg c "$STOP_AUDIT"
prompt_hook_group_before=$(group_json "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")
out=$(INSTW "$X" --host claude 2>&1)
eq "JRN-011 a group running the stop audit and a prompt hook is kept as it was (no terminal)" \
  "$(group_json "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")" "$prompt_hook_group_before"
check "JRN-011 one Warnings line names the kept group's prompt hook (no terminal)" \
  'warned_once "$out" "$STOP_AUDIT" kept "\"type\":\"prompt\""' "$out"

echo "== a template matcher that is not a plain | list is never merged (JRN-012)"
SCN=$WORK/sc-non-plain-template
NON_PLAIN_TEMPLATE_MATCHER='^(implementation|integration)$'
cp -R "$SC" "$SCN"
set_group_matcher "$SCN/.agents/hooks/claude-settings.template.json" SubagentStop "$STOP_AUDIT" "$NON_PLAIN_TEMPLATE_MATCHER"
X=$WORK/non-plain-template
clone_target "$FOO_BASE" "$X"
out=$(INST_FROM "$SCN" "$X" --host claude --matchers=merge 2>&1)
eq "JRN-012 --matchers=merge keeps implementation|foo under a non-plain template matcher" \
  "$(group_matchers "$X/.claude/settings.json" SubagentStop "$STOP_AUDIT")" 'implementation|foo'
check "JRN-012 one Warnings line says the template matcher is not a plain | list" \
  'warned_once "$out" "$STOP_AUDIT" "since the template matcher" "not a plain | list"' "$out"

echo "== the prompt at a terminal (JRN-013)"
# pty_upgrade NAME ANSWER TARGET : upgrades a copy of TARGET at $WORK/pty-NAME on a pseudo-terminal, typing ANSWER.
#   Sets PTY_DIR and PTY_OUT (what the terminal showed), and RUN_RC.
pty_upgrade() {
  PTY_DIR=$WORK/pty-$1
  clone_target "$3" "$PTY_DIR"
  run_on_pty 20 "$2" "$PTY_DIR.out" "$TEST_BASH" "$SCW/install.sh" "$PTY_DIR" --host claude
  PTY_OUT=$(cat "$PTY_DIR.out")
}
pty_matcher() { group_matchers "$PTY_DIR/.claude/settings.json" SubagentStop "$STOP_AUDIT"; }
MIXED_BASE=$WORK/mixed-base
clone_target "$FOO_BASE" "$MIXED_BASE"
add_user_hook "$MIXED_BASE/.claude/settings.json" SubagentStop "$STOP_AUDIT" "$USER_STOP_HOOK"
if ! detect_pty_form; then
  for case_name in "Enter merges" "r replaces" "k keeps" "a mixed group's prompt lists every hook" \
    "Enter keeps a group whose template matcher is not a plain | list"; do
    skip "JRN-013 $case_name" "neither script -qec (util-linux) nor script -q /dev/null (macOS) gives a pseudo-terminal here"
  done
else
  pty_upgrade enter "" "$FOO_BASE"
  eq "JRN-013 Enter: the upgrade ends within 20 s with exit 0" "$RUN_RC" 0
  check "JRN-013 the prompt names the event SubagentStop and the command $STOP_AUDIT" \
    'contains_all "$PTY_OUT" SubagentStop "$STOP_AUDIT"' "$PTY_OUT"
  check "JRN-013 the prompt shows the current, replace and merge lines" \
    'mentions_words "$PTY_OUT" current replace merge && contains_all "$PTY_OUT" "implementation|foo" "implementation|integration" "implementation|foo|integration"' \
    "$PTY_OUT"
  eq "JRN-013 Enter merges" "$(pty_matcher)" 'implementation|foo|integration'

  pty_upgrade replace r "$FOO_BASE"
  eq "JRN-013 r: the upgrade ends within 20 s with exit 0" "$RUN_RC" 0
  eq "JRN-013 r replaces" "$(pty_matcher)" 'implementation|integration'

  pty_upgrade keep k "$FOO_BASE"
  eq "JRN-013 k: the upgrade ends within 20 s with exit 0" "$RUN_RC" 0
  eq "JRN-013 k keeps" "$(pty_matcher)" 'implementation|foo'

  mixed_before=$(group_json "$MIXED_BASE/.claude/settings.json" SubagentStop "$STOP_AUDIT")
  pty_upgrade mixed-keep k "$MIXED_BASE"
  eq "JRN-013 mixed group, k: the upgrade ends within 20 s with exit 0" "$RUN_RC" 0
  check "JRN-013 a mixed group's prompt lists every hook in it" 'contains_all "$PTY_OUT" "$STOP_AUDIT" "$USER_STOP_HOOK"' "$PTY_OUT"
  eq "JRN-013 k keeps the mixed group as it was" "$(group_json "$PTY_DIR/.claude/settings.json" SubagentStop "$STOP_AUDIT")" "$mixed_before"

  PTY_DIR=$WORK/pty-non-plain-template
  clone_target "$FOO_BASE" "$PTY_DIR"
  run_on_pty 20 "" "$PTY_DIR.out" "$TEST_BASH" "$SCN/install.sh" "$PTY_DIR" --host claude
  PTY_OUT=$(cat "$PTY_DIR.out")
  eq "JRN-013 non-plain template matcher, Enter: the upgrade ends within 20 s with exit 0" "$RUN_RC" 0
  check "JRN-013 the prompt says merge is not offered since the template matcher is not a plain | list" \
    'contains_all "$PTY_OUT" "merge:   not offered, since the template matcher"' "$PTY_OUT"
  eq "JRN-013 Enter keeps a group whose template matcher is not a plain | list" "$(pty_matcher)" 'implementation|foo'
fi

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
