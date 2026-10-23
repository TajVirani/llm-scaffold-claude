#!/usr/bin/env bash
# Suite: regenerate-caches extractors/bash.sh, the bash graph extractor, run directly on a bash fixture project.
# Covers: dependency-cruiser-shaped JSON (modules[].source, dependencies[]); the files it claims (*.sh and bash-shebang
#   files, not python or markdown); an edge for each `source`/`.` form (dir-anchored inline, a `$here` variable, one variable
#   hop) and each call form (dir-anchored, runtime-root with an existing tail); `couldNotResolve: true` with the source text in
#   `module` and no `resolved` for a dynamic `source` and a runtime-root call whose tail does not exist; every resolved path an
#   existing file; the `exports` map of sorted unique top-level functions of sourced files only; deterministic output; usage
#   errors. CAP-NEW-bash-graph-extractor.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/graph-extractors.sh
source "$TESTS_DIR/fixtures/graph-extractors.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
X="$WORK/scaffold/.agents/skills/regenerate-caches/scripts/extractors/bash.sh"
R="$WORK/repo"
bash_project_repo "$R"

graph=$("$X" --root "$R" "${BASH_SCOPES[@]}"); rc=$?
eq "extractor exits 0 on a bash project" "$rc" 0
check "output is dependency-cruiser-shaped JSON" \
  'jq -e ".modules | type == \"array\" and length > 0 and all(.[]; (.source | type) == \"string\" and (.dependencies | type) == \"array\")" <<<"$graph" >/dev/null 2>&1'

# resolved_of FILE : the sorted resolved targets of FILE's dependencies, comma-joined.
resolved_of() { jq -r --arg f "$1" '[.modules[] | select(.source == $f) | .dependencies[] | .resolved // empty] | unique | join(",")' <<<"$graph" 2>/dev/null; }
# unresolved_of FILE : the module text of FILE's dependencies marked couldNotResolve, one per line.
unresolved_of() { jq -r --arg f "$1" '.modules[] | select(.source == $f) | .dependencies[] | select(.couldNotResolve == true) | .module' <<<"$graph" 2>/dev/null; }

eq "claims *.sh files and bash-shebang files only, sorted" "$(jq -r '[.modules[].source] | join(",")' <<<"$graph" 2>/dev/null)" \
  "bin/build.sh,bin/release,lib/paths.sh,lib/strings.sh,ops/report.sh,tests/build-test.sh,tools/deploy.sh"
eq "build.sh: edges for dir-anchored and \$here sources, a dir-anchored call and a runtime-root call with an existing tail" \
  "$(resolved_of bin/build.sh)" "lib/paths.sh,lib/strings.sh,ops/report.sh,tools/deploy.sh"
eq "deploy.sh: edge through one variable hop" "$(resolved_of tools/deploy.sh)" "lib/strings.sh"
eq "paths.sh: edge for an inline dirname source" "$(resolved_of lib/paths.sh)" "lib/strings.sh"
eq "test file: edge to the lib it sources" "$(resolved_of tests/build-test.sh)" "lib/strings.sh"

unres=$(unresolved_of bin/build.sh)
eq "build.sh: two unresolved dependencies" "$(printf '%s\n' "$unres" | grep -c .)" 2
check "dynamic source is couldNotResolve with its source text in module" \
  'printf "%s\n" "$unres" | grep -qF -- "$BASH_DYNAMIC_SOURCE_TEXT"'
check "runtime-root call with a missing tail is couldNotResolve with its source text in module" \
  'printf "%s\n" "$unres" | grep -qF -- "$BASH_MISSING_CALL_TEXT"'
eq "an unresolved dependency carries no resolved path" \
  "$(jq '[.modules[].dependencies[] | select(.couldNotResolve == true and has("resolved"))] | length' <<<"$graph" 2>/dev/null)" 0

missing=""
while IFS= read -r p; do [ -f "$R/$p" ] || missing="$missing $p"; done < <(jq -r '.modules[].dependencies[] | .resolved // empty' <<<"$graph" 2>/dev/null)
eq "every resolved path is an existing repo file" "$missing" ""
check "at least one resolved edge was checked" '[ -n "$(resolved_of bin/build.sh)" ]'

eq "exports: sorted unique top-level functions of sourced files only" \
  "$(jq -c '.exports' <<<"$graph" 2>/dev/null)" '{"lib/paths.sh":["repo_root"],"lib/strings.sh":["join_by","trim","upper_case"]}'

eq "output is deterministic" "$("$X" --root "$R" "${BASH_SCOPES[@]}")" "$graph"
mkdir -p "$R/docs"
echo '# Docs' >"$R/docs/a.md"
eq "a scope with no bash files gives an empty modules list" "$("$X" --root "$R" --scope docs | jq -c '.modules' 2>/dev/null)" "[]"
eq "a single-directory scope claims only its own files" "$("$X" --root "$R" --scope ops | jq -r '[.modules[].source] | join(",")' 2>/dev/null)" "ops/report.sh"

t "no arguments is a usage error" 2 "$X"
t "--root without --scope is a usage error" 2 "$X" --root "$R"
t "a missing root is an error" 2 "$X" --root "$WORK/nope" --scope bin

shellcheck_files "shellcheck: extractors/bash.sh" "$X"
finish
