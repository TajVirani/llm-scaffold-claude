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
#   wf_path <root> <rel>   prints <root>/<rel> (root's trailing slash dropped); e.g. wf_path "$ROOT" "$WF_SPECS"
#   wf_main_root <dir>     prints the main checkout root for <dir>, inside the repo or one of its worktrees; status 1
#                          and the reason on stderr when <dir> is not inside a git repository
#   wf_norm_folder spec|initiative <arg>
#                          prints <arg> as the repo-relative folder `$WF_SPECS/NNN-slug` or `$WF_INITIATIVES/NNN-slug`
#                          (relative, or absolute with that parent); status 1 and the reason on stderr when <arg> is not one
#   Neither function exits: each caller turns status 1 into its own error message and exit code.
# Paths are repo-relative; the write guards compare them case-insensitively.
# Sources: first-party.
# shellcheck disable=SC2034 # the variables are the API; each sourcing script uses a subset

WF_DIR=".workflow"

WF_GLOSSARY="$WF_DIR/GLOSSARY.md"
WF_GLOSSARY_MAP="$WF_DIR/GLOSSARY-MAP.md"
WF_AGENT_OVERRIDES="$WF_DIR/agent-overrides.yaml"
WF_MODEL_MAP="$WF_DIR/model-map"
WF_PROFILES="$WF_DIR/profiles"
WF_SPECS="$WF_DIR/specs"
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

# wf_norm_folder spec|initiative ARG : print ARG as the repo-relative folder `$WF_SPECS/NNN-slug` or
#   `$WF_INITIATIVES/NNN-slug`; status 1 when ARG is not one.
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
  # An absolute path may point into the main checkout or any worktree, so only its last two parts name the folder.
  if [[ "$folder" == /* ]]; then
    if [[ "$(dirname "$folder")" != */"$root" ]]; then
      printf '%s must be %s/NNN-slug: %s\n' "$label" "$root" "$arg" >&2
      return 1
    fi
    folder="$root/$(basename "$folder")"
  fi
  if ! [[ "$folder" == "$root"/* && "${folder#"$root"/}" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    printf '%s must be %s/NNN-slug: %s\n' "$label" "$root" "$arg" >&2
    return 1
  fi
  printf '%s\n' "$folder"
}
