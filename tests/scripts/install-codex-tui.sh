#!/usr/bin/env bash
# Suite: install.sh (repo root): the Codex [tui] status_line merge.
# Covers: a user [tui] table kept (one table, a warning naming status_line, --force does not rewrite it, config.toml
#   still parses); a user tui.status_line key kept; a [tui] table that already matches the template gets no warning.
# The scaffold under test is a copy of this repo's install.sh and .agents/ inside the fixture, so the repo is never written.
# Env: TEST_BASH=<bash binary> runs install.sh under another bash (default: bash).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
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

new_target() { rm -rf "$1"; git_init_repo "$1"; }

echo "== Codex [tui] status_line merge"
# A [tui] table the user wrote is kept: no second table, a warning, and --force does not rewrite it.
K4=$WORK/codextui
new_target "$K4"
mkdir -p "$K4/.codex"
printf '[tui]\ntheme = "mine"\n' >"$K4/.codex/config.toml"
out=$(INST "$K4" --host codex 2>&1)
eq "user [tui]: exit 0" "$?" 0
check "user [tui]: warning names status_line" 'printf "%s" "$out" | grep -q "keeping your \[tui\] table; add status_line"'
eq "user [tui]: one [tui] table, user key kept, no status_line added" "$(grep -c "^\[tui\]" "$K4/.codex/config.toml") $(yq -p toml -o json -I=0 '[.tui.theme, .tui.status_line]' "$K4/.codex/config.toml")" '1 ["mine",null]'
out=$(INST "$K4" --host codex --force 2>&1)
check "user [tui] with --force: left as is, with a warning" '[ "$(grep -c "^\[tui\]" "$K4/.codex/config.toml")" = 1 ] && printf "%s" "$out" | grep -q "does not rewrite it"'
check "user [tui]: config.toml still parses" 'yq -p toml -o json . "$K4/.codex/config.toml" >/dev/null'
K5=$WORK/codextuikey
new_target "$K5"
mkdir -p "$K5/.codex"
printf 'tui.status_line = ["model"]\n' >"$K5/.codex/config.toml"
out=$(INST "$K5" --host codex 2>&1)
check "user tui.status_line key: kept, warned, still parses" 'printf "%s" "$out" | grep -q "keeping your \[tui\]" && [ "$(yq -p toml -o json -I=0 .tui.status_line "$K5/.codex/config.toml")" = "[\"model\"]" ] && ! grep -q "^\[tui\]" "$K5/.codex/config.toml"'
K6=$WORK/codextuisame
new_target "$K6"
mkdir -p "$K6/.codex"
printf '[tui]\nstatus_line = ["model-with-reasoning", "context-remaining", "current-dir", "git-branch"]\n' >"$K6/.codex/config.toml"
out=$(INST "$K6" --host codex 2>&1)
check "user [tui] already matching: no warning, one table" '! printf "%s" "$out" | grep -q "\[tui\]" && [ "$(grep -c "^\[tui\]" "$K6/.codex/config.toml")" = 1 ]'

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
