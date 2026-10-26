#!/usr/bin/env bash
# Suite: regenerate-caches build-architecture.sh choosing its graph extractors from the work profiles, and
#   extractors/dependency-cruiser.sh run directly.
# Covers: extractors named by the profiles' `graph_extractor` run with `--root` and the scopes and their graphs merged
#   (TEMPLATE.md and `none` skipped); `--extractor NAME` running NAME alone; `--print-generator` (sorted, comma-joined,
#   `none` left out, `--extractor` honoured, no `--cache` needed); refusals with exit 2: a file claimed by two extractors,
#   an extractor that fails, prints no `.modules` or prints an entry that is not an object with a string `source`, an unknown `--extractor`, an empty `graph_extractor`, no profiles,
#   yq missing; the dependency-cruiser extractor's usage errors, tool lookup, tsconfig flag and `depcruise failed:` message.
#   Extractors other than dependency-cruiser are stand-ins written into the fixture's copy of the scripts.
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
X="$S/extractors/dependency-cruiser.sh"

# stand_in_extractor NAME JSON : writes extractors/NAME.sh printing JSON and logging its arguments to $WORK/NAME.args.
stand_in_extractor() {
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" >"%s"\ncat <<'"'"'EOF'"'"'\n%s\nEOF\n' "$WORK/$1.args" "$2" >"$S/extractors/$1.sh"
  chmod +x "$S/extractors/$1.sh"
}

stand_in_extractor alpha '{"modules":[{"source":"a/one.txt","dependencies":[{"resolved":"a/two.txt"}]},{"source":"a/two.txt","dependencies":[]}]}'
stand_in_extractor beta '{"modules":[{"source":"b/three.txt","dependencies":[{"resolved":"a/one.txt"}]}]}'
stand_in_extractor claims-a '{"modules":[{"source":"a/two.txt","dependencies":[]}]}'
stand_in_extractor not-json 'this is not json'
stand_in_extractor no-modules '{"files":[]}'
stand_in_extractor module-not-object '{"modules":["x"]}'
stand_in_extractor source-not-string '{"modules":[{"source":1,"dependencies":[]}]}'
printf '#!/usr/bin/env bash\necho "broken tool" >&2\nexit 2\n' >"$S/extractors/broken.sh"
chmod +x "$S/extractors/broken.sh"

R="$WORK/repo"
git_init_repo "$R"
mkdir -p "$R/a" "$R/b"
for f in a/one.txt a/two.txt b/three.txt; do echo "$f" >"$R/$f"; done
write_profile "$R" scripts-one beta
write_profile "$R" scripts-two alpha
write_profile "$R" docs none
write_profile "$R" scripts-three alpha
write_profile "$R" TEMPLATE
git_commit_all "$R" init
cd "$R" || exit 1

# section BODY NAME : the non-blank lines between "## NAME" and the next "## " heading.
section() { printf '%s\n' "$1" | awk -v h="## $2" '/^## / { on = ($0 == h); next } on && NF'; }

echo "== profiles select the extractors"
out=$("$B" --print-generator 2>&1); rc=$?
eq "print-generator exits 0 without --cache or --scope" "$rc" 0
eq "print-generator names each selected extractor once, sorted, none and TEMPLATE.md left out" "$out" "alpha,beta"
eq "print-generator with --extractor names that extractor" "$("$B" --print-generator --extractor beta 2>&1)" "beta"

arch=$("$B" --cache architecture --scope a --scope b 2>&1); rc=$?
eq "architecture exits 0 with two extractors" "$rc" 0
eq "edges from both extractors are merged" "$(section "$arch" Edges)" '- `a/one.txt` → `a/two.txt`
- `b/three.txt` → `a/one.txt`'
eq "an extractor gets --root and every scope" "$(cat "$WORK/alpha.args" 2>/dev/null)" "--root
$R
--scope
a
--scope
b"

echo "== --extractor overrides which extractor runs"
rm -f "$WORK/alpha.args"
arch=$("$B" --cache architecture --scope a --scope b --extractor beta 2>&1); rc=$?
eq "--extractor beta exits 0" "$rc" 0
check "--extractor beta does not run alpha" '[[ ! -e "$WORK/alpha.args" ]]'
eq "--extractor beta graphs only beta's files" "$(section "$arch" Edges)" 'None.'

echo "== refusals"
out=$("$B" --cache architecture --scope a --scope b --extractor nosuch 2>&1); rc=$?
eq "an unknown --extractor exits 2" "$rc" 2
check "the error names the unknown --extractor" 'printf "%s" "$out" | grep -qF nosuch' "$out"

write_profile "$R" scripts-two claims-a
git_commit_all "$R" "two extractors claim a/two.txt"
out=$("$B" --cache architecture --scope a --scope b 2>&1); rc=$?
eq "a file claimed by two extractors exits 2" "$rc" 2
check "the error names the file and both extractors, and no body is printed" \
  'printf "%s" "$out" | grep -F a/two.txt | grep -F alpha | grep -qF claims-a && ! printf "%s" "$out" | grep -q "^# Architecture"' "$out"
write_profile "$R" scripts-two alpha
git_commit_all "$R" "restore alpha"

for name in not-json no-modules module-not-object source-not-string broken; do
  out=$("$B" --cache architecture --scope a --extractor "$name" 2>&1); rc=$?
  eq "extractor $name exits 2" "$rc" 2
  check "the error for $name names the extractor and not dependency-cruiser" \
    'printf "%s" "$out" | grep -qF "$name" && ! printf "%s" "$out" | grep -qF dependency-cruiser' "$out"
done

# write_profile cannot write an empty graph_extractor value, so this profile is written by hand.
printf '# Profile: blank\n\n## Toolchain\n\n```yaml\ntest: "true"\ngraph_extractor: ""\n```\n' >"$R/.workflow/profiles/blank.md"
git_commit_all "$R" "profile with an empty graph_extractor"
out=$("$B" --cache architecture --scope a 2>&1); rc=$?
eq "an empty graph_extractor exits 2" "$rc" 2
check "the error names the profile" 'printf "%s" "$out" | grep -qF blank' "$out"
git -C "$R" rm -q "$R/.workflow/profiles/blank.md"
git_commit_all "$R" "drop the blank profile"

R2="$WORK/no-profiles"
git_init_repo "$R2"
mkdir -p "$R2/a"
echo one >"$R2/a/one.txt"
git_commit_all "$R2" init
out=$("$B" --cache architecture --scope a --root "$R2" 2>&1); rc=$?
eq "a project with no work profiles exits 2" "$rc" 2
check "the error says the profiles name the extractors" 'printf "%s" "$out" | grep -qF graph_extractor' "$out"

nobin="$WORK/no-yq-bin"
mkdir -p "$nobin"
ln -s "$(command -v jq)" "$nobin/jq"
ln -s "$(command -v git)" "$nobin/git"
if PATH="$nobin:/usr/bin:/bin" command -v yq >/dev/null 2>&1; then
  skip "yq missing exits 2" "yq is installed in /usr/bin or /bin"
else
  out=$(PATH="$nobin:/usr/bin:/bin" "$B" --cache architecture --scope a 2>&1); rc=$?
  eq "yq missing exits 2" "$rc" 2
  check "the error names yq" 'printf "%s" "$out" | grep -qF yq' "$out"
  t "--from-json does not need yq" 0 env PATH="$nobin:/usr/bin:/bin" "$B" --cache architecture --scope a \
    --from-json <(echo '{"modules":[{"source":"a/one.txt"}]}')
fi

echo "== extractors/dependency-cruiser.sh"
t "dependency-cruiser extractor without --root is a usage error" 2 "$X" --scope a
t "dependency-cruiser extractor without --scope is a usage error" 2 "$X" --root "$R"
t "dependency-cruiser extractor with an unknown argument is a usage error" 2 "$X" --root "$R" --scope a --bogus
printf '#!/usr/bin/env bash\necho "first line" >&2\necho "second line" >&2\nexit 1\n' >"$WORK/failing-depcruise"
chmod +x "$WORK/failing-depcruise"
out=$(DEPCRUISE="$WORK/failing-depcruise" "$X" --root "$R" --scope a 2>&1); rc=$?
eq "a failing depcruise exits 2" "$rc" 2
check "the failure keeps the depcruise failed: message with depcruise's stderr" \
  'printf "%s" "$out" | grep -qF "depcruise failed: first line"' "$out"

echo '{"modules":[]}' >"$WORK/empty-graph.json"
mkdir -p "$R/node_modules/.bin"
depcruise_stub "$R/node_modules/.bin/depcruise" "$WORK/empty-graph.json" "$WORK/local-depcruise.args"
echo '{}' >"$R/tsconfig.json"
# unset DEPCRUISE so a value in the developer's shell cannot pick the depcruise this test expects to be looked up.
out=$(unset DEPCRUISE; "$X" --root "$R" --scope a 2>&1); rc=$?
eq "without DEPCRUISE the project's node_modules depcruise runs" "$rc" 0
eq "a tsconfig.json at the root adds --ts-config" "$(cat "$WORK/local-depcruise.args" 2>/dev/null)" '--no-config
--ts-config
tsconfig.json
--exclude
(^|/)node_modules/
-T
json
a'
rm -rf "$R/node_modules" "$R/tsconfig.json"

shellcheck_files "shellcheck: build-architecture.sh, extractors/dependency-cruiser.sh" "$B" "$X"
finish
