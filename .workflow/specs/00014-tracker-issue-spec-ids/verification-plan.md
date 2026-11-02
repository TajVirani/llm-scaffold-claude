# Verification plan: Tracker issues as spec IDs

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-tracker-issues: with no tracker set up, `next-spec-number.sh` prints the same number today's 0.1.1 scan does, no gh or glab is called, and the Sign-off PR keeps the "Link to issue" stub.
- [ ] CAP-NEW-tracker-issues: with GitLab (or GitHub) set up, starting a spec creates one issue with a placeholder title and empty body, and the spec folder is named after its number padded to five digits, with `tracker_issue` holding its URL.
- [ ] CAP-NEW-tracker-issues: two spec starts against the same tracker get two different numbers.
- [ ] CAP-NEW-tracker-issues: the issue's title and body are set from `spec.md` at 0.3.19, at ready-for-dev and at sign-off.
- [ ] CAP-NEW-tracker-issues: each task gets a GitLab child task (or a `relates_to` linked issue when the child call is refused) or a GitHub sub-issue, whose body is its task file and whose URL is the task record's `issue`.
- [ ] CAP-NEW-tracker-issues: issue labels move backlog → in progress → done at 3.1, 3.3, 3.16 and the sign-off merge, done closes the issue, and a reopened task goes back to in progress.
- [ ] CAP-NEW-tracker-issues: an unreachable tracker stops the spec start with a named reason and creates no folder.
- [ ] CAP-NEW-tracker-issues: the Sign-off PR carries the issue URL and `Closes #<n>`, in "Link to issue" or appended last with a project template, and `check-pr-body.sh` accepts every form.
- [ ] CAP-NEW-issue-tracking-setup: setup refuses with a named reason when the CLI is missing, not logged in or issues are disabled; on success it writes `.workflow/issue-tracking.yaml` and creates missing labels only when confirmed.
- [ ] CAP-NEW-issue-tracking-setup: project-setup has a tracker step that runs the issue-tracking setup, and the new skill is in the install manifest and `PROVENANCE.md`.
- [ ] CAP-NEW-issue-tracking-setup: Tracker adoption files and renames active specs (folder, backlog list, spec branch, spec worktree, `spec_branch` and task `branch` fields, `.workflow/` references), pushes a renamed branch whose old one was pushed and reports the old one, refuses a spec with a live task worktree, and renames Done specs and their backlog lists with the `old_` prefix.
- [ ] CAP-NEW-issue-tracking-setup: every workflow script accepts an `old_` Done folder and its backlog list.
- [ ] CAP-NEW-issue-tracking-setup: `move-to-done.sh`, `open-task-pr.sh` and `rules-setting.sh` use the shared lib path rewrite and host choice, no other copy of either remains, and their existing tests pass unchanged.
- [ ] CAP-NEW-tracker-issues: the new-feature start stays at or under 45,000 bytes and the implementation resume at or under 55,000.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | No tracker, unchanged numbering | CAP-NEW-tracker-issues | 1. Fixture repo with numbered specs, no `.workflow/issue-tracking.yaml`, fake gh and glab on PATH logging calls. 2. Run `next-spec-number.sh`. 3. Repeat with `issue_tracker: none`. | Prints the scan's next number (as the old 0.1.1 block did); call log empty | MISSING (planned `tests/run-all.sh --suite scripts/next-spec-number`) |
| JRN-002 | Spec number from a GitLab issue | CAP-NEW-tracker-issues | 1. Fixture with a gitlab `origin` and GitLab settings; fake glab answers iid 42. 2. Run `next-spec-number.sh`. | Prints `00042` and the issue URL; fake glab saw one create with a placeholder title and empty body | MISSING (planned `--suite scripts/issue-tracking`) |
| JRN-003 | Spec number from a GitHub issue | CAP-NEW-tracker-issues | As JRN-002 with a github `origin` and fake gh answering number 7. | Prints `00007` and the URL | MISSING (planned `--suite scripts/issue-tracking`) |
| JRN-004 | Two starts, two numbers | CAP-NEW-tracker-issues | 1. Fake tracker hands out increasing numbers. 2. Run the number script twice from two clones of one fixture. | Two different numbers; no local scan used | MISSING (planned `--suite scripts/issue-tracking`) |
| JRN-005 | Spec synced into the issue | CAP-NEW-tracker-issues | 1. Run the fill call with a fixture `spec.md` (body starting with `#` and with a `[` line). 2. Lint the step files for the fill call at 0.3.19, 0.6 / 0.3.20 and sign-off. | Fake CLI received the title and the whole body unchanged; the call is present at each step | MISSING (planned `--suite scripts/issue-tracking`, `--suite lint/issue-tracking-docs`) |
| JRN-006 | Task issues under the spec issue | CAP-NEW-tracker-issues | 1. GitLab: create a task issue; fake GraphQL accepts. 2. Again with GraphQL refused. 3. GitHub: create with `--parent`. 4. `set-task --issue <url>`; then a non-URL. | 1: child task; 2: `relates_to` linked issue; 3: sub-issue; 4: URL recorded and validator passes, non-URL refused with exit 2 | MISSING (planned `--suite scripts/issue-tracking`, `--suite scripts/status-transition-tasks`) |
| JRN-007 | Issue flow moves | CAP-NEW-tracker-issues | 1. Move backlog → in progress → done; reopen. 2. Lint step files for the move call at 3.1, 3.3, 3.16, 5.8 and the reopen at 3.9, 3.11, 4.7. | Each move removes the old label and adds the new; done closes, reopen reopens; calls present | MISSING (planned `--suite scripts/issue-tracking`, `--suite lint/issue-tracking-docs`) |
| JRN-008 | Unreachable tracker stops | CAP-NEW-tracker-issues | 1. Fake CLI fails (network, auth). 2. Run `next-spec-number.sh`. | Non-zero exit naming the cause; no number printed; no folder | MISSING (planned `--suite scripts/issue-tracking`) |
| JRN-009 | Sign-off PR link | CAP-NEW-tracker-issues | 1. Fill the PR body for a spec with `tracker_issue`. 2. Same with a project template. 3. Same with no tracker. 4. `check-pr-body.sh` on each. | 1: URL and `Closes #<n>` in "Link to issue"; 2: appended last; 3: stub; 4: all exit 0 | MISSING (planned `--suite scripts/sign-off-pr`) |
| JRN-010 | Setup check and save | CAP-NEW-issue-tracking-setup | 1. Run setup with the CLI missing, then not logged in, then issues disabled. 2. Run it with all fine and two labels missing, without and with confirmation. | 1: three named refusals, nothing written; 2: settings file written; labels created only with confirmation | MISSING (planned `--suite scripts/issue-tracking-setup`) |
| JRN-011 | Tracker adoption | CAP-NEW-issue-tracking-setup | 1. Fixture project: one draft spec, one spec past 1.1 with a pushed spec branch and worktree, one spec with a live task worktree, two Done specs with backlog lists and review lessons. 2. Run adoption. | Draft and past-1.1 specs renamed to their issue numbers everywhere; renamed branch pushed, old one reported, nothing deleted; the live-worktree spec refused; Done specs and lists prefixed `old_`; every `.workflow/` link resolves | MISSING (planned `--suite scripts/tracker-adoption`) |
| JRN-012 | `old_` names accepted | CAP-NEW-issue-tracking-setup | 1. Call `wf_norm_folder`, `review-lessons.sh validate`, check-write and the backlog lookup on `old_` names. 2. Same on malformed names. | 1: accepted; 2: still refused | MISSING (planned `--suite scripts/lib-workflow-paths`, `--suite scripts/review-lessons`, `--suite scripts/check-write-paths`) |
| JRN-013 | Shared lib, no copies | CAP-NEW-issue-tracking-setup | 1. Run the existing move-to-done, open-task-pr and rules-setting suites. 2. Grep for the host-choice and path-rewrite patterns outside lib. | 1: pass unchanged; 2: no copy outside lib | `tests/run-all.sh --suite scripts/move-to-done` and siblings; MISSING grep lint (planned `--suite lint/shared-tracker-logic`) |
| JRN-014 | Setup step and packaging | CAP-NEW-issue-tracking-setup | 1. Lint project-setup for its tracker step. 2. Check the manifest and `PROVENANCE.md` list `skills/issue-tracking`. 3. Run the frontmatter and symlink lints. | All present and passing | MISSING (planned `--suite lint/issue-tracking-docs`); `--suite lint/frontmatter --suite lint/symlinks` |
| JRN-015 | Load budget | CAP-NEW-tracker-issues | Run the load-size lint. | Start ≤ 45,000 B, resume ≤ 55,000 B | `tests/run-all.sh --suite lint/workflow-load-size` |
| JRN-016 | Full suite green | CAP-NEW-tracker-issues | Run `tests/run-all.sh`. | Every suite passes | `tests/run-all.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Fake glab and gh | Executables on PATH that log every call with its arguments and stdin, and answer from env-set responses (issue number, failure, GraphQL refusal) | Written under `tests/fixtures/` (D17) | JRN-001 to JRN-011 |
| Origin fixtures | Fixture repos with a gitlab, a github and a non-host `origin` URL | Written under `tests/fixtures/` | JRN-001 to JRN-004, JRN-010 |
| Old scan output | The number the 0.1.1 block printed for each existing scan fixture (`002`, `00010`, `00011`) | `tests/scripts/move-to-done.sh:343-372`, `tests/scripts/spec-worktree.sh:85-90` (codebase-map.md § Module audit) | JRN-001 |
| Adoption fixture project | Draft, past-1.1, live-worktree and Done specs with backlog lists, review lessons and links | Written under `tests/fixtures/`, built on `tests/fixtures/done-folder.sh` | JRN-011, JRN-012 |
| PR body fixtures | Workflow-template, project-template and no-tracker bodies | `tests/fixtures/pr-template.sh` | JRN-009 |
| Load-size limits | 45,000 and 55,000 bytes | ADR-0004; `tests/lint/workflow-load-size.sh:18-19` | JRN-015 |

## Targets

## Suites
