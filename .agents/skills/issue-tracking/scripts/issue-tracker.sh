#!/usr/bin/env bash
# File: Helper script (not a hook): file and update a spec's or a task's tracker issue on GitLab (glab) or GitHub (gh).
# Purpose: The one place the workflow talks to the tracker about issues. The host comes from the `origin` remote and the
#   issue flow labels from .workflow/issue-tracking.yaml. Interface placeholder: it parses its arguments and prints a fixed
#   URL until the tracker calls are built.
# Usage:
#   issue-tracker.sh [--cwd <dir>] <command> [args]
#     create-spec                              create the spec's issue with a placeholder title and an empty body, in
#                                              the backlog stage; prints its URL.
#     fill <issue-url> <spec.md>               set the issue title from the file's first `# ` heading and the body to the
#                                              whole file, passed as a file.
#     create-task <spec-issue-url> <task-file> create a task's issue under the spec's issue (a GitLab child task, or a
#                                              `relates_to` linked issue when GitLab refuses the child; a GitHub
#                                              sub-issue), its body the task file; prints its URL.
#     move <issue-url> backlog|in_progress|done
#                                              remove the other flow labels and add this one; done also closes the
#                                              issue, in_progress reopens a closed one.
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
# stdout: a URL (create-spec, create-task), or `skipped: no tracker` when no tracker is set up.
# Exit: 0 done or skipped; 1 the tracker failed (named on stderr); 2 usage error or bad settings.
# Called by: modules/discovery.md, modules/questioning-loop.md, modules/discovery-impact.md, modules/task-breakdown.md,
#   modules/implementation-setup.md, modules/implementation-waves.md, modules/implementation-finish.md,
#   modules/review-triage.md, modules/sign-off.md, feature-workflow/scripts/next-spec-number.sh.
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

PROG=issue-tracker.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage lines to stderr and exit 2.
usage() {
  cat >&2 <<EOF
usage: $PROG [--cwd <dir>] create-spec
       $PROG [--cwd <dir>] fill <issue-url> <spec.md>
       $PROG [--cwd <dir>] create-task <spec-issue-url> <task-file>
       $PROG [--cwd <dir>] move <issue-url> backlog|in_progress|done
EOF
  exit 2
}

cwd=$PWD
args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd)
      [[ $# -ge 2 ]] || usage
      cwd=$2
      shift 2
      ;;
    -h | --help) usage ;;
    -*) usage ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done
[[ -d $cwd ]] || die "--cwd is not a directory: $cwd"
[[ ${#args[@]} -ge 1 ]] || usage

case ${args[0]} in
  create-spec | fill | create-task | move) ;;
  *) usage ;;
esac

echo https://example.invalid/placeholder
