#!/usr/bin/env bash
# Suite: regenerate-caches extractors/bash.sh, the bash graph extractor, run directly on a bash fixture project.
# Covers: dependency-cruiser-shaped JSON (modules[].source, dependencies[]); the files it claims (*.sh and bash-shebang
#   files, not python or markdown); an edge for each `source`/`.` form (dir-anchored inline, a `$here` variable, one variable
#   hop) and each call form (dir-anchored, runtime-root with an existing tail, an extensionless script claimed by its shebang);
#   `couldNotResolve: true` with the source text in `module` and no `resolved` for a dynamic `source`, a runtime-root call
#   whose tail does not exist, a bare `source lib`, and cwd-relative `./x`, `dir/x` and `bash x` calls; every resolved path an
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
  "bin/build.sh,bin/release,lib/paths.sh,lib/strings.sh,ops/report.sh,tests/build-test.sh,tools/deploy.sh,tools/publish"
eq "build.sh: edges for dir-anchored and \$here sources, a dir-anchored call and a runtime-root call with an existing tail" \
  "$(resolved_of bin/build.sh)" "lib/paths.sh,lib/strings.sh,ops/report.sh,tools/deploy.sh"
eq "deploy.sh: edges through one variable hop and to an extensionless script claimed by its shebang" \
  "$(resolved_of tools/deploy.sh)" "lib/strings.sh,tools/publish"
eq "paths.sh: edge for an inline dirname source" "$(resolved_of lib/paths.sh)" "lib/strings.sh"
eq "test file: edge to the lib it sources" "$(resolved_of tests/build-test.sh)" "lib/strings.sh"

unres=$(unresolved_of bin/build.sh)
eq "build.sh: two unresolved dependencies" "$(printf '%s\n' "$unres" | grep -c .)" 2
check "dynamic source is couldNotResolve with its source text in module" \
  'printf "%s\n" "$unres" | grep -qF -- "$BASH_DYNAMIC_SOURCE_TEXT"'
check "runtime-root call with a missing tail is couldNotResolve with its source text in module" \
  'printf "%s\n" "$unres" | grep -qF -- "$BASH_MISSING_CALL_TEXT"'
eq "deploy.sh: cwd-relative ./ and bash script calls are couldNotResolve at their lines, never guessed" \
  "$(jq -r '[.modules[] | select(.source == "tools/deploy.sh") | .dependencies[] | select(.couldNotResolve == true) | "\(.line) \(.module)"] | join(",")' <<<"$graph" 2>/dev/null)" \
  "$BASH_DOT_SLASH_CALL_LINE $BASH_DOT_SLASH_CALL_TEXT,$BASH_BASH_CWD_CALL_LINE $BASH_BASH_CWD_CALL_TEXT"
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
t "a scope that climbs out of the root is a usage error" 2 "$X" --root "$R" --scope ../repo
t "a missing scope path is an error" 2 "$X" --root "$R" --scope nowhere
t "an unknown argument is a usage error" 2 "$X" --root "$R" --scope bin --verbose
t "a root outside git is an error" 2 "$X" --root "$WORK/scaffold/.agents" --scope hooks

# Edge forms: heredoc bodies, redirection targets, quoted text and files that are not scripts are data, a run-time variable set from another one is followed one
# hop, and a dir-anchored path to a missing file is never turned into an edge.
E="$WORK/edges"
git_init_repo "$E"
mkdir -p "$E/hooks" "$E/skill/scripts"
printf '#!/usr/bin/env bash\necho check\n' >"$E/skill/scripts/check.sh"
cat >"$E/hooks/adapter.sh" <<'OUTER'
#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scripts=$main_root/skill/scripts
"$scripts/check.sh"
cat >"$here/generated.sh" <<'EOF'
source "$here/../skill/scripts/check.sh"
EOF
bash "$here/missing.sh"
bash -c "./inline.sh"
echo 'a; ./quoted.sh'
cat "$here/../skill/scripts/notes.txt"
FOO=1 ./run-me
bash --norc tools/norc.sh
bash -ec "./inline-e.sh"
OUTER
printf 'notes\n' >"$E/skill/scripts/notes.txt"
git_commit_all "$E" init
edges=$("$X" --root "$E" --scope hooks --scope skill)
eq "a run-time variable set from another one plus a tail resolves through one hop" \
  "$(jq -r '[.modules[] | select(.source == "hooks/adapter.sh") | .dependencies[] | .resolved // empty] | join(",")' <<<"$edges" 2>/dev/null)" \
  "skill/scripts/check.sh"
eq "heredoc bodies, redirection targets, bash -c and -ec strings, quoted text and data files add nothing; a missing file and cwd-relative calls, after a long option too, are unresolved at their lines" \
  "$(jq -r '[.modules[] | select(.source == "hooks/adapter.sh") | .dependencies[] | select(.couldNotResolve) | "\(.line) \(.module)"] | join(",")' <<<"$edges" 2>/dev/null)" \
  '8 $here/missing.sh,12 ./run-me,13 tools/norc.sh'
eq "a file nothing sources has no exports entry" "$(jq -c '.exports' <<<"$edges" 2>/dev/null)" '{}'

# Detected calls are never dropped: subshell and command-substitution calls, glob paths, calls after a bash option that
# takes a value, an anchored call to a file that cannot be read, a source target with no slash or .sh and a command run by a
# bare relative path are each unresolved, with the path text as module. Assignments, arithmetic, quoted prose, case
# patterns, continued lines, folder names, jq `. as $h` and multi-line quoted strings are not calls.
cat >"$E/hooks/forms.sh" <<'OUTER'
#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
(./scripts/version.sh)
v=$(bash scripts/version.sh)
./scripts/*.sh
bash -o pipefail ./opt.sh
w=$(./scripts/version.sh)
"$here/../data/locked"
bash --rcfile rc.sh ./rc-run.sh
bash -O extglob ./ext.sh
source lib
scripts/x.sh --flag
dir=lib/sub
n=$((total/2))
echo $((a/b)) /usr/bin/x
echo "refused (docs/x.md)"
  text/plain) echo t ;;
printf %s a \
  src/a.ts
v=$(scripts/y.sh)
. as $h
tests/
emit "$t" a "" '[]' "missing (assets/y.md)"
jq '
  `src/b.ts` -> `src/c.ts`
'
"scripts/z.sh"
OUTER
mkdir -p "$E/data"
printf '#!/usr/bin/env bash\n' >"$E/data/locked"
chmod 000 "$E/data/locked"
forms=$("$X" --root "$E" --scope hooks); rc=$?
chmod 644 "$E/data/locked"
eq "extractor exits 0 when an anchored call names an unreadable file" "$rc" 0
eq "subshell, substitution, glob, option-value, unreadable-target, bare source and bare relative calls are each unresolved with the path text" \
  "$(jq -r '[.modules[] | select(.source == "hooks/forms.sh") | .dependencies[] | select(.couldNotResolve) | "\(.line) \(.module)"] | join(",")' <<<"$forms" 2>/dev/null)" \
  '3 ./scripts/version.sh,4 scripts/version.sh,5 ./scripts/*.sh,6 ./opt.sh,7 ./scripts/version.sh,8 $here/../data/locked,9 ./rc-run.sh,10 ./ext.sh,11 lib,12 scripts/x.sh,20 scripts/y.sh,27 scripts/z.sh'

shellcheck_files "shellcheck: extractors/bash.sh" "$X"
finish
