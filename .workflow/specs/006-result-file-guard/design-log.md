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

## 2026-10-29 Integration batch shell-scripts (3.2)

- `wf_enc` and `wf_agent_worktree_name` applied (fd4a1d7, merged). Launched under `isolation: "worktree"` per the current module; isolation refused the main-checkout result-file write again (heredoc and Write), so the main session copied `integration.yaml` from the agent's worktree by hand. `check-task-result.sh` exit 0; `toolchain.json` pass. `lib-workflow-paths` 98 passed, 1 failed (the hooks' `codex_enc` check, owned by T1).
- Task PRs: `origin` is a local path, so `open-task-pr.sh` skips before pushing ("origin host is neither GitHub nor GitLab"); task merges are local and `pr` stays null.

## 2026-10-29 Discovered work: refusal-line-count-test

- Found at: step 3.4 by the T2 implementation agent (`artifacts/T2/implementation-r1.yaml`). Kind: bug
- Problem and evidence: the Phase 1 helper `expect_refused` in `tests/scripts/check-merge-artifacts.sh:89` compares the output line count with `$#` inside the expression it hands `check`, which evals it in its own body (`tests/lib/common.sh:65-66`), so `$#` is always 3; the 7 refusal cases fail with a correct gate (right exit code and paths).
- Assessment and ruling: blocker (JRN-007 cannot pass); stays blocked, human resolves. Stakeholder: "Fix in T2 (Recommended)": T2's agent fixes the three test lines on its task branch and reruns its gates; no loop back.

## 2026-10-29 Wave 1 gates (3.4)

- T2 and T3 returned `tests_added: []`. T2's gate is covered by its Phase 1 suite, which already holds negative cases (every exit-2 usage and environment error) and edge cases (look-alike folder, a branch synced with the newer spec branch, detached commits); T3 is doc text whose cases live in T4's and T5's suites. 3.4 judged met without a resume. T2's fix round added a `shellcheck disable=SC2034` line beside the ruled `want=$#` fix (the variable is read only inside the evaled check expression).

## 2026-10-29 Discovered work: upgrade-matcher-merge

- Found at: step 3.4 by the T1 implementation agent (`artifacts/T1/implementation.yaml`, status scope-expansion, requested path `install.sh`). Kind: scope-expansion
- Problem and evidence: `install.sh` `merge_groups` (`JQ_MERGE`) appends only hook commands missing under an event, so an upgrade keeps the old SubagentStop group (matcher `implementation`) and integration agents in upgraded targets are never stop-audited; `scripts/install-upgrade` "JRN-006 after the upgrade: the stop audit matcher matches integration" fails. The 2.1 breakdown missed it: no task owned the installer module. How to treat a hand-edited matcher is undecided.
- Assessment and ruling: blocker (End state "an `install.sh` upgrade leaves exactly one SubagentStop entry", JRN-006); to discovery (spec back to draft). Stakeholder: "Back to discovery (Recommended)".
- State kept: T2 (gate) and T3 (briefs) passed 3.8, unmerged on their task branches; T1 done apart from the upgrade case (52daec3, toolchain red on that one case), unmerged. Task worktrees s006_t1, s006_t2, s006_t3 left in place. The integration batch is merged on the spec branch.
Outcome: loop back (00.24 discovered work)

## 2026-10-29 Facts behind round 5 (0.3.10)

- fact-lookup: `install.sh` `merge_groups` matches groups by hook command only and never reads or rewrites an existing group's matcher; no scaffold-owned marker exists (`install.sh:212-218`, `:237-242`; `claude-settings.template.md` § Merge rules). No template matcher has changed before (`git log -G'"matcher"'`: aa05f00, 4640be9). Codex's SubagentStop group has no matcher (`codex-hooks.template.json:68-79`). Warnings print in a `Warnings:` block on stdout, also under `--dry-run` (`install.sh:119-122`, `:578-581`). JRN-006 asserts one SubagentStop entry, one stop-audit group, and matches for `implementation` and `integration` (`tests/scripts/install-upgrade.sh:81-96`); no case covers a user-edited matcher.

## 2026-10-29 Questioning round 5 (0.3.11)

- **D19 Upgrade rule for a changed matcher.** Options: widen by union of `|` alternatives with a warning; replace with the template's and warn; warn only. Recommended: widen by union. Answer: "Ask the user if they want to replace or split the matchers, list what is currently there and what the replace would turn it into." The installer asks per differing group, showing the current matcher and the proposed one; "split" and the no-answer case are open (round 6).
- **D20 Rule scope.** Options: every event; SubagentStop only. Recommended: every event. Answer: "Every event (Recommended)".

## 2026-10-29 Facts behind round 6 (0.3.10)

- fact-lookup: `install.sh` never prompts or reads stdin; flags are `<target>`, `--host`, `--force`, `--dry-run`, `-h` (`install.sh:62-82`). Test suites call it through `INST()` with no stdin redirect (`tests/scripts/install-*.sh`), so an unguarded prompt could hang them. Refusals print to stderr and exit 1 before any write, also under `--dry-run` (`install.sh:461-467`, `:583-586`). Matcher behaviour is in no user doc; the lines to update are README "Install and upgrade" L88-94, CHANGELOG 2.0.0 Migration (L55-57), `claude-settings.template.md` Merge rules L48 and L54, and the `install.sh` header (L18-20, Conflicts L32-38).

## 2026-10-29 Questioning round 6 (0.3.11)

- **D21 What "split" means.** Options: merge both matchers' `|` alternatives into one group; add a second group with the template's extra alternatives. Recommended: merge into one. Answer: "Merge into one (Recommended)" (`implementation|foo` with template `implementation|integration` gives `implementation|foo|integration`; replace gives the template's value).
- **D22 No terminal (CI, test suites) and `--dry-run`.** Options: keep and warn; refuse; merge silently. Recommended: keep and warn. Answer: "Merge silently": without a terminal the installer applies the merge and prints a Warnings line; `--dry-run` shows the change and asks nothing.
- **D23 Command-line choice.** Options: `--matchers=replace|merge|keep`; `--force` implies replace. Recommended: `--matchers=MODE`. Answer: "--matchers=MODE (Recommended)"; `--force` leaves matchers alone.
- **D24 Docs.** Options: all four (install.sh header, README "Install and upgrade", `claude-settings.template.md` Merge rules, a CHANGELOG 2.0.0 Migration line); code docs only. Recommended: all four. Answer: "All four (Recommended)".

## 2026-10-29 Questioning round 7 (0.3.11)

- **D25 Prompt answers.** Options: merge/replace/keep with Enter = merge; merge/replace only. Recommended: merge/replace/keep, Enter = merge. Answer: "Merge/replace/keep, Enter=merge (Recommended)". The prompt names the event and the scaffold command, and shows current, replace and merge lines; keep leaves the group and warns.

## 2026-10-29 Goal re-settled (0.3.19), after the upgrade-matcher-merge loop-back

- Summary of D19-D25 restated: `install.sh` merges, replaces or keeps a differing matcher per hook group on every event (prompt at a terminal with Enter = merge, merge with a warning without one, `--matchers=merge|replace|keep`, `--dry-run` asks nothing, `--force` leaves matchers alone), documented in four places. Placement: installer module (new owner for this spec), hooks (`claude-settings.template.md` Merge rules, T1's file), root-docs (README; CHANGELOG has no owning module and goes with root-docs). Still one feature: the upgrade rule joins CAP-NEW-result-file-write's success line. Stakeholder: "Matches". `light_path` stays false.

## 2026-10-29 Light-path test (0.3.20), re-run

- `light_path: false`: footprint now spans lib, feature-workflow, hooks, agents, installer, root-docs and tests. Continue at 0.4.

## 2026-10-29 Impact classification update (0.4.4, after rounds 5-7)

| Part | Module | Class |
| --- | --- | --- |
| `install.sh` `merge_groups`: per-group matcher resolution (merge / replace / keep) on every hook event | installer | extend |
| `install.sh` terminal prompt, `--matchers=MODE` flag, no-terminal merge with a warning, `--dry-run` preview | installer | create |
| `install.sh` header (usage, flags, Conflicts, hook merge summary) | installer | doc update |
| `.agents/install-manifest.txt` | installer | unchanged |
| `claude-settings.template.md` Merge rules (L48, L54) | hooks | doc update (joins T1's file) |
| README "Install and upgrade" | root-docs | doc update |
| CHANGELOG 2.0.0 Migration line | none (no owning module; with root-docs) | doc update |
| `tests/scripts/install-upgrade.sh` JRN-006, new prompt and flag cases | tests | extend |
| Codex `.codex/hooks.json` merge | installer | unchanged in effect (no matcher on its groups) |

## 2026-10-29 Module audit installer (0.4.6) and conflict check (0.4.7)

- `module-audit` (installer) written to `codebase-map.md`. No cache disagrees with code. Its decision lines (mixed groups, matcher forms, what "per group" means, dry-run preview, re-run idempotence) are goal conflicts at 0.4.7, sent back to the loop as round 8.

## 2026-10-29 Questioning round 8 (0.3.11)

- **D26 Mixed groups.** Options: ask (the prompt lists every hook in the group) and never auto-merge a group holding a non-template hook (keep and warn without a terminal; `--matchers` still applies); treat all groups alike. Recommended: ask, never auto-merge. Answer: "Ask, never auto-merge (Recommended)".
- **D27 Matcher forms.** Options: absent, `""` and `"*"` are match-all, an existing match-all group is never touched, a match-all template makes merge and replace drop the matcher, and merge is offered only when both matchers are plain alternations (`[A-Za-z0-9_|]`); absent only, split everything. Recommended: the first. Answer: "Match-all + plain only (Recommended)".
- **D28 Per group.** Options: each existing group running at least one command of a template group under a matcher that does not cover the template's is resolved on its own, missing commands still appended; the template group as one unit. Recommended: each existing group. Answer: "Each existing group (Recommended)".
- **D29 Re-runs and --dry-run.** Options: a matcher whose alternatives include all of the template's counts as no difference (idempotent), and `--dry-run` without `--matchers` previews the no-terminal outcome; dry-run lists only. Recommended: the first. Answer: "Covered = same; preview default (Recommended)".

## 2026-10-29 Goal re-settled (0.3.19), after round 8

- D26-D29 restated as one rule; written into `spec.md` Constraints. Stakeholder: "Matches". `light_path` stays false; 0.4.4 classification unchanged by round 8.

## 2026-10-29 End state (0.5), after the upgrade-matcher-merge loop-back

- `verification-plan.md`: one End state objective for the matcher resolution; journeys JRN-011 (no terminal), JRN-012 (`--matchers`, dry-run, `--force`, non-plain matcher), JRN-013 (terminal prompt, pseudo-terminal, skipped where none exists), JRN-014 (four docs); fixtures "Upgrade target with user groups" and "Pseudo-terminal". Targets and Suites keep their rows; 1.1 re-entry adds targets only for the new work.

## 2026-10-29 Exit gate (0.6): clear, after the loop-back

- Scope: Open Questions empty; the audit's can-wait lines were ruled in round 8 (D27 non-plain matchers, D29 dry-run), nothing shelved. System impact: installer audit in `codebase-map.md`; no cache disagrees with code. Data changes: `data-model.md` adds matcher resolution and M2 after M1. Testable objectives: the new objective has JRN-011 to JRN-014.

## 2026-10-29 Targets (1.1), re-entry for JRN-011 to JRN-014

- Baseline `e049f4d` and the existing Targets rows kept. **D30 Installer targets.** Options: none new; a no-hang row (upgrade with stdin an open pipe exits within 10 s); a no-op re-run time row. Recommended: none new (script-lint, script-coverage and agent-docs-lint already cover `install.sh`, README and the template doc; JRN-011 to 014 prove the behaviour). Answer: "None new (Recommended)".

## 2026-10-29 Harness build (1.2), re-entry for JRN-011 to JRN-014

- Launched under `isolation: "worktree"` as the current `verification-setup.md` says. The agent fast-forwarded to the spec branch first (base `b5f0e56`). Isolation refused the main-checkout result-file write again; the main session copied `implementation.yaml` from the agent's worktree by hand (the earlier round kept as `implementation-r1.yaml`). `check-task-result.sh` exit 0; stop audit clean (`toolchain.json` pass, no `audit.json`).
- Merged `1058a0d` as `04aba50`; isolation worktree and branch removed. Adds JRN-011 to 013 cases to `tests/scripts/install-upgrade.sh`, the new JRN-014 suite `tests/lint/install-matcher-docs.sh`, fixture helpers in `tests/fixtures/claude-settings.sh`, and `</dev/null` on every `install.sh` call in the six `tests/scripts/install-*.sh` suites.
- Agent notes: the JRN-011 to 013 cases upgrade to a copy of today's template with the SubagentStop matcher widened, so they do not depend on T1's merge order. Cases pinning behaviour that is already right (match-all, covered and mixed groups untouched, `keep`, `bogus` exit 2, dry runs write nothing, `(a|b)c` never merged, no hang under a pseudo-terminal) pass on today's `install.sh`.

## 2026-10-29 Discovered work: slow-install-upgrade-suite

- Found at: step 1.2 by the implementation agent (phase-1-test-harness, `artifacts/phase-1-test-harness/implementation.yaml`). Kind: refactor
- Problem and evidence: `tests/scripts/install-upgrade.sh` takes about 66 s alone and 156 s in a parallel run, past `tests/README.md:29` "Every suite takes under a minute".
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-001.md](../work-backlog/006-result-file-guard-disc-001.md)

## 2026-10-29 Task breakdown (2.1-2.5), re-run after the upgrade-matcher-merge loop-back

- T1-T5 records and statuses kept. T1 gains the Merge rules lines in `claude-settings.template.md` (D19-D29) and hands `tests/scripts/install-upgrade.sh` and its upgrade acceptance line to T6.
- New: T6 "Upgrade resolves hook matchers per group" (installer, `install.sh`, M, depends on T1) owns `tests/scripts/install-upgrade.sh`; T7 "Docs describe the upgrade matcher rule" (root-docs, `README.md`, `CHANGELOG.md`, S, depends on T6) owns `tests/lint/install-matcher-docs.sh`. Both edges gate test ownership. Waves: 1 = T1, T2, T3; 2 = T4, T5, T6; 3 = T7. Stakeholder: "Approve (Recommended)".
- Seams (2.3): T6 through the `install.sh` CLI on a fixture target; T7 through grep over the four docs. Stakeholder: "Agree (Recommended)". No new shared-core request (2.4). Budget D18 unchanged.

## 2026-10-29 T1 fix round (3.4-3.6)

- Fresh agent in `s006_t1` (the first T1 agent belonged to an earlier session). It merged the spec branch (`689fa8c`) and added the Merge rules lines (`fca013e`); round 1 kept as `artifacts/T1/implementation-r1.yaml`. The result file landed in the main checkout with no copy step. `check-task-result.sh` exit 0; `toolchain.json` pass (lint clean, 3 own suites, scoped), no `audit.json`.
- 3.4 judged met: `tests_added` is empty in both rounds, and T1's Phase 1 suites already hold its negative and edge cases (malformed spec folder returns 1, outside writes denied, missing worktree warns, failing integration toolchain blocks).
- 3.7 diff base: `implementation.yaml` `base_commit` is round 1's head (`52daec3`); the mini-review gets the spec-branch tip `4b66751` with a three-dot diff, so it judges the whole task change.

- Duplicate discovered work: header-worktree-kind-mapping matches .workflow/deferred/worktree-name-parser.md; line appended.

## 2026-10-29 Discovered work: codex-integration-missing-transcript

- Found at: step 3.7 by profile-mini-review for T1 (`artifacts/T1/mini-review.yaml` out_of_scope_noticed). Kind: bug
- Problem and evidence: `post-implementation-audit.sh:121` warns on a missing or unreadable transcript before the Codex integration exit at `:129`, so a Codex integration stop with no transcript now gets a warning (worded for an implementation stop at 3.7) where every integration stop used to exit silently; against T1's criterion "Codex and Phase 3 behaviour is unchanged".
- Assessment and ruling: blocker (T1's acceptance criterion cannot be met as built); stays in T1. Stakeholder: "Fix in T1, silent exit (Recommended)": an integration stop with no readable transcript exits silently on both hosts, as before T1; fixed in T1's fix round with the R4 item. No loop back.

## 2026-10-29 T1 mini-review round 2 (3.7-3.8)

- Verdict fail, item 3 `worktree-write-guard.sh:102`: a header the lib cannot name left the name empty with no deny, so the agent ran unconfined (fail-open). Behaviour fix round with a fresh agent; the next review is full. The reviewer's Sources-line note (guard header omits `lib/workflow-paths.sh`) is T1's own file and goes into the same round.
- Checklist item 3 wording against the silent-exit ruling: a profile change, so proposal P1 in `proposals.md` for 5.3.

## 2026-10-29 Discovered work: spec-folder-digit-rule

- Found at: step 3.7 by profile-mini-review for T1 (`artifacts/T1/mini-review-r2.yaml` out_of_scope_noticed). Kind: decision
- Problem and evidence: `wf_agent_worktree_name` needs three or more digits in the spec number (`.agents/lib/workflow-paths.sh:135`), while `resolve-launch.sh --parse-header` and the pre-change guard accepted any count.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-002.md](../work-backlog/006-result-file-guard-disc-002.md)

## 2026-10-29 T1 mini-review round 3 (3.7-3.8)

- Verdict pass (13 of 13), full review of `4b66751...9e706b7`. T1 ready to merge.

## 2026-10-29 Discovered work: guard-allows-without-confinement

- Found at: step 3.7 by profile-mini-review for T1 (`artifacts/T1/mini-review.yaml` out_of_scope_noticed, two decision entries). Kind: decision
- Problem and evidence: the guard allows a non-isolated agent when the header cannot be parsed (`worktree-write-guard.sh:92-93`) or the named worktree is missing (`check-worktree-scope.sh:101-104` rule 3), against `.workflow/profiles/shell-scripts.md:25` "Guard hooks fail closed"; both predate 006 for Phase 3.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-003.md](../work-backlog/006-result-file-guard-disc-003.md)

## 2026-10-29 Wave 1 merged (3.16, 3.15, 3.9)

- T1 `c8deecd`, T2 `a518317`, T3 `c2e1159`, in id order; task PRs skipped (local `origin`). Budget: 7 tasks, 12 of 30 changed files. Gate 3.9 w1: pass, `TOTAL passed=3138 failed=0 (56 suites)`, 4 unfinished tasks' suites excluded (`artifacts/gate-3.9-w1/`).
- Wave 2 launched: T4, T5, T6 in `s006_t4`, `s006_t5`, `s006_t6` off `97b627c`.

## 2026-10-29 Wave 2 gates (3.4-3.8), T4 and T5

- T5: doc text; `tests_added` empty, its JRN-008 suite is the check (3.4 met as for T3). Mini-review r1 failed R4 (two added `# e.g.` lines naming a workflow path and spec folder). Wording-only round on the same agent also removed the older `# e.g.` line and added the no-relaunch reason (both reviewer notes, in T5's own files). Re-check launched.
- T4: done with one negative and one edge entry (19 new edge cases), JRN-009 green; `yq -s`/`--split-exp` also denied; GNU sed `e` left out (`considered_not_built`). Guard-time on the plan's chain: 0.04 s best of 3 from the main checkout. Note for 4.3: the `guard-time` target command must run from the main checkout; from a linked worktree the scope check allows at the cwd step and never reaches the allowlist.

## 2026-10-29 T4 mini-review round 1 (3.7-3.8)

- Verdict fail, R2 `check-worktree-scope.sh:167-168` (the lone-`&` check relies on the `&&` rewrite above it, unexplained). The reviewer's note that `sed -n '1wout.txt'` (w with an attached file name) passes as read-only is T4's own acceptance criterion ("sed w/W denied"), not out-of-scope work, and the spec settles it: behaviour fix round with a fresh agent, full review next.

## 2026-10-29 Discovered work: gnu-sed-exec-command

- Found at: step 3.7 by profile-mini-review for T4 (`artifacts/T4/mini-review-r1.yaml` out_of_scope_noticed). Kind: bug
- Problem and evidence: GNU sed's `e` command runs a shell command, and `check-worktree-scope.sh:140` does not deny it, so `sed -n '1e touch x'` passes as a read; not in the spec's deny list.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-004.md](../work-backlog/006-result-file-guard-disc-004.md)

## 2026-10-29 T4 mini-review round 2 (3.7-3.8)

- Verdict fail, R2 `check-worktree-scope.sh:167, 172` (no reason for the `<` denial, which stops `<(cmd)`, or for the trailing `|` that ends the segment loop). Reviewer notes: sed `w` still passes with a letter delimiter (`sxaxbxwout.txt`, `\xaxwout.txt`) and through `-f <script>`; header and comments differ from the code (carriage return missing from the header denylist; the "after a non-letter" comment).
- **D31 sed reads.** A deny regex cannot close the sed write class. Options: allowlist sed scripts (only `sed -n` with line or `/regex/` addresses and `p` counts as a read; anything else needs the `cd`); keep the denylist; drop sed from the allowlist. Recommended: allowlist. Answer: "Allowlist sed scripts (Recommended)". This also covers backlog item disc-004 (GNU sed `e`); offer it as dismissed at 5.9. Behaviour fix round with a fresh agent covering D31, R2 and the doc mismatches; full review next.

## 2026-10-29 Discovered work: quoted-dollar-reads

- Found at: step 3.4 by the T4 implementation agent (`artifacts/T4/implementation.yaml` `discovered_work[0]`). Kind: decision
- Problem and evidence: `read_only_chain` denies any `$`, so the sed `$` address the D31 allowlist accepts can never pass (`sed -n -e '1p' -e '$p' f` exits 2); the fix brief's allow case for it was replaced by `-e '1p' -e '5p'`.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-005.md](../work-backlog/006-result-file-guard-disc-005.md)

## 2026-10-29 T6 mini-review round 1 (3.7-3.8)

- Verdict fail, item 3 `install.sh:283, :296`: a group running commands of two template groups of one event gets a second question the first pass never asked; the missing answer leaves it unchanged, or one answer narrows it to one template's matcher, so the other hook silently loses coverage (e.g. `Write|Edit|NotebookEdit` holding the Write guard and the git guard, answered `r` for Bash).
- Reviewer notes, both T6's own scope: a non-plain user matcher is dropped when the template matcher is match-all, against the spec constraint "Merge is offered only for plain `|` alternations" (fix: keep with a warning); the non-plain `--matchers=merge` test also accepts the replaced value (tighten).
- **D32 Group running two template groups' commands.** Options: keep with a warning; merge both template matchers; split it. Recommended: keep with a warning. Answer: "Go with the repos matcher - I would imagine unless this is user created, we want whatever we ship in the update. IF its user created, keep the user created one with a warning." Read as: a group holding only template commands from two or more template groups is rewritten to the template's own groups and matchers, in every mode, with a Warnings line; a group that also holds a non-template hook is kept unchanged with a Warnings line. Behaviour fix round with a fresh agent; full review next.

## 2026-10-29 T4 mini-review round 3 (3.7-3.8)

- Verdict pass (10 of 10 applicable), full review of `97b627c...d612b9d`. T4 ready to merge.
- Reviewer notes: the sed allowlist also accepts `-E`/`-r` (with `-n`), which D31 does not name; they do not change how an address parses and open no write or exec path, so accepted as within D31's intent. The header says sed words carry no backslash, but a single-quoted file operand may; no write passes through it (a file operand cannot write under `sed -n`). Left as a header-wording candidate for Phase 4 (review-standards), not a new round.

## 2026-10-29 T6 mini-review round 2 (3.7-3.8)

- Verdict fail: item 3 `install.sh:105, :117` (an empty `--matchers=` is taken as no flag, not exit 2); item 8 `tests/scripts/install-upgrade.sh:354, :359` (two `shellcheck disable=SC2329` lines without a reason); R1 `:367, :385` (loop variable `session` holds the expected SessionStart outcome). Behaviour fix round with a fresh agent; full review next.

## 2026-10-29 Discovered work: prompt-eof-merges

- Found at: step 3.7 by profile-mini-review for T6 (`artifacts/T6/mini-review-r2.yaml` out_of_scope_noticed). Kind: decision
- Problem and evidence: end of input at the matcher prompt counts as Enter and merges with no Warnings line (`install.sh:440`, header `:434`).
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-006.md](../work-backlog/006-result-file-guard-disc-006.md)

## 2026-10-29 T6 mini-review round 3 (3.7-3.8)

- Verdict fail: item 3 `install.sh:280` (a group whose matcher is not a string is kept with no Warnings line, against the header's "kept with a warning"); R2 `install.sh:333-336` (no reason for removing rewritten groups after the reduce). Reviewer note: a D32 rewrite replaces the user's hook objects with the template's, so per-hook keys such as a custom timeout reset to the template's, and the warning does not say so. That follows D32 ("we want whatever we ship"); the warning will name it (T6's own scope). A non-string matcher is malformed: kept with a warning in every mode, `replace` included. Behaviour fix round 4 of 5 with a fresh agent, briefed to check every branch of the resolution against the header; full review next.

## 2026-10-29 T6 mini-review round 4 (3.7-3.8)

- Verdict fail, item 8 `tests/scripts/install-upgrade.sh:62` (the `warned_once` SC2329 disable has no reason; the block comment counts four readers). Reviewer note: `group_cmds` counts only hooks with a `command` string, so a user hook of another type (prompt-type) is not "own"; a group with one template command and such a hook is merged without a terminal, against D26 ("a mixed group is kept") and against `split_or_keep`, which does count it. T6's own rule, so it joins the round. Fix round 5 of 5 (behaviour, fresh agent, full review); a failing review after it is a stop.

## 2026-10-29 T6 mini-review round 5 (3.7-3.8)

- Verdict pass (11 of 11 applicable), full review of `97b627c...b78d868`. T6 ready to merge after five fix rounds.

## 2026-10-29 Discovered work: rerun-checks-ignore-exit

- Found at: step 3.7 by profile-mini-review for T6 (`artifacts/T6/mini-review.yaml` out_of_scope_noticed). Kind: bug
- Problem and evidence: three "re-run writes nothing" checks in `tests/scripts/install-upgrade.sh` (`:280-281`, `:408-409`) do not assert exit 0, so a refusing re-run would pass.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/006-result-file-guard-disc-007.md](../work-backlog/006-result-file-guard-disc-007.md)

## 2026-10-29 Wave 2 merged (3.16, 3.15, 3.9)

- T4 `9892695`, T5 `86d7b0a`, T6 `c3c0e7d`, in id order; task PRs skipped (local `origin`). These merges ran before T5's gate text was on the spec branch, so no artifacts gate was run for them; from T7 on the merged T5 text applies. Budget: 7 tasks, 16 of 30 changed files. Gate 3.9 w2: pass, `TOTAL passed=3452 failed=0 (59 suites)`, T7's suite excluded (`artifacts/gate-3.9-w2/`).

## 2026-10-29 Wave 3 merged and implementation done (3.16, 3.15, 3.9, 3.11)

- T7 `Merge T7`, after the artifacts gate (`check-merge-artifacts.sh --rev task/006-result-file-guard/T07-docs-upgrade-matcher-rule`, exit 0): the first merge run under T5's new 3.16 text. Budget: 7 tasks, 18 of 30 changed files.
- 3.9 wave 3 (last): full harness 3472 passed, 0 failed, 60 suites, nothing excluded (`artifacts/gate-3.9-w3/`); lint clean. 3.10-3.11: no browser suite (Suites, Browser row: not applicable), so no e2e run; in-review at 3.11, as in spec 005.
- JRN-010 (a real launch files its own result) is partly met already: every Phase 3 implementation and mini-review in this spec wrote its result file to the main checkout with no copy step. The Phase 1 and integration half needs the next spec's launch under the new T5 text.

## 2026-10-29 Triage, review pass 1

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | review-end-state (RE-1) | The integration and Phase 1 briefs still name "the checkout you were launched in" as the worktree; under the no-isolation launch that is the main checkout, so the prescribed result-file command `cd`s there and the guard denies it | `.agents/agents/integration.md:71`, `:79`, `:93`; `.agents/agents/implementation.md:30` | high | Read at HEAD `5fdfb89`: no `cd <worktree> &&` rule in integration.md, result-file command `cd <absolute path of the checkout you were launched in> && ...`; orchestrator `:29` launches without isolation from the main checkout; breaks the success line "each brief's prescribed result-file write passes the guard"; `tests/hooks/worktree-guard.sh:174` fills the placeholder with the agent worktree, so no test sees it | patch (T3) |
| F2 | review-end-state (RE-2) | Orchestrator 3.2 says no stop audit fires for integration, but on Claude it now does | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:120` | low | `post-implementation-audit.sh` now runs for `implementation\|integration`; the orchestrator would not read `artifacts/integration-<wt>/audit.json`; text fix, no guard added | patch (T5) |
| F3 | review-standards (RS-1) | Guard messages and headers say "task worktree", a glossary _Avoid_ alias, now shown to Phase 1 and integration agents | `check-worktree-scope.sh:2`, `:114`, `:125`, `:234`; `worktree-write-guard.sh:2` | low | Lines predate 006; the deny still names the right path and `cd` fix | discovered work (filed: work-backlog/006-result-file-guard-disc-008.md) |
| F4 | review-standards (RS-2) | `assetlist.md` still gives the old matcher and the isolation fallback, with no amendment note | `assetlist.md:40`, `:234` | low | Scaffold-only record, never installed; no task owns it | discovered work (filed: work-backlog/006-result-file-guard-disc-009.md) |
| F5 | review-lessons (RL-1) | The `yq --front-matter=extract:*` allow entry also matches `-i`, the in-place rewrite a pitfall records | `.agents/hooks/claude-settings.template.json:130`; `.claude/settings.json:141` | medium | Unchanged since baseline `e049f4d`; pre-existing | discovered work (filed: work-backlog/006-result-file-guard-disc-010.md) |

Targets: 7 of 7 measurable pass (guard-time 0.04 s); line coverage not measurable (D17). Gaps: JRN-010 (a real no-isolation Phase 1 or integration launch, including whether Claude Code accepts the heredoc result-file command) is the manual 5.x check, run with F1 fixed. The end-state lens's third open item (wave 2 merged before the gate text) is settled: no merge from T1 to T7 changed anything under `artifacts/`.

Failed lenses: none
Outcome: rework 1 of 5

## 2026-10-29 Rework 1 (4.7 → 3.x)

- T3 (F1): integration.md gains a "Confirm the worktree" step naming `s<NNN>_integration_<enc>` with the `cd <worktree> &&` rule, and every "checkout you were launched in" now names that worktree; implementation.md names `s<NNN>_phase_1_<enc>` for Phase 1. `tests/hooks/worktree-guard.sh` now fills a `launched` placeholder with the main checkout and checks the filled result-file command starts with `cd <agent worktree> &&` (red on the old brief). Mini-review pass. Its note that `lint/agent-worktree-docs` was excluded from T3's run (T5 reopened) was settled by running it in T3's worktree: 27/27, guard suite 168/168.
- T5 (F2): the 3.2 Toolchain bullet says the Claude stop audit runs the full toolchain in the integration worktree (Codex none) and how to read `toolchain.json` and `audit.json`; one wording round on its own clause; re-check pass. A reviewer resume fixed a mini-review file missing an item `location`.
- Both merged after the artifacts gate (exit 0): T3 `faeb1df`, T5 `9b30638`.
- Gate 3.9 after rework 1: full harness pass, nothing excluded (`artifacts/gate-3.9-rework1/`); in-review at 3.11.

## 2026-10-29 Triage, review pass 2

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |

No findings from any lens. review-end-state confirms F1 and F2 fixed (rework 1). Targets: 7 of 7 measurable pass (guard-time 0.04 s); line coverage not measurable (D17). Gap: JRN-010 (a real no-isolation Phase 1 or integration launch filing its own result file, including whether Claude Code accepts the heredoc command) stays the manual 5.x check.

Failed lenses: none
Outcome: clean, to sign-off
