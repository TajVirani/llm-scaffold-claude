#!/usr/bin/env bash
# Suite: regenerate-caches extractors/bash.sh, the bash graph extractor, run directly on a bash fixture project.
# Covers: dependency-cruiser-shaped JSON (modules[].source, dependencies[]); the files it claims (*.sh and bash-shebang
#   files, not python or markdown); an edge for each `source`/`.` form (dir-anchored inline, a `$here` variable, one variable
#   hop) and each call form (dir-anchored, runtime-root with an existing tail, an extensionless script claimed by its shebang);
#   `couldNotResolve: true` with the source text in `module` and no `resolved` for a dynamic `source`, a runtime-root call
#   whose tail does not exist, a bare `source lib`, and cwd-relative `./x`, `dir/x` and `bash x` calls; every resolved path an
#   existing file; the `exports` map of sorted unique top-level functions of sourced files only; deterministic output; usage
#   errors. JRN-001: `case` arms in every form (one-line, `|` alternatives, `(pattern)`, `./x)`, a pattern on its own line,
#   a whole case on one line, a case in a loop) give no pattern as a call or an edge, while every call in an arm body is
#   still reported. Quoted strings that span lines (a jq program, an awk script, a plain single-quoted block, a
#   double-quoted message) report nothing from their text, while a `$(...)` inside a double-quoted one is still read, and
#   calls after the string are reported; an apostrophe in a trailing comment, a quote spliced from `'` and `"`, an escaped
#   quote in `$'...'`, a `#`-led line inside a string and a `<<` inside a quoted string do not hide later calls; run on this
#   suite file, the extractor reports no `./x` from its jq program. CAP-NEW-bash-graph-extractor, CAP-005.
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
# bare relative path are each unresolved, with the path text as module, also on a line continued after an operator.
# Assignments, arithmetic, quoted prose, case patterns, words on a line continued mid-command, folder names, jq `. as $h`
# and multi-line quoted strings are not calls.
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
true && \
  scripts/b.sh
foo \
  scripts/c.sh
OUTER
mkdir -p "$E/data"
printf '#!/usr/bin/env bash\n' >"$E/data/locked"
chmod 000 "$E/data/locked"
forms=$("$X" --root "$E" --scope hooks); rc=$?
chmod 644 "$E/data/locked"
eq "extractor exits 0 when an anchored call names an unreadable file" "$rc" 0
eq "subshell, substitution, glob, option-value, unreadable-target, bare source and bare relative calls are each unresolved with the path text" \
  "$(jq -r '[.modules[] | select(.source == "hooks/forms.sh") | .dependencies[] | select(.couldNotResolve) | "\(.line) \(.module)"] | join(",")' <<<"$forms" 2>/dev/null)" \
  '3 ./scripts/version.sh,4 scripts/version.sh,5 ./scripts/*.sh,6 ./opt.sh,7 ./scripts/version.sh,8 $here/../data/locked,9 ./rc-run.sh,10 ./ext.sh,11 lib,12 scripts/x.sh,20 scripts/y.sh,27 scripts/z.sh,29 scripts/b.sh'

echo "== JRN-001 case arms"
# Every arm form a script can use: one-line, `|` alternatives (the install.sh shape, with and without spaces), a leading
# `(`, a `./x` pattern, a pattern on its own line with the body below, a default arm, a whole case on one line, and a case
# inside a loop. Only the commands in the arm bodies are calls.
C="$WORK/cases"
git_init_repo "$C"
mkdir -p "$C/scripts" "$C/bin" "$C/lib"
printf '#!/usr/bin/env bash\necho tool\n' >"$C/bin/tool.sh"
printf '# Helpers sourced by the arms script.\nhelp_me() { :; }\n' >"$C/lib/helpers.sh"
cat >"$C/scripts/arms.sh" <<'OUTER'
#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$1" in
  a) ./bin/one-line.sh ;;
  ../*|/*) source lib.sh ;;
  /* | ../* | */../* | */.. | ..) echo "outside" ;;
  (./x) "$here/../bin/tool.sh" ;;
  ./x) ./bin/after-dot.sh ;;
  ../up | ./down)
    ./bin/multi.sh
    ;;
  *)
    bash ./bin/fallback.sh
    ;;
esac
case "$f" in /* | ../* | ..) echo skip ;; *) ./bin/same-line.sh ;; esac
while read -r p; do
  case "$p" in
    ./*) ./bin/in-loop.sh "$p" ;;
    ../lib/*.sh)
      . "$here/../lib/helpers.sh"
      ;;
  esac
done
OUTER
git_commit_all "$C" init
cases=$("$X" --root "$C" --scope scripts --scope bin --scope lib); rc=$?
eq "JRN-001 extractor exits 0 on every case arm form" "$rc" 0
arm_unresolved=$(jq -r '[.modules[] | select(.source == "scripts/arms.sh") | .dependencies[] | select(.couldNotResolve) | "\(.line) \(.module)"] | join(",")' <<<"$cases" 2>/dev/null)
eq "JRN-001 every cwd-relative or bare call in an arm body is unresolved at its line, and no pattern is" \
  "$arm_unresolved" \
  '4 ./bin/one-line.sh,5 lib.sh,8 ./bin/after-dot.sh,10 ./bin/multi.sh,13 ./bin/fallback.sh,16 ./bin/same-line.sh,19 ./bin/in-loop.sh'
eq "JRN-001 anchored calls and sources in arm bodies are edges, after a ( pattern too" \
  "$(jq -r '[.modules[] | select(.source == "scripts/arms.sh") | .dependencies[] | .resolved // empty] | unique | join(",")' <<<"$cases" 2>/dev/null)" \
  "bin/tool.sh,lib/helpers.sh"
pattern_hits=$(jq -r '[.modules[] | select(.source == "scripts/arms.sh") | .dependencies[] | (.module // ""), (.resolved // "")]
  | map(select(. == "../*" or . == "/*" or . == "*/../*" or . == "*/.." or . == ".." or . == "./x" or . == "(./x" or . == "../up"
    or . == "./down" or . == "./*" or . == "../lib/*.sh" or . == "a")) | join(",")' <<<"$cases" 2>/dev/null)
eq "JRN-001 no case pattern is reported as a call or an edge" "$pattern_hits" ""

# Harder case forms: a case nested in an arm body, a `)` inside a quoted pattern, the word `case` as a plain argument
# (which opens no case, so later calls are still read), and a whole case inside `$(...)`.
cat >"$C/scripts/nested.sh" <<'OUTER'
#!/usr/bin/env bash
case "$a" in
  "x)y" | 'q)') ./bin/quoted-arm.sh ;;
  outer)
    case "$b" in
      ../in) ./bin/inner-arm.sh ;;
    esac
    ./bin/after-inner.sh
    ;;
esac
echo just in case ./not-a-call
./bin/after-argument.sh
r=$(case "$c" in ../sub) echo n ;; esac)
./bin/after-substitution.sh
OUTER
git_commit_all "$C" nested
nested=$("$X" --root "$C" --scope scripts); rc=$?
eq "JRN-001 extractor exits 0 on nested, quoted and substituted case forms" "$rc" 0
# nested_deps FIRST LAST : "line module" of each scripts/nested.sh dependency on lines FIRST to LAST, comma-joined.
nested_deps() {
  jq -r --argjson first "$1" --argjson last "$2" '[.modules[] | select(.source == "scripts/nested.sh") | .dependencies[]
    | select(.line >= $first and .line <= $last) | "\(.line) \(.module)"] | join(",")' <<<"$nested" 2>/dev/null
}
eq "JRN-001 a ) inside a quoted pattern ends no pattern early, and the arm body call is reported" \
  "$(nested_deps 2 3)" '3 ./bin/quoted-arm.sh'
eq "JRN-001 a case nested in an arm body hides its own pattern, and calls inside and after it are reported" \
  "$(nested_deps 4 10)" '6 ./bin/inner-arm.sh,8 ./bin/after-inner.sh'
eq "JRN-001 the word case as a plain argument opens no case, so the next line's call is reported" \
  "$(nested_deps 11 12)" '12 ./bin/after-argument.sh'
eq "JRN-001 a whole case inside \$(...) hides its pattern and closes, so the next line's call is reported" \
  "$(nested_deps 13 14)" '14 ./bin/after-substitution.sh'

echo "== quoted strings that span lines"
# Text inside a quoted string is data however many lines the string spans; a call after the string closes is still read.
Q="$WORK/quotes"
git_init_repo "$Q"
mkdir -p "$Q/scripts"
cat >"$Q/scripts/jq-program.sh" <<'OUTER'
#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
jq -r '
  ./x
  "(./x"
source x
$here/x.sh
  # a jq comment with an apostrophe: it'"'"'s data
' input.json
./after-jq.sh
OUTER
cat >"$Q/scripts/awk-and-plain.sh" <<'OUTER'
#!/usr/bin/env bash
awk '
  $1 == "run" { system("./in-awk.sh") }
' input.txt
echo '
./in-plain-quote.sh
scripts/in-plain-quote.sh
'
./after-blocks.sh
OUTER
cat >"$Q/scripts/double-quoted.sh" <<'OUTER'
#!/usr/bin/env bash
message="Run $(./first.sh) first, then:
./in-dquote.sh
scripts/in-dquote.sh
and $(./real.sh) with $(scripts/real-bare.sh) last"
./after-dquote.sh
OUTER
cat >"$Q/scripts/hash-line.sh" <<'OUTER'
#!/usr/bin/env bash
note='first line of the note
# a line of the note that closes it'
scripts/after-hash-close.sh
OUTER
cat >"$Q/scripts/trailing-comment.sh" <<'OUTER'
#!/usr/bin/env bash
echo hi # don't
scripts/x.sh
./y.sh
OUTER
cat >"$Q/scripts/escaped-quotes.sh" <<'OUTER'
#!/usr/bin/env bash
x='it'"'"'s'
scripts/after-concat.sh
y=$'a\'b'
scripts/after-ansi.sh
./after-ansi.sh
OUTER
cat >"$Q/scripts/quoted-heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
echo "use << EOF to start a heredoc"
./after-double-quoted.sh
printf '%s\n' 'cat <<END'
scripts/after-single-quoted.sh
OUTER
cat >"$Q/scripts/edge-forms.sh" <<'OUTER'
#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
msg="first line
$(bash "$here/tool.sh" "a b") and $((1 + 2))
./not-a-call.sh"
[[ $# -gt 0 ]] && ./after-count.sh
n=${#items[@]}; ./after-length.sh
OUTER
printf '#!/usr/bin/env bash\necho tool\n' >"$Q/scripts/tool.sh"
git_commit_all "$Q" init
quotes=$("$X" --root "$Q" --scope scripts); rc=$?
eq "extractor exits 0 on quoted strings that span lines" "$rc" 0
# quote_deps FILE : "line module" of each dependency of FILE in the quotes repo, comma-joined.
quote_deps() {
  jq -r --arg f "$1" '[.modules[] | select(.source == $f) | .dependencies[] | "\(.line) \(.module)"] | join(",")' \
    <<<"$quotes" 2>/dev/null
}
eq "a multi-line single-quoted jq program reports none of the ./x forms, source or \$here lines inside it, and the call after it is read" \
  "$(quote_deps scripts/jq-program.sh)" '10 ./after-jq.sh'
eq "a multi-line awk script and a plain multi-line single-quoted block report nothing from inside" \
  "$(quote_deps scripts/awk-and-plain.sh)" '9 ./after-blocks.sh'
eq "a multi-line double-quoted string reports no call from its plain text, and every \$(...) inside it is read as code" \
  "$(quote_deps scripts/double-quoted.sh)" '2 ./first.sh,5 ./real.sh,5 scripts/real-bare.sh,6 ./after-dquote.sh'
eq "a line that starts with # inside a quoted string can close it, so the next line's call is reported" \
  "$(quote_deps scripts/hash-line.sh)" '4 scripts/after-hash-close.sh'
eq "an apostrophe in a trailing comment opens no quote, so later bare and cwd-relative calls are reported" \
  "$(quote_deps scripts/trailing-comment.sh)" '3 scripts/x.sh,4 ./y.sh'
eq "calls after a quote spliced from single and double quotes and after an escaped quote in \$'...' are reported" \
  "$(quote_deps scripts/escaped-quotes.sh)" '3 scripts/after-concat.sh,5 scripts/after-ansi.sh,6 ./after-ansi.sh'
eq "a << inside a quoted string starts no heredoc, so calls on the following lines are reported" \
  "$(quote_deps scripts/quoted-heredoc.sh)" '3 ./after-double-quoted.sh,5 scripts/after-single-quoted.sh'
eq "a \$(...) holding its own quotes inside a multi-line double-quoted string is read as code, and \$# and \${#...} start no comment" \
  "$(quote_deps scripts/edge-forms.sh)" '4 $here/tool.sh,6 ./after-count.sh,7 ./after-length.sh'
eq "an anchored call inside a \$(...) in a multi-line double-quoted string still resolves" \
  "$(jq -r '[.modules[] | select(.source == "scripts/edge-forms.sh") | .dependencies[] | .resolved // empty] | join(",")' \
    <<<"$quotes" 2>/dev/null)" 'scripts/tool.sh'
suite_self=$("$X" --root "$REPO_ROOT" --scope tests/scripts/extractor-bash.sh); rc=$?
eq "extractor exits 0 on this suite file" "$rc" 0
eq "the extractor run on this suite claims the suite file" \
  "$(jq -r '[.modules[].source] | join(",")' <<<"$suite_self" 2>/dev/null)" "tests/scripts/extractor-bash.sh"
eq "the extractor run on this suite reports no ./x from the case-pattern jq program" \
  "$(jq -r '[.modules[].dependencies[] | select(.module == "./x" or .module == "(./x") | "\(.line) \(.module)"] | join(",")' \
    <<<"$suite_self" 2>/dev/null)" ""

shellcheck_files "shellcheck: extractors/bash.sh" "$X"
finish
