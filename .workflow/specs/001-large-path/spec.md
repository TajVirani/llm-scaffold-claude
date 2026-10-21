---
status: draft # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
# budget: {max_tasks: 10, max_changed_files: 30}   # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Large path: planning a large subject into several specs

## Why

The workflow sizes every request as a trivial edit, a light path or a full path, and both paths assume the route to the result can be settled inside one spec's discovery: one owning module, one capability, one orchestrator, and a questioning loop that must empty Open Questions before the spec is final. A large subject does not fit that shape. Its route is unknown at intake, it needs research and exploration spread over several sessions, and once understood it decomposes into several specs that depend on one another. Today a stakeholder with such a subject must either force it into one oversized spec, which the size budget then halts, or chart it by hand outside the workflow; the wayfinder comparison page concedes this and points at Wayfinder for "long, uncertain, multi-session efforts". This feature adds a large path: a planning route that takes a large, uncertain subject, explores and settles it across sessions while keeping a record of what is still unknown, and emits several ordered specs that each run through the existing light or full path. It matters now because the scaffold has started to run the workflow on itself and its first real changes are exactly this shape.

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
- Placement ADR: [.workflow/decisions/adr/NNNN-slug.md](../../decisions/adr/NNNN-slug.md)

## Known gaps

<!-- Three uses. Light path: a gate skipped because a suite is missing, recorded at 3.14 and flagged again in report.md at 5.4. Sign-off: findings still open when a spec blocked at 4.7 resumes at 5.1. Never reported as a pass. -->

- <Gate skipped (3.9 tests and CI, or 3.10 browser suite)>: <which suite is missing>. Handoff: [.workflow/deferred/<slug>.md](../../deferred/<slug>.md)
- <Open finding F<n> (5.1)>: <one line, severity>. Handoff: [.workflow/deferred/<slug>.md](../../deferred/<slug>.md) or design-log.md triage entry
