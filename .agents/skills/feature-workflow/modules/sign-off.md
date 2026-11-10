# Sign-off (Phase 5)

You reconcile the spec with what shipped, prepare everything the stakeholder needs to close the feature, ask them once (5.5), then carry out what they approved without asking again. The steps run in the order 5.1, 5.2, 5.4, 5.5, then 5.3, 5.9, 5.7, 5.8: everything before 5.5 prepares the one sign-off ask, and everything after it applies the answers, the backlog rulings before the retrospective sets `done`. You are done when the spec is `done`, moved to the Done folder and merged (5.8), or when a change request has sent it back to 0.3.8 (5.6).

`.workflow/specs/NNN-slug` is this feature's folder until 5.8 moves it into the Done folder, `.workflow/specs/done/NNN-slug`. Run scripts from the project root with their exact `.agents/skills/feature-workflow/scripts/` prefix ([conventions](../references/conventions.md)). Every status, task-record and step change goes through `status-transition.sh` with the exact `--step` shown; exit 2 is a refused transition: stop and report it. Protected files are written with Write or Edit after the matching step is set, so the write guards can check them. If a guard denies a write, stop and show the stakeholder the denial and the text you meant to write. On Codex, run `check-write.sh` before each protected write as the conventions' [Host notes](../references/conventions.md#host-notes) say.

## 5.1 Reconcile spec.md

1. **Set the step.** Read `status` with `yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md`.
   - `blocked` (from 4.7): `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 5.1`. This lifts the block; do it with the stakeholder present.
   - `in-review`: `.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.1`.
2. **Record open findings as known gaps.** For a spec that was blocked, and for any finding still open after 4.7, add one line per finding under `## Known gaps` in `.workflow/specs/NNN-slug/spec.md`: the finding id, its verified severity and the triage pass that left it open.
3. **Reconcile the body with what shipped.** Compare each capability, constraint, non-goal and the success signal with the merged diff (`git diff <baseline_revision>...HEAD`) and the design-log triage entries. Make spec.md describe the feature as built: resolve Assumptions that were confirmed or disproved, empty Open Questions, and keep the `deferred` list matching the shelf files this spec wrote (0.3.17, 3.14, or a shelf file the stakeholder asked for). Leave `status` and `blocked_condition` alone. A capability that shipped differently from what was agreed is a finding for the stakeholder at 5.5: name it in the report rather than rewriting the capability to fit.

Done when spec.md matches the merged change and every open finding is a known gap.

## 5.2 Propose Tier A updates

Copy `assets/proposals.md` to `.workflow/specs/NNN-slug/proposals.md` if it does not exist; if it does (mid-feature redirects and proposal-routed findings land there), keep its rows and continue the `P<n>` numbering. Add one row per change, each with a **Why** that says what an agent would do differently without the line. Leave out any line that changes no behaviour or restates what the code already shows. Gather candidates from:

| Group | Where they come from |
| --- | --- |
| Capabilities | every `CAP-NEW-<slug>` in `.workflow/specs/NNN-slug/spec.md`: the Proposed text keeps the provisional id until 5.3 assigns `CAP-###`, plus the description and the spec link; an existing `CAP-###` this spec changed: add the spec link to its row |
| Rules | rule conflicts found at 0.3.5; triage findings routed `proposal P<n>`; the `pr_template` row below |
| Decisions | design-log decisions that pass the three-part ADR test in `.agents/skills/domain-modeling/SKILL.md` and were not written at 0.3.7; a term that should enter a glossary |
| Pitfalls | observed failures only: verified `high` or `medium` findings, gates that failed, "profile is wrong" reports |
| Profiles | libraries the project adopted, a location rule that proved wrong, a checklist line that kept catching the same thing or never caught anything |
| Tool rules | a mini-review finding that recurred across tasks (in the `artifacts/<task-id>/` mini-review returns): propose the lint rule, boundary constraint or type-check setting, paired with removing the checklist line it replaces |

**The `pr_template` row.** It picks the template the Sign-off PR description follows at 5.4. Add it when either holds:

- The key is unset (`.agents/skills/feature-workflow/scripts/rules-setting.sh pr_template` prints `workflow` and a note on stderr that the default is used) and the repo has a host PR/MR template at one of the paths listed in `.agents/skills/project-setup/modules/files.md` ("PR template", step 1), and only those. With no host template, add no row.
- 5.4 stopped on a failing setting or an unusable host template and the stakeholder chose to fix the path.

Target `.workflow/rules.md` § Workflow settings; Proposed text `pr_template: <your recommendation>`. The row offers one choice: every host template path found, repo-relative, plus `workflow` (the workflow's own ten-section template). Name the alternatives in Why, so the stakeholder can pick one at 5.5 with `P<n>: modify pr_template: <choice>`.

Every row starts at Status `proposed`. Done when every candidate is a row or was dropped for changing no behaviour.

## 5.4 Report

Write `.workflow/specs/NNN-slug/report.md` from `assets/report.md`. The Write tool refuses a file named `report.md`, so create it with a Bash heredoc and edit it afterwards. Every claim needs evidence you can point to (no completion claim without evidence first):

- **Tests and CI**: the harness and CI results at the current `HEAD`. Run the harness through the toolchain script, which reuses the newest passing full run on the same tree (workflow-data commits do not change it) and runs the harness again only when code changed:

  ```bash
  .agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id sign-off-5.4 --work-type test-harness --cwd "$PWD" --reuse
  ```

  Paste the harness's summary line from `artifacts/sign-off-5.4/toolchain.txt` and that path, not the whole output; `reused_from` in its `toolchain.json` names the run it reused. Tool audit rows from `artifacts/<task-id>/toolchain.json`.
- **Targets vs measured**: one row per target in `verification-plan.md`, copied from the `measurements:` table of the newest `artifacts/review/pass-<n>/review-targets.yaml` (target, threshold, measured, result, raw output link). A `not_measurable` row keeps its reason and is a known gap. If the lens failed (its pass file failed the check), each row says `not measured: review-targets failed` and is a known gap. On the light path, with no `verification-plan.md`, the section reads `no targets (light path)`.
- **Journeys**: one row per `JRN-###`, linked to its evidence under `artifacts/`. A journey with no evidence is `not exercised`.
- **Review outcome**: passes, rework used, and patched, discovered-work, proposal and dismissed counts from the design-log triage entries; failed lenses; `followup_review_recommended`.
- **Known gaps**: everything under `## Known gaps` in spec.md (light-path suite gaps from 3.14; open findings from 5.1), the `Gaps:` line of each triage pass, the lenses' `not_checked` items, and unmeasured targets. A skipped gate is a gap, never a pass.
- **Deferred**: every file in spec.md `deferred`, with its severity when it has one.
- **Open items**: the discovered-work items waiting for the stakeholder's ruling (`modules/discovered-work.md`, 00.25), one line each with its class and recommendation.

For a one-task spec (every light-path spec): write `report.md` as these five lines instead of the template, under the same evidence rules: run the harness through `run-toolchain.sh` as above and link every result.

<!-- The block is indented so its "# Report" title is not read as a heading that ends this section. -->
  ```markdown
  # Report: <feature title>

  - **Changed:** <what is different, in one sentence>; files: <the `files` list of budget-check.sh>; `<baseline_revision>`..`<head sha>`.
  - **Tests:** <the harness summary line> ([toolchain.txt](artifacts/sign-off-5.4/toolchain.txt)); <the 3.13–3.14 suite gap, or "both suites ran">.
  - **Findings:** <n> patched, <n> deferred, <n> dismissed over <n> review passes; failed review: <none | the review>. Detail in design-log.md.
  - **Known gaps:** <spec.md Known gaps, and the review's not_checked and not_verifiable lines, one phrase each | None.>
  - **Merge:** `<spec_branch>` into `<main_branch>` at 5.8, by <PR | local merge>.
  ```

**Then fill the Sign-off PR description**, `.workflow/specs/NNN-slug/pr-body.md`, beside `report.md`. 5.8 publishes it unchanged apart from the spec path the move rewrites, so fill it afresh on every pass through 5.4 (a 5.6 change request comes back through here).

1. **Read the template setting:** `.agents/skills/feature-workflow/scripts/rules-setting.sh pr_template`. When `proposals.md` holds a `pr_template` row, use the template that row proposes instead: the row is approved at 5.5 and applied at 5.3, after this body is filled. Exit 1 (a bad value, or a path whose file is gone): stop and show the stakeholder its message. They choose the workflow template for this PR, or a fixed path through a `pr_template` row (back to 5.2). Never fall back to a template on your own.
2. **Fill the body.**
   - `workflow`: copy `assets/pr-template.md` to `pr-body.md`. Replace each section's guidance comment with its text, drawn from the evidence the comment names (`report.md` as just written, `design-log.md`, `codebase-map.md`, `spec.md`, the `files` list of `budget-check.sh`), and delete the template's header comment. When the change cannot be undone, How to undo this PR says why and Risk is High.
   - A path: fill every heading of that host template, `#` to `######`, at its own level and in its order, from the same evidence; the ten workflow sections are not added. When `tracker_issue` in spec.md is set, end a body filled from a project template with two last lines after a blank line: the issue URL, then `Closes #<n>`, `<n>` being the number the URL ends in, so merging the PR closes the issue. With no tracker, add nothing.
3. **Check it:**

   ```bash
   .agents/skills/feature-workflow/scripts/check-pr-body.sh .workflow/specs/NNN-slug/pr-body.md   # add --project-template <path> when pr_template is a path
   ```

   Exit 1 prints one `<field>: <problem>` line per fault: fix each and run it again.

   Exit 2 whose message names the host template from `pr_template` means that template is unusable: unreadable, or it has no headings at all. Stop and show the stakeholder the message, as for a failing setting in step 1. They choose the workflow template for this PR (fill it again from `assets/pr-template.md` and check without `--project-template`), or a fixed path through a `pr_template` row (back to 5.2). Never fall back to a template on your own. Any other exit 2 is a usage error or a broken install: stop and report it.

Done when every PASS links evidence, every number is measured or marked "not measured" with the reason, every known gap is listed, and `check-pr-body.sh` exits 0 on `pr-body.md`.

## 5.5 The sign-off ask

This is the one question sign-off puts to the stakeholder: it covers the work, the PR description, the proposals, the backlog and the retrospective's lessons. 5.1, 5.2 and 5.4 have prepared the spec, the proposals, the report and the PR body; prepare the rest, then ask once. Every step after this one applies the answers and asks nothing.

1. **Draft the retrospective.** Invoke the `retrospective` skill for `.workflow/specs/NNN-slug` to draft (its Inputs say how). It judges the result against `spec.md`, gives each finding a disposition, and proposes the process lessons, pitfalls, review lessons, feature notes and model observations, numbered `L1`, `L2`, ... with their sources and destinations, in `.workflow/specs/NNN-slug/retrospective-draft.md`. It writes nothing else and asks nothing.
2. **Gather the list:** the discovered-work items still waiting for a ruling (00.25 step 1 in `modules/discovered-work.md`) and the open lines of this spec's backlog list:

   ```bash
   grep -n '^## .* Discovered work: \|to ask (\|^- Ruling: ' .workflow/specs/NNN-slug/design-log.md
   grep -n '^- \[open\]' .workflow/specs/work-backlog/NNN-slug.md 2>/dev/null
   ```

3. **Present a short summary:** what changed, the verification and review result, what was deferred, the most important gap and the retrospective's draft verdict, with links to `report.md`, `proposals.md` and `retrospective-draft.md`. Then show the full text of `.workflow/specs/NNN-slug/pr-body.md`, as 5.8 will publish it apart from the spec path the move rewrites.
4. **Ask, in this order.** First the assumptions not yet offered for veto, as [conventions](../references/conventions.md#asking-the-stakeholder) says, when there are any. Then:
   1. "Do you approve the work and this PR description?" with "Approve both (Recommended)", "Approve the work; change the PR description" (with the changes) and "No: change requested" (with the change).
   2. The proposals, asked only when `proposals.md` has a row. List every row as `P<n>`, its target (the file it writes) and a one-phrase gist, link `proposals.md` for the full text, and ask "Approve every proposal as written, or name exceptions?" with "Approve all (Recommended)". Exceptions are one per line:

      ```text
      P<n>: modify <new text>
      P<n>: reject <reason>
      ```

   3. One question over the whole list (the backlog items), asked only when the list is not empty. One line per item with your recommendation: a waiting item as `<slug> (<class>, found at <node>): <problem>. Recommended: fold in | keep for later | drop (<reason>)`; an open line as `B<n>: <problem>. Recommended: keep for later | start it as the next feature | drop (<reason>)`. The options are "As recommended (Recommended)", "Keep them all for later" and "Drop the waiting items"; per-item exceptions come back as `<slug or B<n>>: fold in | keep | drop | start next` lines. A shelf file is written only for an item the stakeholder names with "move it to the shelf".
   4. The retrospective's lessons, one line per `L<n>` with its destination: "Record these lessons as drafted?" with "Record as drafted (Recommended)" and "None: record the verdict only". Exceptions come back as `L<n>: change <text>` or `L<n>: reject <reason>` lines; any other text is a concern for the retrospective, in the stakeholder's words. With no candidate, ask "Anything you want weighed in the retrospective?" with "Nothing in particular" instead.

   - **Claude Code:** one AskUserQuestion call holding every question. Past its limit of four questions per call, put the rest in a second call straight after, in the same order.
   - **Codex, or chat:** one message with the questions numbered, then wait.
5. **Follow up only on wording you had to write.** When an answer asks for a change without giving its exact text (a PR description change, a `P<n>: modify` that describes the change, a `pr_template` row modified or rejected so the body must be filled from another template), make the change; for the body, run `check-pr-body.sh` as at 5.4 until it exits 0. Then show every such change together in one message, the full body when it changed: "Apply these as worded?". An answer that gave its text stands as given. This follow-up is the only second question sign-off asks, and never follows a No.
6. **Log the answers** in `.workflow/specs/NNN-slug/design-log.md` with the "Sign-off" shape in [../assets/design-log.md](../assets/design-log.md): the assumptions offered, the approval, the PR description, the proposals answer, one `Ruling:` line per item on the list, the lessons answer and any concern, with the stakeholder's words verbatim.

- **Yes**, and no item folded in: go to 5.3, then 5.9, 5.7 and 5.8, each applying the logged answers.
- **No, change requested**, or any item ruled **fold in**: go to 5.6 with the request and every folded-in item as one change request. Nothing else is applied: no proposal is written, no ruling carried out and no lesson recorded. The answers stay logged; when the spec comes back to 5.5, offer them as the recommended answers, with a fresh retrospective draft.

Done when the stakeholder has answered every question, any follow-up is confirmed, and the design-log entry records all of the answers.

## 5.6 Change requested: re-enter at 0.3.8

Append a dated entry to `.workflow/specs/NNN-slug/design-log.md` quoting the request verbatim, ending with `Outcome: loop back (5.6 change request)` so `review-triage` starts a new review cycle. Then follow "Re-entry (5.6)" in `SKILL.md`, which makes the one status call (`status .workflow/specs/NNN-slug draft --step 5.6`) and loads `modules/questioning-loop.md` at 0.3.8 with the request as the first frontier question. Make that call once: a second `draft` call is refused. 5.3 has not run, so no proposal is written; its rows keep `proposed` for the next pass through 5.5.

## 5.3 Apply the approved proposals

Runs after 5.5 Yes, before 5.9; with no row in `proposals.md`, go to 5.9. The stakeholder answered the proposals question at 5.5 (its `Proposals:` line in the Sign-off entry of `design-log.md`), so ask nothing here. Record each answer in its row: a row not named is `approved`; `modified` with the new text in Decision (the stakeholder's text, or the wording they confirmed in the 5.5 follow-up); `rejected` with the reason in Decision.

**Apply.** Then set the step once and write each `approved` or `modified` row:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.3
```

- **New capability.** Re-read `.workflow/capabilities.md` immediately before each assignment and take the next unused number:

  ```bash
  n=$(grep -oE '^\| CAP-[0-9]{3,} ' .workflow/capabilities.md | grep -oE '[0-9]+' | sort -n | tail -1)
  printf 'CAP-%03d\n' $((10#${n:-0} + 1))
  ```

  Add the row to `.workflow/capabilities.md` (`CAP-###`, description, link to `.workflow/specs/NNN-slug/spec.md`). Then replace every `CAP-NEW-<slug>` with the assigned id:
  - `.workflow/specs/NNN-slug/spec.md`: edit it directly (5.3 is a spec.md writer node).
  - `.workflow/specs/NNN-slug/tasks.md`: through `set-task` only. For each task id printed by `CAP=CAP-NEW-<slug> yq --front-matter=extract '.tasks[] | select(.capability == strenv(CAP) and .status != "split-out") | .id' .workflow/specs/NNN-slug/tasks.md` (`split-out` tasks are ignored), run

    ```bash
    .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T<n> --capability CAP-### --step 5.3
    ```

  - `.workflow/specs/NNN-slug/verification-plan.md`, `.workflow/specs/NNN-slug/proposals.md`, `.workflow/specs/NNN-slug/design-log.md`, `.workflow/specs/NNN-slug/report.md`, `.workflow/specs/NNN-slug/pr-body.md` and `.workflow/specs/NNN-slug/retrospective-draft.md`: edit the token in place, and change nothing else. In design-log.md this is the one permitted edit of earlier entries. After a `pr-body.md` edit, run `check-pr-body.sh` on it as at 5.4.

  Done when `grep -ns 'CAP-NEW-' .workflow/specs/NNN-slug/{spec,verification-plan,proposals,report,pr-body,retrospective-draft,design-log}.md` prints nothing and `yq --front-matter=extract '[.tasks[] | select(.status != "split-out" and (.capability | test("^CAP-NEW-")))] | length' .workflow/specs/NNN-slug/tasks.md` prints `0`.
- **Glossary term.** Follow `.agents/skills/domain-modeling/SKILL.md` for the entry format and write it now; 5.3 is a glossary step.
- **ADR or a superseded ADR.** Follow `domain-modeling` ("ADRs") with its template and format files.
- **Rule.** Edit `.workflow/rules.md`. On Claude the `rules-boundary-config-sync` hook regenerates `.workflow/tools/boundaries/` and blocks if the YAML blocks no longer parse; fix them before moving on. On a host without that hook, run `.agents/skills/project-setup/scripts/generate-boundary-config.sh .` yourself (exit 2: the blocks do not parse, fix them; exit 3: yq or jq is missing, report it).
- **Pitfall, profile, tool rule.** Edit `.workflow/decisions/pitfalls.md`, `.workflow/profiles/<work-type>.md`, and the lint or type-check config named in the row. Editing an existing profile is allowed only here.

**Run the harness again after a rule or profile row.** 5.4 ran it before these writes. When an applied row edited `.workflow/rules.md`, a profile or a lint config, run the 5.4 `run-toolchain.sh` call again and put its summary line in `report.md`. A failure stops sign-off: show the stakeholder the output; a fix is a change request (5.6).

Done when every approved and modified row is written, every rejected row is untouched, and `yq --front-matter=extract -e` with the frontmatter validator in `assets/spec.md` still prints `true` for `.workflow/specs/NNN-slug/spec.md`.

## 5.9 Carry out the backlog rulings

This runs after 5.3 and before 5.7, so every item this spec found is decided before the spec is `done` (node ids are kept, so 5.9 comes before 5.7). The stakeholder ruled on each item at 5.5; here you carry the rulings out without asking again. No item on the 5.5 list: go to 5.7. Otherwise set the step:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.9
```

Then apply each `Ruling:` line of the 5.5 design-log entry. Backlog lists are written only in the main session at this step; edit only the lines named here.

- **Keep for later** (a waiting item): add its line through `modules/discovered-work.md` [00.26](discovered-work.md#0026-add-the-backlog-line) steps 2–4; the step is already 5.9. An open line ruled keep: change nothing.
- **Drop**: a waiting item gets nothing beyond its ruling. An open line: delete it from `.workflow/specs/work-backlog/NNN-slug.md` with Edit (delete the file when no line is left).
- **Start it as the next feature.** Seed a new spec from the line: run 0.1.1-0.1.6 of `modules/discovery.md` ("Seeded from a work item") with it as the request. It creates `.workflow/specs/<new NNN-slug>/` at `draft`, marks the line `promoted` at the new spec's 0.1.4, and hands the folder name back. Do not edit the line yourself. Set this spec's step again (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.9`) and append one line to `.workflow/specs/NNN-slug/design-log.md`: `Backlog item B<n> started as .workflow/specs/<new NNN-slug> (5.9)`. The new spec waits in `draft` and resumes through the router after this one closes; this spec never absorbs the item.
- **Move it to the shelf** (only when the stakeholder asked for it). Load `modules/deferred-handoff.md` **Write** with the item (concept from its problem, origin step 5.9, its Problem and Evidence; no `severity`). Then set the step to 5.9 again and delete its line from the backlog list.

After each edit run the line check from [../assets/work-backlog.md](../assets/work-backlog.md) on the list (it prints nothing). If a guard denies the edit, stop and show the stakeholder the denial, as for any protected write.

**Done when:** every `Ruling:` line of the 5.5 entry is carried out: each kept item is an `- [open]` line on the list, each dropped line is gone, and each started item is logged in `design-log.md` with its new spec. Then go to 5.7.

## 5.7 Retrospective, then done

Run after 5.9 has carried out every backlog ruling. Set the step, then check that every sub-item of the spec is closed:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.7
.agents/skills/feature-workflow/scripts/move-to-done.sh --check .workflow/specs/NNN-slug
```

Exit 0: every task record is `done` or `split-out`, and every line on this spec's backlog list is a well-formed `open` or `promoted` line. Exit 1: stop. Show the stakeholder each open item it lists, leave the spec `in-review`, and resume at 5.7 once they are closed; a spec with open sub-items never becomes `done`. Exit 2 is a usage error or a folder that is not a spec: stop and report it.

Invoke the `retrospective` skill for `.workflow/specs/NNN-slug` to finish the draft it wrote at 5.5. It asks nothing: the 5.5 answers are the stakeholder's agreement. It moves `retrospective-draft.md` into `.workflow/decisions/retrospectives/NNN-slug.md` and writes each lesson the 5.5 answer approved: process lessons and pitfalls, feature notes in `design-log.md`, each approved review lesson to `.workflow/review-lessons.md` (created from `assets/review-lessons.md` when the file is missing, and retiring a lesson a rule, lint or profile line now enforces; `.agents/skills/retrospective/modules/routing.md`, "Review lessons", has the procedure), and model observations as a `.workflow/model-map/` entry or a proposed `.workflow/agent-overrides.yaml` entry. Each lesson the stakeholder rejected is recorded as rejected at 5.5. It changes no status. For a one-task spec each section of its document may be one line.

When it returns, read its verdict:

```bash
yq --front-matter=extract '.verdict' .workflow/decisions/retrospectives/NNN-slug.md
```

- `accepted` or `accepted-with-open-items`: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug done --step 5.7` (`done` is reachable only from `in-review`).
- `rejected`: the 5.5 approval overrides a rejecting machine verdict, so this means the retrospective found something the stakeholder did not see. Leave the status as it is, stop and show the stakeholder the verdict and its evidence; a change request goes to 5.6.

**A spec emitted by an initiative** (`yq --front-matter=extract '.initiative // ""' .workflow/specs/NNN-slug/spec.md` prints a name) may be the initiative's last open spec. Write nothing into the initiative here: anything written now would land on the spec branch, and the initiative only counts a spec as `done` once it is `done` on the main branch. The flip happens after 5.8.

## 5.8 Merge and close

Commit what is left on the spec branch (`git status --short`; the spec folder with `pr-body.md`, the approved Tier A writes and the retrospective).

**Copy the final spec into its tracker issue**, while the spec folder is still at its old path:

```bash
.agents/skills/issue-tracking/scripts/issue-tracker.sh fill "$(yq --front-matter=extract '.tracker_issue // ""' .workflow/specs/NNN-slug/spec.md)" .workflow/specs/NNN-slug/spec.md
```

**Check the body again.** Run `check-pr-body.sh` on `pr-body.md` exactly as at 5.4; go on to the move when it exits 0. A fault means an edit after 5.5 broke the body (5.3's id replacement is the only one): when the fix only restores the approved text, fix each line it names, run it again and commit the fixed body; otherwise stop sign-off and show the stakeholder the fault. This is the last point where the body or the design log can change: after the move nothing writes into the spec folder.

**Move the spec into the Done folder.**

```bash
.agents/skills/feature-workflow/scripts/move-to-done.sh .workflow/specs/NNN-slug
```

It runs the 5.7 check again, moves the folder to `.workflow/specs/done/NNN-slug`, deletes `.step`, rewrites the spec's path in the `.workflow/` files that name it (`pr-body.md` included; the initiative files wait for 6.13) and commits on the spec branch. Exit 1: it refused and changed nothing; stop and show the stakeholder what it lists. Exit 2 is a usage error or a folder that is not a spec: stop and report it. From here on the old folder is gone: no later step calls a script on `.workflow/specs/NNN-slug`, and with `.step` deleted the progress line names the folder and the step itself (`.agents/skills/feature-workflow/scripts/step-progress.sh --spec-dir .workflow/specs/done/NNN-slug 5.8`).

**Check the moved body.**

```bash
.agents/skills/feature-workflow/scripts/check-pr-body.sh .workflow/specs/done/NNN-slug/pr-body.md   # add --project-template <path> when pr_template is a path
```

This is a guard, not a question: exit 0 goes straight on to publish. The body passed the same check before the move, the move changed only the spec path in it, and the check reads no paths. Any fault here is a move bug: stop sign-off unpublished, show the stakeholder the output, and report it as a bug in `move-to-done.sh`. The moved folder stays as the move left it; nothing writes into it.

**Publish.** The 5.5 approval of the work and the PR description is the go-ahead; ask nothing more. Merge the spec branch into the main branch through a PR/MR carrying `pr-body.md` as its description, or by a local merge whose message holds it. The route follows the remote, as task merges do: a PR/MR needs a host. Pick the line with the shared host choice that task PRs use, `wf_origin_host` in `.agents/lib/workflow-paths.sh`: `bash -c '. .agents/lib/workflow-paths.sh && wf_origin_host .'` prints `github` for the `gh` line, `gitlab` for the `glab` line, and nothing for any other host or no remote. Without a remote or the CLI, on any other host, or when the stakeholder asks for one, run the last three lines, the local merge, which lands in the main checkout (the first worktree `git worktree list` names), where the main branch is checked out. Never pass `--template`: the approved body is the whole description. Run from the spec checkout, setting the variables in the same Bash command, since each Bash call starts a fresh shell:

- `SPEC_DIR=.workflow/specs/done/NNN-slug`
- `SPEC_BRANCH`: `spec_branch` in `$SPEC_DIR/spec.md` (`spec/NNN-slug`; the move leaves it unchanged).
- `MAIN`: `.agents/skills/feature-workflow/scripts/rules-setting.sh main_branch`.
- `SUBJECT`: a Conventional Commits subject naming the feature, e.g. `feat(<module>): <feature title>`; it is also the PR/MR title.

<!-- 5.8 publish commands -->

```bash
git push -u origin "$SPEC_BRANCH" && gh pr create --base "$MAIN" --head "$SPEC_BRANCH" --title "$SUBJECT" --body-file "$SPEC_DIR/pr-body.md"
git push -u origin "$SPEC_BRANCH" && glab mr create --target-branch "$MAIN" --source-branch "$SPEC_BRANCH" --title "$SUBJECT" --description-file "$SPEC_DIR/pr-body.md" --yes
merge_message=$(mktemp) && { printf '%s\n\n' "$SUBJECT"; cat "$SPEC_DIR/pr-body.md"; } >"$merge_message"
main_checkout=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
git -C "$main_checkout" switch "$MAIN" && git -C "$main_checkout" merge --no-ff -F "$merge_message" --cleanup=verbatim --no-edit "$SPEC_BRANCH" && rm -f "$merge_message"
```

The merge message is built in the spec checkout because `pr-body.md` exists only on the spec branch; git refuses the merge while the main checkout has uncommitted changes to files it touches, so check `git -C "$main_checkout" status --short` first; when it lists anything, stop and show the stakeholder what it lists, since those changes are theirs; `--no-edit` and `--cleanup=verbatim` keep the message to the body as checked, line for line: an editor session would strip the `##` heading lines as comments, and the default cleanup trims blank lines and trailing spaces. Push only what the stakeholder asked for: after a local merge, push the main branch only on request. Remove leftover agent worktrees (`git worktree list`, then `git worktree remove <path>` for each one under `.workflow/.worktrees/` this feature created).

**Move the spec's tracker issue to done, then remove the spec worktree and the spec branch,** once the spec branch is on the main branch: right after a local merge, or once the PR/MR has merged and the main checkout has pulled it. A merged PR/MR closes the issue through its `Closes #<n>` line but leaves the in-progress label, so run the move on both routes; on a closed issue it changes only the label:

```bash
.agents/skills/issue-tracking/scripts/issue-tracker.sh move "$(yq --front-matter=extract '.tracker_issue // ""' .workflow/specs/done/NNN-slug/spec.md)" done
```

Leave the spec worktree first, since the command deletes it: on Claude Code call `ExitWorktree` with `action: keep` when this session entered it with `EnterWorktree` (that returns the session to the main checkout); a session opened in the spec worktree runs it as its last command. From the main checkout:

```bash
.agents/skills/feature-workflow/scripts/spec-worktree.sh remove .workflow/specs/done/NNN-slug
```

It removes `.workflow/.spec-worktrees/NNN-slug` and deletes `spec/NNN-slug` with `git branch -d`, the safe delete, so a branch that is not merged is never lost; a spec run in the main checkout has no spec worktree, and only its branch goes. Exit 1 removes nothing and says what still holds them (not merged yet, uncommitted changes, an agent worktree left inside): fix that and run it again. While the PR/MR is still open, leave the issue, the worktree and the branch, and tell the stakeholder to run both commands once it merges. Close with a one- or two-sentence summary: what shipped, the merge commit, where the deferred items wait, and which backlog items were promoted (with their new spec folders) or kept open.

**Harness after a local merge.** Run the harness on the main branch again only when the merge changed what was tested. Check first; it runs nothing and writes nothing:

```bash
.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/done/NNN-slug --task-id post-merge --work-type test-harness --cwd "$PWD" --reuse-check
```

Exit 0: the merge result is a tree the harness already passed on (it prints the run, usually `sign-off-5.4`); do not run it again, and name that run in the closing summary. Exit 1: the main branch had moved, so run the harness command from `## Suites` (the `test` key of the test-harness profile) and report its summary line. Exit 2 is a usage or setup error: report it and run the harness.

**Close the initiative.** For a spec that carries `initiative:`, once the merge has landed on main, load [large-path](large-path.md#613-close-when-every-spec-is-done) at 6.13 for that initiative. 6.13 first reads the initiative's status on main, then at the tip of `initiative/NNN-slug` when that branch exists locally or on `origin`: while the initiative is still exploring (absent from main, `exploring` there, or `exploring` at the branch tip after a reopen), it tells the stakeholder so and writes nothing. A branch whose tip reads `planned`, left on `origin` by a merged PR, does not stop the close. When it is `planned` and every emitted spec is `done` on main (at the top level or in the Done folder), it re-points the initiative's links to the specs now in the Done folder and moves the initiative to `done` through `initiative-transition.sh` on a re-created `initiative/NNN-slug` and merges that change into main the way `planned` was merged; otherwise it tells the stakeholder which specs are still open. While the PR/MR is still open, skip this: the initiative's next resume runs the same check.

Done when the PR is open (or the local merge has landed) with the stakeholder told where, the spec's tracker issue is moved to done and the spec worktree and spec branch are removed once merged (or the stakeholder has the commands for when the PR/MR merges), the spec sits in `.workflow/specs/done/NNN-slug` reading `status: done`, and a spec carrying `initiative:` has been through the 6.13 check or waits for its PR/MR.
