# Design log: PR template

Spec: [spec.md](spec.md)

## 2026-10-29 Term gate 0.2.2

- Agreed and written to `.workflow/GLOSSARY.md`: **PR template** (chosen over "PR description template"), **Sign-off PR**, **Blast radius** (stakeholder chose a glossary entry over a plain section heading).
- D1: no existing capability covers PR descriptions (`.workflow/capabilities.md:13-17`); the change is a new capability, `CAP-NEW-pr-template`.
- D2: owning module is clear, feature-workflow (`.agents/skills/feature-workflow/**`); no placement ADR.

## 2026-10-29 Deeper prompt

Revision rounds: 1. Draft goals shown; stakeholder answered downstream ("The review step may use some pieces of this template to help it understand what to review"), tools ("What you suggested") and gotchas (issue link required but a stub until issue creation exists, filed as its own item; a project's own pull_request_template is asked about once and the answer saved in config). Agreed with "go"; the issue-creation item goes to the deferred shelf at 0.3.17.

**Ask:** Every Sign-off PR should tell a reviewer (human or AI) what the change is for, prove it works, and say what it could break and how to undo it, so nobody has to open the spec folder to judge it.

**Goals:**
- Every Sign-off PR opened at 5.8 carries all ten PR template sections, in a fixed order.
- Each section is filled from evidence the spec folder already holds (commands run and their output, reviewer findings, report.md, design-log.md), not claims.
- Risk and reversibility use a fixed scale (Risk: Low/Medium/High; Reversibility: Easy/Moderate/Hard), each with a one-line reason.
- If "How to undo" can't be written, sign-off stops and flags it before opening the PR.
- The body reaches GitHub/GitLab through a file (gh --body-file / glab --description-file); a local merge keeps the same body.
- "Link to issue" is a required section. Until the workflow creates issues, it is a marked stub.
- When the project has its own .github/pull_request_template.md (or GitLab MR template), the user is asked once whether to use it or ignore it, and the answer is saved in the project's workflow settings so it is never asked again.

**Downstream:** The Phase 4 review may later read parts of the filled template (intent, blast radius, areas changed) to decide what to review. Keep the sections separately readable.

**Tools and technologies:** Plain bash plus a Markdown template under feature-workflow/assets/. No new dependencies.

**Gotchas:**
- No issue is created at the start of a spec today, so the issue link has nothing to point to yet.
- Workflow settings in .workflow/rules.md change only at 5.3, and the PR is opened at 5.8. Where the use-or-ignore answer gets saved needs settling.
- gh errors if --template is passed together with --body-file.

**Not asked for:**
- Creating a tracker issue at spec start. This becomes its own item to be built later.
- A REVIEW.md for AI review.
- Changing task PR bodies (3.16).
- Making the review step read the template.

**Original request:** "At the end of a spec when the system is creating a PR, we need to follow a template for the PR. The headlines should cover: Link to issue, What changed (Bullets), Why the change (Bullets), Why this approach, Special things to note, How the user can test (Step by step instructions), The blast radius of the change, The change risk and reversibility (A general score ie Risk: High, Reversibility: Easy), Which areas / concepts / seams of the code changed, How to undo this PR"

## 2026-10-29 Questioning round 1

- Q1 Fill timing. Options: at 5.4 with approval at 5.5 / at 5.8 just before opening / defer. Recommended: 5.4 + 5.5 (stakeholder signs off on the exact PR text). Answer: "At 5.4, you approve at 5.5". **D3:** the main session fills `pr-body.md` in the spec folder at 5.4 beside `report.md`; the stakeholder approves it at 5.5; 5.8 sends it unchanged.
- Q2 Meaning of "use the project's template". Options: project's headings filled, ours dropped / ours then project's / defer. Recommended: project's headings. Answer: "Project's headings, filled". **D4:** "use" fills the project's own headings from the same evidence; "ignore" uses the ten PR template sections only.
- Q3 Undo cannot be written. Options: flag at 5.5 / hard stop / defer. Recommended: flag at 5.5. Answer: "State that under the "How to undo" and make sure the risk factor is flagged as HIGH". **D5:** the How to undo section states why it cannot be undone, and Risk is High.
- Q4 Check script. Options: yes / prose only / defer. Recommended: yes. Answer: "Yes, check script". **D6:** a bash check validates the filled body (headings present in order, no empty section, scores on the fixed scale) at 5.4 and 5.8.

Facts looked up (fact-lookup), not asked:
- 5.3 asks only the proposals approval round, then applies rows; the main session may write `.workflow/rules.md` at 5.3 (`sign-off.md:32-72`, `check-write.sh:75`).
- The light path runs 5.4 and 5.8 the same as the full path (`sign-off.md:85, 88, 161`; `references/steps.tsv:109-117`).
- A new Workflow settings key needs a `setting_spec` case in `rules-setting.sh` (`rules-setting.sh:42-48, 65`); tests in `tests/scripts/task-breakdown.sh:97-122`.
- The 5.8 local merge passes no message (`sign-off.md:161`); other workflow merges pass `-m`.
- A new `pr-body.md` in the spec folder is unguarded (`check-write.sh:206-212, 228`).

## 2026-10-29 Questioning round 2

- Q1 Where the use-or-ignore answer is saved. Options: rules.md key via a 5.2 proposal approved at 5.3 / separate config file / defer. Recommended: rules.md key via 5.3. Answer: deferred to deep dive.
- Q2 Irreversible value. Options: add Irreversible and enforce Risk: High / keep three values / defer. Recommended: enforce. Answer: "Yes, enforce it". **D7:** reversibility scale is Easy / Moderate / Hard / Irreversible; the check script fails when Reversibility is Irreversible and Risk is not High.
- Q3 Local merge. Options: body in merge commit / PR route only / defer. Recommended: body in merge commit. Answer: "Yes, body in merge commit". **D8:** the 5.8 local merge uses `git merge --no-ff -F <file>` with a Conventional Commits subject followed by the approved `pr-body.md`.

## 2026-10-29 Deep dive: where the use-or-ignore answer is saved

- Facts: behaviour settings live in the `## Workflow settings` block of `.workflow/rules.md` (Tier A, written at 0.3.7, 5.3, 5.7; read by `rules-setting.sh`); models live in unguarded `.workflow/model-map/<type>.md` and `.workflow/agent-overrides.yaml`; state lives per spec in `spec.md` and `.step`. No single settings home exists.
- Options: (1) rules.md key chosen through a 5.2 proposal at 5.3; (2) the same key, also asked by `project-setup` when it writes rules.md and a host template exists, with the 5.2/5.3 fallback; (3) a new unguarded settings file.
- Recommended: (1) or (2). Answer: "Lets do 2 for now - add a backlog item to unify global settings to a central location".
- **D9:** new Workflow settings key `pr_template: workflow | project` in rules.md, read by `rules-setting.sh`. `project-setup` asks it when it writes rules.md and the project has a host PR/MR template; sign-off 5.2 adds a proposal row when the key is unset and a host template exists, decided at 5.3, before 5.4 fills the body. Unset with no host template: the PR template is used.
- Unifying workflow settings in one home is out of scope: shelved at 0.3.17.

## 2026-10-29 Scope decision: spec issue creation

- Item: create a tracker issue when a spec starts, so "Link to issue" has a target.
- Ruling: shelved (HITL), per the deeper prompt's Not asked for. [.workflow/deferred/spec-issue-creation.md](../../deferred/spec-issue-creation.md)

## 2026-10-29 Scope decision: workflow settings home

- Item: one central home for project-wide workflow settings (behaviour settings and models).
- Ruling: shelved (HITL); stakeholder: "add a backlog item to unify global settings to a central location". [.workflow/deferred/workflow-settings-home.md](../../deferred/workflow-settings-home.md)

## 2026-10-29 Placement: feature-workflow

- D10: feature-workflow owns the change (template, sign-off steps, check script, `rules-setting.sh` key). D9 adds one setup question to `project-setup`, which may depend on feature-workflow (`.workflow/rules.md` Ownership). No placement ADR: it fails the three-part test (easy to reverse, no real trade-off).
- 0.3.19 summary confirmed by the stakeholder ("Yes, confirmed"). Light-path facts: intent gaps clean, no irreversible actions, footprint not small (two modules, new script and tests, about 8 files) → full path.

## 2026-10-29 Impact classification

0.4.2 term gate: no new concept; PR template, Sign-off PR and Blast radius were agreed at 0.2.2.

| Part | Module | Class |
| --- | --- | --- |
| `assets/pr-template.md` (ten sections, per-section evidence guidance) | feature-workflow | create |
| `scripts/check-pr-body.sh` (headings, order, non-empty, score scales, Irreversible → High; project mode: non-empty only) | feature-workflow | create |
| `modules/sign-off.md` 5.2 (pr_template proposal row), 5.4 (fill and check `pr-body.md`), 5.5 (approve the text), 5.8 (`--body-file` / `--description-file`; local merge `-F`) | feature-workflow | extend |
| `scripts/rules-setting.sh` (`pr_template` key: `workflow` / `project`, default `workflow`) | feature-workflow | extend |
| `project-setup` setup flow and its `assets/docs/rules.md` Workflow settings template (ask when a host template exists) | project-setup | extend |
| This repo's `.workflow/rules.md` Workflow settings (document the key) | Tier A | extend, via 5.3 proposal |
| Tests: new check-pr-body suite; `pr_template` cases beside the `rules-setting.sh` tests | tests | create / extend |
| `PROVENANCE.md` / `assetlist.md` entries for the new files | scaffold docs | extend |
| `assets/report.md`, `open-task-pr.sh`, task PRs, `references/steps.tsv` | feature-workflow | unchanged |

## 2026-10-29 Scope decision: initiative PR template

- Item (module-audit, out of scope noticed, can-wait): the initiative PR into main has no body (`modules/large-path.md:218-221`).
- Ruling: shelved (HITL) through the 0.3.17 scope gate. [.workflow/deferred/initiative-pr-template.md](../../deferred/initiative-pr-template.md)
- The audit's second line (no issue identifier captured) is the already-shelved [spec-issue-creation.md](../../deferred/spec-issue-creation.md).
- 0.4.7: no conflict with the goal or placement; audit gaps are covered by D3, D8, D9; stale-body and CAP-NEW constraints are met because 5.4 runs after 5.3 and refills `pr-body.md` on every pass.

## 2026-10-29 Main moved since handoff

- The handoff was written at `02bc218`; the spec branch forks from `16c72b1`. That commit adds glossary terms and `.workflow/deferred/` shelf files for specs 006-009 and deletes one work-backlog item. No file in the affected area (`.agents/skills/feature-workflow`, `glab`, `pr-quality`, `install-manifest.txt`) changed, so no contract the spec relies on moved.

## 2026-10-29 Verification setup 1.1-1.2

- Targets: stakeholder set `check-pr-body.sh` wall time at ≤ 1 s best of 3 and line coverage as not measured (no bash coverage tool; no new dependencies).
- D11 (follows D10's "no new 5.8 script, `open-task-pr.sh` unchanged"): JRN-005 tests the 5.8 commands as written in `modules/sign-off.md`. 5.8 keeps its publish commands in one fenced `bash` block placed right after the marker line `<!-- 5.8 publish commands -->`, written against the variables `SPEC_DIR`, `SPEC_BRANCH`, `MAIN` and `SUBJECT`. The suite extracts that block, runs its `gh`, `glab` and `git merge` lines in a fixture repo with argument-recording stand-ins on `PATH`, and checks the arguments and the merge commit. The block's presence is the suite's first assertion, so today's prose fails on an assertion, not a setup error.
- 1.2: harness merged as `c10742b` (suites `scripts/check-pr-body`, `scripts/sign-off-pr`, JRN-004 cases in `scripts/task-breakdown`; fixture `tests/fixtures/pr-template.sh`; stubs `assets/pr-template.md`, `scripts/check-pr-body.sh` exiting 3). Project mode shape fixed by the tests: `check-pr-body.sh <file> --project-template <template file>`. The tests also pin the 5.8 branch flags (`--base`/`--head`, `--target-branch`/`--source-branch`) and that the publish block passes shellcheck. The agent's result file stayed in its worktree (sandbox refused the main-checkout write); `check-task-result.sh` passed on it there.
- 1.3: not applicable (no browser suite). 1.4: 60 new cases red on assertions; record in `artifacts/phase-1-known-bad/record.md`.

## 2026-10-29 Task breakdown 2.1-2.3

- Approved breakdown (stakeholder: "Approve as shown"): T1 `pr_template` setting (feature-workflow, `rules-setting.sh`); T2 PR template and `check-pr-body.sh` (feature-workflow); T4 project-setup asks `pr_template` (project-setup); T3 sign-off 5.2/5.4/5.5/5.8, `SKILL.md`, `assets/design-log.md` (feature-workflow), blocked by T1, T2, T4. Waves: T1, T2, T4 in wave 1; T3 in wave 2. All afk, all S, no shared core. T3 owns `tests/scripts/sign-off-pr.sh`, including T4's three JRN-006 cases (selectors are per suite).
- Seams agreed: `rules-setting.sh pr_template` CLI; `check-pr-body.sh` CLI plus the template headings; project-setup text check; the 5.8 publish block against stand-ins plus sign-off text checks.
- Budget: project default, max_tasks 10, max_changed_files 30 (predicted 4 tasks, 9 non-test files).
- Q (project-mode host template): options were first found in a fixed order / record the path in the setting. Recommended: first found. Answer: "Record the path in the setting". This changes D9's setting shape (`workflow | project` → `workflow | <path>`), which discovery did not settle: loop back at 2.3 to the questioning loop with the new shape as its first frontier question.

## 2026-10-29 Questioning round 3 (loop-back from 2.3)

Seed: the stakeholder chose at 2.1 to record the host template's path in the setting instead of `project`.

- Q1 Setting shape and validation. Options: `workflow` or a repo-relative `.md` path, shape checked only / also check the file exists / defer. Recommended: shape only (mirrors `main_branch`'s `@branch` check, `rules-setting.sh:51-53`). Answer: "Also check it exists". **D12** (supersedes D9's value set): `pr_template: workflow | <path>`, the path repo-relative, ending in `.md`, no `..`, no leading `/` or `-`; `rules-setting.sh pr_template` exits 1 when the shape is wrong or the file does not exist. Absent key still reads `workflow` with a default note. The value `project` is gone.
- Q2 Path set but file gone at 5.4. Options: stop and ask / fall back to workflow / defer. Recommended: stop and ask. Answer: "Stop at 5.4 and ask". **D13:** 5.4 stops when `rules-setting.sh pr_template` fails, tells the stakeholder, who chooses the workflow template for this PR or a fixed path through a `pr_template` proposal (back through 5.2/5.3). Never a silent fallback.
- Q3 Several host templates found. Options: each path plus `workflow` / defer. Recommended: each path plus workflow. Answer: "Each path plus workflow". **D14:** project-setup and the 5.2 row offer one choice: every found template path, plus `workflow`; the answer is the value written.
- Q4 Where to look. Options: GitHub and GitLab paths including `docs/` and root / only `.github/` and `.gitlab/` / defer. Recommended: the wider list. Answer: "Only .github/ and .gitlab/". **D15:** the search covers `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md` and `.gitlab/merge_request_templates/*.md` only.

Facts used, not asked: `rules-setting.sh` validates a free-form value through an `@`-pattern in `setting_spec` (`rules-setting.sh:42-53`); with `--rules` it never computes the repo root (`rules-setting.sh:73-82`).

## 2026-10-29 Questioning round 4

- Q1 Root for the existence check. Options: main checkout root from `--cwd` / two levels above the rules file / defer. Recommended: main checkout root. Answer: "Main checkout root from --cwd". **D16:** `rules-setting.sh pr_template` resolves the path against the main checkout root found from `--cwd` (git common dir, as for rules.md), also when `--rules` is passed; outside a git repo the path check exits 1.
- 0.3.18: no question left open; no new term; no answer outside scope.

## 2026-10-29 Impact classification (loop-back from 2.3)

0.4.2 term gate: no new concept ("host template" stays plain prose, as in the first pass).

| Part | Module | Class |
| --- | --- | --- |
| `scripts/rules-setting.sh` (`pr_template` key: `workflow` or a repo-relative `.md` path checked for shape and existence against the main checkout root, D12, D16) | feature-workflow | extend (was: enum `workflow` / `project`) |
| `modules/sign-off.md` 5.2 (row offers each found host template path plus `workflow`, D14, D15), 5.4 (stop and ask when the setting fails, D13; project mode passes the path to `--project-template`) | feature-workflow | extend |
| `project-setup` setup question (offers each found path plus `workflow`, D14, D15) | project-setup | extend |
| All other rows of the first Impact classification | as before | unchanged |

0.4.6: no new module audit. The changed part sits in lines the first audit already read (`rules-setting.sh:13-27, 41-48, 65, 83-105`: the five places a key appears and the generic validation), and its constraints still hold. 0.4.7: no conflict with the goal or the placement.
- 0.5: verification-plan end state, JRN-003 (path argument), JRN-004 (path values, missing file, bad shapes, `project` now refused, outside git) and fixtures updated; JRN-004 Check set back to MISSING for the 1.2 re-entry. 0.6: all four checks clear.
- 1.2 re-entry: JRN-004 reworked for D12/D16 and merged as `4907bca` (15 cases); `tests/README.md` row updated by hand to match. The agent's result files (`implementation.yaml`, `implementation-r1.yaml`) stayed in its worktree again; `check-task-result.sh` passed there. 1.4 Run 4: 67 new cases red on assertions.
- 2.5: budget written (10 / 30). Tasks renumbered blockers first: project-setup is T3, sign-off is T4 (blocked by T1, T2, T3). T1 resized to ~40 lines for the D12/D16 path check; no other change to the approved breakdown. Phase 1 tests: `task-breakdown.sh` → T1, `check-pr-body.sh` → T2, `sign-off-pr.sh` → T4; T3 owns none. Validator `true`; `task-waves.sh` exit 0, no implied edges, waves as approved.
- 2.6: within budget, 4 of 10 tasks; 10 of 30 predicted files (predicted), 3 changed so far.

## 2026-10-29 Implementation wave 1

- 3.1: work types T1, T2 shell-scripts; T3, T4 agent-docs. `impl_base_revision` `103fe9d`. Suites: harness yes, browser not applicable.
- 3.4 T1: no tests added; accepted because the Phase 1 JRN-004 cases it turns green include 8 negative cases (bad shapes, missing file, `project`, `other`, outside git) at the agreed CLI seam. T1 also moved the main-checkout lookup onto `wf_main_root` from `.agents/lib/workflow-paths.sh` (a lib consumer, no shared-core change).
- 3.4 T3: no tests added; accepted because the change is project-setup prose and its three JRN-006 text cases (owned by T4's suite) pass on its branch. T3 states the project-setup write of `pr_template` as the one exception to the project-standards ledger (fresh unfilled copy; the human picks the value directly).
- 3.8 T3: mini-review pass (5 pass, 2 n/a). Its `out_of_scope_noticed` entry (the `files.md` readback of `rules-setting.sh pr_template` exits 1 at T3's base) is not outside the agreed scope: T1 adds the key and merges before T3 in id order at 3.16. Assessed as covered by T1, not filed; 3.9 after the wave confirms the readback.
- 3.8 T1 round 1: fail on checklist item 3 (`rules-setting.sh:117` accepts a literal `@template_path`; the same loop lets a literal `@branch` through for `main_branch`). Behaviour fix: fresh agent in the same worktree, with cases for both. Its `out_of_scope_noticed` entry (the `valid_template_path` comment claims more than the `-f` check guarantees, since symlinks are followed) concerns T1's own new comment, so it joins the fix round instead of being filed.
- 3.8 T1 round 2 (full): pass (12 pass, 1 n/a). Its `out_of_scope_noticed` entry (the outside-git stderr for `task_review`/`main_branch` gains a `cannot find .workflow/rules.md: ` prefix) needs no work: the old text survives as the suffix, exit code and stdout are unchanged, and no script or test under `.agents/` or `tests/` reads that message. Accepted under acceptance criterion 4, not filed.
- 3.4 T2: resumed once to add tests for behaviour it built beyond Phase 1 (guidance-only section reads empty; a heading-less project template exits 2; 7 more edge and negative cases): 9 added, suite 36/36.
- 3.8 T2 round 1: fail on item 7 (`tests/scripts/check-pr-body.sh:134` uses `[[ ]]` in a file of `[ ]`) and R2 (`check-pr-body.sh:160` early return without its reason). Its `out_of_scope_noticed` entry (`RISK_SECTION` hard-codes the Risk heading, so renaming it in `pr-template.md` silently disables score checks) is T2's own code, so it joins the round; that makes it a behaviour fix (fresh agent, full review).
- 3.16 wave 1: T1, T2, T3 merged in id order; no task PRs (`task_review: pr`, but `open-task-pr.sh` skipped: origin /Users/tvirani/Desktop/Projects/llm-scaffold-claude is neither GitHub nor GitLab), so `pr` stays null and nothing was pushed.
- 3.15 wave 1: within budget, 7 of 30 changed files. 3.9 wave 1: pass, `TOTAL passed=3126 failed=0` (57 suites; `sign-off-pr` excluded as T4's), evidence `artifacts/gate-3.9-w1/`.

## 2026-10-29 Implementation wave 2: T4 design calls

T4's first round went beyond the task file in two places; put to the stakeholder before the mini-review.

- Q1 Hash check (5.5 logs `git hash-object` of the approved `pr-body.md`; 5.8 refuses to publish and re-asks when it changed). Options: keep / remove. Recommended: keep. Answer: "Remove it". **D17:** no hash; 5.8 reruns only the shape check, as `data-model.md` accepts (content drift between 5.5 and 5.8 is not detected).
- Q2 Separate 5.5 question "Do you approve this PR description?", whose change answer edits `pr-body.md` in place, rechecks and re-asks without the 5.6 loop. Options: keep / fold into 5.6. Recommended: keep. Answer: "Keep it (Recommended)". **D18:** the PR description has its own 5.5 approval; a wording change to it is handled in place; the feature approval keeps 5.6 on No.
- 3.8 T4: mini-review pass (5 pass, 2 n/a), full review after the D17 fix round. Its `out_of_scope_noticed` entry (the 5.8 merge-message temp file is removed only when the whole chain succeeds, so a failed switch or conflicted merge leaves it in `$TMPDIR`) is T4's own block: left as a known minor gap for Phase 4 triage, not filed.
- 3.16 wave 2: T4 merged; no task PR (origin is neither GitHub nor GitLab).
- 3.15 wave 2: within budget, 10 of 30 changed files. 3.9 wave 2 (last): pass, `TOTAL passed=3152 failed=0` (58 suites, nothing excluded), evidence `artifacts/gate-3.9-w2/`. 3.10-3.11: no browser suite (Suites, Browser row: not applicable), so no e2e run; in-review at 3.11.
