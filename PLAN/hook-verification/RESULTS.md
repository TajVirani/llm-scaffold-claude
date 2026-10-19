# Claude Code 2.1.300 hook verification (2 headless runs, haiku, ~$0.07 total)

> Scaffold-only; excluded from install payload (D30). Summary doc: ../hook-verification.md

Raw run outputs and log.jsonl are not kept here (they contain session IDs and home paths); `run.sh` regenerates them in a temp dir.
Hooks: hooks/*.sh, settings: settings.template.json (paths substituted by run.sh). Probe definitions: probe/.

| Test | Result | Evidence |
|---|---|---|
| T1 symlinked .claude/skills + .claude/agents discovered | confirmed | model listed `probe` among subagent_types and `probe-skill` among skills; Agent(subagent_type=probe) ran, SubagentStart agent_type="probe" |
| T2 launch tool name | confirmed `Agent` | PreToolUse tool_name="Agent"; tool_input={description,prompt,subagent_type,run_in_background[,isolation][,model]} (optional fields only present when set) |
| T2 SubagentStart payload | no prompt/description/model | keys: agent_id, agent_type, cwd, hook_event_name, prompt_id, session_id, transcript_path (transcript_path = PARENT transcript) |
| T2 PreToolUse inside subagent | confirmed agent_id/agent_type present | agent_id="aca9eeb423cf2df42", agent_type="probe"; transcript_path = parent transcript; main-session events have no agent_id/agent_type keys |
| T2 SubagentStop payload | confirmed | agent_type, last_assistant_message, agent_transcript_path (.../<session>/subagents/agent-<id>.jsonl), stop_hook_active, background_tasks, session_crons, effort, permission_mode |
| T3 SubagentStop block feedback | confirmed | probe2.txt = "again"; 2nd SubagentStop has stop_hook_active=true; reason delivered to subagent as a user turn |
| T4 SubagentStart additionalContext | confirmed | subagent final: "DONE. BANANA. SECRET-TOKEN-42"; injected as system-reminder in agent transcript |
| T5 PreToolUse updatedInput on Agent (prompt + model) | confirmed | PostToolUse tool_input.prompt="go Also say BANANA in your reply.", model="sonnet"; tool_response.resolvedModel="claude-sonnet-5-5" (session on haiku; run2 without rewrite -> resolvedModel "claude-haiku-5-5"); reply contained BANANA |
| T6 two PreToolUse hooks on Write, allow + deny | confirmed deny wins | denyme.txt not created; tool error "PreToolUse:Write hook error: deny-hook blocked denyme" (allow hook listed first) |
| T7 worktree subagent | hooks fire; cwd = worktree; CLAUDE_PROJECT_DIR = main repo | Agent tool_input.isolation="worktree"; subagent PreToolUse/PostToolUse/SubagentStart/SubagentStop all fired; input.cwd and hook pwd = proj/.claude/worktrees/agent-a782f2857175742e1; env CLAUDE_PROJECT_DIR = proj (main checkout). SubagentStart's cwd is already the worktree. tool_response adds worktreePath, worktreeBranch="worktree-agent-<id>". "$CLAUDE_PROJECT_DIR"/... command form resolved and ran in all contexts |
| T8 MultiEdit exists | refuted | tool list has Edit, Write, NotebookEdit; no MultiEdit |
| Bash `echo x > f` triggers matcher Write\|Edit | refuted (as expected) | only PreToolUse tool_name="Bash" fired (matcher *); Write\|Edit hook didn't log; bashwrite.txt created |

## Exact field lists
- PreToolUse(Agent), main session: session_id, transcript_path, cwd, prompt_id, permission_mode, effort{level}, hook_event_name, tool_name, tool_input, tool_use_id
- SubagentStart: session_id, transcript_path, cwd, prompt_id, agent_id, agent_type, hook_event_name
- PreToolUse inside subagent: the PreToolUse fields above + agent_id, agent_type
- SubagentStop: session_id, transcript_path, cwd, prompt_id, agent_id, agent_type, agent_transcript_path, last_assistant_message, stop_hook_active, background_tasks, session_crons, effort, permission_mode, hook_event_name
- PostToolUse: PreToolUse fields + tool_response, duration_ms (+agent_id/agent_type inside subagent). PostToolUse(Agent).tool_response: status, prompt, agentId, agentType, content, resolvedModel, totalDurationMs, totalTokens, totalToolUseCount, usage, toolStats, [worktreePath, worktreeBranch, canContinueAgent]
- SessionStart: session_id, transcript_path, cwd, hook_event_name, source
