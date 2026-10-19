# claude-settings.template.json

The Claude Code settings fragment that `install.sh` merges into `<target>/.claude/settings.json` (D36). It holds the hook wiring, the permission deny rules for hard write limits, the output style and the status line. JSON allows no comments, so the rationale lives here. The scaffold repo's own `.claude/settings.json` does not use this template: it wires only `block-destructive-git.sh` (D36).

## Entries

| Event | Matcher | Script | Timeout (s) | Why | Refs |
| --- | --- | --- | --- | --- | --- |
| `SessionStart` | (none: all sources) | `session-start-resume.sh` | 10 | Offers to resume an in-flight spec. The script can read `source` from the payload if it should skip `compact`. | 5.6; D22 |
| `PreToolUse` | `Bash` | `block-destructive-git.sh` | 10 | Blocks destructive git commands. Same entry as this repo's own settings. | — |
| `PreToolUse` | `Agent` | `pre-launch.sh` | 30 | Validates the ```` ```yaml launch-header ```` block (D37), resolves model and profile, returns `updatedInput`. | 00.11–00.14, 00.18–00.20; D13, D31, D33, D35 |
| `PreToolUse` | `Write\|Edit\|NotebookEdit` | `spec-single-writer-guard.sh`, `tier-a-write-guard.sh`, `tier-b-write-guard.sh` | 10 each | Accident-prevention write guards. Any one deny wins (verified 2.1.300). There is no `MultiEdit` tool. | 0.1.4; Tier A; Tier B; D16, D17 |
| `PostToolUse` | `Write\|Edit\|NotebookEdit` | `rules-boundary-config-sync.sh` | 60 | Regenerates the boundary config after an approved `docs/rules.md` write. The script filters on path. | 00.3, 3.5; D15, D20 |
| `PostToolUse` | `Bash` | `evidence-capture.sh` | 60 | Copies browser-suite evidence. The script acts only on the `e2e` command. | 3.10, 3.12; D15 |
| `PostToolUseFailure` | `Bash` | `evidence-capture.sh` | 60 | Same script. On Claude Code 2.1.303 a Bash call that exits non-zero fires only this event, never `PostToolUse`, and a failing suite (or the fault-injected run at 1.4) is the run whose evidence matters most. The payload carries `tool_name`, `tool_input.command` and `cwd` like `PostToolUse`, plus `error` and `is_interrupt`, and no `tool_response`; the script needs none of those. Codex needs no equivalent: its PostToolUse fires after non-zero exits. | 3.11, 1.4; F-1 |
| `SubagentStop` | `implementation` | `post-implementation-audit.sh` | 600 | Finds the task from the launch header in `agent_transcript_path` (D39) and runs the profile toolchain. Blocks the stop only on toolchain failures, and gives up after 3 identical failure digests (`audit.json` outcome `gave-up`). A missing or malformed header, an unreadable transcript, or a toolchain config or environment error allows the stop with a warning (a `systemMessage` plus `artifacts/<task-id>/audit.json` outcome `warning`, or `artifacts/audit-warnings.jsonl`; D55). 600 is the documented command-hook default; set explicitly because the toolchain can be slow. | 3.5–3.8; D19, D39, D55 |

- Commands use `"$CLAUDE_PROJECT_DIR"/.agents/hooks/<script>`, which resolves in the main session, sub-agents and worktree sub-agents (verified 2.1.300). Scripts take worktree-sensitive paths from the payload `cwd` (D18).
- The `SubagentStop` matcher filters on agent type, and a matcher made only of letters is an exact match ([hooks reference](https://code.claude.com/docs/en/hooks), "Matcher field by event" and matcher evaluation). The script still checks `agent_type`, so wiring it with an empty matcher would also be safe. The matcher itself was not live-tested on 2.1.300; the verification harness registered `SubagentStop` without one.
- `outputStyle: "Concise Technical"` ships because the style is first-party and in the payload (`output-styles/concise-technical.md`; PROVENANCE).
- `statusLine` runs `node "${CLAUDE_PROJECT_DIR:-.}"/.agents/hooks/context-bridge.js` (first-party, D79). It prints a 10-cell context-usage bar from the payload's `context_window.remaining_percentage`, scaled so 80% real usage shows as 100%, and writes `{session_id, remaining_percentage, timestamp}` to `<os.tmpdir()>/claude-ctx-<session_id>.json`. Nothing in the payload reads that bridge file yet: the PreToolUse gate hook its header names does not exist. The `:-.` fallback covers a status line run without `CLAUDE_PROJECT_DIR` set; the command then resolves from the session cwd. Needs `node` on `PATH`.
- Implemented: `pre-launch.sh`, `post-implementation-audit.sh`, `spec-single-writer-guard.sh`, `tier-a-write-guard.sh`, `tier-b-write-guard.sh`, `rules-boundary-config-sync.sh` and `session-start-resume.sh`, plus their shared helper `_guard-common.sh`. `evidence-capture.sh` is implemented too (wired under both `PostToolUse` and `PostToolUseFailure`).

## Permission deny rules (hard write limits, D16)

| Rule | Protects | Decision |
| --- | --- | --- |
| `Edit(docs/cache/**)` | Tier B caches | Added. Nothing may write there through Write, Edit or NotebookEdit (D17). `publish-cache.sh` moves files in from a script, which the rule does not see. |
| `Edit(specs/*/.step)` | The step marker the guards read (D16) | Added. Only `status-transition.sh` writes it, from a script the rule does not see. The rule stops the model forging a step through Write, Edit, NotebookEdit or a Bash redirect. The pattern has two segments, so it is anchored at the project root, which is where `.step` lives (D18: gitignored state exists only in the main checkout). |
| (none) | Tier A docs (`GLOSSARY.md`, `docs/capabilities.md`, `docs/rules.md`, `docs/decisions/`, `profiles/`) | Not added. The main session writes them at approved steps (D16), so only the step-aware guard can decide. |
| (none) | `specs/*/spec.md` | Not added, for the same reason (writes at 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29). |

What the docs say ([permissions](https://code.claude.com/docs/en/permissions), "Read and Edit"; [sandboxing](https://code.claude.com/docs/en/sandboxing), "Permission rules"):

- Path rules are checked only for `Edit(...)` and `Read(...)`. A `Write(path)` or `NotebookEdit(path)` rule is accepted but never consulted. `Edit` rules apply to all built-in tools that edit files, so one `Edit` rule covers Write, Edit and NotebookEdit.
- Patterns are gitignore-style. A relative single-segment directory pattern such as `docs/cache/**` matches at any depth under the cwd when used as a deny rule. That depth also covers worktree copies under `.claude/worktrees/` (D18).
- Edit deny rules also cover file commands Claude Code recognizes in Bash (`sed`, `tee`, ...) and redirect targets (`> file`). They do not cover arbitrary subprocesses that write files themselves, such as a script.
- Deny rules are evaluated first, in every scope, whatever a PreToolUse hook returns.

**Gap (sandbox).** The sandbox is off by default. When it is on, `Read` and `Edit` deny rules are merged into the sandbox configuration, which is enforced at the OS level on every Bash command and its children. A target project that enables the sandbox would therefore block `publish-cache.sh`'s move into `docs/cache/` and `status-transition.sh`'s write of `specs/*/.step`. That project must run both scripts outside the sandbox, with exact `sandbox.excludedCommands` entries for the command lines the `regenerate-caches` and `feature-workflow` skills use. `excludedCommands` matches the call text, so the skills must call each script the same way every time. For the same reason the template adds no `sandbox.filesystem.denyWrite`. Tier A and `spec.md` have no hard limit: a Bash write that bypasses the guards is caught only at review.

## Merge rules for `install.sh` (D11, D36)

- No existing `<target>/.claude/settings.json`: write the template as is.
- Existing file: deep-merge with `jq`.
  - `hooks.<event>`: append the template's matcher groups. Skip a group whose `command` already appears under that event, so reinstalling is idempotent.
  - `permissions.deny`: union, de-duplicated. Never remove user entries.
  - Other `permissions` keys and unrelated top-level keys (`enabledPlugins`, `env`, ...): keep the user's values.
  - `outputStyle`: set it if absent. If the user set a different style, keep theirs and warn, or overwrite with `--force`.
  - `statusLine`: same rule as `outputStyle`. A project `statusLine` overrides a user-level one, so a user who prefers their own status line removes the key from the project settings.
- Any other conflicting scalar: refuse without `--force` (D11).
- Upgrades re-run the same merge. The scaffold does not track which entries it added, so a hook removed from the template must be removed from targets by hand (open: record scaffold-owned entries in the version stamp).
