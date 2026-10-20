#!/usr/bin/env bash
# File: Helper script (not a hook): push one task branch and open its PR/MR into the spec branch (3.16, D85). Never blocks the workflow.
# Purpose: The task review record of task_review `pr` / `pr-blocking`: push the spec branch and the task branch to `origin`, then open a
#   pull request (GitHub, gh) or merge request (GitLab, glab) from the task branch into the spec branch, and print its URL. Anything that
#   prevents it (setting `local`, light-path task without a branch, no origin, unknown host, CLI missing or not logged in, push or create
#   failing) prints `skipped: <reason>` and exits 0, so the orchestrator logs the reason in design-log.md and merges locally anyway.
# Usage:
#   open-task-pr.sh <spec-dir> <task-id> [--cwd <dir>] [--record] [--dry-run]
#     <spec-dir>  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it).
#     <task-id>   T<n>; its tasks.md record gives `branch`, `title` and `file`.
#     --cwd       any directory in the project or one of its worktrees (default $PWD); git runs in the MAIN checkout (D18).
#     --record    after a PR/MR is opened (or found), write its URL with status-transition.sh set-task <spec-dir> <task-id> --pr <url> --step 3.16.
#     --dry-run   print the push and create commands instead of running them (still exits 0).
# Host choice: `git remote get-url origin`; a host containing "github" -> gh (gh pr create --base <spec_branch> --head <branch>), a host
#   containing "gitlab" -> glab (glab mr create --target-branch <spec_branch> --source-branch <branch> --yes); anything else -> skipped.
#   An existing open PR/MR for the same head and base is reused (its URL is printed; nothing new is created).
# Spec branch: spec.md `spec_branch`, else spec/<NNN-slug>.
# PR title "T<n>: <title>"; body names the task file and, when present, artifacts/<task-id>/mini-review.yaml.
# stdout: one line, the PR/MR URL or `skipped: <reason>` (with --dry-run, the commands and then `dry-run: ...`). Details on stderr.
# Exit codes: 0 always once the arguments are valid (opened, reused, skipped or dry run); 1 usage error (bad arguments, spec or task
#   not found).
# Called by: modules/implementation-orchestrator.md (3.16) when rules-setting.sh task_review prints pr or pr-blocking.
# Plan refs: 3.16; assetlist D18, D38, D85.
# Notes: Requires git, mikefarah yq v4 (D38); gh or glab only for the matching host. Pushing the two branches is covered by the
#   stakeholder's task_review setting (standing consent). Never force-pushes. bash 3.2 compatible.
# Sources: first-party; host-to-CLI choice mirrors the glab skill and the sign-off PR step.

set -uo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=open-task-pr.sh
SCRIPTS=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 1; }
skip() { printf '%s: skipped: %s\n' "$PROG" "$1" >&2; printf 'skipped: %s\n' "$1"; exit 0; }
usage() { echo "usage: open-task-pr.sh <spec-dir> <task-id> [--cwd <dir>] [--record] [--dry-run]" >&2; exit 1; }

POS=() OPT_CWD=$PWD RECORD=0 DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd) [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    --record) RECORD=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage ;;
    --*) die "unknown option: $1" ;;
    *) POS+=("$1"); shift ;;
  esac
done
[[ ${#POS[@]} -eq 2 ]] || usage
TASK_ID=${POS[1]}
[[ "$TASK_ID" =~ ^T[0-9]+$ ]] || die "task id must look like T<n>: $TASK_ID"
[[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
if ! command -v yq >/dev/null 2>&1 || ! yq --version 2>/dev/null | grep -q mikefarah; then die "mikefarah yq v4 not found on PATH (D38)"; fi

common=$(git -C "$OPT_CWD" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
if [[ "$(basename "$common")" == ".git" ]]; then ROOT=$(dirname "$common")
else ROOT=$(git -C "$OPT_CWD" worktree list --porcelain | sed -n '1s/^worktree //p'); fi

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
URL=$(git -C "$ROOT" remote get-url origin 2>/dev/null) || skip "no origin remote"
case "$URL" in
  *github*) CLI=gh ;;
  *gitlab*) CLI=glab ;;
  *) skip "origin host is neither GitHub nor GitLab ($URL)" ;;
esac
command -v "$CLI" >/dev/null 2>&1 || skip "$CLI not installed"

PR_TITLE="$TASK_ID: ${TITLE:-$TASK_ID}"
PR_BODY="Task $TASK_ID of $SPEC_DIR (review record, D85).

Task file: $SPEC_DIR/${TFILE:-tasks.md}"
[[ ! -f "$ROOT/$SPEC_DIR/artifacts/$TASK_ID/mini-review.yaml" ]] || PR_BODY="$PR_BODY
Mini-review: $SPEC_DIR/artifacts/$TASK_ID/mini-review.yaml"

if [[ $DRY -eq 1 ]]; then
  echo "git -C $ROOT push -u origin $SPEC_BRANCH $BRANCH"
  if [[ $CLI == gh ]]; then echo "gh pr create --base $SPEC_BRANCH --head $BRANCH --title \"$PR_TITLE\" --body <body>"
  else echo "glab mr create --target-branch $SPEC_BRANCH --source-branch $BRANCH --title \"$PR_TITLE\" --description <body> --yes"; fi
  echo "dry-run: nothing pushed or created"
  exit 0
fi

"$CLI" auth status >/dev/null 2>&1 || skip "$CLI is not logged in ($CLI auth status failed)"
git -C "$ROOT" push -u origin "$SPEC_BRANCH" "$BRANCH" >&2 2>&1 || skip "git push of $SPEC_BRANCH and $BRANCH to origin failed"

first_url() { grep -Eo 'https?://[^[:space:]]+' | tail -n 1; }
PR=""
if [[ $CLI == gh ]]; then
  PR=$(cd "$ROOT" && gh pr list --head "$BRANCH" --base "$SPEC_BRANCH" --state open --json url --jq '.[0].url // empty' 2>/dev/null | first_url)
  [[ -n "$PR" ]] || PR=$(cd "$ROOT" && gh pr create --base "$SPEC_BRANCH" --head "$BRANCH" --title "$PR_TITLE" --body "$PR_BODY" 2>&1 | first_url)
else
  PR=$(cd "$ROOT" && glab mr list --source-branch "$BRANCH" --target-branch "$SPEC_BRANCH" 2>/dev/null | first_url)
  [[ -n "$PR" ]] || PR=$(cd "$ROOT" && glab mr create --target-branch "$SPEC_BRANCH" --source-branch "$BRANCH" --title "$PR_TITLE" --description "$PR_BODY" --yes 2>&1 | first_url)
fi
[[ -n "$PR" ]] || skip "$CLI did not return a PR/MR URL"

if [[ $RECORD -eq 1 ]]; then
  bash "$SCRIPTS/status-transition.sh" set-task "$SPEC_DIR" "$TASK_ID" --pr "$PR" --step 3.16 --cwd "$ROOT" >&2 \
    || printf '%s: warning: could not record the URL in %s; run status-transition.sh set-task %s %s --pr %s --step 3.16\n' "$PROG" "$TASKS" "$SPEC_DIR" "$TASK_ID" "$PR" >&2
fi
printf '%s\n' "$PR"
exit 0
