# Design log: Tracker issues as spec IDs

Spec: [spec.md](spec.md)

Came off the shelf: [.workflow/deferred/archive/spec-issue-creation.md](../../deferred/archive/spec-issue-creation.md)

## 2026-11-02 Term gate 0.2.2

- Agreed: **Tracker issue** and **Issue flow**, written to `.workflow/GLOSSARY.md` at 0.2.3.
- Not a new term: the issue a task is filed as. Stakeholder: "this repo uses task, a task should be linked to a sub issue or subtask in git/gitlab." It is folded into the **Tracker issue** definition (a sub-issue on GitHub, a child task on GitLab).
- Stakeholder on how the spec issue is made: "The issue is created blank, we get the issue number. The spec number becomes the issue number, we create the spec, the specs details is then used to update the issue with title and details. Placeholder can be used if the fields are required."
- Decision: **D1** The tracker issue is created first with a placeholder title and empty body; its number names the spec folder; the issue's title and body are filled from the spec once written.

## 2026-11-02 Placement: issue-tracking

- Capability: new, `CAP-NEW-tracker-issues` (no existing capability files or moves tracker issues; CAP-006 and CAP-011 are touched, not reframed).
- Owning module: a new `issue-tracking` module, `.agents/skills/issue-tracking/**`: the tracker scripts (create, fill, sub-issue, move through the issue flow) for glab and gh, the setup flow for a project already under way, and the spec migration. project-setup's new step and feature-workflow call its scripts.
- Alternatives considered: feature-workflow (grows a module already at 44,733 of its 45,000-byte start budget, ADR-0004); extend the glab skill (GitLab only, and a standalone playbook feature-workflow may not depend on).
- Conflict with an ADR or rule: proposed rule change. `.workflow/rules.md` Ownership has no `issue-tracking` module, and neither feature-workflow nor project-setup may depend on it; see proposals.md P1.
- Decision: **D2** Place the tracker work in a new `issue-tracking` skill. ADR: [.workflow/decisions/adr/0005-issue-tracking-placement.md](../../decisions/adr/0005-issue-tracking-placement.md)

## 2026-11-02 Deeper prompt

**What this changes:** A spec's number comes from a tracker issue created when the spec starts instead of a scan of local folders; tasks get sub-issues; issues move through the project's issue flow as work starts and finishes; project setup, or the new `issue-tracking` skill on a project already under way, checks the tracker and agrees the issue flow; existing specs are migrated.

**Why:** A local scan hands two people on one project the same spec number, so their specs collide on merge.

**Ask:** Make the project's tracker the single source of spec numbers and the place the team follows a feature's progress, while a project without a tracker works exactly as it does today.

**Goals:**
- Two people starting specs at the same time on one project get different spec numbers, without coordinating.
- Every new spec has a tracker issue whose number names its folder (zero-padded to at least five digits), whose title and body hold the written spec, and which the spec links to.
- Every task of a spec has a sub-issue (GitHub) or child task (GitLab) under the spec's issue, linked from its task file.
- Each issue moves through the issue flow agreed at setup (backlog, in progress, done) as its spec or task starts and finishes, and the Sign-off PR links the spec's issue.
- A project that adopts this mid-way gets its active specs filed and renamed, and its finished specs prefixed `old_` so their numbers never collide with issue numbers.

**Downstream:** Initiatives and their slices will later get tracker issues too; the design should leave room for a parent issue above a spec's issue.

**Tools and technologies:** glab for GitLab and gh for GitHub, picked from the `origin` URL as task PRs already are; the existing `glab` skill is the how-to reference.

**Gotchas:** "Everything should still work without a remote just as it works today." Found in discovery: GitLab scoped labels need Premium, so on Free the old stage label is removed explicitly; a GitLab child task can only be set through GraphQL; bulk sub-issue creation can hit GitHub secondary rate limits; feature-workflow's new-feature start is at 44,733 of its 45,000-byte budget (ADR-0004); this repo is on GitHub with no gh installed.

**Not asked for:** Tracker issues for initiatives and slices (downstream, later); other trackers such as Jira or Linear; syncing issue comments back into the spec.

**Original request:** "Currently we auto increment spec numbers, however this doesn't work well when multiple people are running the same project. I want to leverage git/gitlab issues for tracking numbers and features. When a feature is speced and the initial spec is about to be created, leverage our git skill to create a task, get the task ID and use that as the spec ID (lead with 0s for a minimum of 5 digits). Once the Spec is written, copy the contents to the task as well. The spec should have a link to the task (add this to the template). Any sub tasks are created as sub tasks under that task with their information and links working the same way. To set this all up (or use it at all) we need an additional step in the project setup, this should verify that git can be used - issues are available, and confirm with the user the flow of the ticket (label/column for backlog, in progress, complete). Issues should move as they are started and finished. We will need an additional skill that sets this up if a project is already started so that this can be added later as well. For specs already made and that are active, we need to go through and create issues + rename the specs. For the specs that are done/archived their spec should be prefixed with an old_ so that their numbers don't collide, no issue needs to be made."

Revisions: first restatement.

Agreement: pending, asked in the first questioning ask

## 2026-11-02 Questioning round 1

Stakeholder answer to the whole round: "Yes to all" (every recommendation, including the revised Q9 and the Q11 addition given after the fact lookup).

**Q1. Pass the deeper prompt on as written?**

- Options: A: yes · B: change it
- Recommended: A
- Answer: "Yes to all"
- Decision: **D3** The 2026-11-02 Deeper prompt entry is agreed as written.

**Q2. One spec, or convert into an initiative?**

- Options: A: one spec · B: initiative
- Recommended: A, because numbering, setup and migration serve one capability with one owning module (ADR-0005)
- Answer: "Yes to all"
- Decision: **D4** One spec.

**Q3. Issue flow form?**

- Options: A: labels on both hosts, done also closes the issue · B: GitHub Projects columns on GitHub
- Recommended: A, because GitLab board lists are label-backed and Projects needs extra token scope and ID lookups (codebase-map.md § Library options 4)
- Answer: "Yes to all"
- Decision: **D5** The issue flow is three labels on both hosts; done adds the done label and closes the issue.

**Q4. When issues move?**

- Options: A: spec issue backlog at creation, in progress at 3.1, done when the Sign-off PR merges; task issue created in backlog at breakdown (2.5, 0.3.20 light), in progress at its launch (3.3), done at its merge (3.16) · B: other points
- Recommended: A
- Answer: "Yes to all"
- Decision: **D6** Moves happen at those steps.

**Q5. When the spec is copied into the issue?**

- Options: A: title and body at 0.3.19, refreshed at ready-for-dev and at sign-off; a task issue's body is its task file at breakdown · B: on every spec.md write
- Recommended: A
- Answer: "Yes to all"
- Decision: **D7** Sync points are 0.3.19, ready-for-dev (0.6, or 0.3.20 on the light path) and sign-off; task issue bodies come from task files at breakdown.

**Q6. Link fields?**

- Options: A: `spec.md` frontmatter `tracker_issue: <url>` ("" when none) plus a Links line; task record `issue:` URL key plus a task-file link line · B: links section only
- Recommended: A
- Answer: "Yes to all"
- Decision: **D8** `tracker_issue` in spec frontmatter and Links; `issue` in the task record and a link line in the task file.

**Q7. Tracker set up but unreachable when a spec starts?**

- Options: A: stop and ask the stakeholder to fix or retry · B: fall back to a local scan number
- Recommended: A, because a local number could later equal a real issue number
- Answer: "Yes to all"
- Decision: **D9** Stop and ask; no fallback number. A project with no tracker set up keeps today's local numbering unchanged.

**Q8. GitLab task issue form?**

- Options: A: child task under the spec's issue via GraphQL, verified live at setup, falling back to a `relates_to` linked issue · B: always a linked issue
- Recommended: A (codebase-map.md § Library options 2)
- Answer: "Yes to all"
- Decision: **D10** GitLab tasks are child tasks, with a `relates_to` fallback; GitHub tasks are sub-issues.

**Q9. Settings home (revised after the fact lookup)?**

- Options: A: own unguarded file `.workflow/issue-tracking.yaml`, read by an issue-tracking script · B: `.workflow/rules.md` § Workflow settings, with an adoption exception in the Tier A guard
- Recommended: A, because rules.md cannot be written while a spec is in flight except at 0.3.7, 5.3, 5.7, and adoption always runs with specs in flight
- Answer: "Yes to all"
- Decision: **D11** Tracker settings (`issue_tracker: gitlab|github|none`, `issue_flow` label names) live in `.workflow/issue-tracking.yaml`.

**Q10. Missing labels at setup?**

- Options: A: create after the stakeholder confirms the names · B: require them to exist
- Recommended: A
- Answer: "Yes to all"
- Decision: **D12** Setup creates missing flow labels after confirmation.

**Q11. Migration?**

- Options: A: active specs get an issue and are renamed (folder, work-backlog list, spec branch, spec worktree, `.workflow/` path references), refused while a live task worktree exists; finished specs become `done/old_NNN-slug`, references rewritten, no issue; `wf_norm_folder` and the `review-lessons.sh` origin_spec check accept the `old_` prefix · B: other
- Recommended: A
- Answer: "Yes to all"
- Decision: **D13** Migration as in A, including the two `old_` prefix allowances (the lib change goes through integration).

**Q12. Adopt this repo in this spec?**

- Options: A: no, this repo keeps local numbering; adoption later is one run of the new skill · B: yes
- Recommended: A, because this repo is on GitHub and gh is not installed
- Answer: "Yes to all"
- Decision: **D14** This repo is not adopted here; this spec stays 00014.

**Q13. Sign-off PR link?**

- Options: A: "Link to issue" holds the issue URL and `Closes #<n>`; stub stays with no tracker · B: URL only
- Recommended: A
- Answer: "Yes to all"
- Decision: **D15** Sign-off PR links and closes the spec's tracker issue.

Facts looked up instead of asked (0.3.10):
- Writing rules.md outside a spec: allowed only when nothing is in flight; otherwise only at 0.3.7, 5.3, 5.7 (source `.agents/skills/feature-workflow/scripts/check-write.sh:342-402`).
- Task file created at 2.5 / 0.3.20, task start 3.3, task merge 3.16, spec in-progress 3.1, done 5.7, published 5.8 (sources `task-breakdown.md:75-85`, `discovery-impact.md:23,32-46`, `implementation-waves.md:84-88,117-121`, `implementation-setup.md:13`, `sign-off.md:204,248-253`).
- Load budget measured by `tests/lint/workflow-load-size.sh:19,24-52`; static files 41,492 bytes; glossary grew 15,649 to 16,360 bytes this spec.
- Tests asserting numbering and folder names: `tests/scripts/move-to-done.sh:338-372`, `tests/scripts/spec-worktree.sh:84-90`, `tests/scripts/lib-workflow-paths.sh:110-200`, `tests/fixtures/initiative.sh:130-148` (three-digit oracle).
- An `old_` Done folder breaks `wf_norm_folder` (`.agents/lib/workflow-paths.sh:144`) and its callers, the 0.1.1 scan glob, and `review-lessons.sh:89`.

## 2026-11-02 Questioning round 2

**Q1. Remote handling when migrating a spec whose spec branch is pushed?**

- Why now: D13 renames the local spec branch and worktree.
- Options: A: push the renamed branch, leave the old remote branch and open task PRs, tell the stakeholder which to close · B: push new and delete old after confirmation
- Recommended: A, because nothing on the remote is deleted
- Answer: "Push new, leave old (Recommended)"
- Decision: **D16** Push the renamed branch; leave the old remote branch and task PRs and report them.

**Q2. Testing tracker calls?**

- Why now: D5-D10 fix the calls to test.
- Options: A: fake glab/gh on PATH plus one live check on a scratch gitlab.com project · B: fakes only
- Recommended: A
- Answer: "Fakes only"
- Decision: **D17** Tests use fake glab and gh on PATH only; no live tracker run in this spec. The GitLab child-task GraphQL call stays unproven against a real instance until first use; setup's live check (D10) and its `relates_to` fallback cover it at runtime.

**Q3. Settled design summary?**

- Answer: "Yes, settled (Recommended)"
- Decision: **D18** The settled design is confirmed as one feature (the round-2 summary).

Facts looked up instead of asked (0.3.10): None.

## 2026-11-02 Term gate 0.4.2

- Agreed: **Tracker adoption**, written to `.workflow/GLOSSARY.md` at 0.4.3.

## 2026-11-02 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Tracker settings file `.workflow/issue-tracking.yaml` | create | host and issue flow labels; see data-model.md § Tracker settings |
| `issue-tracking` skill: SKILL.md, tracker script (check, create, fill, child, move, close), setup and adoption flows | create | ADR-0005 |
| Spec frontmatter `tracker_issue` and the Links line | extend | data-model.md § Spec |
| Task record `issue` and the task-file link line | extend | data-model.md § Task |
| `status-transition.sh` writers for `tracker_issue` and `issue` | extend | the single writer gains the two keys |
| Discovery 0.1.1 numbering | extend | tracker number when set up; scan unchanged otherwise |
| Issue sync at 0.3.19, 0.6 / 0.3.20, sign-off | extend | step-file calls only |
| Task issues at 2.5 / 0.3.20; label moves at 3.1, 3.3, 3.16 and merge | extend | step-file calls only |
| PR template "Link to issue" and `check-pr-body.sh` | extend | URL and `Closes #<n>` when a tracker issue exists |
| project-setup tracker step | extend | calls the issue-tracking setup flow |
| `wf_norm_folder` and `review-lessons.sh` origin_spec check | extend | accept `old_` in the Done folder; lib is shared core |
| Install manifest, PROVENANCE | extend | new first-party skill |
| Tests: fake glab and gh on PATH | create | D17 |
| 0.1.1 scan, session-start scan, Codex name parsing | unchanged | no `old_` folder outside the Done folder; top-level folders stay numeric |
| `.workflow/rules.md` Ownership | unchanged | P1 at 5.3 |
| glab skill | unchanged | reference only |

## 2026-11-02 Scope decision: tracker-host-detection

- Item: one shared host-detection reader (module-audit, Out of scope noticed, refactor, can-wait)
- Ruling: deferred, because every existing copy works and unifying them is a refactor outside this goal
- Handoff: [.workflow/deferred/tracker-host-detection.md](../../deferred/tracker-host-detection.md) (AFK), also listed in spec.md `deferred`

## 2026-11-02 Scope decision: done-spec-branch-fallback

- Item: fallback branch `spec/done/NNN-slug` for a Done spec (module-audit, Out of scope noticed, bug, can-wait)
- Ruling: deferred, because no step runs those scripts on a Done spec
- Handoff: [.workflow/deferred/done-spec-branch-fallback.md](../../deferred/done-spec-branch-fallback.md) (AFK), also listed in spec.md `deferred`

## 2026-11-02 Scope decision: initiative-tracker-issues

- Item: initiative and converted-spec numbering on a tracker (module-audit, Out of scope noticed, decision, can-wait), merged with the Downstream item "initiatives and slices"
- Ruling: deferred, because the large path is outside this spec (Deeper prompt, Not asked for)
- Handoff: [.workflow/deferred/initiative-tracker-issues.md](../../deferred/initiative-tracker-issues.md) (HITL), also listed in spec.md `deferred`

## 2026-11-02 Questioning round 3

Seeded by 0.4.7: the module audit's constraints conflict with the settled design (load budget, path-rewrite ownership, `old_` names, project-template PR link).

**Q1. Making room in the new-feature start budget?**

- Why now: start load about 44,966 of 45,000 bytes (codebase-map.md § Module audit, constraint ADR-0004).
- Options: A: move the 0.1.1 scan into a `next-spec-number.sh` script that runs the scan or asks issue-tracking for an issue number · B: new ADR raising the limit
- Recommended: A
- Answer: "Move scan into script (Recommended)"
- Decision: **D19** 0.1.1 becomes one script call; the scan and the tracker branch live in the script.

**Q2. Who renames specs for Tracker adoption?**

- Why now: only move-to-done.sh may rewrite spec paths, and no script renames a branch or worktree (codebase-map.md § Module audit, gaps).
- Options: A: rename mode in move-to-done.sh · B: new script in issue-tracking
- Recommended: A
- Answer: "New script in issue-tracking. Login that is duplicated should be shared as common library items"
- Decision: **D20** A new rename script in issue-tracking does the adoption renames. Logic it would duplicate (path rewrite with rollback and scoped commit from move-to-done.sh, and host detection) moves into shared `.agents/lib/` functions that both callers use; lib changes go through the integration agent.

**Q3. Names changed by the `old_` prefix?**

- Options: A: Done folder and its backlog list · B: folder only · C: also retrospectives
- Recommended: A
- Answer: "Folder + backlog list (Recommended)"
- Decision: **D21** `done/old_NNN-slug` and `work-backlog/old_NNN-slug.md` with links rewritten; retrospective and ADR file names unchanged.

**Q4. Issue link with a project PR template?**

- Options: A: append the issue URL and `Closes #<n>` as the body's last lines · B: no link
- Recommended: A
- Answer: "Append Closes line (Recommended)"
- Decision: **D22** Project-template PRs end with the issue URL and `Closes #<n>`; `check-pr-body.sh` is unchanged.

Facts looked up instead of asked (0.3.10): None.

## 2026-11-02 Settled design (round 3)

- Answer: "Yes, fold in and settle (Recommended)"
- Decision: **D23** (supersedes the 2026-11-02 Scope decision: tracker-host-detection) Host detection becomes a shared `.agents/lib` function used by open-task-pr.sh, rules-setting.sh and issue-tracking, in this spec. The shelf item is archived: [.workflow/deferred/archive/tracker-host-detection.md](../../deferred/archive/tracker-host-detection.md).
- Decision: **D24** The revised design is confirmed: 0.1.1 calls `next-spec-number.sh`; issue-tracking owns the tracker script and a Tracker adoption rename script; path rewrite with rollback and host detection are shared lib functions; `old_` renames the Done folder and its backlog list; project-template PRs end with `Closes #<n>`; every earlier decision stands.

## 2026-11-02 Impact classification (after round 3)

Adds to the 2026-11-02 Impact classification; rows there still stand except where named here.

| Part | Classification | Note |
| --- | --- | --- |
| `next-spec-number.sh` (feature-workflow) and the 0.1.1 text | create / refactor | 0.1.1 becomes one call; scan moves into the script (D19) |
| Shared path rewrite with rollback and scoped commit (`.agents/lib`) | create | extracted from `move-to-done.sh` (D20) |
| `move-to-done.sh` | refactor | uses the shared rewrite; behaviour and tests unchanged |
| Shared host choice (`.agents/lib`) | create | D23 |
| `open-task-pr.sh`, `rules-setting.sh`, sign-off 5.8 prose | refactor | use the shared host choice; behaviour unchanged |
| Tracker adoption rename script (issue-tracking) | create | folder, backlog list, branch, worktree, `spec_branch`, task `branch` fields (D20, D21) |
| `references/conventions.md` guarded-writes table | extend | Tracker adoption named as the second path-only rewriter |
| check-write backlog list-name rule and `open_sub_items` lookup | extend | accept `old_NNN-slug.md` (D21) |
| `tests/fixtures/initiative.sh` `next_spec_number` | refactor | tests call `next-spec-number.sh` instead of copies of the scan |

## 2026-11-02 Phase 1 scope and interface stubs

- No browser suite: every journey is a harness check (`tests/run-all.sh --suite ...`), no journey drives a browser and the project has no `e2e-browser` profile, so 1.3 builds nothing and 1.4 runs the harness only.
- Interface the 1.2 harness pins, with stubs that print a placeholder and exit 0 so the new tests fail on an assertion. It follows D5-D12, D19-D22 and the codebase-map Library options; Phase 3 tasks build to it.
  - `.agents/skills/feature-workflow/scripts/next-spec-number.sh [--cwd DIR]`: no tracker (no `.workflow/issue-tracking.yaml`, or `issue_tracker: none`) prints the 0.1.1 scan's next number, one line, no gh or glab call; with a tracker prints the issue number padded to five digits, then the issue URL on a second line. Exit 1 tracker failure (cause on stderr, nothing on stdout); 2 usage or a bad settings file.
  - `.agents/skills/issue-tracking/scripts/issue-tracker.sh [--cwd DIR] <command>`: `create-spec` (placeholder title, empty body; prints the URL), `fill <issue-url> <spec.md>` (title from the first `# ` heading, body the whole file through a file argument), `create-task <spec-issue-url> <task-file>` (GitLab child task through `glab api graphql`, `relates_to` linked issue when refused; GitHub `gh issue create --parent`; prints the URL), `move <issue-url> backlog|in_progress|done` (removes the other flow labels and adds the new one; done closes, in_progress on a closed issue reopens). No tracker: prints `skipped: no tracker`, exit 0. Exit 1 tracker failure named on stderr; 2 usage or bad settings.
  - `.agents/skills/issue-tracking/scripts/tracker-setup.sh [--cwd DIR] check|save`: `check` refuses with exit 1 and a named reason for a missing CLI, not logged in, issues disabled or a CLI older than the minimum, else prints the host and one `missing-label: <name>` line per absent flow label; `save --backlog L --in-progress L --done L [--create-labels]` writes `.workflow/issue-tracking.yaml`, and with labels missing it creates them only with `--create-labels`, otherwise exits 1 and writes nothing; `save --none` writes `issue_tracker: none`.
  - `.agents/skills/issue-tracking/scripts/tracker-adoption.sh [--cwd DIR]`: files and renames each active spec, refuses one with a live task worktree (the others still run), pushes a renamed branch whose old one was pushed and reports the old one, prefixes Done specs and their backlog lists `old_`. Exit 0 all adopted; 1 any spec refused; 2 usage or environment.
  - `status-transition.sh set-task --issue <url>|null`, like `--pr`; `tracker_issue` is a spec frontmatter key written by Edit at 0.1.4.
- Pinned by the 1.2 harness, on top of the contract above: `set-task --issue` with a non-URL exits 2 (the JRN-006 row), not 1 as `--pr` does; `tracker-adoption.sh` writes `tracker_issue` on each spec it adopts; the shared lib functions carry `host` and `rewrite` in their names (the JRN-013 lint finds them by that); the four stub scripts get their `PROVENANCE.md` rows and the `issue-tracking` SKILL.md and manifest line in Phase 3.

## 2026-11-02 Discovered work, Phase 1 duration

- Found at: step 1.2 by the orchestrator (Phase 1 timing). Kind: refactor
- Problem and evidence: one serial harness build covered JRN-001 to JRN-014, repeated full `tests/run-all.sh` runs (75 suites before, 81 after) and wrote throwaway prototypes in a scratch copy; the agent ran 2,734,186 ms (148 tool uses, 477,743 tokens) of the 18:16:52Z-19:13:27Z Phase 1, and the main session ran the full harness again on the merged checkout (`artifacts/phase-1-test-harness/implementation.yaml`; `.agents/skills/feature-workflow/modules/verification-setup.md`, "Launching a Phase 1 build").
- Assessment and ruling: not a blocker; kept for later (stakeholder: "Throw it in the backlog"). Candidate levers: one build per journey group in parallel; scoped `--suite` runs inside a build, keeping one full run for the merge; drop or narrow the prototype pass.
- Backlog line: [work-backlog/00014-tracker-issue-spec-ids.md](../work-backlog/00014-tracker-issue-spec-ids.md) B1

## 2026-11-02 Task breakdown (2.1-2.3)

Draft: 10 tasks in 6 waves, all afk, each with its seam and Phase 1 suites (session notes `00014-breakdown-draft.md`, now `tasks.md` and `tasks/`).

**Q1. Approve the 10 tasks, their order and what each is tested through, as drafted?**

- Answer: "Approve (Recommended)"
- Decision: **D25** The breakdown, its edges and its seams are approved as drafted.

**Q2. T8 (Tracker adoption) is close to L; keep it as one task?**

- Answer: "Keep as one (Recommended)"
- Decision: **D26** T8 stays one task.

**Q3. Size budget for this spec?**

- Recommended: 10 tasks and 34 changed files, because about 29 distinct non-test files are predicted but the predicted sum counts `SKILL.md`, `move-to-done.sh` and `sign-off.md` once per task (33).
- Answer: "10 tasks / 34 files (Recommended)"
- Decision: **D27** Budget for this spec: `max_tasks: 10`, `max_changed_files: 34`.

## 2026-11-02 Discovered work, wave 1

- 3.4 T3: the first result file wrote `self_review[].item` as quoted strings, which `check-task-result.sh` rejects; resumed once and fixed. Duplicate discovered work: quoted self-review items match `work-backlog/009-slim-workflow-context.md` B2; not appended, item of 009-slim-workflow-context.
- 3.4 T3 (`artifacts/T3/implementation.yaml`): `next-spec-number.sh` (feature-workflow) calls `issue-tracking/scripts/issue-tracker.sh`, a dependency the `.workflow/rules.md` Ownership block does not yet allow; already proposal P1 for 5.3 (`proposals.md`), nothing new filed. T3 also changed `PROVENANCE.md` (row for the new script) and `tests/README.md`, outside its predicted files.
- 3.16 wave 1: `task_review` reads `pr`, but `open-task-pr.sh` printed `skipped: gh not installed` for T1, T2 and T3, before any push; they merged locally with `pr: null`.
- 3.7 T5 out_of_scope_noticed (`artifacts/T5/mini-review-r1.yaml`), kind bug: a GitLab child-task GraphQL transport failure (timeout) is taken as a refusal and filed as a `relates_to` issue with exit 0, against `SKILL.md:24` "Exit 1: the tracker failed". Route: **current work** (proven by probe, on lines T5 adds); joins the T5 3.8 fix round.
- 3.16 wave 2: `open-task-pr.sh` printed `skipped: gh not installed` for T4 and T5; merged locally with `pr: null`. T5 took one behaviour fix round and one wording patch (applied by the orchestrator, re-check pass).
