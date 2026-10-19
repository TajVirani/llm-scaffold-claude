# Install end-to-end check (Claude Code)

> Scaffold-only evidence for this repo, not part of the install payload (D30). The harness is `PLAN/install-e2e/run.sh`. It covers the checklist §7 sample-target item for Claude Code. Codex and `project-setup` were not run.

## Tested version

- Date 2026-10-16, macOS. Claude Code 2.1.300. Scaffold `efb9263-dirty`, from the workflow-2.0 working tree. mikefarah yq v4.
- Session model `haiku`, resolved as `claude-haiku-5-5`. Two headless runs (`claude -p --permission-mode bypassPermissions --output-format stream-json --verbose`, temp project only). Reported `total_cost_usd`: run 1 $0.0102, run 2 $0.0039, about $0.014 in total.
- Sample target: a fresh git repo with `package.json`, `tsconfig.json` and `src/{math,index}.ts`. It starts with a `.claude/settings.json` that has a user `env` key, `permissions.allow` `Bash(npm test:*)`, `permissions.deny` `Read(./.env)` and a user `PreToolUse(Bash)` hook that logs commands to `.claude/user-hook.log`.
- Workflow data was seeded by hand, without `project-setup`:
  - `GLOSSARY.md` with one term
  - `docs/rules.md` from the template
  - `docs/cache/`
  - `model-map/fact-lookup.md` with `claude: haiku`
  - `profiles/ts.md`, with every toolchain command set to `true`
  - `specs/001-demo/spec.md` from the template (status draft), with `.step` written by `status-transition.sh status specs/001-demo draft --step 0.1.4`
- Logging: only `.claude/settings.local.json`, which records the PostToolUse(Agent) payload to read `resolvedModel` and the rewritten input. Every other result comes from the installed hooks' own output and the stream-json transcript.

## Results

| # | Check | Result | Evidence |
|---|---|---|---|
| 1a | Install over an existing `settings.json` | pass | Exit 0. The user's `env`, `permissions.allow`, `Read(./.env)` deny and user Bash hook were kept. The template's hook groups were appended after the user hook. `permissions.deny` became `[Read(./.env), Edit(docs/cache/**), Edit(specs/*/.step)]`. `outputStyle` was set. Symlinks are `.claude/{skills,agents,output-styles} -> ../.agents/<dir>`. The `.gitignore` marker block holds `specs/*/.step`, `.cache-staging/` and `.worktrees/`. |
| 1b | Re-install is idempotent | pass | The second run printed `up to date` for the payload, the shim and `.gitignore`. A snapshot of every file and symlink (sha and target, 115 entries) was identical before and after. |
| 1c | The pre-existing user hook still fires | pass | `.claude/user-hook.log` recorded each Bash command from both runs, including commands that were later denied. |
| 3a | SessionStart resume offer | pass | stream-json `hook_response` (`SessionStart:startup`) contained `- specs/001-demo: status draft; current step 0.1.4 (since …)`. Run 2 showed step `0.2.3`, and the model quoted the offer. |
| 3b | Tier A guard, `GLOSSARY.md` at step 0.1.4 | pass (denied) | `PreToolUse:Edit hook error: deny: GLOSSARY.md is Tier A; current step is 0.1.4 (specs/001-demo). Glossary files are written only at 0.2.3 0.3.15 0.4.3 5.3. Record the change as a 5.2 proposal …` |
| 3b | Tier A guard, `GLOSSARY.md` at step 0.2.3 | pass (allowed) | Run 2 Edit succeeded. The file now reads `_Avoid_: summer, totaliser`. |
| 3c | `Edit(docs/cache/**)` through the Write tool | pass (denied) | `File is in a directory that is denied by your permission settings.` `docs/cache/x.md` is absent. |
| 3c | `Edit(docs/cache/**)` through a Bash redirect | pass (denied) | `permission_denied` (`decision_reason_type: subcommandResults`): `Permission to use Bash with command echo x > docs/cache/y.md has been denied.` `y.md` is absent. |
| 3c+ | `Edit(specs/*/.step)` through a Bash redirect | pass (denied) | `Permission to use Bash with command echo 'step: 9.9' > specs/001-demo/.step has been denied.` `.step` is unchanged. |
| 3d | pre-launch, `fact-lookup` without a launch header | pass (denied) | `PreToolUse:Agent hook error: pre-launch: launch of 'fact-lookup' refused: no launch header: task type 'fact-lookup' requires a ```yaml launch-header block first in the prompt with spec_dir (D31, D37)` |
| 3d | pre-launch, `fact-lookup` with a valid header | pass (allowed, model set) | The model's `tool_use` input had keys `{description, prompt, subagent_type}`. PostToolUse `tool_input` had `{description, model:"haiku", prompt, subagent_type}`, so the hook's `updatedInput` was applied. `resolvedModel:"claude-haiku-5-5"`. The sub-agent answered `e2e-sample` (`package.json:1`). |
| 3e | `block-destructive-git` | pass (blocked) | `PreToolUse:Bash hook error: BLOCKED: Destructive git command detected: git reset --hard …`. HEAD is unchanged. |

## Issues and observations

1. **No hook or install bugs found** in the paths tested.
2. **The model rewrite is only partly proven here.** model-map gives `haiku` and the session also runs on haiku, so `resolvedModel` cannot tell the two apart. The proof is the `model` key that appears only in the post-hook `tool_input`. `PLAN/hook-verification.md` T5 already showed a cross-model rewrite. To prove it in the installed project, set `claude: sonnet` in `model-map/fact-lookup.md` and expect `resolvedModel: claude-sonnet-*`.
3. **In `-p` mode, Agent launches ran in the background by default.** The model sent no `run_in_background`, yet `task_started` had `is_backgrounded:true`, and PostToolUse(Agent) fired at launch with `tool_response.status:"async_launched"`, before the sub-agent ran. PostToolUse(Agent) therefore does not mark completion. Today only SubagentStop (`post-implementation-audit.sh`) depends on completion, so nothing breaks.
4. **An untrusted workspace ignores `permissions.allow` from project settings.** stderr: `Ignoring 1 permissions.allow entry from .claude/settings.json: this workspace has not been trusted.` Deny rules and hooks still applied. That is the safe direction, but a fresh install relies on the project `allow` list only after the trust dialog has been accepted.
5. **Cosmetic:** with `--host claude`, the `install.sh` next-steps line still says "Review and commit the changes (.agents/, .claude/, .codex/, .gitignore)" (`install.sh:569`). **Fixed since:** the line names only the shims the chosen `--host` creates (asserted in `tests/scripts/install.sh`).
6. **Scaffold repo, not target:** `block-destructive-git.sh` greps the whole command string, so a Bash heredoc that only contains the text `git reset --hard` (for example while writing this harness) is blocked. This is a false positive the design accepts. The harness builds that string at run time to avoid it. **Fixed since:** the guard now parses the command into simple commands and skips heredoc bodies, quoted arguments and comments (`tests/hooks/block-destructive-git.sh`).
7. **Not covered:** the `SubagentStop` `implementation` matcher (`post-implementation-audit.sh`), `rules-boundary-config-sync.sh`, `evidence-capture.sh` (a stub), `spec-single-writer-guard.sh` and `tier-b-write-guard.sh` deny paths, the sandbox gap, Codex, and `project-setup`.

## Re-run

```bash
PATH=<dir with mikefarah yq v4>:$PATH PLAN/install-e2e/run.sh [model]   # default haiku; base + follow-up runs, about $0.06
E2E_SKIP_BASE=1 PLAN/install-e2e/run.sh                                # follow-up runs f1-f3 only, about $0.045
E2E_SKIP_CLAUDE=1 PLAN/install-e2e/run.sh                              # install, seed, idempotence and follow-up seed only, free
```

`E2E_BASE` sets the parent of the fresh temp work dir. Transcripts stay in `<work>/runs/` and are not committed, because they contain session ids and home paths. Requires `claude`, `jq`, `git` and yq v4.

## Follow-up run

This run closes the gaps in issues 2 and 7, except Codex and `project-setup`. The harness is section 5 of `PLAN/install-e2e/run.sh`.

### Tested version

- Date 2026-10-19, macOS. Claude Code 2.1.303. Scaffold `efb9263-dirty`, installed from the working tree as it was at the start of the run. Another agent was copying vendored reference files into first-party skills at the same time. mikefarah yq v4.
- Session model `haiku` (`claude-haiku-5-5`). Three headless runs, f1 to f3, with the base runs skipped (`E2E_SKIP_BASE=1`). Reported `total_cost_usd`: f1 $0.0106, f2 $0.0258 (this includes the sonnet `fact-lookup` sub-agent), f3 $0.0089. Total about $0.045.
- Install and seed are the same as above. The follow-up seed adds:
  - `model-map/fact-lookup.md` switched to `claude: sonnet`
  - `model-map/implementation.md` with `claude: haiku`
  - `specs/001-demo/tasks.md` with task T1 (`work_type: ts`)
  - a stateful `lint` in `profiles/ts.md`. It fails until `specs/001-demo/artifacts/T1/toolchain.json` exists, which `run-toolchain.sh` writes only after its commands have run. So it fails on the first stop audit and passes on the next. This stands in for "`lint: \"false\"` first, then passing" within one run. Every call is logged to `<work>/lint.log`.
  - `profiles/e2e-browser.md` with `e2e: "./e2e.sh"`. That is a fake suite: it writes a Playwright-shaped `test-results/e2e-results.json` with a passing `JRN-001` test that has a base64 console attachment and a failing untagged test with a screenshot `path`. `E2E_EXIT` sets its exit code. Playwright is not installed.
  - `.claude/settings.local.json` loggers, used for evidence only: the PostToolUse(Agent) payload, every SubagentStop payload, and a copy of the sub-agent transcript at each stop.
- Steps were set with `status-transition.sh`. The harness set 0.2.3 before f1, and f1 itself ran `status-transition.sh step` to reach 0.3.17 and then 0.3.7. Between f1 and f2 the harness ran `draft -> ready-for-dev` (0.6) and then `-> in-progress` (3.1).

### Results

| # | Check | Result | Evidence |
|---|---|---|---|
| F1 | Model switch: `fact-lookup` with model-map `claude: sonnet`, session on haiku | pass | PostToolUse(Agent): `{"model":"sonnet","resolvedModel":"claude-sonnet-5-5","status":"async_launched"}`. The session `init` model was `claude-haiku-5-5`. The sub-agent answered `e2e-sample` (`package.json:1`). Closes issue 2. |
| F2a | Spec guard: body edit at a disallowed step (0.2.3) | pass (denied) | `PreToolUse:Edit hook error: deny: specs/001-demo/spec.md: current step is 0.2.3; spec.md is written only at 0.1.4 0.1.6 0.3.17 … (single writer, 0.1.4). …` |
| F2b | Spec guard: `status:` change at an allowed step (0.3.17) | pass (denied) | `deny: specs/001-demo/spec.md: this write changes status or blocked_condition ('draft' -> 'in-progress'). Status changes go only through status-transition.sh status specs/001-demo <status> (D16).` `status:` stayed `draft`. |
| F2c | Spec guard: body edit at an allowed step (0.3.17) | pass (allowed) | The Edit succeeded. `spec.md:69` reads `## Non-goals (e2e)`. |
| F3a | Tier A from a sub-agent: `implementation` edits `GLOSSARY.md` in its worktree | pass (denied) | `deny: GLOSSARY.md is protected (tier-a) and the write comes from a sub-agent (implementation). Only the main session writes … Tier A …`. `GLOSSARY.md` is unchanged in both the worktree and the main checkout. |
| F3b | Tier B from a sub-agent: `implementation` writes `docs/cache/z.md` in its worktree | pass (denied) | `File is in a directory that is denied by your permission settings.` The `Edit(docs/cache/**)` deny rule matched the worktree path (`.claude/worktrees/agent-*/docs/cache/z.md`). No `z.md` exists anywhere. Observation 3 covers why the hook's own message did not appear. |
| F4 | SubagentStop audit: blocked with a digest, then passes | pass | The launch used `isolation:"worktree"` and the header `spec_dir/task_id: T1/work_type: ts`. PostToolUse showed `model:"haiku"`, `worktreePath …/.claude/worktrees/agent-a08ebd39…` and `status:"completed"`. Worktree isolation works in `-p` mode. The sub-agent committed `a1ba911 T1: hello file` on `worktree-agent-a08ebd39…`, and its `git-dir` and `git-common-dir` differed. There were two SubagentStop payloads for `implementation`: `stop_hook_active:false` and then `true`. The sub-agent transcript holds `Stop hook feedback:\nToolchain failed for task T1 (1 of 5 commands). Fix these in the same context, then stop again.\nFull output: …/specs/001-demo/artifacts/T1/toolchain.txt\n\n[lint] …`. `lint.log` shows exactly two calls, both with cwd set to the worktree, so the agent never ran lint itself. Evidence is in the main checkout under `specs/001-demo/artifacts/T1/`: `toolchain.json` (`status:"pass"`, 5 ran, all pass) and `toolchain.txt`. `audit-loop.json` was cleared on the pass. |
| F5a | rules sync: valid yaml in `docs/rules.md` (at 0.3.7) | pass | `tools/boundaries/dependency-cruiser.cjs` was absent before the run. After the Edit it existed with the rule `"name": "math-not-to-app"` (in-session `grep -c not-to` returned `1`). |
| F5b | rules sync: malformed yaml | pass (blocked) | `PostToolUse:Edit hook blocking error from command: …rules-boundary-config-sync.sh: docs/rules.md was written, but its boundary rules do not parse, so tools/boundaries/ was not regenerated (D15, D20): generate-boundary-config: Ownership: block is not valid YAML: … line 6: did not find expected ',' or ']'. Fix the fenced yaml blocks …`. The config was left at the last good render. |
| F6a | evidence-capture: fake suite, exit 0 | pass | `PostToolUse:Bash hook additional context: evidence-capture: filed 2 files for 2 tests (1 failing, 1 journeys) under specs/001-demo/artifacts/e2e-20261019T135128Z-edd8a5f/ (index: evidence-index.json).` Filed: `JRN-001/console.txt` (decoded body), `untagged/screenshot.png` (copied path), `e2e-results.json`, and `evidence-index.json` (command `./e2e.sh`, `spec_dir`, stats, per-test journeys, status and files). |
| F6b | evidence-capture: same suite, exit 1 (`E2E_EXIT=1 ./e2e.sh`) | **fail (not filed)**; fixed by F-1 wiring, not re-run live | The Bash tool result was `is_error:true` (`Exit code 1`). No hook message reached the model, and no second `e2e-*` directory was created. The single index still names `./e2e.sh`, so the second run did not overwrite it either. See issue F-1. |

### Issues and observations

1. **F-1, bug (fixed): evidence-capture never saw a failing suite run.** It is wired as `PostToolUse` on `Bash`. On 2.1.303 a Bash call that exits non-zero is a tool error, and `PostToolUse` does not fire for it (Claude Code has a separate `PostToolUseFailure` event). `npx playwright test` exits 1 whenever a test fails. So the runs whose evidence matters most are never filed: the failing journeys at 3.11 and the fault-injected run at 1.4, which must fail by design. A deterministic payload piped to the hook files them correctly (checked before the live run), so the parsing is fine and only the wiring misses them. **Fix applied:** `claude-settings.template.json` now also registers `evidence-capture.sh` under `PostToolUseFailure` with matcher `Bash` (verified live on 2.1.303: the payload carries `tool_input.command` and `cwd`, plus `error`; see `PLAN/hook-verification.md`). The hook reads only command and cwd, so it needed no parsing change, and it echoes the payload's `hook_event_name` in its output. `install.sh` already appends groups per event key, so the new event merges into existing settings (`tests/scripts/install.sh` checks it); `tests/hooks/evidence-capture.sh` covers the failure payload. Codex is unchanged: its PostToolUse fires after non-zero exits. Live re-run of F6b not repeated. Alternatives considered: also register the hook under `PostToolUseFailure` with matcher `Bash` (check that event's payload carries `tool_input.command` and `cwd`), or have profiles wrap the suite so it exits 0 (this loses the signal).
2. **The Agent `isolation` parameter is honoured in `-p` mode**, and `pre-launch.sh`'s `updatedInput` keeps it: the PostToolUse `tool_input.isolation` was `"worktree"`. With `run_in_background:false` set by the model, the implementation launch ran in the foreground (`is_backgrounded:false`). PostToolUse then fired at completion with `status:"completed"`, and the sub-agent's tool calls were streamed into the parent transcript.
3. **The Tier B deny rule shadows `tier-b-write-guard.sh`'s pointer.** For a Write under `docs/cache/`, both live runs (base 3c and F3b) returned the permission-settings message, not the hook's text, which points to `regenerate-caches`. Piping the same worktree payload to the hook gives the expected deny with that pointer, so the hook works. The agent simply never sees the pointer. This is harmless for safety but loses guidance. Not changed.
4. **The SubagentStop block reason reaches only the sub-agent.** The parent session saw no hook text, and its model reported "no stop-hook reason appears in my context". The orchestrator learns about a failed audit only from the evidence files or the sub-agent's report. This matches D19, which keeps the fix in the same context.
5. **Not covered:** the audit's give-up path after 3 identical failures (unit-tested only), Codex, and `project-setup`.
