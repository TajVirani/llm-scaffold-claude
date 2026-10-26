#!/usr/bin/env bash
# Suite: JRN-003 "Missing key is a breaking-change error": build-architecture.sh on the bash fixture project with one more
#   profile that has no `graph_extractor` key.
# Covers: a plain run and an `--extractor bash` run each exit 2 with a message that calls it a breaking change, names the
#   profile without the key and gives the `graph_extractor:` line to add; a `--from-json` run skips profile resolution and
#   succeeds; a profile naming an extractor that does not exist exits 2 naming it. CAP-NEW-selectable-graph-extractor.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/graph-extractors.sh
source "$TESTS_DIR/fixtures/graph-extractors.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
B="$WORK/scaffold/.agents/skills/regenerate-caches/scripts/build-architecture.sh"
R="$WORK/repo"
bash_project_repo "$R"
write_profile "$R" agent-notes
git_commit_all "$R" "profile without graph_extractor"
refusing_depcruise_stub "$WORK/depcruise"
export DEPCRUISE="$WORK/depcruise"
cd "$R" || exit 1

# breaking_change_message NAME OUTPUT : true when OUTPUT calls it a breaking change, names profile NAME and gives the line to add.
# shellcheck disable=SC2329 # called from check expressions through eval
breaking_change_message() {
  printf '%s' "$2" | grep -qi 'breaking change' && printf '%s' "$2" | grep -qF -- "$1" && printf '%s' "$2" | grep -qF 'graph_extractor:'
}

echo "== JRN-003 plain run"
out=$("$B" --cache architecture "${BASH_SCOPES[@]}" 2>&1); rc=$?
eq "JRN-003 a profile without graph_extractor exits 2" "$rc" 2
check "JRN-003 the error calls it a breaking change, names agent-notes and gives the line to add" \
  'breaking_change_message agent-notes "$out"' "$out"
check "JRN-003 the error does not name the profile that has the key" '! printf "%s" "$out" | grep -qF shell-scripts' "$out"

echo "== JRN-003 --extractor does not bypass the key"
out=$("$B" --cache architecture "${BASH_SCOPES[@]}" --extractor bash 2>&1); rc=$?
eq "JRN-003 --extractor bash still exits 2" "$rc" 2
check "JRN-003 --extractor bash gives the same breaking-change message" 'breaking_change_message agent-notes "$out"' "$out"

echo "== JRN-003 --from-json skips profiles"
echo '{"modules":[{"source":"bin/build.sh","dependencies":[{"resolved":"lib/paths.sh"}]},{"source":"lib/paths.sh","dependencies":[]}]}' >"$WORK/graph.json"
t "JRN-003 --from-json succeeds with a profile missing the key" 0 "$B" --cache architecture "${BASH_SCOPES[@]}" --from-json "$WORK/graph.json"

echo "== JRN-003 unknown extractor name"
write_profile "$R" agent-notes cobol
git_commit_all "$R" "profile naming an unknown extractor"
out=$("$B" --cache architecture "${BASH_SCOPES[@]}" 2>&1); rc=$?
eq "JRN-003 a profile naming an unknown extractor exits 2" "$rc" 2
check "JRN-003 the error names the unknown extractor" 'printf "%s" "$out" | grep -qF cobol' "$out"

shellcheck_files "shellcheck: build-architecture.sh" "$B"
finish
