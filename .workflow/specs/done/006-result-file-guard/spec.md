---
status: done # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "e049f4dde93474aca594212026144ed7006a917f" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/006-result-file-guard # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "5a7f8c9fdec8822cbd1955a655573f0acc5b0679" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/worktree-name-parser.md, .workflow/deferred/codex-spawn-profile-lookup.md, .workflow/deferred/known-bad-evidence-path.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 005-cache-build-followups-disc-001.md # filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
budget: {max_tasks: 10, max_changed_files: 30} # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Sub-agents can write their own result file

## Why

Origin: work item 005-cache-build-followups-disc-001.md. The implementation, integration and profile-mini-review sub-agents must each file one result file under the spec's `artifacts/` in the main checkout, where the orchestrator checks it with a script. In spec 005 the Phase 1 build and the integration batch could not: Claude Code's own worktree isolation, used for those two launches, refused the write, and the main session copied the files by hand. Phase 3 agents wrote theirs into the worktree copy instead of the main checkout. The worktree guard also refused harmless read commands that did not start with `cd <worktree> &&`.

After this change every one of those agents writes its result file straight to `<main checkout>/<spec_dir>/artifacts/<id>/`, the orchestrator never copies or retypes one, read-only commands pass the guard, and every other write stays confined to the agent's worktree.

## Capabilities

- **CAP-007** Sub-agents file their own result file
  - **intent:** Implementation (Phase 1 and Phase 3), integration and profile-mini-review agents write their result file to `<main checkout>/<spec_dir>/artifacts/<id>/` themselves, so the orchestrator checks the file the agent wrote.
  - **success:** On Claude, Phase 1 and integration launches run in agent worktrees the orchestrator creates (`s<NNN>_phase_1_<enc(work_type)>`, `s<NNN>_integration_<enc(work_type)>` on branch `wf/NNN-slug/<name>` off the spec-branch tip, reused on relaunch, removed after merge) with no `isolation`; the worktree guard confines them by name and the stop audit runs in them, integration agents included, also in a target project upgraded by `install.sh` (an existing hook group that runs a template command under a differing matcher is merged, replaced or kept per group, asked at a terminal, merged with a warning without one, or set by `--matchers=merge|replace|keep`, on every hook event); each brief's prescribed result-file write passes the guard; and a new gate script, given a branch or the light-path commit, refuses the merge when it adds, modifies or deletes anything under `<spec_dir>/artifacts/` since the merge-base with the spec branch, each shown by suite cases in `tests/`.
- **CAP-008** Read-only commands pass the worktree guard
  - **intent:** A confined agent can run a read-only command from the main checkout without the leading `cd <worktree> &&`.
  - **success:** `check-worktree-scope.sh` allows a command made only of allowlisted read commands (cat, head, tail, grep, rg, ls, wc, `sed -n`, find, git log/show/diff/status, yq, jq) joined by `|` or `&&`, and denies it without the leading `cd` when any segment uses a writing or exec flag (`sed` `w`/`W`/`-i`; `find` `-delete`/`-exec`/`-execdir`/`-ok`/`-okdir`/`-fprint*`/`-fls`; `yq`/`jq` `-i`; `git --output`; `rg --pre`) or the command contains `$`, a backtick, `<`, `>`, `;`, a lone `&`, `||`, a newline or `tee`; every other command still needs the leading `cd`, each shown by suite cases in `tests/hooks/worktree-guard.sh`.

## Constraints

- bash 3.2 and git only (plus the jq and yq the project already requires); no new dependency.
- No agent that writes a result file is launched with `isolation: "worktree"`: Claude Code's isolation layer cannot be configured from this repo. The isolation fallback in `implementation-orchestrator.md` is removed; an agent that keeps getting denied becomes a blocked task.
- Agent worktree names match the Codex `task_name` forms byte for byte, built by `wf_` functions in `.agents/lib/workflow-paths.sh` pinned to `LC_ALL=C` that replace both `codex_enc` copies (shared core, changed only through the integration agent).
- The light path keeps its detached worktree and `--ff-only` merge.
- Writes other than the agent's own result file stay confined to its worktree.
- `install.sh` never waits on input without a terminal on stdin and stdout; `--dry-run` shows matcher changes and asks nothing; `--force` does not change matchers.
- Matcher resolution touches only an existing group that runs a template command under a matcher not already covering the template's (re-runs ask nothing). A match-all group (absent, `""`, `"*"`) is never touched. Merge is offered only for plain `|` alternations. A group that also holds a non-template hook is never merged without a terminal or `--matchers`: it is kept with a warning, and its prompt lists every hook in it.
- The matcher rule, the prompt and `--matchers` are documented in the `install.sh` header, README "Install and upgrade", the Merge rules of `claude-settings.template.md` and a CHANGELOG 2.0.0 Migration line.
- A group that runs commands of two or more template groups of one event under a matcher that does not cover them all is never asked about. If it holds only template hooks, it is rewritten into the template's groups, with the template's matchers and hook settings. If it also holds a hook of the user's own (of any hook type), it is kept. Either way a Warnings line is printed (D32). A malformed (non-string) matcher is kept with a warning in every mode.

## Non-goals

- Admitting Phase 4 pass files or other artifacts (`audit.json`, evidence) through the guard.
- Changing or working around Claude Code's built-in worktree isolation.
- Confining Codex shell commands (`codex-write-guard.sh` stays `apply_patch` only).
- Rewriting commands in the hook through `updatedInput`.
- The gate-checker-piped-into-head pitfall.
- Parsing agent worktree names in one shared place: [.workflow/deferred/worktree-name-parser.md](../../../deferred/worktree-name-parser.md).
- The Codex pre-spawn profile lookup: [.workflow/deferred/codex-spawn-profile-lookup.md](../../../deferred/codex-spawn-profile-lookup.md).
- Where 1.4 known-bad evidence is written: [.workflow/deferred/known-bad-evidence-path.md](../../../deferred/known-bad-evidence-path.md).

## Success signal

A Phase 1 build, an integration batch, a Phase 3 task and its mini-review each run under the guard and leave their result file in the main checkout's `artifacts/<id>/`, which `check-task-result.sh` accepts with no copy step; a branch carrying a stray `artifacts/` file is refused at merge; a target upgraded from the old settings audits integration agents with one SubagentStop entry; and a plain `cat file | head` from a confined agent is allowed while `echo x > file` without `cd` is still denied.

## Assumptions

- Launching without `isolation` and confining by the brief and the guard, as Phase 3 already does, works for Phase 1 and integration agents too. Not yet confirmed by a live launch: this spec's own Phase 1 and integration launches ran under isolation, before T5 landed (JRN-010, see Known gaps). Every Phase 3 implementation and mini-review launch here did write its result file to the main checkout with no copy step.
- The read-only allowlist (D6, D12) covers the reads agents actually make; a command outside it still works with the leading `cd`. Unconfirmed; sed counts as a read only for print-only scripts (D31).
- The integration stop audit runs the full profile toolchain, as a Phase 3 task's does. Confirmed (T1; `tests/hooks/audit-agent-worktrees.sh`).

## Open Questions

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)

## Known gaps

- JRN-010, a real launch filing its own result file, is not exercised for Phase 1 and integration. No live no-isolation launch has run, so whether Claude Code accepts the heredoc result-file command from such an agent is unconfirmed. The first Phase 1 build or integration batch of the next spec checks it.
- Line coverage of the changed shell code is not measured: there is no bash coverage tool, and no new dependency is allowed (D17).
