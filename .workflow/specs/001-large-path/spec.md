---
status: ready-for-dev # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "f7a4b23b895c0b7a81d8b7517ec6be87dba3b6fd" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "spec/001-large-path" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/shared-path-normaliser.md, .workflow/deferred/sign-off-scoped-commit.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
budget: {max_tasks: 10, max_changed_files: 30} # written at 2.5 from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Large path: planning a large subject into several specs

## Why

Let the workflow take on a subject too large or too uncertain for one spec: plan it as an initiative across sessions, keep what is known, unknown and decided on disk, and hand each settled slice to the existing light or full path as its own spec. The large path plans; it never builds. Today both paths assume the route can be settled inside one spec's discovery (one owning module, one capability, one orchestrator, Open Questions empty before the spec is final), so a large subject is either forced into one oversized spec that the size budget halts, or charted by hand outside the workflow, as the wayfinder comparison page concedes. The loop settled the shape: every request still starts as a spec; discovery converts the spec into an initiative when it finds several features; the initiative explores its questions in rounds, with research by agents that may stay pending across sessions; each slice that settles is emitted as an ordinary spec that carries its initiative as origin; the initiative lives on its own branch, reaches main by PR when it is planned, and closes itself on its next resume once every emitted spec is done. It matters now because the scaffold has started to run the workflow on itself and its first real changes are exactly this shape.

## Capabilities

- **CAP-NEW-initiative-conversion** Convert a spec into an initiative
  - **intent:** A stakeholder in a spec's questioning loop can convert the spec into an initiative when discovery finds several features, so the subject is planned instead of forced into one spec.
  - **success:** After conversion, `.workflow/initiatives/NNN-slug/` exists with status `exploring`, the spec's design log and codebase map, and an Origin entry naming the spec; the spec folder is gone and the resume offer no longer lists it.
- **CAP-NEW-initiative-exploration** Explore an initiative across sessions
  - **intent:** A stakeholder can settle an initiative's questions over several sessions, with research done by agents and decisions made in rounds, while what is known, unknown and decided stays on disk.
  - **success:** A session can end with a research question in state `researching`; the next session resumes the initiative, writes the answer back into `questions.md`, and its next round asks only the frontier.
- **CAP-NEW-slice-emission** Emit a slice as a spec
  - **intent:** A stakeholder can emit a settled slice as an ordinary spec that carries its initiative as origin, so it runs the light or full path like any other spec.
  - **success:** Emission creates `.workflow/specs/NNN-slug/` through discovery 0.1 with `initiative:` in its frontmatter, a Why drafted from the slice and an Origin entry carrying the binding decisions; the initiative's reference table links it; the session stays in the initiative unless an open question depends on the new spec.
- **CAP-NEW-initiative-close** Offer, route and close an initiative
  - **intent:** The system offers in-flight initiatives at session start, routes a request that names one to the large path, and moves a planned initiative to `done` once every emitted spec is done.
  - **success:** The session-start offer lists an `exploring` initiative from its branch and a `planned` one with unstarted specs; resuming a `planned` initiative whose emitted specs are all `done` moves it to `done` through the initiative status script and merges that change into main the same way `planned` was merged.

## Constraints

- Same stack only: bash 3.2 without bash 4 constructs, mikefarah yq v4, jq, markdown skills, the in-house test harness. No new runtime, library or vendored skill.
- Initiative status and its `.step` marker change only through one script with the spec single writer's exit-code contract; sub-agents never write initiative files.
- Node ids stay inside the step-list lint: `6.x` on a `large` track, with `tests/lint/step-list.sh`, its pins and the two PLAN flow docs changed in the same commit as `references/steps.tsv`.
- The spec-side guards, validators and templates admit the `initiative:` key without rejecting existing specs.
- The large path plans only: no code is built inside an initiative.
- Initiative files are committed only on `initiative/NNN-slug` and reach main only through a PR/MR, at `planned` and at `done`; they never sit on a spec branch, so the spec size budget and the Tier A gate are untouched.
- `task_review` governs the initiative branch as it governs task branches: `pr` and `pr-blocking` push at every commit point and open the PR/MR at `planned` and `done`; `local` never pushes and merges the branch into main locally with `--no-ff`. The PR/MR is opened by the generic mode of `open-task-pr.sh`, never by a second copy of the host switch.

## Non-goals

- Cross-spec delivery: driving an initiative's emitted specs to done in dependency order.
- Filing initiatives or specs in a tracker through gh or glab.
- Prototype tickets inside exploration.
- Renaming the full path.
- An intake gate for large requests (D2): every request starts as a spec.
- Guarding or warning on `depends_on` between emitted specs (D18): the order is informational.
- A spec-count bound on an initiative (D8).
- Changes to the handoff skill or to project-setup: `.workflow/initiatives/` is created lazily by the large path.
- A shared path normaliser replacing the per-script copies: shelved to [.workflow/deferred/shared-path-normaliser.md](../../deferred/shared-path-normaliser.md).
- Scoping sign-off's final commit so untracked draft folders are not swept in: shelved to [.workflow/deferred/sign-off-scoped-commit.md](../../deferred/sign-off-scoped-commit.md).

## Success signal

A stakeholder can take a draft spec whose questioning loop found several features, convert it into an initiative on its own branch, explore its questions across sessions with research left pending between them, emit each settled slice as an ordinary spec linked back to the initiative, see the initiative offered at session start, and watch it close on its next resume once every emitted spec is done. The harness proves each of these in a fixture repo (JRN-001 to JRN-008 in [verification-plan.md](verification-plan.md)), and `tests/run-all.sh` passes with the `large` track in the step list.

## Assumptions

- The `research` task type gets its model in a target project through the existing 00.14 flow at first launch, so project-setup assets need no change; this repo records it in `.workflow/model-map/research.md`.
- Static files that carry literal `.workflow/specs` paths (the Claude settings template permission line, the Codex config comment, `.gitignore`) are extended by hand for `.workflow/initiatives/*/.step`, as the lib header requires.
- `wayfinder-comparison.html` is scaffold-only and is not updated by this spec.
- At conversion every reference to the deleted spec is re-pointed to the initiative: `superseded_by` and `origin_spec` on shelf items, `promoted_to` on a work item, and the `Spec:` line of the moved design log.
- Switching to an initiative branch needs a clean working tree, as switching to a spec branch does today; an emitted spec folder stays uncommitted in the working tree until its own branch exists, as a draft spec does today.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
- Placement ADR: none; the placement fails the three-part test and is recorded as D1 in [design-log.md](design-log.md)
