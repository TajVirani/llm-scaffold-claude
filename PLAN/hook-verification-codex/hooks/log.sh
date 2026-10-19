#!/bin/bash
# usage: log.sh EVENT [TAG]  -- appends {event,tag,hook_pwd,env,input} to $H/log.jsonl
H=__HOOKTEST_DIR__
IN=$(cat)
NAMES=$(env | sed 's/=.*//' | grep -vE '^(CLAUDE|_$)' | sort -u | jq -Rn '[inputs]')
ENVJ=$(env | grep -E '^(CODEX[A-Z_]*|[A-Z_]*PROJECT_DIR[A-Z_]*|PWD)=' | sed 's/^\([^=]*\)=.*/\1/' | sort | while read k; do printf '%s\t%s\n' "$k" "${!k}"; done | jq -Rn '[inputs|split("\t")|{(.[0]):.[1]}]|add // {}')
echo "$IN" | jq -c --arg ev "$1" --arg tag "${2:-abs}" --arg pwd "$(pwd)" --argjson env "$ENVJ" --argjson names "$NAMES" \
  '{event:$ev, tag:$tag, hook_pwd:$pwd, env:$env, env_names:$names, input:.}' >> $H/log.jsonl 2>>$H/hook-errors.log \
  || jq -cn --arg ev "$1" --arg raw "$IN" '{event:$ev, raw:$raw}' >> $H/log.jsonl
exit 0
