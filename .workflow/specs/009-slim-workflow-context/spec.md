---
status: ready-for-dev # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "a29eca7c475544a99ccc9d986cde87e02f4f140d" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "spec/009-slim-workflow-context" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/cache-scope-paths.md, .workflow/deferred/in-review-hand-off.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
# initiative: NNN-slug               # optional; the initiative this spec was emitted from, present only on an emitted spec
budget: {max_tasks: 10, max_changed_files: 75}   # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Slim the workflow context

## Why

Starting the feature workflow uses about 10% of the context window before any work is done: on `main` at 7a9b852 a new feature loads about 81 KB (89 KB on the small path) and an implementation resume about 85 KB, much of it text the current step never uses (the Modules table, Codex host notes, launch rules, the loop-back table, the whole glossary, the `rules.md` blocks, the small-path overlay, the parts of discovery and the implementation orchestrator that belong to other steps). The same conventions are also written twice, in SKILL.md and large-path.md, so they can drift apart. The goal is that a session loads only the instructions the current step needs, so its context goes to the work, while the workflow behaves exactly as it does today. Later work (clear-and-resume offers, a step-file size cap, slimming other skills) will build on this, so the step-file layout and the term-list script must be reusable outside feature-workflow.

## Capabilities

- **CAP-NEW-lean-workflow-load** Load only the instructions the current step needs
  - **intent:** A session running the feature workflow loads the **Router**, the **Workflow conventions** and the one **Step file** its step needs, plus the **Term list** instead of the whole glossary, so its context is spent on the work.
  - **success:** Measured with `wc -c`, hook output included, a new-feature start (small path included) loads at most 45 KB and an implementation resume at most 55 KB (D15, D21), and a test suite fails above either (D19); every rule lives in one file; every relative link and anchor under `.agents/` resolves; `tests/run-all.sh` passes.

## Constraints

- Behaviour is unchanged: every route, step id, status transition, guard and script works as before, and every existing test passes, re-pointed where it names a moved file or section ([design-log.md](design-log.md), Deeper prompt).
- Every rule has one home; nothing is copied into several step files (D2, D10).
- No new dependencies: byte counts with `wc`, checks in in-house bash (codebase-map.md, Library options).
- Bash 3.2 for any script; the term-list script lives in domain-modeling and the output style references no script (D1).
- `feature-workflow/modules/` keeps its name (D1).
- 3.9 and 3.13 stay in the waves step file, because they run after every wave (D13); 3.2 and the per-task gates 3.4–3.8 with their result routing get their own step files (D16, D25).
- 0.2.1 reads only module names and `owns` paths from `rules.md`; the full Ownership block loads at 0.3.3 and Shared core at 0.3.20 and review (D22).
- `small-path.md` is folded into the step files it changes, with "Leave the small path" in the questioning loop; no overlay file loads beside a step file (D17, D24).
- The proven-first review-escalation rule lives once, in `discovered-work.md`; review-triage keeps its Phase 4 triage steps and points to it (D23).
- The unread `modules:` and `progressive_loading:` frontmatter keys are removed from the router (D14).

## Non-goals

- Clear-and-resume offers at phase changes.
- Renaming `modules/` or other skills' folders.
- Slimming skills other than feature-workflow.
- Switching domain-modeling term gates or large-path 6.6 to the term list (D11).
- Validating cache scope paths in publishing and the stamp check ([cache-scope-paths](../../deferred/cache-scope-paths.md)).
- Running the hand-off on the 3.14 routes to review ([in-review-hand-off](../../deferred/in-review-hand-off.md)).

## Success signal

A new feature starts with at most 45 KB of workflow text loaded and an implementation resume with at most 55 KB, down from about 81 KB and 85 KB on `main` at 7a9b852, and the full test suite, including the new link lint and the size check, passes. Detail: [verification-plan.md](verification-plan.md).

## Assumptions

- New step-file names: `discovery.md` keeps the before-the-loop half and `discovery-impact.md` takes the after-the-loop half; the orchestrator becomes `implementation-setup.md` (3.1), `implementation-waves.md` (wave loop with 3.9 and 3.13, resume, rework), `implementation-shared-core.md` (3.2), `implementation-gates.md` (3.4–3.8 and result routing) and `implementation-finish.md` (3.10–3.11, 3.14, hand off); the conventions file is `references/conventions.md`. The term-list script is `.agents/skills/domain-modeling/scripts/term-list.sh`; the size-check suite is `tests/lint/workflow-load-size.sh` and prints one `<load point>: <n> bytes (limit <m>)` line per load point.
- The size check's hook output comes from a fixture with one in-flight spec and no handoffs (D21); a busier repo loads a little more than the check counts.
- The output style's inline term-list command reads only the root `.workflow/GLOSSARY.md`; map support lives in the script (D1, D12).
- Rework from 4.7 routes to the waves step file, and an `in-progress` resume with `impl_base_revision` set loads the waves step file instead of setup (D13). So that behaviour stays the same, waves' On resume sends the session to the setup step file first when a task has a null `work_type`, and 3.13 looks up which suites exist itself.
- KB in the targets means 1,000 bytes, the unit of the 81 KB and 85 KB baselines.
- The audit's unassigned rules get these homes: Size budget, Never grow the spec mid-build and the Codex write-guard row go to the conventions file; the resume-offer row to the router; the question-rounds row to the questioning loop; the other-skills row to the conventions file.
- The merged sub-agent write rule keeps both scopes: inside a spec a sub-agent writes only its own result file; inside an initiative it writes nothing. The progress-line rule keeps both call forms (`--spec-dir` and the bare `<6.x>`).
- Script and asset headers that name a moved step file are re-pointed as part of this change.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
