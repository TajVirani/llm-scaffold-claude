#!/usr/bin/env bash
# File: Helper script (not a hook): Tracker adoption, moving a project already under way onto tracker numbering.
# Purpose: Files a tracker issue for each active spec and renames the spec after it (folder, backlog list, spec branch, spec
#   worktree, spec_branch and the task records' branch fields, and every .workflow/ reference); refuses a spec with a live
#   task worktree while the others still run; pushes a renamed branch whose old one was pushed and reports the old one,
#   deleting nothing on the remote; prefixes each Done spec's folder and backlog list with `old_`. Interface placeholder: it
#   parses its arguments and prints a fixed line until the renames are built.
# Usage:
#   tracker-adoption.sh [--cwd <dir>]
#     --cwd    any directory in the project's main checkout. Default: $PWD.
# Exit: 0 every spec adopted; 1 one or more specs refused (each named on stderr); 2 usage or environment error.
# Called by: the issue-tracking skill.
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

PROG=tracker-adoption.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage line to stderr and exit 2.
usage() { echo "usage: $PROG [--cwd <dir>]" >&2; exit 2; }

cwd=$PWD
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd)
      [[ $# -ge 2 ]] || usage
      cwd=$2
      shift 2
      ;;
    *) usage ;;
  esac
done
[[ -d $cwd ]] || die "--cwd is not a directory: $cwd"

echo placeholder
