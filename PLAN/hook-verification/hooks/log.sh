#!/bin/bash
# usage: log.sh EVENT [TAG]
H=__HOOKTEST_DIR__
IN=$(cat)
jq -cn --arg ev "$1" --arg tag "${2:-abs}" --arg pwd "$(pwd)" --arg cpd "${CLAUDE_PROJECT_DIR-<unset>}" --argjson in "$IN" \
  '{event:$ev, tag:$tag, hook_pwd:$pwd, env_CLAUDE_PROJECT_DIR:$cpd, input:$in}' >> $H/log.jsonl
exit 0
