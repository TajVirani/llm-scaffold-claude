#!/usr/bin/env bash
# Suite: lint over the docs of install.sh's hook matcher rule: the install.sh header and its --help, README "Install and
#   upgrade", the "Merge rules" section of .agents/hooks/claude-settings.template.md and the CHANGELOG 2.0.0 Migration section.
# Covers: JRN-014: each of the four names the --matchers flag, its merge, replace and keep modes and what happens without a
#   terminal; --help lists --matchers and its modes; the Merge rules no longer say a group whose command is already present
#   is skipped, whatever its matcher. The checks look for phrases a correct doc must hold, not exact sentences. Reads the
#   repo; runs --help on a copy of install.sh in a scratch dir; writes nothing to the repo.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir

# mentions_words TEXT WORD... : true when TEXT has every WORD as a whole word, in any case.
# shellcheck disable=SC2329  # called from check expressions
mentions_words() {
  local text=$1 w
  shift
  for w in "$@"; do printf '%s\n' "$text" | grep -qiw -- "$w" || return 1; done
}
# section LEVEL HEADING : the lines of stdin under the first heading of LEVEL ("##" or "###") that starts with HEADING,
#   up to the next heading of that level.
section() {
  awk -v level="$1 " -v want="$1 $2" '
    index($0, level) == 1 { if (inside) exit; if (index($0, want) == 1) { inside = 1; next } }
    inside'
}

header=$(awk 'NR > 1 && !/^#/ { exit } NR > 1 { print }' "$REPO_ROOT/install.sh")
copy_agents "$WORK/scaffold"
cp "$REPO_ROOT/install.sh" "$WORK/scaffold/install.sh"
help_text=$(bash "$WORK/scaffold/install.sh" --help </dev/null 2>&1)
readme=$(section "##" "Install and upgrade" <"$REPO_ROOT/README.md")
merge_rules=$(section "##" "Merge rules" <"$AGENTS_SRC/hooks/claude-settings.template.md")
migration=$(section "##" "[2.0.0]" <"$REPO_ROOT/CHANGELOG.md" | section "###" "Migration")

check_doc() {
  local name=$1 text=$2
  check "JRN-014 $name is found" '[ -n "$text" ]'
  check "JRN-014 $name names the --matchers flag" 'printf "%s\n" "$text" | grep -qF -- --matchers' "$text"
  check "JRN-014 $name names the merge, replace and keep modes" 'mentions_words "$text" merge replace keep' "$text"
  check "JRN-014 $name says what happens without a terminal" 'mentions_words "$text" terminal' "$text"
}

echo "== the install.sh header"
check_doc "the install.sh header" "$header"

echo "== install.sh --help"
check "JRN-014 --help lists --matchers" 'printf "%s\n" "$help_text" | grep -qF -- --matchers' "$help_text"
check "JRN-014 --help names the merge, replace and keep modes" 'mentions_words "$help_text" merge replace keep' "$help_text"

echo "== README Install and upgrade"
check_doc "README \"Install and upgrade\"" "$readme"

echo "== claude-settings.template.md Merge rules"
check_doc "the claude-settings.template.md Merge rules" "$merge_rules"
check "JRN-014 the Merge rules no longer skip a group whose command is present, whatever its matcher" \
  '! printf "%s\n" "$merge_rules" | grep -qF "Skip a group whose \`command\` already appears under that event"' "$merge_rules"

echo "== CHANGELOG 2.0.0 Migration"
check_doc "the CHANGELOG 2.0.0 Migration section" "$migration"

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
