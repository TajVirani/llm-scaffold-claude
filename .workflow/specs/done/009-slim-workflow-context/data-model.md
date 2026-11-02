# Data model: Slim the workflow context

Spec: [spec.md](spec.md) · Placement: feature-workflow

## Summary

No stored data or schema changes. The parts below are the interfaces between the router, step files, scripts and tests, classified in the 2026-11-01 Impact classification in [design-log.md](design-log.md).

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Route table, step-file load contract and 0.0.3 sizing rule (`SKILL.md`) | interface | refactor | feature-workflow |
| Discovery 0.2.1 read of `rules.md` (module names and `owns` paths only) | interface | refactor (D22) | feature-workflow |
| `SKILL.md` frontmatter `modules:` and `progressive_loading:` keys | field | refactor (removed, D14) | feature-workflow |
| `references/conventions.md` | interface | create | feature-workflow |
| `references/launching.md` | interface | create | feature-workflow |
| Discovery step files (`discovery.md`, `discovery-impact.md`) | interface | refactor | feature-workflow |
| Implementation step files (`implementation-setup.md`, `implementation-waves.md`, `implementation-finish.md`) | interface | refactor | feature-workflow |
| `implementation-shared-core.md` (3.2), `implementation-gates.md` (3.4–3.8 with result routing, D25) | interface | create | feature-workflow |
| `small-path.md` and its "On the small path:" notes in the owning step files | interface | refactor (file removed, D17) | feature-workflow |
| Questioning-loop Entry seed table | interface | extend | feature-workflow |
| Proven-first escalation rule (`discovered-work.md`, pointers elsewhere) | interface | refactor (one home, D23) | feature-workflow |
| large-path.md Conventions | interface | refactor | feature-workflow |
| Term-list script (list with aliases; `--define <term>`) | interface | create | domain-modeling |
| Output-style vocabulary rule | interface | refactor | output-styles |
| Link lint suite `tests/lint/md-links.sh` | interface | create | tests |
| Size-check suite and its load sets | interface | create | tests |
| `status-transition.sh`, `step-progress.sh`, `steps.tsv`, step ids, `check-write.sh` constants, write guards, `session-start-resume.sh` | interface | unchanged | feature-workflow, hooks |

## Entities

### Route table row (refactor)

One row of the router's Route by status table: a status and `.step` condition that names one step file and its resume node.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| status | spec status | yes | one of the six statuses (CAP-NEW-lean-workflow-load) | unchanged |
| condition | `.step` range or task-record test | yes | every step id in `steps.tsv` routes to exactly one step file | refactor |
| step file | relative link under `modules/` | yes | resolves (link lint, D8) | refactor |
| resume at | step id | yes | a step the named step file holds | refactor |

**Invalid states ruled out:** a step id routed to a step file that does not hold it is caught by JRN-003, which walks every step id in `steps.tsv` against the step files. A `small_path: true` spec no longer loads a second file beside its step file (D17), so "step file plus overlay" is no longer a state. Still representable: a step file loaded by an in-session "Then load" link without the conventions, accepted because the router loads the conventions first (D7).

### Load set (create)

The files a session has read at one load point, as the size check counts them (D15, D19, D21).

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| load point | `new-feature start` or `implementation resume` | yes | one of the two | create |
| files | list of repo-relative paths | yes | new-feature start: `AGENTS.md`, `SKILL.md`, `references/conventions.md`, `modules/discovery.md`; implementation resume: `AGENTS.md`, `SKILL.md`, `references/conventions.md`, `modules/implementation-waves.md` | create |
| generated output | byte count | yes | the session-start hook output from a fixture with one in-flight spec and no handoffs (both points); the term-list output (new-feature start only) | create |
| limit | bytes | yes | 45,000 for a new-feature start, 55,000 for an implementation resume (KB as 1,000 bytes, the unit the 81 KB and 85 KB baselines use); the suite fails above it | create |

**Invalid states ruled out:** a small-path start has no load set of its own, because it loads the same files as any new-feature start (D17). Still representable: a busier repo's hook output exceeds the fixture's (spec.md Assumptions), accepted as known.

### Term list line (create)

One line the term-list script prints per glossary entry.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| term | string | yes | the text between `**` and `**:` on an entry line (GLOSSARY-FORMAT.md) | create |
| aliases | comma list | no | the `_Avoid_:` line of the same entry (D5) | create |
| context | string | no | the context name from `GLOSSARY-MAP.md`, present only with a map (D12) | create |

## Migrations

None.
