# Design log: Sub-agents can write their own result file

Spec: [spec.md](spec.md)

## 2026-10-28 Origin: 005-cache-build-followups-disc-001.md

- Work item: 005-cache-build-followups-disc-001.md (started at 005's sign-off, 5.9)
- Origin spec and step: .workflow/specs/005-cache-build-followups, step 3.2
- Problem: An integration or implementation sub-agent must write its result file (`integration.yaml`, `implementation.yaml`) under the spec's `artifacts/` in the main checkout, but the worktree write guard confines it to its worktree and denies that write. The agent finishes its work but cannot file its result, so the orchestrator has nothing to check without retyping the agent's block.
- Evidence:
  - Integration batch `integration-shell-scripts`, spec 005 step 3.2, agent report quoted: "Both the Write tool and Bash refused `.../.workflow/specs/005-cache-build-followups/artifacts/integration-shell-scripts/integration.yaml` because it is outside the worktree."
  - `.agents/hooks/worktree-write-guard.sh:15-16` confines an isolation-launch agent to its linked worktree; `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` has no exception for `.workflow/specs/<spec>/artifacts/<id>/` (grep for `artifacts` finds nothing).
  - `run-toolchain.sh` evidence in the same folder was written (it runs outside the guard), so only the agent's own Write/Edit/Bash writes are blocked.
  - Every implementation, integration and mini-review agent in spec 005 (including its rework) hit it; the workaround was to write the file inside the worktree and have the main session copy it out.
- Why not a blocker (carried): spec 005's capabilities did not depend on the guard; the copy-out workaround held.
- Suggested scope (carried): let `check-worktree-scope.sh` admit a write to `<main checkout>/.workflow/specs/<spec>/artifacts/<own task id or integration-<work_type>>/` for the agent's own result files, with suite cases in `tests/hooks/` for allow and deny; leave the rest of the confinement as is. Size: 1 task, 1 module.

## 2026-10-29 Term gate (0.2.2)

- "Result file" agreed as proposed and added to `.workflow/GLOSSARY.md` under Branches and tasks: the one YAML file implementation, integration or profile-mini-review writes under `<spec_dir>/artifacts/<id>/`; not a Phase 4 pass file.

## 2026-10-29 Capability (0.3.1)

- No entry in `.workflow/capabilities.md` covers result files, artifacts or the worktree guard. New capability, provisional `CAP-NEW-result-file-write`.

## 2026-10-29 Placement (0.3.4)

- Touched modules: feature-workflow (`check-worktree-scope.sh`), tests (`tests/hooks`, `tests/scripts`); agents docs only if their result-file wording must change.
- Stakeholder chose the recommended option: the exception lives in `check-worktree-scope.sh`, the one rule behind both `worktree-write-guard.sh` (Claude) and `codex-write-guard.sh` (Codex), so both hosts get it and the hooks stay thin adapters. Rejected: putting it in the Claude hook, which would leave Codex denying and put logic in an adapter.

## 2026-10-29 Placement check (0.3.5-0.3.7)

- 0.3.5 ADRs: consistent with ADR-0001 (hooks are adapters over skill scripts); no conflict with ADR-0002 or ADR-0003. Rules: hooks may depend on feature-workflow; tests may depend on both. No conflict.
- 0.3.7 No placement ADR: an exception inside an existing script is cheap to reverse and follows the adapter pattern, so it fails the three-part test.

## 2026-10-29 Deeper prompt (0.3.22)

- Round 1: drafted elevation and four goals; stakeholder answered downstream "none known", tools "no new deps", gotchas "those cover it".
- Round 2: full block restated; stakeholder agreed: "yes, pass it on".

**Ask:** Let the workflow's coding and review sub-agents (implementation, integration, profile-mini-review) file their own result file where the orchestrator checks it, so the main session never copies results out of worktrees by hand, while the worktree guard keeps every other write confined.

**Goals:**
- An implementation, integration or profile-mini-review agent under the worktree guard can write its result file to `<main checkout>/<spec_dir>/artifacts/<its own id>/`, through Write/Edit and through the one-heredoc Bash command its brief prescribes, on Claude and Codex.
- Any other write outside the worktree is still denied: another task's `artifacts/` folder, any other file name, `..` traversal, symlink escapes.
- `check-task-result.sh` reads the file the agent wrote; no copy step, no retyped block.
- Allow and deny cases are covered by suite cases in `tests/hooks/`, and `tests/run-all.sh` passes.

**Downstream:** none known; keep the exception narrow to the three result-file kinds.

**Tools and technologies:** no new deps: bash 3.2 and git only.

**Gotchas:** only the agent's own `artifacts/<id>/` folder and the result-file names get through, with no traversal or symlink escape; Bash heredoc writes must pass the command rule, not only the Write/Edit path rule; mini-review re-checks write `mini-review-r<k>.yaml`.

**Not asked for:** admitting Phase 4 pass files or other artifacts (`audit.json`, evidence); the Phase 1 worktree base-ref pitfall; the checker-piped-into-head pitfall.

**Original request:** "let `check-worktree-scope.sh` admit a write to `<main checkout>/.workflow/specs/<spec>/artifacts/<own task id or integration-<work_type>>/` for the agent's own result files, with suite cases in `tests/hooks/` for allow and deny; leave the rest of the confinement as is. Size: 1 task, 1 module."

## 2026-10-29 Facts behind round 1 (0.3.10)

- fact-lookup: `worktree-write-guard.sh` confines only `implementation` and `integration` sub-agents (`.agents/hooks/worktree-write-guard.sh:55-60`); it passes `--worktree-name s<NNN>_t<N>` only when the header has `task_id` (`:70-104`), so Phase 1 and integration fall to rule 2 (linked-worktree cwd). profile-mini-review is not confined (`implementation-orchestrator.md:15`). The command rule checks only the leading `cd` target and never inspects redirection targets (`check-worktree-scope.sh:120-141`). `codex-write-guard.sh` checks only `apply_patch` (`:2-8`, `:79`). Codex already launches Phase 1 and integration in orchestrator-made named worktrees `s<NNN>_phase_1_<wt>` / `s<NNN>_integration_<wt>` (`verification-setup.md:46`, `implementation-orchestrator.md:41`).
- Transcript audit of spec 005 (session 80386173, 18 sub-agents): 22 result-file writes. 3 refused, all by Claude Code's built-in worktree isolation, none by this repo's hook: Phase 1 build (heredoc refused "too complex to verify that it stays inside the worktree"; a plain `cp` from a temp file then succeeded) and integration (heredoc and Write both refused; the file was never written). Phase 3 implementation (10 writes) and profile-mini-review (10 writes) all succeeded, but the Phase 3 agents wrote a relative path after `cd <worktree>`, so their files landed in the worktree copy, not the main checkout. The repo hook refused 2 non-result commands in Phase 3 (a read `cat ... | head`, an `rm` in a scratch dir) because they lacked the leading `cd <worktree> &&`.
- Consequence: the work item's suggested scope (an exception in `check-worktree-scope.sh`) would not have fixed the refusals; the host isolation layer cannot be changed from this repo.

## 2026-10-29 Questioning round 1 (0.3.11)

- **D1 How isolation-launched agents file their result.** Options: named worktrees like Phase 3 (no `isolation`); keep isolation with a temp-file-then-`cp` shape; orchestrator reads the result from the worktree. Recommended: named worktrees (removes the host layer; matches the Codex forms; Phase 1 then forks from the spec branch). Answer: "Named worktrees (Recommended)".
- **D2 Phase 3 result files landing in the worktree copy.** Options: brief fix plus a merge-gate check that refuses a task branch adding files under `<spec_dir>/artifacts/`; brief wording only. Recommended: brief plus merge-gate check. Answer: "Brief + merge-gate check (Recommended)".
- **D3 Read-only Bash refused without a leading `cd`.** Options: shelve to `.workflow/deferred/`; include; drop. Recommended: shelve. Answer: "Include it". Scope widened: relaxing the command rule for reads is in this spec.
- Supersedes the 0.3.4 Placement entry: the change is no longer a `check-worktree-scope.sh` exception alone; placement is re-asked once the touched modules are settled.

## 2026-10-29 Questioning round 2 (0.3.11)

- **D4 Named-worktree names on Claude.** Options: match the Codex forms; a new Claude-only scheme. Recommended: match Codex (`s<NNN>_phase_1_<enc(work_type)>`, `s<NNN>_integration_<enc(work_type)>`, derived from the launch header). Answer: "Match Codex names (Recommended)".
- **D5 The isolation fallback at `implementation-orchestrator.md:29`.** Options: remove it; keep it with a temp-then-`cp` result write. Recommended: remove (an agent that keeps getting denied becomes a blocked task, not a silent switch). Answer: "Remove the fallback (Recommended)".
- **D6 How reads get through the command rule.** Options: read-only allowlist (cat, head, tail, grep, rg, ls, wc, `sed -n`, find without `-delete`/`-exec`, git log/show/diff/status, yq, jq; joined by `|` or `&&`; no `>`, `>>`, `tee` or `;`); hook rewrites the command via `updatedInput`. Recommended: allowlist. Answer: "Read-only allowlist (Recommended)".
- **D7 Where the artifacts merge-gate check lives.** Options: one inline `git diff --name-only` at 3.16; a new gate script with tests. Recommended: inline. Answer: "New gate script" (scripted gates avoid the pipe-into-head pitfall).

## 2026-10-29 Questioning round 3 (0.3.11)

- **D8 One spec or an initiative.** Two capabilities: result files filed in the main checkout; read-only commands pass the worktree guard. Options: one spec; convert to an initiative; file the second as a work item. Recommended: one spec (shared script and test suite, a few tasks). Answer: "One spec (Recommended)".
- **D9 Placement (supersedes the 0.3.4 Placement entry).** Options: each piece in its current owner; share the worktree-name encoder in `.agents/lib/`. Recommended: each in its owner. Answer: "Share the name encoder in lib". The `s<NNN>_<kind>_<enc(work_type)>` naming moves to shared core and changes through the integration agent; `codex_enc` is copied today in `.agents/hooks/codex-pre-spawn.sh:70` and `post-implementation-audit.sh`.
- **D10 Which merges the artifacts gate checks.** Options: every orchestrator merge (Phase 3 task branches at 3.16, integration batches at 3.2, the Phase 1 build); Phase 3 only. Recommended: every merge. Answer: "Every orchestrator merge (Recommended)".

## 2026-10-29 Placement check (0.3.5-0.3.7), re-run for D9

- Touched modules: lib (shared core: name encoder), feature-workflow (`check-worktree-scope.sh`, new artifacts gate script, `verification-setup.md`, `implementation-orchestrator.md`, `resolve-launch.sh` if it builds names), hooks (`worktree-write-guard.sh`, `post-implementation-audit.sh`, `codex-pre-spawn.sh`), agents (`implementation.md`, `integration.md`), tests.
- 0.3.5 ADRs: consistent with ADR-0001 (hooks stay adapters over shared scripts); no conflict with ADR-0002 or ADR-0003. Rules: hooks and feature-workflow may depend on lib; agents on feature-workflow; tests on all; lib depends on nothing. `.workflow/profiles/shell-scripts.md` already says code a second skill needs moves to `.agents/lib/`. No conflict.
- 0.3.7 No placement ADR: moving a helper into lib follows the profile rule and is cheap to reverse; it fails the three-part test.

## 2026-10-29 Goal settled (0.3.19)

- Summary of D1-D10 restated as two capabilities (CAP-NEW-result-file-write, CAP-NEW-worktree-read-commands), placement per D9, non-goals and the full path. Stakeholder: "matches".
- Light-path facts: intent gaps clean; no irreversible actions; footprint not small (five modules plus shared core). `light_path: false`.

## 2026-10-29 Light-path test (0.3.20)

- `light_path: false`: footprint spans lib, feature-workflow, hooks, agents and tests. Full path, continue at 0.4.

## 2026-10-29 Impact classification (0.4.4)

| Part | Module | Class |
| --- | --- | --- |
| Worktree-name encoder (`s<NNN>_t<N>`, `s<NNN>_phase_1_<enc>`, `s<NNN>_integration_<enc>`) | lib | create (moved from the `codex_enc` copies) |
| `codex_enc` in `codex-pre-spawn.sh`, `post-implementation-audit.sh` | hooks | refactor (use the lib encoder) |
| `worktree-write-guard.sh` name derivation for Phase 1 and integration headers | hooks | extend |
| Stop audit's worktree lookup for Phase 1 and integration on Claude | hooks | extend |
| `check-worktree-scope.sh` command rule: read-only allowlist | feature-workflow | extend |
| Artifacts merge-gate script | feature-workflow | create |
| `verification-setup.md` Phase 1 Claude launch (named worktree, no isolation) | feature-workflow | extend |
| `implementation-orchestrator.md` integration launch, isolation fallback removed, gate call at 3.2 and 3.16 | feature-workflow | extend |
| `implementation.md`, `integration.md` result-file write step | agents | extend |
| `profile-mini-review.md` | agents | unchanged |
| `check-task-result.sh` | feature-workflow | unchanged |
| `codex-write-guard.sh` | hooks | unchanged |
| Suites `tests/hooks/worktree-guard.sh`, new gate-script suite, encoder suite | tests | extend / create |

## 2026-10-29 Module audits (0.4.6) and conflict check (0.4.7)

- Three `module-audit` returns (feature-workflow, hooks, lib) written to `codebase-map.md`. No cache disagrees with code.
- 0.4.7 goal conflicts sent back to the loop: integration agents are never stop-audited; allowlisted tools and shell forms can write without `>`; the merge gate must handle committed `artifacts/` and the light-path commit merge; Phase 1 and integration lose their branch source and cleanup without isolation; encoder home in lib.
- Term gate 0.4.2: "Agent worktree" agreed as proposed and added to `.workflow/GLOSSARY.md`.

## 2026-10-29 Questioning round 4 (0.3.11)

- **D11 Integration stop audit.** Options: leave integration unaudited and drop it; widen the hook filter and Claude matcher so integration agents are audited in their agent worktree. Recommended: leave unaudited. Answer: "b". Widen the stop audit to integration agents.
- **D12 Hardening the read-only allowlist (refines D6).** Options: narrow list plus shell-form denylist; keep the full D6 list with a per-tool flag denylist (`sed` w/W/-i, `find` write and exec actions, `yq -i`, `git --output`, `rg --pre`) plus the shell-form denylist (`$`, backtick, `<`, `>`, `;`, `&` other than `&&`, `||`, newline, `tee`). Recommended: narrow. Answer: "b". Full list with per-tool flag denylist.
- **D13 Merge-gate input and rule.** Options: revision (branch or commit), diff from the merge-base, refuse any add/modify/delete under `<spec_dir>/artifacts/`; added only. Stakeholder first answered "light-path should still make a branch, not commit on main"; follow-up clarified the light path commits on the spec branch via a detached worktree. Follow-up answers: light path "No, keep as is" (the gate also accepts a commit); rule "Any add/modify/delete (Recommended)".
- **D14 Agent worktree lifecycle for Phase 1 and integration.** Recommended: `git worktree add .workflow/.worktrees/<name> -b wf/NNN-slug/<name> spec/NNN-slug` on both hosts; merge uses that branch; reused on relaunch or fix round; worktree and branch removed after merge; 1.3 forks after the 1.2 merge. Answer: "a".
- **D15 Encoder home.** Recommended: `wf_` functions in `workflow-paths.sh`, pinned to `LC_ALL=C`, replacing both `codex_enc` copies (including its agent-type use). Answer: "a".
- Scope gate: three module-audit out-of-scope lines shelved without objection (see Scope decision entries below).

## 2026-10-29 Scope decision: worktree-name parser (0.3.17)

- Module-audit (hooks) out-of-scope line: name parsing stays copied across three hooks. Shelved, AFK: `.workflow/deferred/worktree-name-parser.md`. Building names stays in scope (D15).

## 2026-10-29 Scope decision: Codex spawn profile lookup (0.3.17)

- Module-audit (hooks) out-of-scope line: `codex-pre-spawn.sh` resolves work types against main-checkout profiles only. Shelved, AFK: `.workflow/deferred/codex-spawn-profile-lookup.md`.

## 2026-10-29 Scope decision: known-bad evidence path (0.3.17)

- Module-audit (feature-workflow) out-of-scope line: 1.4 evidence written inside the scratch worktree. Shelved, AFK: `.workflow/deferred/known-bad-evidence-path.md`.
- The hooks audit's doc-drift line (guard, audit and settings-template headers) stays in scope: the docs change with the code.

## 2026-10-29 Goal re-settled (0.3.19)

- Changes since the first confirmation restated (D11-D15, three shelved items); integration stop audit runs the full toolchain like Phase 3 (assumption, stated in the summary). Stakeholder: "Still matches". `light_path` stays false.

## 2026-10-29 Impact classification update (0.4.4, after round 4)

- Added: `post-implementation-audit.sh` `agent_type` filter widened to integration (extend); SubagentStop matcher in `claude-settings.template.json` and this repo's `.claude/settings.json` (extend; migration M1); `claude-settings.template.md` and hook headers (doc updates in scope). Light path keeps its detached worktree (D13). Full table in `data-model.md`.
- 0.4.7 re-check: with D11-D15 no goal or placement conflict remains. Continue at 0.5.

## 2026-10-29 End state (0.5)

- `verification-plan.md` written: eight End state objectives, journeys JRN-001 to JRN-010 (JRN-010 manual, first real launch), fixtures and oracles. Targets left for 1.1.

## 2026-10-29 Exit gate (0.6): clear

- Scope: Non-goals and `deferred` list the three shelved items; Open Questions empty. System impact: module audits for feature-workflow, hooks and lib in `codebase-map.md`; no cache disagrees with code. Data changes: `data-model.md` classifies every part; one reversible migration (M1). Testable objectives: both capabilities have objectives and journeys.
- Work item 005-cache-build-followups-disc-001.md deleted (origin kept in frontmatter and the Origin entry).

## 2026-10-29 Targets (1.1)

- Spec branch `spec/006-result-file-guard` created off main `16c72b1`; baseline `e049f4dde93474aca594212026144ed7006a917f`. Main moved since the handoff (`02bc218` to `16c72b1`) only in workflow data; nothing under `.agents/`, `tests/` or `install.sh` changed, so no contract the spec relies on moved.
- **D16 Guard time.** Recommended: `check-worktree-scope.sh --command` on a long read-only chain, real ≤ 0.2 s best of 3 (baseline 0.04 s). Answer: "≤ 0.2 s".
- **D17 Line coverage.** Recommended: not measured (no bash coverage tool; no new dependency). Answer: "Not measured".

## 2026-10-29 Harness build (1.2)

- Launched under `isolation: "worktree"` as the current `verification-setup.md` says; the isolation worktree forked from main `16c72b1`, not the spec branch. Claude Code's isolation refused the main-checkout result-file Write ("This agent is isolated in the worktree ... Edit the worktree copy") and heredoc and `$(git …)` commands. The agent wrote `implementation.yaml` in its worktree; the main session copied it into `artifacts/phase-1-test-harness/` by hand (the defect this spec removes). `check-task-result.sh` exit 0; stop audit clean.
- Merged `eb292c5` as `346b568`; isolation worktree and branch removed.
- Agent decisions to note: the existing `worktree-guard` deny case "task agent Bash without cd" now uses `npm test` instead of `git status`, since `git status` joins the read-only allowlist (verdict and hint unchanged). JRN-001 expects `wf_enc` to replace every non-`[a-z0-9]` byte under both locales (`Wéb` → `w__b`), where the old `codex_enc` gave `w_b` under UTF-8; every work type and agent type used today is ASCII, so names stay byte-identical.

## 2026-10-29 Task breakdown (2.1-2.5)

- Five tasks, one module each: T1 hooks (touches shared core: `wf_enc`, `wf_agent_worktree_name`), T2 artifacts gate, T3 agent briefs, T4 scope-check allowlist, T5 orchestrator text. Waves: 1 = T1, T2, T3; 2 = T4, T5; one shell-scripts integration batch before wave 1. Stakeholder: "Approve (Recommended)".
- T1 → T4 and T3 → T5 are gating edges for test ownership: `tests/run-all.sh` selects whole suite files, and `worktree-guard.sh` and `agent-worktree-docs.sh` each hold cases for two tasks.
- Seams (2.3) as the Phase 1 suites drive them. Stakeholder: "Agree (Recommended)".
- **D18 Size budget.** Recommended: project defaults, max_tasks 10, max_changed_files 30 (predicted 5 tasks, 12 non-test files). Answer: "Defaults 10 / 30".
