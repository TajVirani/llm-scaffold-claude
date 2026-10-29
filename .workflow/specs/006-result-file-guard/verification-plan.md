# Verification plan: Sub-agents can write their own result file

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-result-file-write: `wf_` encoder and name builder in `.agents/lib/workflow-paths.sh` give byte-identical names to the old `codex_enc` for every work type and agent type used today, under a UTF-8 and a C locale; neither hook keeps a `codex_enc` copy.
- [ ] CAP-NEW-result-file-write: for an implementation sub-agent whose header has `work_type` and no `task_id`, and for an integration sub-agent, `worktree-write-guard.sh` confines to `.workflow/.worktrees/s<NNN>_phase_1_<enc>` / `s<NNN>_integration_<enc>`: a Write inside it is allowed, a Write to the main checkout or another agent worktree is denied.
- [ ] CAP-NEW-result-file-write: the exact result-file command each of `implementation.md` (Phase 1 and Phase 3) and `integration.md` prescribes, with the agent's cwd in the main checkout, is allowed by the guard and leaves the file at `<main checkout>/<spec_dir>/artifacts/<id>/`, which `check-task-result.sh` accepts.
- [ ] CAP-NEW-result-file-write: the stop audit, for a Claude Phase 1 or integration launch, runs in its agent worktree (integration with the full toolchain, Phase 1 with `--skip test`), and warns and allows when the worktree is missing; the SubagentStop matcher in the template and this repo's settings covers integration, and an `install.sh` upgrade leaves exactly one SubagentStop entry.
- [ ] CAP-NEW-result-file-write: the artifacts gate script exits 0 for a branch or commit with no change under `<spec_dir>/artifacts/` since the merge-base, and refuses (non-zero, reason naming each path) an add, a modify and a delete there; committed `artifacts/` already on the spec branch do not trip it.
- [ ] CAP-NEW-result-file-write: `verification-setup.md` and `implementation-orchestrator.md` contain no `isolation: "worktree"` launch and no isolation fallback; they create Phase 1 and integration agent worktrees with `-b wf/NNN-slug/<name> spec/NNN-slug`, merge that branch, remove worktree and branch after merge, and call the gate before each of the five merge sites.
- [ ] CAP-NEW-worktree-read-commands: with cwd in the main checkout and a confinement root, `check-worktree-scope.sh --command` allows each allowlisted read and `|`/`&&` chains of them, and denies each per-tool writing flag and each shell form listed in the spec's success line; every existing allow and deny case in `tests/hooks/worktree-guard.sh` keeps its verdict.
- [ ] `tests/run-all.sh` passes and shellcheck is clean on every changed shell file.

## Journeys

The scaffold has no running application or browser suite. Each journey runs the real scripts and hooks against a fixture repo, checked by a harness suite under `tests/`.

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Names agree across hosts | CAP-NEW-result-file-write | 1. Call the lib encoder and builder for work types and agent types (`shell-scripts`, `test-harness`, `Web.UI`, `fact-lookup`) under `LC_ALL=C` and a UTF-8 locale. 2. Compare with the recorded `codex_enc` output. | Identical bytes; malformed spec folders return status 1. | `tests/scripts/lib-workflow-paths.sh` (JRN-001 cases) |
| JRN-002 | Phase 1 agent files its result | CAP-NEW-result-file-write | 1. Fixture repo with spec `007-demo`, worktree `.workflow/.worktrees/s007_phase_1_shell_scripts`. 2. Feed the guard a Phase 1 implementation sub-agent payload (cwd main checkout) running the brief's result-file command, then a Write inside, a Write to the main checkout, a Write to another worktree. 3. Run the command for real and `check-task-result.sh` on the file. | Command and inside Write allowed; outside Writes denied; the file exists in the main checkout and passes the checker. | `tests/hooks/worktree-guard.sh` (JRN-002 cases) |
| JRN-003 | Integration agent files its result | CAP-NEW-result-file-write | Same as JRN-002 with `s007_integration_shell_scripts` and an integration header. | Same verdicts; `integration.yaml` passes the checker. | `tests/hooks/worktree-guard.sh` (JRN-003 cases) |
| JRN-004 | Phase 3 result lands in the main checkout | CAP-NEW-result-file-write | 1. Phase 3 payload for `s007_t3`. 2. Run the brief's command. | Allowed; file in the main checkout, none in the worktree copy. | `tests/hooks/worktree-guard.sh` (JRN-004 cases) |
| JRN-005 | Stop audit finds the agent worktree | CAP-NEW-result-file-write | 1. SubagentStop payloads for a Claude Phase 1 and an integration launch, worktree present and absent. 2. Run `post-implementation-audit.sh` with a stand-in toolchain. | Present: toolchain runs in the worktree (Phase 1 with `--skip test`); absent: warn and allow. | `tests/hooks/audit-sync-resume.sh` or a new audit suite (JRN-005 cases) |
| JRN-006 | Settings matcher upgrade | CAP-NEW-result-file-write | 1. Target project installed with the old template. 2. Run `install.sh` again. | One SubagentStop entry, matching implementation and integration. | `tests/scripts/install-claude-settings.sh`, `install-upgrade.sh` (JRN-006 cases) |
| JRN-007 | Artifacts merge gate | CAP-NEW-result-file-write | 1. Fixture spec branch with committed `artifacts/T1/implementation.yaml`. 2. Task branches that: change only code; add, modify and delete a file under `artifacts/`. 3. A detached light-path commit of each kind. 4. Run the gate on each. | Code-only passes; every artifacts change is refused with its path; the pre-existing committed file does not trip it. | new `tests/scripts/<gate-script>.sh` (JRN-007 cases) |
| JRN-008 | Orchestrator text matches the design | CAP-NEW-result-file-write | 1. Grep `verification-setup.md`, `implementation-orchestrator.md`, `implementation.md`, `integration.md`. | No `isolation: "worktree"` launch or fallback; `-b wf/NNN-slug/` creation for Phase 1 and integration; gate call before each merge; absolute main-checkout result path in both briefs. | `tests/lint/` or a harness grep suite (JRN-008 cases) |
| JRN-009 | Read-only commands pass, writes do not | CAP-NEW-worktree-read-commands | 1. Confined payload, cwd main checkout. 2. Commands: each allowlisted read; `cat f \| head`; `grep x f && wc -l f`; each denied flag (`sed -i`, `sed -n 'w out'`, `find . -delete`, `find . -fprint x`, `yq -i`, `git diff --output=x`, `rg --pre cmd`); each shell form (`$(…)`, backtick, `<(`, `>`, `;`, `&`, `\|\|`, newline, `tee`). | Reads allowed; every flag and shell-form case denied with the `cd <worktree> &&` hint; existing cases unchanged. | `tests/hooks/worktree-guard.sh` (JRN-009 cases) |
| JRN-010 | A real launch files its own result | CAP-NEW-result-file-write | 1. In the next spec that runs Phase 1 or a Phase 3 wave with integration, launch through the new steps. | Each result file is in the main checkout without a copy step; the design log records no hand copy. | Manual at 5.x of this spec's dogfood run, or the next spec's first wave (evidence under `artifacts/`) |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Worktree-guard fixture repo | Git repo with `.agents/` copy, spec `007-demo`, agent worktrees `s007_t3`, `s007_t4`, `s007_phase_1_shell_scripts`, `s007_integration_shell_scripts`, sub-agent transcripts with launch headers | Extends `make_fixture_repo` and `mk_sub` in `tests/hooks/worktree-guard.sh` | JRN-002 to JRN-004, JRN-009 |
| Recorded `codex_enc` outputs | Expected names for the JRN-001 inputs | Run the old `codex_enc` at `baseline_revision` before Phase 3 | JRN-001 |
| Brief commands | The exact result-file command lines from `implementation.md` and `integration.md` | Extracted from the agent docs at test time, so a brief change re-tests | JRN-002 to JRN-004 |
| Toolchain stand-in | A `run-toolchain.sh` substitute that records its cwd and flags | Harness-written, as in the existing audit suites | JRN-005 |
| Old settings template | The pre-change `claude-settings.template.json` | `git show <baseline_revision>:.agents/hooks/claude-settings.template.json` | JRN-006 |
| Gate branches | Spec branch plus task branches and detached commits with each `artifacts/` change kind | Harness-written fixture repo | JRN-007 |
