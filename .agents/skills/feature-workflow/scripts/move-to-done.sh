#!/usr/bin/env bash
# File: Helper script (not a hook): check that a finished spec and its sub-items are closed, and move it into the Done folder.
# Purpose: Interface only for now: it accepts the three call forms below, changes nothing and exits 0. The check, the move, the
#   path rewrite and the sweep are built by the feature that owns this script.
# Usage:
#   move-to-done.sh --check <spec-dir>   check only: the task records and the work-backlog items from the spec are closed
#   move-to-done.sh <spec-dir>           check, then move the done spec into the Done folder, rewrite its path, commit
#   move-to-done.sh --sweep              move every done spec at the top level of the specs folder
#     <spec-dir>  the spec folder, relative to the project root.
# Exit: 0 always (no behaviour yet).
# Called by: modules/sign-off.md (5.7 check, 5.8 move), by hand for a one-off sweep.
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

exit 0
