# Sign-off (Phase 5)

You reconcile the spec with what shipped, get Tier A changes approved line by line, report real results, and close the feature with the stakeholder. The steps run in the order 5.1-5.5, 5.9, 5.7, 5.8: the backlog offer comes before the retrospective sets `done`. You are done when the spec is `done` and merged (5.8), or when a change request has sent it back to 0.3.8 (5.6).

`.workflow/specs/NNN-slug` is this feature's folder. Run scripts from the project root with their exact `.agents/skills/feature-workflow/scripts/` prefix (SKILL.md, "Conventions every module follows"). Every status, task-record and step change goes through `status-transition.sh` with the exact `--step` shown; exit 2 is a refused transition: stop and report it. Protected files are written with Write or Edit after the matching step is set, so the write guards can check them. If a guard denies a write, stop and show the stakeholder the denial and the text you meant to write. On Codex, run `check-write.sh` before each protected write as SKILL.md "Host notes" says.

## 5.1 Reconcile spec.md

1. **Set the step.** Read `status` with `yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md`.
   - `blocked` (from 4.7): `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 5.1`. This lifts the block; do it with the stakeholder present.
   - `in-review`: `.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.1`.
2. **Record open findings as known gaps.** For a spec that was blocked, and for any finding still open after 4.7, add one line per finding under `## Known gaps` in `.workflow/specs/NNN-slug/spec.md`: the finding id, its verified severity and its `.workflow/deferred/` link.
3. **Reconcile the body with what shipped.** Compare each capability, constraint, non-goal and the success signal with the merged diff (`git diff <baseline_revision>...HEAD`) and the design-log triage entries. Make spec.md describe the feature as built: resolve Assumptions that were confirmed or disproved, empty Open Questions, and keep the `deferred` list matching the files 4.8 wrote. Leave `status` and `blocked_condition` alone. A capability that shipped differently from what was agreed is a finding for the stakeholder at 5.5: name it in the report rather than rewriting the capability to fit.

Done when spec.md matches the merged change and every open finding is a known gap.

## 5.2 Propose Tier A updates

Copy `assets/proposals.md` to `.workflow/specs/NNN-slug/proposals.md` if it does not exist; if it does (mid-feature redirects and proposal-routed findings land there), keep its rows and continue the `P<n>` numbering. Add one row per change, each with a **Why** that says what an agent would do differently without the line. Leave out any line that changes no behaviour or restates what the code already shows. Gather candidates from:

| Group | Where they come from |
| --- | --- |
| Capabilities | every `CAP-NEW-<slug>` in `.workflow/specs/NNN-slug/spec.md`: the Proposed text keeps the provisional id until 5.3 assigns `CAP-###`, plus the description and the spec link; an existing `CAP-###` this spec changed: add the spec link to its row |
| Rules | rule conflicts found at 0.3.5; triage findings routed `defer (proposal P<n>)` |
| Decisions | design-log decisions that pass the three-part ADR test in `.agents/skills/domain-modeling/SKILL.md` and were not written at 0.3.7; a term that should enter a glossary |
| Pitfalls | observed failures only: verified `high` or `medium` findings, gates that failed, "profile is wrong" reports |
| Profiles | libraries the project adopted, a location rule that proved wrong, a checklist line that kept catching the same thing or never caught anything |
| Tool rules | a mini-review finding that recurred across tasks (in the `artifacts/<task-id>/` mini-review returns): propose the lint rule, boundary constraint or type-check setting, paired with removing the checklist line it replaces |

Every row starts at Status `proposed`. Done when every candidate is a row or was dropped for changing no behaviour.

## 5.3 Approve line by line, then apply

**Approve.** Walk the stakeholder through the rows one at a time: approve, modify, or reject. Record each answer in the row: `approved`; `modified` with the new text in Decision; `rejected` with the reason in Decision. A modified line is shown again in its new wording and applied only once the stakeholder confirms it. Apply nothing until every row has an answer.

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

  - `.workflow/specs/NNN-slug/verification-plan.md`, `.workflow/specs/NNN-slug/proposals.md`, `.workflow/specs/NNN-slug/design-log.md` and `.workflow/specs/NNN-slug/report.md` (if it exists yet): edit the token in place. In design-log.md this is the one permitted edit of earlier entries; nothing else in them changes.

  Done when `grep -ns 'CAP-NEW-' .workflow/specs/NNN-slug/{spec,verification-plan,proposals,report,design-log}.md` prints nothing (`-s` skips a report.md not written yet; 5.4 writes it with the real ids) and `yq --front-matter=extract '[.tasks[] | select(.status != "split-out" and (.capability | test("^CAP-NEW-")))] | length' .workflow/specs/NNN-slug/tasks.md` prints `0`.
- **Glossary term.** Follow `.agents/skills/domain-modeling/SKILL.md` for the entry format and write it now; 5.3 is a glossary step.
- **ADR or a superseded ADR.** Follow `domain-modeling` ("ADRs") with its template and format files.
- **Rule.** Edit `.workflow/rules.md`. On Claude the `rules-boundary-config-sync` hook regenerates `.workflow/tools/boundaries/` and blocks if the YAML blocks no longer parse; fix them before moving on. On a host without that hook, run `.agents/skills/project-setup/scripts/generate-boundary-config.sh .` yourself (exit 2: the blocks do not parse, fix them; exit 3: yq or jq is missing, report it).
- **Pitfall, profile, tool rule.** Edit `.workflow/decisions/pitfalls.md`, `.workflow/profiles/<work-type>.md`, and the lint or type-check config named in the row. Editing an existing profile is allowed only here.

Done when every approved and modified row is written, every rejected row is untouched, and `yq --front-matter=extract -e` with the frontmatter validator in `assets/spec.md` still prints `true` for `.workflow/specs/NNN-slug/spec.md`.

## 5.4 Report

Write `.workflow/specs/NNN-slug/report.md` from `assets/report.md`. The Write tool refuses a file named `report.md`, so create it with a Bash heredoc and edit it afterwards. Every claim needs evidence you can point to (no completion claim without evidence first):

- **Tests and CI**: the 3.9 suite and CI results at the current `HEAD`. If the newest recorded run is older than `HEAD`, run the suite again and paste the real output. Tool audit rows from `artifacts/<task-id>/toolchain.json`.
- **Targets vs measured**: one row per target in `verification-plan.md`, copied from the `measurements:` table of the newest `artifacts/review/pass-<n>/review-targets.yaml` (target, threshold, measured, result, raw output link). A `not_measurable` row keeps its reason and is a known gap. If the lens failed (no parseable block), each row says `not measured: review-targets failed` and is a known gap.
- **Journeys**: one row per `JRN-###`, linked to its evidence under `artifacts/`. A journey with no evidence is `not exercised`.
- **Review outcome**: passes, rework used, and patched, deferred and dismissed counts from the design-log triage entries; failed lenses; `followup_review_recommended`.
- **Known gaps**: everything under `## Known gaps` in spec.md (light-path suite gaps from 3.14; open findings from 5.1), the lenses' `not_verifiable` and `not_checked` items, and unmeasured targets. A skipped gate is a gap, never a pass.
- **Deferred**: every file in spec.md `deferred`, with its severity.

Done when every PASS links evidence, every number is measured or marked "not measured" with the reason, and every known gap is listed.

## 5.5 Stakeholder approves the work?

Present a short summary: what changed, the verification and review result, what was deferred, and the most important gap, with links to `report.md` and `proposals.md`. Ask whether they approve the work.

- **Yes**: go to 5.9.
- **No, change requested**: go to 5.6.

## 5.6 Change requested: re-enter at 0.3.8

Append a dated entry to `.workflow/specs/NNN-slug/design-log.md` quoting the request verbatim, ending with `Outcome: loop back (5.6 change request)` so `review-triage` starts a new review cycle. Then follow "Re-entry (5.6)" in `SKILL.md`, which makes the one status call (`status .workflow/specs/NNN-slug draft --step 5.6`) and loads `modules/questioning-loop.md` at 0.3.8 with the request as the first frontier question. Make that call once: a second `draft` call is refused. Tier A rows applied at 5.3 stay written; a request that reverses one becomes a proposal at the next 5.2.

## 5.9 Offer this spec's open backlog items as the next feature

This runs after 5.5 Yes and before 5.7, so every work item this spec discovered is decided before the spec is `done` (node ids are kept, so 5.9 comes before 5.7). Set the step, then list this spec's open items:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.9
for f in .workflow/specs/work-backlog/NNN-slug-disc-*.md; do [ -f "$f" ] && [ "$(yq --front-matter=extract '.status' "$f")" = open ] && echo "$f"; done
```

No open items: go to 5.7. Otherwise, for each item show the stakeholder its title, **Problem**, **Suggested scope and size** and origin step, and offer three choices. Backlog files are written only in the main session at this step; edit only the keys and lines named here.

- **Start it as the next feature.** Seed a new spec from the item: run 0.1.1-0.1.6 of `modules/discovery.md` ("Seeded from a work item") with the item as the request. It creates `.workflow/specs/<new NNN-slug>/` at `draft`, marks the item promoted at the new spec's 0.1.4 and deletes it once that spec finishes discovery, and hands the folder name back. Do not edit the item yourself. Set this spec's step again (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.9`) and append one line to `.workflow/specs/NNN-slug/design-log.md`: `Backlog item <item file> started as .workflow/specs/<new NNN-slug> (5.9)`. The new spec waits in `draft` and resumes through the router after this one closes; this spec never absorbs the item.
- **Keep it open.** Change nothing; it stays listed for the stakeholder by the router.
- **Move it to `.workflow/deferred/`.** Load `modules/deferred-handoff.md` **Write** with the item (concept from its title, origin step 5.9, the item's Problem and Evidence; no `severity`). Then set the step to 5.9 again and Edit the item: `status: moved-to-deferred`, and fill the **Deferred file** link with the path the handoff returned.

After each edit the item's frontmatter must pass the validator in `assets/work-item.md`. If a guard denies the edit, stop and show the stakeholder the denial, as for any protected write.

**Done when:** no item `.workflow/specs/work-backlog/NNN-slug-disc-*.md` is `open` unless the stakeholder chose to keep it or discovery has taken it (started items are logged in `design-log.md` with their new spec), and every `moved-to-deferred` item links its `.workflow/deferred/` file. Then go to 5.7.

## 5.7 Retrospective, then done

Run after 5.9 has decided every open backlog item.

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 5.7
```

Invoke the `retrospective` skill for `.workflow/specs/NNN-slug` with the stakeholder present. It writes `.workflow/decisions/retrospectives/NNN-slug.md`, process lessons and pitfalls, feature notes in `design-log.md`, and model observations as a `.workflow/model-map/` entry or a proposed `.workflow/agent-overrides.yaml` entry. It changes no status. When it returns, read its verdict:

```bash
yq --front-matter=extract '.verdict' .workflow/decisions/retrospectives/NNN-slug.md
```

- `accepted` or `accepted-with-open-items`: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug done --step 5.7` (`done` is reachable only from `in-review`).
- `rejected`: leave the status as it is and ask the stakeholder whether this is a change request; if it is, go to 5.6.

**A spec emitted by an initiative** (`yq --front-matter=extract '.initiative // ""' .workflow/specs/NNN-slug/spec.md` prints a name) may be the initiative's last open spec. Write nothing into the initiative here: anything written now would land on the spec branch, and the initiative only counts a spec as `done` once it is `done` on the main branch. The flip happens after 5.8.

## 5.8 Merge and close

Commit what is left on the spec branch (`git status --short`; the spec folder, the approved Tier A writes and the retrospective). With the stakeholder's go-ahead, merge the spec branch (`spec_branch` in `spec.md`, `spec/NNN-slug`) into the main branch (`rules-setting.sh main_branch`, `main` below) through a pull request: push it and open the PR with `gh pr create --base main --head spec/NNN-slug` or `glab mr create --target-branch main --source-branch spec/NNN-slug`, titled after the feature and linking `report.md` and the task PRs/MRs (`pr` on the records). Without a remote or CLI, or when the stakeholder asks for one, merge locally (`git merge --no-ff spec/NNN-slug` on main). Push only what the stakeholder asked for. Remove leftover worktrees (`git worktree list`, then `git worktree remove <path>` for each one under `.workflow/.worktrees/` this feature created). Close with a one- or two-sentence summary: what shipped, the merge commit, where the deferred items wait, and which backlog items were promoted (with their new spec folders) or kept open.

**Close the initiative.** For a spec that carries `initiative:`, once the merge has landed on main, load [large-path](large-path.md#613-close-when-every-spec-is-done) at 6.13 for that initiative. 6.13 first reads the initiative's status on main: while the initiative is still exploring (absent from main, or `exploring` there), it tells the stakeholder so and writes nothing. When it is `planned` and every emitted spec is `done` on main, it moves the initiative to `done` through `initiative-transition.sh` on a re-created `initiative/NNN-slug` and merges that change into main the way `planned` was merged; otherwise it tells the stakeholder which specs are still open. While the PR/MR is still open, skip this: the initiative's next resume runs the same check.

Done when the PR is open (or the local merge has landed) with the stakeholder told where, the spec reads `status: done`, and a spec carrying `initiative:` has been through the 6.13 check or waits for its PR/MR.
