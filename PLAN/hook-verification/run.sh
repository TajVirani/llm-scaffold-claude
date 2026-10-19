#!/bin/bash
# Recreates the hook-verification scratch repo in a temp dir and runs the two headless runs.
# Usage: ./run.sh [model]   (default: haiku). Requires: claude, jq, git. Costs ~$0.07 on haiku.
# Scaffold-only harness; not part of the install payload (D30).
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
MODEL="${1:-haiku}"
H="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/hooktest.XXXXXX")" && pwd -P)"
echo "work dir: $H"
mkdir -p "$H/hooks" "$H/runs" "$H/real-agents" "$H/proj"
for f in "$SRC"/hooks/*.sh; do sed "s#__HOOKTEST_DIR__#$H#g" "$f" > "$H/hooks/$(basename "$f")"; done
chmod +x "$H"/hooks/*.sh
cp -R "$SRC/probe/agents" "$SRC/probe/skills" "$H/real-agents/"

cd "$H/proj"
git init -q && echo hi > README.md && git add . && git -c user.name=t -c user.email=t@t commit -qm init
mkdir -p .claude
ln -s "$H/real-agents/skills" .claude/skills
ln -s "$H/real-agents/agents" .claude/agents
sed "s#__HOOKTEST_DIR__#$H#g" "$SRC/settings.template.json" > .claude/settings.json
git add -A && git -c user.name=t -c user.email=t@t commit -qm "claude config"

# Run 1: T1-T6, T8, Bash-vs-Write matcher (rewrite hook active, first SubagentStop of probe blocked)
claude -p --model "$MODEL" --max-turns 12 --permission-mode bypassPermissions --output-format json \
  "Do these steps in order: 1) Use the Agent tool with subagent_type 'probe', description 'probe run', prompt 'go'. Report its final reply verbatim. 2) Use the Write tool to write denyme.txt containing 'x'. 3) Run Bash: echo x > bashwrite.txt 4) Finally, list (a) every tool name you have, exactly, comma-separated, (b) every skill name available to you, (c) every agent subagent_type available to you." \
  > "$H/runs/run1.json" 2> "$H/runs/run1.err"

# Run 2: T7 worktree (rewrite disabled; SubagentStop marker already set, so no block)
touch "$H/no_rewrite"
claude -p --model "$MODEL" --max-turns 6 --permission-mode bypassPermissions --output-format json \
  "Use the Agent tool with subagent_type 'probe', description 'probe wt', prompt 'go', and isolation set to \"worktree\" (you must pass isolation: \"worktree\"). Then report its final reply verbatim and any worktree path/branch the tool result mentions." \
  > "$H/runs/run2.json" 2> "$H/runs/run2.err"

L="$H/log.jsonl"
echo "== files in proj (expect probe.txt=hi, probe2.txt=again, bashwrite.txt, NO denyme.txt)"
for f in probe.txt probe2.txt bashwrite.txt denyme.txt; do printf '%s: ' "$f"; cat "$H/proj/$f" 2>/dev/null || echo MISSING; done
echo "== cost"; jq -r '.total_cost_usd' "$H"/runs/run*.json
echo "== keys per event"
jq -c 'select(.event|test("^(PreToolUse|PostToolUse|SubagentStart|SubagentStop|SessionStart)$")) | {event, sub:(.input.agent_id!=null), keys:(.input|keys)}' "$L" | sort -u
echo "== Agent launches (tool_input as seen by PostToolUse, resolvedModel, worktree)"
jq -c 'select(.event=="PostToolUse" and .input.tool_name=="Agent") | {tool_input:.input.tool_input, resolvedModel:.input.tool_response.resolvedModel, worktreePath:.input.tool_response.worktreePath}' "$L"
echo "== SubagentStop (stop_hook_active, last message)"
jq -c 'select(.event=="SubagentStop") | {stop_hook_active:.input.stop_hook_active, msg:.input.last_assistant_message[0:120]}' "$L"
echo "== subagent cwd / hook pwd / CLAUDE_PROJECT_DIR"
jq -c 'select(.input.agent_id!=null) | [.event, .input.cwd, .hook_pwd, .env_CLAUDE_PROJECT_DIR]' "$L" | sort -u
echo "== Write|Edit matcher hits by tool (expect no Bash)"
jq -r 'select(.event=="PreToolUse-WriteEditMatcher") | .input.tool_name' "$L" | sort | uniq -c
echo "== MultiEdit mentioned in run1 tool list?"; jq -r '.result' "$H/runs/run1.json" | grep -c MultiEdit || true
echo "Full log: $L"
