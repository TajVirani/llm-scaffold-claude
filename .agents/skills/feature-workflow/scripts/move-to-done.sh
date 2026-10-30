#!/usr/bin/env bash
# File: Helper script (not a hook): check that a finished spec and its sub-items are closed, and move it into the Done folder.
# Purpose: A spec that has shipped leaves the top level of the specs folder, so the top level lists only work in flight.
#   --check reads the spec's task records and the work-backlog items it raised and lists every one still open; it changes
#   nothing. The move runs the same check, then moves a `done` spec into the Done folder (WF_SPECS_DONE), deletes its step
#   marker and rewrites the spec's path in the workflow files that name it, so every link still resolves, and commits the
#   result on the checked-out branch. --sweep moves every `done` spec at the top level in one commit.
# Usage:
#   move-to-done.sh --check <spec-dir> [--cwd <dir>]   check only: every task record and work-backlog item is closed
#   move-to-done.sh <spec-dir> [--cwd <dir>]           check, then move the done spec into the Done folder, rewrite, commit
#   move-to-done.sh --sweep [--cwd <dir>]              move every done spec at the top level of the specs folder
#     <spec-dir>  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it); --check also
#                 takes a spec already in the Done folder.
#     --cwd       any directory in the project or one of its worktrees (default $PWD); git runs in the MAIN checkout.
# Closed means: a task record is `done` or `split-out`; a work-backlog item `<NNN-slug>-disc-*.md` is `open`, `promoted`,
#   `moved-to-deferred` or `dismissed`. The spec's own status does not matter to --check.
# stdout: one `open: ...` line per open task record or item; `check passed: <spec-dir>`; for a move, `moved <old> -> <new>`
#   per spec and `committed <sha>`; for a sweep, `left in place: <spec-dir>` per spec that failed, or `nothing to sweep`.
# Exit: 0 check passed, or moved and committed, or nothing to sweep; 1 refused: an open sub-item, a spec that is not `done`,
#   a Done folder entry of the same name, the main branch or a detached HEAD checked out, a merge in progress; nothing
#   changed. For --sweep, 1 also means at least one done spec failed and stayed in place while the others moved and were
#   committed. 2 usage or environment error (bad arguments, not a git repository, a folder that is not a spec, spec.md
#   missing, yq missing, a git or file operation failing).
# Called by: modules/sign-off.md (5.7 --check, 5.8 the move and the one-off --sweep).
# Notes: Requires git and mikefarah yq v4. Never pushes. bash 3.2 compatible.
# Sources: first-party. Pattern: commit-workflow-data.sh (main-checkout resolution, explicit staging, path-limited commit).

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
  local spec_dir=$1 tasks item status
  tasks=$(wf_path "$ROOT" "$spec_dir/tasks.md")
  if [[ -f "$tasks" ]]; then
    yq --front-matter=extract \
      '(.tasks // [])[] | select(.status != "done" and .status != "split-out") | "open: task " + .id + " (" + (.status // "no status") + ")"' \
      "$tasks" || die "cannot read the task records in $spec_dir/tasks.md"
  fi
  for item in "$(wf_path "$ROOT" "$WF_WORK_BACKLOG")/${spec_dir##*/}"-disc-*.md; do
    [[ -f "$item" ]] || continue
    status=$(yq --front-matter=extract '.status // ""' "$item") || die "cannot read the status of $WF_WORK_BACKLOG/${item##*/}"
    case $status in
      open | promoted | moved-to-deferred | dismissed) ;;
      *) printf 'open: backlog item %s (%s)\n' "$WF_WORK_BACKLOG/${item##*/}" "${status:-no status}" ;;
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
ROOT=$(wf_main_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"

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
TMP_FILE=$(mktemp) || die "cannot create a temporary file"
trap 'rm -f "$TMP_FILE"' EXIT

# refuse_unsafe_checkout : exit 1 when the checked-out branch must not take the move commit or git is mid-operation.
refuse_unsafe_checkout() {
  local current main h
  current=$(git -C "$ROOT" branch --show-current)
  [[ -n "$current" ]] || die "the main checkout has a detached HEAD; check out the spec branch first" 1
  main=$(bash "$SCRIPT_DIR/rules-setting.sh" main_branch --cwd "$ROOT" 2>/dev/null) ||
    die "cannot read the main branch name (rules-setting.sh main_branch)"
  [[ "$current" != "$main" ]] || die "the main checkout is on the main branch $main; the move commits on the spec branch" 1
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
  [[ "$status" == "done" ]] || echo "status is ${status:-empty}, not done"
  open_sub_items "$spec_dir"
  [[ ! -e "$(wf_path "$ROOT" "$WF_SPECS_DONE/${spec_dir##*/}")" ]] || echo "$WF_SPECS_DONE/${spec_dir##*/} already exists"
}

# replace_file FILE : copy TMP_FILE over FILE when they differ, keeping FILE's mode; true when FILE changed.
replace_file() {
  cmp -s "$TMP_FILE" "$1" && return 1
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
  local file=$1 name=$2 name_re rel_dir depth climb="" climb_re="" end
  name_re=${name//./\\.}
  # A path that ends a sentence keeps its full stop, but `NAME.md` is another file and stays as it is.
  end="(\\.?[^$SLUG_CHARS]|\\.?\$)"
  local exprs
  exprs=(-e ':again' -e "s#(^|[^$SLUG_CHARS])$SPECS_LEAF/$name_re$end#\\1$SPECS_LEAF/$DONE_LEAF/$name\\2#g")
  rel_dir=${file#"$ROOT"/}
  rel_dir=${rel_dir%/*}
  if [[ "$rel_dir" == "$WF_SPECS"/* ]]; then
    rel_dir=${rel_dir#"$WF_SPECS"/}
    depth=$(($(printf '%s' "$rel_dir" | tr -cd / | wc -c) + 1))
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

# move_spec SPEC_DIR : move SPEC_DIR into the Done folder, drop its step marker, fix its outbound links, rewrite its path in
#   every workflow file outside cache/ and initiatives/, and queue the changed paths in PATHSPECS for the commit.
move_spec() {
  local spec_dir=$1 name target old_abs new_abs file rel
  name=${spec_dir##*/}
  target=$WF_SPECS_DONE/$name
  old_abs=$(wf_path "$ROOT" "$spec_dir")
  new_abs=$(wf_path "$ROOT" "$target")
  mkdir -p "$(wf_path "$ROOT" "$WF_SPECS_DONE")" || die "cannot create $WF_SPECS_DONE"
  # Plain mv, not git mv: git mv refuses an untracked spec folder.
  mv "$old_abs" "$new_abs" || die "cannot move $spec_dir to $target"
  rm -f "$new_abs/.step" || die "cannot delete $target/.step"
  while IFS= read -r file; do
    rel=${file#"$new_abs"/}
    add_up_level_to_outbound_links "$file" "$(printf '%s' "$rel" | tr -cd / | wc -c)"
  done < <(find "$new_abs" -type f -name '*.md')
  while IFS= read -r -d '' rel; do
    file=$(wf_path "$ROOT" "$rel")
    [[ -f "$file" && ! -L "$file" ]] || continue
    grep -qIF -- "$name" "$file" || continue
    if point_at_done_folder "$file" "$name"; then PATHSPECS+=("$rel"); fi
  done < <(git -C "$ROOT" ls-files -c -o --exclude-standard -z -- "$WF_DIR" ":(exclude)$WF_CACHE" \
    ":(exclude)$WF_INITIATIVES" ":(exclude)$WF_WORKTREES" ":(exclude)$WF_HANDOFF" ":(exclude)$WF_CACHE_STAGING" \
    ":(exclude)$WF_STANDARDS_STAGING")
  if [[ -n "$(git -C "$ROOT" ls-files -c -- "$spec_dir" | head -1)" ]]; then PATHSPECS+=("$spec_dir"); fi
  PATHSPECS+=("$target")
  MOVED+=("$name")
  echo "moved $spec_dir -> $target"
}

# commit_moves SUBJECT : stage the queued paths and commit only them on the checked-out branch.
commit_moves() {
  local file staged=()
  git -C "$ROOT" --literal-pathspecs add -A -- "${PATHSPECS[@]}" || die "git add failed for the moved spec"
  while IFS= read -r -d '' file; do staged+=("$file"); done \
    < <(git -C "$ROOT" --literal-pathspecs diff --cached --name-only -z --no-renames -- "${PATHSPECS[@]}")
  [[ ${#staged[@]} -gt 0 ]] || die "nothing staged after the move"
  git -C "$ROOT" --literal-pathspecs commit -q -m "$1" -m "Moved into the Done folder: ${MOVED[*]}" -- "${staged[@]}" ||
    die "git commit failed"
  echo "committed $(git -C "$ROOT" rev-parse HEAD)"
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
