#!/usr/bin/env bash
# File: Helper script (not a hook): check that a finished spec and its sub-items are closed, and move it into the Done folder.
# Purpose: A spec that has shipped leaves the top level of the specs folder, so the top level lists only work in flight.
#   --check reads the spec's task records and the work-backlog items it raised and lists every one still open; it changes
#   nothing. The move runs the same check, then moves a `done` spec into the Done folder (WF_SPECS_DONE), deletes its step
#   marker and rewrites the spec's path in the workflow files that name it, so every link still resolves, and commits the
#   result on the checked-out branch. --sweep moves every `done` spec at the top level in one commit, except the one whose
#   spec_branch is checked out: that is the spec being signed off, and its own move step follows the sweep.
# Usage:
#   move-to-done.sh --check <spec-dir> [--cwd <dir>]   check only: every task record and work-backlog item is closed
#   move-to-done.sh <spec-dir> [--cwd <dir>]           check, then move the done spec into the Done folder, rewrite, commit
#   move-to-done.sh --sweep [--cwd <dir>]              move every done spec at the top level of the specs folder, except
#                                                      the one whose spec_branch is the checked-out branch
#     <spec-dir>  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it); --check also
#                 takes a spec already in the Done folder.
#     --cwd       any directory in the project or one of its worktrees (default $PWD); git runs in the spec checkout
#                 (lib/workflow-paths.sh wf_project_root: the checkout it is in, or the one an agent worktree sits in).
# Closed means: a task record is `done` or `split-out`; every line of the spec's backlog list `<NNN-slug>.md` that starts `- `
#   is a well-formed `- [open] B<n> <kind> (<node>): ...` or `- [promoted] ...` line (a line kept for later or started as a
#   spec); an older work-backlog item `<NNN-slug>-disc-*.md` is `open`, `promoted`, `moved-to-deferred` or `dismissed`. The
#   spec's own status does not matter to --check.
# stdout: one `open: ...` line per open task record, item or malformed backlog line; `check passed: <spec-dir>`; for a move, `moved <old> -> <new>`
#   per spec and `committed <sha>`; for a sweep, `left in place: <spec-dir>` per spec that failed, `skipped: <spec-dir> (moved
#   by its own sign-off step)` for the spec on the checked-out branch, or `nothing to sweep`.
# Exit: 0 check passed, or moved and committed, or nothing to sweep (a sweep that only skips the checked-out spec has
#   nothing to sweep); 1 refused: an open sub-item, a spec that is not `done`, a Done folder entry of the same name, the
#   main branch or a detached HEAD checked out, a merge in progress; nothing changed. For --sweep, 1 also means at least
#   one done spec failed and stayed in place while the others moved and were committed; the skipped spec is not a failure.
#   2 usage or environment error (bad arguments, not a git repository, a folder that is not a spec, spec.md missing, yq
#   missing, a git or file operation failing). An error after the first move rolls the run back before it
#   exits 2: every moved spec goes back with its step marker, every rewritten file gets its old content back and the index
#   is restored, so nothing is left moved or staged. When a rollback step itself fails, stderr names each spec folder, file
#   or index still changed and how to put it back by hand.
# Called by: modules/sign-off.md (5.7 --check, 5.8 the move and the one-off --sweep).
# Notes: Requires git and mikefarah yq v4. Never pushes. bash 3.2 compatible. At sign-off the spec being signed off is
#   already `done` when the sweep runs, so the sweep skips it: the sweep commit holds only the older specs, and the spec's
#   own `move-to-done.sh <spec-dir>` after it still finds the folder at the top level. The move, the path rewrite, the
#   rollback and the commit of exactly the touched paths are the shared path rewrite in lib/workflow-paths.sh (wf_rewrite_*).
# Sources: first-party. Pattern: commit-workflow-data.sh (spec-checkout resolution, explicit staging, path-limited commit).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROG=move-to-done.sh
USAGE="usage: move-to-done.sh --check <spec-dir> | <spec-dir> | --sweep [--cwd <dir>]"
# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a refusal).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }
# usage : print the usage line to stderr and exit 2.
usage() { echo "$USAGE" >&2; exit 2; }

# resolve_spec ARG : print ARG as the repo-relative spec folder; exit 2 when it is not a spec folder or has no spec.md.
resolve_spec() {
  local folder
  folder=$(wf_norm_folder spec "$1" 2>/dev/null) || die "not a spec folder (want $WF_SPECS/NNN-slug): $1"
  [[ -f "$(wf_path "$ROOT" "$folder/spec.md")" ]] || die "spec.md not found: $folder/spec.md"
  printf '%s\n' "$folder"
}

# open_sub_items SPEC_DIR : print one line per task record or work-backlog item of SPEC_DIR that is not closed.
open_sub_items() {
  local spec_dir=$1 tasks list item status
  tasks=$(wf_path "$ROOT" "$spec_dir/tasks.md")
  if [[ -f "$tasks" ]]; then
    yq --front-matter=extract \
      '(.tasks // [])[] | select(.status != "done" and .status != "split-out") | "open: task " + .id + " (" + (.status // "no status") + ")"' \
      "$tasks" || die "cannot read the task records in $spec_dir/tasks.md"
  fi
  list="$(wf_path "$ROOT" "$WF_WORK_BACKLOG")/${spec_dir##*/}.md"
  if [[ -f "$list" ]]; then
    awk -v f="$WF_WORK_BACKLOG/${list##*/}" '
      /^- / && $0 !~ /^- \[(open|promoted)\] B[0-9]+ (bug|requirement|refactor|scope-expansion|decision|budget-split) \([0-9.]+[^)]*\): .+ Evidence: .+/ {
        status = $0; sub(/^- \[/, "", status); sub(/\].*$/, "", status)
        if (status == $0 || status ~ /^(open|promoted)$/) status = "malformed"
        printf "open: backlog line %s:%d (%s)\n", f, NR, status
      }' "$list" || die "cannot read the backlog list $WF_WORK_BACKLOG/${list##*/}"
  fi
  for item in "$(wf_path "$ROOT" "$WF_WORK_BACKLOG")/${spec_dir##*/}"-disc-*.md; do
    [[ -f "$item" ]] || continue
    status=$(yq --front-matter=extract '.status // ""' "$item") || die "cannot read the status of $WF_WORK_BACKLOG/${item##*/}"
    case $status in
      open | promoted | moved-to-deferred | dismissed) ;;
      *) printf 'open: backlog item %s (%s)\n' "$WF_WORK_BACKLOG/${item##*/}" "${status:-no status}" ||
        die "cannot write the list of open sub-items" ;;
    esac
  done
}

MODE=move SPEC_ARG="" OPT_CWD=$PWD
while [[ $# -gt 0 ]]; do
  case $1 in
    --check) MODE=check; shift ;;
    --sweep) MODE=sweep; shift ;;
    --cwd) [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    -h | --help) echo "$USAGE"; exit 0 ;;
    -*) usage ;;
    *) [[ -z "$SPEC_ARG" ]] || usage; SPEC_ARG=$1; shift ;;
  esac
done
if [[ "$MODE" == sweep ]]; then
  [[ -z "$SPEC_ARG" ]] || usage
else
  [[ -n "$SPEC_ARG" ]] || usage
fi

command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4"
ROOT=$(wf_project_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"

if [[ "$MODE" == check ]]; then
  SPEC_DIR=$(resolve_spec "$SPEC_ARG") || exit 2
  OPEN=$(open_sub_items "$SPEC_DIR") || exit 2
  if [[ -n "$OPEN" ]]; then
    printf '%s\n' "$OPEN"
    die "$SPEC_DIR has open sub-items; close them first" 1
  fi
  echo "check passed: $SPEC_DIR"
  exit 0
fi

# The names of the specs this run moved, for the commit body.
MOVED=()

# on_exit : roll back the uncommitted changes when the script fails after its first move, then remove the temporary folder.
on_exit() {
  local exit_code=$?
  set +e
  if [[ $exit_code -ne 0 ]] && wf_rewrite_pending; then
    if wf_rewrite_roll_back; then
      printf '%s: rolled back; nothing was moved, rewritten or committed\n' "$PROG" >&2
    else
      printf '%s: rollback incomplete, nothing was committed; still changed:\n' "$PROG" >&2
      printf '  %s\n' "${WF_REWRITE_LEFT[@]}" >&2
    fi
    exit_code=2
  fi
  wf_rewrite_end
  exit "$exit_code"
}
trap on_exit EXIT

# refuse_unsafe_checkout : exit 1 when the checked-out branch must not take the move commit or git is mid-operation;
#   otherwise set MAIN_BRANCH to the main branch and CURRENT_BRANCH to the checked-out one.
refuse_unsafe_checkout() {
  local refusal
  MAIN_BRANCH=$(bash "$SCRIPT_DIR/rules-setting.sh" main_branch --cwd "$ROOT" 2>/dev/null) ||
    die "cannot read the main branch name (rules-setting.sh main_branch)"
  refusal=$(wf_rewrite_checkout_refusal "$ROOT" "$MAIN_BRANCH") || die "cannot check whether $ROOT may take the move commit"
  [[ -z "$refusal" ]] || die "$refusal" 1
  CURRENT_BRANCH=$(git -C "$ROOT" branch --show-current) || die "cannot read the checked-out branch in $ROOT"
}

# move_refusal SPEC_DIR : print why SPEC_DIR cannot move (its open sub-items, a status other than done, a taken Done
#   folder name), nothing when it can.
move_refusal() {
  local spec_dir=$1 status
  status=$(yq --front-matter=extract '.status // ""' "$(wf_path "$ROOT" "$spec_dir/spec.md")") ||
    die "cannot read the status of $spec_dir/spec.md"
  [[ "$status" == "done" ]] || echo "status is ${status:-empty}, not done" || die "cannot write why $spec_dir cannot move"
  open_sub_items "$spec_dir"
  [[ ! -e "$(wf_path "$ROOT" "$WF_SPECS_DONE/${spec_dir##*/}")" ]] || echo "$WF_SPECS_DONE/${spec_dir##*/} already exists" ||
    die "cannot write why $spec_dir cannot move"
}

# move_spec SPEC_DIR : move SPEC_DIR into the Done folder, set its step marker aside, and rewrite its path and its outbound
#   links in the workflow files; the shared path rewrite queues each changed path for the commit.
move_spec() {
  local spec_dir=$1 target
  target=$WF_SPECS_DONE/${spec_dir##*/}
  wf_rewrite_move "$spec_dir" "$target" || die "cannot move $spec_dir to $target"
  # The step marker is set aside rather than deleted, so a rollback can put it back.
  if [[ -e "$(wf_path "$ROOT" "$target/.step")" ]]; then
    wf_rewrite_set_aside "$target/.step" || die "cannot set aside $target/.step"
  fi
  wf_rewrite_spec_path "$spec_dir" "$target" || die "cannot rewrite the path of $spec_dir in the workflow files"
  MOVED+=("${spec_dir##*/}")
  echo "moved $spec_dir -> $target"
}

# commit_done_folder SUBJECT : commit only the paths the run moved or rewrote, on the checked-out branch, and print the
#   new commit id.
commit_done_folder() {
  local head
  wf_rewrite_commit "$MAIN_BRANCH" "$1" "Moved into the Done folder: ${MOVED[*]}" || die "cannot commit the move"
  head=$(git -C "$ROOT" rev-parse HEAD) || die "committed, but cannot read the new commit id"
  echo "committed $head"
}

if [[ "$MODE" == move ]]; then
  SPEC_DIR=$(resolve_spec "$SPEC_ARG") || exit 2
  [[ "$SPEC_DIR" == "$WF_SPECS/${SPEC_DIR##*/}" ]] || die "$SPEC_DIR is already in the Done folder"
  REFUSAL=$(move_refusal "$SPEC_DIR") || exit 2
  if [[ -n "$REFUSAL" ]]; then
    printf '%s\n' "$REFUSAL"
    die "$SPEC_DIR cannot move; nothing changed" 1
  fi
  refuse_unsafe_checkout
  wf_rewrite_begin "$ROOT" || die "cannot start the move"
  move_spec "$SPEC_DIR"
  commit_done_folder "chore(workflow): move ${SPEC_DIR##*/} into the Done folder"
  exit 0
fi

refuse_unsafe_checkout
wf_rewrite_begin "$ROOT" || die "cannot start the sweep"
LEFT=0
for spec_md in "$(wf_path "$ROOT" "$WF_SPECS")"/*/spec.md; do
  [[ -f "$spec_md" ]] || continue
  name=$(basename "$(dirname "$spec_md")")
  [[ "$name" =~ ^[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || continue
  status=$(yq --front-matter=extract '.status // ""' "$spec_md") || die "cannot read the status of $WF_SPECS/$name/spec.md"
  [[ "$status" == "done" ]] || continue
  spec_branch=$(yq --front-matter=extract '.spec_branch // ""' "$spec_md") ||
    die "cannot read the spec branch of $WF_SPECS/$name/spec.md"
  # At sign-off the spec on the checked-out branch is already done, and its own move must follow the sweep commit.
  if [[ "$spec_branch" == "$CURRENT_BRANCH" ]]; then
    echo "skipped: $WF_SPECS/$name (moved by its own sign-off step)"
    continue
  fi
  REFUSAL=$(move_refusal "$WF_SPECS/$name") || exit 2
  if [[ -n "$REFUSAL" ]]; then
    echo "left in place: $WF_SPECS/$name"
    printf '%s\n' "$REFUSAL" | sed 's/^/  /'
    LEFT=1
    continue
  fi
  move_spec "$WF_SPECS/$name"
done
if [[ ${#MOVED[@]} -eq 0 ]]; then
  [[ $LEFT -eq 0 ]] || die "no done spec could move; nothing changed" 1
  echo "nothing to sweep"
  exit 0
fi
commit_done_folder "chore(workflow): sweep finished specs into the Done folder"
[[ $LEFT -eq 0 ]] || die "some done specs failed the check and stayed in place; the others moved" 1
