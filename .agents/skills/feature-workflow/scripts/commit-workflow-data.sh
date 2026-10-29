#!/usr/bin/env bash
# File: Helper script (not a hook): commit the workflow data the main session wrote under the workflow root onto the spec branch.
# Purpose: The orchestrator writes spec files, task records, gate evidence under artifacts/, deferred items, decisions and work-backlog
#   items in the main checkout, where no task branch carries them. This commits them on the spec branch at wave start and after each
#   wave's merges, so task branches fork with current workflow data and the spec branch holds it beside the merged code.
#   Staged: the spec folder, the work-backlog, and everything else under the workflow root except other spec and initiative folders
#   (a draft spec or an initiative is committed by its own flow, on its own branch). Gitignored local state (.step, .worktrees/,
#   .handoff/, .cache-staging/, .standards-staging/) stays out: git add skips ignored files, and a run where one of them is
#   not ignored is refused. Only these paths are committed:
#   anything else already staged in the index is left staged.
# Usage:
#   commit-workflow-data.sh <spec-dir> -m <message> [--cwd <dir>]
#     <spec-dir>  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it).
#     -m          the commit message.
#     --cwd       any directory in the project or one of its worktrees (default $PWD); git runs in the MAIN checkout.
# stdout: `committed <sha>` or `nothing to commit`.
# Exit: 0 committed, or nothing to commit; 1 refused: the main checkout is not on the spec branch (spec.md `spec_branch`, else
#   spec/<NNN-slug>; a detached HEAD included), or a merge, cherry-pick or revert is in progress;
#   2 usage or environment error (bad arguments, not a git repository, spec.md missing, yq missing, local state not gitignored,
#   git add or commit failing).
# Called by: modules/implementation-orchestrator.md (wave start, end of 3.16, hand off).
# Notes: Requires git and mikefarah yq v4. Never pushes. bash 3.2 compatible.
# Sources: first-party. Pattern: status-transition.sh (main-checkout resolution, spec-dir normalising).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=commit-workflow-data.sh
USAGE="usage: commit-workflow-data.sh <spec-dir> -m <message> [--cwd <dir>]"
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }
usage() { echo "$USAGE" >&2; exit 2; }

# has_paths PATHSPEC... : true when the pathspecs match a tracked or untracked, non-ignored file in the main checkout.
has_paths() {
  [[ -n "$(git -C "$ROOT" ls-files -c -o --exclude-standard -- "$@" | head -1)" ]]
}

SPEC_ARG="" MSG="" OPT_CWD=$PWD
while [[ $# -gt 0 ]]; do
  case $1 in
    -m) [[ $# -ge 2 ]] || usage; MSG=$2; shift 2 ;;
    --cwd) [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    -*) usage ;;
    *) [[ -z "$SPEC_ARG" ]] || usage; SPEC_ARG=$1; shift ;;
  esac
done
[[ -n "$SPEC_ARG" && -n "$MSG" ]] || usage

command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4"
ROOT=$(wf_main_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
SPEC_DIR=$(wf_norm_folder spec "$SPEC_ARG" 2>/dev/null) || die "spec dir must be $WF_SPECS/NNN-slug: $SPEC_ARG"
SPEC=$(wf_path "$ROOT" "$SPEC_DIR/spec.md")
[[ -f "$SPEC" ]] || die "spec.md not found: $SPEC"

want=$(yq --front-matter=extract '.spec_branch // ""' "$SPEC") || die "cannot read spec_branch from $SPEC"
[[ -n "$want" ]] || want="spec/${SPEC_DIR#"$WF_SPECS"/}"
cur=$(git -C "$ROOT" branch --show-current)
[[ "$cur" == "$want" ]] || die "the main checkout is on ${cur:-a detached HEAD}, not the spec branch $want; switch to it first" 1
for h in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
  if git -C "$ROOT" rev-parse -q --verify "$h" >/dev/null; then
    die "a merge, cherry-pick or revert is in progress in $ROOT; finish or abort it first" 1
  fi
done

# Local state must be gitignored: git add cannot exclude an ignored path, so a missing ignore block is refused, never committed.
leak=$(git -C "$ROOT" ls-files -o --exclude-standard -- "$SPEC_DIR/.step" "$WF_WORKTREES" "$WF_HANDOFF" "$WF_CACHE_STAGING" \
  "$WF_STANDARDS_STAGING")
[[ -z "$leak" ]] || die "local state is not gitignored: ${leak%%$'\n'*}; restore the workflow block in .gitignore (install.sh writes it)"
PATHS=()

# stage PATHSPEC... : stage the pathspecs and append their staged files to PATHS; no-op when none match.
stage() {
  local f
  has_paths "$@" || return 0
  git -C "$ROOT" add -A -- "$@" || die "git add failed for $1"
  while IFS= read -r -d '' f; do PATHS+=("$f"); done \
    < <(git -C "$ROOT" diff --cached --name-only -z --no-renames -- "$@")
}

stage "$SPEC_DIR"
stage "$WF_WORK_BACKLOG"
stage "$WF_DIR" ":(exclude)$WF_SPECS" ":(exclude)$WF_INITIATIVES"

# Commit these files only, never other staged work; literal pathspecs keep names with glob characters intact.
if [[ ${#PATHS[@]} -eq 0 ]]; then
  echo "nothing to commit"
  exit 0
fi

git -C "$ROOT" --literal-pathspecs commit -q -m "$MSG" -- "${PATHS[@]}" || die "git commit failed"
echo "committed $(git -C "$ROOT" rev-parse HEAD)"
