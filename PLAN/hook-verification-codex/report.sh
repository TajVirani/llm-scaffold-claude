#!/bin/bash
# Summarise a run. Usage: report.sh <work-dir>
H="$1"; L="$H/log.jsonl"; P="$H/proj"
s() { sed "s#$H#\$H#g; s#$HOME#~#g"; }
echo "== preflight: skills listed / permission profile"
jq -r '..|strings' "$H/runs/prompt-input.json" 2>/dev/null | grep -E "^- (probe-skill|direct-skill):" | sed "s/ (file.*//"
jq -r '..|strings' "$H/runs/prompt-input.json" 2>/dev/null | grep -oE "<entry access=\"[a-z]+\"><path>[^<]*docs/cache</path>" | s
echo "== files (expect probe.txt=hi, probe2.txt=again; NO denyme.txt, docs/cache/a.txt, docs/cache/b.txt)"
for f in probe.txt probe2.txt denyme.txt docs/cache/a.txt docs/cache/b.txt; do printf '%s: ' "$f"; cat "$P/$f" 2>/dev/null | tr '\n' ' ' || printf MISSING; echo; done
echo "== usage"; jq -c 'select(.type=="turn.completed")|.usage' "$H/runs/run1.jsonl"
echo "== events: key sets (sub = has agent_id)"
jq -c 'select(.input)|{event, tool:.input.tool_name, sub:(.input.agent_id!=null), keys:(.input|keys)}' "$L" | sort -u
echo "== spawn_agent raw tool_input / rewritten / PostToolUse view"
jq -c 'select(.event=="PreToolUse-spawn-raw")|.input.tool_input' "$L"; cat "$H/rewritten_input.jsonl" 2>/dev/null
jq -c 'select(.event=="PostToolUse" and (.input.tool_name|test("spawn")))|{tool_input:.input.tool_input, resp:(.input.tool_response|tostring|.[0:300])}' "$L"
echo "== models seen per agent"; jq -c 'select(.input)|[.event,(.input.agent_type//"main"),.input.model]' "$L" | sort -u
echo "== SubagentStart / SubagentStop"
jq -c 'select(.event=="SubagentStart")|.input|del(.session_id)' "$L" | s
jq -c 'select(.event=="SubagentStop")|.input|{agent_type,stop_hook_active,agent_transcript_path,msg:(.last_assistant_message//""|.[0:150])}' "$L" | s
for t in $(jq -r 'select(.event=="SubagentStop")|.input.agent_transcript_path//empty' "$L" | sort -u); do
  printf 'transcript %s exists=%s SECRET=%s BANANA=%s\n' "$(echo $t|s)" "$([ -f "$t" ] && echo y || echo n)" "$(grep -c SECRET-TOKEN-42 "$t" 2>/dev/null)" "$(grep -c BANANA "$t" 2>/dev/null)"; done
echo "== matcher probes (M-* spawn matchers, ShellMatcher)"; jq -c 'select(.event|test("^M-|ShellMatcher"))|[.event,.input.tool_name]' "$L"
echo "== edit-matcher hits"; jq -c 'select(.event=="PreToolUse-EditMatcher")|[.input.tool_name,(.input.agent_type//"main"),(.input.tool_input|tostring|.[0:120])]' "$L"
echo "== PostToolUse shell"; jq -c 'select(.event=="PostToolUse" and (.input.tool_name|test("Bash|shell|exec")))|{tool:.input.tool_name, ti:.input.tool_input, tr:(.input.tool_response|tostring|.[0:300])}' "$L" | s
echo "== cwd / hook pwd / env per agent"; jq -c 'select(.input)|[(.input.agent_type//"main"),.input.cwd,.hook_pwd,.env]' "$L" | sort -u | s
echo "== final message"; s < "$H/runs/run1.last.txt"
echo "== models (list)"; tr '\n' ' ' < "$H/runs/models.txt"; echo
