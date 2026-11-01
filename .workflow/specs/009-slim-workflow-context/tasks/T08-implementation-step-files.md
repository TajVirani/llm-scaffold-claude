# T08: Setup, waves and finish step files; orchestrator removed

Index: [../tasks.md](../tasks.md) · Blocked by: T7 (Fold the small path into its step files) · Parallel with: None

**What to build:** An implementation resume loads only the wave loop. The rest of `modules/implementation-orchestrator.md` splits into `implementation-setup.md` (3.1, skipped on resume once `impl_base_revision` is set), `implementation-waves.md` (wave loop, wave start, 3.3, 3.16, 3.15, 3.9, 3.13, Launching agents, Evidence and the ledger, Discovered work, Stops, resume and the 4.7 rework entry) and `implementation-finish.md` (3.10–3.11, 3.14 and hand off) (D6, D13); then the orchestrator file is deleted. Waves' On resume sends the session to setup first when a task has a null `work_type`, and 3.13 looks up which suites exist itself (spec Assumptions). The router's Route rows send 3.1 to setup, an `in-progress` resume with `impl_base_revision` set and the 4.7 rework to waves. Loads and links are re-pointed in review-triage (rework, 4.7), task-breakdown (load setup), discovery-impact (light pass → setup), verification-setup, large-path (`#316-merge-the-wave`) and the shared-core and gates files from T6.

**Seam:** `tests/lint/step-routing.sh` (every step id held by exactly one step file and reached from the router or a load line), `lint/md-links`, and the existing orchestrator pins re-pointed (`tests/hooks/worktree-guard.sh` the missing-agent-worktree deny sentence, `tests/lint/agent-worktree-docs.sh`).

**Acceptance criteria:**

- [ ] `tests/run-all.sh --suite lint/step-routing` passes.
- [ ] `implementation-orchestrator.md` no longer exists and no `.md` under `.agents/` names it.
- [ ] Every link and anchor that pointed into the orchestrator resolves to its new home (`lint/md-links` passes).
- [ ] `lint/upstream-lineage`, `lint/step-list` and every other existing suite pass, re-pointed only where they name the moved text.
- [ ] `PROVENANCE.md` names the three new files and drops the orchestrator row; `upstream-lineage.json` entries name the file their text now lives in.

**Predicted files:** `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`, `.agents/skills/feature-workflow/modules/implementation-setup.md`, `.agents/skills/feature-workflow/modules/implementation-waves.md`, `.agents/skills/feature-workflow/modules/implementation-finish.md`, `.agents/skills/feature-workflow/modules/implementation-shared-core.md`, `.agents/skills/feature-workflow/modules/implementation-gates.md`, `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/modules/review-triage.md`, `.agents/skills/feature-workflow/modules/task-breakdown.md`, `.agents/skills/feature-workflow/modules/discovery-impact.md`, `.agents/skills/feature-workflow/modules/verification-setup.md`, `.agents/skills/feature-workflow/modules/large-path.md`, `PROVENANCE.md`, `upstream-lineage.json`, `tests/hooks/worktree-guard.sh`, `tests/lint/agent-worktree-docs.sh`

**Phase 1 tests:** `tests/lint/step-routing.sh`

**Size:** L (16 files, about 500 changed lines; almost all moved text). Kept as one task by the stakeholder at 2.1.

**Mode:** afk.

**Notes:** Script and asset headers that name the orchestrator are T9's; leave them.
