#!/usr/bin/env bash
# File: Helper script (not a hook): check one spec against its soft size budget (D58).
# Purpose: Compare the task count (2.6) and the changed-file count (3.15, once per wave after the 3.16 merge) with the spec's
#   `budget: {max_tasks, max_changed_files}`. Read-only: it never writes spec.md, tasks.md or .step.
# Usage:
#   budget-check.sh --spec-dir specs/NNN-slug [--cwd <dir>]
#     --spec-dir  `specs/NNN-slug` (relative to the project root, or an absolute path ending in it). spec.md and tasks.md are read
#                 from the MAIN checkout, found with `git rev-parse --git-common-dir` (D18).
#     --cwd       where the changed files are counted (a task worktree or feature branch). Default: the main checkout's HEAD.
#                 The main checkout is located from --cwd, or from $PWD when --cwd is absent.
# Budget source, first found wins (each source must give both keys as non-negative integers, or the script exits 1):
#   spec     spec.md frontmatter `budget: {max_tasks, max_changed_files}` (written at 2.5 / 0.3.20, raised at 00.29)
#   rules    docs/rules.md: the first fenced yaml block under `## Size budget`, key `size_budget: {max_tasks, max_changed_files}`
#   default  max_tasks 10, max_changed_files 30 (D58, confirmed by the user)
# Counts:
#   tasks          records in the tasks.md frontmatter `tasks:` array, excluding `split-out` ones (their work moved to the backlog at a
#                  00.29 split, D68), so 2.6 does not trip again after a split.
#   changed_files  `git diff --name-only <baseline_revision>..HEAD` in the count directory, excluding the spec folder and specs/work-backlog/.
#                  When spec.md has no baseline_revision yet, changed files are not counted: changed_files is null and `note` says why.
# stdout: one JSON object {max_tasks, tasks, max_changed_files, changed_files, over: ["tasks"|"changed_files"...], source: "spec"|"rules"|"default"}
#   plus `note` when changed files were not counted. A count is over when it is greater than its maximum.
# Exit codes: 0 within budget; 2 over budget (the caller runs 00.21 with blocked_condition "size budget: <what>", then 00.29);
#   1 usage or environment error (missing yq/jq, not a git repo, missing file, malformed budget, unknown baseline commit).
# Called by: modules task-breakdown (2.6) and implementation-orchestrator (3.15); discovered-work at 00.29 after an approved overrun.
# Plan refs: 2.5, 2.6, 3.15, 3.16, 0.3.20, 00.21, 00.29; reference "Sizing", "Discovered work", "Per-feature files"; assetlist D18, D38, D56, D58, D68.
# Notes: Requires git, jq and mikefarah yq v4 (D38). bash 3.2 compatible.
# Sources: first-party; PLAN/decision-flow-reference.md 2.6, 3.15, 3.16, "Sizing", "Discovered work: the scope-creep guardrail"; assetlist D18, D38, D56, D58;
#   project-setup/assets/docs/rules.md "Size budget"; feature-workflow/assets/spec.md `budget`. Pattern: status-transition.sh (main-checkout resolution).

set -euo pipefail

PROG=budget-check.sh
DEFAULT_MAX_TASKS=10
DEFAULT_MAX_CHANGED_FILES=30

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 1; }

usage() {
  echo "usage: budget-check.sh --spec-dir specs/NNN-slug [--cwd <dir>]" >&2
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
    [[ "$(basename "$(dirname "$d")")" == "specs" ]] || die "spec dir must be specs/NNN-slug: $1"
    d="specs/$(basename "$d")"
  fi
  [[ "$d" =~ ^specs/[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "spec dir must be specs/NNN-slug: $1"
  printf '%s\n' "$d"
}

# read_budget <yq-expression yielding the budget map> <file> [front-matter]: prints "<max_tasks> <max_changed_files>",
# nothing when the map is absent; dies when it is present but malformed.
read_budget() {
  local expr=$1 file=$2 fm=${3:-} tag mt mc
  if [[ -n "$fm" ]]; then
    tag=$(yq --front-matter=extract "($expr) | tag" "$file") || die "cannot read $file"
  else
    tag=$(yq "($expr) | tag" "$file") || die "cannot parse the Size budget block of docs/rules.md"
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

# ---------------------------------------------------------------- arguments
SPEC_ARG="" OPT_CWD="" HAVE_CWD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-dir) [[ $# -ge 2 ]] || usage; SPEC_ARG=$2; shift 2 ;;
    --cwd)      [[ $# -ge 2 ]] || usage; OPT_CWD=$2; HAVE_CWD=1; shift 2 ;;
    -h|--help)  usage ;;
    *)          die "unknown argument: $1" ;;
  esac
done
[[ -n "$SPEC_ARG" ]] || usage
[[ $HAVE_CWD -eq 0 ]] || [[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
command -v jq >/dev/null 2>&1 || die "jq not found on PATH"
command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (D38)"
yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (D38)"

ROOT=$(main_root "${OPT_CWD:-$PWD}")
SPEC_DIR=$(norm_spec_dir "$SPEC_ARG")
SPEC="$ROOT/$SPEC_DIR/spec.md"
TASKS="$ROOT/$SPEC_DIR/tasks.md"
RULES="$ROOT/docs/rules.md"
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

BASE=$(yq --front-matter=extract '.baseline_revision // ""' "$SPEC") || die "cannot read the frontmatter of $SPEC"
[[ "$BASE" != "null" ]] || BASE=""
FILES_JSON=null NOTE=""
if [[ -z "$BASE" ]]; then
  NOTE="baseline_revision is not captured in spec.md yet (1.1, or 3.1 on the light path); changed files not counted"
else
  git -C "$COUNT_DIR" rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null \
    || die "baseline_revision $BASE is not a commit in $COUNT_DIR"
  list=$(git -C "$COUNT_DIR" diff --name-only "$BASE..HEAD") || die "git diff failed in $COUNT_DIR"
  n=0
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    case "$f" in
      "$SPEC_DIR"/*|specs/work-backlog/*) continue ;;
    esac
    n=$((n + 1))
  done <<<"$list"
  FILES_JSON=$n
fi

OVER='[]'
[[ "$TASK_COUNT" -le "$MAX_TASKS" ]] || OVER=$(jq -c '. + ["tasks"]' <<<"$OVER")
if [[ "$FILES_JSON" != "null" && "$FILES_JSON" -gt "$MAX_FILES" ]]; then
  OVER=$(jq -c '. + ["changed_files"]' <<<"$OVER")
fi

jq -n --argjson mt "$MAX_TASKS" --argjson t "$TASK_COUNT" --argjson mc "$MAX_FILES" --argjson c "$FILES_JSON" \
  --argjson over "$OVER" --arg src "$SOURCE" --arg note "$NOTE" \
  '{max_tasks:$mt, tasks:$t, max_changed_files:$mc, changed_files:$c, over:$over, source:$src}
   + (if $note == "" then {} else {note:$note} end)'

[[ "$OVER" == "[]" ]] || exit 2
exit 0
