#!/usr/bin/env bash
# File: Helper script (not a hook): create, set up, check and remove the worktrees a spec runs in.
# Purpose: One script makes every spec worktree, agent worktree and scratch worktree ready to build and test: it gives the spec a
#   slot, copies the project's gitignored files named in .worktreeinclude from the main checkout, runs the project's worktree_setup
#   command with the isolation values, and refuses a symlink that reaches back into the main checkout or another worktree.
# Usage:
#   worktree-setup.sh agent <name> <branch> [--cwd <dir>]
#     Adds the agent worktree <name> under the spec checkout's agent worktree folder (.workflow/.worktrees) on <branch>, a new
#     branch off the spec checkout's branch (or <branch> as it is when it already exists), or reuses the worktree when it is
#     already there on <branch>; then sets it up. --cwd is any folder in the spec checkout (default $PWD).
#   worktree-setup.sh scratch <name> [<commit>] [--cwd <dir>]
#     Adds a detached worktree <name> beside the agent worktrees at <commit> (default the spec checkout's HEAD), or reuses it when
#     it is already detached there; then sets it up with the spec's slot.
#   worktree-setup.sh setup <worktree path>
#     Sets up a worktree that exists. A spec worktree takes the lowest slot no other spec worktree of the repository holds and
#     keeps it in .workflow/.slot; an agent or scratch worktree reads its spec worktree's. Copies each file matching a pattern in
#     the main checkout's .worktreeinclude that git ignores there, as a regular file (a symlink arrives as the file it points to);
#     a file the worktree already has is kept. Runs the spec checkout's worktree_setup (rules-setting.sh) with `bash -c` in the
#     worktree, the five isolation values exported, then the link check. Safe to run again.
#   worktree-setup.sh check <worktree path>
#     The link check alone: every symlink in the worktree, tracked or not, dependency folders included (worktrees nested inside it
#     are skipped), must not resolve into the main checkout or another worktree of the repository outside this one. A link to a
#     path outside the repository passes.
#   worktree-setup.sh env <worktree path>
#     Prints the isolation values. A spec worktree with no slot yet takes one, as setup does.
#   worktree-setup.sh remove <name> [--force] [--cwd <dir>]
#     Removes the agent or scratch worktree <name> of the spec checkout; its branch stays. --force (discard its changes) only for a
#     scratch worktree.
#   A relative <worktree path> is read from --cwd.
# stdout: agent and scratch print `worktree <absolute path>`; env prints `export WF_SLOT=<slot>`, `export WF_INSTANCE=s<NNN>`,
#   `export WF_PORT_OFFSET=<slot x 100>`, `export WF_MAIN_ROOT=<main checkout>` and `export WF_SPEC_ROOT=<spec worktree>`, one per
#   line, each value shell-quoted (0, main, 0 and the main checkout twice for the main checkout or a worktree of a spec running
#   there); remove prints `removed worktree <path>`; setup and check print nothing. Progress, each bad link and the output of
#   worktree_setup go to stderr.
# Exit: 0 done; 1 refused or a check failed, with the reason: a bad link, a failing worktree_setup (its output above), a file that
#   cannot be copied, setup of the main checkout itself, a worktree path taken by something else or on another branch, remove of a
#   worktree that is not there, or --force for an agent worktree; 2 usage or environment error (bad arguments, not a git
#   repository, a folder that is neither the main checkout nor a spec worktree nor inside one, a git step failing).
# Called by: scripts/spec-worktree.sh (create, remove), scripts/run-toolchain.sh, the step files that create agent and scratch
#   worktrees.
# Notes: Requires git and mikefarah yq v4 (through rules-setting.sh). Everything setup writes must be gitignored, or the worktree
#   could not be removed cleanly. Two spec worktrees set up at the same instant may take the same slot. bash 3.2 compatible.
# Sources: first-party. Pattern: spec-worktree.sh (die, usage, argument parser, root resolution).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROG="worktree-setup.sh"
USAGE="usage: worktree-setup.sh agent <name> <branch> | scratch <name> [<commit>] | setup|check|env <worktree path> | remove <name> [--force]  [--cwd <dir>]"
# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a refusal).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }
# usage : print the usage line to stderr and exit 2.
usage() { echo "$USAGE" >&2; exit 2; }

SCRATCH=""
trap 'if [[ -n "$SCRATCH" ]]; then rm -rf "$SCRATCH"; fi' EXIT

# registered_worktrees : print the path of every worktree of this repository, the main checkout first.
registered_worktrees() {
  git -C "$MAIN_ROOT" worktree list --porcelain | sed -n 's/^worktree //p'
}

# registered_worktree PATH : true when PATH is a worktree git knows, in any checkout of this repository.
registered_worktree() {
  git -C "$MAIN_ROOT" worktree list --porcelain | grep -qxF "worktree $1"
}

# resolve_roots WORKTREE : set MAIN_ROOT, SPEC_ROOT and INSTANCE for WORKTREE; SPEC_ROOT is the main checkout and INSTANCE
#   `main` when the spec runs there.
resolve_roots() {
  local worktree=$1 owner spec_number
  MAIN_ROOT=$(wf_main_root "$worktree" 2>/dev/null) || die "not inside a git repository: $worktree"
  owner=$(wf_project_root "$worktree" 2>/dev/null) || die "not inside a git repository: $worktree"
  if [[ "$owner" == "$MAIN_ROOT" ]]; then
    SPEC_ROOT=$MAIN_ROOT INSTANCE=main
  elif [[ "$(dirname "$owner")" == "$MAIN_ROOT/$WF_SPEC_WORKTREES" ]]; then
    SPEC_ROOT=$owner
    spec_number=${owner##*/}
    spec_number=${spec_number%%-*}
    [[ "$spec_number" =~ ^[0-9]+$ ]] || die "the spec worktree $owner is not named NNN-slug"
    INSTANCE=s$spec_number
  else
    die "$worktree is neither the main checkout nor a spec worktree nor a worktree inside one"
  fi
}

# read_or_take_slot : set SLOT to the spec's slot: 0 in the main checkout, else the number in the spec worktree's slot file,
#   writing the lowest number no other spec worktree holds when the file has none.
read_or_take_slot() {
  local slot_file worktrees held="" path candidate=1
  if [[ "$SPEC_ROOT" == "$MAIN_ROOT" ]]; then
    SLOT=0
    return 0
  fi
  slot_file=$(wf_path "$SPEC_ROOT" "$WF_SLOT_FILE")
  if [[ -f "$slot_file" ]]; then
    SLOT=$(head -n 1 "$slot_file") || die "cannot read $slot_file"
    if [[ "$SLOT" =~ ^[1-9][0-9]*$ ]]; then return 0; fi
    printf '%s: %s holds no slot number; taking a new slot\n' "$PROG" "$slot_file" >&2
  fi
  worktrees=$(registered_worktrees) || die "cannot list the worktrees of $MAIN_ROOT"
  while IFS= read -r path; do
    if [[ "$path" != "$SPEC_ROOT" && "$(dirname "$path")" == "$MAIN_ROOT/$WF_SPEC_WORKTREES" && -f "$path/$WF_SLOT_FILE" ]]; then
      held="$held $(head -n 1 "$path/$WF_SLOT_FILE")" || die "cannot read $path/$WF_SLOT_FILE"
    fi
  done <<<"$worktrees"
  while [[ " $held " == *" $candidate "* ]]; do candidate=$((candidate + 1)); done
  mkdir -p "$(dirname "$slot_file")" || die "cannot create $(dirname "$slot_file")"
  printf '%s\n' "$candidate" >"$slot_file" || die "cannot write $slot_file"
  SLOT=$candidate
}

# print_isolation_values : print the five export lines for the roots and slot already resolved.
print_isolation_values() {
  printf 'export WF_SLOT=%q\nexport WF_INSTANCE=%q\nexport WF_PORT_OFFSET=%q\nexport WF_MAIN_ROOT=%q\nexport WF_SPEC_ROOT=%q\n' \
    "$SLOT" "$INSTANCE" "$((SLOT * 100))" "$MAIN_ROOT" "$SPEC_ROOT"
}

# copy_listed_files WORKTREE : copy into WORKTREE each file of the main checkout that the copy list names and git ignores there.
copy_listed_files() {
  local worktree=$1 copy_list rel source target ignore_status=0
  copy_list=$(wf_path "$MAIN_ROOT" "$WF_COPY_LIST")
  [[ -s "$copy_list" ]] || return 0
  # Untracked files only, so a tracked match is never copied over the worktree's own committed version.
  git -C "$MAIN_ROOT" ls-files -z -o -i --exclude-from="$copy_list" >"$SCRATCH/listed" ||
    die "cannot list the files $copy_list names in $MAIN_ROOT"
  # A match git does not ignore would show as untracked in the worktree, and remove refuses a worktree with untracked files.
  git -C "$MAIN_ROOT" check-ignore -z --stdin <"$SCRATCH/listed" >"$SCRATCH/ignored" || ignore_status=$?
  [[ $ignore_status -le 1 ]] || die "cannot ask git which listed files it ignores in $MAIN_ROOT"
  while IFS= read -r -d '' rel; do
    source=$MAIN_ROOT/$rel target=$worktree/$rel
    # A file already there is kept, so a resumed setup never overwrites the worktree's own edits or writes through a link.
    if [[ -e "$target" || -L "$target" ]]; then continue; fi
    mkdir -p "$(dirname "$target")" || die "cannot create $(dirname "$target")"
    if [[ -d "$source" ]]; then
      cp -RL "$source" "$target" || die "cannot copy $source into $worktree" 1
    else
      cp -L "$source" "$target" || die "cannot copy $source into $worktree" 1
    fi
    printf '%s: copied %s\n' "$PROG" "$rel" >&2
  done <"$SCRATCH/ignored"
}

# run_worktree_setup WORKTREE : run the spec checkout's worktree_setup command in WORKTREE with the isolation values; exit 1
#   when it fails.
run_worktree_setup() {
  local worktree=$1 setup_command setup_status=0
  setup_command=$(bash "$SCRIPT_DIR/rules-setting.sh" worktree_setup --cwd "$SPEC_ROOT" 2>/dev/null) ||
    die "cannot read worktree_setup (rules-setting.sh worktree_setup failed)"
  [[ -n "$setup_command" ]] || return 0
  printf '%s: running worktree_setup in %s\n' "$PROG" "$worktree" >&2
  # Its stdout is held back and shown only when it fails: callers such as spec-worktree.sh create pass this script's stderr on
  #   to their own, and a chatty setup command would bury the lines they print.
  (
    cd "$worktree" || exit 2
    eval "$(print_isolation_values)" || exit 2
    exec bash -c "$setup_command"
  ) >"$SCRATCH/setup-stdout" || setup_status=$?
  if [[ $setup_status -ne 0 ]]; then
    cat "$SCRATCH/setup-stdout" >&2
    die "worktree_setup failed with exit $setup_status in $worktree: $setup_command" 1
  fi
}

# physical_target LINK : print the physical path LINK resolves to, following every hop; a dangling link gives its last target.
physical_target() {
  local path=$1 next hops=0 folder
  while [[ -L "$path" && $hops -lt 40 ]]; do
    next=$(readlink "$path") || break
    if [[ "$next" != /* ]]; then next=$(dirname "$path")/$next; fi
    path=$next
    hops=$((hops + 1))
  done
  if [[ -d "$path" ]]; then
    (cd -P "$path" 2>/dev/null && pwd) && return 0
  fi
  if folder=$(cd -P "$(dirname "$path")" 2>/dev/null && pwd); then
    printf '%s/%s\n' "$folder" "$(basename "$path")"
  else
    printf '%s\n' "$path"
  fi
}

# owning_worktree PATH WORKTREES : print the deepest worktree in the newline-separated WORKTREES that holds PATH, nothing when
#   none does.
owning_worktree() {
  local target=$1 path owner=""
  while IFS= read -r path; do
    if [[ -n "$path" && ("$target" == "$path" || "$target" == "$path"/*) && ${#path} -gt ${#owner} ]]; then owner=$path; fi
  done <<<"$2"
  printf '%s\n' "$owner"
}

# check_links WORKTREE : exit 1, naming each one on stderr, when a symlink in WORKTREE resolves into another checkout of this
#   repository.
check_links() {
  local worktree=$1 worktrees path link target owner bad=0 prune=()
  worktrees=$(registered_worktrees) || die "cannot list the worktrees of $MAIN_ROOT"
  # A worktree nested inside this one is checked on its own, against itself.
  prune=(-path "$worktree/.git")
  while IFS= read -r path; do
    if [[ "$path" == "$worktree"/* ]]; then prune+=(-o -path "$path"); fi
  done <<<"$worktrees"
  find "$worktree" \( "${prune[@]}" \) -prune -o -type l -print0 >"$SCRATCH/links" || die "cannot list the symlinks in $worktree"
  while IFS= read -r -d '' link; do
    target=$(physical_target "$link")
    owner=$(owning_worktree "$target" "$worktrees")
    if [[ -z "$owner" || "$owner" == "$worktree" ]]; then continue; fi
    printf '%s: %s links to %s, inside %s\n' "$PROG" "${link#"$worktree"/}" "$target" "$owner" >&2
    bad=$((bad + 1))
  done <"$SCRATCH/links"
  [[ $bad -eq 0 ]] ||
    die "$bad symlink(s) in $worktree reach into another checkout of this repository; replace each with a copy or a link inside the worktree" 1
}

# set_up WORKTREE : the setup call in the header.
set_up() {
  local worktree=$1
  resolve_roots "$worktree"
  [[ "$worktree" != "$MAIN_ROOT" ]] || die "$worktree is the main checkout; setup takes a spec, agent or scratch worktree" 1
  read_or_take_slot
  copy_listed_files "$worktree"
  run_worktree_setup "$worktree"
  check_links "$worktree"
}

# resolve_spec_checkout : set MAIN_ROOT and CHECKOUT, the spec checkout --cwd is in, for the calls that take a worktree name.
resolve_spec_checkout() {
  CHECKOUT=$(wf_project_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
  MAIN_ROOT=$(wf_main_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
}

# named_worktree NAME : print the path of the agent or scratch worktree NAME of the spec checkout; exit 2 for a bad name.
named_worktree() {
  [[ -n "$1" && "$1" != */* && "$1" != .* && "$1" != -* ]] || die "a worktree name is one folder name: $1"
  printf '%s/%s\n' "$(wf_path "$CHECKOUT" "$WF_WORKTREES")" "$1"
}

# add_agent NAME BRANCH : the agent call in the header.
add_agent() {
  local name=$1 branch=$2 worktree spec_branch out
  resolve_spec_checkout
  worktree=$(named_worktree "$name")
  git check-ref-format --branch "$branch" >/dev/null 2>&1 || die "not a valid branch name: $branch"
  if [[ -d "$worktree" ]]; then
    registered_worktree "$worktree" || die "$worktree exists but is not a git worktree; move it aside and run again" 1
    [[ "$(git -C "$worktree" branch --show-current)" == "$branch" ]] || die "the worktree $worktree is not on $branch" 1
  else
    spec_branch=$(git -C "$CHECKOUT" symbolic-ref -q --short HEAD) || die "$CHECKOUT has a detached HEAD; agent worktrees branch off the spec branch"
    mkdir -p "$(dirname "$worktree")" || die "cannot create $(dirname "$worktree")"
    if git -C "$MAIN_ROOT" show-ref --verify -q "refs/heads/$branch"; then
      out=$(git -C "$MAIN_ROOT" worktree add -q "$worktree" "$branch" 2>&1) || die "cannot add the agent worktree $worktree: $out" 1
    else
      out=$(git -C "$MAIN_ROOT" worktree add -q -b "$branch" "$worktree" "$spec_branch" 2>&1) ||
        die "cannot add the agent worktree $worktree: $out" 1
    fi
  fi
  set_up "$worktree"
  printf 'worktree %s\n' "$worktree"
}

# add_scratch NAME COMMIT : the scratch call in the header.
add_scratch() {
  local name=$1 commit=$2 worktree sha out
  resolve_spec_checkout
  worktree=$(named_worktree "$name")
  sha=$(git -C "$CHECKOUT" rev-parse -q --verify "$commit^{commit}") || die "not a commit: $commit"
  if [[ -d "$worktree" ]]; then
    registered_worktree "$worktree" || die "$worktree exists but is not a git worktree; move it aside and run again" 1
    if git -C "$worktree" symbolic-ref -q HEAD >/dev/null || [[ "$(git -C "$worktree" rev-parse HEAD)" != "$sha" ]]; then
      die "the worktree $worktree is not detached at $sha; remove it first" 1
    fi
  else
    mkdir -p "$(dirname "$worktree")" || die "cannot create $(dirname "$worktree")"
    out=$(git -C "$MAIN_ROOT" worktree add -q --detach "$worktree" "$sha" 2>&1) || die "cannot add the scratch worktree $worktree: $out" 1
  fi
  set_up "$worktree"
  printf 'worktree %s\n' "$worktree"
}

# remove_named NAME : the remove call in the header.
remove_named() {
  local name=$1 worktree out
  resolve_spec_checkout
  worktree=$(named_worktree "$name")
  registered_worktree "$worktree" || die "no agent or scratch worktree is registered at $worktree" 1
  if [[ $FORCE -eq 1 ]]; then
    if git -C "$worktree" symbolic-ref -q HEAD >/dev/null; then
      die "$worktree is an agent worktree on a branch; --force is only for a scratch worktree, so commit or discard its changes and remove it without --force" 1
    fi
    out=$(git -C "$MAIN_ROOT" worktree remove --force "$worktree" 2>&1) || die "cannot remove $worktree: $out" 1
  else
    out=$(git -C "$MAIN_ROOT" worktree remove "$worktree" 2>&1) || die "cannot remove $worktree: $out" 1
  fi
  printf 'removed worktree %s\n' "$worktree"
}

# worktree_of PATH : print the top level of the worktree holding PATH (read from --cwd when relative).
worktree_of() {
  local path=$1
  if [[ "$path" != /* ]]; then path=$OPT_CWD/$path; fi
  [[ -d "$path" ]] || die "not a directory: $1"
  git -C "$path" rev-parse --show-toplevel 2>/dev/null || die "not inside a git repository: $1"
}

CALL="" OPT_CWD=$PWD FORCE=0 ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd) [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h | --help) echo "$USAGE"; exit 0 ;;
    -*) usage ;;
    *)
      if [[ -z "$CALL" ]]; then CALL=$1; else ARGS+=("$1"); fi
      shift
      ;;
  esac
done
[[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
OPT_CWD=$(cd -P "$OPT_CWD" && pwd) || die "cannot enter --cwd: $OPT_CWD"
[[ $FORCE -eq 0 || "$CALL" == remove ]] || usage
ARG_COUNT=${#ARGS[@]}

case "$CALL" in
  agent | scratch | setup | check) SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/worktree-setup.XXXXXX") || die "cannot create a temporary folder" ;;
esac

case "$CALL" in
  agent)
    [[ $ARG_COUNT -eq 2 ]] || usage
    add_agent "${ARGS[0]}" "${ARGS[1]}"
    ;;
  scratch)
    [[ $ARG_COUNT -eq 1 || $ARG_COUNT -eq 2 ]] || usage
    add_scratch "${ARGS[0]}" "${ARGS[1]:-HEAD}"
    ;;
  setup)
    [[ $ARG_COUNT -eq 1 ]] || usage
    WORKTREE=$(worktree_of "${ARGS[0]}")
    set_up "$WORKTREE"
    ;;
  check)
    [[ $ARG_COUNT -eq 1 ]] || usage
    WORKTREE=$(worktree_of "${ARGS[0]}")
    MAIN_ROOT=$(wf_main_root "$WORKTREE" 2>/dev/null) || die "not inside a git repository: $WORKTREE"
    check_links "$WORKTREE"
    ;;
  env)
    [[ $ARG_COUNT -eq 1 ]] || usage
    WORKTREE=$(worktree_of "${ARGS[0]}")
    resolve_roots "$WORKTREE"
    read_or_take_slot
    print_isolation_values
    ;;
  remove)
    [[ $ARG_COUNT -eq 1 ]] || usage
    remove_named "${ARGS[0]}"
    ;;
  *) usage ;;
esac
