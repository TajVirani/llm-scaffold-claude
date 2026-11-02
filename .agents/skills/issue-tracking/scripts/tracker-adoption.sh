#!/usr/bin/env bash
# File: Helper script (not a hook): Tracker adoption, moving a project already under way onto tracker numbering.
# Purpose: Files a tracker issue for each active spec (issue-tracker.sh create-spec, then fill) and renames the spec after
#   the issue number, padded to five digits: its folder, its backlog list, its spec branch, its spec worktree, spec_branch,
#   the task records' branch fields and every .workflow/ reference; it writes tracker_issue and keeps the step marker. A
#   spec with a live task worktree is refused and left as it was while the others still run. A renamed branch whose old one
#   was pushed is pushed under the new name; the old remote branch and the task PRs are reported, and nothing on the remote
#   is deleted. Each Done spec and its backlog list get the `old_` prefix, so their numbers are never read as issue numbers.
#   The moves and reference rewrites are the shared path rewrite in lib/workflow-paths.sh (wf_rewrite_*), one run per
#   checkout: a spec worktree's run is committed on its spec branch; the main checkout's run (the Done specs, the specs whose
#   folder is there, and the references to every renamed spec) is left uncommitted, because the main branch takes no direct
#   commits. An error during a run rolls that run back.
# Usage:
#   tracker-adoption.sh [--cwd <dir>]
#     --cwd    any directory in the project's main checkout or one of its worktrees. Default: $PWD.
#   Active specs are the spec folders at the top level of the specs folder in the main checkout and those in the spec
#   worktrees under .workflow/.spec-worktrees/<name>. A spec whose tracker_issue is set keeps that issue, so a second run
#   files nothing twice; one already named after its issue is reported as already adopted.
# stdout: `adopted <old folder> -> <new folder>: <issue url>` per active spec; for a spec worktree also `committed <sha> on
#   <branch>`, `renamed branch <old> -> <new>`, `moved spec worktree <old> -> <new>`, and when the old branch was pushed
#   `pushed <new branch> to <remote>`, `left on <remote>: <old branch> (nothing on the remote is deleted)` and
#   `task PR on the old branch: <url>` per task PR; `renamed <old> -> <new>` per Done spec; `already adopted: <folder>`;
#   `not committed: ...` when the main checkout holds renames.
# Exit: 0 every spec adopted (or already adopted) and every Done spec renamed; 1 one or more specs refused, or a step after
#   an issue was filed (filling it, pushing the renamed branch) left to do by hand, each named on stderr with the reason,
#   while the others still ran; 2 usage or environment error (bad arguments, not a git repository, git or yq missing, no
#   tracker set up or the origin remote on another host, the main branch unreadable, the tracker script refusing its
#   settings, a git or file step failing). An error during a rename rolls back that checkout's run; renames already
#   committed in another spec worktree stay. A spec keeps the tracker_issue it was given, so a later run reuses the issue.
# Called by: the issue-tracking skill.
# Notes: Requires git, mikefarah yq v4, and what issue-tracker.sh requires. bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/workflow-paths.sh
. "$SCRIPT_DIR/../../../lib/workflow-paths.sh"

PROG="tracker-adoption.sh"
ISSUE_TRACKER=$SCRIPT_DIR/issue-tracker.sh
RULES_SETTING=$SCRIPT_DIR/../../feature-workflow/scripts/rules-setting.sh
SPEC_NAME_PATTERN='^[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$'
ISSUE_URL_PATTERN='^https://[^[:space:]]+/([0-9]+)$'
# A branch name match must not run on into a longer name, so it stops at any character a spec name can hold.
NAME_CHARS='A-Za-z0-9._-'

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage line to stderr and exit 2.
usage() { echo "usage: $PROG [--cwd <dir>]" >&2; exit 2; }

# warn MSG : print "<prog>: MSG" to stderr and count it, so the run exits 1 once every other spec has been handled.
warn() {
  printf '%s: %s\n' "$PROG" "$1" >&2
  PROBLEMS=$((PROBLEMS + 1))
}

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
command -v git >/dev/null 2>&1 || die "git not found on PATH"
command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4"
MAIN=$(wf_main_root "$cwd" 2>/dev/null) || die "not inside a git repository: $cwd"

# require_tracker : exit 2 unless the settings name GitHub or GitLab and the origin remote is on that host, so a run that
#   cannot file issues stops before it files the first one.
require_tracker() {
  local settings tracker host
  settings=$(wf_path "$MAIN" "$WF_ISSUE_TRACKING")
  [[ -f $settings ]] || die "no tracker is set up ($WF_ISSUE_TRACKING is missing); run tracker-setup.sh save first"
  tracker=$(yq '.issue_tracker // ""' "$settings") || die "cannot read $WF_ISSUE_TRACKING"
  case $tracker in
    gitlab | github) ;;
    *) die "$WF_ISSUE_TRACKING names the tracker '${tracker}', not gitlab or github; run tracker-setup.sh save first" ;;
  esac
  host=$(wf_origin_host "$MAIN")
  [[ $host == "$tracker" ]] ||
    die "$WF_ISSUE_TRACKING names $tracker, but the origin remote is on ${host:-neither GitHub nor GitLab}"
}

require_tracker
MAIN_BRANCH=$(bash "$RULES_SETTING" main_branch --cwd "$MAIN" 2>/dev/null) ||
  die "cannot read the main branch name (rules-setting.sh main_branch)"
SCRATCH=$(mktemp -d) || die "cannot create a temporary folder"
PROBLEMS=0

# RUN_OPEN is 1 while a rewrite run has changes that an error must undo. The branch-name edits are made before the run
#   starts, outside the shared rewrite, so they are listed here (the file, the name it had, the name it got) to be undone
#   with it.
RUN_OPEN=0
BRANCH_EDIT_FILE=() BRANCH_EDIT_FROM=() BRANCH_EDIT_TO=()

# rewrite_branch_names FILE FROM TO : rewrite the branch names spec/FROM and task/FROM... in FILE to name TO; status 0
#   when FILE changed, 1 when nothing named FROM, 2 with a reason on stderr when FILE could not be rewritten.
rewrite_branch_names() {
  local file=$1 from_re=${2//./\\.} to=$3 rewritten=$SCRATCH/branch-names
  # Repeat until nothing changes: two names one character apart share that character, and one pass rewrites only the first.
  sed -E -e ':again' -e "s%(^|[^$NAME_CHARS])(spec|task)/$from_re(\\.?[^$NAME_CHARS]|\\.?\$)%\\1\\2/$to\\3%g" -e 't again' \
    "$file" >"$rewritten" || {
    printf '%s: cannot rewrite the branch names in %s\n' "$PROG" "$file" >&2
    return 2
  }
  cmp -s "$rewritten" "$file" && return 1
  cat "$rewritten" >"$file" || {
    printf '%s: cannot write %s\n' "$PROG" "$file" >&2
    return 2
  }
  return 0
}

# edit_branch_names ROOT NAME NEW : in the checkout ROOT, rename the branches the spec NAME's folder and backlog list name
#   (spec/NAME, task/NAME/...) to NEW, and list each changed file so an error can undo it.
edit_branch_names() {
  local root=$1 name=$2 new=$3 paths=() path file search_status=0 rewrite_status
  for path in "$(wf_path "$root" "$WF_SPECS/$name")" "$(wf_path "$root" "$WF_WORK_BACKLOG/$name.md")"; do
    [[ ! -e $path ]] || paths+=("$path")
  done
  [[ ${#paths[@]} -gt 0 ]] || return 0
  grep -rlIF --null -e "spec/$name" -e "task/$name" -- "${paths[@]}" >"$SCRATCH/branch-files" || search_status=$?
  [[ $search_status -le 1 ]] || die "cannot search $WF_SPECS/$name in $root for its branch names"
  while IFS= read -r -d '' file; do
    rewrite_status=0
    rewrite_branch_names "$file" "$name" "$new" || rewrite_status=$?
    case $rewrite_status in
      0)
        BRANCH_EDIT_FILE+=("$file")
        BRANCH_EDIT_FROM+=("$name")
        BRANCH_EDIT_TO+=("$new")
        ;;
      1) ;;
      *) die "cannot rename the branches $WF_SPECS/$name names in $root" ;;
    esac
  done <"$SCRATCH/branch-files"
}

# undo_branch_names : give each file edit_branch_names changed its old branch names back; status 1 when some could not be.
undo_branch_names() {
  local i=${#BRANCH_EDIT_FILE[@]} undo_status=0 rewrite_status
  while [[ $i -gt 0 ]]; do
    i=$((i - 1))
    rewrite_status=0
    rewrite_branch_names "${BRANCH_EDIT_FILE[i]}" "${BRANCH_EDIT_TO[i]}" "${BRANCH_EDIT_FROM[i]}" || rewrite_status=$?
    if [[ $rewrite_status -eq 2 ]]; then
      printf '  %s still names %s: rename it back to %s by hand\n' "${BRANCH_EDIT_FILE[i]}" "${BRANCH_EDIT_TO[i]}" \
        "${BRANCH_EDIT_FROM[i]}" >&2
      undo_status=1
    fi
  done
  BRANCH_EDIT_FILE=() BRANCH_EDIT_FROM=() BRANCH_EDIT_TO=()
  return "$undo_status"
}

# on_exit : on an error during a rewrite run, roll the run back and undo its branch-name edits; then remove the temporary
#   folders.
on_exit() {
  local exit_code=$?
  set +e
  if [[ $exit_code -ne 0 && $RUN_OPEN -eq 1 ]]; then
    if { ! wf_rewrite_pending || wf_rewrite_roll_back; } && undo_branch_names; then
      printf '%s: rolled back the renames of the checkout in progress; they were not kept\n' "$PROG" >&2
    else
      printf '%s: rollback incomplete, nothing of it was committed; still changed:\n' "$PROG" >&2
      [[ ${#WF_REWRITE_LEFT[@]} -eq 0 ]] || printf '  %s\n' "${WF_REWRITE_LEFT[@]}" >&2
    fi
    exit_code=2
  fi
  wf_rewrite_end
  rm -rf "$SCRATCH"
  exit "$exit_code"
}
trap on_exit EXIT

# front_matter FILE EXPR : print one frontmatter value of FILE; exit 2 when it cannot be read.
front_matter() { yq --front-matter=extract "$2" "$1" || die "cannot read the frontmatter of $1"; }

# spec_branch_of ROOT NAME : print the spec branch of the spec NAME in the checkout ROOT, spec/NAME when none is recorded.
spec_branch_of() {
  local branch
  branch=$(front_matter "$(wf_path "$1" "$WF_SPECS/$2/spec.md")" '.spec_branch // ""') || exit 2
  printf '%s\n' "${branch:-spec/$2}"
}

# spec_refusal ROOT NAME IN_WORKTREE : print why the spec NAME, whose folder is in the checkout ROOT (IN_WORKTREE 1 for
#   a spec worktree), cannot be adopted now; nothing when it can.
spec_refusal() {
  local root=$1 name=$2 in_worktree=$3 dir branch current checkout_refusal
  # Agent worktree names start s<number>_ with the spec number as the folder name writes it.
  for dir in "$(wf_path "$root" "$WF_WORKTREES")/s${name%%-*}_"* "$(wf_path "$MAIN" "$WF_WORKTREES")/s${name%%-*}_"*; do
    [[ -d $dir ]] || continue
    echo "it has a live task worktree $dir; finish or remove it, then run the adoption again" ||
      die "cannot write why $name is refused"
    return 0
  done
  [[ $in_worktree -eq 1 ]] || return 0
  branch=$(spec_branch_of "$root" "$name") || exit 2
  current=$(git -C "$root" branch --show-current) || die "cannot read the checked-out branch in $root"
  if [[ $current != "$branch" ]]; then
    echo "its spec worktree $root is on ${current:-a detached HEAD}, not $branch" || die "cannot write why $name is refused"
    return 0
  fi
  checkout_refusal=$(wf_rewrite_checkout_refusal "$root" "$MAIN_BRANCH") || die "cannot read the checkout $root"
  [[ -z $checkout_refusal ]] || echo "$checkout_refusal" || die "cannot write why $name is refused"
}

# name_taken ROOT NEW IN_WORKTREE : print what already uses the new spec name NEW (a folder, backlog list, spec worktree
#   or branch); nothing when it is free.
name_taken() {
  local root=$1 new=$2 in_worktree=$3 path
  for path in "$WF_SPECS/$new" "$WF_WORK_BACKLOG/$new.md"; do
    if [[ -e $(wf_path "$root" "$path") || -e $(wf_path "$MAIN" "$path") ]]; then
      echo "$path already exists" || die "cannot write why $new is taken"
      return 0
    fi
  done
  [[ $in_worktree -eq 1 ]] || return 0
  if [[ -e $(wf_path "$MAIN" "$WF_SPEC_WORKTREES/$new") ]]; then
    echo "$WF_SPEC_WORKTREES/$new already exists" || die "cannot write why $new is taken"
  elif git -C "$MAIN" rev-parse -q --verify "refs/heads/spec/$new" >/dev/null; then
    echo "the branch spec/$new already exists" || die "cannot write why $new is taken"
  fi
}

# rename_spec ROOT OLD NEW : in the open rewrite run on the checkout ROOT, move the spec folder OLD to NEW and its backlog
#   list after it, where ROOT holds them, and rewrite every reference to OLD.
rename_spec() {
  local root=$1 old=$2 new=$3 old_list=$WF_WORK_BACKLOG/${2##*/}.md new_list=$WF_WORK_BACKLOG/${3##*/}.md
  if [[ -e $(wf_path "$root" "$old") ]]; then
    wf_rewrite_move "$old" "$new" || die "cannot move $old to $new in $root"
  fi
  if [[ -e $(wf_path "$root" "$old_list") ]]; then
    wf_rewrite_move "$old_list" "$new_list" || die "cannot move $old_list to $new_list in $root"
  fi
  wf_rewrite_spec_path "$old" "$new" || die "cannot rewrite the references to $old in $root"
}

# report_old_remote_branch ROOT NAME REMOTE BRANCH : report the old branch BRANCH left on REMOTE and the task PRs the spec
#   NAME's task records hold.
report_old_remote_branch() {
  local tasks pr
  echo "left on $3: $4 (nothing on the remote is deleted)"
  tasks=$(wf_path "$1" "$WF_SPECS/$2/tasks.md")
  [[ -f $tasks ]] || return 0
  front_matter "$tasks" '(.tasks // [])[] | .pr // "" | select(. != "")' >"$SCRATCH/task-prs" || exit 2
  while IFS= read -r pr; do
    echo "task PR on the old branch: $pr"
  done <"$SCRATCH/task-prs"
}

# adopt_in_spec_worktree NAME NEW URL : rename the spec NAME in its spec worktree to NEW and commit it on the spec branch,
#   then rename the branch and the worktree, and push the branch when the old one was pushed.
adopt_in_spec_worktree() {
  local name=$1 new=$2 url=$3 worktree new_worktree old_branch new_branch=spec/$2 remote pushed=0 head
  worktree=$(wf_path "$MAIN" "$WF_SPEC_WORKTREES/$name")
  new_worktree=$(wf_path "$MAIN" "$WF_SPEC_WORKTREES/$new")
  old_branch=$(spec_branch_of "$worktree" "$name") || exit 2
  remote=$(git -C "$MAIN" config --get --default origin "branch.$old_branch.remote") ||
    die "cannot read the remote of $old_branch"
  if git -C "$MAIN" rev-parse -q --verify "refs/remotes/$remote/$old_branch" >/dev/null; then pushed=1; fi
  RUN_OPEN=1
  edit_branch_names "$worktree" "$name" "$new"
  wf_rewrite_begin "$worktree" || die "cannot start the rename in $worktree"
  rename_spec "$worktree" "$WF_SPECS/$name" "$WF_SPECS/$new"
  wf_rewrite_commit "$MAIN_BRANCH" "chore(workflow): rename $name after its tracker issue" \
    "Tracker adoption: $WF_SPECS/$name is now $WF_SPECS/$new, after its tracker issue $url." ||
    die "cannot commit the rename in $worktree"
  RUN_OPEN=0
  BRANCH_EDIT_FILE=() BRANCH_EDIT_FROM=() BRANCH_EDIT_TO=()
  wf_rewrite_end
  echo "adopted $WF_SPECS/$name -> $WF_SPECS/$new: $url"
  head=$(git -C "$worktree" rev-parse HEAD) || die "committed the rename, but cannot read the new commit id in $worktree"
  echo "committed $head on $old_branch"
  git -C "$MAIN" branch -m "$old_branch" "$new_branch" ||
    die "committed $head, but cannot rename the branch; run git branch -m $old_branch $new_branch, then git worktree move $worktree $new_worktree"
  echo "renamed branch $old_branch -> $new_branch"
  git -C "$MAIN" worktree move "$worktree" "$new_worktree" ||
    die "renamed the branch, but cannot move the spec worktree; run git worktree move $worktree $new_worktree"
  echo "moved spec worktree $worktree -> $new_worktree"
  [[ $pushed -eq 1 ]] || return 0
  # The full refspec and -u keep the push off the old remote branch, which the renamed branch still tracks until then.
  if git -C "$new_worktree" push -q -u "$remote" "refs/heads/$new_branch:refs/heads/$new_branch"; then
    echo "pushed $new_branch to $remote"
  else
    warn "cannot push $new_branch to $remote; push it by hand with git push -u $remote $new_branch"
  fi
  report_old_remote_branch "$new_worktree" "$new" "$remote" "$old_branch"
}

# The active specs: ACTIVE_NAME, ACTIVE_ROOT (the checkout holding the folder) and ACTIVE_IN_WORKTREE (1 for a spec
#   worktree) are parallel. ACTIVE_NEW and ACTIVE_URL are filled for each spec that will be renamed, empty otherwise.
ACTIVE_NAME=() ACTIVE_ROOT=() ACTIVE_IN_WORKTREE=() ACTIVE_NEW=() ACTIVE_URL=()
DONE_NAME=()

# add_active NAME ROOT IN_WORKTREE : list the spec NAME, whose folder is in the checkout ROOT, as active.
add_active() {
  ACTIVE_NAME+=("$1")
  ACTIVE_ROOT+=("$2")
  ACTIVE_IN_WORKTREE+=("$3")
  ACTIVE_NEW+=("")
  ACTIVE_URL+=("")
}

for spec_md in "$(wf_path "$MAIN" "$WF_SPECS")"/*/spec.md; do
  [[ -f $spec_md ]] || continue
  name=$(basename "$(dirname "$spec_md")")
  [[ $name =~ $SPEC_NAME_PATTERN ]] || continue
  # A spec with a spec worktree is adopted there; the main checkout only gets its references rewritten.
  [[ ! -f $(wf_path "$MAIN" "$WF_SPEC_WORKTREES/$name/$WF_SPECS/$name/spec.md") ]] || continue
  add_active "$name" "$MAIN" 0
done
for worktree in "$(wf_path "$MAIN" "$WF_SPEC_WORKTREES")"/*; do
  name=$(basename "$worktree")
  [[ $name =~ $SPEC_NAME_PATTERN && -f $(wf_path "$worktree" "$WF_SPECS/$name/spec.md") ]] || continue
  add_active "$name" "$worktree" 1
done
for done_dir in "$(wf_path "$MAIN" "$WF_SPECS_DONE")"/*; do
  name=$(basename "$done_dir")
  [[ -d $done_dir && $name =~ $SPEC_NAME_PATTERN ]] || continue
  DONE_NAME+=("$name")
done

# File an issue for each active spec that can be adopted, before anything is renamed. Its URL goes into tracker_issue at
#   once, so a run that fails later still knows the issue and a second run files nothing twice.
i=0
while [[ $i -lt ${#ACTIVE_NAME[@]} ]]; do
  name=${ACTIVE_NAME[i]} root=${ACTIVE_ROOT[i]} in_worktree=${ACTIVE_IN_WORKTREE[i]}
  i=$((i + 1))
  refusal=$(spec_refusal "$root" "$name" "$in_worktree") || exit 2
  if [[ -n $refusal ]]; then
    warn "refused $WF_SPECS/$name: $refusal"
    continue
  fi
  spec_md=$(wf_path "$root" "$WF_SPECS/$name/spec.md")
  url=$(front_matter "$spec_md" '.tracker_issue // ""') || exit 2
  filed=0
  if [[ -z $url ]]; then
    tracker_status=0
    url=$(bash "$ISSUE_TRACKER" --cwd "$MAIN" create-spec) || tracker_status=$?
    case $tracker_status in
      0) ;;
      2) die "issue-tracker.sh create-spec refused its arguments or the settings" ;;
      *)
        warn "refused $WF_SPECS/$name: the tracker could not file its issue (issue-tracker.sh exit $tracker_status)"
        continue
        ;;
    esac
    filed=1
  fi
  [[ $url =~ $ISSUE_URL_PATTERN ]] || die "the issue URL of $WF_SPECS/$name does not end in its number: $url"
  new=$(printf '%05d' "$((10#${BASH_REMATCH[1]}))")-${name#*-}
  if [[ $filed -eq 1 ]]; then
    URL=$url yq --front-matter=process -i '.tracker_issue = strenv(URL)' "$spec_md" ||
      die "filed $url, but cannot write it to tracker_issue in $spec_md; write it there by hand"
    bash "$ISSUE_TRACKER" --cwd "$MAIN" fill "$url" "$spec_md" ||
      warn "filed $url for $WF_SPECS/$name, but cannot fill it; run issue-tracker.sh fill $url <its spec.md> by hand"
  fi
  if [[ $new == "$name" ]]; then
    echo "already adopted: $WF_SPECS/$name"
    continue
  fi
  taken=$(name_taken "$root" "$new" "$in_worktree") || exit 2
  if [[ -n $taken ]]; then
    warn "refused $WF_SPECS/$name: its new name $new is taken: $taken; its issue is $url"
    continue
  fi
  ACTIVE_NEW[i - 1]=$new
  ACTIVE_URL[i - 1]=$url
done

# Each spec worktree takes its rename as a commit on its spec branch, so it runs before the main checkout's run, which is
#   left uncommitted and so must be the last.
i=0
while [[ $i -lt ${#ACTIVE_NAME[@]} ]]; do
  if [[ ${ACTIVE_IN_WORKTREE[i]} -eq 1 && -n ${ACTIVE_NEW[i]} ]]; then
    adopt_in_spec_worktree "${ACTIVE_NAME[i]}" "${ACTIVE_NEW[i]}" "${ACTIVE_URL[i]}"
  fi
  i=$((i + 1))
done

# The main checkout: the Done specs first, then the active specs whose folder is here, then the references to the specs
#   renamed in their spec worktrees.
RUN_OPEN=1
i=0
while [[ $i -lt ${#ACTIVE_NAME[@]} ]]; do
  [[ -z ${ACTIVE_NEW[i]} ]] || edit_branch_names "$MAIN" "${ACTIVE_NAME[i]}" "${ACTIVE_NEW[i]}"
  i=$((i + 1))
done
wf_rewrite_begin "$MAIN" || die "cannot start the renames in the main checkout $MAIN"
# bash 3.2 reads an empty array as unset under set -u, so the loop expands it only when it has entries.
for name in ${DONE_NAME[@]+"${DONE_NAME[@]}"}; do
  target=$WF_SPECS_DONE/old_$name
  taken=""
  for path in "$target" "$WF_WORK_BACKLOG/old_$name.md"; do
    [[ ! -e $(wf_path "$MAIN" "$path") ]] || taken=$path
  done
  if [[ -n $taken ]]; then
    warn "refused $WF_SPECS_DONE/$name: $taken already exists"
    continue
  fi
  rename_spec "$MAIN" "$WF_SPECS_DONE/$name" "$target"
  echo "renamed $WF_SPECS_DONE/$name -> $target"
done
i=0
while [[ $i -lt ${#ACTIVE_NAME[@]} ]]; do
  if [[ -n ${ACTIVE_NEW[i]} ]]; then
    rename_spec "$MAIN" "$WF_SPECS/${ACTIVE_NAME[i]}" "$WF_SPECS/${ACTIVE_NEW[i]}"
    [[ ${ACTIVE_IN_WORKTREE[i]} -eq 1 ]] ||
      echo "adopted $WF_SPECS/${ACTIVE_NAME[i]} -> $WF_SPECS/${ACTIVE_NEW[i]}: ${ACTIVE_URL[i]}"
  fi
  i=$((i + 1))
done
MAIN_CHANGED=0
if wf_rewrite_pending || [[ ${#BRANCH_EDIT_FILE[@]} -gt 0 ]]; then MAIN_CHANGED=1; fi
RUN_OPEN=0
wf_rewrite_end
if [[ $MAIN_CHANGED -eq 1 ]]; then
  echo "not committed: the renames in the main checkout $MAIN are left in its working tree, because $MAIN_BRANCH takes no direct commits; commit them on a branch and merge it"
fi

if [[ $PROBLEMS -gt 0 ]]; then
  printf '%s: %s spec(s) refused or left with a step to finish by hand; the others were adopted\n' "$PROG" "$PROBLEMS" >&2
  exit 1
fi
