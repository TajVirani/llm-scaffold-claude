## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- New `issue-tracking` skill: `issue-tracker.sh` (create-spec, fill, create-task, move), `tracker-setup.sh` (check, save) and `tracker-adoption.sh`, installed through the manifest.
- Discovery 0.1.1 is one call to `next-spec-number.sh`. With a tracker set up, the GitLab or GitHub issue number, padded to five digits, names the spec folder, and 0.1.4 records the issue URL as `tracker_issue`. With no tracker, the number comes from today's local scan.
- Each task gets a child task (GitLab, with a `relates_to` fallback) or a sub-issue (GitHub), recorded as `issue` through `set-task --issue`.
- Step files fill the spec issue at 0.3.19, 0.6 / 0.3.20 and sign-off, and move issues through the three-label issue flow: 3.1, 3.3, 3.16 and the sign-off merge, and back to in progress at 3.9, 3.11 and 4.7.
- The Sign-off PR's "Link to issue" carries the issue URL and `Closes #<n>`, appended last with a project PR template.
- project-setup gains a tracker step. Tracker adoption files and renames active specs (folder, backlog list, branch, worktree, task issues) and prefixes Done specs `old_`, which every workflow script and the session-start hook now accept.
- The host choice (`wf_origin_host`) and the path rewrite with rollback and scoped commit (`wf_rewrite_*`) are shared `.agents/lib` functions. `move-to-done.sh`, `open-task-pr.sh` and `rules-setting.sh` use them, with behaviour unchanged.

## Why the change

- Spec numbers came from a scan of the local checkout, so two people starting specs at once took the same number and collided on merge. The tracker already hands out unique numbers and is where the team follows work.
- Every spec and task now shows on the tracker at its current stage, and a project can adopt the tracker later without number collisions. A project with no tracker sees no difference.

## Why this approach

- A new `issue-tracking` skill owns the tracker logic (ADR-0005). feature-workflow and project-setup carry only the steps that call it, and settings live in `.workflow/issue-tracking.yaml`, because `rules.md` cannot be written while specs are in flight (D11).
- Labels on both hosts make the issue flow (D5): GitLab board lists are label-backed, and GitHub Projects would need extra token scope and ID lookups.
- The tracker is reached only through gh and glab, chosen from the `origin` URL as task PRs already are. An unreachable tracker stops the spec start rather than falling back to a local number that could later equal a real issue (D9).
- Logic the scripts would have copied (host choice, path rewrite with rollback) moved into `.agents/lib` through the integration agent (D20, D23). The 0.1.1 scan moved into a script to keep the new-feature start within the ADR-0004 budget (D19).

## Special things to note

- Report: [report.md](report.md). Task PRs: none; gh is not installed here, so every task merged locally (`pr: null`).
- Tests use fake gh and glab only (D17). The GitLab child-task GraphQL call, the gh 2.94.0 and glab 1.115.0 minimums, and two simultaneous starts on a real tracker are not checked against a live service.
- A GitLab served over plain http files an issue before `issue-tracker.sh` refuses its URL (review F11, dismissed as unlikely).
- Waiting for a ruling: Tracker adoption does not rewrite initiative files, and some step files prescribe commit subjects that are not Conventional Commits.
- Deferred: [done-spec-branch-fallback.md](../../../deferred/done-spec-branch-fallback.md), [initiative-tracker-issues.md](../../../deferred/initiative-tracker-issues.md).

## How to test

1. Run `tests/run-all.sh`. Expected: every suite passes (81 suites, 0 failed).
2. Run `tests/run-all.sh --suite scripts/issue-tracking --suite scripts/tracker-adoption --suite scripts/issue-tracking-setup --suite scripts/next-spec-number`. Expected: all pass against the fake trackers, with no network call.
3. Run `bash tests/lint/workflow-load-size.sh`. Expected: new-feature start at most 45,000 bytes and implementation resume at most 55,000.
4. In a repo with no `.workflow/issue-tracking.yaml`, run `.agents/skills/feature-workflow/scripts/next-spec-number.sh`. Expected: the next local number, and no gh or glab call.

## Blast radius

- feature-workflow scripts: `move-to-done.sh`, `open-task-pr.sh`, `rules-setting.sh` (refactored onto the shared lib), `status-transition.sh` (`--issue`), `check-write.sh` and `review-lessons.sh` (`old_` names), and the new `next-spec-number.sh`.
- feature-workflow step files and assets: discovery, questioning-loop, discovery-impact, task-breakdown, implementation-setup, implementation-waves, implementation-finish, review-triage, sign-off, conventions, and the spec, tasks, task and PR templates.
- `.agents/lib/workflow-paths.sh` (shared core), `.agents/hooks/session-start-resume.sh`, project-setup's SKILL.md and files module, the install manifest and `PROVENANCE.md`.
- Untouched: initiatives and the large path, other skills, and the Codex adapters.

## Risk and reversibility

Risk: Medium - shared lib functions now back the Done move and task PRs, and the tracker path is proven only against fake CLIs; with no tracker set up, behaviour is unchanged and the full harness passes.
Reversibility: Easy - revert the merge; no data format changes for a project with no tracker, and the new keys read as "no tracker" when absent.

## Areas, concepts and seams changed

- Interfaces whose shape changed: `status-transition.sh set-task` gains `--issue`; spec frontmatter gains `tracker_issue` and the task record `issue`; `wf_norm_folder` accepts `specs/done/old_NNN-slug`.
- New interfaces: `next-spec-number.sh`, `issue-tracker.sh`, `tracker-setup.sh`, `tracker-adoption.sh`, `wf_origin_host`, the `wf_rewrite_*` functions, `WF_ISSUE_TRACKING`.
- Modules: feature-workflow, issue-tracking (new), project-setup, lib, hooks, installer.
- Concepts: **Tracker issue**, **Issue flow**, **Tracker adoption**.

## How to undo this PR

1. Revert the merge commit of `spec/00014-tracker-issue-spec-ids` on main (`git revert -m 1 <merge sha>`).
2. A project that ran tracker setup keeps its `.workflow/issue-tracking.yaml`; delete it, or set `issue_tracker: none`, to return to local numbering.
3. A project that ran Tracker adoption keeps its renamed specs, branches and filed issues; the rename is reversed by renaming back, and the issues can be closed but not deleted.
