---
status: in-review # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "e8162a94fb923cdae2496f4db5c8d9231abcabfc" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "spec/00014-tracker-issue-spec-ids" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "d79ab0b0887def80859bb343d8b5c9106c90d070" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes; true from 0.1.4 on the small path
small_path: false # true from 0.1.4 when intake (0.0.3) picked the small path; false once it leaves it (0.3.19)
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/done-spec-branch-fallback.md, .workflow/deferred/initiative-tracker-issues.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
budget: {max_tasks: 10, max_changed_files: 34}
---

# Tracker issues as spec IDs

## Why

Spec numbers come from a scan of the local checkout, so two people starting specs on the same project at the same time take the same number and collide on merge. The project's tracker already hands out unique numbers and is where the team follows work. This feature makes the tracker the single source of spec numbers and the place a feature's progress shows: every new spec is filed as a tracker issue whose number names its folder, every task as a sub-issue or child task under it, and each issue moves through the project's agreed issue flow as work starts and finishes. A project set up with no tracker keeps working exactly as it does today, and a project already under way can adopt the tracker later without number collisions.

## Capabilities

- **CAP-NEW-tracker-issues** Specs and tasks filed as tracker issues
  - **intent:** When a project has a tracker set up, discovery files a spec's tracker issue before the spec folder exists and names the folder after the issue number, task breakdown files each task under it, and the workflow moves every issue through the issue flow, so parallel specs never share a number and the team follows progress on the tracker.
  - **success:** With a fake glab and a fake gh on PATH, starting two specs gives folders named after the two issue numbers zero-padded to five digits (`00042-slug`); the issue receives the spec's title and body at 0.3.19, ready-for-dev and sign-off; each task gets a GitLab child task (or a `relates_to` linked issue when the child call fails) or a GitHub sub-issue, recorded as `issue` in its task record; the issue labels change at 3.1, 3.3, 3.16 and merge, and done closes the issue; the Sign-off PR's "Link to issue" holds the URL and `Closes #<n>` (appended last with a project PR template); and with no tracker set up, numbering, templates and the PR stub behave exactly as before.
- **CAP-NEW-issue-tracking-setup** Tracker setup and adoption
  - **intent:** project-setup, and the `issue-tracking` skill on a project already under way, check that the tracker can be used, agree the issue flow with the stakeholder and save it, and on adoption file and rename every active spec and prefix every finished spec `old_`, so the tracker can be added at any time.
  - **success:** With fake CLIs, setup refuses with a named reason when the CLI is missing, not logged in, or issues are disabled; on success it writes `.workflow/issue-tracking.yaml` with the host and the three agreed labels and creates the missing labels only after confirmation; adoption on a fixture project with one draft spec, one spec past 1.1 and two Done specs gives the active specs issues and new folder, backlog-list, branch and worktree names with every `.workflow/` reference rewritten, refuses a spec with a live task worktree, renames the Done specs to `done/old_NNN-slug` and their backlog lists to `old_NNN-slug.md` with references rewritten, and every workflow script still accepts the renamed folders; `move-to-done.sh`, `open-task-pr.sh` and `rules-setting.sh` keep passing their existing tests on the shared lib functions.

## Constraints

- A project with no tracker set up (no `.workflow/issue-tracking.yaml`, or `issue_tracker: none`) keeps today's local numbering, templates and Sign-off PR stub unchanged, with no tracker call and no network use.
- A tracker that is set up but unreachable stops the spec at its start and asks the stakeholder to fix or retry; no local number is used instead.
- The tracker issue is created first with a placeholder title and an empty body; its number names the spec folder, zero-padded to at least five digits.
- glab drives GitLab and gh drives GitHub, chosen from the `origin` URL as task PRs already are; no other tracker.
- Tracker settings live in `.workflow/issue-tracking.yaml`, not in `.workflow/rules.md`.
- The issue flow is three labels (backlog, in progress, done) on both hosts; done also closes the issue.
- Nothing on the remote is deleted by adoption; a renamed spec branch is pushed under its new name and the old remote branch and its task PRs are reported.
- feature-workflow's new-feature start stays within ADR-0004's 45,000-byte budget and its implementation resume within 55,000; the 0.1.1 numbering is one call to a `next-spec-number.sh` script, which runs today's scan or takes the tracker's issue number.
- The tracker scripts and the Tracker adoption rename script live in the new `issue-tracking` skill (ADR-0005); feature-workflow and project-setup carry only the steps that call them.
- No logic is copied between scripts: the path rewrite with rollback and scoped commit (today inside `move-to-done.sh`) and the host choice (today in `open-task-pr.sh`, `rules-setting.sh` and the sign-off prose) become shared `.agents/lib` functions used by every caller, changed through the integration agent.
- The `old_` prefix renames a Done spec's folder and its work-backlog list only; retrospective and ADR file names stay.
- With a project PR template, the issue URL and `Closes #<n>` are appended as the body's last lines; `check-pr-body.sh` is unchanged.
- Tests use fake glab and gh on PATH only; no test creates a real issue.

## Non-goals

- Tracker issues for initiatives and their slices, and tracker numbering for initiatives and converted specs; the design leaves room for a parent issue above a spec's issue. Shelved: [.workflow/deferred/initiative-tracker-issues.md](../../deferred/initiative-tracker-issues.md).
- The Done-folder spec-branch fallback name. Shelved: [.workflow/deferred/done-spec-branch-fallback.md](../../deferred/done-spec-branch-fallback.md).
- Trackers other than GitLab and GitHub (Jira, Linear).
- GitHub Projects columns or other board fields beyond labels.
- Syncing issue comments or edits back into the spec.
- Adopting this repo onto its tracker in this spec.
- Deleting old remote branches or closing task PRs during adoption.

## Success signal

On a project with a tracker set up, two people start specs at the same moment and get two different folder numbers, each matching an issue that shows the spec, its tasks and its current stage on the board, and the merged Sign-off PR closes it; a project already under way adopts the tracker in one run with no number collisions; a project with no tracker sees no difference. The objectives and journeys that prove it are in [verification-plan.md](verification-plan.md).

## Assumptions

- The GitLab child-task GraphQL call works on gitlab.com as documented; it is proven only against a fake glab in this spec (D17), and the `relates_to` fallback covers a refusal.
- gh 2.94.0 or later (`gh issue create --parent`) and glab 1.115.0 or later (`issue update --description-file`) are installed where the tracker is used; `tracker-setup.sh check` refuses an older CLI and names the minimum. The two minimums are taken from the CLIs' release lists and are not checked against a real install.
- The tracker serves issue URLs over https; `issue-tracker.sh` refuses any other URL, after the tracker has already created the issue it names.
- Migrating active specs runs when no task worktree is live; a spec mid-wave is refused until its wave ends.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
- Placement ADR: [.workflow/decisions/adr/0005-issue-tracking-placement.md](../../decisions/adr/0005-issue-tracking-placement.md)
