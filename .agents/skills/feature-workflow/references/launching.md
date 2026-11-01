# Launching a sub-agent

How the main session launches a sub-agent, on Claude Code and on Codex. Read this file at a step that launches. The step file gives the task type, the header fields and the task body; this file gives the header rules, the denies and the spawn on each host.

## Launch header

Every launch prompt starts with the launch header on its first line, followed by the task:

````markdown
```yaml launch-header
task_type: retrieval
spec_dir: .workflow/specs/007-csv-export
```

<task body: only what the agent's definition says it receives>
````

- Required fields per task type: run `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements` (add `--task-type <type>` for one type). Phase 0 types (`retrieval`, `library-evaluation`, `fact-lookup`, `module-audit`) and `research` take `spec_dir` only. A launch from an initiative (`research`, and `fact-lookup`, `retrieval` or `library-evaluation` asked for one) sets `spec_dir: .workflow/initiatives/NNN-slug`.
- The task body carries only what `.agents/agents/<type>.md` lists under its inputs. Its return format is fixed in that file; read the return from there rather than expecting another shape.
- A return that starts `LAUNCH ERROR:` means the header was wrong: fix it and relaunch once.
- Launch independent agents in one message so they run in parallel. No nested launches.
- A deny that names **00.14** means no model is configured for that task type: tell the stakeholder, record the model they choose in `.workflow/model-map/<type>.md` (or in `.workflow/agent-overrides.yaml` when the agent definition pins a model for this host), and relaunch. A deny that names **00.19** means a coding launch has no profile: the step file that launches it handles it.

## Claude Code

Call the Agent tool with `subagent_type: <task type>` and the prompt = header + task. Leave `model` unset and the profile out: `hooks/pre-launch.sh` resolves both through `resolve-launch.sh`, inserts any profile after the header, and denies a malformed launch.

### An agent worktree on Claude Code

The Agent tool has no working-directory option (a sub-agent starts in the main session's directory), so launch it without `isolation` and confine it by the brief: every Bash command starts with `cd <absolute worktree path> && `, and every Read, Edit and Write uses an absolute path inside the worktree. `hooks/worktree-write-guard.sh` enforces this for implementation and integration sub-agents: it reads the agent worktree from the launch header (`.workflow/.worktrees/s<NNN>_t<N>` for a task, `s<NNN>_integration_<enc(work_type)>` for an integration batch) and denies a Write, Edit or NotebookEdit inside the main checkout but outside it, and a Bash command without that leading `cd` (accident prevention; a command can still reach out after its `cd`). The stop audit finds the worktree itself and warns when it is missing.

## Codex

On Codex you build each launch yourself (advisory): the spawn message is encrypted, so no hook can read the header or insert the profile.

1. Build the launch. `--task-type` keeps the hyphenated `<type>`; pass `--task-id` and `--work-type` when the header carries them. Exit 2 is a deny.

   ```bash
   printf '%s' "$TASK_BODY" | .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type <type> --spec-dir .workflow/specs/NNN-slug [--task-id T<n>] [--work-type <wt>]
   ```

2. Spawn the agent with:
   - `agent_type` = `<type>` with `-` replaced by `_` (`fact_lookup`, `profile_mini_review`, `cache_regeneration`);
   - `.prompt` as its message;
   - `.model` as its model. The generated `.codex/agents/*.toml` never carry `model` (a toml model would override the spawn-time one), so this is what selects it;
   - `task_name` from [Task names](#task-names);
   - `fork_turns: "none"` (a full-history fork may ignore the spawn `model` override, and it keeps the parent's history out of the sub-agent).

`hooks/codex-pre-spawn.sh` denies a malformed name and checks the `s<NNN>` spec folder or the `i<NNN>` initiative folder.

**Agent worktrees.** Codex has no `isolation` option. An implementation spawn runs in the task worktree created at wave start, a Phase 1 build in the worktree created before its launch, and an integration spawn in the integration worktree created at 3.2. Each worktree is `.workflow/.worktrees/<task_name>`; name its absolute path in the brief as the directory the agent works in. A fix-round relaunch keeps the same worktree and the same `task_name`. The spawn message is encrypted, so the Codex stop audit finds an implementation task from its `task_name`: it reads the name back from the sub-agent transcript's `session_meta` `agent_path`, runs the toolchain in that worktree (the evidence still goes to the spec checkout) and blocks on a toolchain failure as on Claude. Without the worktree it allows the stop with a warning.

### Task names

Codex accepts only `[a-z0-9_]` in a `task_name`, with no `/`. `enc` lowercases and turns every character outside `[a-z0-9]` into `_`. `<NNN>` is the number of the spec or initiative folder.

| Launch | `task_name` | Example |
| --- | --- | --- |
| `implementation` of a task (3.3), every launch including a fix-round relaunch; keep it exact, the stop audit finds the task from it | `s<NNN>_t<N>` | `s007_t3` for `.workflow/specs/007-checkout`, `T3` |
| `profile-mini-review` of review round `<round>` (3.7) | `s<NNN>_t<N>_r<round>` | `s007_t3_r2` |
| `integration` batch (3.2) | `s<NNN>_integration_<enc(work_type)>` | `s007_integration_web` |
| Phase 1 build (1.2, 1.3) | `s<NNN>_phase_1_<enc(work_type)>` | `s007_phase_1_test_harness` |
| `cache-regeneration` inside a feature (0.2.8); `cache_<type>` in a bulk run | `s<NNN>_cache_<type>` | `s007_cache_modules` |
| `review-combined` on the light path (4.10) | `s<NNN>_review_combined` | `s007_review_combined` |
| Every other type in a spec: `retrieval` (0.2.4), `library-evaluation` (0.2.5), `fact-lookup` (0.3.10), `module-audit` (0.4.6), the four review lenses (4.1–4.3, 4.9) | `s<NNN>_<enc(task type)>` | `s007_retrieval`, `s007_library_evaluation`, `s007_fact_lookup`, `s007_module_audit`, `s007_review_standards`, `s007_review_end_state`, `s007_review_targets`, `s007_review_lessons` |
| Any launch from an initiative, with `--spec-dir .workflow/initiatives/NNN-slug` | `i<NNN>_<enc(task type)>` | `i004_research`, `i004_fact_lookup` |
