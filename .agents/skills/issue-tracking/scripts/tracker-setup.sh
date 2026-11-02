#!/usr/bin/env bash
# File: Helper script (not a hook): check that the project's tracker can be used and save the tracker settings.
# Purpose: Setup for tracker issues, run by project-setup or on a project already under way. `check` proves the host CLI
#   (glab for GitLab, gh for GitHub, chosen from the `origin` remote) is installed, new enough and logged in, and that the
#   project has issues enabled. `save` writes .workflow/issue-tracking.yaml with the host and the three agreed issue flow
#   labels. Interface placeholder: it parses its arguments and prints a fixed line until the checks are built.
# Usage:
#   tracker-setup.sh [--cwd <dir>] check
#       prints the host, then one `missing-label: <name>` line per flow label the tracker lacks.
#   tracker-setup.sh [--cwd <dir>] save --backlog <label> --in-progress <label> --done <label> [--create-labels]
#       writes the settings; labels the tracker lacks are created only with --create-labels, otherwise nothing is written.
#   tracker-setup.sh [--cwd <dir>] save --none
#       writes `issue_tracker: none`.
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
# Exit: 0 checked or saved; 1 refused, with the reason on stderr (CLI missing, not logged in, issues disabled, CLI older
#   than the minimum, labels missing without --create-labels); 2 usage error.
# Called by: project-setup, the issue-tracking skill.
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

PROG=tracker-setup.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage lines to stderr and exit 2.
usage() {
  cat >&2 <<EOF
usage: $PROG [--cwd <dir>] check
       $PROG [--cwd <dir>] save --backlog <label> --in-progress <label> --done <label> [--create-labels]
       $PROG [--cwd <dir>] save --none
EOF
  exit 2
}

cwd=$PWD command=""
backlog="" in_progress="" done_label="" create_labels=0 none=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd | --backlog | --in-progress | --done)
      [[ $# -ge 2 ]] || usage
      case $1 in
        --cwd) cwd=$2 ;;
        --backlog) backlog=$2 ;;
        --in-progress) in_progress=$2 ;;
        --done) done_label=$2 ;;
      esac
      shift 2
      ;;
    --create-labels)
      create_labels=1
      shift
      ;;
    --none)
      none=1
      shift
      ;;
    check | save)
      [[ -z $command ]] || usage
      command=$1
      shift
      ;;
    *) usage ;;
  esac
done
[[ -d $cwd ]] || die "--cwd is not a directory: $cwd"
case $command in
  check)
    [[ $none -eq 0 && $create_labels -eq 0 && -z $backlog$in_progress$done_label ]] || usage
    ;;
  save)
    if [[ $none -eq 1 ]]; then
      [[ $create_labels -eq 0 && -z $backlog$in_progress$done_label ]] || usage
    else
      [[ -n $backlog && -n $in_progress && -n $done_label ]] || usage
    fi
    ;;
  *) usage ;;
esac

echo placeholder
