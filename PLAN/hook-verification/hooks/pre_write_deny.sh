#!/bin/bash
H=__HOOKTEST_DIR__
IN=$(cat)
echo "$IN" | $H/hooks/log.sh PreToolUse-WriteEditMatcher
FP=$(echo "$IN" | jq -r '.tool_input.file_path // empty')
case "$FP" in *denyme.txt) echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"deny-hook blocked denyme"}}';; esac
exit 0
