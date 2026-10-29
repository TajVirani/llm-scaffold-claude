#!/usr/bin/env bash
# File: Reader for the result-file command the implementation and integration agent docs prescribe, shared by the worktree-guard
#   suite (which runs the command) and the orchestrator-docs lint (which checks where it writes). Read from the doc on each run,
#   so a changed brief is tested as written. Sourced after lib/common.sh; defines functions only. bash 3.2 compatible.
# Provides:
#   brief_result_command DOC FILE_NAME   prints the command in DOC's bash block that writes FILE_NAME, from the block's first line
#                                        through the line that opens the heredoc; prints nothing when there is none
#   brief_result_target COMMAND          prints the path COMMAND's `cat >` writes to, quotes removed

brief_result_command() {
  awk -v name="$2" '
    /^```bash/ { inblock = 1; buf = ""; next }
    inblock && /^```/ { inblock = 0; next }
    inblock {
      buf = (buf == "" ? $0 : buf "\n" $0)
      if (index($0, "<<") && index(buf, name)) { print buf; exit }
    }' "$1"
}

brief_result_target() {
  local re='cat[[:space:]]+>[[:space:]]*("([^"]+)"|([^[:space:]]+))'
  if [[ "$1" =~ $re ]]; then printf '%s\n' "${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; fi
}
