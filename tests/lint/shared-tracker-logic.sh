#!/usr/bin/env bash
# Suite: lint that the host choice and the path rewrite with rollback each live once, in .agents/lib/, and that every
#   script needing them calls the shared function instead of keeping a copy.
# Covers: JRN-013 (spec 00014). Every shell file under .agents/ outside .agents/lib/ is read, comment lines left out:
#   - the host choice: no code line matches the origin URL against github or gitlab (a `*github*` / `*gitlab*` pattern, or
#     an `=~` or grep match naming either), which is how open-task-pr.sh and rules-setting.sh pick gh or glab today;
#   - the path rewrite with rollback: no file keeps the rewritten files' saved copies (SAVED_FILE / SAVED_COPY), defines
#     replace_file, the copy-then-rewrite helper, or defines roll_back / rollback, the undo of a half-done rewrite, which is
#     how move-to-done.sh rewrites a moved spec's paths today.
#   And the shared homes exist and are used: .agents/lib/ defines a function whose name holds `host`, called by
#   open-task-pr.sh, rules-setting.sh, issue-tracker.sh and tracker-setup.sh; and one whose name holds `rewrite`, called by
#   move-to-done.sh and tracker-adoption.sh. The existing move-to-done, task-breakdown (open-task-pr.sh, rules-setting.sh)
#   and initiative-merge suites prove the behaviour stays the same. A shellcheck run covers those scripts and the
#   issue-tracking ones. Reads the repo; writes nothing.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

LIB_DIR=$AGENTS_SRC/lib
HOST_CHOICE='\*(github|gitlab)\*|=~.*(github|gitlab)|grep .*(github|gitlab)'
REWRITE_WITH_ROLLBACK='SAVED_FILE|SAVED_COPY|^[[:space:]]*(function[[:space:]]+)?(replace_file|roll_back|rollback)[[:space:]]*\(\)'

# scripts_outside_lib : every shell file under .agents/ but not under .agents/lib/, one path per line.
scripts_outside_lib() { find "$AGENTS_SRC" -path "$LIB_DIR" -prune -o -type f -name '*.sh' -print | LC_ALL=C sort; }

# code_matches REGEX : print `<file>:<line>: <text>` for each code line (not a comment line) of a script outside
#   .agents/lib/ that matches the extended REGEX.
code_matches() {
  local file
  while IFS= read -r file; do
    grep -nE -- "$1" "$file" | grep -vE '^[0-9]+:[[:space:]]*#' | sed "s#^#${file#"$REPO_ROOT"/}:#"
  done < <(scripts_outside_lib)
}

# lib_functions_named WORD : the functions .agents/lib/*.sh defines whose name holds WORD, one per line.
lib_functions_named() {
  grep -hoE '^[[:space:]]*(function[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)' "$LIB_DIR"/*.sh \
    | sed -E 's/^[[:space:]]*(function[[:space:]]+)?//; s/[[:space:]]*\(\)$//' | grep -i -- "$1" || true
}

# callers_missing WORD SCRIPT... : print each SCRIPT (relative to .agents/) that calls none of the lib functions named WORD;
#   every SCRIPT is printed when there is no such function.
callers_missing() {
  local word=$1 script names
  shift
  names=$(lib_functions_named "$word")
  for script in "$@"; do
    if [[ -z $names ]] || ! grep -qwF -f <(printf '%s\n' "$names") "$AGENTS_SRC/$script"; then echo "$script"; fi
  done
}

echo "== JRN-013: no copy of the host choice outside .agents/lib/"
HOST_COPIES=$(code_matches "$HOST_CHOICE")
check "JRN-013 no script outside .agents/lib/ picks gh or glab by matching the origin URL itself" '[[ -z $HOST_COPIES ]]' \
  "$HOST_COPIES"
MISSING_HOST=$(callers_missing host skills/feature-workflow/scripts/open-task-pr.sh skills/feature-workflow/scripts/rules-setting.sh \
  skills/issue-tracking/scripts/issue-tracker.sh skills/issue-tracking/scripts/tracker-setup.sh)
check "JRN-013 .agents/lib/ defines the host choice and every script that needs it calls it" '[[ -z $MISSING_HOST ]]' \
  "lib host functions: $(lib_functions_named host | tr '\n' ' '); not calling one: $(tr '\n' ' ' <<<"$MISSING_HOST")"

echo "== JRN-013: no copy of the path rewrite with rollback outside .agents/lib/"
REWRITE_COPIES=$(code_matches "$REWRITE_WITH_ROLLBACK")
check "JRN-013 no script outside .agents/lib/ keeps its own path rewrite with rollback" '[[ -z $REWRITE_COPIES ]]' \
  "$(head -5 <<<"$REWRITE_COPIES")"
MISSING_REWRITE=$(callers_missing rewrite skills/feature-workflow/scripts/move-to-done.sh \
  skills/issue-tracking/scripts/tracker-adoption.sh)
check "JRN-013 .agents/lib/ defines the path rewrite and move-to-done.sh and tracker-adoption.sh call it" \
  '[[ -z $MISSING_REWRITE ]]' \
  "lib rewrite functions: $(lib_functions_named rewrite | tr '\n' ' '); not calling one: $(tr '\n' ' ' <<<"$MISSING_REWRITE")"

shellcheck_files "shellcheck: the scripts that need the host choice or the path rewrite" \
  "$AGENTS_SRC/skills/feature-workflow/scripts/open-task-pr.sh" "$AGENTS_SRC/skills/feature-workflow/scripts/rules-setting.sh" \
  "$AGENTS_SRC/skills/feature-workflow/scripts/move-to-done.sh" "$AGENTS_SRC/skills/issue-tracking/scripts/issue-tracker.sh" \
  "$AGENTS_SRC/skills/issue-tracking/scripts/tracker-setup.sh" "$AGENTS_SRC/skills/issue-tracking/scripts/tracker-adoption.sh"
finish
