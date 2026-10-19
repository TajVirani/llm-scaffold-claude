# Hook verification (Codex CLI)

> Scaffold-only evidence for this repo. It is not part of the install payload (D30). The harness is in `PLAN/hook-verification-codex/`. Claude Code results: `PLAN/hook-verification.md`.

## Tested version

- `codex-cli 0.155.1` (npm, macOS arm64), tested 2026-10-16, logged in with ChatGPT.
- Session model `gpt-6-luna` (the cheap tier from G8), with `model_reasoning_effort` low in run 1 and medium in runs 2 and 3. Subagent models came from the probes: `gpt-5.6-luna` and `gpt-6-luna`.
- **Cost:** the ChatGPT plan's usage. No dollar amount is billed. Main-thread `turn.completed` usage per run:

  | Run | Input tokens | Cached | Output tokens |
  |---|---|---|---|
  | 1 | 140.6k | 91.9k | 655 |
  | 2 | 166.8k | 148.0k | 2,532 |
  | 3 | 141.8k | 108.2k | 1,319 (617 of them reasoning) |

  Each subagent thread logs its own usage in its transcript, about 17k–51k input tokens. Free checks with no model call: `codex debug models`, `codex debug prompt-input`, `codex sandbox`.
- **Setup.** Each run used a fresh scratch git repo containing:
  - `.agents/skills/probe-skill`, a **symlink** to a directory outside the repo, plus a non-symlinked `direct-skill`;
  - `.codex/agents/probe.toml` (no `model`) and `.codex/agents/probem.toml` (`model = "gpt-5.6-luna"`);
  - `.codex/hooks.json`;
  - `.codex/config.toml` with a permissions profile.
- **Flags:** `codex exec --dangerously-bypass-hook-trust`, plus an in-memory trust override `-c 'projects={"<repo>"={trust_level="trusted"}}'`. The dotted form `projects."<path>".trust_level` did **not** load the project layer. `-c approval_policy="never"` was also set. `~/.codex/config.toml` was not edited.
- Three headless runs. Run 1: a nested sandbox broke shell calls, and the spawn matcher missed. Run 2: the spawn matcher still missed, and the shell broke because the profile lacked `extends`. Run 3: everything fired. The results below combine all three runs. Each row names the run it comes from.

## Results

| # | Test | Result | Evidence |
|---|---|---|---|
| 1 | Skills discovered from `.agents/skills`, including a symlinked dir | confirmed | `codex debug prompt-input` lists `- probe-skill: Test probe skill…` (symlinked) and `- direct-skill: …` under `<skills_instructions>` |
| 2a | Custom agent loads from `.codex/agents/*.toml` | confirmed | `spawn_agent{agent_type:"probe"}` and `{agent_type:"probem"}` were accepted. The probe's `developer_instructions` show up as a developer message in its transcript. `probem` replied `PONG` |
| 2b | The toml `model` field applies | confirmed | SubagentStart `model:"gpt-5.6-luna"` for `probem`, against the parent's `gpt-6-luna` (all 3 runs) |
| 2c | The toml `model` beats a spawn-time `model` | confirmed | Run 3: the hook set `probem` `model:"gpt-6-luna"` through `updatedInput`, and PostToolUse showed it. SubagentStart still reported `gpt-5.6-luna` |
| 3a | PreToolUse fires on spawn: tool name and matcher | confirmed, with caveats | `tool_name:"collaborationspawn_agent"` (namespace `collaboration` + `spawn_agent`, joined with no separator). Matching is a **full match**. These matchers fired: `.*`, `.*spawn_agent`, `collaborationspawn_agent`. These did **not** fire: `spawn_agent`, `^spawn_agent$`, `^Agent$`, `^collaboration\.spawn_agent$`. The documented "`spawn_agent` also matches `Agent`" does not hold in 0.155.1 |
| 3b | spawn `tool_input` fields | observed | `agent_type, message, task_name`, plus `fork_turns:"all"` (run 3) and `model` when set. **`message` arrives encrypted** (`"gAAAAA…"` Fernet-style ciphertext) |
| 3c | `updatedInput` rewrites the `model` | confirmed | Run 3: `probe` (no toml model) got `model:"gpt-5.6-luna"`. SubagentStart showed `model:"gpt-5.6-luna"`, and the PostToolUse `tool_input` shows the rewritten input |
| 3d | `updatedInput` rewrites the `message` (prompt) | refuted | Run 3: replacing the ciphertext with plaintext was accepted by the hook layer. The subagent then failed: `invalid_encrypted_content … Encrypted content could not be decrypted or parsed` (HTTP 400). The message can't be edited, because it isn't readable |
| 4a | SubagentStart payload | confirmed | `agent_id, agent_type, cwd, hook_event_name, model, permission_mode, session_id, transcript_path, turn_id`. There is no message or task_name. `transcript_path` = the subagent's own rollout file |
| 4b | SubagentStart `additionalContext` reaches the subagent | delivered, but not acted on | `SECRET-TOKEN-42…` appears as a developer message in every subagent transcript. Luna never echoed it (a model-compliance issue, not a delivery one) |
| 4c | SubagentStop payload and `agent_transcript_path` | confirmed | `agent_transcript_path` = `~/.codex/sessions/YYYY/MM/DD/rollout-…-<agent_id>.jsonl` and exists. It also has `last_assistant_message`, `stop_hook_active` and `turn_id` |
| 4d | SubagentStop `{"decision":"block","reason":…}` sends feedback | confirmed | Run 2: `probe2.txt` = `again`. The second SubagentStop had `stop_hook_active:true`. The transcript has a `HookPrompt` item carrying the reason. In run 1 the reason was delivered, but luna at low effort ignored it |
| 4e | The launch message is readable in `agent_transcript_path` (needed for D39) | refuted | The task shows up as `agent_message` → `{"type":"encrypted_content",…}`. The first `role:"user"` message in the subagent transcript is the **parent's** prompt, because the transcript is a fork that carries parent history (`forked_from_id`). There is no plaintext copy in `event_msg` either |
| 5a | File-edit tool name in hooks | confirmed: `apply_patch` | `tool_input:{command:"*** Begin Patch\n*** Add File: probe.txt\n+hi\n*** End Patch"}`. It fires for the main session and for subagents (with `agent_id` and `agent_type`) |
| 5b | PreToolUse deny on `apply_patch` (allow and deny hooks both registered) | confirmed: deny wins | `denyme.txt` was not created. Log: `Command blocked by PreToolUse hook: deny-hook blocked denyme` (all 3 runs) |
| 6 | PostToolUse on shell | confirmed | Hook `tool_name:"Bash"` (the model-side tool is `exec_command`). `tool_input:{command}`. `tool_response` is a **plain string** of the output (`"x\n"`) with no exit-code field. It fires after non-zero exits (`exit 3`, and exit 1 from a sandbox denial) |
| 7a | Permissions profile `"docs/cache" = "read"` blocks `apply_patch` | confirmed | Run 3: `patch rejected: writing outside of the project; rejected by user approval settings`. With `approval_policy="never"`, a policy that can escalate might ask instead |
| 7b | The same profile blocks shell writes | confirmed | Run 3: `zsh:1: operation not permitted: docs/cache/b.txt`. Normal writes in the workspace succeeded (checked with `codex sandbox`) |
| 7c | Profile syntax | caveat | A profile that has only `[permissions.<p>.filesystem.":workspace_roots"]` entries gets no system read access, so **every sandboxed shell aborts with exit 134**. Run 2 hit this. Fix: `extends = ":workspace"`. `":root" = "read"` also works |
| 8 | cwd and project-dir env var seen by hooks | observed | Payload `cwd` = hook `pwd` = the session cwd (repo root), in the main session and in subagents. **There is no project-dir env var** (no `CODEX_PROJECT_DIR`, and no `CLAUDE_PROJECT_DIR`). The only `CODEX_*` vars are `CODEX_MANAGED_BY_NPM` and `CODEX_MANAGED_PACKAGE_ROOT`. Not tested: worktree subagents (`spawn_agent` has no isolation argument) |
| 9 | Model names | confirmed | `codex debug models` list-visibility slugs: `gpt-6-astra, gpt-6-sol, gpt-6-luna, gpt-5.6-sol, gpt-5.6-terra, gpt-5.6-luna`. Both G8 picks (`gpt-6-luna`, `gpt-6-sol`) are present. `gpt-6.1-sol` is still absent |

## Payload field lists (0.155.1)

- **Fields every event shares:** `session_id` (the parent's, even in subagent hooks), `transcript_path`, `cwd`, `hook_event_name`, `model`, `permission_mode`. The model value is per agent: inside a subagent it is the subagent's model.
- **PreToolUse**, main session: common fields + `turn_id, tool_name, tool_input, tool_use_id`
  - For `collaborationspawn_agent`, `tool_input` = `agent_type, message` (encrypted), `task_name`, plus `fork_turns` and `model` when set
- **PreToolUse inside a subagent:** the fields above + `agent_id, agent_type`
- **PostToolUse:** the PreToolUse fields + `tool_response`
  - spawn: `"{\"task_name\":\"/root/<name>\"}"`
  - wait: `"{\"message\":\"Wait completed.\",\"timed_out\":false}"`
  - `Bash`: the output string
  - `apply_patch`: `"Exit code: 0\nWall time: …\nOutput:\nSuccess. Updated the following files:\nA probe.txt\n"`
- **SubagentStart:** common fields + `turn_id, agent_id, agent_type`. There is no message, task_name or `tool_use_id`
- **SubagentStop:** common fields + `turn_id, agent_id, agent_type, agent_transcript_path, last_assistant_message, stop_hook_active`
- **Stop:** common fields + `turn_id, last_assistant_message, stop_hook_active`
- **SessionStart:** common fields + `source` (`"startup"`). It has no `turn_id`

## Design implications

- **D9 / D40: what to wire in `.codex/hooks.json`.** Wire these events, because they behave like Claude's:
  - PreToolUse deny on `apply_patch`, for write guards;
  - PostToolUse on `Bash`, for evidence capture;
  - SubagentStop block-with-reason, for audit feedback;
  - SubagentStart `additionalContext`;
  - SessionStart.

  Matchers are full-match regexes on the hook-side name: `apply_patch`, `Bash`, and `.*spawn_agent` (not `Agent` or `spawn_agent`). Real use still needs project trust and a `/hooks` review. `--dangerously-bypass-hook-trust` is for automation only.
- **D35: the generated `.codex/agents/<name>.toml` `model` is authoritative.**
  - A toml `model` beats a spawn-time value, including one set through `updatedInput`.
  - A per-launch `updatedInput` model rewrite works only for agents whose toml has no `model`.
  - So write the resolved model at install or setup time, as G8 recommends.
- **D39: header-from-transcript does not work on Codex.**
  - The launch message is encrypted, both in PreToolUse `tool_input.message` and in `agent_transcript_path`.
  - The subagent transcript's first user message is the parent's forked prompt.
  - The only plaintext launch fields are `agent_type`, `task_name` and `model`.
  - Options: carry the task id in `task_name`, which the model chooses but which is plaintext and returned as `/root/<task_name>`; or keep the Codex audit advisory (the orchestrator runs `run-toolchain.sh`).
- **D40: profile injection.** It cannot rewrite the launch prompt, because `message` is opaque and a rewrite breaks the spawn. Inject the profile through SubagentStart `additionalContext` instead, which arrives as a developer message, or through the toml `developer_instructions`. `resolve-launch.sh` can still validate `agent_type`/`model` in PreToolUse and deny the call.
- **D55:** a Codex `post-implementation-audit` hook would always hit the "header or transcript error → warning" branch under D39 as written. That makes it warn-only on Codex, unless the task lookup moves to `task_name`. SubagentStop blocking itself works, so blocking on a `run-toolchain.sh` failure is possible once the task is found.
- **Hard write limits:**
  - A permissions profile (`extends = ":workspace"` plus `"docs/cache" = "read"`) blocks both `apply_patch` and shell writes. That gives a real Tier B limit for plain subpaths.
  - The `.step` globs stay advisory, because glob portability is limited (see G7).
  - Shell writes are covered by the sandbox, not by hooks: the `apply_patch` PreToolUse does not see `Bash`.
- **Project dir:** use the payload `cwd`. Codex sets no project-dir env var. Hooks run with `pwd` = the session cwd.

## Citations

These docs pages are cited from `PLAN/gap-research.md` (fetched 2026-10-15) and were not re-fetched for this run. Where they disagree with 0.155.1, the observed behaviour above wins.

- https://learn.chatgpt.com/docs/hooks covers the events, input fields, `updatedInput`, SubagentStop block, and the statement "`spawn_agent` also matches `Agent`". Rows 3a and 3d contradict that page for 0.155.1.
- https://learn.chatgpt.com/docs/permissions covers `default_permissions`, `[permissions.<name>.filesystem.":workspace_roots"]`, and read/write/deny precedence. It does not state that `extends` is needed (row 7c).
- https://learn.chatgpt.com/docs/agent-configuration/subagents covers the toml `model` precedence over the spawn value (confirmed in row 2c).
- https://learn.chatgpt.com/docs/models covers the model slugs (G8).
- Local CLI: `codex exec --help` (`--dangerously-bypass-hook-trust`, `-c`), `codex debug models`, `codex debug prompt-input`, `codex sandbox`, and the `spawn_agent` tool description in the 0.155.1 binary ("Do not set the `model` field unless the user explicitly asks…").

## Re-run on upgrade

```bash
PLAN/hook-verification-codex/run.sh [work-base-dir]   # env: CODEX_TEST_MODEL (default gpt-6-luna), CODEX_TEST_EFFORT (default medium)
```

- Run it **outside** any outer sandbox, such as Claude Code's Bash sandbox. Under nested seatbelt every Codex shell call aborts with exit 134 (run 1).
- It builds the scratch repo in a fresh `mktemp -d` and runs the free `codex debug prompt-input` preflight, then **one** `codex exec`. `report.sh <work-dir>` prints:
  - the skills and profile from the preflight, and which expected files exist;
  - token usage and the key sets per event;
  - spawn input before and after the rewrite, and the models per agent;
  - SubagentStart/SubagentStop, and the transcript check for SECRET and BANANA;
  - which spawn matchers fired, the edit-matcher hits, and PostToolUse(Bash);
  - cwd, pwd and env per agent;
  - the model list.
- **Not yet run:** the shipped harness swaps run 3's rewrite targets. `probe` gets a model-only rewrite, so the SubagentStop block test can complete. `probem` gets the plaintext-message rewrite, to show the decryption failure and the toml-vs-spawn model precedence. Each piece was exercised in runs 2 and 3, but this exact combination has not been run.
- After an upgrade, compare against the tables above. Check especially: the spawn tool name and matcher semantics, whether `message` is still encrypted, the toml-vs-spawn precedence, and the profile `extends` requirement. Update the version and date here.
- Logs, transcripts and run outputs stay in the temp dir and are not committed. They contain session IDs and home paths.
