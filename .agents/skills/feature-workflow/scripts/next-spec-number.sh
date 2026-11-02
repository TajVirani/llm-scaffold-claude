#!/usr/bin/env bash
# File: Helper script (not a hook): print the number a new spec folder takes at discovery 0.1.1.
# Purpose: One call for 0.1.1 numbering. With no tracker set up (no .workflow/issue-tracking.yaml, or `issue_tracker: none`)
#   the number is the next one after the highest any spec has taken (the local scan); with a tracker set up it is the number
#   of a new tracker issue. issue-tracking's issue-tracker.sh create-spec reads the settings and decides which: its
#   `skipped: no tracker` answer sends the number to the local scan. The scan runs in the main checkout, where the spec
#   worktrees sit, even when --cwd is a spec worktree. A number stays taken after its folder leaves the top level of
#   .workflow/specs/: it counts the spec folders at the top level and in the Done folder .workflow/specs/done/, the spec
#   worktrees .workflow/.spec-worktrees/NNN-slug, and every initiative's `origin` and `slices[].spec`, in the working tree
#   and on each `initiative/*` branch (local or on origin). A folder without a numeric prefix never counts. Spec branches
#   are not counted: every spec a merged and deleted spec branch held is in one of these places.
# Usage:
#   next-spec-number.sh [--cwd <dir>]
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
# stdout: no tracker: the number, zero-padded to five digits, one line. A tracker: the issue number padded to five digits,
#   then the issue's https URL on a second line.
# Exit: 0 number printed; 1 the tracker failed, or answered with no https issue URL ending in its number (cause on stderr,
#   nothing on stdout); 2 usage error, not a git repository, an unreadable initiative.md, or settings issue-tracker.sh
#   refuses (an unknown `issue_tracker`, a tracker without its three distinct, non-empty `issue_flow` labels, an origin
#   remote on another host, or the tracker's CLI not installed).
# Called by: modules/discovery.md (0.1.1), tests/fixtures/initiative.sh.
# Notes: Requires git and mikefarah yq v4. Always calls issue-tracking/scripts/issue-tracker.sh create-spec first, which
#   calls no gh or glab when no tracker is set up. bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/workflow-paths.sh
. "$SCRIPT_DIR/../../../lib/workflow-paths.sh"

PROG=next-spec-number.sh
ISSUE_TRACKER=$SCRIPT_DIR/../../issue-tracking/scripts/issue-tracker.sh
NO_TRACKER_ANSWER="skipped: no tracker"

# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a tracker failure).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }

# usage : print the usage line to stderr and exit 2.
usage() { echo "usage: $PROG [--cwd <dir>]" >&2; exit 2; }

# spec_references NAME [FILE] : print the `origin` and each `slices[].spec` of the initiative.md in FILE (default stdin),
#   named NAME in the error when its frontmatter cannot be read.
spec_references() {
  yq --front-matter=extract '.origin, (.slices // [] | .[].spec)' "${2:--}" || die "cannot read the frontmatter of $1"
}

# taken_spec_names ROOT : print, one per line, every spec folder name and initiative spec reference in the checkout ROOT
#   and on its initiative branches; lines without a numeric prefix are left for the caller to drop.
taken_spec_names() {
  local root=$1 dir file refs ref branch_path listed
  for dir in "$root/$WF_SPECS"/[0-9]*-*/ "$root/$WF_SPECS_DONE"/[0-9]*-*/ "$root/$WF_SPEC_WORKTREES"/[0-9]*-*/; do
    if [[ -d $dir ]]; then basename "$dir"; fi
  done
  for file in "$root/$WF_INITIATIVES"/*/initiative.md; do
    if [[ -f $file ]]; then spec_references "$file" "$file"; fi
  done
  refs=$(git -C "$root" for-each-ref --format='%(refname)' refs/heads/initiative refs/remotes/origin/initiative) ||
    die "cannot list the initiative branches in $root"
  for ref in $refs; do
    branch_path=$WF_INITIATIVES/${ref##*/}/initiative.md
    # Listing the path reads only the branch's trees, so a blob missing from the object store still reaches the read
    # below and fails there, rather than passing for a branch without the file.
    listed=$(git -C "$root" ls-tree "$ref" -- "$branch_path") || die "cannot list $branch_path on $ref"
    # A branch can lack its initiative.md (cut before the file was written); it then takes no number.
    if [[ -n $listed ]]; then
      git -C "$root" show "$ref:$branch_path" | spec_references "$ref:$branch_path" || die "cannot read $ref:$branch_path"
    fi
  done
}

# next_scanned_number ROOT : print the highest spec number taken in the checkout ROOT plus one, zero-padded to five digits.
next_scanned_number() {
  local highest
  highest=$(taken_spec_names "$1" | awk 'match($0, /^[0-9]+/) { print substr($0, 1, RLENGTH) }' | sort -n | tail -1) ||
    exit 2
  printf '%05d\n' $((10#${highest:-0} + 1))
}

# tracker_answer DIR : print what issue-tracker.sh create-spec answers from DIR: a new issue's URL, or NO_TRACKER_ANSWER
#   when no tracker is set up; print nothing and exit 2 when it exits 2 (usage, project or settings), 1 on any other failure.
tracker_answer() {
  local answer tracker_status=0
  answer=$(bash "$ISSUE_TRACKER" --cwd "$1" create-spec) || tracker_status=$?
  if [[ $tracker_status -ne 0 ]]; then
    [[ $tracker_status -eq 2 ]] || die "issue-tracker.sh create-spec failed (exit $tracker_status)" 1
    die "issue-tracker.sh create-spec refused its arguments, the project or the settings"
  fi
  printf '%s\n' "$answer"
}

# print_issue_number URL : print the issue number in the last path segment of URL, zero-padded to five digits, then URL;
#   exit 1 when URL is not an https URL ending in its number.
print_issue_number() {
  local url=$1 number=${1##*/}
  [[ $url == https://*/* && $number =~ ^[0-9]+$ ]] ||
    die "issue-tracker.sh create-spec printed no https issue URL ending in its number: $url" 1
  printf '%05d\n%s\n' $((10#$number)) "$url"
}

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

answer=$(tracker_answer "$cwd") || exit $?
if [[ $answer == "$NO_TRACKER_ANSWER" ]]; then
  main_root=$(wf_main_root "$cwd") || exit 2
  next_scanned_number "$main_root"
else
  print_issue_number "$answer"
fi
