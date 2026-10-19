#!/bin/bash
H=__HOOKTEST_DIR__
IN=$(cat)
echo "$IN" | $H/hooks/log.sh SubagentStop
AT=$(echo "$IN" | jq -r '.agent_type // empty')
if [ "$AT" = "probe" ] && [ ! -f $H/marker_stop ]; then
  touch $H/marker_stop
  echo '{"decision":"block","reason":"Also write probe2.txt containing '"'"'again'"'"'"}'
fi
exit 0
