# Decision Flow Reference

Companion to `decision-flow.mermaid`. Every node in that diagram is numbered; every number has an entry here saying what it is, what it is responsible for, and what it is *not*. Where an idea was taken from another project, the entry says so and the Sources section says where to find the original prompts and code.

**Decisions applied.** This document and the diagram are reconciled with decisions D1–D84 in [`assetlist.md`](../assetlist.md#decisions), which is the authority on asset names, paths and mechanisms. Where the two disagree, `assetlist.md` wins and this file is the one to fix. Decision numbers are cited inline as (D#). `PLAN/` is a scaffold-only design doc: `install.sh` leaves it out of the payload copied into target projects (D30). Shared vocabulary lives in `GLOSSARY.md`.

## Sources

Several parts of this flow are adapted from other projects. When building the workflow, go to the originals for their prompts, templates and configuration rather than reconstructing them from these notes. These are inspirations and reference material only, not runtime dependencies: no first-party skill, agent or hook calls a vendored skill at runtime (D10). The vendored copies under `.agents/skills/` are deleted once a first-party version exists or the skill is dropped (D77, D78); go to the upstream repos at the commits pinned in `upstream-lineage.json`.

| Source | What we took | Where to find it |
| --- | --- | --- |
| **BMad Method** — docs at https://docs.bmad-method.org/, code and skill prompts at https://github.com/bmad-code-org/BMAD-METHOD | The trivial-edit bypass (0.0.1); the three-fact light-path test (0.3.20); the five spec fields, stable capability IDs, and single-writer rule (0.1.4); spec frontmatter status states and *blocked* as a routing signal (Status section); finding-level triage with verify → severity → dismiss-with-reason (4.4); the patch / defer / decision-needed routing (4.5); the third-pass heuristic (4.6); the rework ceiling of five (4.7); the retrospective (5.7); the two-tier project-context model and its tests for what earns a line (Tier A / Tier B section). | Relevant pages: *Build a Change*, *Review a Change*, *Autonomous Development Loops*, *Define Requirements and a Specification*, *Finish an Epic*, *The Theory of Project Context*, *Set and Maintain Project Context*. Skill prompts live in the repo under the skill folders; the review lenses are configured in `_bmad/custom/bmad-code-review.toml`. |
| **Spec Kit** (GitHub) — https://github.com/github/spec-kit | `.workflow/specs/NNN-slug/` numbering and slug derivation (0.1.1, 0.1.2); `data-model.md` as a named artifact (0.4.5); the analyse-before-implement idea behind 0.6. | Command prompts under `templates/commands/`. Spec Kit ships no `data-model` template: its shape (entities, fields, relationships, validation rules, state transitions) is in Phase 1 of `templates/commands/plan.md`. A local copy of the `speckit-*` commands is in the claude-night-market spec-kit plugin (`commands/speckit-plan.md`). Per-item sources for every §4 build item are in `PLAN/sourcing.md`. |
| **Matt Pocock's skills** — https://github.com/mattpocock/skills | The questioning loop (0.3.8–0.3.13, from *grilling*); `GLOSSARY.md` as glossary-only and the three-part ADR test (00.1, 0.3.5–0.3.7, from *domain-modeling*); out-of-scope handling and the HITL/AFK distinction (0.3.16–0.3.17 and `.workflow/deferred/`, from *wayfinder*); the two-axis review and Fowler smell baseline (4.1–4.2, from *code-review*); agreed test seams and vertical slices (2.1, 2.3, from *tdd*); the module/interface/seam/adapter vocabulary (from *codebase-design*). | Upstream, at the commits pinned in `upstream-lineage.json`; the vendored reference copies were deleted (D78). *domain-modeling* is not vendored: the first-party `domain-modeling` skill is adapted from it, with its formats in `domain-modeling/assets/` (D10). The `implementation` agent carries its own TDD method rather than calling *tdd* (D10). *codebase-design* in turn credits Michael Feathers (seams) and John Ousterhout (deep modules). |
| **PROJECT_BRIEF.md** (this project) | Verification loop before the game (Phase 1, 3.12); one builder per module, waves by dependency, a single integrator for core (3.1–3.2); never inflate, report real numbers (4.7, 5.4); resume from recorded state (5.6). | In this project's files. |
| **anti-slop** — https://github.com/dmmulroy/anti-slop | The principle behind 3.5: reject low-evidence code mechanically before any agent reviews it. The vendored Oxlint rule set is the starting point for the TypeScript/JavaScript toolchain in every profile that touches TS/JS; `no-module-mocking` also enforces our test-seam discipline (2.3) as a lint rule. | Vendored, not an npm dependency: copy `src/` into the repo (the README suggests `.workflow/tools/oxlint/anti-slop/`) and register it in `oxlint.config.ts`. Upstream ships an install skill (`install-anti-slop`); in this workflow the install is a step inside `project-setup`, not a runtime call to that skill (D10); `project-setup` fetches the rules from `dmmulroy/anti-slop` at a pinned commit at setup time rather than bundling them (D42). The rules are meant to be read and edited to match the team's standards; each profile's toolchain section names which rules are on. |
| **Diagram.md** (this project) | The original stage spine. | In this project's files. |

Our own contributions, not taken from elsewhere: the placement-before-requirements gate (0.3.3); the three inline term gates (0.2.2, 0.3.14, 0.4.2); the `.workflow/deferred/` folder with one file per item, back-links and archival (00.8–00.10); the defer-to-deep-dive option (0.3.12–0.3.13); the browser-suite gate and known-bad-build test for both suites (1.3–1.4, 3.10–3.11); the model-selection map, launch resolution and pre-launch validation (00.11–00.14); work profiles injected by work type, with a tool audit and then a profile-specific mini-review (00.16–00.20, 3.5–3.8); `spec.md` as feature map written at four points; commit-stamped caches as the answer to documentation staleness (Tier B).

## Build inventory

Everything the flow needs to exist before it can run: files, templates, sub-agent task types, hooks, and processes that live outside the flow. Node numbers point back to the diagram. Names and paths follow `assetlist.md`: scaffold assets live in `.agents/` (skills, agents, hooks, scripts and templates), and the files below are created in the target project. Change a path there first, then everywhere.

### Persistent files (`.workflow/` in the target project, shared by every feature)

All workflow data lives under one committed folder, `.workflow/` (D81). Paths below are relative to the target project root. Only `e2e/` (the app's browser tests) stays at root, plus root tool configs that tools require there (for example `.oxlintrc.json`, `playwright.config.ts`), which point into `.workflow/tools/`.

| Path | Node | Tier | Written by | Notes |
| --- | --- | --- | --- | --- |
| `.workflow/GLOSSARY.md` | 00.1 | A | 0.2.3, 0.3.15, 0.4.3 inline | Glossary only. Format in `domain-modeling/assets/GLOSSARY-FORMAT.md` (adapted from Matt Pocock's `CONTEXT-FORMAT.md`; D10). |
| `.workflow/capabilities.md` | 00.2 | A | 5.3 | One entry per capability, stable ID (`CAP-###`), user-facing description, link to the spec that introduced it. Specs in flight use provisional `CAP-NEW-<slug>` IDs; 5.3 assigns the real number and rewrites the spec's references (D44). |
| `.workflow/rules.md` | 00.3 | A | 5.3 | Sections: ownership and boundaries, shared-core definition, cross-cutting policy, external systems, required versions, and a `## Size budget` fenced `yaml` block holding the project defaults `max_tasks` and `max_changed_files` (D58; defaults `max_tasks: 10` and `max_changed_files: 30`). Prohibitions name the permitted alternative. The Ownership and Shared core sections are **structured**: a fenced `yaml` block under each fixed heading (module → owned paths → allowed dependencies; D15), because project setup generates the import-boundary tool's config from them; prose in those two sections is commentary, not source. The rules are tool-neutral (D20). |
| `.workflow/decisions/adr/NNNN-slug.md` | 00.4 | A | 0.3.7 | ADR format in `domain-modeling/assets/ADR-FORMAT.md`, template `adr.md` (D10). Superseded ADRs stay, marked. |
| `.workflow/decisions/pitfalls.md` | 00.4 | A | 5.7 | Observed failures only. Each entry: what happened, where, the spec it happened in, the rule or check that now prevents it (if any). |
| `.workflow/decisions/retrospectives/NNN-slug.md` | 00.4 | A | 5.7 | One per shipped feature, written by the `retrospective` skill (D25). Combined-result judgement plus process lessons and action items. There is no `.workflow/decisions/status.md` (D22). |
| `.workflow/cache/modules.md` | 00.5 | B | 0.2.8, `regenerate-caches` | Frontmatter: `generated_at_commit`, `generated_at`, `scope` (paths covered). Body is generated. Only `publish-cache.sh` puts files here (D17). |
| `.workflow/cache/flows.md` | 00.6 | B | same | Same frontmatter. Mermaid sequence or flow diagrams per traced path. Entry points (routes, CLI mains, handlers) are discovered by `cache-regeneration` on each run; there is no config block (D64). |
| `.workflow/cache/architecture.md` | 00.7 | B | same | Same frontmatter. Module dependency graph. |
| `.workflow/.cache-staging/<type>.md` (gitignored, outside `.workflow/cache/`) | 00.5–00.7 | — | `cache-regeneration` | Where the agent writes a regenerated cache before `publish-cache.sh` stamps it and moves it into `.workflow/cache/` (D17). The path is `.workflow/.cache-staging/<type>.md`, gitignored by `install.sh`. |
| `.workflow/tools/boundaries/` | 00.3 | — | `generate-boundary-config.sh` | Generated import-boundary config, one file per language adapter (dependency-cruiser for TS/JS first; D20). Derived from `rules.md`, never hand-edited. |
| `.workflow/deferred/slug.md` | 00.8 | — | 0.3.17, 4.8, 3.14, 5.9 (a work-backlog item moved to the shelf, D57) | Written through the `deferred-handoff` module (D24). Frontmatter: `origin_spec`, `created`, `severity` (for review findings). Body: goal, background, constraints, decisions already made, evidence. |
| `.workflow/deferred/archive/slug.md` | 00.10 | — | 00.9 | Same file with `superseded_by: .workflow/specs/NNN-slug` prepended. |
| `.workflow/specs/work-backlog/<NNN-slug>-disc-<###>.md` | 00.27 | — | 00.26 (create); 5.9 (`moved-to-deferred`); the new spec's 0.1.4 (`promoted`, D69); deleted when that new spec finishes discovery (0.6 Yes or a 0.3.20 pass, D69). Main session only; sub-agents denied (D16 pattern) | Discovered-work backlog (D57): one small work item per discovery that is not a blocker and that the user wants as a next feature. Lives in a project-level folder under `.workflow/specs/`, named by its origin spec, but outside the origin spec's folder, because that spec will not solve it. `###` increments per origin spec. Template `feature-workflow/assets/work-item.md`: origin spec and step, problem, evidence, why it is not a blocker, suggested scope and size, `status: open \| promoted \| moved-to-deferred \| dismissed`, links. A started item's content is preserved in the new spec (`origin:` frontmatter and a `design-log.md` Origin entry) before the file is deleted, so no stale docs remain (D69). Not the `.workflow/deferred/` shelf (00.8), which holds out-of-scope work decided during discovery or review. |
| `.workflow/agent-overrides.yaml` | 00.11 | — | project setup (empty, commented), a human, 5.7 | Project-owned model overrides per agent type per host, e.g. `implementation: {claude: <alias>, codex: <model>}`. Models only, no other fields. Highest precedence (D35). `install.sh` never touches it. |
| `.workflow/model-map/<task-type>.md` | 00.11 | — | project setup, 00.14, 5.7 | Lowest-precedence model source: used for a host only when neither `.workflow/agent-overrides.yaml` nor the agent definition gives one (D35). Project-owned; `install.sh` never touches it. Frontmatter: `tier` (cheap or strong) and a host model alias for Claude and for Codex, never a dated version ID (D23); optional `fallback`. Body: why this model for this task type. One per task type in the table below (D12). |
| `.workflow/profiles/TEMPLATE.md` | 00.16 | — | project setup | Fixed sections: File locations, Approved libraries per concern, Language and style rules, Toolchain (one fenced `yaml` block: `lint`, `typecheck`, `format`, `boundary`, `test` (D61) and `e2e` hold commands; `serve` and `serve_ready` (D62) hold the start command and the URL to poll, which `run-toolchain.sh` never runs; D15), Mini-review checklist (only what the toolchain cannot express). The section headings are the contract 00.20, 3.5 and 3.7 depend on. |
| `.workflow/profiles/<work-type>.md` | 00.17 | A | project setup, 00.19, 5.3 | One per work type. Follows the template exactly. The scaffold ships filled examples (`test-harness`, `e2e-browser`) marked "adapt before use" (D26). |

### Per-feature files (`.workflow/specs/NNN-slug/`)

| Path | Node | Written at | Frontmatter |
| --- | --- | --- | --- |
| `spec.md` | 0.1.4 | 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29 (0.1.4 creates it, with `origin:` when seeded from a backlog item, D69; 0.3.17 and 4.8 `deferred[]`; 1.1 or 3.1 `baseline_revision`, D53; 1.1, or 0.3.20 on the light path, `spec_branch`, and 3.1 `impl_base_revision`, D85; 2.5, or 0.3.20 on the light path, `budget`, D58; 3.14 suite gap; 4.6 `followup_review_recommended`, D54; 5.3 real capability IDs, D52; 5.9 `deferred[]` when an item moves to the shelf; 00.29 a raised budget after an approved overrun, D58); `status` and `blocked_condition` only via `status-transition.sh` | `status`, `baseline_revision`, `spec_branch`, `impl_base_revision` (D85), `followup_review_recommended`, `deferred[]`, `blocked_condition` (when blocked; `discovered work: <slug>` or `size budget: <what>` from the D56 protocol), `light_path: true/false`, `budget: {max_tasks, max_changed_files}` (D58), `origin:` (the backlog item it was started from, D69) |
| `.step` (gitignored) | — | every guarded step, by `status-transition.sh` | Not frontmatter: the current step, a timestamp and, while the spec is `blocked`, `blocked_from` (the node that blocked, so resume knows where to return); read by the write guards (D16). Lives only in the main checkout; scripts find it with `git rev-parse --git-common-dir` (D18). |
| `codebase-map.md` | 0.2.6 | 0.2.4, 0.2.5, 0.2.8, 0.4.6 | `cache_stamps` (the commits of the caches it was drawn from) |
| `design-log.md` | 0.3.21 | every round, 0.3.4, 0.3.17, 0.3.22 (the agreed Deeper prompt entry; D73), 0.4.4, 4.4, 5.7, and a discovered-work entry for every 00.22–00.29 ruling (blocker or not, discovery or not, next feature or ignored, split, re-scope or overrun with its reason; D56, D58), with Outcome `loop back (00.24 discovered work)` when 00.24 sends it to discovery; 0.1.4 of a spec started from a backlog item writes an Origin entry (D69) | none; append-only body, one dated section per round or event |
| `data-model.md` | 0.4.5 | 0.4.4 | none |
| `verification-plan.md` | 0.5.4 | 0.5.1–0.5.3 | none; sections: end state, journeys (each with `JRN-###` ID), fixtures and oracles, targets (from 1.1) |
| `tasks.md` | 2.5 | Created at 2.5, or as a one-task file at 0.3.20 on the light path (D14); afterwards only `status-transition.sh set-task` writes task records, at 3.1 (`work_type`), 3.3, 3.9, 3.11, 3.16 (also `--pr`, D85), 4.7 (rework), 5.3 (`--capability`, D52) and 00.29 (`split-out`) (D45, D59, D68) | The task index: a `tasks:` YAML array (D15); per task: `id`, `status`, `work_type`, `depends_on[]`, `touches_core`, `capability` (the `CAP-###` it serves), and (D85) `file`, `branch`, `predicted_files[]`, `size: {files, est_lines, points}`, `mode`, `parallel_with[]`, `pr`; body: waves table and Mermaid graph only. Every feature has one (D14). |
| `tasks/T<nn>-<slug>.md` | 2.5 | 2.5, or `T01` at 0.3.20 on the light path; never edited afterwards (D85) | One file per task, numbered in dependency order: what to build, seam, acceptance criteria, predicted files, size, mode, notes. No frontmatter. The implementer reads its own file from its task worktree. |
| `proposals.md` | 5.2 | 5.2, 5.3 | One line per proposed Tier A or profile change, each with an approval status (D21) |
| `report.md` | 5.4 | 5.4 | none; real test output, metrics, known gaps (including any D29 suite gap), evidence links (D21) |
| `artifacts/` | 3.12 | 3.5, 3.10 | directory; screenshots, traces, console and network logs per run, named by run and journey ID (`evidence-capture`); tool-audit output per task from 3.5 in `artifacts/<task-id>/` (`run-toolchain.sh`) |

### Templates to author

Each of the following needs a template before the flow can produce it consistently. Templates live in the `assets/` folder of the skill that owns them, not in the project's `docs/` (D8); all of them are authored, at the paths below under `.agents/skills/`.

- `feature-workflow/assets/`: `spec.md`, `codebase-map.md`, `design-log.md`, `data-model.md`, `verification-plan.md`, `tasks.md` (D15), `task.md` (one per task under `tasks/`, D85), `deferred.md` (for `.workflow/deferred/*.md`), `proposals.md` and `report.md` (D21), `work-item.md` (for `.workflow/specs/work-backlog/*.md`, D57).
- `domain-modeling/assets/`: `adr.md`, `ADR-FORMAT.md`, `GLOSSARY-FORMAT.md` (D10).
- `retrospective/assets/`: `retrospective.md`, for `.workflow/decisions/retrospectives/*.md` (D25).
- `project-setup/assets/`: `model-map/TEMPLATE.md` (D12), `agent-overrides.yaml` (D35), `profiles/TEMPLATE.md`, `profiles/examples/test-harness.md` and `e2e-browser.md` (D26), `GLOSSARY.md`, `rules.md`, `capabilities.md`, `decisions/pitfalls.md`; setup copies them into `.workflow/` (D81). No `status.md` (D22).
- `regenerate-caches/assets/`: `cache-frontmatter.md`, the Tier B cache frontmatter schema.

### Sub-agent task types

Each row is one agent definition at `.agents/agents/<name>.md` (D1), one entry in `.workflow/model-map/` (D12) and one launch prompt to write. A definition may pin per-host models in its frontmatter as `models: {claude: <alias>, codex: <model>}`. Claude Code does not read `models:` natively, so the `pre-launch` hook applies the Claude value. The model is resolved by precedence: `.workflow/agent-overrides.yaml`[type][host] > the agent definition's `models.<host>` > `.workflow/model-map/<type>.md` for the host > none, which blocks the launch at 00.14 (D35). Definitions are scaffold-owned and overwritten on reinstall; project choices go in `.workflow/agent-overrides.yaml`. "Receives" is the whole of the sub-agent's context beyond the task itself; anything not listed does not go in. "Default tier" is what `project-setup` seeds (D23).

| Task type | Node(s) | Default tier | Purpose | Receives | Returns | Does not receive |
| --- | --- | --- | --- | --- | --- | --- |
| `retrieval` | 0.2.4 | cheap | Pull the sections of Tier A, Tier B and `.workflow/deferred/` relevant to the affected area | Affected area, agreed terms | Extracts with source paths, into `codebase-map.md` | The full corpus in main context; the model map |
| `library-evaluation` | 0.2.5 | cheap | Assess third-party options for the affected concerns | Affected area, `rules.md` external-systems section | Options with cost, licence, fit | Anything else |
| `cache-regeneration` | 0.2.8; also launched by `regenerate-caches` (D4) | strong | Derive a Tier B cache from code | Scope (paths), cache type, current commit | The regenerated cache, written to the staging path; `publish-cache.sh` stamps and publishes it (D17) | Tier A; the previous cache (regenerate, don't patch) |
| `fact-lookup` | 0.3.10 | cheap | Answer a factual question from code or docs so it need not be asked | The question, affected area | The fact with its source, or "not determinable from the repo" | The stakeholder conversation |
| `module-audit` | 0.4.6 | strong | Deep read of the owning module for reuse, gaps, constraints | Owning module path, `codebase-map.md` | Additions to `codebase-map.md` | Other modules |
| `implementation` | 3.3, and 1.2/1.3 under test profiles | strong | Write failing test, then code, for one task in one module, in its own git worktree (D18), following the TDD method in its own prompt (D10) | Task, profile prepended to the launch by the `pre-launch` hook (00.20, D33), the interfaces under test (2.3), relevant `codebase-map.md` extract, the readable-code baseline (D86) | The diff, test results, any "profile is wrong" report | Other tasks; other modules; the model map; the rest of the spec folder |
| `integration` | 3.2 | strong | Apply core-change requests between batches | Core-change requests, the profile for the batch's one work type (D28), `rules.md` shared-core section, the readable-code baseline (D86) | The diff to core | Individual task context |
| `profile-mini-review` | 3.7 | cheap | Check one task's diff against the profile checklist items that no tool covers | The diff, the profile's checklist section, the readable-code check lines (`feature-workflow/references/readable-code.md`, D86), the tool output from 3.5 | Pass, or failed checklist items with locations | The rest of the profile; the spec; other tasks. Does not re-run or re-derive anything the toolchain already reported |
| `review-standards` | 4.1 | strong | Standards, rules, profile and architecture conformance across the whole change | The full diff, `rules.md`, the profiles for the work types touched, the placement ADR, `GLOSSARY.md`, documented coding standards, the readable-code baseline (D86), the Fowler smell baseline, the tool output from 3.5 | Findings with location and claimed consequence | The other lenses' output; `spec.md`. Does not re-lint |
| `review-end-state` | 4.2 | strong | Does the change do what the spec says, and nothing it doesn't | The full diff, `spec.md`, `verification-plan.md`, `artifacts/` | Findings: missing, unasked-for, wrong | The other lenses' output; standards |
| `review-targets` | 4.3 | cheap | Measure against 1.1's targets: start the build with the profile's `serve` command, wait for `serve_ready`, measure, stop it (D62) | The build, the profile's `serve` and `serve_ready`, the targets | Measured numbers vs targets | Judgement calls; the other lenses |
| `standards-discovery` | outside the flow: launched by `project-standards` (D80) | strong | Read-only brownfield scan of what the code already does, so standards ratify it | Scope (paths), candidate work types, instruction files, `since_commit` on refresh, optional focus | Scope, Modules (observed imports, proposed owns and may_depend_on), Conventions (category, frequency, file:line, confidence, enforce_by), Versions, Contradictions, Unknowns, Discovered work | The human interview; write access |

Every launch prompt starts with a header block (D13): a fenced YAML block on the prompt's first line, opened with ```` ```yaml launch-header ```` and closed with ```` ``` ````, holding `task_type` plus the fields below (D37). The `pre-launch` hook prepends the profile after this block, so the block stays first. Each task type declares which header fields it requires, and the `pre-launch` hook denies a launch missing any of them (D31, D33). Fields a type does not require are left out. `resolve-launch.sh` owns this table and the hook reuses it.

| Task type | Required header fields | Why |
| --- | --- | --- |
| `implementation` | `spec_dir`, `task_id`; `work_type` optional | One task under one profile; `work_type` is optional, looked up from the task record in `tasks.md`; a mismatch is denied. Phase 1 launches (1.2, 1.3) have no task record yet, so they carry `spec_dir` and an explicit `work_type` with no `task_id` — the one marked exception (D14). |
| `integration` | `spec_dir`, `work_type` | A batch, not a task: no `task_id`. Each batch touches one work type, so it carries exactly one profile (D28). |
| `profile-mini-review` | `spec_dir`, `task_id`; `work_type` optional | Reviews one task's diff under that task's profile; `work_type` is optional, looked up from `tasks.md` (a mismatch is denied), and selects the checklist section. |
| `retrieval`, `library-evaluation`, `fact-lookup`, `module-audit` | `spec_dir` | Phase 0 launches: no tasks or work types exist yet. |
| `review-standards`, `review-end-state`, `review-targets` | `spec_dir` | Phase 4 lenses see the whole change, not one task or one profile. |
| `cache-regeneration` | `spec_dir` at 0.2.8; none for bulk `regenerate-caches` runs | Bulk regeneration runs outside any feature. |
| `standards-discovery` | none; a header, when present, holds `task_type` only | `project-standards` runs outside any feature, so there is no `spec_dir` (D80). |

Sub-agents do not launch sub-agents in v1, so the nested-launch step 00.15 is removed (D13, D32).

The orchestrator (3.1), the triage step (4.4) and everything in Phase 0 that is not marked as a sub-agent run in the main session.

### Hooks

Hooks are the parts of the flow that must happen without anyone remembering. Event names, payload fields and matchers below were verified on Claude Code 2.1.300 by live tests (`PLAN/hook-verification.md`); re-run its checks after upgrades. Each is a Bash script in `.agents/hooks/` and a thin Claude Code adapter: it reads the event JSON, calls a host-neutral shared script that holds the rule (D9), and translates the exit code into the host's decision format. Hooks take worktree-sensitive paths from the payload `cwd`, not `$CLAUDE_PROJECT_DIR` (D18). On Codex, events that a live Codex verification run shows behave like Claude's are wired in `.codex/hooks.json` to the same adapters; for the rest the phase modules call the same scripts directly and enforcement is advisory (D9, D40). Verified on Codex 0.155.1 (`PLAN/hook-verification-codex.md`; D66, D67):
  - Matchers are full-match regexes: `.*spawn_agent` for launches, `apply_patch` for writes, and `Bash`.
  - Hooks use the payload `cwd`, because Codex sets no project-dir variable.
  - The spawn `message` is encrypted. It cannot be read or rewritten, so profile injection on Codex works differently. The orchestrator builds the full launch message itself through `resolve-launch.sh`; that is the only Codex path (a SubagentStart profile backstop was considered and is not built; D67).
  - The generated `.codex/agents/*.toml` never carry `model`, because a toml `model` would override the spawn-time model. `resolve-launch.sh` resolves the model by D35 precedence (`.workflow/agent-overrides.yaml` > definition `models.codex` > `.workflow/model-map/`), and the orchestrator passes it at spawn.
  - The audit hook finds its task from the plaintext spawn `task_name`, read as `payload.agent_path` (`/root/<task_name>`) from the first `session_meta` line of SubagentStop's `agent_transcript_path` (verified against saved 0.155.1 rollouts), so the Codex audit blocks on toolchain failure as on Claude (D66). Codex accepts only `[a-z0-9_]` in it, with no `/`, so the orchestrator sets it to `s<NNN>_t<N>`, `s<NNN>_integration_<enc(wt)>` or `s<NNN>_phase_1_<enc(wt)>`, where `enc` lowercases and maps every character outside `[a-z0-9]` to `_` (D66). It spawns with `fork_turns: "none"` so the spawn model applies (D67).
  - A permissions profile with `extends = ":workspace"` and a `read` entry for `.workflow/cache` is a real hard limit on Codex, covering shell writes too. The `.workflow/specs/*/.step` glob was rejected by Codex 0.155.1, so `.step` protection is advisory only on Codex (D67). The write guards match `Write|Edit|NotebookEdit` (there is no `MultiEdit` tool), and any one deny wins over allows. They deny a write when the payload carries `agent_id`, which only calls made inside a sub-agent carry (D16). They are accident prevention only, because Bash writes bypass Write/Edit hooks. The hard limits are the permission deny rules `Edit(.workflow/cache/**)` and `Edit(.workflow/specs/*/.step)` (the step marker); Tier A and `spec.md` are written at approved steps, so no deny rule can protect them (D16, D36). Worktree-isolated sub-agents fire project hooks with the worktree as payload `cwd` (D18). The wiring and the deny rule live in `.agents/hooks/claude-settings.template.json`, which `install.sh` merges into the target's `.claude/settings.json` (D11, D36).

| Hook | Fires on | Does | Nodes |
| --- | --- | --- | --- |
| Pre-launch (`pre-launch.sh`) | Before any sub-agent launch (PreToolUse, matcher `Agent`) | Reads `tool_input` (`description`, `prompt`, `subagent_type`, `run_in_background`; `model` and `isolation` only when set), takes the ```` ```yaml launch-header ```` block from the start of `prompt` (D37), and calls `resolve-launch.sh` for the task type in `subagent_type` (a header `task_type` that disagrees is denied). Denies a launch missing a header field its task type requires (D31), a task type with no model for this host at any precedence level (surfacing 00.14), or a coding launch (`implementation`, `integration`, `profile-mini-review`) with no profile (surfacing 00.19). Otherwise returns `updatedInput`: the full input with the profile prepended to `prompt` (whole for `implementation` and `integration`; checklist section only for `profile-mini-review`) and `model` set to the resolved value: `.workflow/agent-overrides.yaml`[type][host] > the agent definition's `models.<host>` > `.workflow/model-map/<type>.md` for the host > none, which blocks the launch at 00.14 (D35). The input is always sent complete, because Claude Code validates `updatedInput` and denies invalid input. Replaces the earlier model-selection, profile-injection and validate-only hooks and the SubagentStart backstop, whose payload carries no prompt (D13, D33). | 00.11–00.14, 00.18–00.20 |
| Post-implementation audit (`post-implementation-audit.sh`) | When an `implementation` sub-agent tries to stop (SubagentStop, matcher `implementation`; the script also filters) | Finds the task by parsing the D37 launch header from the first user message in the payload's `agent_transcript_path`, because the SubagentStop payload carries no prompt (D39). Runs the profile's toolchain (3.5) through `run-toolchain.sh` in the task's worktree. If the toolchain fails, blocks the stop and returns the tool output, so the implementer keeps fixing in the same context. The hook blocks the stop only on toolchain failures, and gives up after 3 identical failure digests (`audit.json` outcome `gave-up`). It allows the stop with a warning when the launch header is missing or malformed, the transcript is unreadable, or `run-toolchain.sh` reports a config or environment error. The warning is a `systemMessage` plus `artifacts/<task-id>/audit.json` with outcome `warning`, or a line in `artifacts/audit-warnings.jsonl` when no task id is known (D55). If clean, saves the output to `artifacts/` and lets the stop through; the orchestrator then launches `profile-mini-review` (3.7) with it attached, because a hook cannot launch an agent (D19). Neither step can be skipped. | 3.5–3.8 |
| `spec.md` single-writer guard (`spec-single-writer-guard.sh`) | Before any Write/Edit to `.workflow/specs/*/spec.md`, `.workflow/specs/*/tasks.md`, `.workflow/specs/*/.step` or `.workflow/specs/work-backlog/**` (PreToolUse, matcher `Write\|Edit\|NotebookEdit`) | Through `check-write.sh`: allows the write only when `.step` names one of the spec.md writer nodes (0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29); writes to `.workflow/specs/*/tasks.md` only at 2.5 or 0.3.20, and otherwise points at `status-transition.sh set-task` (D45); denies every file-tool write to `.workflow/specs/*/.step`, which only `status-transition.sh` writes (D16, D36); writes under `.workflow/specs/work-backlog/` only at 00.26, 5.9 or a new spec's 0.1.4 (D57, D69); status changes go only through `status-transition.sh`. Denies writes whose payload carries `agent_id` (sub-agent calls; D16). Otherwise blocks and explains. | 0.1.4 |
| Tier A write guard (`tier-a-write-guard.sh`) | Before any Write/Edit to any `GLOSSARY.md` or `GLOSSARY-MAP.md` at any depth (D46), `.workflow/capabilities.md`, `.workflow/rules.md`, `.workflow/decisions/`, `.workflow/profiles/` (PreToolUse, matcher `Write\|Edit\|NotebookEdit`) | Through `check-write.sh`: allows glossary writes (`GLOSSARY.md`, `GLOSSARY-MAP.md`) only when `.step` names a term gate's agree-definition node (0.2.3, 0.3.15, 0.4.3) or 5.3; other Tier A writes only at 0.3.7 (which also covers a supersede decided at 0.3.6), 5.3 or 5.7; a new profile also at 00.19 (D50, D51). With no feature in flight (no `.workflow/specs/*/spec.md` whose status is not `done`), every Tier A write from the main session is allowed without a step, which `project-setup`, standalone `domain-modeling` and a standalone `retrospective` rely on (D51). Denies writes whose payload carries `agent_id` (D16). Everything else is redirected to a 5.2 proposal in `proposals.md` (D21). | Tier A |
| Tier B write guard (`tier-b-write-guard.sh`) | Before any Write/Edit under `.workflow/cache/` (PreToolUse, matcher `Write\|Edit\|NotebookEdit`) | Through `check-write.sh`: blocks every Write/Edit there, from any writer, so it never needs to know who is writing. `cache-regeneration` writes to the staging path and `publish-cache.sh` stamps and moves the cache in (D17). Hand edits are blocked with a pointer to the `regenerate-caches` skill. | Tier B |
| Rules → boundary config sync (`rules-boundary-config-sync.sh`) | After any approved Write/Edit to `.workflow/rules.md` (PostToolUse, matcher `Write\|Edit\|NotebookEdit`, acting only on `.workflow/rules.md`, which only 5.3 can write) | Re-runs `generate-boundary-config.sh`, which regenerates the import-boundary config in `.workflow/tools/boundaries/` from the Ownership and Shared core YAML blocks (D15, D20), so the tool enforces the rules as approved rather than as they were at setup. Fails the write if the blocks do not parse. | 00.3, 3.5 |
| Evidence capture (`evidence-capture.sh`) | After any browser-suite run (PostToolUse and PostToolUseFailure, matcher `Bash` each; a Bash call that exits non-zero fires only PostToolUseFailure on Claude Code 2.1.303, and a failing run is the one whose evidence matters most). Acts only on a command that starts with the `e2e` command from the `e2e-browser` profile or the default `npx playwright test`, or that runs `run-toolchain.sh --e2e`; a `--list` run never matches | Copies screenshots, traces, console and network logs into `.workflow/specs/NNN-slug/artifacts/`, named by run and journey ID. | 3.10, 3.12 |
| Session start (`session-start-resume.sh`) | When a session opens in a repo that has `.workflow/specs/` (SessionStart) | On every SessionStart source, scans the `.workflow/specs/*/spec.md` frontmatter and lists every spec that is not `done` (`draft`, `ready-for-dev`, `in-progress`, `in-review`, `blocked`; there is no `status.md`, D22), and offers to resume at the phase the status names, through `feature-workflow`. | 5.6 |

`.agents/hooks/` also holds `block-destructive-git.sh` and the statusline script `context-bridge.cjs` (first-party and shipped as the target's `statusLine`, D79). Neither is part of this flow.

### Helper scripts

These are called by the phase skills and by the hook adapters; they are not tied to a host event. Each lives in the `scripts/` folder of the skill that owns it (D7). The shared rule scripts are host-neutral (D9). `jq` and `yq` are declared dependencies (D15); `yq` is mikefarah `yq` v4, which reads Markdown frontmatter with `--front-matter=extract` (D38).

| Script | Called | Does | Nodes |
| --- | --- | --- | --- |
| Cache stamp check (`regenerate-caches/scripts/cache-stamp-check.sh`) | By `discovery` before `retrieval` reads any file under `.workflow/cache/`; by `regenerate-caches` for stale-only runs | Compares each cache's `generated_at_commit` against `HEAD` for the paths in `scope` that intersect the affected area. Marks stale caches so 0.2.7 has its answer before retrieval starts. | 0.2.7 |
| Status transition (`feature-workflow/scripts/status-transition.sh`) | At each node that changes state, and in step-only mode before a guarded write | Writes `status` into `spec.md` frontmatter and enforces the legal transitions (see Status). Its `set-task` mode is the only writer of task records in `tasks.md`: task status at 3.3, 3.9, 3.11, 3.16 (`set-task --status done --step 3.16`, the wave merge; refused while the spec is blocked; `--pr <url>` records the task PR/MR, D85) and 4.7, `work_type` at 3.1, `--capability` at 5.3, `split-out` at 00.29 (D45, D52, D59, D68). Spec `blocked` on any halt, including 00.19 when no human can define a missing profile (`status <spec-dir> blocked --step 00.19 --blocked <condition>`). One writer, one place. Also writes the gitignored step marker `.step` that the write guards read (D16). | 0.1.4, 0.6, 0.3.20, 1.4, 2.2, 2.3, 3.1, 3.9, 3.11, 3.14, 3.16, 4.5, 4.6, 4.7, 5.1, 5.3, 5.6, 5.7, 00.19, 00.21, 00.24, 00.28, 00.29 |
| Resolve launch (`feature-workflow/scripts/resolve-launch.sh`) | By the `pre-launch` hook on every Claude launch; by the modules before each launch on Codex (advisory) | Validates the header against the D31 table, resolves the model for the host by precedence (`.workflow/agent-overrides.yaml`[type][host] > the agent definition's `models.<host>` > `.workflow/model-map/<type>.md` for the host > none, which blocks the launch at 00.14 (D35)), and returns it with the profile text (whole, checklist-only or none by task type). Fails with a 00.14 message when no level has a model, or 00.19 when the profile is missing (D13, D33). | 00.11–00.14, 00.18–00.20 |
| Run toolchain (`feature-workflow/scripts/run-toolchain.sh`) | By `post-implementation-audit` on both hosts; by the orchestrator when the audit warns | Runs the profile's Toolchain YAML commands against the task diff in the task's worktree and saves the output to `artifacts/<task-id>/` (D19). | 3.5–3.6 |
| Check write (`feature-workflow/scripts/check-write.sh`) | By the three write-guard hooks; by modules directly on hosts without write hooks | Decides allow or deny from the target path, `.step` and the caller (D9, D16, D17), including `.workflow/specs/*/tasks.md` (main session at 2.5 or 0.3.20 only; afterwards `set-task`, D45), `.workflow/specs/*/.step` (denied always: only `status-transition.sh` writes it; D16, D36) and `.workflow/specs/work-backlog/` (main session at 00.26, 5.9 or a new spec's 0.1.4 only; D57, D69). Tier A writes from the main session are allowed without a step when no feature is in flight (D51). | 0.1.4; Tier A; Tier B |
| Budget check (`feature-workflow/scripts/budget-check.sh`) | By `task-breakdown` at 2.6; by the orchestrator at 3.15, once per wave after the 3.16 merge; by `discovered-work` at 00.29 after an approved overrun | Read-only. Compares the task count in `tasks.md` (excluding `split-out` tasks) and the changed-file count since `impl_base_revision` (D85; excluding the spec folder and `.workflow/specs/work-backlog/`; not counted before it exists), or with `--predicted` at 2.6 the sum of the records' `size.files`, with the spec's `budget`, else the `.workflow/rules.md` `## Size budget` defaults, else 10 / 30. Prints one JSON object; exit 2 when over budget, so the caller runs 00.21 (D58, D68). | 2.6, 3.15, 00.29 |
| Step progress (`feature-workflow/scripts/step-progress.sh`) | By the orchestrator before each phase or step update to the stakeholder, and on resume | Prints the phase progress line for a node id (D84) from `references/steps.tsv`, the path from `spec.md` `light_path`; read-only | all phase nodes |
| Build architecture (`regenerate-caches/scripts/build-architecture.sh`) | By the `cache-regeneration` agent | Derives the generated parts of the Tier B caches from one dependency-cruiser run, deterministically and sorted for a given scope and commit: the whole `architecture.md` body, the `modules.md` skeleton with a purpose slot per module for the agent to fill, or the `flows.md` entry-point candidates as JSON (D4, D64). Refuses to write under `.workflow/cache/`; output goes to `.workflow/.cache-staging/<type>.md`. | 0.2.8 |
| Check staged cache (`regenerate-caches/scripts/check-staged-cache.sh`) | By the `cache-regeneration` agent before it returns; by `regenerate-caches` and `discovery` 0.2.8 before publishing | Checks a staged cache body against the fixed shape for its type, so only canonical bodies reach `publish-cache.sh`; optionally wraps its Mermaid blocks into HTML for `validate_mermaid.mjs`. Exit 1 lists the problems. | 0.2.8 |
| Publish cache (`regenerate-caches/scripts/publish-cache.sh`) | By `regenerate-caches`; by `discovery` after a 0.2.8 launch returns | Stamps a staged cache's frontmatter and moves it into `.workflow/cache/` (D17). | 0.2.8 |
| Generate boundary config (`project-setup/scripts/generate-boundary-config.sh`) | By `project-setup`; by `rules-boundary-config-sync`; by `sign-off` at 5.3 on Codex | Turns the `rules.md` YAML blocks into per-language config in `.workflow/tools/boundaries/` through adapters, dependency-cruiser first (D20). | 00.3, 3.5 |

### Processes outside the flow

| Process | What it does | Depends on | Invoked by |
| --- | --- | --- | --- |
| Install (`install.sh`, scaffold repo root) | Copies the first-party payload named in `.agents/install-manifest.txt` into the target's `.agents/` (D72; vendored skills never ship, D71), writes a version stamp (`.agents/VERSION`) and prunes files a previous install shipped that the manifest no longer names, creates the `.claude/` symlinks, merges `.agents/hooks/claude-settings.template.json` (hook wiring, deny rules, output style) into `.claude/settings.json` (D36), and creates the Codex shim (`.codex/`). Leaves out the scaffold-only docs: `PLAN/`, `assetlist.md`, `organization.md`, `checklist.md` (D11, D30). The shipped files under `.agents/` are scaffold-owned and always overwritten on install and upgrade, agent definitions included. Project-owned files live outside it (`.workflow/agent-overrides.yaml`, `.workflow/model-map/`, `.workflow/`, which holds the project's glossary, rules, profiles, model map, specs and the rest, plus the project's own `docs/`) and are never touched; an existing `.claude/settings.json` is merged, not clobbered (D11, D35). | The scaffold's `.agents/` | A human, once per project and on each scaffold upgrade |
| Project setup (`project-setup` skill) | Creates `.workflow/` (`GLOSSARY.md`, `rules.md`, `capabilities.md`, `decisions/`, `deferred/`, `model-map/`, `profiles/`) from templates (D81); agrees the work types and seeds each profile's Toolchain block; then calls `project-standards` for the standards interview first, before example profiles are offered and before any toolchain is installed (D82); then installs and configures each profile's toolchain (for TS/JS profiles the anti-slop install is a step inside this skill, D10). `project-standards` fills `rules.md`, the rest of each profile, the ADRs (including `0001-project-baseline`), the `.workflow/pr-quality/` checks, per-profile lint config and the managed `AGENTS.md` block through one approval ledger (D80); **generates the import-boundary tool's config from the structured ownership and shared-core blocks in `rules.md`** through `generate-boundary-config.sh` — the rules are the source, the config in `.workflow/tools/boundaries/` is derived and never hand-edited (D20); seeds `.workflow/model-map/` with the tiered default per task type (D23); creates an empty, commented `.workflow/agent-overrides.yaml` (D35) | The templates above | A human, once per project, or when a new work type appears; the config-generation step re-runs automatically on every approved change to `rules.md` (see hooks) |
| Cache regeneration (`regenerate-caches` skill) | Regenerates any or all Tier B caches by launching the `cache-regeneration` agent per scope and cache type, then publishing each through `publish-cache.sh` (D4, D17) | The `cache-regeneration` task type | Schedule, post-merge automation, or a human on demand. Must produce output identical to 0.2.8 for the same scope and commit. |
| Multi-question interface | Presents a numbered round of questions, each with a recommended answer and a defer option, and collects the answers in one turn | The host tool's question UI | 0.3.11 |

The workflow's entry points are skills only, with no command aliases (D27). `feature-workflow` is the router; each phase is a module in its `modules/` folder (D3), with deferred handoffs in the shared `deferred-handoff` module (D24). The `retrospective` skill is standalone but runs inside the flow at 5.7 (D25).

## How to read the diagram

**Node shapes and colours**

| Shape / colour | Meaning |
| --- | --- |
| Rounded, grey | Entry or exit point of the whole flow |
| Rectangle, dark blue | A stage: work done in the main session |
| Rectangle, mid blue | A step: a smaller action inside a stage |
| Rectangle, purple | A sub-agent: a separate context that reads a lot and returns a little |
| Rectangle, grey dashed | A process outside this flow, shown because the flow depends on its output |
| Parallelogram, light blue | An authored document or artifact on disk |
| Parallelogram, pale blue dashed | A generated cache: derived from code, stamped with a commit, never hand-edited |
| Parallelogram, teal | `spec.md`, the feature map and the one file to open first |
| Diamond, orange | A gate: a decision with named exits |

**Numbering**

- `00.x` — persistent artifacts that outlive any single feature, and the shared processes around them (deferred handoff 00.8–00.10, model map 00.11–00.14, profiles 00.16–00.20, discovered work 00.21–00.29).
- `0.0.x` — intake, before a feature folder exists.
- `0.x.y` — Phase 0, substage `x`, node `y`.
- `0.6` — the Phase 0 exit gate.
- `1.x` through `5.x` — Phases 1 to 5.

Numbers identify nodes, not execution order.

**Progress line (D84).** The orchestrator leads every phase or step update to the stakeholder with `Phase <p> of <P> · step <s> of <S> — <phase>: <step> (<id>)`, printed by `feature-workflow/scripts/step-progress.sh` from the ordered list in `feature-workflow/references/steps.tsv`. Display only: node ids and every rule that names one are unchanged. Steps are numbered by run order within each phase (0.3.22 before 0.3.8; 3.16, 3.15 before 3.13, 3.9), and a repeated step keeps its number. Full path: 6 phases of 47, 5, 6, 14, 8 and 9 steps. Light path: 4 phases (0.1.1–0.3.20 = 35, then Phases 3–5 = 15 with 3.14, 8, 9). Not counted: intake 0.0.x (no line), the 00.x nodes (shown after the linear step they were entered from), and the side artifacts 0.3.21 and 3.12.

**Solid vs dotted edges**

Solid edges are flow or a write. Dotted edges are a read or a reference. The eleven dotted edges out of 00.12 mean "this launch happens on the model the `pre-launch` hook resolved through `resolve-launch.sh` and set on the launch"; they fan out to every purple node (D5, D13, D32, D33).

## Design rules the diagram encodes

1. **Use the smallest amount of process that safely fits the change.** *(BMad.)*
2. **Project context has two tiers.** Tier A is authored: what the code cannot say; agent proposes, human approves. Tier B is generated: cached, stamped, never hand-edited, regenerated when stale. *(Adapted from BMad; the stamped-cache mechanism is ours.)*
3. **The corpus never enters main context.** Both tiers are read by a sub-agent that returns extracts. Two exceptions, both deliberate: `GLOSSARY.md` is read whole into the main session because it is needed to interpret the request; a work profile is injected whole into a coding agent because it is that agent's operating instructions. See "Work profiles".
4. **Model choice is looked up, not improvised.** *(Ours.)*
5. **Coding agents get their operating context by work type, not by guesswork.** *(Ours.)*
6. **Tools before agents.** Anything a deterministic tool can check — lint rules, type-check, formatting, import boundaries — is checked by that tool before any agent reviews the code, and no agent re-derives what a tool already reported. When a reviewer keeps catching the same thing by judgement, that is a candidate for a new tool rule, proposed at 5.2. *(Ours; the rule set from anti-slop.)*
7. **Questions are asked in parallel, not one at a time.** *(Matt Pocock, grilling.)*
8. **Facts are the agent's job; decisions are the stakeholder's.** *(Matt Pocock; BMad.)*
9. **Every document has exactly one home for each fact.** Terms in `GLOSSARY.md`; what the system does in the capabilities index; project-wide policy in the rules; work-type conventions in the profiles; rationale, pitfalls and lessons in the decision log; goal, contract and status in `spec.md`; per-feature decisions in `design-log.md`; schema in `data-model.md`; acceptance in `verification-plan.md`; the existing system's shape in the caches.
10. **`spec.md` is a living document with one writer.** *(BMad.)*
11. **A gate has named exits and no dead ends.**
12. **Nothing is claimed that has not been verified.** *(PROJECT_BRIEF.)*
13. **Fix the layer that is wrong.** *(BMad.)*
14. **Phase 0 is re-enterable.**

## Work profiles: the operating context for coding agents

Three of the persistent stores are keyed by "what kind of work is this", and they are easy to confuse. They answer different questions and are read by different parties.

| Store | Question it answers | Who reads it | Enters an agent's context? |
| --- | --- | --- | --- |
| `.workflow/agent-overrides.yaml`, else agent definition `models:`, else `.workflow/model-map/` (00.11) | *Which model* runs this task type | The launcher: the `pre-launch` hook, through `resolve-launch.sh` (D35) | No |
| Rules (00.3) | *What is true project-wide*: ownership, boundaries, cross-cutting policy | The retrieval sub-agent, the review lens, `generate-boundary-config.sh` | As extracts only |
| Profiles (00.17) | *How this kind of work is done here*: where files go, which libraries, which language rules, what the mini-review checks | The `pre-launch` hook, which prepends it to the launch prompt through `resolve-launch.sh` (the orchestrator on Codex) | Yes, in full, into coding agents |

**What a profile is.** One file per work type — `frontend-react`, `backend-api`, `data-migration`, whatever the project actually has — with five sections fixed by the template: file locations (where each kind of artifact lives, and where it must not); approved libraries per concern (server state, forms, validation, dates, and so on, so the agent does not pick its own); language and style rules (strictness settings, banned constructs, naming, error handling); the toolchain (one fenced `yaml` block whose `lint`, `typecheck`, `format`, `boundary`, `test` (D61) and `e2e` hold commands; `serve` and `serve_ready` (D62) hold the start command and the URL to poll, which `run-toolchain.sh` never runs — the commands are exact, with the rule set named — for TS/JS profiles, the vendored anti-slop rules plus the project's own; D15); and the mini-review checklist, which holds *only* what the toolchain cannot express.

**The order of audit is tools, then agent.** When the implementing agent tries to stop, the post-implementation audit runs the toolchain against the diff (3.5). Nothing else happens until it is clean: a failure blocks the stop and hands the tool output back to the same agent (D19). Then 3.7 launches the mini-review agent with the tool output attached, to judge the checklist items that need reading rather than parsing — "is this the right abstraction for this module", "does the error path match how the rest of the domain reports failures". A reviewer that has to re-find what a linter would have found is a wasted launch; a reviewer that only sees what remains is cheap and sharp.

**The checklist should shrink over time.** Every mini-review finding that recurs is a candidate for a tool rule. 5.2 proposes the conversion; once a rule exists, the checklist line is removed. anti-slop is itself an example of this: a set of review judgements about low-evidence TypeScript that someone turned into lint rules so no reviewer has to make them again.

**Where it is configured.** At project setup (`project-setup`), once per work type, from `.workflow/profiles/TEMPLATE.md`; the scaffold ships filled `test-harness` and `e2e-browser` examples to adapt (D26). Setup also installs the toolchain each profile names. The flow assumes the profiles exist and has a gate (00.18) for when a task's work type has none.

**How it is used.** At 3.1 the orchestrator classifies each task by work type — recorded on the task in `tasks.md`. 00.18 checks a profile exists. 00.20 places it, whole, into the launch of the implementing agent (3.3) and of the integration owner (3.2), whose batches are split so each touches one work type and so carries exactly one profile (D28). Then 3.5 runs the toolchain, and 3.7 runs the mini-review on what the tools could not check.

**Why whole, when everything else is extracts.** A profile is small by construction and is exactly the set of constraints the coding agent must operate under. Extracting from it would mean deciding which conventions apply, which is the decision the profile exists to remove. The BMad line-test still applies to its contents: a line stays only if removing it would change what the agent does.

**Why the mini-review runs before CI.** A profile violation is cheap to catch immediately and expensive to catch at Phase 4, where it arrives mixed with real findings. 3.7 checks only the profile's checklist; 4.1 checks it again as one of several baselines with the whole change in view, so the mini-review does not have to be perfect.

**Who changes a profile.** Nobody edits an existing profile mid-feature: profiles are Tier A in nature, proposed at 5.2 and approved at 5.3. The one mid-feature exception is creating a *new* profile at 00.19, in the main session, when a task's work type has none (D50). A coding agent that thinks the profile is wrong reports it; it does not work around it.

**Relationship to the rules.** Rules are project-wide and apply to every task regardless of work type. Profiles are per work type. "No module writes to the audit table directly" is a rule. "React components live under `src/components/<Domain>/`" is a profile line. If a line would appear identically in every profile, it is a rule.

## Project context: Tier A and Tier B

*(Adapted from BMad's "Theory of Project Context". Their evidence: instruction files that restate what the repo already holds showed no improvement in agent success rate and about 20% more inference cost; a document describing a system loses to the source it describes; what is not recoverable from source is intent, rationale, policy, and what was rejected.)*

**The test.** Can the fact be derived from the code? If no, it is Tier A. If yes, it is Tier B: cached because deriving it is expensive, never treated as the truth.

**Tier A: authored, source of truth, small.** `GLOSSARY.md` (00.1), the capabilities index (00.2), the rules (00.3), the decision log (00.4), and — same in kind, kept in its own folder because of how it is consumed — the profiles (00.17). Rules are general and standing; decisions are specific and dated.

**Tier A is agent-proposed, human-approved.** At 5.2 the agent proposes in `proposals.md`; at 5.3 a human approves, modifies or rejects each line (D21). The retrospective (5.7) runs with the stakeholder present so its writes are approved as agreed. The inline term gates write `GLOSSARY.md` directly because the stakeholder is already in the conversation. `tier-a-write-guard` holds writes to these steps (D16).

**Pitfalls: observed failure only.** A pitfall enters the decision log only when something actually went wrong. It is removed only when the thing it is about is gone or is enforced by a tool, never because it hasn't recurred.

**Tier B: generated caches, stamped, never hand-edited.** Module map (00.5), flow diagrams (00.6), architecture structure (00.7). Derived from code by a sub-agent into a staging path, then stamped with the commit and moved into `.workflow/cache/` by `publish-cache.sh`; no Write/Edit lands there directly (D17).

**Staleness is a check, not a judgement.** 0.2.7 compares stamps against `HEAD` for the affected area (`cache-stamp-check.sh`). Mismatch means 0.2.8 regenerates before anything downstream reads.

**Regeneration is a separate process.** Bulk regeneration is its own skill, `regenerate-caches`, outside this flow (D4). 0.2.8 regenerates only what one feature needs. Both launch the same `cache-regeneration` agent and publish through the same script, and must produce identical output for identical input.

**Where we depart from BMad.** They say store nothing derivable. We cache flows and structure anyway, because their studies measured always-loaded derivable context, and a stamped cache behind a targeted sub-agent is a different artifact. Recorded so it can be revisited.

## Status: the state `spec.md` carries in frontmatter

*(Adapted from BMad.)*

| Status | Set at | Meaning |
| --- | --- | --- |
| `draft` | 0.1.4; again on every loop back to 0.3.8 (2.2 No, 2.3 No, 4.5 decision needed, 4.6 Yes, 5.6) (D49), and at 00.24 from `blocked` when discovered work is a blocker and the user sends it to discovery (D56) | Folder exists, spec is being discovered. |
| `ready-for-dev` | 0.6 or 0.3.20 | Discovery complete enough to implement. |
| `in-progress` | 3.1 | Implementation underway. |
| `in-review` | 3.11 passed, or 3.14 on a light path without suites; 5.1 from `blocked` (D47) | Review and triage underway. |
| `done` | 5.7, from `in-review` only (D47) | Approved, retrospective recorded, merged. |
| `blocked` | any halt; 00.21 for discovered work or a crossed size budget (D56, D58) | Cannot safely continue without a human. Carries a blocking condition. |

`blocked` is a routing signal. Conditions include: an unresolvable intent gap; the rework ceiling hit with high-severity findings open (4.7; without high-severity findings the spec stays `in-review` and the rest is deferred at 4.8, D48); a harness that cannot be made to fail a known-bad build (1.4); a task whose work type has no profile and no human available to define one (00.18); discovered work outside the agreed scope, or a crossed size budget, while the D56 protocol runs (00.21). Other fields: `followup_review_recommended`, `deferred`, `baseline_revision`. Task records in `tasks.md` carry status and work type individually.

**Legal spec transitions** (enforced by `status-transition.sh`): `draft` → `ready-for-dev` (0.6, 0.3.20); `ready-for-dev` → `in-progress` (3.1); `in-progress` → `in-review` (3.11, 3.14); `ready-for-dev` or `in-review` → `draft` on a loop back to 0.3.8 (D49). There is no `in-progress` → `draft`: Phase 3 reaches discovery only through the D56 blocker path, `blocked` → `draft` at 00.24; `in-review` → `blocked` (4.7 with high-severity findings open, D48); any status → `blocked` on another halt (1.4, 00.19, 00.21), with `blocked_from` recorded in `.step`; `blocked` → `in-review` at 5.1, with open findings recorded as known gaps (D47); `blocked` → `draft` at 00.24, or at 00.29 on a budget re-scope (D56, D58); `blocked` → the status at `blocked_from` when a human resolves the condition, including 00.28 after the D56 protocol (D56); `in-review` → `done` (5.7).

**Task statuses** (written only by `set-task`, D45): `pending` → `in-progress` when its 3.3 launch starts; `in-progress` → `done` after 3.8 passes and its worktree is merged; `pending` or `in-progress` → `blocked` on a halt, and `blocked` → `pending` or `in-progress` once it is resolved; `done` → `in-progress` only for 4.7 rework or a 3.9/3.11 failure, and `done` → `blocked` at 3.9/3.11 (D59); `pending` → `split-out` (terminal) at 00.29 when a budget split moves the task's work to backlog items, via `set-task --status split-out --step 00.29`. The orchestrator, review and sign-off ignore `split-out` tasks (D68).

Status lives only here and in the task records. Every status change goes through `status-transition.sh`, which also updates the `.step` marker (D16). There is no project-wide `.workflow/decisions/status.md`: `session-start-resume` finds in-flight work by scanning `.workflow/specs/*/spec.md` frontmatter (D22).

## Discovered work: the scope-creep guardrail (00.21–00.29)

*(Ours; D56–D58.)* Work found outside the spec's agreed scope while the feature is under way — a new requirement, a bug found along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer — is never folded into the current tasks or spec. It is detected mostly in Phase 3, also in Phases 1, 2 and 4. Agents (`implementation`, `integration`, the review lenses and `module-audit`) report it, as a `discovered-work` return status or finding kind, and never fix it; the orchestrator or triage runs the protocol in the main session. Out-of-scope items found during Phase 0 framing still go through 0.3.16–0.3.17 to `.workflow/deferred/`.

1. **00.21** sets the spec `blocked` at the current step, with `blocked_condition: "discovered work: <slug>"` (or `"size budget: <what>"` for D58); `blocked_from` goes in `.step`. In Phase 3, tasks already running finish and pass through their gates. The orchestrator starts no new launches until the user answers the 00.22 prompt.
2. **00.22** presents it to the user: what the problem is, the evidence (file:line, a failing test, the agent's return), and the system's assessment — a **blocker** for the current work, or **can be solved later** — with a recommendation.
3. **00.23 Blocker?** Yes → **00.24 Go to discovery to address it?** Yes → `blocked` → `draft`, back to 0.3.8 with the problem as the first frontier. No → the spec stays `blocked`. There is no new route out: a human resolves the condition, and the existing resolve transition at 00.28 returns the spec to `blocked_from`.
4. Not a blocker → **00.25 Tackle it as the next feature?** No → ignore it, with one line in `design-log.md` for traceability. Yes → **00.26** writes a work item to the backlog (**00.27**, `.workflow/specs/work-backlog/<NNN-slug>-disc-<###>.md`; D57).
5. **00.28** unblocks to `blocked_from` and the current work continues unchanged.

Every ruling at 00.22–00.29 gets a discovered-work entry in `design-log.md`. A second report that arrives while the spec is already blocked joins the same 00.22 prompt; it does not start a second block. While the spec is blocked, wave merges (3.16) and the budget check (3.15) wait. At a 00.29 split, the pending tasks whose work moves to backlog items become `split-out` (D68).

A crossed size budget (2.6, 3.15) uses the same 00.21–00.22 block and presentation, then **00.29 Split, re-scope or approve the overrun?** Split → the remaining work becomes backlog items through 00.26, then 00.28. Re-scope → `draft`, back to 0.3.8. Approve → the reason goes in `design-log.md`, the spec's `budget` is raised for this spec only, then 00.28.

**Backlog versus shelf.** `.workflow/deferred/` (00.8–00.10) holds out-of-scope work decided during discovery or review (0.3.17, 4.8). `.workflow/specs/work-backlog/` holds work discovered while building that the user wants as a *next* feature. At sign-off, **5.9** runs after 5.5 approves the work and before 5.7 sets `done`. It offers each `open` item from this spec as the next feature: start it (hand off to a new spec seeded from the item through 0.1), keep it `open`, or move it to `.workflow/deferred/` (`moved-to-deferred`, and `deferred[]` in `spec.md`). 5.9 only offers and hands off. The new spec's 0.1.4 marks the item `promoted` and preserves its content (`origin:` frontmatter plus a `design-log.md` Origin entry), and the item file is deleted when that spec finishes discovery (0.6 Yes, or a 0.3.20 pass) (D69). The current spec never grows to absorb them. Backlog items are written only by the main session, at 00.26, 5.9 and the new spec's 0.1.4; sub-agents are denied (D16 pattern).

## Model selection

Eleven nodes are sub-agent launches: 0.2.4, 0.2.5, 0.2.8, 0.3.10, 0.4.6, 3.2, 3.3, 3.7, 4.1, 4.2, 4.3 (D5). The twelfth task type, `standards-discovery`, is launched outside the flow by `project-standards` and resolves its model the same way (D80). The orchestrator writes each launch with its ```` ```yaml launch-header ```` block (D37) and task. The `pre-launch` hook (00.12) then calls `resolve-launch.sh`, which validates the header and returns the profile text and the model resolved for the host by precedence: `.workflow/agent-overrides.yaml`[type][host] > the agent definition's `models.<host>` > `.workflow/model-map/<type>.md` for the host > none, which blocks the launch at 00.14 (D35). The hook denies a malformed launch or returns it rewritten through `updatedInput`, with the profile prepended and `model` set to the resolved value (D13, D33, D35). On Codex the orchestrator runs `resolve-launch.sh` itself and places both (advisory; D9). Codex has hooks (`.codex/hooks.json`); per D40 the pre-launch rewrite moves onto a Codex hook only if a live verification run shows PreToolUse can rewrite a `spawn_agent` launch (see `.codex/README.md`). Agent definitions pin models per host under `models:`, which Claude Code does not read natively, so the hook applies them. `.workflow/agent-overrides.yaml` is where a project overrides a pinned model, because definitions are overwritten on reinstall (D35). The map says *which model* and nothing else; it never enters the sub-agent's context, because sub-agents do not launch sub-agents in v1 (the nested-launch step 00.15 is removed; D13, D32). Map entries are tiered aliases per host — a cheap tier and a strong tier, seeded by `project-setup` — never dated version IDs (D23). The profile mini-review (3.7) is a distinct task type from the Phase 4 lenses and defaults to the cheap tier. The tool audit (3.5) is not a launch at all — it is a command run.

## The questioning loop

*(Matt Pocock, grilling; defer-to-deep-dive is ours.)* Nodes 0.3.8–0.3.19. Nine gates route back into 0.3.8: 0.4.7, 0.6, 2.2, 2.3, 4.5, 4.6, 5.6, plus the discovered-work gates 00.24 and 00.29. Loop-backs skip 0.3.22, which runs on first entry only (D73). One pass computes the frontier, asks all of it in one round with recommended answers and a defer option, processes the answers, and recomputes or exits.

## Sizing

*(BMad.)* Trivial (0.0.1): no workflow. Light path (0.3.20): three facts clean — intent gaps, irreversible actions, footprint — create the spec branch, write a one-task `tasks.md` and its task file (D14, D85) and go straight to the orchestrator with existing suites. If the harness or the browser suite does not exist yet, the light path still runs: the orchestrator runs whichever suite exists and skips only the gate of the missing one (3.9 or 3.10; D60), records the gap in `spec.md` and `.workflow/deferred/`, and sign-off flags it in the 5.4 report (3.13–3.14; D29). Full path: everything else. Both paths carry a soft size budget (D58): `budget: {max_tasks, max_changed_files}` is written to `spec.md` when `tasks.md` is written (2.5, or 0.3.20 on the light path), from the `## Size budget` defaults in `.workflow/rules.md`. 2.6 checks the task count and the predicted files, 3.15 the changed-file count since `impl_base_revision` after each Phase 3 wave (D85); crossing either runs the discovered-work protocol (00.21).

## The four gates of Phase 3

Phase 3 has four gates in sequence, cheapest first, each catching a class of problem the next would find late and mixed with other findings. **3.6 asks whether the tools object** — lint (anti-slop rules and the project's own), type-check, format, import boundaries; deterministic, seconds to run, no judgement, enforced by the SubagentStop audit before the implementer can finish (D19). **3.8 asks whether the work follows the profile** in the ways only a reader can tell. **3.9 asks whether the code is correct** — unit and integration tests through the profile's `test` command (D61), CI. **3.11 asks whether the feature works** — the browser suite drives the named journeys against the running application. On a light path missing a suite, only that suite's gate is skipped and the gap is recorded, never hidden (D29, D60). A 3.9 or 3.11 failure after a task is `done` reopens it (D59).

## Review: lenses, then triage

*(Lenses from Matt Pocock; triage, routing and the third-pass rule from BMad.)* Independent parallel lenses (4.1–4.3); finding-level triage (4.4); routing to patch / defer / decision needed / none (4.5); third-pass heuristic (4.6); ceiling of five (4.7).

---

## Persistent artifacts (00.x)

### Tier A — authored

**00.1 — `GLOSSARY.md`: canonical terms** *(Matt Pocock)*
Glossary only. Read whole at 0.2.1. Written inline at 0.2.3, 0.3.15, 0.4.3, following `domain-modeling`. Naming baseline for 4.1.

**00.2 — Capabilities index**
What the system does for users, one entry per capability with a stable ID. Read at 0.3.1. Grows at 5.3.

**00.3 — Rules: cross-cutting policy, module ownership and boundaries, external systems, required versions**
Project-wide standing constraints the code cannot express. Read at 0.3.3 (ownership), 2.4 (shared core), 4.1 (conformance). Prohibitions name the permitted alternative. Anything that would appear identically in every profile belongs here instead. The Ownership and Shared core sections are fenced `yaml` blocks (D15), because `generate-boundary-config.sh` generates the import-boundary tool's config in `.workflow/tools/boundaries/` from them and `rules-boundary-config-sync` re-generates it on every approved change (D20) — which means module boundaries are *enforced* at 3.5 rather than reviewed at 4.1. Changed only at 5.3.

**00.4 — Decision log: ADRs, pitfalls, retrospective lessons** *(ADRs from Matt Pocock)*
Rationale. Written at 0.3.7 and 5.7 (by the `retrospective` skill; D25). Read at 0.2.4. Holds no feature status (D22).

### Tier B — generated caches

**00.5 — Module map** · **00.6 — System flow diagrams** · **00.7 — Architecture structure**
Derived from code, stamped with the commit, never hand-edited. Regenerated by 0.2.8 (feature-scoped) or by the `regenerate-caches` skill (bulk), both through the staging path and `publish-cache.sh` (D4, D17).

### Deferred work

**00.8 — `.workflow/deferred/slug.md`** · **00.9 — Mark superseded and archive** · **00.10 — `.workflow/deferred/archive/slug.md`**
One file per shelved item with a back-link to its originating spec; fed into 0.2.4; archived when it gets a spec of its own. Written and archived by the shared `deferred-handoff` module (D24).

### Model map

**00.11 — `.workflow/model-map/task-type.md`** · **00.12 — Pre-launch hook** (resolves, validates and rewrites the launch; D33) · **00.13 — Task type has a model assignment?** (in `.workflow/agent-overrides.yaml`, the agent definition's `models:`, or the map, in that order; D35) · **00.14 — Assign a model** · ~~**00.15 — Will this sub-agent launch sub-agents?**~~ Removed in v1 (D32); reintroduce with nested launches. The map is never passed along (D13).
Which model runs each task type, as a tiered alias per host, when neither `.workflow/agent-overrides.yaml` nor the agent definition gives one (D12, D23, D35). Read only by the launcher: the `pre-launch` hook, through `resolve-launch.sh`. Seeded by `project-setup`, written by a human at 00.14 and by the retrospective at 5.7. When the definition pins a model for that host, 00.14 and 5.7 write an `.workflow/agent-overrides.yaml` entry instead; nothing in a target project edits `.agents/agents/*.md` (D35).

### Work profiles

**00.16 — `.workflow/profiles/TEMPLATE.md`**
The fixed shape every profile follows: file locations, approved libraries per concern, language and style rules, toolchain, mini-review checklist. The template is the contract between project setup and the flow — 00.20 injects whatever the template's sections contain, 3.5 runs whatever the toolchain section names, and 3.7 checks whatever the checklist section says, so the template's structure is what the flow depends on.

**Project setup** *(outside this flow; the `project-setup` skill)*
Fills the template once per work type the project has, starting from the shipped examples where they fit (D26). Runs at project start and whenever a new kind of work appears. Not invoked by any node here; 00.19 is the in-flow fallback when setup missed a work type.

**00.17 — `.workflow/profiles/work-type.md`**
One file per work type. The operating context for every coding agent doing that kind of work. Injected whole (00.20); the source of the toolchain run at 3.5, the baseline for the mini-review (3.7) and one baseline for the standards lens (4.1); read by 2.1 because file-location rules constrain how slices are cut. Tier A in nature: changed only through 5.2–5.3.

**00.18 — Task matches a work profile?**
Checked for each launch by the `pre-launch` hook through `resolve-launch.sh`, using the work type recorded on the task (or passed explicitly in Phase 1; D14). Yes → 00.20. No → 00.19. A task that cannot be classified is itself a finding: either the task is badly cut or a work type is missing from setup.

**00.19 — Human defines the missing profile from the template**
The main session creates the new `.workflow/profiles/<work-type>.md` with the human; this is the only mid-feature profile write, and editing an existing profile stays 5.3-only (D50). The launch waits; the `pre-launch` hook denies a coding launch with no profile. A coding agent launched without a profile is one that picks its own file locations and libraries, which is exactly the outcome profiles exist to prevent. If no human is available, the task goes `blocked`.

**00.20 — Inject the profile into the launch prompt, in full**
The one place a Tier A document enters a sub-agent's context whole. The `pre-launch` hook prepends the text returned by `resolve-launch.sh` to the launch prompt through `updatedInput` (D33); on Codex the orchestrator places it. Goes to 3.3 for every task (including 1.2 and 1.3 under the test profiles), to 3.2 for the one work type its batch touches (D28), and, checklist section only, to 3.7.

---

## Intake (0.0.x)

**0.0 — Feature request** · **0.0.1 — Trivial edit the stakeholder will review themselves?** *(BMad)* · **0.0.2 — Edit directly; no workflow**

Entry is the `feature-workflow` skill, which sizes the request and routes it (D3, D27).

---

## Phase 0 — Discovery

### 0.1 — Initialise the feature folder

**0.1.1 — Scan `.workflow/specs/`** *(Spec Kit)* · **0.1.2 — Derive a slug** *(Spec Kit)* · **0.1.3 — `.workflow/specs/NNN-slug/`** · **0.1.4 — `spec.md`** *(fields, IDs, single writer from BMad)*: frontmatter status; Why, Capabilities with IDs, Constraints, Non-goals, Success signal; links, never copies; single writer enforced by `spec-single-writer-guard` against the `.step` marker (D16); when seeded from a backlog item, writes `origin:`, a `design-log.md` Origin entry, and marks the item `promoted` (D69) · **0.1.5 — Did this request come off the shelf?** (if so, `deferred-handoff` archives the shelf file; D24) · **0.1.6 — Draft the goal**

### 0.2 — Retrieve existing system context

**0.2.1 — Identify the affected area** · **0.2.2 — Term gate** · **0.2.3 — Agree definition** · **0.2.4 — Sub-agent: retrieve** (both tiers plus the shelf; extracts only) · **0.2.5 — Sub-agent: libraries** · **0.2.6 — `codebase-map.md`** (per-feature extracts; not a cache, not Tier A) · **0.2.7 — Cache stamps match HEAD for the affected area?** (a check, not a judgement; `cache-stamp-check.sh`) · **0.2.8 — Sub-agent: regenerate the affected caches and restamp** (the agent writes to staging; `publish-cache.sh` stamps and publishes; D17)

### 0.3 — Frame the problem

**0.3.1 — Capability already exists?** (00.2) · **0.3.2 — Reframe** · **0.3.3 — Owning module clear?** (00.3) · **0.3.4 — Resolve placement** · **0.3.5 — Conflicts with an ADR or rule?** (a rule conflict becomes a 5.3 proposal, not a mid-feature override) · **0.3.6 — Conform or supersede** (a supersede is written under step 0.3.7; D51) · **0.3.7 — ADR** (test and format from `domain-modeling`; a placement that fails the three-part test goes in `design-log.md` instead, D43) · **0.3.22 — Deeper prompt** (`deeper-prompt` skill, first entry only; runs before 0.3.8 and its agreed prompt is the loop's input; id kept out of order, since numbers identify nodes; D73) · **0.3.8 — Compute the frontier** · **0.3.9 — Any answerable?** · **0.3.10 — Sub-agent: look up facts** · **0.3.11 — Ask the whole set in one round** · **0.3.12 — Any deferred to deep dive?** · **0.3.13 — Deep dive each** · **0.3.14 — Term gate** · **0.3.15 — Agree definition** · **0.3.16 — Outside agreed scope?** · **0.3.17 — Write the deferred handoff** (`deferred-handoff`; D24) · **0.3.18 — Questions remaining?** · **0.3.19 — Confirm or revise the goal** · **0.3.20 — Light-path test** *(BMad)*: a pass writes a one-task `tasks.md` and sets `ready-for-dev` (D14), and deletes the originating backlog item file, if any (D69) · **0.3.21 — `design-log.md`**

### 0.4 — Model the impact

**0.4.1 — Map onto schema and interfaces** · **0.4.2 — Term gate** · **0.4.3 — Agree definition** · **0.4.4 — Classify: create, extend, refactor, unchanged** · **0.4.5 — `data-model.md`** *(Spec Kit)* · **0.4.6 — Sub-agent: audit the owning module** (writes to the map; a wrong cache is a stamp problem, not a hand edit) · **0.4.7 — Conflicts with goal or placement?**

### 0.5 — Define the end state

**0.5.1 — End state as testable objectives** · **0.5.2 — Name the journeys** · **0.5.3 — Fixtures and reference systems** · **0.5.4 — `verification-plan.md`**

### 0.6 — Exit gate

**0.6 — Scope, impact, data changes, testable objectives all clear?** Sets `ready-for-dev`. If the spec was started from a backlog item, Yes deletes that item file (D69).

---

## Phase 1 — Verification setup *(PROJECT_BRIEF)*

**1.1 — Measurable targets** (also creates the spec branch `spec/NNN-slug` off main, commits the spec folder as its first commit and captures that commit as `baseline_revision`, with `spec_branch`, in `spec.md` on the full path; D53, D85) · **1.2 — Harness and CI** · **1.3 — Browser suite from the journeys** · **1.4 — Do both suites fail a known-bad build?** (No → 1.2; cannot be made to fail → `blocked`. Only assertion failures count as proof, not errors or crashes. For a brand-new module, stub the interface first so the new tests fail on an assertion. Technique: targeted fault injection per `PLAN/gap-research.md` G4, with StrykerJS optional; D63) · **1.5 — Harness, browser suite, pipeline** (records `## Suites`, then commits the Phase 1 state on the spec branch; the branch is red by design until the last wave, D85)

1.2 and 1.3 are built by `implementation` sub-agents like any other coding task, launched under test-specific profiles (`test-harness` and `e2e-browser`) so file locations, test libraries and assertion style follow the project's conventions. Project setup therefore creates those two profiles alongside the application ones; the scaffold ships filled examples of both (D26). These launches come before `tasks.md` exists, so they pass `work_type` explicitly in the header — the one marked exception to looking it up by task ID (D14). Discovered work while building the suites → 00.21 (D56). The stop audit for these launches skips the profile's `test` key (`run-toolchain.sh --skip test`): the new tests are red by design, and 1.4 proves they fail; the other command keys still run (D70).

---

## Phase 2 — Task breakdown

**2.1 — Split into vertical slices** *(Matt Pocock)* — slices also respect profile file-location rules, so a slice does not straddle two work types unnecessarily; each gets predicted files, a size (files + estimated lines → S/M/L, L a split signal) and a mode (`afk`/`hitl`); a predicted-file overlap within a wave becomes an edge unless the stakeholder approves `parallel_with`; the quiz shows the waves table (D85) · **2.2 — Specifiable?** (No → status `draft`, back to 0.3.8; D49) · **2.3 — Interfaces under test agreed?** (No → status `draft`, back to 0.3.8; D49) · **2.4 — Modifies shared core?** (00.3; core work is batched for `integration`, one work type per batch, D28) · **2.5 — `tasks.md` + dependency graph**, the index: a `tasks:` YAML array in frontmatter (D15), each task carrying status and, once classified at 3.1, work type, plus the waves table; one `tasks/T<nn>-<slug>.md` per task holds its body (D85); also writes `budget` into `spec.md` from the `.workflow/rules.md` defaults (D58) · **2.6 — Within the size budget (task count and predicted files)?** No → 00.21 (D58, D85). Yes → commit the breakdown on the spec branch. Discovered work during breakdown → 00.21 (D56).

---

## Phase 3 — Implementation

**3.1 — Orchestrator: classify each task by work type; launch one sub-agent per task in dependency order** *(PROJECT_BRIEF; classification is ours)*
Two lookups per task, both made by the `pre-launch` hook through `resolve-launch.sh`: the model (00.12) and the profile (00.18) (D33). The work type is written onto the task record by `status-transition.sh set-task`, the only writer of task records (D45), so a resumed session does not reclassify. 3.1 records `impl_base_revision` (the spec-branch tip) in `spec.md`; on the light path it also captures `baseline_revision` (D53, D85). At each wave start the orchestrator creates, on both hosts, a task branch `task/NNN-slug/T<nn>-<slug>` off the spec-branch tip and its worktree `.workflow/.worktrees/<task_name>`, and launches the implementer there; it merges the wave back at 3.16 (D18, D85). If discovered work or a crossed budget blocks the spec (00.21), running tasks finish and pass through their gates, and no new launch starts until the user answers (D56). Sets `in-progress`.

**3.2 — Integration owner applies core changes between batches**
Receives the profile for the work type its batch touches. The orchestrator splits integration batches so each touches only one work type, so each launch carries exactly one profile (D28).

**3.3 — Sub-agent per module: write failing test, then implementation, under the injected profile** *(Matt Pocock, tdd)*
The profile is in its prompt, and so is the TDD method: the agent does not call a vendored skill (D10). It works in its task worktree (D18, D85), reads its task file, and makes its own task's tests green; other tasks' Phase 1 tests stay red until they merge. Before a `mode: hitl` task the orchestrator pauses and asks the stakeholder (D85). It does not choose file locations, libraries or language settings; it follows them. If it believes the profile is wrong, it says so in its output and stops rather than working around it.

**3.4 — Add negative and edge-case tests**

**3.5 — Run the profile's toolchain: lint with anti-slop rules, type-check, format, import-boundary check**
A command run, not an agent. When the implementing agent tries to stop, `post-implementation-audit` calls `run-toolchain.sh`, which executes the command keys in the profile's Toolchain YAML block — `lint`, `typecheck`, `format`, `boundary` and `test` (D61), never `serve` or `serve_ready` (D62) — against the task's diff in its worktree (D19). Phase 3 audits always run `test`, scoped to the task's own tests plus regressions against `impl_base_revision` (D85); only the Phase 1 (1.2, 1.3) audits skip it (D70). For TS/JS work types that means the vendored anti-slop rules plus the project's own lint config, the type checker in strict mode, the formatter in check mode, and an import-boundary tool configured from `.workflow/tools/boundaries/` (generated from the ownership section of `rules.md`; D20) so a module reaching into another module's internals fails here rather than in review. Output is saved to `artifacts/<task-id>/`. On Codex the orchestrator runs the same script itself (D9).

**3.6 — Tool audit clean?**
No → 3.3 with the raw tool output: the hook blocks the stop, so the implementing agent fixes what the tools named in the same context. Yes → 3.7. No agent looks at the diff until this is yes.

**3.7 — Sub-agent: mini-review against the checklist items no tool can express, given the tool output**
Launched by the orchestrator once 3.6 passes, because a hook cannot launch an agent (D19). Reads the diff and the profile's checklist section, plus the fixed readable-code lines every project gets (comments say why, never restate the code, never cite a decision record or document; names say what things are for; D86), with 3.5's output attached so it knows what has already been checked. Judges only the lines that need a reader — abstraction fit, naming against the domain, whether the error path matches the module's convention. Does not re-lint, re-type-check, or re-derive anything a tool reported. Every finding it makes that recurs across tasks is a candidate for conversion into a tool rule at 5.2.

**3.8 — Mini-review passes?**
No → 3.3 with the checklist items that failed. Yes → 3.16 (wave merge), then 3.15 (budget), then 3.13.

**3.9 — Tests pass and CI green?**
Runs the harness through the profile's `test` command (D61). The spec branch is red by design until the last wave: after an earlier wave it passes when nothing green at `impl_base_revision` regressed and every `done` task's tests pass; after the last wave the whole harness must pass (D85). No → the failing task is reopened: `set-task` `done` → `in-progress` (or `done` → `blocked` on a halt) is legal at this step (D59).

**3.10 — Run the browser suite against the running feature**

**3.11 — Do the end-to-end journeys pass?** Sets `in-review`. No → the task is reopened as at 3.9 (`done` → `in-progress` or `blocked`; D59).

**3.12 — Run artifacts** *(PROJECT_BRIEF)*
Collected by `evidence-capture` after each browser-suite run.

**3.13 — Harness and browser suite both exist?**
Always yes on the full path, because Phase 1 built them. Yes → 3.9. No, which can only happen on the light path → 3.14 (D29, D60).

**3.16 — Merge the wave's worktrees**
Once every task in the wave has passed 3.8, the orchestrator takes them in task-id order: opens the task PR/MR into the spec branch per `task_review` in `.workflow/rules.md` (`pr` by default, a non-blocking review record; `pr-blocking` waits for approval; `local` none), merges `--no-ff` with `Merge T<n>: <title>` (D18), marks the task `done`, records `pr`, and deletes the task branch and worktree (D85). Then 3.15 runs, once per wave. While the spec is blocked (00.21), both the merge and 3.15 wait (D56). `split-out` tasks are skipped (D68).

**3.15 — After each wave merge: within the size budget?**
After 3.16, counts `git diff --name-only <impl_base_revision>..HEAD` (D85; Phase 1 files never count), excluding the spec folder, against `max_changed_files`. No → 00.21 (D58). A `discovered-work` return from `implementation` or `integration` at any point in Phase 3 → 00.21 (D56).

**3.14 — Skip the gate of each missing suite; record the suite gap**
The orchestrator runs the suite that exists (the harness at 3.9, or the browser suite at 3.10) and skips only the missing suite's gate (D60). It records the missing suite in `spec.md` and as a `.workflow/deferred/` handoff through `deferred-handoff`; when neither suite exists it sets `in-review` and goes straight to Phase 4. Sign-off flags the gap in the 5.4 report (D29). The gap is never reported as a pass.

---

## Phase 4 — Review and triage

**4.1 — Sub-agent: coding standards, rules, profile and architecture conformance** *(Matt Pocock)*
Baselines: documented standards, the rules (00.3), the profile for each task's work type (00.17), the placement ADR (0.3.7), `GLOSSARY.md` naming, and the readable-code baseline in `feature-workflow/references/readable-code.md`, fixed in every project (D86): a comment citing a decision record or document is a hard breach, a comment restating the code is low severity. Receives the tool output from 3.5 for every task and does not re-lint; its job is what tools cannot see across the whole change — the Fowler smells, boundary drift, a placement that technically passes the import checker but violates the ADR's intent. Re-checks the profile even though 3.7 did, because 3.7 was per task and this lens sees the whole change.

**4.2 — Sub-agent: goal and end-state conformance** *(Matt Pocock)* · **4.3 — Sub-agent: measurable targets** (starts the build with the profile's `serve`, waits for `serve_ready`, measures, stops it; D62) · **4.4 — Triage each finding** *(BMad)* (a `discovered-work` finding → 00.21, D56) · **4.5 — Route: patch / defer / decision needed / none** *(BMad)* (decision needed → status `draft`, back to 0.3.8; D49) · **4.6 — Third pass with non-trivial findings?** *(BMad)*: Yes sets `followup_review_recommended` in `spec.md` (D54) and status `draft` before returning to 0.3.8 (D49) · **4.7 — Rework attempts remaining? (max 5)**: Yes reopens the task (`set-task` done → in-progress). No sets `blocked` only when high-severity findings are open; otherwise the spec stays `in-review` and the rest is deferred at 4.8 (D48) · **4.8 — Deferred handoffs** (`deferred-handoff`; D24; adds them to `deferred[]` in `spec.md`)

---

## Phase 5 — Sign-off

**5.1 — Reconcile `spec.md`**
If the spec arrived `blocked` from 4.7, 5.1 moves it to `in-review` and records the open findings as known gaps for the 5.4 report (D47).

**5.2 — Propose Tier A updates: capabilities, rules, decisions, pitfalls, profile changes**
Written to `.workflow/specs/NNN-slug/proposals.md`, one line per proposal with an approval status (D21). Profile changes are proposed here too: a library the project adopted, a location rule that turned out wrong, a checklist item that kept catching the same thing (or never caught anything). A recurring mini-review finding is proposed as a *tool rule* — a new lint rule, a boundary constraint, a type-check setting — with the checklist line removed once the rule is in the toolchain. Each proposal states why removing it later would change agent behaviour.

**5.3 — Human approves or modifies the proposals?**
Line by line. Writes to Tier A and to the profiles as approved. Approved new capabilities get real `CAP-###` IDs: 5.3 rewrites the provisional `CAP-NEW-<slug>` references in `spec.md` directly and in `tasks.md` through `status-transition.sh set-task --capability` (D44, D45, D52). An approved `rules.md` change regenerates `.workflow/tools/boundaries/` through `rules-boundary-config-sync` (on Codex, `sign-off` runs `generate-boundary-config.sh` itself; D9, D20).

**5.4 — Report** *(PROJECT_BRIEF)*: written to `.workflow/specs/NNN-slug/report.md` (D21), with real test output, metrics, known gaps (including any skipped suite from 3.14; D29) and evidence attached · **5.5 — Stakeholder approves the work?** · **5.6 — Read status; re-enter at the phase it names** (a change request sets `draft` and returns to 0.3.8; D49) (also offered at session start by `session-start-resume`) · **5.9 — Offer this spec's open work-backlog items as the next feature** (runs after 5.5 Yes and before 5.7, so every item is decided before `done`; ids kept, since numbers identify nodes, not order; D57): start (hand off to a new spec through 0.1; that spec's 0.1.4 marks the item `promoted`, D69), keep `open`, or move to `.workflow/deferred/` (`moved-to-deferred`, through `deferred-handoff`, adding to `deferred[]`) · **5.7 — Retrospective with stakeholder** *(BMad)*: combined result against the spec; process lessons to the decision log, feature notes to `design-log.md`, model observations to `.workflow/model-map/` — or, where the agent definition pins a model for that host, a proposed `.workflow/agent-overrides.yaml` entry; definitions are never edited in a target project (D35). Run by the standalone `retrospective` skill, which `sign-off` invokes (D25). Sets `done`, from `in-review` (D47). · **5.8 — Merge and close** (the spec branch into main through a PR, D85)
