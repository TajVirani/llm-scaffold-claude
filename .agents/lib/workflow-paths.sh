#!/usr/bin/env bash
# File: Sourced helper (not a hook, not executable on its own): the one home for where workflow data lives in a target project.
# Purpose: Every workflow-written path in a target project sits under one hidden, committed folder, WF_DIR. Hooks (through
#   hooks/_guard-common.sh or directly) and skill scripts source this file and build paths from the variables below instead of
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
#                          prints <arg> as the repo-relative folder `$WF_SPECS/NNN-slug`, `$WF_SPECS_DONE/NNN-slug` (spec only)
#                          or `$WF_INITIATIVES/NNN-slug` (relative, or absolute with that parent); status 1 and the reason on
#                          stderr when <arg> is not one
#   wf_enc <string>        prints <string> lowercased with every byte outside [a-z0-9] turned into `_`, no trailing newline;
#                          the same bytes in every locale (run under LC_ALL=C), so Claude and Codex agree on worktree names;
#                          status 1 and the reason on stderr when not given exactly one argument
#   wf_agent_worktree_name <spec_dir> task|phase_1|integration <value>
#                          prints the agent worktree name under $WF_WORKTREES: task T<n> -> s<NNN>_t<n>, phase_1 <work_type>
#                          -> s<NNN>_phase_1_<wf_enc work_type>, integration <work_type> -> s<NNN>_integration_<wf_enc work_type>,
#                          <NNN> taken from the spec folder name NNN-slug (relative, dot-relative, trailing-slash or absolute
#                          spec dir), no trailing newline; status 1 and the reason on stderr for a spec folder that is not
#                          NNN-slug, an unknown kind, a task value that is not T<digits> or an empty work type
#   No function exits: each caller turns status 1 into its own error message and exit code.
# Paths are repo-relative; the write guards compare them case-insensitively.
# Sources: first-party.
# shellcheck disable=SC2034 # the variables are the API; each sourcing script uses a subset

WF_DIR=".workflow"

WF_GLOSSARY="$WF_DIR/GLOSSARY.md"
WF_GLOSSARY_MAP="$WF_DIR/GLOSSARY-MAP.md"
WF_AGENT_OVERRIDES="$WF_DIR/agent-overrides.yaml"
WF_ISSUE_TRACKING="$WF_DIR/issue-tracking.yaml"
WF_MODEL_MAP="$WF_DIR/model-map"
WF_PROFILES="$WF_DIR/profiles"
WF_SPECS="$WF_DIR/specs"
WF_SPECS_DONE="$WF_SPECS/done"
WF_INITIATIVES="$WF_DIR/initiatives"
WF_WORK_BACKLOG="$WF_SPECS/work-backlog"
WF_DEFERRED="$WF_DIR/deferred"
WF_RULES="$WF_DIR/rules.md"
WF_CAPABILITIES="$WF_DIR/capabilities.md"
WF_REVIEW_LESSONS="$WF_DIR/review-lessons.md"
WF_CACHE="$WF_DIR/cache"
WF_DECISIONS="$WF_DIR/decisions"
WF_PR_QUALITY="$WF_DIR/pr-quality"
WF_DESIGN_PATTERN_DOC="$WF_DIR/design-pattern-doc"
WF_TOOLS="$WF_DIR/tools"
WF_BOUNDARIES="$WF_TOOLS/boundaries"
WF_OXLINT="$WF_TOOLS/oxlint"
WF_CACHE_STAGING="$WF_DIR/.cache-staging"
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
#   `$WF_SPECS_DONE/NNN-slug` or `$WF_INITIATIVES/NNN-slug`; status 1 when ARG is not one.
wf_norm_folder() {
  local kind=$1 arg=$2 root label folder
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
  # Finished specs move into the Done folder and scripts still run on them there, so its direct children are spec dirs too.
  if [[ "$kind" == spec ]] && { [[ "$folder" == "$WF_SPECS_DONE"/* ]] ||
    [[ "$folder" == /* && "$(dirname "$folder")" == */"$WF_SPECS_DONE" ]]; }; then
    root=$WF_SPECS_DONE
  fi
  # An absolute path may point into the main checkout or any worktree, so only its last two parts name the folder.
  if [[ "$folder" == /* ]]; then
    if [[ "$(dirname "$folder")" != */"$root" ]]; then
      printf '%s must be %s/NNN-slug: %s\n' "$label" "$root" "$arg" >&2
      return 1
    fi
    folder="$root/$(basename "$folder")"
  fi
  if ! [[ "$folder" == "$root"/* && "${folder#"$root"/}" =~ ^[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
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
