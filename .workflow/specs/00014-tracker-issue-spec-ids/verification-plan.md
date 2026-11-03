# Verification plan: Tracker issues as spec IDs

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-013: with no tracker set up, `next-spec-number.sh` prints the same number today's 0.1.1 scan does, no gh or glab is called, and the Sign-off PR keeps the "Link to issue" stub.
- [ ] CAP-013: with GitLab (or GitHub) set up, starting a spec creates one issue with a placeholder title and empty body, and the spec folder is named after its number padded to five digits, with `tracker_issue` holding its URL.
- [ ] CAP-013: two spec starts against the same tracker get two different numbers.
- [ ] CAP-013: the issue's title and body are set from `spec.md` at 0.3.19, at ready-for-dev and at sign-off.
- [ ] CAP-013: each task gets a GitLab child task (or a `relates_to` linked issue when the child call is refused) or a GitHub sub-issue, whose body is its task file and whose URL is the task record's `issue`.
- [ ] CAP-013: issue labels move backlog → in progress → done at 3.1, 3.3, 3.16 and the sign-off merge, done closes the issue, and a reopened task goes back to in progress.
- [ ] CAP-013: an unreachable tracker stops the spec start with a named reason and creates no folder.
- [ ] CAP-013: the Sign-off PR carries the issue URL and `Closes #<n>`, in "Link to issue" or appended last with a project template, and `check-pr-body.sh` accepts every form.
- [ ] CAP-014: setup refuses with a named reason when the CLI is missing, not logged in or issues are disabled; on success it writes `.workflow/issue-tracking.yaml` and creates missing labels only when confirmed.
- [ ] CAP-014: project-setup has a tracker step that runs the issue-tracking setup, and the new skill is in the install manifest and `PROVENANCE.md`.
- [ ] CAP-014: Tracker adoption files and renames active specs (folder, backlog list, spec branch, spec worktree, `spec_branch` and task `branch` fields, `.workflow/` references), pushes a renamed branch whose old one was pushed and reports the old one, refuses a spec with a live task worktree, and renames Done specs and their backlog lists with the `old_` prefix.
- [ ] CAP-014: every workflow script accepts an `old_` Done folder and its backlog list.
- [ ] CAP-014: `move-to-done.sh`, `open-task-pr.sh` and `rules-setting.sh` use the shared lib path rewrite and host choice, no other copy of either remains, and their existing tests pass unchanged.
- [ ] CAP-013: the new-feature start stays at or under 45,000 bytes and the implementation resume at or under 55,000.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | No tracker, unchanged numbering | CAP-013 | 1. Fixture repo with numbered specs, no `.workflow/issue-tracking.yaml`, fake gh and glab on PATH logging calls. 2. Run `next-spec-number.sh`. 3. Repeat with `issue_tracker: none`. | Prints the scan's next number (as the old 0.1.1 block did); call log empty | `--suite scripts/next-spec-number`, `--suite scripts/issue-tracking`, `--suite lint/issue-tracking-docs` (tests `JRN-001 ...`) |
| JRN-002 | Spec number from a GitLab issue | CAP-013 | 1. Fixture with a gitlab `origin` and GitLab settings; fake glab answers iid 42. 2. Run `next-spec-number.sh`. | Prints `00042` and the issue URL; fake glab saw one create with a placeholder title and empty body | `--suite scripts/issue-tracking` (tests `JRN-002 ...`) |
| JRN-003 | Spec number from a GitHub issue | CAP-013 | As JRN-002 with a github `origin` and fake gh answering number 7. | Prints `00007` and the URL | `--suite scripts/issue-tracking` (tests `JRN-003 ...`) |
| JRN-004 | Two starts, two numbers | CAP-013 | 1. Fake tracker hands out increasing numbers. 2. Run the number script twice from two clones of one fixture. | Two different numbers; no local scan used | `--suite scripts/issue-tracking` (tests `JRN-004 ...`) |
| JRN-005 | Spec synced into the issue | CAP-013 | 1. Run the fill call with a fixture `spec.md` (body starting with `#` and with a `[` line). 2. Lint the step files for the fill call at 0.3.19, 0.6 / 0.3.20 and sign-off. | Fake CLI received the title and the whole body unchanged; the call is present at each step | `--suite scripts/issue-tracking`, `--suite lint/issue-tracking-docs` (tests `JRN-005 ...`) |
| JRN-006 | Task issues under the spec issue | CAP-013 | 1. GitLab: create a task issue; fake GraphQL accepts. 2. Again with GraphQL refused. 3. GitHub: create with `--parent`. 4. `set-task --issue <url>`; then a non-URL. | 1: child task; 2: `relates_to` linked issue; 3: sub-issue; 4: URL recorded and validator passes, non-URL refused with exit 2 | `--suite scripts/issue-tracking`, `--suite scripts/status-transition-tasks`, `--suite lint/issue-tracking-docs` (tests `JRN-006 ...`) |
| JRN-007 | Issue flow moves | CAP-013 | 1. Move backlog → in progress → done; reopen. 2. Lint step files for the move call at 3.1, 3.3, 3.16, 5.8 and the reopen at 3.9, 3.11, 4.7. | Each move removes the old label and adds the new; done closes, reopen reopens; calls present | `--suite scripts/issue-tracking`, `--suite lint/issue-tracking-docs` (tests `JRN-007 ...`) |
| JRN-008 | Unreachable tracker stops | CAP-013 | 1. Fake CLI fails (network, auth). 2. Run `next-spec-number.sh`. | Non-zero exit naming the cause; no number printed; no folder | `--suite scripts/issue-tracking` (tests `JRN-008 ...`) |
| JRN-009 | Sign-off PR link | CAP-013 | 1. Fill the PR body for a spec with `tracker_issue`. 2. Same with a project template. 3. Same with no tracker. 4. `check-pr-body.sh` on each. | 1: URL and `Closes #<n>` in "Link to issue"; 2: appended last; 3: stub; 4: all exit 0 | `--suite scripts/sign-off-pr` (tests `JRN-009 ...`) |
| JRN-010 | Setup check and save | CAP-014 | 1. Run setup with the CLI missing, then not logged in, then issues disabled. 2. Run it with all fine and two labels missing, without and with confirmation. | 1: three named refusals, nothing written; 2: settings file written; labels created only with confirmation | `--suite scripts/issue-tracking-setup` (tests `JRN-010 ...`) |
| JRN-011 | Tracker adoption | CAP-014 | 1. Fixture project: one draft spec, one spec past 1.1 with a pushed spec branch and worktree, one spec with a live task worktree, two Done specs with backlog lists and review lessons. 2. Run adoption. | Draft and past-1.1 specs renamed to their issue numbers everywhere; renamed branch pushed, old one reported, nothing deleted; the live-worktree spec refused; Done specs and lists prefixed `old_`; every `.workflow/` link resolves | `--suite scripts/tracker-adoption` (tests `JRN-011 ...`) |
| JRN-012 | `old_` names accepted | CAP-014 | 1. Call `wf_norm_folder`, `review-lessons.sh validate`, check-write and the backlog lookup on `old_` names. 2. Same on malformed names. | 1: accepted; 2: still refused | `--suite scripts/lib-workflow-paths`, `--suite scripts/review-lessons`, `--suite scripts/check-write-paths`, `--suite scripts/tracker-adoption` (tests `JRN-012 ...`) |
| JRN-013 | Shared lib, no copies | CAP-014 | 1. Run the existing move-to-done, open-task-pr and rules-setting suites. 2. Grep for the host-choice and path-rewrite patterns outside lib. | 1: pass unchanged; 2: no copy outside lib | `tests/run-all.sh --suite scripts/move-to-done` and siblings; `--suite lint/shared-tracker-logic` (tests `JRN-013 ...`) |
| JRN-014 | Setup step and packaging | CAP-014 | 1. Lint project-setup for its tracker step. 2. Check the manifest and `PROVENANCE.md` list `skills/issue-tracking`. 3. Run the frontmatter and symlink lints. | All present and passing | `--suite lint/issue-tracking-docs` (tests `JRN-014 ...`); `--suite lint/frontmatter --suite lint/symlinks` |
| JRN-015 | Load budget | CAP-013 | Run the load-size lint. | Start ≤ 45,000 B, resume ≤ 55,000 B | `tests/run-all.sh --suite lint/workflow-load-size` |
| JRN-016 | Full suite green | CAP-013 | Run `tests/run-all.sh`. | Every suite passes | `tests/run-all.sh` |

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

Run every command in bash from the project root on a clean checkout of the feature's HEAD. The two load targets read the totals the size-check suite prints (`<load point>: <n> bytes (limit <m>)`), the same measure as JRN-015.

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| New-feature start load | performance | ≤ 45,000 bytes | the `load-new-start` command below | `spec.md` Constraints (ADR-0004) |
| Implementation resume load | performance | ≤ 55,000 bytes | the `load-impl-resume` command below | `spec.md` Constraints (ADR-0004) |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean | errors | exit 0; each lint suite reports 0 failed | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| Every script this spec adds or changes has a suite | coverage | `0` printed | the `script-coverage` command below | `.workflow/profiles/test-harness.md` § Mini-review checklist |
| Every new `.agents/` file is in `PROVENANCE.md` | coverage | `0` printed | the `asset-coverage` command below | `.workflow/rules.md` § Cross-cutting policy (PROVENANCE) |
| Line coverage of changed shell code | coverage | not measured | Cannot be measured: no bash coverage tool is installed. The script-coverage target and the test-harness checklist at 3.7 stand in. | `.workflow/rules.md` § Required versions (no coverage tool listed) |

Commands referenced above; each runs from the project root:

```bash
# load-new-start: prints the byte total; the threshold is 45000
bash tests/lint/workflow-load-size.sh | sed -n 's/^new-feature start: \([0-9]*\) bytes.*/\1/p'
# load-impl-resume: prints the byte total; the threshold is 55000
bash tests/lint/workflow-load-size.sh | sed -n 's/^implementation resume: \([0-9]*\) bytes.*/\1/p'
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of changed scripts no file under tests/ names; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/00014-tracker-issue-spec-ids/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files PROVENANCE.md does not name; the threshold is 0
git diff --name-only --diff-filter=A "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/00014-tracker-issue-spec-ids/spec.md)"..HEAD -- .agents | while read -r f; do grep -qF -- "${f#.agents/}" PROVENANCE.md || echo "$f"; done | wc -l | tr -d ' '
```

## Suites

<!-- 1.2-1.4. Filled by modules/verification-setup.md. Commands come from the profile Toolchain keys, not from this file: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md), full log [harness.txt](artifacts/phase-1-known-bad/harness.txt): 161 failures across the 6 new suites and the 5 extended ones, all assertions |
| Browser | `e2e`: not applicable (no `e2e-browser` profile; every journey is a harness suite) | none | none | not applicable; see record.md § Steps not run |
