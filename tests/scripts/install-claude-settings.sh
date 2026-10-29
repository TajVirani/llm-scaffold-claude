#!/usr/bin/env bash
# Suite: install.sh (repo root): Claude settings merge and refusals.
# Covers: settings merge over user settings (user keys, hooks and deny entries kept, deny unioned without duplicates,
#   outputStyle and statusLine kept with a warning, --force replaces them); refusals that write nothing (real
#   .claude/skills dir, symlink pointing elsewhere, wrong-type settings key, invalid JSON) and their --force paths.
#   JRN-006: a fresh install has one SubagentStop entry, running the stop audit for implementation and integration agents.
# The scaffold under test is a copy of this repo's install.sh and .agents/ inside the fixture, so the repo is never written.
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
INST() { "$TEST_BASH" "$SC/install.sh" "$@"; }

# snap DIR : one line per file (cksum) and symlink (target) outside .git, sorted.
snap() {
  (cd "$1" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r f; do
    if [ -L "$f" ]; then printf '%s -> %s\n' "$f" "$(readlink "$f")"; else cksum "$f"; fi
  done)
}
new_target() { rm -rf "$1"; git_init_repo "$1"; }

echo "== Claude settings merge over user settings"
M=$WORK/merge
new_target "$M"
mkdir -p "$M/.claude"
cat >"$M/.claude/settings.json" <<'EOF'
{
  "outputStyle": "Explanatory",
  "statusLine": {"type": "command", "command": "my-status.sh"},
  "enabledPlugins": {"foo@bar": true},
  "env": {"FOO": "1"},
  "permissions": {"allow": ["Bash(ls:*)"], "deny": ["Read(.env)", "Edit(.workflow/cache/**)"]},
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/block-destructive-git.sh", "timeout": 10}]},
      {"matcher": "Read", "hooks": [{"type": "command", "command": "my-read-hook.sh"}]}
    ],
    "Stop": [{"hooks": [{"type": "command", "command": "my-stop.sh"}]}]
  }
}
EOF
out=$(INST "$M" --host claude 2>&1)
eq "merge exits 0" "$?" 0
S=$M/.claude/settings.json
eq "outputStyle kept" "$(jq -r .outputStyle "$S")" "Explanatory"
check "outputStyle warning printed" 'printf "%s" "$out" | grep -q "outputStyle: keeping your"'
eq "statusLine kept" "$(jq -r .statusLine.command "$S")" "my-status.sh"
check "statusLine warning printed" 'printf "%s" "$out" | grep -q "statusLine: keeping your"'
eq "unrelated user keys kept" "$(jq -c '[.enabledPlugins, .env]' "$S")" '[{"foo@bar":true},{"FOO":"1"}]'
eq "user allow rule kept first, template allow rules appended" "$(jq -c '.permissions.allow | [.[0], (index("Bash(git status:*)") != null)]' "$S")" '["Bash(ls:*)",true]'
eq "deny unioned, user first, no duplicates" "$(jq -c .permissions.deny "$S")" '["Read(.env)","Edit(.workflow/cache/**)","Edit(.workflow/specs/*/.step)","Edit(.workflow/initiatives/*/.step)"]'
check "user hooks kept" '[ "$(jq -r ".hooks.Stop[0].hooks[0].command" "$S")" = my-stop.sh ] && jq -e "[.hooks.PreToolUse[].hooks[].command] | index(\"my-read-hook.sh\")" "$S" >/dev/null'
eq "block-destructive-git not duplicated" "$(jq '[.hooks.PreToolUse[].hooks[].command | select(test("block-destructive-git"))] | length' "$S")" 1
# shellcheck disable=SC2034  # used inside the eval'd check below
tpl_cmds=$(jq -r '[.hooks[][].hooks[].command] | sort | .[]' "$SC/.agents/hooks/claude-settings.template.json")
# shellcheck disable=SC2034
got_cmds=$(jq -r '[.hooks[][].hooks[].command] | sort | .[]' "$S")
check "every template hook command present" '[ -z "$(comm -23 <(printf "%s\n" "$tpl_cmds") <(printf "%s\n" "$got_cmds"))" ]'
eq "PostToolUseFailure event added with its Bash group" "$(jq -c '[.hooks.PostToolUseFailure[] | {matcher, c: [.hooks[].command]}]' "$S")" "$(jq -c '[.hooks.PostToolUseFailure[] | {matcher, c: [.hooks[].command]}]' "$SC/.agents/hooks/claude-settings.template.json")"
before=$(snap "$M")
INST "$M" --host claude >/dev/null 2>&1
eq "merge re-run changes nothing" "$(snap "$M")" "$before"
t "--force run" 0 INST "$M" --host claude --force
eq "--force replaces outputStyle" "$(jq -r .outputStyle "$S")" "Concise Technical"
eq "--force replaces statusLine" "$(jq -c .statusLine "$S")" "$(jq -c .statusLine "$SC/.agents/hooks/claude-settings.template.json")"
eq "--force keeps user keys" "$(jq -c .env "$S")" '{"FOO":"1"}'

echo "== refusals write nothing"
R=$WORK/refuse
new_target "$R"
mkdir -p "$R/.claude/skills/mine"
echo "x" >"$R/.claude/skills/mine/SKILL.md"
before=$(snap "$R")
out=$(INST "$R" 2>&1)
eq "real .claude/skills dir: exit 1" "$?" 1
check "...names the directory and --force" 'printf "%s" "$out" | grep -q ".claude/skills is a real directory" && printf "%s" "$out" | grep -q -- "--force"'
eq "...and nothing was written" "$(snap "$R")" "$before"
t "real .claude/skills dir with --force" 0 INST "$R" --force
eq "--force: .claude/skills is now the symlink" "$(readlink "$R/.claude/skills")" "../.agents/skills"
check "--force: old dir kept as a backup" 'ls "$R/.claude" | grep -q "^skills.backup-" && [ -f "$R/.claude/$(ls "$R/.claude" | grep "^skills.backup-")/mine/SKILL.md" ]'
R2=$WORK/refuse2
new_target "$R2"
mkdir -p "$R2/.claude"
ln -s /elsewhere "$R2/.claude/agents"
t "symlink pointing elsewhere: exit 1" 1 INST "$R2" --host claude
t "symlink pointing elsewhere with --force" 0 INST "$R2" --host claude --force
eq "--force: symlink replaced" "$(readlink "$R2/.claude/agents")" "../.agents/agents"
R3=$WORK/refuse3
new_target "$R3"
mkdir -p "$R3/.claude"
echo '{"permissions": "all"}' >"$R3/.claude/settings.json"
before=$(snap "$R3")
t "settings key of the wrong type: exit 1" 1 INST "$R3" --host claude
eq "...and nothing was written" "$(snap "$R3")" "$before"
echo '{not json' >"$R3/.claude/settings.json"
t "invalid settings JSON: exit 1" 1 INST "$R3" --host claude
t "invalid settings JSON: exit 1 even with --force" 1 INST "$R3" --host claude --force

echo "== SubagentStop stop audit after a fresh install (JRN-006)"
F=$WORK/fresh
new_target "$F"
t "JRN-006 fresh Claude install exits 0" 0 INST "$F" --host claude
FS=$F/.claude/settings.json
eq "JRN-006 fresh install: one SubagentStop entry in all" "$(jq '.hooks.SubagentStop | length' "$FS")" 1
eq "JRN-006 fresh install: one SubagentStop group runs the stop audit" "$(stop_audit_matchers "$FS" | grep -c '')" 1
for agent in implementation integration; do
  check "JRN-006 fresh install: the stop audit matcher matches $agent" 'matcher_matches "$(stop_audit_matchers "$FS")" "$agent"' \
    "$(jq -c .hooks.SubagentStop "$FS")"
done

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
