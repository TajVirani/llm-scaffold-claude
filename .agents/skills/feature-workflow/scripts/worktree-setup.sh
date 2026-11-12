#!/usr/bin/env bash
# File: Helper script (not a hook): create, set up, check and remove the worktrees a spec runs in. Interface stub: every call
#   answers with a fixed placeholder and does no work yet.
# Purpose: One script makes every spec worktree, agent worktree and scratch worktree ready to build and test: it gives the spec a
#   slot, copies the project's gitignored files named in .worktreeinclude from the main checkout, runs the project's worktree_setup
#   command with the isolation values, and refuses a symlink that reaches back into the main checkout or another worktree.
# Usage:
#   worktree-setup.sh agent <name> <branch> [--cwd <dir>]    add (or reuse) the agent worktree <name> on <branch> off the spec branch
#   worktree-setup.sh scratch <name> [<commit>] [--cwd <dir>] add a detached worktree <name> at <commit> (default HEAD)
#   worktree-setup.sh setup <worktree path>                  set up a worktree that exists; safe to run again
#   worktree-setup.sh check <worktree path>                  the symlink check alone
#   worktree-setup.sh env <worktree path>                    print the isolation values of that worktree
#   worktree-setup.sh remove <name> [--force] [--cwd <dir>]  remove an agent or scratch worktree; --force only for a scratch one
# stdout: agent and scratch print `worktree <absolute path>`; env prints `export WF_SLOT=...`, `export WF_INSTANCE=...`,
#   `export WF_PORT_OFFSET=...`, `export WF_MAIN_ROOT=...` and `export WF_SPEC_ROOT=...`, one per line; remove prints
#   `removed worktree <path>`; setup and check print nothing. Progress and command output go to stderr.
# Exit: 0 done; 1 refused or a check failed, with the reason; 2 usage or environment error.
# Called by: scripts/spec-worktree.sh (create), scripts/run-toolchain.sh, the step files that create agent and scratch worktrees.
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

USAGE="usage: worktree-setup.sh agent|scratch|setup|check|env|remove ..."
PLACEHOLDER=PLACEHOLDER

case "${1:-}" in
  agent | scratch) echo "worktree $PLACEHOLDER" ;;
  setup | check) ;;
  env)
    for name in WF_SLOT WF_INSTANCE WF_PORT_OFFSET WF_MAIN_ROOT WF_SPEC_ROOT; do
      echo "export $name=$PLACEHOLDER"
    done
    ;;
  remove) echo "removed worktree $PLACEHOLDER" ;;
  -h | --help) echo "$USAGE" ;;
  *) echo "$USAGE" >&2; exit 2 ;;
esac
