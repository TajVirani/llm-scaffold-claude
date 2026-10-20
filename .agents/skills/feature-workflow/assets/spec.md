---
status: draft                       # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: ""               # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: ""                     # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: ""              # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false                   # true once the 0.3.20 light-path test passes
followup_review_recommended: false  # true when triage recommends another review pass after this one
deferred: []                        # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from (D69); the item is deleted after discovery
# budget: {max_tasks: 10, max_changed_files: 30}   # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---
<!--
File: Template for .workflow/specs/NNN-slug/spec.md, the feature map and the one file to open first. Copied by modules/discovery.md at 0.1.4 with status `draft`.
Sources: body sections (Why; Capabilities with intent + success; Constraints; Non-goals; Success signal; optional Assumptions and Open Questions) adapted from bmad-code-org/BMAD-METHOD skills/bmad-spec/assets/spec-template.md (MIT, Copyright (c) 2025 BMad Code, LLC); status states and `baseline_revision` meaning adapted from the same repo's skills/bmad-build/plan-template.md and step-03-implement.md (MIT). Frontmatter fields, Links and Known gaps: PLAN/decision-flow-reference.md "Per-feature files" and "Status"; assetlist D16, D21, D22, D29.

Frontmatter contract (read with mikefarah yq v4, `--front-matter=extract`; D38). status-transition.sh, session-start-resume.sh and check-write.sh depend on these keys:
  - status: one of
      draft          set at 0.1.4   folder exists, spec is being discovered
      ready-for-dev  set at 0.6 or 0.3.20   discovery complete enough to implement
      in-progress    set at 3.1     implementation underway
      in-review      set when 3.11 passes, or at 3.14 on a light path without suites
      done           set at 5.7     approved, retrospective recorded, merged
      blocked        any halt       cannot safely continue without a human; blocked_condition says why
    `blocked` is a routing signal (unresolvable intent gap; rework ceiling hit at 4.7 with high-severity findings open; a harness that cannot fail a known-bad build at 1.4; a work type with no profile and no human at 00.18). There is no project-wide status file (D22).
  - baseline_revision: the commit the work starts from: the spec branch's first commit (D85). Captured before the first code change (1.1 on the full path, 3.1 on the light path) and kept on resume. The Phase 4 review diff is taken against it.
  - spec_branch: string, `spec/NNN-slug` (D85). Created off the main branch and written at 1.1 (0.3.20 on the light path); every task branch forks from it and merges back into it, and sign-off 5.8 merges it into main through a PR. "" until created.
  - impl_base_revision: string, the full SHA of the spec-branch tip at 3.1 (D85): the Phase 1 commit plus the committed breakdown on the full path, the first commit on the light path. The 3.15 size budget counts only files changed since it (and in the PR/MR against `main_branch`, tests excluded; D87), so Phase 1 harness and suite files count only when Phase 3 changes them again. "" until 3.1, then never overwritten.
  - light_path: boolean.
  - followup_review_recommended: boolean, default false.
  - deferred: list of strings, repo-relative paths under .workflow/deferred/ (0.3.17, 3.14, 4.8). Empty list when none.
  - origin: optional string, the filename of the .workflow/specs/work-backlog/ item this spec was seeded from. Set at 0.1.4 when seeded from a backlog item; the item is deleted at 0.6 (0.3.20 on the light path) after its content is carried into this spec (D69). Convention: the spec body opens its Why with a line "Origin: <work-item filename>, <one-phrase problem>."
  - budget: optional map `{max_tasks: int, max_changed_files: int}` (D58). Absent (the shipped template leaves it commented out) until 2.5 (0.3.20 on the light path) writes it; until then the rules.md fallback applies. The defaults come from the `## Size budget` block of .workflow/rules.md. 2.6 checks the task count, 3.15 the changed-file count. An approved overrun raises it for this spec only (00.29).
  - blocked_condition: string. Present only while status is `blocked`; status-transition.sh adds it on entering `blocked` and removes it on leaving. Discovered-work and size-budget halts (00.21) use `discovered work: <slug>` and `size budget: <what>`.
  Add no other keys. Status changes go only through status-transition.sh, never by hand.

Writing rules:
  - Single writer: the main session writes this file only at 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9 and 00.29 (spec-single-writer-guard checks the .step marker; D16). Sub-agents never write it. `status` and `blocked_condition` change only through status-transition.sh, whatever the step.
  - Links, never copies: support detail lives in the linked files. Each fact has one home.
  - Capability IDs: a capability that already exists in .workflow/capabilities.md keeps its ID (0.3.1). A new one gets a provisional ID scoped to this spec, `CAP-NEW-<slug>` (lowercase kebab-case, unique within the spec, e.g. CAP-NEW-guest-checkout). At sign-off 5.3 the approved proposal assigns the next real CAP-### in .workflow/capabilities.md, and every reference in this spec's files (spec.md, tasks.md, verification-plan.md, proposals.md, report.md) is rewritten to it (D44).
  - Optional sections (Assumptions, Open Questions, Known gaps) are deleted when empty. Every other section stays.
  - Delete this comment in the finished file.

Validate the frontmatter (prints true, exits non-zero otherwise):
  yq --front-matter=extract -e '
    (.status | test("^(draft|ready-for-dev|in-progress|in-review|done|blocked)$")) and
    ((.baseline_revision | tag) == "!!str") and
    (((.spec_branch // "") | tag) == "!!str") and
    (((.impl_base_revision // "") | tag) == "!!str") and
    ((.light_path | tag) == "!!bool") and
    ((.followup_review_recommended | tag) == "!!bool") and
    ((.deferred | tag) == "!!seq") and
    (((.origin // "") | tag) == "!!str") and
    (((.budget // null) == null) or (((.budget.max_tasks | tag) == "!!int") and ((.budget.max_changed_files | tag) == "!!int"))) and
    ((.status == "blocked") == ((.blocked_condition // "") != ""))
  ' .workflow/specs/NNN-slug/spec.md
-->

# <Feature title>

## Why

<One paragraph: the goal. Name the force behind the work (a pain to solve, an opportunity, a vision, or a mandate), who is affected, and why it matters now. Drafted at 0.1.6, confirmed or revised at 0.3.19. Every later trade-off resolves against this paragraph.>

## Capabilities

- **CAP-### or CAP-NEW-<slug>** <short name>
  - **intent:** <One sentence: user or system can do X to achieve Y. What, not how.>
  - **success:** <A criterion a test or a real demonstration can decide.>

## Constraints

- <A non-negotiable that rules out some design. If it rules nothing out, delete it.>

## Non-goals

- <An explicit out-of-scope item. At least one. Work that is shelved rather than refused goes to .workflow/deferred/ and is listed in the `deferred` frontmatter.>

## Success signal

<One or two sentences describing the moment the world has changed, concrete enough to test or demonstrate. The testable objectives and journeys that prove it live in verification-plan.md (0.5.1).>

## Assumptions

- <A call made without direct confirmation from the stakeholder.>

## Open Questions

- <A gap that needs a human decision, phrased so a human can answer it. Must be empty before 0.6 sets ready-for-dev.>

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
- Placement ADR: [.workflow/decisions/adr/NNNN-slug.md](../../docs/decisions/adr/NNNN-slug.md)

## Known gaps

<!-- Three uses. Light path (D29, D60): a gate skipped because a suite is missing, recorded at 3.14 and flagged again in report.md at 5.4. Sign-off (D47): findings still open when a spec blocked at 4.7 resumes at 5.1. Never reported as a pass. -->

- <Gate skipped (3.9 tests and CI, or 3.10 browser suite)>: <which suite is missing>. Handoff: [.workflow/deferred/<slug>.md](../../deferred/<slug>.md)
- <Open finding F<n> (5.1)>: <one line, severity>. Handoff: [.workflow/deferred/<slug>.md](../../deferred/<slug>.md) or design-log.md triage entry
