#!/usr/bin/env bash
# File: Helper script (not a hook): start a spec in its own spec worktree, or remove that worktree and the spec branch once merged.
# Purpose: A spec runs in a spec worktree, <main checkout>/.workflow/.spec-worktrees/NNN-slug, on its spec branch spec/NNN-slug, so
#   several specs run in one clone while the main checkout stays on its own branch. Discovery writes the spec folder and other workflow
#   data (glossary terms, decisions, deferred items, caches) uncommitted in the checkout it runs in. `create` carries all of it onto the
#   spec branch's first commit, so nothing of the spec stays behind, and moves the gitignored step marker into the new worktree.
#   `remove` undoes the worktree and deletes the branch at sign-off, only once the spec branch has merged.
# Usage:
#   spec-worktree.sh create <spec-dir> [--cwd <dir>]
#     <spec-dir>  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it), holding spec.md in the
#                 checkout --cwd is in (default $PWD; the checkout discovery ran in, normally the main checkout).
#     Creates spec/NNN-slug off the main branch (rules-setting.sh main_branch) by switching that checkout to it, commits the workflow
#     data there with commit-workflow-data.sh ("Spec NNN-slug": the spec folder, the work-backlog and the rest of the workflow root
#     except other spec and initiative folders), switches the checkout back to the branch (or detached commit) it was on, adds the
#     spec worktree on the spec branch and moves .step into it. When spec/NNN-slug already exists (a resumed run), only the last two.
#     When the spec worktree already exists on the spec branch, nothing changes.
#     stdout: `worktree <absolute path>` and `baseline <sha>`, the spec branch's first commit (its oldest commit not on the main branch).
#   spec-worktree.sh remove <spec-dir> [--cwd <dir>]
#     <spec-dir>  the spec folder, at the top level of the specs folder or in its Done folder; only its NNN-slug name is used.
#     Sign-off (5.8), after the spec branch has merged into the main branch (local, or origin/<main>): removes the spec worktree and
#     deletes spec/NNN-slug with `git branch -d`, the safe delete. Run it from outside the spec worktree (the main checkout).
#     stdout: `removed worktree <path>` (when there was one) and `deleted branch spec/NNN-slug` (when there was one).
# Exit: 0 done (or nothing to do); 1 refused, nothing removed or switched: create while the checkout is mid-merge, cherry-pick or
#   revert, on the spec branch already, inside another spec's worktree, or cannot switch (git's reason follows), or the spec branch
#   is checked out in another checkout; remove while the spec branch is not merged into the main branch, the spec worktree has uncommitted or untracked
#   changes, or an agent worktree is still registered inside it; 2 usage or environment error (bad arguments, not a git repository,
#   spec.md missing, a git step failing part-way, with what to do next).
# Called by: modules/verification-setup.md (1.1), modules/discovery.md (0.3.20), modules/sign-off.md (5.8).
# Notes: Requires git and mikefarah yq v4 (through commit-workflow-data.sh and rules-setting.sh). Never pushes, never force-deletes.
#   bash 3.2 compatible.
# Sources: first-party. Pattern: commit-workflow-data.sh (spec-checkout resolution, spec-dir normalising).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROG=spec-worktree.sh
USAGE="usage: spec-worktree.sh create|remove <spec-dir> [--cwd <dir>]"
# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a refusal).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }
# usage : print the usage line to stderr and exit 2.
usage() { echo "$USAGE" >&2; exit 2; }

# registered_worktree PATH : true when PATH is a worktree git knows, in any checkout of this repository.
registered_worktree() {
  git -C "$MAIN_ROOT" worktree list --porcelain | grep -qxF "worktree $1"
}

# baseline : print the spec branch's oldest commit that the main branch does not hold.
baseline() {
  local first
  first=$(git -C "$MAIN_ROOT" rev-list --reverse "$MAIN_BRANCH..$BRANCH" | head -n 1) || die "cannot list the commits of $BRANCH"
  [[ -n "$first" ]] || die "$BRANCH has no commit that $MAIN_BRANCH lacks; it carries no spec yet"
  printf '%s\n' "$first"
}

# move_step : move the step marker from the checkout discovery ran in into the spec worktree, and drop the emptied folder.
move_step() {
  local from=$ROOT/$SPEC_DIR to=$WT/$SPEC_DIR
  [[ "$ROOT" != "$WT" && -f "$from/.step" ]] || return 0
  [[ -d "$to" ]] || die "the spec worktree $WT holds no $SPEC_DIR; the spec branch $BRANCH does not carry the spec"
  mv "$from/.step" "$to/.step" || die "cannot move $from/.step into $to"
  # Only gitignored leftovers can remain once the folder is committed, and those are kept, not deleted.
  rmdir "$from" 2>/dev/null || printf '%s: kept %s: it still holds files git ignores\n' "$PROG" "$from" >&2
}

# create : the create mode in the header.
create() {
  local prev rc out
  if [[ -d "$WT" ]]; then
    registered_worktree "$WT" || die "$WT exists but is not a git worktree; move it aside and run again"
    [[ "$(git -C "$WT" branch --show-current)" == "$BRANCH" ]] || die "the spec worktree $WT is not on $BRANCH" 1
    move_step
    printf 'worktree %s\nbaseline %s\n' "$WT" "$(baseline)"
    return 0
  fi
  [[ "$ROOT" != "$MAIN_ROOT/$WF_SPEC_WORKTREES"/* ]] ||
    die "$ROOT is another spec's worktree; run create from the checkout discovery ran in" 1
  prev=$(git -C "$ROOT" symbolic-ref -q --short HEAD || true)
  [[ "$prev" != "$BRANCH" ]] || die "$ROOT is on $BRANCH: this spec runs in that checkout, not in a spec worktree" 1
  [[ -f "$ROOT/$SPEC_DIR/spec.md" ]] || die "spec.md not found: $ROOT/$SPEC_DIR/spec.md"
  for h in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    if git -C "$ROOT" rev-parse -q --verify "$h" >/dev/null; then
      die "a merge, cherry-pick or revert is in progress in $ROOT; finish or abort it first" 1
    fi
  done

  if ! git -C "$MAIN_ROOT" show-ref --verify -q "refs/heads/$BRANCH"; then
    [[ -n "$prev" ]] || prev=$(git -C "$ROOT" rev-parse HEAD)
    out=$(git -C "$ROOT" switch -q -c "$BRANCH" "$MAIN_BRANCH" 2>&1) || die "cannot create $BRANCH in $ROOT: $out" 1
    rc=0
    out=$(bash "$SCRIPT_DIR/commit-workflow-data.sh" "$SPEC_DIR" -m "Spec ${SPEC_DIR##*/}" --cwd "$ROOT" 2>&1) || rc=$?
    if [[ $rc -ne 0 ]]; then
      # Nothing is committed, so switching back carries the data home again and the empty branch can go.
      git -C "$ROOT" switch -q "$prev" 2>/dev/null || git -C "$ROOT" switch -q --detach "$prev" 2>/dev/null ||
        die "the first commit failed ($out) and $ROOT stays on $BRANCH; switch back to $prev by hand"
      git -C "$ROOT" branch -q -d "$BRANCH" 2>/dev/null || printf '%s: left the empty branch %s\n' "$PROG" "$BRANCH" >&2
      die "the spec branch's first commit failed: $out" "$rc"
    fi
    out=$(git -C "$ROOT" switch -q "$prev" 2>&1) || out=$(git -C "$ROOT" switch -q --detach "$prev" 2>&1) ||
      die "the spec is committed on $BRANCH, but $ROOT cannot switch back to $prev: $out; switch back by hand, then run create again"
  fi

  mkdir -p "$(dirname "$WT")" || die "cannot create $(dirname "$WT")"
  out=$(git -C "$MAIN_ROOT" worktree add -q "$WT" "$BRANCH" 2>&1) || die "cannot add the spec worktree $WT: $out" 1
  move_step
  printf 'worktree %s\nbaseline %s\n' "$WT" "$(baseline)"
}

# remove : the remove mode in the header.
remove() {
  local merged="" ref nested out
  if git -C "$MAIN_ROOT" show-ref --verify -q "refs/heads/$BRANCH"; then
    for ref in "refs/heads/$MAIN_BRANCH" "refs/remotes/origin/$MAIN_BRANCH"; do
      git -C "$MAIN_ROOT" show-ref --verify -q "$ref" || continue
      if git -C "$MAIN_ROOT" merge-base --is-ancestor "refs/heads/$BRANCH" "$ref"; then merged=$ref; break; fi
    done
    [[ -n "$merged" ]] || die "$BRANCH is not merged into $MAIN_BRANCH (local or origin); merge it, or pull the merged PR/MR, first" 1
  fi
  if registered_worktree "$WT"; then
    nested=$(git -C "$MAIN_ROOT" worktree list --porcelain | awk -v p="worktree $WT/" 'index($0, p) == 1 { print substr($0, 10) }')
    [[ -z "$nested" ]] || die "agent worktrees are still registered inside $WT: ${nested//$'\n'/, }; remove them first" 1
    out=$(git -C "$MAIN_ROOT" worktree remove "$WT" 2>&1) || die "cannot remove the spec worktree $WT: $out" 1
    echo "removed worktree $WT"
  fi
  if [[ -n "$merged" ]]; then
    out=$(git -C "$MAIN_ROOT" branch -d "$BRANCH" 2>&1) || die "cannot delete $BRANCH: $out" 1
    echo "deleted branch $BRANCH"
  fi
}

MODE="" SPEC_ARG="" OPT_CWD=$PWD
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd) [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    -h | --help) echo "$USAGE"; exit 0 ;;
    -*) usage ;;
    *)
      if [[ -z "$MODE" ]]; then MODE=$1
      elif [[ -z "$SPEC_ARG" ]]; then SPEC_ARG=$1
      else usage; fi
      shift
      ;;
  esac
done
case "$MODE" in create | remove) ;; *) usage ;; esac
[[ -n "$SPEC_ARG" ]] || usage
[[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"

ROOT=$(wf_project_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
MAIN_ROOT=$(wf_main_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
SPEC_DIR=$(wf_norm_folder spec "$SPEC_ARG" 2>/dev/null) || die "spec dir must be $WF_SPECS/NNN-slug: $SPEC_ARG"
BRANCH="spec/${SPEC_DIR##*/}"
WT=$MAIN_ROOT/$WF_SPEC_WORKTREES/${SPEC_DIR##*/}
MAIN_BRANCH=$(bash "$SCRIPT_DIR/rules-setting.sh" main_branch --cwd "$MAIN_ROOT" 2>/dev/null) ||
  die "cannot read main_branch (rules-setting.sh main_branch failed)"

if [[ "$MODE" == create ]]; then
  [[ "$SPEC_DIR" != "$WF_SPECS_DONE"/* ]] || die "a spec in the Done folder is finished; create takes $WF_SPECS/NNN-slug"
  create
else
  remove
fi
