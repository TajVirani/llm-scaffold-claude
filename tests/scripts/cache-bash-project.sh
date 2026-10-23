#!/usr/bin/env bash
# Suite: JRN-001 "Bash project builds all three caches": build-architecture.sh on a bash fixture project whose profile names
#   `graph_extractor: bash`, with no dependency-cruiser available.
# Covers: architecture.md module edges from `source` lines and script calls, the dynamic `source` and the runtime-root call
#   with a missing tail listed under "## Unresolved edges" as sorted `- \`<file>:<line>\` \`<source text>\`` bullets after
#   "## Boundary violations"; modules.md Public interface as the sorted union of the functions of a module's sourced files,
#   "Not generated" for modules with none; flows entry candidates without files matching the profile's test_patterns;
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

shellcheck_files "shellcheck: build-architecture.sh, check-staged-cache.sh, extractors/bash.sh" "$B" "$C" "$X"
finish
