---
status: in-progress
baseline_revision: "aea4e6ebc531a649e09ff3f34d241fb48cabe9e1"
spec_branch: "spec/00015-worktree-provisioning"
impl_base_revision: "3eb23c84fea45e1e1f9583bc2f54af6fc6fa4a9c"
light_path: false
followup_review_recommended: false
deferred: [.workflow/deferred/rules-setting-usage-exit-code.md]
tracker_issue: ""
budget: {max_tasks: 10, max_changed_files: 37}
---

# Worktree provisioning

## Why

The workflow creates spec worktrees and agent worktrees with a plain `git worktree add` and never sets them up, so each one starts without the project's dependencies, its gitignored config (`.env`) or a running environment. Agents and the orchestrator improvise: in a live project one agent copied the main checkout's `.env`, the orchestrator symlinked it, the symlink made the worktree write guard block an edit, and the run stopped to ask the stakeholder. The worktree also ran the app on the main checkout's fixed ports and shared database containers, so the stakeholder was asked to start and restart environments and a test run damaged the shared dev database. A worktree must be a self-contained place to build and test a spec, set up by the workflow without asking, that cannot collide with the main checkout or with another spec.

## Capabilities

- **CAP-NEW-worktree-setup** Worktree setup
  - **intent:** The workflow creates every spec worktree, agent worktree and scratch worktree through one script that makes it ready to run and test, and it starts and stops the services a test run needs, so no agent or stakeholder sets up or starts an environment by hand.
  - **success:** In a project that declares a setup command, a copy list and service commands, a newly created spec worktree and agent worktree hold the copied gitignored files as real files, the setup command has run with the spec's isolation values, `run-toolchain.sh` runs `services_up` before `test` and `--e2e`, removing the spec worktree runs `services_down`, two specs hold different slots, and a symlink into the main checkout fails both worktree setup and the toolchain run.

## Constraints

- A project that declares no setup command, no service commands and no copy list behaves as it does today: the script only adds the worktree.
- The scaffold sets nothing project-specific. It hands the project's own commands a slot number, an instance name and a port offset; the project turns them into ports, container names and database names.
- Copied files are copies, never links, and only files the project's `.gitignore` already ignores are copied, so a copy can never be committed or block removing the worktree.
- One set of services per spec, shared by its agent worktrees and scratch worktrees. Services start only for a toolchain key that will actually run.
- A failing setup command stops with its output. Nothing falls back to a bare worktree, and no agent installs, copies or links anything into a worktree by hand.
- bash 3.2, git and yq only; the script header and comment rules of the shell-scripts profile.

## Non-goals

- Changes to any target project, Athena included: its ports, task runner and `.env` stay as they are until that project declares its own setup.
- A container or virtual machine per worktree.
- Fixing a project's tests that write to its dev database. The scaffold only says, in the profile template and the standards interview, that tests use a throwaway database.
- Making the settings reader's usage exit code match its sibling scripts: shelved as [rules-setting-usage-exit-code](../../deferred/rules-setting-usage-exit-code.md).

## Success signal

In a project that declares its setup, a spec is built and tested from start to sign-off without one agent installing, copying or linking anything by hand and without the stakeholder being asked to start an environment, while a second spec runs beside it on its own ports. The objectives and journeys that prove it are in [verification-plan.md](verification-plan.md).

## Assumptions

- The design assumptions are the Assumed entries in [design-log.md](design-log.md), offered for veto and kept in Questioning round 1 (D5).

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
