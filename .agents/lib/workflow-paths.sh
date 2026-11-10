#!/usr/bin/env bash
# File: Sourced helper (not a hook, not executable on its own): the one home for where workflow data lives in a target project.
# Purpose: Every workflow-written path in a target project sits under one hidden, committed folder, WF_DIR. Hooks (through
#   hooks/workflow-write-guard.sh through check-write.sh, or directly) and skill scripts source this file and build paths from the variables below instead of
#   spelling the folder out, so the root can change in one place. Static files that cannot source it (JSON/TOML templates,
#   markdown) carry the literal paths and must be kept in step by hand.
# Usage (from a hook):         . "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"
#        (from a skill script): . "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"
#   Use `cd -P` so a path reached through the .claude/skills symlink still resolves into .agents/.
# API:
#   WF_DIR                 the workflow root, relative to the project root (".workflow")
#   WF_<NAME>              each path below, relative to the project root, no trailing slash
#   WF_SPECS, WF_INITIATIVES  the roots for feature specs and for initiatives (".workflow/specs", ".workflow/initiatives")
#   WF_SPECS_DONE          the Done folder finished specs move into (".workflow/specs/done")
#   WF_ISSUE_TRACKING      the issue tracker settings file (".workflow/issue-tracking.yaml")
#   wf_path <root> <rel>   prints <root>/<rel> (root's trailing slash dropped); e.g. wf_path "$ROOT" "$WF_SPECS"
#   WF_SPEC_WORKTREES      the folder of spec worktrees in the main checkout (".workflow/.spec-worktrees"): spec NNN-slug runs
#                          in <main checkout>/.workflow/.spec-worktrees/NNN-slug, on its spec branch
#   WF_ISOLATION_WORKTREES the folder Claude Code puts its own `isolation: "worktree"` launches in (".claude/worktrees")
#   wf_main_root <dir>     prints the main checkout root for <dir>, inside the repo or one of its worktrees; status 1
#                          and the reason on stderr when <dir> is not inside a git repository. Only for what is really the
#                          main checkout's (the session-start scan across worktrees); a spec's own data uses wf_project_root
#   wf_project_root <dir>  prints the checkout that holds the workflow data for <dir>: the top level of the checkout <dir> is
#                          in (`git rev-parse --show-toplevel`; the main checkout or a spec worktree), except that an agent
#                          worktree (<checkout>/.workflow/.worktrees/<name>) or an isolation worktree
#                          (<checkout>/.claude/worktrees/<name>) prints the checkout it sits in; status 1 and the reason on
#                          stderr when <dir> is not inside a git repository
#   wf_norm_folder spec|initiative <arg>
#                          prints <arg> as the repo-relative folder `$WF_SPECS/NNN-slug`, `$WF_SPECS_DONE/NNN-slug` or
#                          `$WF_SPECS_DONE/old_NNN-slug` (spec only) or `$WF_INITIATIVES/NNN-slug` (relative, or absolute
#                          with that parent); status 1 and the reason on stderr when <arg> is not one
#   wf_enc <string>        prints <string> lowercased with every byte outside [a-z0-9] turned into `_`, no trailing newline;
#                          the same bytes in every locale (run under LC_ALL=C), so Claude and Codex agree on worktree names;
#                          status 1 and the reason on stderr when not given exactly one argument
#   wf_agent_worktree_name <spec_dir> task|phase_1|integration <value>
#                          prints the agent worktree name under $WF_WORKTREES: task T<n> -> s<NNN>_t<n>, phase_1 <work_type>
#                          -> s<NNN>_phase_1_<wf_enc work_type>, integration <work_type> -> s<NNN>_integration_<wf_enc work_type>,
#                          <NNN> taken from the spec folder name NNN-slug (relative, dot-relative, trailing-slash or absolute
#                          spec dir), no trailing newline; status 1 and the reason on stderr for a spec folder that is not
#                          NNN-slug, an unknown kind, a task value that is not T<digits> or an empty work type
#   wf_marker_seq <marker>  prints the marker's `seq:` value, nothing when it has none or the file is absent
#   wf_marker_order_key <marker>
#                          prints a key that orders step markers (.step of a spec or an initiative) oldest to newest when
#                          compared as strings: `1:<seq, zero-padded to 12>` for a marker with a `seq:` line, `0:<updated_at>`
#                          for an older marker without one (so any marker with seq is newer), nothing when the file is absent
#   wf_next_marker_seq <checkout root>
#                          prints one more than the highest `seq:` among the spec and initiative step markers under <checkout
#                          root> (1 when none has one), the value a marker writer records so readers never compare clock times
#   wf_origin_host <dir>   prints `github` when the `origin` remote URL of the checkout at <dir> contains "github", else
#                          `gitlab` when it contains "gitlab", else nothing (another host, no origin remote, <dir> empty or
#                          not in a git repository); status 0 in every case. Callers still check the CLI is installed.
#   The path rewrite: moves spec folders and workflow files, rewrites every reference to a moved spec and commits exactly
#   what it touched, or undoes all of it. Its state is in WF_REWRITE_* variables, so call these in the script's own shell,
#   never inside $(...). Each prints its reason on stderr and returns 1 on failure, having undone nothing itself.
#     wf_rewrite_begin <root>   start a run in the checkout <root>; refused while an earlier run is uncommitted
#     wf_rewrite_checkout_refusal <root> <main_branch>
#                               prints why <root> must not take the commit (detached HEAD, <main_branch> checked out, a
#                               merge, cherry-pick or revert in progress), nothing when it may; 1 when git cannot be read.
#                               Call it before the first change, so a refusal changes nothing.
#     wf_rewrite_move <old> <new>
#                               moves a repo-relative file or folder (creating <new>'s missing parents) and queues both
#                               paths for the commit, <old> only when git tracks it
#     wf_rewrite_set_aside <file>
#                               moves an untracked local file such as a step marker out of the tree until rollback or end
#     wf_rewrite_spec_path <old> <new>
#                               <old> and <new> each `$WF_SPECS/NAME` or `$WF_SPECS_DONE/NAME`: rewrites in every workflow
#                               file (tracked or untracked and not ignored, under WF_DIR, outside the initiatives,
#                               worktree, handoff and staging folders) the `specs/<old part>` forms, the `../<old part>`
#                               form a file under the specs folder climbs with, and, when NAME changes, the backlog list
#                               `work-backlog/NAME.md` and `NAME.md#B<n>` references; queues each changed file. When <new>
#                               is one folder deeper and already moved, the links in it that climb out of it first get one
#                               more `../`. A move up out of the Done folder is refused. Renaming the backlog list file
#                               itself is a wf_rewrite_move.
#     wf_rewrite_commit <main_branch> <subject> <body> [<path>...]
#                               re-checks the checkout, stages the queued paths and each <path>, and commits only those on
#                               the checked-out branch (<body> "" for none); afterwards nothing is rolled back
#     wf_rewrite_pending        status 0 while the run has uncommitted changes
#     wf_rewrite_roll_back      undoes every uncommitted change, newest first, index included; 1 when some could not be
#                               undone, each listed with how to undo it by hand in the array WF_REWRITE_LEFT
#     wf_rewrite_end            removes the run's temporary folder (kept after an incomplete rollback, for its copies)
#   A caller's EXIT trap runs `wf_rewrite_pending && wf_rewrite_roll_back` on failure, then wf_rewrite_end.
#   No function exits: each caller turns status 1 into its own error message and exit code.
# Paths are repo-relative; the write guards compare them case-insensitively.
# Sources: first-party.
# shellcheck disable=SC2034 # the variables are the API; each sourcing script uses a subset

WF_DIR=".workflow"

WF_GLOSSARY="$WF_DIR/GLOSSARY.md"
WF_GLOSSARY_MAP="$WF_DIR/GLOSSARY-MAP.md"
WF_ISSUE_TRACKING="$WF_DIR/issue-tracking.yaml"
WF_MODEL_MAP="$WF_DIR/model-map.yaml"
WF_PROFILES="$WF_DIR/profiles"
WF_SPECS="$WF_DIR/specs"
WF_SPECS_DONE="$WF_SPECS/done"
WF_INITIATIVES="$WF_DIR/initiatives"
WF_WORK_BACKLOG="$WF_SPECS/work-backlog"
WF_DEFERRED="$WF_DIR/deferred"
WF_RULES="$WF_DIR/rules.md"
WF_CAPABILITIES="$WF_DIR/capabilities.md"
WF_REVIEW_LESSONS="$WF_DIR/review-lessons.md"
WF_DECISIONS="$WF_DIR/decisions"
WF_PR_QUALITY="$WF_DIR/pr-quality"
WF_DESIGN_PATTERN_DOC="$WF_DIR/design-pattern-doc"
WF_TOOLS="$WF_DIR/tools"
WF_BOUNDARIES="$WF_TOOLS/boundaries"
WF_OXLINT="$WF_TOOLS/oxlint"
WF_STANDARDS_STAGING="$WF_DIR/.standards-staging"
WF_HANDOFF="$WF_DIR/.handoff"
WF_WORKTREES="$WF_DIR/.worktrees"
WF_SPEC_WORKTREES="$WF_DIR/.spec-worktrees"
WF_ISOLATION_WORKTREES=".claude/worktrees"
WF_DATA_STRUCTURE_AUDIT_STATE="$WF_DIR/data-structure-audit-state.jsonl"

wf_path() {
  local root=${1%/}
  printf '%s/%s\n' "$root" "$2"
}

# wf_main_root DIR : print the main checkout root for DIR, from the repo or one of its worktrees; status 1 when DIR is
#   not inside a git repository.
wf_main_root() {
  local common
  if ! common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    printf 'not inside a git repository: %s\n' "$1" >&2
    return 1
  fi
  if [[ "$(basename "$common")" == ".git" ]]; then
    dirname "$common"
  else
    # A common dir not named .git does not sit in the checkout; the worktree list always names the main one first.
    git -C "$1" worktree list --porcelain | sed -n '1s/^worktree //p'
  fi
}

# wf_project_root DIR : print the checkout holding the workflow data for DIR (its top level, or the checkout an agent or
#   isolation worktree sits in); status 1 when DIR is not inside a git repository.
wf_project_root() {
  local top owner nest
  if ! top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || [[ -z "$top" ]]; then
    printf 'not inside a git repository: %s\n' "$1" >&2
    return 1
  fi
  # An agent's worktree is created inside the checkout that runs the spec, so that checkout's step marker, artifacts and
  #   spec branch are the agent's too; the owner must itself be a checkout, or the path only looks like an agent worktree.
  for nest in "$WF_WORKTREES" "$WF_ISOLATION_WORKTREES"; do
    [[ "$(dirname "$top")" == */"$nest" ]] || continue
    owner=${top%/"$nest"/*}
    if [[ "$(git -C "$owner" rev-parse --show-toplevel 2>/dev/null)" == "$owner" ]]; then
      printf '%s\n' "$owner"
      return 0
    fi
  done
  printf '%s\n' "$top"
}

# wf_norm_folder spec|initiative ARG : print ARG as the repo-relative folder `$WF_SPECS/NNN-slug`,
#   `$WF_SPECS_DONE/NNN-slug`, `$WF_SPECS_DONE/old_NNN-slug` or `$WF_INITIATIVES/NNN-slug`; status 1 when ARG is not one.
wf_norm_folder() {
  local kind=$1 arg=$2 root label folder name_pattern
  case "$kind" in
    spec) root=$WF_SPECS label="spec dir" ;;
    initiative) root=$WF_INITIATIVES label="initiative dir" ;;
    *)
      printf 'unknown folder kind (want spec or initiative): %s\n' "$kind" >&2
      return 1
      ;;
  esac
  folder=${arg%/}
  folder=${folder#./}
  name_pattern='^[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$'
  # Finished specs move into the Done folder and scripts still run on them there, so its direct children are spec dirs too.
  #   Adopting an issue tracker renames each Done spec old_NNN-slug, so its number is not read as an issue number.
  if [[ "$kind" == spec ]] && { [[ "$folder" == "$WF_SPECS_DONE"/* ]] ||
    [[ "$folder" == /* && "$(dirname "$folder")" == */"$WF_SPECS_DONE" ]]; }; then
    root=$WF_SPECS_DONE
    name_pattern='^(old_)?[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$'
  fi
  # An absolute path may point into the main checkout or any worktree, so only its last two parts name the folder.
  if [[ "$folder" == /* ]]; then
    if [[ "$(dirname "$folder")" != */"$root" ]]; then
      printf '%s must be %s/NNN-slug: %s\n' "$label" "$root" "$arg" >&2
      return 1
    fi
    folder="$root/$(basename "$folder")"
  fi
  if ! [[ "$folder" == "$root"/* && "${folder#"$root"/}" =~ $name_pattern ]]; then
    printf '%s must be %s/NNN-slug: %s\n' "$label" "$root" "$arg" >&2
    return 1
  fi
  printf '%s\n' "$folder"
}

# wf_enc STRING : print STRING lowercased with every byte outside [a-z0-9] turned into `_`, no trailing newline; status 1
#   when not given exactly one argument.
wf_enc() {
  if [[ $# -ne 1 ]]; then
    printf 'wf_enc takes one string, got %s arguments\n' "$#" >&2
    return 1
  fi
  # The C locale makes tr work byte by byte, so a multi-byte character becomes one `_` per byte whatever the caller's locale.
  printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -c 'a-z0-9' '_'
}

# wf_agent_worktree_name SPEC_DIR task|phase_1|integration VALUE : print the agent worktree name, no trailing newline;
#   status 1 when SPEC_DIR is not a NNN-slug folder, the kind is unknown, a task id is not T<digits> or a work type is empty.
wf_agent_worktree_name() {
  if [[ $# -ne 3 ]]; then
    printf 'wf_agent_worktree_name takes a spec dir, a kind and a value, got %s arguments\n' "$#" >&2
    return 1
  fi
  local spec_dir=$1 kind=$2 value=$3 folder spec_number slug task_number
  folder=${spec_dir%/}
  folder=${folder##*/}
  spec_number=${folder%%-*}
  slug=${folder#*-}
  # Glob tests rather than =~ so the function leaves no BASH_REMATCH behind in the caller.
  if [[ "$folder" != *-* || -z "$spec_number" || "$spec_number" == *[!0-9]* ||
    "$slug" != [A-Za-z0-9]* || "$slug" == *[!A-Za-z0-9._-]* ]]; then
    printf 'spec dir must be a folder named NNN-slug: %s\n' "$spec_dir" >&2
    return 1
  fi
  case "$kind" in
    task)
      task_number=${value#T}
      if [[ "$value" != T* || -z "$task_number" || "$task_number" == *[!0-9]* ]]; then
        printf 'task id must be T<digits>: %s\n' "$value" >&2
        return 1
      fi
      printf 's%s_t%s' "$spec_number" "$task_number"
      ;;
    phase_1 | integration)
      if [[ -z "$value" ]]; then
        printf 'work type for a %s worktree name is empty\n' "$kind" >&2
        return 1
      fi
      printf 's%s_%s_%s' "$spec_number" "$kind" "$(wf_enc "$value")"
      ;;
    *)
      printf 'unknown worktree kind (want task, phase_1 or integration): %s\n' "$kind" >&2
      return 1
      ;;
  esac
}

# wf_marker_seq MARKER : print the marker's seq value, nothing when it has none or the file is absent.
wf_marker_seq() {
  [[ -f "$1" ]] || return 0
  sed -n 's/^seq:[[:space:]]*"\{0,1\}\([0-9][0-9]*\)"\{0,1\}[[:space:]]*$/\1/p' "$1" | head -n 1
}

# wf_marker_order_key MARKER : print a key that sorts step markers oldest to newest as strings; nothing when MARKER is absent.
wf_marker_order_key() {
  local seq at
  [[ -f "$1" ]] || return 0
  seq=$(wf_marker_seq "$1")
  if [[ -n "$seq" ]]; then
    # 10# reads a zero-padded value as decimal, not octal.
    printf '1:%012d\n' "$((10#$seq))"
    return 0
  fi
  at=$(sed -n 's/^updated_at:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "$1" | head -n 1)
  printf '0:%s\n' "$at"
}

# wf_next_marker_seq ROOT : print one more than the highest seq among the spec and initiative step markers under ROOT.
wf_next_marker_seq() {
  local mk seq high=0
  for mk in "$1/$WF_SPECS"/*/.step "$1/$WF_INITIATIVES"/*/.step; do
    [[ -f "$mk" ]] || continue
    seq=$(wf_marker_seq "$mk")
    [[ -z "$seq" ]] || (( 10#$seq <= high )) || high=$((10#$seq))
  done
  printf '%s\n' "$((high + 1))"
}

# wf_origin_host DIR : print github or gitlab when the origin remote URL of the checkout at DIR contains that name, nothing
#   for any other host, no origin remote, an empty DIR or a DIR outside git; status 0 in every case.
wf_origin_host() {
  local url
  # git -C "" would read the current folder's remote instead of none.
  [[ -n "${1:-}" ]] || return 0
  url=$(git -C "$1" remote get-url origin 2>/dev/null) || return 0
  case "$url" in
    *github*) printf 'github\n' ;;
    *gitlab*) printf 'gitlab\n' ;;
  esac
  return 0
}

# The path rewrite. One rewrite run moves spec folders and other workflow files, rewrites every reference to a moved spec
#   in the workflow files and records it all in one commit. Until that commit it keeps what it needs to undo every change,
#   newest first: WF_REWRITE_UNDO_KIND, WF_REWRITE_UNDO_PATH and WF_REWRITE_UNDO_COPY are parallel, one entry per change.
#   The state lives in these variables, so the functions must run in the caller's own shell, never in a command substitution.
WF_REWRITE_SLUG_CHARS='A-Za-z0-9._-'
WF_REWRITE_ROOT="" WF_REWRITE_SCRATCH="" WF_REWRITE_PENDING=0
WF_REWRITE_UNDO_KIND=() WF_REWRITE_UNDO_PATH=() WF_REWRITE_UNDO_COPY=()
WF_REWRITE_COMMIT_PATHS=() WF_REWRITE_LEFT=()

# wf_rewrite_say MESSAGE : print MESSAGE on stderr; status 0, so a failing step can print its reason and then return 1.
wf_rewrite_say() { printf '%s\n' "$1" >&2; }

# wf_rewrite_note_undo KIND PATH COPY : record one change the run made, so wf_rewrite_roll_back can undo it.
wf_rewrite_note_undo() {
  WF_REWRITE_UNDO_KIND+=("$1")
  WF_REWRITE_UNDO_PATH+=("$2")
  WF_REWRITE_UNDO_COPY+=("$3")
  WF_REWRITE_PENDING=1
}

# wf_rewrite_require_run : status 1 with a reason when no rewrite run has been started.
wf_rewrite_require_run() {
  [[ -n "$WF_REWRITE_SCRATCH" ]] && return 0
  wf_rewrite_say "no rewrite run is under way; call wf_rewrite_begin first"
  return 1
}

# wf_rewrite_begin ROOT : start a rewrite run in the checkout ROOT; status 1 when one is still uncommitted or the temporary
#   folder cannot be made.
wf_rewrite_begin() {
  if [[ $# -ne 1 || -z "$1" ]]; then
    wf_rewrite_say "wf_rewrite_begin takes the checkout root"
    return 1
  fi
  if [[ $WF_REWRITE_PENDING -eq 1 ]]; then
    wf_rewrite_say "a rewrite run in $WF_REWRITE_ROOT is not committed yet; commit it or roll it back first"
    return 1
  fi
  wf_rewrite_end
  WF_REWRITE_ROOT=${1%/}
  WF_REWRITE_UNDO_KIND=() WF_REWRITE_UNDO_PATH=() WF_REWRITE_UNDO_COPY=() WF_REWRITE_COMMIT_PATHS=() WF_REWRITE_LEFT=()
  WF_REWRITE_SCRATCH=$(mktemp -d) || {
    WF_REWRITE_SCRATCH=""
    wf_rewrite_say "cannot create a temporary folder"
    return 1
  }
}

# wf_rewrite_pending : status 0 when the run has changes that are neither committed nor rolled back.
wf_rewrite_pending() { [[ $WF_REWRITE_PENDING -eq 1 ]]; }

# wf_rewrite_end : remove the run's temporary folder, unless a rollback left copies in it that are still needed.
wf_rewrite_end() {
  [[ -n "$WF_REWRITE_SCRATCH" ]] || return 0
  rm -rf "$WF_REWRITE_SCRATCH" || wf_rewrite_say "cannot remove the temporary folder $WF_REWRITE_SCRATCH"
  WF_REWRITE_SCRATCH=""
}

# wf_rewrite_checkout_refusal ROOT MAIN_BRANCH : print why the checkout ROOT must not take a commit (a detached HEAD, the
#   branch MAIN_BRANCH checked out, a merge, cherry-pick or revert in progress), nothing when it may; status 1 with a reason
#   when git cannot be read.
wf_rewrite_checkout_refusal() {
  local root=$1 main=$2 current head
  current=$(git -C "$root" branch --show-current) || {
    wf_rewrite_say "cannot read the checked-out branch in $root"
    return 1
  }
  if [[ -z "$current" ]]; then
    printf '%s\n' "the checkout $root has a detached HEAD; check out a branch first"
    return 0
  fi
  if [[ "$current" == "$main" ]]; then
    printf '%s\n' "the checkout $root is on the main branch $main; commit on another branch"
    return 0
  fi
  for head in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    if git -C "$root" rev-parse -q --verify "$head" >/dev/null; then
      printf '%s\n' "a merge, cherry-pick or revert is in progress in $root; finish or abort it first"
      return 0
    fi
  done
}

# wf_rewrite_move OLD NEW : move the repo-relative file or folder OLD to NEW, creating NEW's missing parent folders, and
#   queue both for the commit (OLD only when git tracks it); status 1 with a reason when OLD is missing, NEW exists or a
#   step fails.
wf_rewrite_move() {
  wf_rewrite_require_run || return 1
  local old=$1 new=$2 old_abs new_abs dir parents_to_create=() i tracked
  old_abs=$(wf_path "$WF_REWRITE_ROOT" "$old")
  new_abs=$(wf_path "$WF_REWRITE_ROOT" "$new")
  if [[ ! -e "$old_abs" && ! -L "$old_abs" ]]; then
    wf_rewrite_say "cannot move $old: it does not exist"
    return 1
  fi
  if [[ -e "$new_abs" || -L "$new_abs" ]]; then
    wf_rewrite_say "cannot move $old to $new: $new already exists"
    return 1
  fi
  dir=${new_abs%/*}
  while [[ ! -d "$dir" ]]; do
    parents_to_create+=("$dir")
    dir=${dir%/*}
  done
  i=${#parents_to_create[@]}
  while [[ $i -gt 0 ]]; do
    i=$((i - 1))
    mkdir "${parents_to_create[i]}" || {
      wf_rewrite_say "cannot create ${parents_to_create[i]}"
      return 1
    }
    wf_rewrite_note_undo mkdir "${parents_to_create[i]}" ""
  done
  # Plain mv, not git mv: git mv refuses an untracked spec folder.
  mv "$old_abs" "$new_abs" || {
    wf_rewrite_say "cannot move $old to $new"
    return 1
  }
  wf_rewrite_note_undo move "$old_abs" "$new_abs"
  # git add fails on a path that matches nothing, and an untracked OLD leaves nothing at its old path for git.
  tracked=$(git -C "$WF_REWRITE_ROOT" --literal-pathspecs ls-files -c -- "$old") || {
    wf_rewrite_say "cannot list the tracked files of $old"
    return 1
  }
  [[ -z "$tracked" ]] || WF_REWRITE_COMMIT_PATHS+=("$old")
  WF_REWRITE_COMMIT_PATHS+=("$new")
}

# wf_rewrite_set_aside FILE : move the repo-relative local file FILE, one git does not track such as a step marker, out
#   of the tree into the temporary folder, so a rollback can put it back; status 1 with a reason when it cannot.
wf_rewrite_set_aside() {
  wf_rewrite_require_run || return 1
  local file_abs copy
  file_abs=$(wf_path "$WF_REWRITE_ROOT" "$1")
  copy=$WF_REWRITE_SCRATCH/aside.${#WF_REWRITE_UNDO_KIND[@]}
  mv "$file_abs" "$copy" || {
    wf_rewrite_say "cannot set aside $1"
    return 1
  }
  wf_rewrite_note_undo aside "$file_abs" "$copy"
}

# wf_rewrite_replace_file FILE : put the rewritten text in the temporary folder in place of FILE when they differ, keeping
#   FILE's mode and a copy of its old content for a rollback; status 0 when FILE changed, 1 when it was already the same,
#   2 with a reason when it could not be replaced.
wf_rewrite_replace_file() {
  local file=$1 rewritten=$WF_REWRITE_SCRATCH/rewrite copy
  cmp -s "$rewritten" "$file" && return 1
  copy=$WF_REWRITE_SCRATCH/saved.${#WF_REWRITE_UNDO_KIND[@]}
  cp "$file" "$copy" || {
    wf_rewrite_say "cannot keep a copy of $file"
    return 2
  }
  wf_rewrite_note_undo file "$file" "$copy"
  cat "$rewritten" >"$file" || {
    wf_rewrite_say "cannot write $file"
    return 2
  }
  return 0
}

# wf_rewrite_outbound_links FILE DEPTH LEVELS : give every relative Markdown link in FILE that climbs out of its spec folder
#   LEVELS more `../`; DEPTH is how many folders below the spec folder FILE sits. Status 0 when FILE changed or was already
#   right, 2 with a reason when it could not be read or replaced.
wf_rewrite_outbound_links() {
  local file=$1 replace_status=0
  awk -v depth="$2" -v levels="$3" '
    BEGIN { up = ""; for (n = 0; n < levels; n++) up = up "../" }
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
    # adjusted TARGET : TARGET with the extra `../` in front when it climbs out of the spec folder, else TARGET as it is.
    function adjusted(target) { return climbs_out(target) ? up target : target }
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
  ' "$file" >"$WF_REWRITE_SCRATCH/rewrite" || {
    wf_rewrite_say "cannot read the links in $file"
    return 2
  }
  wf_rewrite_replace_file "$file" || replace_status=$?
  [[ $replace_status -le 1 ]] || return 2
  return 0
}

# wf_rewrite_spec_part SPEC_DIR : print the part of the repo-relative SPEC_DIR below the specs folder, `NAME` or `done/NAME`;
#   status 1 with a reason when SPEC_DIR is neither `$WF_SPECS/NAME` nor `$WF_SPECS_DONE/NAME`.
wf_rewrite_spec_part() {
  local part=${1#"$WF_SPECS"/} done_leaf=${WF_SPECS_DONE#"$WF_SPECS"/} name
  name=${part#"$done_leaf"/}
  if [[ "$part" == "$1" || -z "$name" || "$name" == */* || "$name" != [A-Za-z0-9]* ||
    "$name" == *[!$WF_REWRITE_SLUG_CHARS]* || "$name" == "$done_leaf" || "$name" == "${WF_WORK_BACKLOG##*/}" ]]; then
    wf_rewrite_say "not a spec folder (want $WF_SPECS/NAME or $WF_SPECS_DONE/NAME): $1"
    return 1
  fi
  printf '%s\n' "$part"
}

# wf_rewrite_list_files_naming WORD : write to the temporary folder's `matches` file, NUL-separated, the absolute path of
#   each regular file in its `list` file (repo-relative paths) whose text contains WORD; status 1 with a reason naming the
#   file that cannot be searched.
wf_rewrite_list_files_naming() {
  local word=$1 scratch=$WF_REWRITE_SCRATCH prefix rel file search_status=0
  prefix=$(wf_path "$WF_REWRITE_ROOT" "")
  while IFS= read -r -d '' rel; do
    file=$prefix$rel
    if [[ -f "$file" && ! -L "$file" ]]; then
      printf '%s\0' "$file" || {
        wf_rewrite_say "cannot write the list of workflow files to search"
        return 1
      }
    fi
  done <"$scratch/list" >"$scratch/candidates" || {
    wf_rewrite_say "cannot write the list of workflow files to search"
    return 1
  }
  # The search below reads a failed redirect as "no file names the spec", so both files are opened here first.
  : >"$scratch/matches" || {
    wf_rewrite_say "cannot write the list of workflow files that name the spec"
    return 1
  }
  : >"$scratch/search-errors" || {
    wf_rewrite_say "cannot write the search error log"
    return 1
  }
  # One grep over all the files, not one per file: a sweep searches every workflow file once per spec, and starting a
  #   process per file made it slow. /dev/null keeps grep off stdin when the list is empty.
  xargs -0 grep -lIF --null -- "$word" /dev/null <"$scratch/candidates" >"$scratch/matches" 2>"$scratch/search-errors" ||
    search_status=$?
  # xargs reports a batch with no match (grep status 1) as 1 or 123, the same as a grep error, so a grep error is told
  #   apart by what it wrote to stderr.
  case $search_status in
    0 | 1 | 123) [[ -s "$scratch/search-errors" ]] || return 0 ;;
  esac
  while IFS= read -r -d '' file; do
    search_status=0
    grep -qIF -- "$word" "$file" || search_status=$?
    if [[ $search_status -gt 1 ]]; then
      wf_rewrite_say "cannot search ${file#"$prefix"} for the spec path"
      return 1
    fi
  done <"$scratch/candidates"
  wf_rewrite_say "cannot search the workflow files for the spec path: $(head -n 1 "$scratch/search-errors")"
  return 1
}

# wf_rewrite_references FILE OLD_PART NEW_PART : rewrite in FILE each path to the spec OLD_PART (below the specs folder)
#   into NEW_PART: the `specs/OLD_PART` forms, for a file under the specs folder the `../OLD_PART` form that climbs to it,
#   and, when the folder name changes, its backlog list `work-backlog/NAME.md` and `NAME.md#B<n>` item references. Status 0
#   when FILE changed, 1 when nothing named the spec, 2 with a reason when it could not be rewritten.
wf_rewrite_references() {
  local file=$1 old_part=$2 new_part=$3 slug=$WF_REWRITE_SLUG_CHARS old_re old_name new_name old_name_re
  local specs_leaf=${WF_SPECS##*/} backlog_leaf=${WF_WORK_BACKLOG##*/} rel_dir slashes depth climb="" climb_re="" end sed_exprs
  old_re=${old_part//./\\.}
  old_name=${old_part##*/} new_name=${new_part##*/}
  old_name_re=${old_name//./\\.}
  # A path that ends a sentence keeps its full stop, but `NAME.md` is another file and stays as it is.
  end="(\\.?[^$slug]|\\.?\$)"
  # The % delimiter leaves # free for the backlog item references.
  sed_exprs=(-e ':again' -e "s%(^|[^$slug])$specs_leaf/$old_re$end%\\1$specs_leaf/$new_part\\2%g")
  rel_dir=${file#"$WF_REWRITE_ROOT"/}
  rel_dir=${rel_dir%/*}
  if [[ "$rel_dir" == "$WF_SPECS"/* ]]; then
    rel_dir=${rel_dir#"$WF_SPECS"/}
    slashes=${rel_dir//[!\/]/}
    depth=$((${#slashes} + 1))
    while [[ $depth -gt 0 ]]; do
      climb="$climb../" climb_re="$climb_re\\.\\./"
      depth=$((depth - 1))
    done
    sed_exprs+=(-e "s%(^|[^/$slug])$climb_re$old_re$end%\\1$climb$new_part\\2%g")
  fi
  if [[ "$old_name" != "$new_name" ]]; then
    sed_exprs+=(-e "s%(^|[^$slug])$backlog_leaf/$old_name_re\\.md$end%\\1$backlog_leaf/$new_name.md\\2%g")
    sed_exprs+=(-e "s%(^|[^$slug])$old_name_re\\.md#B([0-9])%\\1$new_name.md#B\\2%g")
  fi
  # Repeat until nothing changes: two paths one character apart share that character, and one pass rewrites only the first.
  sed_exprs+=(-e 't again')
  sed -E "${sed_exprs[@]}" "$file" >"$WF_REWRITE_SCRATCH/rewrite" || {
    wf_rewrite_say "cannot rewrite the spec path in $file"
    return 2
  }
  wf_rewrite_replace_file "$file"
}

# wf_rewrite_spec_path OLD NEW : rewrite every path to the spec folder OLD into NEW (each `$WF_SPECS/NAME` or
#   `$WF_SPECS_DONE/NAME`, repo-relative) in the workflow files, and queue each changed file for the commit. When NEW sits a
#   folder deeper and its folder is already moved there, the relative links in it that climb out of it first get one more
#   `../` each, so call this once per move, after wf_rewrite_move. Initiative records and local working state are
#   skipped: an initiative re-points its own spec paths when it closes, and other checkouts are not this branch's to
#   change. Status 1 with a reason when OLD or NEW is not a spec folder, NEW sits higher than OLD, or a step fails.
wf_rewrite_spec_path() {
  wf_rewrite_require_run || return 1
  local old=$1 new=$2 old_part new_part old_slashes new_slashes levels new_abs prefix file rel slashes rewrite_status
  old_part=$(wf_rewrite_spec_part "$old") || return 1
  new_part=$(wf_rewrite_spec_part "$new") || return 1
  if [[ "$old_part" == "$new_part" ]]; then
    wf_rewrite_say "the spec folder $old would be rewritten to itself"
    return 1
  fi
  old_slashes=${old_part//[!\/]/} new_slashes=${new_part//[!\/]/}
  levels=$((${#new_slashes} - ${#old_slashes}))
  if [[ $levels -lt 0 ]]; then
    wf_rewrite_say "cannot rewrite $old to $new: moving a spec up out of the Done folder is not supported"
    return 1
  fi
  new_abs=$(wf_path "$WF_REWRITE_ROOT" "$new")
  prefix=$(wf_path "$WF_REWRITE_ROOT" "")
  if [[ $levels -gt 0 && -d "$new_abs" ]]; then
    find "$new_abs" -type f -name '*.md' -print0 >"$WF_REWRITE_SCRATCH/list" || {
      wf_rewrite_say "cannot list the Markdown files in $new"
      return 1
    }
    while IFS= read -r -d '' file; do
      rel=${file#"$new_abs"/}
      slashes=${rel//[!\/]/}
      wf_rewrite_outbound_links "$file" "${#slashes}" "$levels" || return 1
    done <"$WF_REWRITE_SCRATCH/list"
  fi
  git -C "$WF_REWRITE_ROOT" ls-files -c -o --exclude-standard -z -- "$WF_DIR" ":(exclude)$WF_INITIATIVES" \
    ":(exclude)$WF_WORKTREES" ":(exclude)$WF_SPEC_WORKTREES" ":(exclude)$WF_HANDOFF" ":(exclude)$WF_STANDARDS_STAGING" >"$WF_REWRITE_SCRATCH/list" || {
    wf_rewrite_say "cannot list the workflow files to rewrite"
    return 1
  }
  wf_rewrite_list_files_naming "${old_part##*/}" || return 1
  while IFS= read -r -d '' file; do
    rewrite_status=0
    wf_rewrite_references "$file" "$old_part" "$new_part" || rewrite_status=$?
    case $rewrite_status in
      0) WF_REWRITE_COMMIT_PATHS+=("${file#"$prefix"}") ;;
      1) ;;
      *) return 1 ;;
    esac
  done <"$WF_REWRITE_SCRATCH/matches"
}

# wf_rewrite_commit MAIN_BRANCH SUBJECT BODY [PATH...] : stage the queued paths and each given PATH (repo-relative) and
#   commit only them on the checked-out branch, with SUBJECT and, when BODY is not empty, BODY as the message; the run's
#   changes are then no longer undone. Status 1 with a reason when the checkout is refused (see
#   wf_rewrite_checkout_refusal), nothing is staged or a git step fails.
wf_rewrite_commit() {
  wf_rewrite_require_run || return 1
  if [[ $# -lt 3 ]]; then
    wf_rewrite_say "wf_rewrite_commit takes the main branch, a subject and a body, then any extra paths"
    return 1
  fi
  local main=$1 subject=$2 body=$3 root=$WF_REWRITE_ROOT refusal git_dir file commit_paths=() staged_paths=() message_args
  shift 3
  refusal=$(wf_rewrite_checkout_refusal "$root" "$main") || return 1
  if [[ -n "$refusal" ]]; then
    wf_rewrite_say "$refusal"
    return 1
  fi
  [[ ${#WF_REWRITE_COMMIT_PATHS[@]} -eq 0 ]] || commit_paths=("${WF_REWRITE_COMMIT_PATHS[@]}")
  [[ $# -eq 0 ]] || commit_paths+=("$@")
  if [[ ${#commit_paths[@]} -eq 0 ]]; then
    wf_rewrite_say "nothing to commit: no path was moved or rewritten"
    return 1
  fi
  git_dir=$(git -C "$root" rev-parse --absolute-git-dir) || {
    wf_rewrite_say "cannot find the git folder of $root"
    return 1
  }
  if [[ -f "$git_dir/index" ]]; then
    cp "$git_dir/index" "$WF_REWRITE_SCRATCH/index" || {
      wf_rewrite_say "cannot keep a copy of the index"
      return 1
    }
    wf_rewrite_note_undo index "$git_dir/index" "$WF_REWRITE_SCRATCH/index"
  else
    wf_rewrite_note_undo index "$git_dir/index" ""
  fi
  git -C "$root" --literal-pathspecs add -A -- "${commit_paths[@]}" || {
    wf_rewrite_say "git add failed for the rewritten paths"
    return 1
  }
  # With rename detection the list names only the new path, so the commit would leave the old path's deletion staged.
  git -C "$root" --literal-pathspecs diff --cached --name-only -z --no-renames -- "${commit_paths[@]}" \
    >"$WF_REWRITE_SCRATCH/list" || {
    wf_rewrite_say "cannot list the staged changes"
    return 1
  }
  while IFS= read -r -d '' file; do staged_paths+=("$file"); done <"$WF_REWRITE_SCRATCH/list"
  if [[ ${#staged_paths[@]} -eq 0 ]]; then
    wf_rewrite_say "nothing staged after the rewrite"
    return 1
  fi
  message_args=(-m "$subject")
  [[ -z "$body" ]] || message_args+=(-m "$body")
  git -C "$root" --literal-pathspecs commit -q "${message_args[@]}" -- "${staged_paths[@]}" || {
    wf_rewrite_say "git commit failed"
    return 1
  }
  WF_REWRITE_PENDING=0
  WF_REWRITE_UNDO_KIND=() WF_REWRITE_UNDO_PATH=() WF_REWRITE_UNDO_COPY=() WF_REWRITE_COMMIT_PATHS=()
}

# wf_rewrite_roll_back : undo every uncommitted change of the run, newest first: the index, rewritten files, set-aside
#   files, moves and created folders. Status 0 when all of it was undone; status 1 when some could not be, with each
#   change still in place and how to undo it by hand in WF_REWRITE_LEFT, and the temporary folder kept for its copies.
wf_rewrite_roll_back() {
  local i kind path copy root=$WF_REWRITE_ROOT
  WF_REWRITE_LEFT=()
  i=${#WF_REWRITE_UNDO_KIND[@]}
  while [[ $i -gt 0 ]]; do
    i=$((i - 1))
    kind=${WF_REWRITE_UNDO_KIND[i]} path=${WF_REWRITE_UNDO_PATH[i]} copy=${WF_REWRITE_UNDO_COPY[i]}
    case $kind in
      index)
        if [[ -n "$copy" ]]; then
          cp "$copy" "$path" || WF_REWRITE_LEFT+=("the index has the change staged: run git reset -q in $root")
        else
          rm -f "$path" || WF_REWRITE_LEFT+=("the index has the change staged: run git reset -q in $root")
        fi
        ;;
      file)
        # A file whose write failed before it was truncated still matches its copy and needs no restore.
        cmp -s "$copy" "$path" && continue
        cat "$copy" >"$path" || WF_REWRITE_LEFT+=("$path is rewritten: copy $copy over it")
        ;;
      aside) mv "$copy" "$path" || WF_REWRITE_LEFT+=("$path is missing: mv $copy back to it") ;;
      move) mv "$copy" "$path" || WF_REWRITE_LEFT+=("$copy is still moved: mv it back to $path") ;;
      mkdir) rmdir "$path" || WF_REWRITE_LEFT+=("$path was created by this run: remove it once it is empty") ;;
    esac
  done
  WF_REWRITE_PENDING=0
  WF_REWRITE_UNDO_KIND=() WF_REWRITE_UNDO_PATH=() WF_REWRITE_UNDO_COPY=() WF_REWRITE_COMMIT_PATHS=()
  [[ ${#WF_REWRITE_LEFT[@]} -gt 0 ]] || return 0
  # The copies named in WF_REWRITE_LEFT live in the temporary folder, so it must outlive the run.
  WF_REWRITE_SCRATCH=""
  return 1
}
