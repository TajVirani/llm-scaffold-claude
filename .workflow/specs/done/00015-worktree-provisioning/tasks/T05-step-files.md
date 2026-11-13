# T05: Step files name the script

Index: [../tasks.md](../tasks.md) · Blocked by: T3 Worktree setup script · Parallel with: None

**What to build:** An orchestrator following the step files creates and removes every agent worktree and scratch worktree with `worktree-setup.sh`, never with a raw git command, and no step tells it to start an environment by hand or to ask the stakeholder to. The launching reference tells every launched agent that its worktree is already set up.

**Seam:** the step files and the launching reference as loaded text, checked by `tests/lint/worktree-setup-docs.sh` (its step-file cases), `tests/lint/agent-worktree-docs.sh` and `lint/step-list`.

**Acceptance criteria:**

- [ ] `verification-setup.md` (1.2, 1.3), `implementation-shared-core.md` (3.2) and `implementation-waves.md` (wave start) create their agent worktree with `worktree-setup.sh agent <name> <branch>` and remove it with `worktree-setup.sh remove <name>`.
- [ ] `verification-setup.md` 1.4 makes its known-bad worktree with `worktree-setup.sh scratch` and removes it with `worktree-setup.sh remove --force`. It no longer starts `serve` by hand or refuses when `serve_ready` already answers: the toolchain run starts the services.
- [ ] `implementation-finish.md` and `sign-off.md` remove leftover agent worktrees with `worktree-setup.sh remove`.
- [ ] `sign-off.md` 5.8 and `discovery-impact.md` 0.3.20 say that `spec-worktree.sh` sets the spec worktree up on `create` and runs `services_down` on `remove`.
- [ ] One rule, in `references/launching.md`: a launched agent's worktree is already set up; the agent never installs, copies or links anything into it by hand, and a worktree that is not ready is reported, not repaired. A step that hits a failed setup stops with the command's output.
- [ ] No step file or reference tells a reader to run a raw `git worktree add` or `git worktree remove`.
- [ ] `tests/lint/agent-worktree-docs.sh` checks the new wording in place of the raw commands it expects today (lines 97-110), and still checks the branch names, the merges and the artifacts gate.
- [ ] `references/steps.tsv` matches any step text that changed, and `lint/step-list`, `lint/md-links` and `lint/agent-worktree-docs` pass.
- [ ] In `tests/run-all.sh --suite lint/worktree-setup-docs`, every case that names a file under `skills/feature-workflow/` passes. The agent-definition cases stay red until T8.

**Predicted files:** `.agents/skills/feature-workflow/modules/verification-setup.md`, `.agents/skills/feature-workflow/modules/implementation-waves.md`, `.agents/skills/feature-workflow/modules/implementation-shared-core.md`, `.agents/skills/feature-workflow/modules/implementation-finish.md`, `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/modules/discovery-impact.md`, `.agents/skills/feature-workflow/references/launching.md`, `.agents/skills/feature-workflow/references/steps.tsv`, `tests/lint/agent-worktree-docs.sh`

**Phase 1 tests:** None. `tests/lint/worktree-setup-docs.sh` belongs to T8; run it by name to see the step-file cases pass.

**Size:** M (9 files, about 130 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** Agent worktree names and branches do not change (`s<NNN>_t<N>`, `s<NNN>_phase_1_<type>`, `s<NNN>_integration_<type>`; `wf/NNN-slug/<name>` or the task record's branch). Keep each rule in one home and point to it; do not copy the launching rule into a step file. If T2 reported that it kept the `git worktree add` allow rule, say so in your result: the orchestrator removes it from the two settings files after this task merges.
