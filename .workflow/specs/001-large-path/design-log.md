# Design log: Large path: planning a large subject into several specs

Spec: [spec.md](spec.md)

## 2026-10-21 Term gate 0.2.2

- Terms agreed and written to `.workflow/GLOSSARY.md` at 0.2.3: **Large path**, **Initiative**; "medium path" folded into **Full path** `_Avoid_`. Flagged ambiguities record the "medium path" and "map" resolutions.
- Boundary agreed: route unknown and multi-session, a spec found to be several features mid-discovery, and a grown deferred item route to the large path; a large but well-understood change stays on the full path.

## 2026-10-21 Placement: feature-workflow

- Owning module: feature-workflow (`.agents/skills/feature-workflow/**`)
- Alternatives considered: a new standalone skill under `.agents/skills/initiative/`: keeps feature-workflow's step counts and lint pins untouched, but the router, the spec template and the resume hook change either way, so two modules would co-own one route.
- Secondary touches outside the owning module: lib (one path constant in `workflow-paths.sh`, shared core, through the integration agent), hooks (resume offer, write guards), agents, tests, root-docs; the exact set is settled in the questioning loop.
- Conflict with an ADR or rule: none. ADR-0001 (workflow lives once in host-neutral `.agents/`, hooks are adapters over skill scripts, all state is files in git) is conformed to; no new `may_depend_on` edge is needed for feature-workflow.
- ADR three-part test: hard to reverse (moderate), a real trade-off (yes), surprising without context (no). Fails the test; recorded here, no ADR.
- Decision: **D1** The large path is owned by feature-workflow as new module file(s), scripts, assets and a third track in `references/steps.tsv`; other modules receive secondary edits only.

## 2026-10-21 Deeper prompt

**Ask:** Let the workflow take on a subject too large or too uncertain for one spec: plan it as an initiative across sessions, keep what is known, unknown and decided on disk, and hand each settled slice to the existing light or full path as its own spec. The large path plans; it never builds.

**Goals:**
- A stakeholder can start an initiative from a large or uncertain request, and the router sends it to the large path instead of forcing one spec.
- An initiative survives sessions: a later session resumes it where it stopped from its record on disk, and the session-start resume offer lists it.
- Uncertainty is first-class: an initiative holds open questions and research across rounds, with facts found by agents and decisions made by the stakeholder, without the "Open Questions must be empty" rule that closes a spec.
- The initiative emits ordered specs with dependencies between them; each enters the existing workflow as a normal spec that carries its initiative as its origin.
- A spec found to be several features mid-discovery, or a grown deferred item, converts into or seeds an initiative without losing its record.

**Downstream:** cross-spec delivery (a later feature drives an initiative's specs through to done in dependency order) and tracker visibility (initiatives and specs filed as epics or issues through gh or glab). The design leaves room by giving initiative records a spec order, dependencies and stable ids a tracker can reference.

**Tools and technologies:** same stack only (bash 3.2, yq v4, jq, markdown skills, the in-house harness). Wayfinder's model (destination, decision tickets, fog, slices) is design input, not vendored.

**Gotchas:** step-list lint pins. The per-phase counts in `references/steps.tsv` are pinned by `tests/lint/step-list.sh` and tied to `PLAN/decision-flow-reference.md` and `PLAN/decision-flow.mermaid`, so a third track changes all three in step.

**Not asked for:** driving emitted specs to done, filing tracker items, prototype tickets, renaming the full path, routing large-but-clear work (it stays on the full path with the size budget).

**Original request:** "Looking at the wayfinder-comparison.html We don't really do well with large, multi spec planning with how our current workflow is set up. We have a light path, a medium path, but I think we should also support a large path that will spit out multiple specs and handle a lot of uncertainty, planning, and exploration across a large subject."

Revisions: agreed as first restated.
