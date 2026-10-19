#!/usr/bin/env bash
# Suite: Claude shim wiring in this repo (reads the repo, writes nothing).
# Covers: .claude/skills, .claude/agents and .claude/output-styles are symlinks resolving into .agents/; .claude/commands does
#   not exist (removed in the 2.0 reset); every hook command in .claude/settings.json, .agents/hooks/claude-settings.template.json
#   and .agents/hooks/codex-hooks.template.json names an existing executable script under .agents/hooks/.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

# physdir PATH : physical path of a directory, empty when it does not resolve.
physdir() { (cd "$1" 2>/dev/null && pwd -P); }

# shellcheck disable=SC2034  # used inside eval'd check expressions
AGENTS_REAL=$(physdir "$REPO_ROOT/.agents")

for n in skills agents output-styles; do
  p=$REPO_ROOT/.claude/$n
  check ".claude/$n is a symlink" '[ -L "$p" ]'
  target=$(physdir "$p")
  check ".claude/$n resolves into .agents/" '[ -n "$target" ] && case "$target" in "$AGENTS_REAL"/*) true ;; *) false ;; esac' "resolves to '${target:-nothing}'"
  want=$(physdir "$REPO_ROOT/.agents/$n")
  eq ".claude/$n resolves to .agents/$n" "$target" "$want"
done
check ".claude/commands does not exist" '[ ! -e "$REPO_ROOT/.claude/commands" ] && [ ! -L "$REPO_ROOT/.claude/commands" ]'

# hook_scripts FILE : the script path of each hook command in FILE, one per line, with the project-dir / git-toplevel
# prefix stripped. Handles `"$CLAUDE_PROJECT_DIR"/.agents/hooks/x.sh` and `bash -c 'exec "$(...)/.agents/hooks/x.sh"'`.
hook_scripts() {
  jq -r '[.. | objects | select(.type? == "command") | .command] | .[]' "$1" |
    sed -n 's|.*\(\.agents/hooks/[A-Za-z0-9_.-]*\).*|\1|p'
}

check_hooks() {
  local f=$1 rel n=0 cmds
  cmds=$(jq -r '[.. | objects | select(.type? == "command")] | length' "$f")
  for rel in $(hook_scripts "$f"); do
    n=$((n + 1))
    check "$(basename "$f"): $rel exists and is executable" '[ -f "$REPO_ROOT/$rel" ] && [ -x "$REPO_ROOT/$rel" ]'
  done
  eq "$(basename "$f"): every hook command names a .agents/hooks script" "$n" "$cmds"
}

for f in "$REPO_ROOT/.claude/settings.json" \
  "$AGENTS_SRC/hooks/claude-settings.template.json" \
  "$AGENTS_SRC/hooks/codex-hooks.template.json"; do
  if [ -f "$f" ]; then check_hooks "$f"; else ko "$f exists"; fi
done

shellcheck_files "shellcheck tests/lint/symlinks.sh" "$TESTS_DIR/lint/symlinks.sh"
finish
