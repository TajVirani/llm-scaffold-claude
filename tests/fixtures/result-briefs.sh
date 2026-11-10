#!/usr/bin/env bash
# File: Reader for the result-file path the implementation and integration agent docs prescribe, shared by the worktree-guard
#   suite (which sends a Write to it through the guard), the spec-worktree suite and the orchestrator-docs lint (which checks
#   where it points). Read from the doc on each run, so a changed brief is tested as written. Sourced after lib/common.sh;
#   defines functions only. bash 3.2 compatible.
# Provides:
#   brief_result_path DOC FILE_NAME   prints the line of DOC's text block that ends in /FILE_NAME (the absolute path the agent
#                                     gives the Write tool, with its placeholders); prints nothing when there is none

brief_result_path() {
  awk -v name="/$2" '
    /^```text/ { inblock = 1; next }
    inblock && /^```/ { inblock = 0; next }
    inblock && length($0) >= length(name) && substr($0, length($0) - length(name) + 1) == name { print; exit }' "$1"
}
