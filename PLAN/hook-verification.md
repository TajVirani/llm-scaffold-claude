# Hook verification (Claude Code)

> Scaffold-only evidence for this repo. It is not part of the install payload (D30). The harness is in `PLAN/hook-verification/`.

## Tested version

- Claude Code 2.1.300 (`claude --version`), tested 2026-10-15, macOS
- Session model `haiku` (resolved `claude-haiku-5-5`). Two headless runs (`claude -p --permission-mode bypassPermissions`), about $0.07 in total (run 1 $0.063, run 2 $0.006)
- Scratch git repo. `.claude/settings.json` registers logging hooks for SessionStart, PreToolUse(`*`), PostToolUse(`*`), SubagentStart and SubagentStop. It also registers behaviour hooks for the T3–T6 tests. `.claude/skills` and `.claude/agents` are symlinks to directories outside the repo. One hook command uses the `"$CLAUDE_PROJECT_DIR"/...` form.

## Results

| Test | Result | Evidence |
|---|---|---|
| T1: skills and agents load through symlinked `.claude/skills` and `.claude/agents` | confirmed | The model listed `probe` among subagent_types and `probe-skill` among skills. `Agent(subagent_type:"probe")` ran, and SubagentStart showed `agent_type:"probe"` |
| T2: the launch tool is named `Agent` | confirmed | PreToolUse `tool_name:"Agent"`. `tool_input` = `{description, prompt, subagent_type, run_in_background}`. `isolation` and `model` appear only when set |
| T2: SubagentStart carries prompt, description or model | refuted | Keys are only `agent_id, agent_type, cwd, hook_event_name, prompt_id, session_id, transcript_path` (the parent's transcript) |
| T2: PreToolUse inside a subagent identifies the agent | confirmed | `agent_id:"aca9eeb423cf2df42"`, `agent_type:"probe"`. `transcript_path` is the parent's. Main-session events have no `agent_id` or `agent_type` keys |
| T2: SubagentStop fields | confirmed | `agent_type`, `last_assistant_message`, `agent_transcript_path` (`…/<session>/subagents/agent-<id>.jsonl`), `stop_hook_active`, `background_tasks`, `session_crons` |
| T3: SubagentStop `{"decision":"block","reason":…}` sends feedback to the subagent | confirmed | `probe2.txt` was written with `again`. The second SubagentStop had `stop_hook_active:true`. The reason reached the subagent as a user turn |
| T4: SubagentStart `additionalContext` reaches the subagent | confirmed | The subagent's final reply contained `SECRET-TOKEN-42`. It arrives as a system-reminder in the agent transcript |
| T5: PreToolUse `updatedInput` on `Agent` rewrites `prompt` and `model` | confirmed | PostToolUse `tool_input.prompt:"go Also say BANANA in your reply."` and `model:"sonnet"`. `tool_response.resolvedModel:"claude-sonnet-5-5"` on a haiku session, against `claude-haiku-5-5` in the control run without the rewrite. The reply contained BANANA |
| T6: Write has two PreToolUse hooks, one allow and one deny | confirmed: deny wins | `denyme.txt` was not created. Error: `PreToolUse:Write hook error: deny-hook blocked denyme`. The allow hook was registered first |
| T7: project hooks fire inside an `isolation:"worktree"` subagent | confirmed | All subagent events fired. Payload `cwd` and the hook's `pwd` = `<repo>/.claude/worktrees/agent-<id>`, but `$CLAUDE_PROJECT_DIR` = the main checkout. SubagentStart's `cwd` is already the worktree. The tool_response adds `worktreePath` and `worktreeBranch:"worktree-agent-<id>"` |
| T8: a `MultiEdit` tool exists | refuted | File-writing tools are `Edit`, `Write` and `NotebookEdit` |
| Bash `echo x > f` triggers a `Write\|Edit` matcher | refuted (as expected) | Only the `*` PreToolUse fired (`tool_name:"Bash"`), and the file was written |
| `"$CLAUDE_PROJECT_DIR"/...` in a hook command | confirmed | It resolved and ran in the main session, the subagent and the worktree subagent |

## Payload field lists (2.1.300)

- **PreToolUse(Agent)**, main session: `session_id, transcript_path, cwd, prompt_id, permission_mode, effort{level}, hook_event_name, tool_name, tool_input, tool_use_id`
  - `tool_input`: `description, prompt, subagent_type, run_in_background`, plus `isolation` and `model` when set
- **PreToolUse inside a subagent**: the fields above plus `agent_id, agent_type`
- **SubagentStart**: `session_id, transcript_path, cwd, prompt_id, agent_id, agent_type, hook_event_name`. It has no `tool_use_id`, prompt or model
- **SubagentStop**: `session_id, transcript_path, cwd, prompt_id, agent_id, agent_type, agent_transcript_path, last_assistant_message, stop_hook_active, background_tasks, session_crons, effort, permission_mode, hook_event_name`
- **PostToolUse(Agent)**: the PreToolUse fields plus `tool_response, duration_ms`. Inside a subagent, `agent_id` and `agent_type` are added
  - `tool_response` keys: `status, prompt, agentId, agentType, content, resolvedModel, totalDurationMs, totalTokens, totalToolUseCount, usage, toolStats, harnessNoteCount, harnessTailCount, harnessSectionHash`, plus `worktreePath, worktreeBranch, canContinueAgent` for worktree launches
  - `tool_input` shows the input after any `updatedInput` rewrite
  - Fires at launch, not at completion, for a background launch: `tool_response.status` is `"async_launched"` and the sub-agent has not run yet. In `-p` mode Claude Code 2.1.300 backgrounds Agent launches by default, even with no `run_in_background` (`PLAN/install-e2e.md` issue 3). Do not use PostToolUse(Agent) as a completion signal; SubagentStop is the one that fires after the sub-agent finishes
- **SessionStart**: `session_id, transcript_path, cwd, hook_event_name, source`

- **PostToolUse(Bash) skips non-zero exits (verified 2.1.303)**: a Bash call that exits non-zero is a tool error, and only `PostToolUseFailure` fires; `PostToolUse` does not. Throwaway repo, `claude -p --model haiku`, both events logged with matcher `Bash`, command `echo hi; exit 1`: one `PostToolUseFailure` entry, no `PostToolUse` entry.
  - **PostToolUseFailure payload**: `session_id, transcript_path, cwd, prompt_id, permission_mode, effort{level}, hook_event_name, tool_name, tool_input{command, description}, tool_use_id, error, is_interrupt, duration_ms`. `error` was `"Exit code 1\nhi"` (exit code plus output). There is no `tool_response`. The matcher is on tool name, as for PreToolUse. Docs: https://code.claude.com/docs/en/hooks, section "PostToolUseFailure" (fires when a tool that started executing fails; output `hookSpecificOutput.additionalContext`; `is_interrupt` and `duration_ms` optional).
  - Consequence: `evidence-capture.sh` is wired under both events (F-1, fixed). Codex differs: PostToolUse fires after non-zero exits there (`PLAN/hook-verification-codex.md` row 6), so Codex needs no failure event.

## Design implications

- **D13 (amended):** a PreToolUse hook on `Agent` can rewrite the launch (`prompt`, `model`) through `updatedInput`. Send the full input object. Since 2.1.300, unknown keys are dropped, and input the tool rejects denies the call.
- **D16:** guards can tell subagent tool calls apart through `agent_id` and `agent_type`, and can deny subagent writes. When hooks disagree, deny wins.
- **D18:** in worktrees, hooks should use the payload's `cwd`, not `$CLAUDE_PROJECT_DIR`. The variable still points at the main checkout.
- **D19:** a SubagentStop `decision:"block"` works. Check `stop_hook_active` to avoid loops. `last_assistant_message` and `agent_transcript_path` are available for checks.
- **Matchers:** use `Write|Edit|NotebookEdit` for file-write guards. There is no `MultiEdit` tool.
- **Bash bypasses Write/Edit guards.** Shell writes need permission deny rules, or a separate `Bash` matcher.
- **Launch metadata:** SubagentStart has no prompt or model. A hook that needs them must capture them in PreToolUse(Agent).
- **Symlinks:** symlinked `.claude/skills` and `.claude/agents` load, but this is undocumented. Re-check it on every upgrade (see the 2.1.284 entry below).

## Citations

- Hooks reference (`hooks.md`): common input fields and the SubagentStart event, https://code.claude.com/docs/en/hooks. This page was not re-fetched for this run. The payloads above are what 2.1.300 actually emitted.
- Local `~/.claude/cache/changelog.md` (both entries checked):
  - 2.1.300: "Changed hooks: `updatedInput` from PreToolUse and PermissionRequest hooks is now validated like Claude's own input: unknown keys are dropped, and input the tool rejects denies the call"
  - 2.1.284: "…a `.claude` directory symlinked from outside the project now asks for the same approval" (the external-imports approval). This run used `bypassPermissions` and only symlinked subdirectories, so no prompt was observed.

## Re-run on upgrade

Run this after every Claude Code upgrade, and before relying on any decision above:

```bash
PLAN/hook-verification/run.sh          # optional arg: model alias (default haiku)
```

The script recreates the scratch repo in a fresh temp directory and runs both headless runs (about $0.07 on haiku). It then prints the key sets for each event, the Agent launch input and `resolvedModel`, the SubagentStop messages, the subagent `cwd` against `$CLAUDE_PROJECT_DIR`, and which tools hit the Write/Edit matcher. Compare the output with the tables above and with `PLAN/hook-verification/RESULTS.md`. Update this file with the new version, date and any changed fields. The full `log.jsonl` stays in the temp directory and is not committed, because it contains session IDs and home paths.

Requires `claude`, `jq` and `git`. The runs use `--permission-mode bypassPermissions`, limited to the temp repo.
