# T01: Hooks build agent worktree names from the shared lib

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately; needs the wave-1 integration batch merged first) · Parallel with: None

**What to build:** On Claude, a Phase 1 implementation agent and an integration agent are confined to and audited in their **Agent worktree**, the same way a Phase 3 task agent is today.
- `worktree-write-guard.sh` derives `--worktree-name` from the launch header:
  - `task_id` → `s<NNN>_t<N>`, as today;
  - an implementation header with `work_type` and no `task_id` → `s<NNN>_phase_1_<enc(work_type)>`;
  - an integration header → `s<NNN>_integration_<enc(work_type)>`.
- `post-implementation-audit.sh` also runs for `integration` agents. For a Claude Phase 1 or integration launch it runs the toolchain in that named worktree: Phase 1 with `--skip test`, integration with the full toolchain. It warns and allows when the worktree is missing.
- Both hooks build names with the lib's `wf_agent_worktree_name` and encode with `wf_enc`. `codex-pre-spawn.sh` encodes agent-type and work-type names with `wf_enc`. Neither hook keeps a `codex_enc` copy.
- The SubagentStop matcher covers implementation and integration in three places: `claude-settings.template.json`, its `.md` table, and this repo's `.claude/settings.json`.

**Seam:** The hooks' JSON contract, driven by payloads:
- PreToolUse payload → deny JSON or nothing (`tests/hooks/worktree-guard.sh` JRN-002, JRN-003);
- SubagentStop payload with a toolchain stand-in → block, warn or allow (`tests/hooks/audit-agent-worktrees.sh`);
- the lib functions sourced directly (`tests/scripts/lib-workflow-paths.sh`);
- the settings matcher after a fresh install and after an upgrade (`tests/scripts/install-claude-settings.sh`, `tests/scripts/install-upgrade.sh`).

**Acceptance criteria:**

- [ ] For a Phase 1 implementation header and an integration header, a Write inside the agent worktree is allowed. A Write to the main checkout or to another agent worktree is denied, naming the worktree. A Bash write without the leading `cd` is denied with the `cd <worktree> &&` hint.
- [ ] Every existing guard case for Phase 3, isolation (linked-worktree cwd), Codex and the main session keeps its verdict.
- [ ] The stop audit for a Claude Phase 1 launch runs the toolchain once in `s<NNN>_phase_1_<enc>` with `--skip test`, and for an integration launch once in `s<NNN>_integration_<enc>` with no `--skip`. A failing integration toolchain blocks the stop. A missing worktree gives a warning and allows the stop. Codex and Phase 3 behaviour is unchanged.
- [ ] `git grep -n codex_enc -- .agents/hooks` prints nothing (target codex-enc-copies). The Codex `task_name` checks in `codex-pre-spawn.sh` and the audit accept the same names as before.
- [ ] The template and `.claude/settings.json` each have one SubagentStop entry whose matcher matches `implementation` and `integration`. The upgrade case moves to T06.
- [ ] Hook headers and `claude-settings.template.md` describe the new confinement. The `isolation` wording goes, except where rule 2 (linked-worktree cwd) still applies.
- [ ] The Merge rules of `claude-settings.template.md` state the upgrade matcher rule (spec Constraints, D19-D29):
  - It applies to an existing group that runs a template command under a matcher not covering the template's.
  - `--matchers=merge|replace|keep` sets the outcome. At a terminal the installer asks, and Enter merges. Without a terminal it merges with a Warnings line, but a mixed group is kept with a warning.
  - A match-all group is never touched, and only plain `|` alternations are merged.
  - The rule replaces the line that skips a group whatever its matcher.
  - JRN-014 checks these lines in `tests/lint/install-matcher-docs.sh`, which T07 owns.
- [ ] The three suites under Phase 1 tests pass, the existing hook suites still pass, and shellcheck is clean.

**Predicted files:** `.agents/hooks/worktree-write-guard.sh`, `.agents/hooks/post-implementation-audit.sh`, `.agents/hooks/codex-pre-spawn.sh`, `.agents/hooks/claude-settings.template.json`, `.agents/hooks/claude-settings.template.md`, `.claude/settings.json`

**Phase 1 tests:** `tests/scripts/lib-workflow-paths.sh`, `tests/hooks/audit-agent-worktrees.sh`, `tests/scripts/install-claude-settings.sh` (`tests/scripts/install-upgrade.sh` moved to T06 at the 2.5 re-run)

**Size:** M (6 files, about 200 changed lines).

**Mode:** afk.

**Notes:**
- **Shared-core request** (touches_core), for the shell-scripts integration batch before wave 1. Replace the stubs in `.agents/lib/workflow-paths.sh` with real functions. Both are pure, safe under `set -euo pipefail`, use only `local` variables, return 1 with a reason and never `exit`, and are listed under `# API:`:
  - `wf_enc <string>`: under `LC_ALL=C`, lowercase, every byte outside `[a-z0-9]` → `_`, no trailing newline, status 0.
  - `wf_agent_worktree_name <spec_dir> task|phase_1|integration <value>`:
    - `task T<n>` → `s<NNN>_t<n>`; `phase_1 <work_type>` → `s<NNN>_phase_1_<wf_enc work_type>`; `integration <work_type>` → `s<NNN>_integration_<wf_enc work_type>`.
    - `<NNN>` is the digits of the spec folder's `NNN-slug` basename.
    - A malformed folder or an unknown kind returns 1 with a reason on stderr and prints nothing.
  - The contract is pinned by `tests/scripts/lib-workflow-paths.sh` (JRN-001), which this task owns.
- `.claude/settings.json` is repo config, not hooks-owned. It changes here because it must stay in step with the template (data-model M1).
- `tests/hooks/worktree-guard.sh` holds this task's JRN-002/003 cases, but T04 owns that suite: it turns green only after both tasks merge.
