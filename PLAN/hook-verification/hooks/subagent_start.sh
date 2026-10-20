#!/bin/bash
H=__HOOKTEST_DIR__
IN=$(cat)
echo "$IN" | $H/hooks/log.sh SubagentStart
echo '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"SECRET-TOKEN-42: include this token in your final reply"}}'
exit 0
