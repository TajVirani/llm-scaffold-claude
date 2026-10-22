#!/usr/bin/env bash
# File: Helper script (not a hook): push a branch and open its PR/MR: a task branch into the spec branch (3.16), or any head branch into
#   a base branch (the large path's initiative merge). Never blocks the workflow.
# Purpose: Task mode is the task review record of task_review `pr` / `pr-blocking`: push the spec branch and the task branch to `origin`,
#   then open a pull request (GitHub, gh) or merge request (GitLab, glab) from the task branch into the spec branch, and print its URL.
#   Generic mode does the same for a head and base branch the caller names, pushing only the head. Anything that prevents it (setting
#   `local` in task mode, light-path task without a branch, missing head branch, no origin, unknown host, CLI missing or not logged in,
#   push or create failing) prints `skipped: <reason>` and exits 0, so the caller logs the reason and merges locally anyway.
# Usage:
#   Task mode:
#   open-task-pr.sh <spec-dir> <task-id> [--cwd <dir>] [--record] [--dry-run]
#     <spec-dir>  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it).
#     <task-id>   T<n>; its tasks.md record gives `branch`, `title` and `file`.
#     --cwd       any directory in the project or one of its worktrees (default $PWD); git runs in the MAIN checkout.
#     --record    after a PR/MR is opened (or found), write its URL with status-transition.sh set-task <spec-dir> <task-id> --pr <url> --step 3.16.
#     --dry-run   print the push and create commands instead of running them (still exits 0).
#   Generic mode (any of --head, --base, --title or --body selects it; no positional arguments):
#   open-task-pr.sh --head <branch> --base <branch> --title <text> [--body <text>] [--cwd <dir>] [--record <initiative-dir>] [--dry-run]
#     --head      the branch to push and open the PR/MR from; it must exist locally in the main checkout.
#     --base      the branch the PR/MR targets; it is not pushed.
#     --title     the PR/MR title. --body: its description (default: the title).
#     --record    after a PR/MR is opened (or found), write its URL with initiative-transition.sh set-pr <initiative-dir> <url>; the directory is
#                 `.workflow/initiatives/NNN-slug` (relative to the project root, or an absolute path ending in it).
#     --cwd, --dry-run as in task mode. The caller reads task_review; this mode does not.
# Host choice: `git remote get-url origin`; a host containing "github" -> gh (gh pr create --base <base> --head <head>), a host
#   containing "gitlab" -> glab (glab mr create --target-branch <base> --source-branch <head> --yes); anything else -> skipped.
#   An existing open PR/MR for the same head and base is reused (its URL is printed; nothing new is created).
# Spec branch (task mode): spec.md `spec_branch`, else spec/<NNN-slug>.
# PR title (task mode) "T<n>: <title>"; body names the task file and, when present, artifacts/<task-id>/mini-review.yaml.
# stdout: one line, the PR/MR URL or `skipped: <reason>` (with --dry-run, the commands and then `dry-run: ...`). Details on stderr.
# Exit codes: 0 always once the arguments are valid (opened, reused, skipped or dry run), and for -h/--help in either mode (it prints
#   the usage line of the mode the other arguments select, on stdout); 1 task-mode usage error (bad arguments, spec or task not
#   found); 2 generic-mode usage error (a missing --head, --base or --title, an option missing its value or unknown, task-mode
#   arguments mixed in, a --record directory outside the initiatives root or without initiative.md, --cwd outside a git repository).
# Called by: modules/implementation-orchestrator.md (3.16) when rules-setting.sh task_review prints pr or pr-blocking (task mode);
#   modules/large-path.md (6.11 and 6.13, the initiative merge into main) under the same settings (generic mode).
# Notes: Requires git; mikefarah yq v4 in task mode and for --record; gh or glab only for the matching host. Pushing the branches is
#   covered by the stakeholder's task_review setting (standing consent). Never force-pushes. bash 3.2 compatible.
# Sources: first-party; host-to-CLI choice mirrors the glab skill and the sign-off PR step.

set -uo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=open-task-pr.sh
SCRIPTS=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-1}"; }
skip() { printf '%s: skipped: %s\n' "$PROG" "$1" >&2; printf 'skipped: %s\n' "$1"; exit 0; }
TASK_USAGE="usage: open-task-pr.sh <spec-dir> <task-id> [--cwd <dir>] [--record] [--dry-run]"
GENERIC_USAGE="usage: open-task-pr.sh --head <branch> --base <branch> --title <text> [--body <text>] [--cwd <dir>] [--record <initiative-dir>] [--dry-run]"
usage() { echo "$TASK_USAGE" >&2; exit 1; }
# generic_usage MESSAGE : report a generic-mode usage error and exit 2.
generic_usage() {
  printf '%s: %s\n' "$PROG" "$1" >&2
  echo "$GENERIC_USAGE" >&2
  exit 2
}
# show_help : print the usage line of the mode the other arguments select, and exit 0.
show_help() {
  if [[ $GENERIC -eq 1 ]]; then echo "$GENERIC_USAGE"; else echo "$TASK_USAGE"; fi
  exit 0
}

# The generic mode's --record takes a directory while the task mode's is a flag, so the mode is settled before parsing.
GENERIC=0
for arg in "$@"; do
  case "$arg" in --head|--base|--title|--body) GENERIC=1 ;; esac
done

POS=() OPT_CWD=$PWD RECORD=0 RECORD_DIR="" DRY=0 HEAD="" BASE="" TITLE_ARG="" BODY_ARG="" BODY_SET=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)
      if [[ $# -lt 2 ]]; then [[ $GENERIC -eq 0 ]] || generic_usage "--cwd needs a directory"; usage; fi
      OPT_CWD=$2; shift 2 ;;
    --record)
      RECORD=1
      if [[ $GENERIC -eq 1 ]]; then [[ $# -ge 2 ]] || generic_usage "--record needs an initiative directory"; RECORD_DIR=$2; shift; fi
      shift ;;
    --dry-run) DRY=1; shift ;;
    --head|--base|--title|--body)
      [[ $# -ge 2 ]] || generic_usage "$1 needs a value"
      case "$1" in
        --head) HEAD=$2 ;;
        --base) BASE=$2 ;;
        --title) TITLE_ARG=$2 ;;
        --body) BODY_ARG=$2; BODY_SET=1 ;;
      esac
      shift 2 ;;
    -h|--help) show_help ;;
    --*) die "unknown option: $1" $((GENERIC + 1)) ;;
    *) POS+=("$1"); shift ;;
  esac
done

if [[ $GENERIC -eq 1 ]]; then
  [[ ${#POS[@]} -eq 0 ]] || generic_usage "the generic mode (--head) takes no <spec-dir> <task-id>: ${POS[*]}"
  [[ -n "$HEAD" ]] || generic_usage "--head is required"
  [[ -n "$BASE" ]] || generic_usage "--base is required"
  [[ -n "$TITLE_ARG" ]] || generic_usage "--title is required"
  [[ -d "$OPT_CWD" ]] || generic_usage "--cwd is not a directory: $OPT_CWD"
else
  [[ ${#POS[@]} -eq 2 ]] || usage
  TASK_ID=${POS[1]}
  [[ "$TASK_ID" =~ ^T[0-9]+$ ]] || die "task id must look like T<n>: $TASK_ID"
  [[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
  if ! command -v yq >/dev/null 2>&1 || ! yq --version 2>/dev/null | grep -q mikefarah; then die "mikefarah yq v4 not found on PATH"; fi
fi

common=$(git -C "$OPT_CWD" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "not inside a git repository: $OPT_CWD" $((GENERIC + 1))
if [[ "$(basename "$common")" == ".git" ]]; then ROOT=$(dirname "$common")
else ROOT=$(git -C "$OPT_CWD" worktree list --porcelain | sed -n '1s/^worktree //p'); fi

if [[ $GENERIC -eq 1 ]]; then
  if [[ $RECORD -eq 1 ]]; then
    record_arg=$RECORD_DIR
    RECORD_DIR=${RECORD_DIR%/}; RECORD_DIR=${RECORD_DIR#./}
    [[ "$RECORD_DIR" != /* ]] || RECORD_DIR="$WF_INITIATIVES/$(basename "$RECORD_DIR")"
    initiative_slug=${RECORD_DIR#"$WF_INITIATIVES"/}
    [[ "$RECORD_DIR" == "$WF_INITIATIVES"/* && "$initiative_slug" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
      || generic_usage "--record must be $WF_INITIATIVES/NNN-slug: $record_arg"
    [[ -f "$ROOT/$RECORD_DIR/initiative.md" ]] || generic_usage "--record is not an initiative directory (no initiative.md): $record_arg"
  fi
  PUSH_BRANCHES=("$HEAD")
  PR_HEAD=$HEAD PR_BASE=$BASE PR_TITLE=$TITLE_ARG PR_BODY=$TITLE_ARG
  # A flag rather than ${BODY_ARG:-...}, so an explicit --body "" gives an empty description instead of repeating the title.
  [[ $BODY_SET -eq 0 ]] || PR_BODY=$BODY_ARG
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/$HEAD" || skip "head branch $HEAD does not exist locally"
else
  d=${POS[0]%/}; d=${d#./}
  [[ "$d" != /* ]] || d="$WF_SPECS/$(basename "$d")"
  SLUG=${d#"$WF_SPECS"/}
  [[ "$d" == "$WF_SPECS"/* && "$SLUG" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "spec dir must be $WF_SPECS/NNN-slug: ${POS[0]}"
  SPEC_DIR=$d
  SPEC="$ROOT/$SPEC_DIR/spec.md" TASKS="$ROOT/$SPEC_DIR/tasks.md"
  [[ -f "$SPEC" ]] || die "spec.md not found: $SPEC"
  [[ -f "$TASKS" ]] || die "tasks.md not found: $TASKS"
  export TID=$TASK_ID
  n=$(yq --front-matter=extract '[.tasks[] | select(.id == strenv(TID))] | length' "$TASKS" 2>/dev/null) || die "cannot read $TASKS"
  [[ "$n" == 1 ]] || die "task $TASK_ID appears $n times in $TASKS (expected once)"
  rec() { yq --front-matter=extract ".tasks[] | select(.id == strenv(TID)) | .$1 // \"\"" "$TASKS"; }
  BRANCH=$(rec branch) TITLE=$(rec title) TFILE=$(rec file)
  SPEC_BRANCH=$(yq --front-matter=extract '.spec_branch // ""' "$SPEC" 2>/dev/null)
  [[ -n "$SPEC_BRANCH" && "$SPEC_BRANCH" != null ]] || SPEC_BRANCH="spec/$SLUG"

  MODE=$(bash "$SCRIPTS/rules-setting.sh" task_review --cwd "$ROOT" 2>/dev/null) || skip "cannot read task_review from $WF_RULES (rules-setting.sh failed)"
  [[ "$MODE" != local ]] || skip "task_review is local"
  [[ -n "$BRANCH" && "$BRANCH" != null ]] || skip "task $TASK_ID has no branch (light path: it commits on $SPEC_BRANCH)"
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH" || skip "task branch $BRANCH does not exist locally"
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/$SPEC_BRANCH" || skip "spec branch $SPEC_BRANCH does not exist locally"

  PUSH_BRANCHES=("$SPEC_BRANCH" "$BRANCH")
  PR_HEAD=$BRANCH PR_BASE=$SPEC_BRANCH
  PR_TITLE="$TASK_ID: ${TITLE:-$TASK_ID}"
  PR_BODY="Task $TASK_ID of $SPEC_DIR (review record).

Task file: $SPEC_DIR/${TFILE:-tasks.md}"
  [[ ! -f "$ROOT/$SPEC_DIR/artifacts/$TASK_ID/mini-review.yaml" ]] || PR_BODY="$PR_BODY
Mini-review: $SPEC_DIR/artifacts/$TASK_ID/mini-review.yaml"
fi

URL=$(git -C "$ROOT" remote get-url origin 2>/dev/null) || skip "no origin remote"
case "$URL" in
  *github*) CLI=gh ;;
  *gitlab*) CLI=glab ;;
  *) skip "origin host is neither GitHub nor GitLab ($URL)" ;;
esac
command -v "$CLI" >/dev/null 2>&1 || skip "$CLI not installed"

if [[ $DRY -eq 1 ]]; then
  echo "git -C $ROOT push -u origin ${PUSH_BRANCHES[*]}"
  if [[ $CLI == gh ]]; then echo "gh pr create --base $PR_BASE --head $PR_HEAD --title \"$PR_TITLE\" --body <body>"
  else echo "glab mr create --target-branch $PR_BASE --source-branch $PR_HEAD --title \"$PR_TITLE\" --description <body> --yes"; fi
  echo "dry-run: nothing pushed or created"
  exit 0
fi

"$CLI" auth status >/dev/null 2>&1 || skip "$CLI is not logged in ($CLI auth status failed)"
pushed_names=${PUSH_BRANCHES[*]}
git -C "$ROOT" push -u origin "${PUSH_BRANCHES[@]}" >&2 2>&1 || skip "git push of ${pushed_names// / and } to origin failed"

first_url() { grep -Eo 'https?://[^[:space:]]+' | tail -n 1; }
PR=""
if [[ $CLI == gh ]]; then
  PR=$(cd "$ROOT" && gh pr list --head "$PR_HEAD" --base "$PR_BASE" --state open --json url --jq '.[0].url // empty' 2>/dev/null | first_url)
  [[ -n "$PR" ]] || PR=$(cd "$ROOT" && gh pr create --base "$PR_BASE" --head "$PR_HEAD" --title "$PR_TITLE" --body "$PR_BODY" 2>&1 | first_url)
else
  PR=$(cd "$ROOT" && glab mr list --source-branch "$PR_HEAD" --target-branch "$PR_BASE" 2>/dev/null | first_url)
  [[ -n "$PR" ]] || PR=$(cd "$ROOT" && glab mr create --target-branch "$PR_BASE" --source-branch "$PR_HEAD" --title "$PR_TITLE" --description "$PR_BODY" --yes 2>&1 | first_url)
fi
[[ -n "$PR" ]] || skip "$CLI did not return a PR/MR URL"

if [[ $RECORD -eq 1 && $GENERIC -eq 1 ]]; then
  bash "$SCRIPTS/initiative-transition.sh" set-pr "$RECORD_DIR" "$PR" --cwd "$ROOT" >&2 \
    || printf '%s: warning: could not record the URL in %s/initiative.md; run initiative-transition.sh set-pr %s %s\n' "$PROG" "$RECORD_DIR" "$RECORD_DIR" "$PR" >&2
elif [[ $RECORD -eq 1 ]]; then
  bash "$SCRIPTS/status-transition.sh" set-task "$SPEC_DIR" "$TASK_ID" --pr "$PR" --step 3.16 --cwd "$ROOT" >&2 \
    || printf '%s: warning: could not record the URL in %s; run status-transition.sh set-task %s %s --pr %s --step 3.16\n' "$PROG" "$TASKS" "$SPEC_DIR" "$TASK_ID" "$PR" >&2
fi
printf '%s\n' "$PR"
exit 0
