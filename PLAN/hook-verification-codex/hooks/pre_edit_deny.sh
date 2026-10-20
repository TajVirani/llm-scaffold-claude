#!/bin/bash
# Deny any edit whose input mentions denyme.txt
H=__HOOKTEST_DIR__
IN=$(cat)
echo "$IN" | $H/hooks/log.sh PreToolUse-EditMatcher
if echo "$IN" | jq -e '.tool_input|tostring|test("denyme\\.txt")' >/dev/null; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"deny-hook blocked denyme"}}'
fi
exit 0
