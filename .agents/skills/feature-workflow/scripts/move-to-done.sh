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
#   own `move-to-done.sh <spec-dir>` after it still finds the folder at the top level.
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

SLUG_CHARS='A-Za-z0-9._-'
SPECS_LEAF=${WF_SPECS##*/}
DONE_LEAF=${WF_SPECS_DONE#"$WF_SPECS"/}
PATHSPECS=()
MOVED=()
SCRATCH_DIR=$(mktemp -d) || die "cannot create a temporary folder"
TMP_FILE=$SCRATCH_DIR/rewrite
LIST_FILE=$SCRATCH_DIR/list
CANDIDATE_FILE=$SCRATCH_DIR/candidates
MATCH_FILE=$SCRATCH_DIR/matches
SEARCH_ERRORS=$SCRATCH_DIR/search-errors
ROOT_PREFIX=$(wf_path "$ROOT" "")

# What this run changed and has not committed yet, kept so a failure can put it back. MOVED_FROM, MOVED_TO and STEP_COPY
#   are parallel: a spec folder's old and new path and where its step marker was set aside ("" when it had none).
#   SAVED_FILE and SAVED_COPY are parallel: a file's path when it was rewritten and a copy of its content before that.
UNCOMMITTED=0
MOVED_FROM=() MOVED_TO=() STEP_COPY=() SAVED_FILE=() SAVED_COPY=()
CREATED_DONE_FOLDER="" INDEX_FILE="" INDEX_COPY=""

# roll_back : put the index, the rewritten files, the moved spec folders and their step marker back as they were, newest
#   change first; print what was undone, or each change that could not be undone and how to undo it by hand.
roll_back() {
  local i left=()
  if [[ -n "$INDEX_FILE" ]]; then
    if [[ -n "$INDEX_COPY" ]]; then
      cp "$INDEX_COPY" "$INDEX_FILE" || left+=("the index has the move staged: run git reset -q in $ROOT")
    else
      rm -f "$INDEX_FILE" || left+=("the index has the move staged: run git reset -q in $ROOT")
    fi
  fi
  i=${#SAVED_FILE[@]}
  while [[ $i -gt 0 ]]; do
    i=$((i - 1))
    # A file whose write failed before it was truncated still matches its copy and needs no restore.
    cmp -s "${SAVED_COPY[i]}" "${SAVED_FILE[i]}" && continue
    cat "${SAVED_COPY[i]}" >"${SAVED_FILE[i]}" ||
      left+=("${SAVED_FILE[i]} is rewritten: copy ${SAVED_COPY[i]} over it")
  done
  i=${#MOVED_TO[@]}
  while [[ $i -gt 0 ]]; do
    i=$((i - 1))
    if ! mv "${MOVED_TO[i]}" "${MOVED_FROM[i]}"; then
      left+=("${MOVED_TO[i]} is still moved: mv it back to ${MOVED_FROM[i]}")
      [[ -z "${STEP_COPY[i]}" ]] || left+=("its step marker is at ${STEP_COPY[i]}: mv it back to ${MOVED_FROM[i]}/.step")
      continue
    fi
    [[ -z "${STEP_COPY[i]}" ]] || mv "${STEP_COPY[i]}" "${MOVED_FROM[i]}/.step" ||
      left+=("${MOVED_FROM[i]}/.step is missing: mv ${STEP_COPY[i]} back to it")
  done
  [[ -z "$CREATED_DONE_FOLDER" ]] || rmdir "$CREATED_DONE_FOLDER" ||
    left+=("$CREATED_DONE_FOLDER was created by this run: remove it once it is empty")
  if [[ ${#left[@]} -eq 0 ]]; then
    printf '%s: rolled back; nothing was moved, rewritten or committed\n' "$PROG" >&2
    return 0
  fi
  printf '%s: rollback incomplete, nothing was committed; still changed:\n' "$PROG" >&2
  printf '  %s\n' "${left[@]}" >&2
  # The copies named above live in the temporary folder, so it must outlive this run.
  SCRATCH_DIR=""
  return 1
}

# on_exit : roll back the uncommitted changes when the script fails after its first move, then remove the temporary folder.
on_exit() {
  local exit_code=$?
  set +e
  if [[ $UNCOMMITTED -eq 1 && $exit_code -ne 0 ]]; then
    roll_back
    exit_code=2
  fi
  [[ -z "$SCRATCH_DIR" ]] || rm -rf "$SCRATCH_DIR"
  exit "$exit_code"
}
trap on_exit EXIT

# refuse_unsafe_checkout : exit 1 when the checked-out branch must not take the move commit or git is mid-operation;
#   otherwise set CURRENT_BRANCH to it.
refuse_unsafe_checkout() {
  local current main h
  current=$(git -C "$ROOT" branch --show-current) || die "cannot read the checked-out branch in $ROOT"
  [[ -n "$current" ]] || die "the spec checkout has a detached HEAD; check out the spec branch first" 1
  main=$(bash "$SCRIPT_DIR/rules-setting.sh" main_branch --cwd "$ROOT" 2>/dev/null) ||
    die "cannot read the main branch name (rules-setting.sh main_branch)"
  CURRENT_BRANCH=$current
  [[ "$current" != "$main" ]] || die "the spec checkout is on the main branch $main; the move commits on the spec branch" 1
  for h in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    if git -C "$ROOT" rev-parse -q --verify "$h" >/dev/null; then
      die "a merge, cherry-pick or revert is in progress in $ROOT; finish or abort it first" 1
    fi
  done
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

# replace_file FILE : copy TMP_FILE over FILE when they differ, keeping FILE's mode and a copy of its old content for a
#   rollback; true when FILE changed.
replace_file() {
  local copy
  cmp -s "$TMP_FILE" "$1" && return 1
  copy=$SCRATCH_DIR/saved.${#SAVED_FILE[@]}
  cp "$1" "$copy" || die "cannot keep a copy of $1"
  SAVED_FILE+=("$1")
  SAVED_COPY+=("$copy")
  cat "$TMP_FILE" >"$1" || die "cannot write $1"
}

# add_up_level_to_outbound_links FILE DEPTH : give every relative Markdown link in FILE that climbs out of the spec folder
#   one more `../`; DEPTH is how many folders below the spec folder FILE sits.
add_up_level_to_outbound_links() {
  awk -v depth="$2" '
    # climbs_out TARGET : 1 when the path part of TARGET, read from DEPTH folders inside the spec, leaves the spec folder.
    function climbs_out(target,   path, n, segs, i, level) {
      if (target == "" || target ~ /^[A-Za-z][A-Za-z0-9+.-]*:/ || target ~ /^[\/#<]/) return 0
      path = target
      sub(/[#?].*$/, "", path)
      n = split(path, segs, "/")
      level = depth
      for (i = 1; i <= n; i++) {
        if (segs[i] == "..") { if (--level < 0) return 1 }
        else if (segs[i] != "." && segs[i] != "") level++
      }
      return 0
    }
    # adjusted TARGET : TARGET with one more `../` in front when it climbs out of the spec folder, else TARGET as it is.
    function adjusted(target) { return climbs_out(target) ? "../" target : target }
    {
      rest = $0
      out = ""
      if (match(rest, /^ *\[[^]]+\]:[ \t]+/)) {
        out = substr(rest, 1, RLENGTH)
        rest = substr(rest, RLENGTH + 1)
        match(rest, /^[^ \t]*/)
        out = out adjusted(substr(rest, 1, RLENGTH))
        rest = substr(rest, RLENGTH + 1)
      }
      while ((i = index(rest, "](")) > 0) {
        out = out substr(rest, 1, i + 1)
        rest = substr(rest, i + 2)
        match(rest, /^[^ )]*/)
        out = out adjusted(substr(rest, 1, RLENGTH))
        rest = substr(rest, RLENGTH + 1)
      }
      print out rest
    }
  ' "$1" >"$TMP_FILE" || die "cannot read the links in $1"
  replace_file "$1" || true
}

# point_at_done_folder FILE NAME : rewrite each path to spec NAME at the top of the specs folder in FILE into its Done
#   folder path, in the `specs/NAME` forms and, for a file under the specs folder, the `../NAME` form that climbs to it;
#   true when FILE changed.
point_at_done_folder() {
  local file=$1 name=$2 name_re rel_dir slashes depth climb="" climb_re="" end
  name_re=${name//./\\.}
  # A path that ends a sentence keeps its full stop, but `NAME.md` is another file and stays as it is.
  end="(\\.?[^$SLUG_CHARS]|\\.?\$)"
  local exprs
  exprs=(-e ':again' -e "s#(^|[^$SLUG_CHARS])$SPECS_LEAF/$name_re$end#\\1$SPECS_LEAF/$DONE_LEAF/$name\\2#g")
  rel_dir=${file#"$ROOT"/}
  rel_dir=${rel_dir%/*}
  if [[ "$rel_dir" == "$WF_SPECS"/* ]]; then
    rel_dir=${rel_dir#"$WF_SPECS"/}
    slashes=${rel_dir//[!\/]/}
    depth=$((${#slashes} + 1))
    while [[ $depth -gt 0 ]]; do
      climb="$climb../" climb_re="$climb_re\\.\\./"
      depth=$((depth - 1))
    done
    exprs+=(-e "s#(^|[^/$SLUG_CHARS])$climb_re$name_re$end#\\1$climb$DONE_LEAF/$name\\2#g")
  fi
  # Repeat until nothing changes: two paths one character apart share that character, and one pass rewrites only the first.
  exprs+=(-e 't again')
  sed -E "${exprs[@]}" "$file" >"$TMP_FILE" || die "cannot rewrite the spec path in $file"
  replace_file "$file"
}

# list_files_naming NAME : write to MATCH_FILE, NUL-separated, the absolute path of each regular file in the LIST_FILE
#   list (repo-relative paths) whose text contains NAME; exit 2 naming the file that cannot be searched.
list_files_naming() {
  local name=$1 rel file status=0
  while IFS= read -r -d '' rel; do
    file=$ROOT_PREFIX$rel
    if [[ -f "$file" && ! -L "$file" ]]; then
      printf '%s\0' "$file" || die "cannot write the list of workflow files to search"
    fi
  done <"$LIST_FILE" >"$CANDIDATE_FILE" || die "cannot write the list of workflow files to search"
  # The search below reads a failed redirect as "no file names the spec", so both files are opened here first.
  : >"$MATCH_FILE" || die "cannot write the list of workflow files that name the spec"
  : >"$SEARCH_ERRORS" || die "cannot write the search error log"
  # One grep over all the files, not one per file: a sweep searches every workflow file once per spec, and starting a
  #   process per file made it slow. /dev/null keeps grep off stdin when the list is empty.
  xargs -0 grep -lIF --null -- "$name" /dev/null <"$CANDIDATE_FILE" >"$MATCH_FILE" 2>"$SEARCH_ERRORS" || status=$?
  # xargs reports a batch with no match (grep status 1) as 1 or 123, the same as a grep error, so a grep error is told
  #   apart by what it wrote to stderr.
  case $status in
    0 | 1 | 123) [[ -s "$SEARCH_ERRORS" ]] || return 0 ;;
  esac
  while IFS= read -r -d '' file; do
    status=0
    grep -qIF -- "$name" "$file" || status=$?
    [[ $status -le 1 ]] || die "cannot search ${file#"$ROOT_PREFIX"} for the spec path"
  done <"$CANDIDATE_FILE"
  die "cannot search the workflow files for the spec path: $(head -n 1 "$SEARCH_ERRORS")"
}

# move_spec SPEC_DIR : move SPEC_DIR into the Done folder, drop its step marker, fix its outbound links, rewrite its path in
#   the workflow files, and queue the changed paths in PATHSPECS for the commit. Generated caches, initiative records and
#   local working state are skipped: caches are rebuilt from the tree, an initiative re-points its own spec paths when it
#   closes, and local state such as other checkouts is not this branch's to change.
move_spec() {
  local spec_dir=$1 name target old_abs new_abs done_abs move_index step_copy file rel slashes tracked
  name=${spec_dir##*/}
  target=$WF_SPECS_DONE/$name
  old_abs=$(wf_path "$ROOT" "$spec_dir")
  new_abs=$(wf_path "$ROOT" "$target")
  done_abs=$(wf_path "$ROOT" "$WF_SPECS_DONE")
  if [[ ! -d "$done_abs" ]]; then
    mkdir -p "$done_abs" || die "cannot create $WF_SPECS_DONE"
    CREATED_DONE_FOLDER=$done_abs
  fi
  UNCOMMITTED=1
  # Plain mv, not git mv: git mv refuses an untracked spec folder.
  mv "$old_abs" "$new_abs" || die "cannot move $spec_dir to $target"
  move_index=${#MOVED_TO[@]}
  MOVED_FROM+=("$old_abs")
  MOVED_TO+=("$new_abs")
  STEP_COPY+=("")
  # The step marker is set aside rather than deleted, so a rollback can put it back.
  if [[ -e "$new_abs/.step" ]]; then
    step_copy=$SCRATCH_DIR/step.$move_index
    mv "$new_abs/.step" "$step_copy" || die "cannot set aside $target/.step"
    STEP_COPY[move_index]=$step_copy
  fi
  find "$new_abs" -type f -name '*.md' -print0 >"$LIST_FILE" || die "cannot list the Markdown files in $target"
  while IFS= read -r -d '' file; do
    rel=${file#"$new_abs"/}
    slashes=${rel//[!\/]/}
    add_up_level_to_outbound_links "$file" "${#slashes}"
  done <"$LIST_FILE"
  git -C "$ROOT" ls-files -c -o --exclude-standard -z -- "$WF_DIR" ":(exclude)$WF_CACHE" \
    ":(exclude)$WF_INITIATIVES" ":(exclude)$WF_WORKTREES" ":(exclude)$WF_HANDOFF" ":(exclude)$WF_CACHE_STAGING" \
    ":(exclude)$WF_STANDARDS_STAGING" >"$LIST_FILE" || die "cannot list the workflow files to rewrite"
  list_files_naming "$name"
  while IFS= read -r -d '' file; do
    if point_at_done_folder "$file" "$name"; then PATHSPECS+=("${file#"$ROOT_PREFIX"}"); fi
  done <"$MATCH_FILE"
  # An untracked spec leaves nothing at its old path for git, and git add fails on a path that matches nothing.
  tracked=$(git -C "$ROOT" ls-files -c -- "$spec_dir") || die "cannot list the tracked files of $spec_dir"
  if [[ -n "$tracked" ]]; then PATHSPECS+=("$spec_dir"); fi
  PATHSPECS+=("$target")
  MOVED+=("$name")
  echo "moved $spec_dir -> $target"
}

# commit_moves SUBJECT : stage the queued paths and commit only them on the checked-out branch.
commit_moves() {
  local file git_dir head staged=()
  git_dir=$(git -C "$ROOT" rev-parse --absolute-git-dir) || die "cannot find the git folder of $ROOT"
  if [[ -f "$git_dir/index" ]]; then
    cp "$git_dir/index" "$SCRATCH_DIR/index" || die "cannot keep a copy of the index"
    INDEX_COPY=$SCRATCH_DIR/index
  fi
  INDEX_FILE=$git_dir/index
  git -C "$ROOT" --literal-pathspecs add -A -- "${PATHSPECS[@]}" || die "git add failed for the moved spec"
  # With rename detection the list names only the new path, so the commit would leave the old path's deletion staged.
  git -C "$ROOT" --literal-pathspecs diff --cached --name-only -z --no-renames -- "${PATHSPECS[@]}" >"$LIST_FILE" ||
    die "cannot list the staged changes"
  while IFS= read -r -d '' file; do staged+=("$file"); done <"$LIST_FILE"
  [[ ${#staged[@]} -gt 0 ]] || die "nothing staged after the move"
  git -C "$ROOT" --literal-pathspecs commit -q -m "$1" -m "Moved into the Done folder: ${MOVED[*]}" -- "${staged[@]}" ||
    die "git commit failed"
  UNCOMMITTED=0
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
  move_spec "$SPEC_DIR"
  commit_moves "chore(workflow): move ${SPEC_DIR##*/} into the Done folder"
  exit 0
fi

refuse_unsafe_checkout
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
commit_moves "chore(workflow): sweep finished specs into the Done folder"
[[ $LEFT -eq 0 ]] || die "some done specs failed the check and stayed in place; the others moved" 1
