#!/usr/bin/env bash
# File: Helper script (not a hook): check one spec against its soft size budget.
# Purpose: Compare the task count and the predicted file count (2.6, --predicted) or the changed-file count (3.15, once per wave after the 3.16 merge) with the spec's
#   `budget: {max_tasks, max_changed_files}`. The changed-file count is the review load of the feature's PR/MR: the files a reviewer sees
#   against the target branch, minus tests (see Counts). Read-only: it never writes spec.md, tasks.md or .step.
# Usage:
#   budget-check.sh --spec-dir .workflow/specs/NNN-slug [--cwd <dir>] [--predicted]
#     --predicted 2.6: changed_files is the sum of the records' predicted `size.files` (tasks not split-out) instead of a git diff, so the
#                 budget is checked before any code is written. Every counted record needs an integer size.files (exit 1).
#     --spec-dir  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it). spec.md and tasks.md are read
#                 from the MAIN checkout, found with `git rev-parse --git-common-dir`, where the main session writes them.
#     --cwd       where the changed files are counted (a task worktree or feature branch). Default: the main checkout's HEAD.
#                 The main checkout is located from --cwd, or from $PWD when --cwd is absent.
# Budget source, first found wins (each source must give both keys as non-negative integers, or the script exits 1):
#   spec     spec.md frontmatter `budget: {max_tasks, max_changed_files}` (written at 2.5 / 0.3.20, raised at 00.29)
#   rules    .workflow/rules.md: the first fenced yaml block under `## Size budget`, key `size_budget: {max_tasks, max_changed_files}`
#   default  max_tasks 10, max_changed_files 30 (chosen by the user)
# Counts:
#   tasks          records in the tasks.md frontmatter `tasks:` array, excluding `split-out` ones (their work moved to the backlog at a
#                  00.29 split), so 2.6 does not trip again after a split.
#   changed_files  the files a reviewer sees in the feature's PR/MR, minus tests. A file counts when it is in all three:
#                    1. the PR/MR file set: `git diff --name-only $(git merge-base HEAD <target>) HEAD`, so changes caught up by merging
#                       the target branch into the spec branch drop out (`excluded.merge_base`);
#                    2. `git diff --name-only <impl_base_revision>..HEAD`, so files changed only before Phase 3 (the Phase 1 harness and
#                       suite) never count (`excluded.harness_only`); one changed again in Phase 3 counts unless it is a test;
#                    3. not the spec folder or .workflow/specs/work-backlog/ (`excluded.spec_backlog`), and not a test (`excluded.tests`).
#                  <target> is `rules-setting.sh main_branch` (.workflow/rules.md `## Workflow settings`, default the branch origin/HEAD
#                  names, else main), as the local branch and origin/<name>, whichever exist (the merge-base considers both).
#                  Neither ref exists, or no merge-base: the PR/MR set is replaced by the step-2 diff, `merge_base` is null and `note`
#                  says so (caught-up changes then count).
#                  impl_base_revision unset: step 2 uses baseline_revision, with a warning on stderr and in `note` (Phase 1 files then count).
#                  Neither set: changed files are not counted; changed_files is null and `note` says why.
#                  With --predicted: the sum of size.files, less each record's predicted_files entries that are tests (no git diff).
#   tests          a path is a test when it matches a pattern of `test_patterns` in a profile's Toolchain block (.workflow/profiles/*.md,
#                  TEMPLATE.md skipped). A profile without the key, or with [], contributes the defaults:
#                    *.test.*  *.spec.*  __tests__/  tests/  test/  e2e/  *_test.go  test_*.py  *_test.py
#                  No profiles: the defaults. A pattern ending in / matches a folder of that name at any depth; one with another / is
#                  matched against the whole repo-relative path; any other pattern is matched against the file name (shell glob).
# stdout: one JSON object {max_tasks, tasks, max_changed_files, changed_files, over: ["tasks"|"changed_files"...], source: "spec"|"rules"|"default",
#   basis: "predicted"|"impl_base_revision"|"baseline_revision"|null, target: <branch>|null, merge_base: <sha>|null,
#   excluded: {tests, spec_backlog, harness_only, merge_base}|null, files: [counted paths]|null, test_files: [excluded test paths]|null}
#   plus `note` when changed files were not counted or the count fell back. A count is over when it is greater than its maximum.
#   excluded figures not computed in a mode are null (spec_backlog, harness_only and merge_base with --predicted; merge_base on the
#   fallback). With --predicted, test_files lists the test entries of predicted_files and files is null.
# Exit codes: 0 within budget; 2 over budget (the caller runs 00.21 with blocked_condition "size budget: <what>", then 00.29);
#   1 usage or environment error (missing yq/jq, not a git repo, missing file, malformed budget or test_patterns, unknown baseline commit,
#   invalid main_branch).
# Called by: modules task-breakdown (2.6) and implementation-orchestrator (3.15); discovered-work at 00.29 after an approved overrun.
# Notes: Requires git, jq and mikefarah yq v4. bash 3.2 compatible. Reads main_branch through rules-setting.sh (same folder).
# Sources: first-party; formats from project-setup/assets/docs/rules.md "Size budget"; feature-workflow/assets/spec.md `budget`. Pattern: status-transition.sh (main-checkout resolution).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=budget-check.sh
DEFAULT_MAX_TASKS=10
DEFAULT_MAX_CHANGED_FILES=30
DEFAULT_TEST_PATTERNS='*.test.*
*.spec.*
__tests__/
tests/
test/
e2e/
*_test.go
test_*.py
*_test.py'
SCRIPTS_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 1; }

usage() {
  echo "usage: budget-check.sh --spec-dir $WF_SPECS/NNN-slug [--cwd <dir>] [--predicted]" >&2
  exit 1
}

main_root() {
  local common
  common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
    || die "not inside a git repository: $1"
  if [[ "$(basename "$common")" == ".git" ]]; then
    dirname "$common"
  else
    git -C "$1" worktree list --porcelain | sed -n '1s/^worktree //p'
  fi
}

norm_spec_dir() {
  local d=$1
  d=${d%/}
  d=${d#./}
  if [[ "$d" == /* ]]; then
    [[ "$(dirname "$d")" == */"$WF_SPECS" ]] || die "spec dir must be $WF_SPECS/NNN-slug: $1"
    d="$WF_SPECS/$(basename "$d")"
  fi
  [[ "$d" == "$WF_SPECS"/* && "${d#"$WF_SPECS"/}" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
    || die "spec dir must be $WF_SPECS/NNN-slug: $1"
  printf '%s\n' "$d"
}

# read_budget <yq-expression yielding the budget map> <file> [front-matter]: prints "<max_tasks> <max_changed_files>",
# nothing when the map is absent; dies when it is present but malformed.
read_budget() {
  local expr=$1 file=$2 fm=${3:-} tag mt mc
  if [[ -n "$fm" ]]; then
    tag=$(yq --front-matter=extract "($expr) | tag" "$file") || die "cannot read $file"
  else
    tag=$(yq "($expr) | tag" "$file") || die "cannot parse the Size budget block of $WF_RULES"
  fi
  [[ "$tag" != "!!null" ]] || return 0
  [[ "$tag" == "!!map" ]] || die "budget in $file must be a map {max_tasks, max_changed_files}"
  if [[ -n "$fm" ]]; then
    mt=$(yq --front-matter=extract "($expr).max_tasks // \"\"" "$file")
    mc=$(yq --front-matter=extract "($expr).max_changed_files // \"\"" "$file")
  else
    mt=$(yq "($expr).max_tasks // \"\"" "$file")
    mc=$(yq "($expr).max_changed_files // \"\"" "$file")
  fi
  [[ "$mt" =~ ^[0-9]+$ && "$mc" =~ ^[0-9]+$ ]] \
    || die "budget in $file needs non-negative integers max_tasks and max_changed_files (got '$mt', '$mc')"
  printf '%s %s\n' "$mt" "$mc"
}

# profile_test_patterns <profile>: prints the Toolchain block's test_patterns, one per line; nothing when the key is absent or [].
profile_test_patterns() {
  local block tag bad
  block=$(awk '
    /^## /{ if (intool) exit; intool = ($0 ~ /^## Toolchain[[:space:]]*$/); next }
    intool && !infence && /^```ya?ml[[:space:]]*$/ { infence=1; next }
    intool && infence && /^```[[:space:]]*$/ { exit }
    intool && infence { print }
  ' "$1")
  [[ -n "$block" ]] || return 0
  tag=$(printf '%s\n' "$block" | yq '.test_patterns | tag' 2>/dev/null) || die "the Toolchain yaml block does not parse in $1"
  [[ "$tag" != "!!null" ]] || return 0
  [[ "$tag" == "!!seq" ]] || die "test_patterns in $1 must be a list of path patterns"
  bad=$(printf '%s\n' "$block" | yq '[.test_patterns[] | select(tag != "!!str" or . == "")] | length')
  [[ "$bad" == 0 ]] || die "test_patterns in $1 must hold non-empty strings only"
  printf '%s\n' "$block" | yq '.test_patterns[]'
}

load_test_patterns() {
  local f pats all=""
  for f in "$ROOT/$WF_PROFILES"/*.md; do
    [[ -f "$f" && "$(basename "$f")" != TEMPLATE.md ]] || continue
    pats=$(profile_test_patterns "$f") || exit 1
    [[ -n "$pats" ]] || pats=$DEFAULT_TEST_PATTERNS
    all="$all$pats"$'\n'
  done
  [[ -n "$all" ]] || all=$DEFAULT_TEST_PATTERNS
  printf '%s\n' "$all" | sed '/^$/d' | LC_ALL=C sort -u
}

is_test_path() {
  local path=$1 base=${1##*/} pat
  while IFS= read -r pat; do
    [[ -n "$pat" ]] || continue
    if [[ "$pat" == */ ]]; then
      [[ "/$path" == *"/${pat%/}/"* ]] && return 0
    elif [[ "$pat" == */* ]]; then
      # shellcheck disable=SC2053 # the pattern is a glob on purpose
      [[ "$path" == $pat ]] && return 0
    else
      # shellcheck disable=SC2053 # the pattern is a glob on purpose
      [[ "$base" == $pat ]] && return 0
    fi
  done <<<"$TEST_PATTERNS"
  return 1
}

in_spec_or_backlog() {
  case "$1" in
    "$SPEC_DIR"/*|"$WF_WORK_BACKLOG"/*) return 0 ;;
  esac
  return 1
}

add_note() {
  if [[ -z "$NOTE" ]]; then NOTE=$1; else NOTE="$NOTE; $1"; fi
}

warn() {
  add_note "$1"
  printf '%s: warning: %s\n' "$PROG" "$1" >&2
}

sorted_paths() { printf '%s\n' "$1" | sed '/^$/d' | LC_ALL=C sort -u; }
line_count() { printf '%s\n' "$1" | sed '/^$/d' | wc -l | tr -d ' '; }
json_lines() { printf '%s\n' "$1" | jq -R -s -c 'split("\n") | map(select(. != ""))'; }

# ---------------------------------------------------------------- arguments
SPEC_ARG="" OPT_CWD="" HAVE_CWD=0 PREDICTED=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-dir) [[ $# -ge 2 ]] || usage; SPEC_ARG=$2; shift 2 ;;
    --cwd)      [[ $# -ge 2 ]] || usage; OPT_CWD=$2; HAVE_CWD=1; shift 2 ;;
    --predicted) PREDICTED=1; shift ;;
    -h|--help)  usage ;;
    *)          die "unknown argument: $1" ;;
  esac
done
[[ -n "$SPEC_ARG" ]] || usage
[[ $HAVE_CWD -eq 0 ]] || [[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
command -v jq >/dev/null 2>&1 || die "jq not found on PATH"
command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (the Python yq has different flags)"
yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (the Python yq has different flags)"

ROOT=$(main_root "${OPT_CWD:-$PWD}")
SPEC_DIR=$(norm_spec_dir "$SPEC_ARG")
SPEC="$ROOT/$SPEC_DIR/spec.md"
TASKS="$ROOT/$SPEC_DIR/tasks.md"
RULES="$ROOT/$WF_RULES"
COUNT_DIR=$ROOT
[[ $HAVE_CWD -eq 0 ]] || COUNT_DIR=$(git -C "$OPT_CWD" rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
[[ -f "$SPEC" ]] || die "spec.md not found in the main checkout: $SPEC"
[[ -f "$TASKS" ]] || die "tasks.md not found in the main checkout: $TASKS"

# ---------------------------------------------------------------- budget
SOURCE=default MAX_TASKS=$DEFAULT_MAX_TASKS MAX_FILES=$DEFAULT_MAX_CHANGED_FILES
pair=$(read_budget '.budget' "$SPEC" fm)
if [[ -n "$pair" ]]; then
  SOURCE=spec
elif [[ -f "$RULES" ]]; then
  block=$(awk '
    /^## /{ if (insec) exit; insec = ($0 ~ /^## Size budget[[:space:]]*$/); next }
    insec && !infence && /^```ya?ml[[:space:]]*$/ { infence=1; next }
    insec && infence && /^```[[:space:]]*$/ { exit }
    insec && infence { print }
  ' "$RULES")
  if [[ -n "$block" ]]; then
    tmp=$(mktemp)
    printf '%s\n' "$block" >"$tmp"
    pair=$(read_budget '.size_budget' "$tmp") || { rm -f "$tmp"; exit 1; }
    rm -f "$tmp"
    [[ -z "$pair" ]] || SOURCE=rules
  fi
fi
if [[ -n "$pair" ]]; then
  MAX_TASKS=${pair% *} MAX_FILES=${pair#* }
fi

# ---------------------------------------------------------------- counts
tag=$(yq --front-matter=extract '.tasks | tag' "$TASKS") || die "cannot read the frontmatter of $TASKS"
[[ "$tag" == "!!seq" ]] || die "tasks.md has no tasks: array in its frontmatter: $TASKS"
TASK_COUNT=$(yq --front-matter=extract '[.tasks[] | select(.status != "split-out")] | length' "$TASKS")

FILES_JSON=null NOTE="" BASIS=null TARGET_JSON=null MB_JSON=null EXCLUDED_JSON=null COUNTED_JSON=null TESTS_JSON=null
TEST_PATTERNS=$(load_test_patterns) || exit 1
if [[ $PREDICTED -eq 1 ]]; then
  bad=$(yq --front-matter=extract '[.tasks[] | select(.status != "split-out") | select((.size.files | tag) != "!!int") | .id] | join(", ")' "$TASKS") \
    || die "cannot read the frontmatter of $TASKS"
  [[ -z "$bad" ]] || die "--predicted: task(s) $bad have no integer size.files in $TASKS (set at 2.5)"
  sizes=$(yq --front-matter=extract '.tasks[] | select(.status != "split-out") | .id + " " + (.size.files | tostring)' "$TASKS") \
    || die "cannot read the frontmatter of $TASKS"
  # shellcheck disable=SC2016 # yq variable $id
  entries=$(yq --front-matter=extract '.tasks[] | select(.status != "split-out") | .id as $id | (.predicted_files // [])[] | $id + " " + .' "$TASKS") \
    || die "cannot read the frontmatter of $TASKS"
  test_ids="" test_entries="" raw=0 n=0
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if is_test_path "${line#* }"; then
      test_ids="$test_ids${line%% *}"$'\n'
      test_entries="$test_entries${line#* }"$'\n'
    fi
  done <<<"$entries"
  while IFS=' ' read -r id files; do
    [[ -n "$id" ]] || continue
    [[ "$files" =~ ^[0-9]+$ ]] || die "--predicted: size.files must be non-negative integers in $TASKS"
    tests_here=$(printf '%s' "$test_ids" | grep -cx -- "$id" || true)
    raw=$((raw + files))
    # A task predicting fewer files than it lists test entries (globs) cannot go below zero.
    [[ $files -le $tests_here ]] || n=$((n + files - tests_here))
  done <<<"$sizes"
  FILES_JSON=$n
  BASIS='"predicted"'
  EXCLUDED_JSON=$(jq -n -c --argjson t $((raw - n)) '{tests:$t, spec_backlog:null, harness_only:null, merge_base:null}')
  TESTS_JSON=$(json_lines "$(sorted_paths "$test_entries")")
fi
IMPL=$(yq --front-matter=extract '.impl_base_revision // ""' "$SPEC") || die "cannot read the frontmatter of $SPEC"
[[ "$IMPL" != "null" ]] || IMPL=""
BASE=$(yq --front-matter=extract '.baseline_revision // ""' "$SPEC") || die "cannot read the frontmatter of $SPEC"
[[ "$BASE" != "null" ]] || BASE=""
BASE_KEY=impl_base_revision
if [[ $PREDICTED -eq 1 ]]; then
  BASE=""
elif [[ -n "$IMPL" ]]; then
  BASE=$IMPL
elif [[ -n "$BASE" ]]; then
  BASE_KEY=baseline_revision
  warn "impl_base_revision is not set in spec.md (3.1); counted from baseline_revision, so Phase 1 harness and suite files count too"
fi
if [[ $PREDICTED -eq 1 ]]; then
  :
elif [[ -z "$BASE" ]]; then
  add_note "neither impl_base_revision (3.1) nor baseline_revision (1.1, or 3.1 on the light path) is captured in spec.md yet; changed files not counted"
else
  BASIS="\"$BASE_KEY\""
  git -C "$COUNT_DIR" rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null \
    || die "$BASE_KEY $BASE is not a commit in $COUNT_DIR"
  since_base=$(git -C "$COUNT_DIR" diff --name-only "$BASE..HEAD") || die "git diff failed in $COUNT_DIR"
  since_base=$(sorted_paths "$since_base")

  TARGET=$("${BASH:-bash}" "$SCRIPTS_DIR/rules-setting.sh" main_branch --cwd "$ROOT" 2>/dev/null) \
    || die "cannot read main_branch from $WF_RULES (run rules-setting.sh main_branch for the reason)"
  TARGET_JSON=$(jq -n -c --arg t "$TARGET" '$t')
  target_refs=""
  for ref in "refs/heads/$TARGET" "refs/remotes/origin/$TARGET"; do
    if git -C "$COUNT_DIR" show-ref --verify --quiet "$ref"; then target_refs="$target_refs $ref"; fi
  done
  merge_base=""
  if [[ -z "$target_refs" ]]; then
    warn "target branch $TARGET not found (neither $TARGET nor origin/$TARGET exists locally); counted $BASE_KEY..HEAD without the merge-base, so changes merged in from $TARGET count too"
  else
    # shellcheck disable=SC2086 # one or two ref names, split on purpose
    merge_base=$(git -C "$COUNT_DIR" merge-base HEAD $target_refs 2>/dev/null) \
      || { merge_base=""; warn "HEAD has no merge-base with $TARGET; counted $BASE_KEY..HEAD without the merge-base, so changes merged in from $TARGET count too"; }
  fi
  if [[ -n "$merge_base" ]]; then
    MB_JSON="\"$merge_base\""
    in_mr=$(git -C "$COUNT_DIR" diff --name-only "$merge_base" HEAD) || die "git diff failed in $COUNT_DIR"
    in_mr=$(sorted_paths "$in_mr")
    dropped=$(line_count "$(LC_ALL=C comm -23 <(printf '%s\n' "$since_base") <(printf '%s\n' "$in_mr"))")
  else
    in_mr=$since_base
    dropped=null
  fi
  before_base=$(LC_ALL=C comm -13 <(printf '%s\n' "$since_base") <(printf '%s\n' "$in_mr"))
  in_both=$(LC_ALL=C comm -12 <(printf '%s\n' "$since_base") <(printf '%s\n' "$in_mr"))
  n_spec=0 n_harness=0 counted="" test_files=""
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if in_spec_or_backlog "$f"; then n_spec=$((n_spec + 1)); else n_harness=$((n_harness + 1)); fi
  done <<<"$before_base"
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if in_spec_or_backlog "$f"; then
      n_spec=$((n_spec + 1))
    elif is_test_path "$f"; then
      test_files="$test_files$f"$'\n'
    else
      counted="$counted$f"$'\n'
    fi
  done <<<"$in_both"
  FILES_JSON=$(line_count "$counted")
  COUNTED_JSON=$(json_lines "$counted")
  TESTS_JSON=$(json_lines "$test_files")
  EXCLUDED_JSON=$(jq -n -c --argjson t "$(line_count "$test_files")" --argjson s "$n_spec" --argjson h "$n_harness" --argjson m "$dropped" \
    '{tests:$t, spec_backlog:$s, harness_only:$h, merge_base:$m}')
fi

OVER='[]'
[[ "$TASK_COUNT" -le "$MAX_TASKS" ]] || OVER=$(jq -c '. + ["tasks"]' <<<"$OVER")
if [[ "$FILES_JSON" != "null" && "$FILES_JSON" -gt "$MAX_FILES" ]]; then
  OVER=$(jq -c '. + ["changed_files"]' <<<"$OVER")
fi

jq -n --argjson mt "$MAX_TASKS" --argjson t "$TASK_COUNT" --argjson mc "$MAX_FILES" --argjson c "$FILES_JSON" \
  --argjson over "$OVER" --arg src "$SOURCE" --arg note "$NOTE" --argjson basis "$BASIS" \
  --argjson target "$TARGET_JSON" --argjson mb "$MB_JSON" --argjson excl "$EXCLUDED_JSON" \
  --argjson files "$COUNTED_JSON" --argjson tests "$TESTS_JSON" \
  '{max_tasks:$mt, tasks:$t, max_changed_files:$mc, changed_files:$c, over:$over, source:$src, basis:$basis,
    target:$target, merge_base:$mb, excluded:$excl, files:$files, test_files:$tests}
   + (if $note == "" then {} else {note:$note} end)'

[[ "$OVER" == "[]" ]] || exit 2
exit 0
