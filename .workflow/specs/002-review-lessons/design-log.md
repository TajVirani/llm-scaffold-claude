# Design log: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md)

## 2026-10-21 Term gate 0.2.2: Review lesson

- Gate ran for the one new term the request introduces. Agreed and written at 0.2.3: **Review lesson** in `.workflow/GLOSSARY.md`, plus `review-lessons` in the Task type list and the review lessons in the Tier A entry.
- Stakeholder: "Review lesson (Recommended)".

## 2026-10-21 Placement: retrospective

- Owning module: retrospective
- Alternatives considered: feature-workflow: owns the Phase 4 step, the launch table, the write-guard classes and the step list, and was the orchestrator's recommendation; agents: owns only the new lens file and cannot own the triage or guard changes.
- Conflict with an ADR or rule: none. `retrospective` may depend on `feature-workflow` and gains no dependency; the lens lives in `agents`, which may depend on `feature-workflow`; `.workflow/review-lessons.md` is project data owned by no module; `.agents/lib/workflow-paths.sh` is shared core and changes only through the integration agent.
- Decision: **D1** The retrospective module owns the change: it defines the review lesson and writes it at 5.7. The lens (`agents`), the Phase 4 wiring and guard class (`feature-workflow`), the thin hooks (`hooks`), the empty file for new projects (`project-setup`), the manifest (`installer`), the READMEs (`root-docs`) and the suites (`tests`) are satellite tasks inside their own ownership. Stakeholder: "retrospective". ADR: [.workflow/decisions/adr/0002-review-lessons-placement.md](../../decisions/adr/0002-review-lessons-placement.md)

## 2026-10-21 Deeper prompt

**Ask:** Let the lessons a retrospective records reach the Phase 4 review of every later feature without a human rewriting them as rules: the retrospective writes a review lesson directly, and a fourth review lens checks each change against the recorded lessons, pitfalls and retrospectives.

**Goals:**
- A review lesson approved at 5.7 is written by the retrospective to `.workflow/review-lessons.md` at that step and nowhere else; a rejected one writes nothing.
- The `review-lessons` lens, launched with the other three lenses on the cheap tier, returns one high-severity finding per recorded lesson the change repeats, in the `review-findings` block triage already validates, so triage grades and routes it unchanged.
- The Tier A guard allows the lessons file at 5.7 and denies it at every other step; a lens launch with the header is accepted and one without a model is refused.
- New projects get an empty lessons file from project-setup; the lens ships with its model-map entry, manifest, provenance, README lines and generated Codex toml.
- `tests/run-all.sh` passes with a new suite for the lens contract and the guard case, plus shellcheck and the lint suites.

**Downstream:** none known.

**Tools and technologies:** bash 3.2, jq, mikefarah yq v4, markdown. The lessons file is a fenced YAML list validated with yq; the lens is an LLM sub-agent on the cheap tier.

**Gotchas:** the step-list lint pins Phase 4 at 8 steps and compares ids with the PLAN docs; `check-write.sh` treats the lessons file as unguarded today; a launch with no model-map entry is denied at 00.14; the bash harness cannot run an LLM, so "exactly one finding" needs a live-run journey beside the harness tests; `.agents/lib/workflow-paths.sh` is shared core.

**Not asked for:** changing the inputs of the three existing lenses; auto-writing rules or profile checklist lines; changing pr-quality; inventing lessons (the fixture lesson is the only content); retrieval reading the lessons file at discovery.

**Original request:** "Add a fourth Phase 4 review lens that checks a change against lessons recorded by past retrospectives, and let the retrospective write those lessons directly." (headline sentence; the five design points, acceptance criteria and non-goals follow it in the request)

Revisions: agreed as first restated. Stakeholder: "Yes, pass it on". Downstream, tools and gotchas answers: "None known", "Fenced YAML list", "None beyond those".

## 2026-10-21 Questioning round 1

**Q1. Step id for the lens launch: new id without renumbering, or renumber 4.4-4.8?**

- Why now: the deeper prompt's gotcha that the step-list lint pins Phase 4 at 8 and compares ids with the PLAN docs; fact-lookup showed renumbering touches 26 files and 181 lines and that the progress line uses row order (`step-progress.sh:84-88`)
- Options: A: `4.9` placed in run order after 4.3, lint counts 4:9, one node in each PLAN doc · B: renumber 4.4-4.8 to 4.5-4.9 across 26 files
- Recommended: A, because ids already run out of order in Phase 0 (0.3.22 runs before 0.3.8) and the progress line counts rows, not ids (codebase-map.md § Relevant code, "Step list")
- Answer: "ID can be out of order, but step count needs to be in order"
- Decision: **D2** The lens launch is step `4.9`. Its `steps.tsv` row sits right after 4.3, so the progress line counts it fourth in Phase 4 and 4.4-4.8 shift to fifth through ninth; the lint's Phase 4 count becomes 9 on both paths; both PLAN docs gain the node.

**Q2. Entry shape of `.workflow/review-lessons.md`?**

- Why now: the deeper prompt fixed a fenced YAML list; the fields drive the lens, the retrospective write, the project-setup template and the tests
- Options: A: `lessons:` list, each entry `id` (`RL-001`, zero-padded, never reused), `symptom`, `paths` (repo-relative globs, Ownership-block syntax), `origin_spec`, `date` (ISO); lens finding prefix `RL` · B: another field set
- Recommended: A, because the request names exactly those five facts and triage hard-codes one prefix per lens (codebase-map.md § Relevant code, "Lens result check")
- Answer: "A"
- Decision: **D3** The entry shape is option A; the lens's finding ids are `RL-<n>`.

**Q3. Severity of findings drawn from `pitfalls.md` and `retrospectives/`?**

- Why now: the request has the lens read both, but only review lessons carry a path scope
- Options: A: repeated review lesson high; repeated pitfall or retrospective lesson with no review-lesson entry medium, text suggests recording it at the next 5.7 · B: high for all · C: review lessons only, the others context
- Recommended: A, because a prose lesson has no scope and the acceptance criterion counts only review-lesson findings as high
- Answer: "A"
- Decision: **D4** A repeated review lesson is a high finding; a repeated pitfall or retrospective lesson is a medium finding that suggests recording it as a review lesson; the confidence filter applies to both.

**Q4. Missing `.workflow/review-lessons.md` in a project set up before this change?**

- Why now: the lens contract and the guard depend on it; projects installed earlier have no file
- Options: A: `status: done`, file under `not_checked`, pitfalls and retrospectives still checked · B: `status: blocked`
- Recommended: A, mirroring review-targets with no Targets section
- Answer: "If the file doesn't exist, create it before use."
- Decision: **D5** A missing lessons file is created from the project-setup template before it is used, never reported as missing or blocking. Who creates it, given that the lens is read-only, is round 2's Q1.

**Q5. Retiring a lesson once a rule, lint or profile line enforces it?**

- Why now: D3 gives entries an id and origin; the pitfalls rule already says remove an entry only when a tool enforces it
- Options: A: the retrospective removes it at 5.7 under the same approval · B: humans only, outside a feature · C: a 5.3 proposal (needs the guard to admit 5.3)
- Recommended: A, because it keeps the guard at 5.7 only and mirrors the pitfalls rule (codebase-map.md § Prior decisions, "Closest precedent: pitfalls file")
- Answer: "A"
- Decision: **D6** The retrospective removes a superseded entry at 5.7 under the same per-entry approval it uses to add one; the guard admits the file at 5.7 only.

**Q6. How to prove "exactly one finding" when the harness cannot run an LLM?**

- Answer: "This is poorly worded and I don't understand the question" (re-asked, reworded, in round 2)
- Decision: none yet

Facts looked up instead of asked (0.3.10): no per-lens step marker is set in review-triage (`modules/review-triage.md:17-39`); `status-transition.sh` accepts any dotted id (`:114`); the lint pins `4:8` on both paths and compares ids with `PLAN/decision-flow-reference.md:472` and `PLAN/decision-flow.mermaid:162-166` (`tests/lint/step-list.sh:37-57`); `check-write.sh` classes the lessons file as `other` today (`:182-210`) and the per-class step lists are at `:60-68, 318-331`; the retrospective writes pitfalls at 5.7 with per-entry approval (`retrospective/SKILL.md:26-30, 65`; `modules/routing.md:16-26`); project-setup creates files from the table in `modules/files.md:5-13`; `install.sh:28` never touches `.workflow/` and the manifest ships whole skill folders; no test validates a `review-findings` block today (`tests/scripts/resolve-launch.sh:154-156` covers headers only); the lineage lint needs no entry for a first-party agent (`tests/lint/upstream-lineage.sh:8-10`); suites are discovered under `tests/{scripts,hooks,lint}/` and build fixtures with `make_fixture_repo` (`tests/lib/common.sh:139-143`); `assetlist.md:36, 543-550, 688` and `PROVENANCE.md:125` carry the per-agent entries, `README.md:41` names the three lenses, `.agents/README.md:6` names only the folder.

## 2026-10-21 Questioning round 2

**Q1. Who creates a missing `.workflow/review-lessons.md`, given that the lens is read-only?**

- Why now: D5 settled that the file is created rather than reported missing; sub-agents never write
- Options: A: review-triage copies the template before launching the lenses and the retrospective copies it before its first write · B: the retrospective only, at 5.7; the lens reads a missing file as an empty list · defer
- Recommended: A, so the lens always finds the file
- Answer: "Retrospective only, at 5.7"
- Decision: **D7 (refines D5)** The retrospective creates the file from the project-setup template at 5.7 before its first write; no other step creates it. The lens reads a missing file as an empty list and continues with pitfalls and retrospectives.

**Q2. (Round 1 Q6 reworded) What proves "one lesson plus a repeating diff gives exactly one high finding, and none without the repeat", when the bash harness cannot launch an LLM?**

- Why now: the acceptance criteria ask for both a new suite and a behavioural result no bash test can observe
- Options: A: a live run by hand (two launches against a fixture repo, returns saved under `artifacts/`) plus a harness suite for the bash-checkable contract · B: harness only · C: live run only
- Recommended: A, because the harness can validate a canned return, the guard, pre-launch and the templates, and only a real launch shows the lens's judgement (codebase-map.md § Relevant code, "Tests on launch")
- Answer: "Live run plus harness (Recommended)"
- Decision: **D8** Proof is both: the harness suite covers the triage yq checks with prefix `RL`, the guard at 5.7 and every other step, pre-launch accept and deny, the project-setup template and the manifest and README counts; a live-run journey launches the real lens twice against a fixture repo and stores both returns as evidence.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-21 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Review lesson (entry) | create | id, symptom, paths, origin_spec, date; see data-model.md § Review lesson |
| Review lessons file `.workflow/review-lessons.md` | create | one fenced YAML `lessons:` list; Tier A, guard class writable at 5.7 only; see data-model.md § Review lessons file |
| Agent definition `.agents/agents/review-lessons.md` | create | the lens; frontmatter `name`, `description`, `tools`; see data-model.md § Interfaces |
| Model-map entry `.workflow/model-map/review-lessons.md` | create | cheap tier, claude haiku, codex gpt-6-luna |
| Project-setup template `assets/docs/review-lessons.md` and `modules/files.md` row | create / extend | new projects get the empty file |
| Lens finding (`review-findings` block item) | extend | ids `RL-<n>`, `category: lesson`, `lesson:` field, severity high or medium |
| Task-type table row (`resolve-launch.sh` D31_TABLE) | extend | `review-lessons`: `spec_dir` only, profile none |
| Step list (`steps.tsv`, `tests/lint/step-list.sh` counts, both PLAN docs) | extend | row `4.9` after 4.3; Phase 4 count 9 on both paths |
| Write-guard class (`check-write.sh`) | extend | kind `review-lessons`, steps `5.7`; `SKILL.md` guarded-writes table row |
| Path variable (`workflow-paths.sh`, shared core) | extend | one `WF_` variable for the file |
| Retrospective routing and writes (`SKILL.md`, `modules/routing.md`, `assets/retrospective.md`) | extend | third destination; create the file when missing; retire a superseded entry |
| Review triage (`modules/review-triage.md`) | extend | launch four lenses, wait for four, prefix `RL` |
| Design-log asset lens list, sign-off 5.7 prose | extend | name the fourth lens and the lessons write |
| Manifest, PROVENANCE, READMEs, assetlist, generated Codex toml | extend | housekeeping for one new agent and one new template |
| `pre-launch.sh`, `tier-a-write-guard.sh`, `generate-codex-agents.sh`, `install.sh`, the three existing lens definitions | unchanged | read the extended tables or are re-run; the hook headers only gain prose |

## 2026-10-21 Scope decision: retrospective template drift

- Item: the module audit noticed two stale notes in `.agents/skills/retrospective/assets/retrospective.md` (its header comment lists rules and profiles as Tier A files the skill writes; its Model observations text names a project-root `agent-overrides.yaml`), both `can-wait`.
- Ruling: deferred, because the feature adds a destination and does not re-audit the template's prose; a fix would widen the diff with nothing to test it.
- Handoff: [.workflow/deferred/retrospective-template-drift.md](../../deferred/retrospective-template-drift.md) (AFK), also listed in spec.md `deferred`

## 2026-10-21 Module audit follow-up

- The audit (codebase-map.md § Module audit) found no conflict with the goal or the placement, and two findings that refine earlier decisions:
- Decision: **D9** The empty lessons-file template lives at `.agents/skills/feature-workflow/assets/review-lessons.md`. `retrospective` may depend on `feature-workflow` only and `project-setup` may depend on `feature-workflow`, so one template there serves both: project-setup's `modules/files.md` row sources it for new projects, and the retrospective copies it at 5.7 when the file is missing (D7). A template under project-setup would have made the retrospective depend on project-setup, which the Ownership block forbids. This supersedes the "project-setup template `assets/docs/review-lessons.md`" note in the Impact classification entry.
- Decision: **D10 (refines D6)** Retiring a lesson keeps its entry in the `lessons:` list, marked `retired: <date>` and `enforced_by: <the rule, lint or profile line>`; the lens skips retired entries. D3 fixed ids as never reused and D6 said the entry is removed; the two meet only if the id stays in the file, and `.workflow/capabilities.md` already follows the same rule ("a removed capability keeps its row, marked retired"). Retirement candidates come from this feature's approved 5.3 proposals and from the stakeholder at step 5; the retrospective reads nothing new to find them.
- Routing distinction, for `routing.md`: a judgement lesson whose symptom a reader can see in a diff and that names the paths it applies to is a review lesson and is written; a judgement lesson about process, or with no diff-visible symptom, stays an action item (checklist or rules line). The audit's friction note holds: the lesson kinds live in the routing table, the template's Kind column and step 6's list, and all three change together.

## 2026-10-21 Exit gate 0.6

- D9 and D10 put to the stakeholder with the gate: "Both confirmed". Scope, system impact, data changes and testable objectives all clear; status set to `ready-for-dev` at 0.6. Stakeholder chose a fresh session for Phase 1: "Fresh session".

## 2026-10-22 Phase 1 note: the lens contract moved since discovery

- Main moved from `6704f93` to `4724073` between 0.6 and 1.1 (the fix/test-cost merge). Each Phase 4 lens now writes its `review-findings` block to `<spec_dir>/artifacts/review/pass-<n>/<lens>.yaml` with one heredoc and returns a summary block, and triage checks that file with `.agents/skills/feature-workflow/scripts/check-review-findings.sh`, whose lens table (prefix and allowed categories per lens) replaced the inline yq checks in `modules/review-triage.md`.
- The constraint "the same block as the other lenses; triage changes only by adding the fourth prefix" keeps its intent: the fourth lens writes its pass file the same way, and the script's lens table gains the row `review-lessons` (prefix `RL`, category `lesson`). No decision needed. The end-state lines and JRN-001 to JRN-003 in `verification-plan.md` now name the script and the pass file; `tests/scripts/check-review-findings.sh` is the suite JRN-003 extends.
- Targets filled at 1.1: lint and coverage rows from the profiles and `spec.md`; performance: no target. Stakeholder: "No performance target (Recommended)".
