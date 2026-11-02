#!/usr/bin/env bash
# File: Helper script (not a hook): print the number a new spec folder takes at discovery 0.1.1.
# Purpose: One call for 0.1.1 numbering. With no tracker set up (no .workflow/issue-tracking.yaml, or `issue_tracker: none`)
#   the number is the next one after the highest any spec has taken (the local scan); with a tracker set up it is the number
#   of a new tracker issue. The scan runs in the main checkout, where the spec worktrees sit, even when --cwd is a spec
#   worktree. A number stays taken after its folder leaves the top level of .workflow/specs/: it counts the spec folders at
#   the top level and in the Done folder .workflow/specs/done/, the spec worktrees .workflow/.spec-worktrees/NNN-slug, and
#   every initiative's `origin` and `slices[].spec`, in the working tree and on each `initiative/*` branch (local or on
#   origin). A folder without a numeric prefix never counts. Spec branches are not counted: every spec a merged and deleted
#   spec branch held is in one of these places.
# Usage:
#   next-spec-number.sh [--cwd <dir>]
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
# stdout: no tracker: the number, zero-padded to five digits, one line. A tracker: the issue number padded to five digits,
#   then the issue URL on a second line.
# Exit: 0 number printed; 1 the tracker failed (cause on stderr, nothing on stdout); 2 usage error, not a git repository, an
#   unreadable initiative.md, or a bad settings file (an unknown `issue_tracker`, or a tracker without its three distinct,
#   non-empty `issue_flow` labels).
# Called by: modules/discovery.md (0.1.1), tests/fixtures/initiative.sh.
# Notes: Requires git and mikefarah yq v4; with a tracker, calls issue-tracking/scripts/issue-tracker.sh create-spec.
#   bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/workflow-paths.sh
. "$SCRIPT_DIR/../../../lib/workflow-paths.sh"

PROG=next-spec-number.sh
ISSUE_TRACKER=$SCRIPT_DIR/../../issue-tracking/scripts/issue-tracker.sh

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
  local root=$1 dir file refs ref branch_file
  for dir in "$root/$WF_SPECS"/[0-9]*-*/ "$root/$WF_SPECS_DONE"/[0-9]*-*/ "$root/$WF_SPEC_WORKTREES"/[0-9]*-*/; do
    if [[ -d $dir ]]; then basename "$dir"; fi
  done
  for file in "$root/$WF_INITIATIVES"/*/initiative.md; do
    if [[ -f $file ]]; then spec_references "$file" "$file"; fi
  done
  refs=$(git -C "$root" for-each-ref --format='%(refname)' refs/heads/initiative refs/remotes/origin/initiative) ||
    die "cannot list the initiative branches in $root"
  for ref in $refs; do
    branch_file="$ref:$WF_INITIATIVES/${ref##*/}/initiative.md"
    # A branch can lack its initiative.md (cut before the file was written); it then takes no number.
    if git -C "$root" cat-file -e "$branch_file" 2>/dev/null; then
      git -C "$root" show "$branch_file" | spec_references "$branch_file" || die "cannot read $branch_file"
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

# configured_tracker SETTINGS : print the tracker the settings file SETTINGS names (gitlab, github or none), none when the
#   file is absent; exit 2 when it cannot be read, names another tracker, or gives a tracker no complete issue flow.
configured_tracker() {
  local settings=$1 tracker flow_labels
  if [[ ! -f $settings ]]; then
    echo none
    return 0
  fi
  tracker=$(yq '.issue_tracker // ""' "$settings") || die "cannot read $settings"
  case $tracker in
    none)
      echo none
      return 0
      ;;
    gitlab | github) ;;
    *) die "$settings: issue_tracker must be gitlab, github or none, not '$tracker'" ;;
  esac
  flow_labels=$(yq '[.issue_flow.backlog, .issue_flow.in_progress, .issue_flow.done]
    | map(select(tag == "!!str" and . != "")) | unique | length' "$settings") || die "cannot read issue_flow in $settings"
  [[ $flow_labels == 3 ]] ||
    die "$settings: issue_flow needs three different, non-empty labels: backlog, in_progress and done"
  echo "$tracker"
}

# next_issue_number DIR : create the spec's tracker issue from DIR and print its number, zero-padded to five digits, then
#   its URL; print nothing and exit 2 when issue-tracker.sh exits 2 (usage or settings), 1 on any other failure.
next_issue_number() {
  local url tracker_status=0 number
  url=$(bash "$ISSUE_TRACKER" --cwd "$1" create-spec) || tracker_status=$?
  if [[ $tracker_status -ne 0 ]]; then
    [[ $tracker_status -eq 2 ]] || die "issue-tracker.sh create-spec failed (exit $tracker_status)" 1
    die "issue-tracker.sh create-spec refused its arguments or the settings"
  fi
  number=${url##*/}
  [[ $url == *://*/* && $number =~ ^[0-9]+$ ]] ||
    die "issue-tracker.sh create-spec printed no issue URL ending in its number: $url" 1
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

project_root=$(wf_project_root "$cwd") || exit 2
tracker=$(configured_tracker "$(wf_path "$project_root" "$WF_ISSUE_TRACKING")") || exit 2
if [[ $tracker == none ]]; then
  main_root=$(wf_main_root "$cwd") || exit 2
  next_scanned_number "$main_root"
else
  next_issue_number "$cwd"
fi
