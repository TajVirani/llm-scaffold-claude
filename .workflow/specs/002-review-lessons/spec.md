---
status: in-progress # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "7289fbf78919ba022f59aa336370e2fca50806bf" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/002-review-lessons # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "726149960fd8e7cd78c6337baf6c5543f3e0e39c" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/retrospective-template-drift.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
budget: {max_tasks: 10, max_changed_files: 30} # written at 2.5 from .workflow/rules.md "Size budget" (D11); raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Review lessons: a Phase 4 lens for retrospective lessons

## Why

Lessons a retrospective records at 5.7 reach the Phase 4 review only after a human rewrites them as a rule or a profile line, and even then only as a generic standards check. The three review lenses read a fixed input list that never includes `.workflow/decisions/pitfalls.md` or `.workflow/decisions/retrospectives/`, and the retrospective routes every lesson to an action item that waits for a human. So a lesson such as "we shipped the same race condition in the queue worker twice" sits in `pitfalls.md` until someone rewrites it. This feature lets those lessons reach the review of every later feature directly: the retrospective writes a stakeholder-approved review lesson to `.workflow/review-lessons.md` at 5.7, and a fourth, read-only, cheap-tier review lens checks each change since `baseline_revision` against the recorded lessons, pitfalls and retrospectives, returning findings in the `review-findings` block triage already validates. It matters now because the scaffold runs the workflow on itself and its own retrospectives are starting to accumulate lessons that nothing checks at review time.

## Capabilities

- **CAP-NEW-review-lessons-lens** Review lessons lens
  - **intent:** The Phase 4 review can check every change against the project's recorded review lessons, pitfalls and retrospectives, so a lesson reaches review without a human rewriting it as a rule.
  - **success:** In a fixture repo with one recorded lesson, a diff that repeats it yields exactly one high-severity `RL-` finding from the lens and the same diff without the repeat yields none; the block passes the triage yq checks and is graded and routed with no triage code change.
- **CAP-NEW-review-lessons-record** Review lessons written by the retrospective
  - **intent:** The retrospective can record a stakeholder-approved "watch for X in Y" lesson directly as a review lesson at 5.7, and retire one that a rule, lint or profile line now enforces.
  - **success:** An approved lesson appears as one entry in `.workflow/review-lessons.md` and nothing else changes; a rejected lesson writes nothing; the Tier A guard allows the write at 5.7 and denies it at every other step.

## Constraints

- The lens returns the same `review-findings` block as the other lenses, with ids `RL-<n>`; triage changes only by adding the fourth prefix and waiting for four lenses, so its validation, confidence filter and routing stay as they are.
- The lens is read-only and runs on the cheap tier; it never writes the lessons file. Only the retrospective writes that file, at 5.7, under the per-entry approval it already uses for pitfalls, and it creates the file from the project-setup template when it is missing. A missing file reads as an empty list in the lens.
- A repeated review lesson is a high-severity finding; a repeated pitfall or retrospective lesson with no review-lesson entry is a medium-severity finding that suggests recording it as a review lesson.
- `.workflow/review-lessons.md` is one fenced YAML `lessons:` list; each entry has `id` (`RL-001`, zero-padded, never reused), `symptom`, `paths` (repo-relative globs in the Ownership-block syntax), `origin_spec` and `date`; validated with mikefarah yq v4. Bash 3.2, jq and yq only.
- The lens launch is step `4.9`, placed in run order right after 4.3; 4.4-4.8 keep their ids and the Phase 4 count becomes 9 on both paths.
- `.agents/lib/workflow-paths.sh` is shared core: its one new path variable goes through the integration agent.
- Every new first-party asset is listed in `.agents/install-manifest.txt` and `PROVENANCE.md`; the Codex toml is generated by `generate-codex-agents.sh`, never hand-written; the agent frontmatter is exactly `name`, `description`, `tools`.

## Non-goals

- Changing the inputs of `review-standards`, `review-end-state` or `review-targets`.
- Auto-writing rules or profile checklist lines: lessons that belong there keep the proposal path.
- Changing `pr-quality`.
- Inventing lessons: the fixture lesson used by the harness and the live run is the only lesson text this feature writes, and only inside fixtures.
- Retrieval reading the lessons file at discovery.
- Fixing the retrospective template's two stale notes (its Tier A list and the agent-overrides path): shelved as [.workflow/deferred/retrospective-template-drift.md](../../deferred/retrospective-template-drift.md).
- Creating this repo's own `.workflow/review-lessons.md`: it appears at this spec's 5.7 if a lesson is approved.

## Success signal

A retrospective's approved lesson is one entry in `.workflow/review-lessons.md`, written at 5.7 and nowhere else, and the next feature's Phase 4 review runs four lenses, the fourth returning exactly one high finding when the change repeats that lesson and none when it does not.

## Assumptions

- Lesson findings carry `category: lesson` and a `lesson:` field holding the lesson id; the triage yq checks ignore extra fields.
- The Codex task name for the lens is `s<NNN>_review_lessons`.
- The model-map entry copies the cheap-tier aliases of the existing entries (claude `haiku`, codex `gpt-6-luna`).
- No `upstream-lineage.json` entry is needed: the lens is first-party, modelled on the first-party lenses, and the lineage lint requires none.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
- Placement ADR: [.workflow/decisions/adr/0002-review-lessons-placement.md](../../decisions/adr/0002-review-lessons-placement.md)
