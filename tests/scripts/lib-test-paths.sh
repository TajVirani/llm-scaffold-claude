#!/usr/bin/env bash
# Suite: .agents/lib/test-paths.sh, the one definition of a test file, and its caller budget-check.sh (JRN-005): the
#   size-budget count, read through `--predicted` test_files.
# Covers: the default patterns; loading the work profiles' Toolchain `test_patterns` (a list, `[]`, the key absent, an empty
#   Toolchain block, TEMPLATE.md skipped, no profiles, invalid values refused with status 1 and a reason); the matcher (a
#   `dir/` pattern at any depth, a pattern holding another `/` against the whole repo path, any other pattern against the
#   file name); budget-check classifying the paths the matcher calls tests for each profile shape; an invalid
#   `test_patterns` exiting 1 in budget-check with its own message; no copy of the default list in a shell file
#   under .agents/ outside lib/test-paths.sh.
# shellcheck disable=SC2016  # the bash -c programs and check expressions are single-quoted on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
LIB="$WORK/scaffold/.agents/lib/test-paths.sh"
BC="$WORK/scaffold/.agents/skills/feature-workflow/scripts/budget-check.sh"

# The nine default patterns.
DEFAULTS='*.spec.*
*.test.*
*_test.go
*_test.py
__tests__/
e2e/
test/
test_*.py
tests/'
PROFILE_PATTERNS='["tests/", "checks/*.sh", "*.check.sh"]'

# lib_call FUNCTION ARGS... : run a test-paths.sh function in a clean bash with the strict options the scripts use.
lib_call() { bash -c 'set -euo pipefail; . "$1"; shift; "$@"' _ "$LIB" "$@"; }
# is_test PATTERNS PATH : "test" or "not" as wf_is_test_path decides for PATH with WF_TEST_PATTERNS=PATTERNS.
is_test() {
  if WF_TEST_PATTERNS=$1 lib_call wf_is_test_path "$2" >/dev/null 2>&1; then echo test; else echo not; fi
}
# empty_toolchain_profile DIR NAME : a profile whose Toolchain section has an empty yaml fence.
empty_toolchain_profile() {
  mkdir -p "$1"
  printf '# Profile: %s\n\n## Toolchain\n\n```yaml\n```\n' "$2" >"$1/$2.md"
}
# profiles_dir NAME : a fresh profiles folder under the scratch dir.
profiles_dir() { rm -rf "$WORK/profiles/$1"; mkdir -p "$WORK/profiles/$1"; printf '%s\n' "$WORK/profiles/$1"; }
# write_profile DIR NAME [TEST_PATTERNS] : writes the work profile NAME under DIR; an empty TEST_PATTERNS leaves the key out.
write_profile() {
  local dir=$1 name=$2 patterns=${3:-}
  mkdir -p "$dir/.workflow/profiles"
  {
    printf '# Profile: %s\n\n## File locations\n\n- Scripts live by owner.\n\n## Toolchain\n\n```yaml\n' "$name"
    printf 'lint: ""\ntest: "true"\n'
    [ -z "$patterns" ] || printf 'test_patterns: %s\n' "$patterns"
    printf '```\n'
  } >"$dir/.workflow/profiles/$name.md"
}

echo "== wf_default_test_patterns"
eq "JRN-005 the default patterns are the nine shared ones" "$(lib_call wf_default_test_patterns 2>/dev/null | LC_ALL=C sort)" "$DEFAULTS"

echo "== wf_load_test_patterns"
eq "JRN-005 no profiles folder gives the defaults" "$(lib_call wf_load_test_patterns "$WORK/no-profiles" 2>/dev/null)" "$DEFAULTS"
d=$(profiles_dir none)
eq "JRN-005 an empty profiles folder gives the defaults" "$(lib_call wf_load_test_patterns "$d" 2>/dev/null)" "$DEFAULTS"
d=$(profiles_dir list)
write_profile "$WORK/profiles/list-root" shell "$PROFILE_PATTERNS"
mv "$WORK/profiles/list-root/.workflow/profiles/shell.md" "$d/shell.md"
eq "JRN-005 a profile's list replaces the defaults, sorted and unique" "$(lib_call wf_load_test_patterns "$d" 2>/dev/null)" '*.check.sh
checks/*.sh
tests/'
printf '# Template\n\n## Toolchain\n\n```yaml\ntest_patterns: ["*.sh"]\n```\n' >"$d/TEMPLATE.md"
eq "JRN-005 TEMPLATE.md is skipped" "$(lib_call wf_load_test_patterns "$d" 2>/dev/null)" '*.check.sh
checks/*.sh
tests/'
write_profile "$WORK/profiles/list-root" docs '[]'
mv "$WORK/profiles/list-root/.workflow/profiles/docs.md" "$d/docs.md"
eq "JRN-005 a [] profile adds the defaults to another profile's list" "$(lib_call wf_load_test_patterns "$d" 2>/dev/null)" \
  "$(printf '%s\n%s\n' "$DEFAULTS" '*.check.sh
checks/*.sh' | LC_ALL=C sort -u)"
for form in absent empty-list empty-block; do
  d=$(profiles_dir "$form")
  case $form in
    absent) write_profile "$WORK/profiles/$form-root" one ;;
    empty-list) write_profile "$WORK/profiles/$form-root" one '[]' ;;
    empty-block) empty_toolchain_profile "$WORK/profiles/$form-root/.workflow/profiles" one ;;
  esac
  mv "$WORK/profiles/$form-root/.workflow/profiles/one.md" "$d/one.md"
  eq "JRN-005 a profile with test_patterns $form gives the defaults" "$(lib_call wf_load_test_patterns "$d" 2>/dev/null)" "$DEFAULTS"
done
for bad in '"tests/"' '["tests/", ""]' '[1]' '{a: b}'; do
  d=$(profiles_dir invalid)
  write_profile "$WORK/profiles/invalid-root" odd "$bad"
  mv "$WORK/profiles/invalid-root/.workflow/profiles/odd.md" "$d/odd.md"
  out=$(lib_call wf_load_test_patterns "$d" 2>&1); rc=$?
  check "JRN-005 test_patterns: $bad is refused with status 1 and a reason naming the profile" \
    '[ "$rc" = 1 ] && [[ "$out" == *odd.md* ]]' "rc=$rc $out"
done

echo "== wf_is_test_path"
LIST_AND_DEFAULTS=$(printf '%s\n%s\n' "$DEFAULTS" 'checks/*.sh
*.check.sh')
while IFS=' ' read -r want path; do
  eq "JRN-005 wf_is_test_path: $path is $want" "$(is_test "$LIST_AND_DEFAULTS" "$path")" "$want"
done <<'EOF'
test tests/unit.sh
test pkg/tests/deep.sh
test e2e/flow.sh
test pkg/test/x.sh
test checks/a.sh
not pkg/checks/a.sh
test pkg/run.check.sh
test pkg/util.test.sh
test pkg/x.spec.sh
test pkg/foo_test.go
test pkg/test_bar.py
test pkg/bar_test.py
not pkg/main.sh
not pkg/contest/a.sh
not pkg/latest.sh
not pkg/tests.sh
EOF
eq "JRN-005 wf_is_test_path: no patterns means no test" "$(is_test "" tests/unit.sh)" not

echo "== JRN-005 budget-check uses the shared matcher"
R="$WORK/repo"
git_init_repo "$R"
FILES='checks/a.sh
e2e/flow.sh
pkg/bar_test.py
pkg/checks/a.sh
pkg/contest/a.sh
pkg/foo_test.go
pkg/latest.sh
pkg/main.sh
pkg/run.check.sh
pkg/test/x.sh
pkg/test_bar.py
pkg/tests/deep.sh
pkg/util.test.sh
pkg/x.spec.sh
tests/unit.sh'
while IFS= read -r f; do mkdir -p "$R/$(dirname "$f")"; echo "# $f" >"$R/$f"; done <<<"$FILES"
SPECD=.workflow/specs/001-alpha
mkdir -p "$R/$SPECD"
cp "$AGENTS_SRC/skills/feature-workflow/assets/spec.md" "$R/$SPECD/spec.md"
printf -- '---\ntasks:\n  - {id: T1, status: pending, depends_on: [], size: {files: 15, est_lines: 10, points: S}, predicted_files: [%s]}\n---\n' \
  "$(printf '%s\n' "$FILES" | sed 's/.*/"&"/' | paste -sd, -)" >"$R/$SPECD/tasks.md"
git_commit_all "$R" init

# budget_tests : the paths budget-check counts as tests, sorted, one per line.
budget_tests() { bash "$BC" --spec-dir "$SPECD" --cwd "$R" --predicted 2>/dev/null | jq -r '.test_files // [] | sort[]'; }
# set_profiles NAME... : replace the fixture's work profiles with the named shapes (list, empty-list, absent, empty-block).
set_profiles() {
  local shape
  rm -rf "$R/.workflow/profiles"
  for shape in "$@"; do
    case $shape in
      list) write_profile "$R" "p-$shape" "$PROFILE_PATTERNS" ;;
      empty-list) write_profile "$R" "p-$shape" '[]' ;;
      absent) write_profile "$R" "p-$shape" ;;
      empty-block) empty_toolchain_profile "$R/.workflow/profiles" "p-$shape" ;;
      invalid) write_profile "$R" "p-$shape" '"tests/"' ;;
    esac
  done
}

ALL_SHAPES_TESTS='checks/a.sh
e2e/flow.sh
pkg/bar_test.py
pkg/foo_test.go
pkg/run.check.sh
pkg/test/x.sh
pkg/test_bar.py
pkg/tests/deep.sh
pkg/util.test.sh
pkg/x.spec.sh
tests/unit.sh'
LIST_ONLY_TESTS='checks/a.sh
pkg/run.check.sh
pkg/tests/deep.sh
tests/unit.sh'
DEFAULT_TESTS='e2e/flow.sh
pkg/bar_test.py
pkg/foo_test.go
pkg/test/x.sh
pkg/test_bar.py
pkg/tests/deep.sh
pkg/util.test.sh
pkg/x.spec.sh
tests/unit.sh'
# both_classify LABEL WANT SHAPE... : with profiles of the given shapes, budget-check treats exactly WANT as tests.
both_classify() {
  local label=$1 want=$2
  shift 2
  set_profiles "$@"
  eq "JRN-005 budget-check counts the expected tests with $label" "$(budget_tests)" "$want"
}
both_classify "a list beside [], absent and empty-block profiles" "$ALL_SHAPES_TESTS" list empty-list absent empty-block
both_classify "a list only" "$LIST_ONLY_TESTS" list
both_classify "a [] profile only" "$DEFAULT_TESTS" empty-list
both_classify "a profile without the key only" "$DEFAULT_TESTS" absent
both_classify "an empty Toolchain block only" "$DEFAULT_TESTS" empty-block

set_profiles list invalid
out=$(bash "$BC" --spec-dir "$SPECD" --cwd "$R" --predicted 2>&1); rc=$?
eq "JRN-005 budget-check exits 1 on an invalid test_patterns" "$rc" 1
check "JRN-005 budget-check names the profile in its own message" \
  '[[ "$out" == *"budget-check.sh: test_patterns in "*"p-invalid.md must be a list of path patterns"* ]]' "$out"

echo "== JRN-005 one copy of the defaults"
copies=$(cd "$WORK/scaffold" && grep -rlx -F -e '*_test.go' --include='*.sh' .agents | grep -vx '.agents/lib/test-paths.sh')
eq "JRN-005 no shell file under .agents/ outside lib/test-paths.sh lists the default test patterns" "$copies" ""

shellcheck_files "shellcheck: lib/test-paths.sh, budget-check.sh" "$LIB" "$BC"
finish
