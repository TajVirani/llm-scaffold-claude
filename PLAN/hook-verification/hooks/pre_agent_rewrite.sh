#!/bin/bash
H=__HOOKTEST_DIR__
IN=$(cat)
[ -f $H/no_rewrite ] && exit 0
NEW=$(echo "$IN" | jq -c '.tool_input | .prompt = (.prompt + " Also say BANANA in your reply.") | .model = "sonnet"')
echo "$NEW" > $H/rewritten_input.json
jq -cn --argjson u "$NEW" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:$u}}'
exit 0
