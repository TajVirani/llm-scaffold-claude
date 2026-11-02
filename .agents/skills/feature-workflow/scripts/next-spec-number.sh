#!/usr/bin/env bash
# File: Helper script (not a hook): print the number a new spec folder takes at discovery 0.1.1.
# Purpose: One call for 0.1.1 numbering. With no tracker set up (no .workflow/issue-tracking.yaml, or `issue_tracker: none`)
#   the number is the next one after the highest any spec has taken (the local scan); with a tracker set up it is the number
#   of a new tracker issue. Interface placeholder: it parses its arguments and prints a fixed number until the scan and the
#   tracker branch are built.
# Usage:
#   next-spec-number.sh [--cwd <dir>]
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
# stdout: no tracker: the number, zero-padded to five digits, one line. A tracker: the issue number padded to five digits,
#   then the issue URL on a second line.
# Exit: 0 number printed; 1 the tracker failed (cause on stderr, nothing on stdout); 2 usage error or a bad settings file.
# Called by: modules/discovery.md (0.1.1).
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

PROG=next-spec-number.sh

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
    -h | --help) usage ;;
    *) usage ;;
  esac
done
[[ -d $cwd ]] || die "--cwd is not a directory: $cwd"

echo 00000
