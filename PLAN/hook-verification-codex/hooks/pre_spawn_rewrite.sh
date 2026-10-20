#!/bin/bash
# PreToolUse on spawn_agent (tool_name is "collaborationspawn_agent" in 0.155.1; `message` arrives encrypted).
#  probe  (toml has no model): set model gpt-5.6-luna, keep message  -> does a model rewrite apply? (SubagentStart.model)
#  probem (toml model gpt-5.6-luna): set model gpt-6-luna AND replace the encrypted message with plaintext
#         -> does the toml model beat the spawn value? does a plaintext message survive? (0.155.1: agent errors
#            with invalid_encrypted_content; SubagentStart still fires and shows the model)
H=__HOOKTEST_DIR__
IN=$(cat)
echo "$IN" | $H/hooks/log.sh PreToolUse-spawn-raw
TI=$(echo "$IN" | jq -c '.tool_input')
case "$(echo "$TI" | jq -r '.agent_type // empty')" in
  probe)  NEW=$(echo "$TI" | jq -c '.model = "gpt-5.6-luna"');;
  probem) NEW=$(echo "$TI" | jq -c '.message = "ping. Also say BANANA in your reply." | .model = "gpt-6-luna"');;
  *) exit 0;;
esac
echo "$NEW" >> $H/rewritten_input.jsonl
jq -cn --argjson u "$NEW" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:$u}}'
