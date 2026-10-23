#!/usr/bin/env bash
# Suite: JRN-001 "Bash project builds all three caches": build-architecture.sh on a bash fixture project whose profile names
#   `graph_extractor: bash`, with no dependency-cruiser available.
# Covers: architecture.md module edges from `source` lines and script calls, the dynamic `source` and the runtime-root call
#   with a missing tail listed under "## Unresolved edges" as sorted `- \`<file>:<line>\` \`<source text>\`` bullets after
#   "## Boundary violations"; modules.md Public interface as the sorted union of the functions of a module's sourced files,
#   "Not generated" for modules with none and "none exported" for an empty exports entry; flows entry candidates without files
#   matching the profile's test_patterns, `[]` falling back to the defaults, a malformed test_patterns exiting 2;
#   check-staged-cache.sh passing the rendered architecture and modules bodies. CAP-NEW-bash-graph-extractor,
#   CAP-NEW-selectable-graph-extractor.
# shellcheck disable=SC2016  # literal Markdown backticks in single quotes; check expressions are eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/graph-extractors.sh
source "$TESTS_DIR/fixtures/graph-extractors.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
S="$WORK/scaffold/.agents/skills/regenerate-caches/scripts"
B="$S/build-architecture.sh"
C="$S/check-staged-cache.sh"
X="$S/extractors/bash.sh"
R="$WORK/repo"
bash_project_repo "$R"
refusing_depcruise_stub "$WORK/depcruise"
export DEPCRUISE="$WORK/depcruise"
cd "$R" || exit 1

# section BODY NAME : the non-blank lines between "## NAME" and the next "## " heading.
section() { printf '%s\n' "$1" | awk -v h="## $2" '/^## / { on = ($0 == h); next } on && NF'; }

echo "== JRN-001 architecture"
arch=$("$B" --cache architecture "${BASH_SCOPES[@]}" "${BASH_MODULES[@]}" 2>"$WORK/arch.err"); rc=$?
eq "JRN-001 architecture renders without dependency-cruiser" "$rc" 0
check "JRN-001 architecture run leaves stderr empty" '[ ! -s "$WORK/arch.err" ]' "$(cat "$WORK/arch.err")"
eq "JRN-001 edges for the sourced libs and the script calls" "$(section "$arch" Edges)" '- `bin` → `lib`
- `bin` → `ops`
- `bin` → `tools`
- `tests` → `lib`
- `tools` → `lib`'
eq "JRN-001 Unresolved edges follows Boundary violations as the last section" \
  "$(printf '%s\n' "$arch" | grep '^## ' | tr '\n' '|')" "## Module graph|## Edges|## Boundary violations|## Unresolved edges|"
unres=$(section "$arch" "Unresolved edges")
eq "JRN-001 two unresolved edges" "$(printf '%s\n' "$unres" | grep -c .)" 2
check "JRN-001 the dynamic source is listed with its file, line and source text" \
  'printf "%s\n" "$unres" | grep -F -- "- \`bin/build.sh:$BASH_DYNAMIC_SOURCE_LINE\` \`" | grep -qF -- "$BASH_DYNAMIC_SOURCE_TEXT"' "$unres"
check "JRN-001 the runtime-root call with a missing tail is listed with its file, line and source text" \
  'printf "%s\n" "$unres" | grep -F -- "- \`bin/build.sh:$BASH_MISSING_CALL_LINE\` \`" | grep -qF -- "$BASH_MISSING_CALL_TEXT"' "$unres"
check "JRN-001 every unresolved bullet has the \`file:line\` \`text\` shape" \
  '[ -n "$unres" ] && ! printf "%s\n" "$unres" | grep -qv "^- \`[^\`]*:[0-9][0-9]*\` \`.*\`\$"' "$unres"
check "JRN-001 unresolved bullets are byte-sorted" '[ -n "$unres" ] && printf "%s\n" "$unres" | LC_ALL=C sort -c 2>/dev/null'
mkdir -p .workflow/.cache-staging
printf '%s\n' "$arch" >.workflow/.cache-staging/architecture.md
t "JRN-001 check-staged-cache.sh passes the architecture body" 0 "$C" architecture .workflow/.cache-staging/architecture.md

echo "== JRN-001 modules"
mods=$("$B" --cache modules "${BASH_SCOPES[@]}" "${BASH_MODULES[@]}"); rc=$?
eq "JRN-001 modules renders without dependency-cruiser" "$rc" 0
eq "JRN-001 one section per module" "$(printf '%s\n' "$mods" | grep '^## ' | tr '\n' '|')" "## bin|## lib|## ops|## tests|## tools|"
eq "JRN-001 lib Public interface is the union of its sourced files' functions" \
  "$(section "$mods" lib | sed -n '/^- Public interface:/,$p')" '- Public interface:
  - `join_by` (function)
  - `repo_root` (function)
  - `trim` (function)
  - `upper_case` (function)'
check "JRN-001 a module with no sourced file reads Not generated" \
  'section "$mods" bin | grep -q "^- Public interface: Not generated"'
printf '%s\n' "$mods" | sed 's|<!-- slot: purpose -->|Holds scripts.|' >.workflow/.cache-staging/modules.md
t "JRN-001 check-staged-cache.sh passes the modules body" 0 "$C" modules .workflow/.cache-staging/modules.md

echo "== JRN-001 entries"
ent=$("$B" --cache entries "${BASH_SCOPES[@]}" "${BASH_MODULES[@]}"); rc=$?
eq "JRN-001 entries renders without dependency-cruiser" "$rc" 0
eq "JRN-001 entry candidates are the scripts nothing sources or calls, test files left out" \
  "$(jq -r '[.candidates[].file] | join(",")' <<<"$ent" 2>/dev/null)" "bin/build.sh,bin/release"
check "JRN-001 the test file is not an entry candidate" \
  'jq -e "[.candidates[].file] | index(\"tests/build-test.sh\") == null" <<<"$ent" >/dev/null 2>&1'
eq "JRN-001 build.sh reaches the files it sources and calls" \
  "$(jq -r '.candidates[] | select(.file == "bin/build.sh") | .reaches_files | join(",")' <<<"$ent" 2>/dev/null)" \
  "bin/build.sh,lib/paths.sh,lib/strings.sh,ops/report.sh,tools/deploy.sh"

echo "== modules Public interface edges"
cat >"$WORK/exports.json" <<'EOF'
{"modules":[
 {"source":"bin/build.sh","dependencies":[{"resolved":"lib/strings.sh"},{"resolved":"ops/report.sh"}]},
 {"source":"lib/strings.sh","dependencies":[]},
 {"source":"ops/report.sh","dependencies":[]}
],"exports":{"lib/strings.sh":["upper_case","trim"],"ops/report.sh":[]}}
EOF
mods=$("$B" --cache modules --scope bin --scope lib --scope ops --module bin --module lib --module ops \
  --from-json "$WORK/exports.json"); rc=$?
eq "modules from exports JSON exits 0" "$rc" 0
eq "a module whose files carry no exports reads Not generated" \
  "$(section "$mods" bin | grep '^- Public interface')" "- Public interface: Not generated: no tsconfig.json."
eq "a sibling module lists its files' functions, sorted" \
  "$(section "$mods" lib | sed -n '/^- Public interface:/,$p')" '- Public interface:
  - `trim` (function)
  - `upper_case` (function)'
eq "a module whose exports entry is empty reads none exported" \
  "$(section "$mods" ops | grep '^- Public interface')" "- Public interface: none exported"

echo "== entries test_patterns edges"
write_profile "$R" shell-scripts bash '[]'
ent=$("$B" --cache entries "${BASH_SCOPES[@]}" "${BASH_MODULES[@]}"); rc=$?
eq "test_patterns [] runs entries" "$rc" 0
eq "test_patterns [] falls back to the defaults, which leave tests/ out" \
  "$(jq -r '[.candidates[].file] | join(",")' <<<"$ent" 2>/dev/null)" "bin/build.sh,bin/release"
write_profile "$R" shell-scripts bash '"tests/"'
out=$("$B" --cache entries "${BASH_SCOPES[@]}" "${BASH_MODULES[@]}" 2>&1); rc=$?
eq "test_patterns that is a string, not a list, exits 2" "$rc" 2
check "the error names the profile and the list rule" \
  'printf "%s" "$out" | grep -qF "test_patterns in .workflow/profiles/shell-scripts.md must be a list of non-empty path patterns"' "$out"
write_profile "$R" shell-scripts bash '["tests/", ""]'
out=$("$B" --cache entries "${BASH_SCOPES[@]}" "${BASH_MODULES[@]}" 2>&1); rc=$?
eq "test_patterns holding an empty string exits 2" "$rc" 2
check "no entries JSON is printed on the error" '! printf "%s" "$out" | grep -q candidates' "$out"
write_profile "$R" shell-scripts bash '["tests/"]'

shellcheck_files "shellcheck: build-architecture.sh, check-staged-cache.sh, extractors/bash.sh" "$B" "$C" "$X"
finish
