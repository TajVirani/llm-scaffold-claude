#!/usr/bin/env bash
# File: Sourced helper (not a hook, not executable on its own): the one home for where workflow data lives in a target project (D81).
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
#   wf_path <root> <rel>   prints <root>/<rel> (root's trailing slash dropped); e.g. wf_path "$ROOT" "$WF_SPECS"
# Paths are repo-relative; the write guards compare them case-insensitively.
# Plan refs: assetlist D81 (target-project path map).
# Sources: first-party.
# shellcheck disable=SC2034 # the variables are the API; each sourcing script uses a subset

WF_DIR=".workflow"

WF_GLOSSARY="$WF_DIR/GLOSSARY.md"
WF_GLOSSARY_MAP="$WF_DIR/GLOSSARY-MAP.md"
WF_AGENT_OVERRIDES="$WF_DIR/agent-overrides.yaml"
WF_MODEL_MAP="$WF_DIR/model-map"
WF_PROFILES="$WF_DIR/profiles"
WF_SPECS="$WF_DIR/specs"
WF_WORK_BACKLOG="$WF_SPECS/work-backlog"
WF_DEFERRED="$WF_DIR/deferred"
WF_RULES="$WF_DIR/rules.md"
WF_CAPABILITIES="$WF_DIR/capabilities.md"
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
