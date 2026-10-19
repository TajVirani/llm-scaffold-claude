<!--
File: Phase 5 module of `feature-workflow` (5.1-5.9; order 5.1-5.5, then 5.9, 5.7, 5.8): reconcile the spec, propose and apply Tier A updates line by line, report with evidence, get the stakeholder's approval, decide this spec's open work-backlog items (5.9), run the retrospective, close.
Triggers/inputs: handoff from modules/review-triage.md (after 4.8, or with nothing left to fix); status `in-review`, or `blocked` from 4.7 (D47). Reads spec.md, tasks.md, design-log.md, verification-plan.md, artifacts/, deferred/, specs/work-backlog/<NNN-slug>-disc-*.md.
Outputs/handoff: reconciled spec.md; specs/NNN-slug/proposals.md and report.md (D21); approved Tier A and profile writes; real CAP-### ids (D44, D52); this spec's specs/work-backlog/ items decided at 5.9 (started through discovery, which marks them promoted (D69); kept open; or moved-to-deferred; D57); status `done` after the `retrospective` skill (D25); merge. A change request loops back to modules/questioning-loop.md at 0.3.8 (D49).
Plan refs: PLAN/decision-flow-reference.md Phase 5, "Tier A is agent-proposed, human-approved", "Status", design rule 12; PLAN/decision-flow.mermaid P5 edges; assetlist D9, D16, D20, D21, D25, D29, D35, D44, D45, D47, D49, D50, D51, D52, D57, D68, D69; PLAN/gap-research.md G3 (review-targets `measurements`).
Sources: first-party, adapted from: athola/claude-night-market/plugins/imbue/skills/proof-of-work/SKILL.md@54fcc85 "The Iron Law" and modules/validation-protocols.md (MIT): no completion claim without evidence first. bmad-code-org/BMAD-METHOD skills/bmad-build/step-05-present.md (MIT, Copyright (c) 2025 BMad Code, LLC): a short completion summary (what changed, verification and review result, what was deferred) and "never auto-push"; skills/bmad-retrospective/workflow.md (same repo, MIT): fixes and reconciliations are proposed and the human decides, and the retrospective changes no status itself; prose adapted, no templating; BMad names are trademarks, used for attribution only. EveryInc/compound-engineering-plugin skills/ce-work/references/shipping-workflow.md "Residual Work Gate" (MIT, Copyright (c) 2025 Every; idea only): every unresolved concern is recorded with why it is deferred before the work is presented. Line-by-line approval, the 5.3 step-marked writes, CAP-id assignment and the Codex boundary regeneration are first-party (plan refs above).
-->

# Sign-off (Phase 5)

You reconcile the spec with what shipped, get Tier A changes approved line by line, report real results, and close the feature with the stakeholder. The steps run in the order 5.1-5.5, 5.9, 5.7, 5.8: the backlog offer comes before the retrospective sets `done`. You are done when the spec is `done` and merged (5.8), or when a change request has sent it back to 0.3.8 (5.6).

`specs/NNN-slug` is this feature's folder. Run scripts from the project root with their exact `.agents/skills/feature-workflow/scripts/` prefix (SKILL.md, "Conventions every module follows"). Every status, task-record and step change goes through `status-transition.sh` with the exact `--step` shown; exit 2 is a refused transition: stop and report it. Protected files are written with Write or Edit after the matching step is set, so the write guards can check them (D16). If a guard denies a write, stop and show the stakeholder the denial and the text you meant to write. On Codex, run `check-write.sh` before each protected write as SKILL.md "Host notes" says.

## 5.1 Reconcile spec.md

1. **Set the step.** Read `status` with `yq --front-matter=extract '.status' specs/NNN-slug/spec.md`.
   - `blocked` (from 4.7): `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug in-review --step 5.1`. This lifts the block (D47); do it with the stakeholder present.
   - `in-review`: `.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 5.1`.
2. **Record open findings as known gaps.** For a spec that was blocked, and for any finding still open after 4.7, add one line per finding under `## Known gaps` in `specs/NNN-slug/spec.md`: the finding id, its verified severity and its `deferred/` link.
3. **Reconcile the body with what shipped.** Compare each capability, constraint, non-goal and the success signal with the merged diff (`git diff <baseline_revision>...HEAD`) and the design-log triage entries. Make spec.md describe the feature as built: resolve Assumptions that were confirmed or disproved, empty Open Questions, and keep the `deferred` list matching the files 4.8 wrote. Leave `status` and `blocked_condition` alone. A capability that shipped differently from what was agreed is a finding for the stakeholder at 5.5: name it in the report rather than rewriting the capability to fit.

Done when spec.md matches the merged change and every open finding is a known gap.

## 5.2 Propose Tier A updates

Copy `assets/proposals.md` to `specs/NNN-slug/proposals.md` if it does not exist; if it does (mid-feature redirects and proposal-routed findings land there), keep its rows and continue the `P<n>` numbering. Add one row per change, each with a **Why** that says what an agent would do differently without the line. Leave out any line that changes no behaviour or restates what the code already shows. Gather candidates from:

| Group | Where they come from |
| --- | --- |
| Capabilities | every `CAP-NEW-<slug>` in `specs/NNN-slug/spec.md`: the Proposed text keeps the provisional id until 5.3 assigns `CAP-###`, plus the description and the spec link; an existing `CAP-###` this spec changed: add the spec link to its row |
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
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 5.3
```

- **New capability (D44, D52).** Re-read `docs/capabilities.md` immediately before each assignment and take the next unused number:

  ```bash
  n=$(grep -oE '^\| CAP-[0-9]{3,} ' docs/capabilities.md | grep -oE '[0-9]+' | sort -n | tail -1)
  printf 'CAP-%03d\n' $((10#${n:-0} + 1))
  ```

  Add the row to `docs/capabilities.md` (`CAP-###`, description, link to `specs/NNN-slug/spec.md`). Then replace every `CAP-NEW-<slug>` with the assigned id:
  - `specs/NNN-slug/spec.md`: edit it directly (5.3 is a spec.md writer node, D52).
  - `specs/NNN-slug/tasks.md`: through `set-task` only (D45). For each task id printed by `CAP=CAP-NEW-<slug> yq --front-matter=extract '.tasks[] | select(.capability == strenv(CAP) and .status != "split-out") | .id' specs/NNN-slug/tasks.md` (`split-out` tasks are ignored, D68), run

    ```bash
    .agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T<n> --capability CAP-### --step 5.3
    ```

  - `specs/NNN-slug/verification-plan.md`, `specs/NNN-slug/proposals.md`, `specs/NNN-slug/design-log.md` and `specs/NNN-slug/report.md` (if it exists yet): edit the token in place. In design-log.md this is the one permitted edit of earlier entries; nothing else in them changes.

  Done when `grep -ns 'CAP-NEW-' specs/NNN-slug/{spec,verification-plan,proposals,report,design-log}.md` prints nothing (`-s` skips a report.md not written yet; 5.4 writes it with the real ids) and `yq --front-matter=extract '[.tasks[] | select(.status != "split-out" and (.capability | test("^CAP-NEW-")))] | length' specs/NNN-slug/tasks.md` prints `0`.
- **Glossary term.** Follow `.agents/skills/domain-modeling/SKILL.md` for the entry format and write it now; 5.3 is a glossary step (D51).
- **ADR or a superseded ADR.** Follow `domain-modeling` ("ADRs") with its template and format files.
- **Rule.** Edit `docs/rules.md`. On Claude the `rules-boundary-config-sync` hook regenerates `tools/boundaries/` and blocks if the YAML blocks no longer parse; fix them before moving on. On a host without that hook, run `.agents/skills/project-setup/scripts/generate-boundary-config.sh .` yourself (exit 2: the blocks do not parse, fix them; exit 3: yq or jq is missing, report it) (D9, D20).
- **Pitfall, profile, tool rule.** Edit `docs/decisions/pitfalls.md`, `profiles/<work-type>.md`, and the lint or type-check config named in the row. Editing an existing profile is allowed only here (D50).

Done when every approved and modified row is written, every rejected row is untouched, and `yq --front-matter=extract -e` with the frontmatter validator in `assets/spec.md` still prints `true` for `specs/NNN-slug/spec.md`.

## 5.4 Report

Write `specs/NNN-slug/report.md` from `assets/report.md`. The Write tool refuses a file named `report.md`, so create it with a Bash heredoc and edit it afterwards. Every claim needs evidence you can point to (no completion claim without evidence first):

- **Tests and CI**: the 3.9 suite and CI results at the current `HEAD`. If the newest recorded run is older than `HEAD`, run the suite again and paste the real output. Tool audit rows from `artifacts/<task-id>/toolchain.json`.
- **Targets vs measured**: one row per target in `verification-plan.md`, copied from the `measurements:` table of the newest `artifacts/review/pass-<n>/review-targets.yaml` (target, threshold, measured, result, raw output link; G3). A `not_measurable` row keeps its reason and is a known gap. If the lens failed (no parseable block), each row says `not measured: review-targets failed` and is a known gap.
- **Journeys**: one row per `JRN-###`, linked to its evidence under `artifacts/`. A journey with no evidence is `not exercised`.
- **Review outcome**: passes, rework used, and patched, deferred and dismissed counts from the design-log triage entries; failed lenses; `followup_review_recommended`.
- **Known gaps**: everything under `## Known gaps` in spec.md (light-path suite gaps from 3.14, D29; open findings from 5.1, D47), the lenses' `not_verifiable` and `not_checked` items, and unmeasured targets. A skipped gate is a gap, never a pass.
- **Deferred**: every file in spec.md `deferred`, with its severity.

Done when every PASS links evidence, every number is measured or marked "not measured" with the reason, and every known gap is listed.

## 5.5 Stakeholder approves the work?

Present a short summary: what changed, the verification and review result, what was deferred, and the most important gap, with links to `report.md` and `proposals.md`. Ask whether they approve the work.

- **Yes**: go to 5.9.
- **No, change requested**: go to 5.6.

## 5.6 Change requested: re-enter at 0.3.8

Append a dated entry to `specs/NNN-slug/design-log.md` quoting the request verbatim, ending with `Outcome: loop back (5.6 change request)` so `review-triage` starts a new review cycle. Then follow "Re-entry (5.6)" in `SKILL.md`, which makes the one status call (`status specs/NNN-slug draft --step 5.6`) and loads `modules/questioning-loop.md` at 0.3.8 with the request as the first frontier question (D49). Make that call once: a second `draft` call is refused. Tier A rows applied at 5.3 stay written; a request that reverses one becomes a proposal at the next 5.2.

## 5.9 Offer this spec's open backlog items as the next feature

This runs after 5.5 Yes and before 5.7, so every work item this spec discovered is decided before the spec is `done` (D57; node ids are kept, so 5.9 comes before 5.7). Set the step, then list this spec's open items:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 5.9
for f in specs/work-backlog/NNN-slug-disc-*.md; do [ -f "$f" ] && [ "$(yq --front-matter=extract '.status' "$f")" = open ] && echo "$f"; done
```

No open items: go to 5.7. Otherwise, for each item show the stakeholder its title, **Problem**, **Suggested scope and size** and origin step, and offer three choices. Backlog files are written only in the main session at this step (D57); edit only the keys and lines named here.

- **Start it as the next feature.** Seed a new spec from the item: run 0.1.1-0.1.6 of `modules/discovery.md` ("Seeded from a work item") with the item as the request. It creates `specs/<new NNN-slug>/` at `draft`, marks the item promoted at the new spec's 0.1.4 and deletes it once that spec finishes discovery (D69), and hands the folder name back. Do not edit the item yourself. Set this spec's step again (`.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 5.9`) and append one line to `specs/NNN-slug/design-log.md`: `Backlog item <item file> started as specs/<new NNN-slug> (5.9)`. The new spec waits in `draft` and resumes through the router after this one closes; this spec never absorbs the item.
- **Keep it open.** Change nothing; it stays listed for the stakeholder by the router.
- **Move it to `deferred/`.** Load `modules/deferred-handoff.md` **Write** with the item (concept from its title, origin step 5.9, the item's Problem and Evidence; no `severity`). Then set the step to 5.9 again and Edit the item: `status: moved-to-deferred`, and fill the **Deferred file** link with the path the handoff returned.

After each edit the item's frontmatter must pass the validator in `assets/work-item.md`. If a guard denies the edit, stop and show the stakeholder the denial, as for any protected write.

**Done when:** no item `specs/work-backlog/NNN-slug-disc-*.md` is `open` unless the stakeholder chose to keep it or discovery has taken it (started items are logged in `design-log.md` with their new spec), and every `moved-to-deferred` item links its `deferred/` file. Then go to 5.7.

## 5.7 Retrospective, then done

Run after 5.9 has decided every open backlog item.

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 5.7
```

Invoke the `retrospective` skill for `specs/NNN-slug` with the stakeholder present (D25). It writes `docs/decisions/retrospectives/NNN-slug.md`, process lessons and pitfalls, feature notes in `design-log.md`, and model observations as a `model-map/` entry or a proposed `agent-overrides.yaml` entry (D35). It changes no status. When it returns, read its verdict:

```bash
yq --front-matter=extract '.verdict' docs/decisions/retrospectives/NNN-slug.md
```

- `accepted` or `accepted-with-open-items`: `.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug done --step 5.7` (D47: `done` only from `in-review`).
- `rejected`: leave the status as it is and ask the stakeholder whether this is a change request; if it is, go to 5.6.

## 5.8 Merge and close

With the stakeholder's go-ahead, merge the feature branch into the main branch the way the project merges (a pull request, or a local merge), so the merged commit carries the spec folder, the approved Tier A writes and the retrospective. Push only when the stakeholder asks. Remove leftover implementation worktrees (`git worktree list`, then `git worktree remove <path>` for each one this feature created). Close with a one- or two-sentence summary: what shipped, the merge commit, where the deferred items wait, and which backlog items were promoted (with their new spec folders) or kept open.

Done when the merge has landed and the spec reads `status: done`.
