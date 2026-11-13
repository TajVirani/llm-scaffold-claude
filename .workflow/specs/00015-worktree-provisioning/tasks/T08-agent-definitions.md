# T08: Agent definitions

Index: [../tasks.md](../tasks.md) · Blocked by: T3 Worktree setup script, T5 Step files name the script · Parallel with: None

**What to build:** Reviewers that probe a finding make their scratch worktree through `worktree-setup.sh scratch`, so the probe runs in a worktree that is set up like the spec's. Coding agents are told their worktree is ready and that they never install, copy or link anything into it by hand. The targets reviewer relies on the services the toolchain run starts instead of assuming one fixed port.

**Seam:** the agent definitions as loaded text, checked by `tests/lint/worktree-setup-docs.sh` and `tests/lint/review-escalation-docs.sh`.

**Acceptance criteria:**

- [ ] `profile-mini-review.md`, `review-end-state.md`, `review-standards.md` and `review-combined.md` create their scratch worktree with `worktree-setup.sh scratch <name>` and remove it with `worktree-setup.sh remove --force <name>`; no `mktemp` worktree and no raw `git worktree` command remains.
- [ ] `implementation.md` and `integration.md` each carry one sentence that says the agent never installs, copies or links anything into its worktree by hand, and that a worktree missing something is reported in the result, not repaired.
- [ ] `review-targets.md` builds its commands with the isolation values (`worktree-setup.sh env`), so the port it polls is the spec's, and says the services come from `services_up`. It still starts and stops the app with `serve`.
- [ ] `tests/lint/review-escalation-docs.sh` checks the new scratch worktree wording in place of the raw command it expects today (lines 50-62).
- [ ] `tests/run-all.sh --suite lint/worktree-setup-docs` passes whole, and `lint/frontmatter` and `lint/review-escalation-docs` pass.

**Predicted files:** `.agents/agents/profile-mini-review.md`, `.agents/agents/review-combined.md`, `.agents/agents/review-end-state.md`, `.agents/agents/review-standards.md`, `.agents/agents/review-targets.md`, `.agents/agents/implementation.md`, `.agents/agents/integration.md`, `tests/lint/review-escalation-docs.sh`

**Phase 1 tests:** `tests/lint/worktree-setup-docs.sh`

**Size:** M (8 files, about 90 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** The reviewers have Bash but no Write or Edit; a scratch worktree made by the script sits beside the agent worktrees in the spec checkout, so name it so two reviewers running at once cannot collide (for example `s<NNN>_scratch_<agent>`). Point to the rule in `references/launching.md` that T5 wrote; do not copy its text.
