# Decision Flow Reference

Companion to `PLAN/decision-flow.mermaid`. Every numbered node in that diagram has an entry here saying what it is, what it is responsible for, and what it is *not*. The numbers are the step ids in `.agents/skills/feature-workflow/references/steps.tsv`. Where an idea was taken from another project, the entry says so and the Sources section says where to find the original.

**Decisions applied.** This document and the diagram are reconciled with decisions D1–D127 in [`assetlist.md`](../assetlist.md#decisions) and with the step files: the router `.agents/skills/feature-workflow/SKILL.md`, the modules in `.agents/skills/feature-workflow/modules/`, `.agents/skills/feature-workflow/references/conventions.md`, `.agents/skills/feature-workflow/references/launching.md` and the agent definitions in `.agents/agents/`. The step files say what runs; when this file disagrees with them, this file is the one to fix. Decision numbers are cited inline as (D#). `PLAN/` is a scaffold-only design doc: `install.sh` leaves it out of the payload copied into target projects (D30). Shared vocabulary lives in `.workflow/GLOSSARY.md`.

## Sources

Several parts of this flow are adapted from other projects. When building the workflow, go to the originals for their prompts and templates rather than reconstructing them from these notes. They are inspirations only, not runtime dependencies: no first-party skill, agent or hook calls a vendored skill at runtime (D10). The vendored copies were deleted once first-party versions existed (D77, D78); the upstream repos are pinned in `upstream-lineage.json`, and per-item sources are in `PROVENANCE.md`.

| Source | What we took | Where to find it |
| --- | --- | --- |
| **BMad Method**: docs at https://docs.bmad-method.org/, code at https://github.com/bmad-code-org/BMAD-METHOD | The trivial-edit bypass (0.0.1); the three-fact light-path test (0.3.20); the five spec fields, stable capability IDs and the single-writer rule (0.1.4); spec status states and *blocked* as a routing signal (Status section); finding-level triage with verify, grade and dismiss-with-reason (4.4); the routing of findings (4.5); the third-pass rule (4.6); the rework ceiling of five (4.7); the retrospective (5.7); the test for what earns a line of project context (Project context section). | The pages *Build a Change*, *Review a Change*, *Autonomous Development Loops*, *Define Requirements and a Specification*, *Finish an Epic*, *The Theory of Project Context* and *Set and Maintain Project Context*. The skill prompts are in the repo under the skill folders. |
| **Spec Kit** (GitHub): https://github.com/github/spec-kit | The numbered spec folder and slug (0.1.1, 0.1.2); `data-model.md` as a named artifact (0.4.5); the analyse-before-implement idea behind 0.6. | The command prompts in that repo. Spec Kit ships no data-model template: its shape is in Phase 1 of its plan command. |
| **Matt Pocock's skills**: https://github.com/mattpocock/skills | The questioning loop (0.3.8–0.3.13, from *grilling*); the glossary-only `GLOSSARY.md` and the three-part ADR test (00.1, 0.3.5–0.3.7, from *domain-modeling*); out-of-scope handling and the HITL/AFK split (0.3.16–0.3.17 and the shelf, from *wayfinder*); the two-axis review and the Fowler smell baseline (4.1–4.2, from *code-review*); agreed test seams and vertical slices (2.1, 2.3, from *tdd*); the module, interface, seam and adapter vocabulary (from *codebase-design*). | Upstream, at the commits pinned in `upstream-lineage.json`. The first-party `domain-modeling` skill is adapted from *domain-modeling*, with its formats in `.agents/skills/domain-modeling/assets/` (D10). The `implementation` agent carries its own TDD method rather than calling *tdd* (D10). |
| **PROJECT_BRIEF.md** (this project) | The verification loop before the build (Phase 1, 3.12); one builder per module, waves by dependency, a single integrator for shared core (3.1–3.3); report real numbers, never inflated ones (4.7, 5.4); resume from recorded state (5.6). | Not kept in the repo; superseded by this file and `assetlist.md`. |
| **anti-slop**: https://github.com/dmmulroy/anti-slop | The principle behind 3.5: reject low-evidence code mechanically before any agent reviews it. Its Oxlint rule set is the starting point for every TypeScript or JavaScript profile's lint. | `project-setup` fetches the rules at a pinned commit at setup time instead of bundling them (D42), as a step inside that skill, not a call to upstream's install skill (D10). Each profile's toolchain names the rules it turns on. |
| **Diagram.md** (this project) | The original stage spine. | Not kept in the repo. |

Our own contributions: the placement-before-requirements gate (0.3.3); the three inline term gates (0.2.2, 0.3.14, 0.4.2); the shelf, `.workflow/deferred/`, with one file per concept, back-links and archival (00.8–00.10); the defer-to-deep-dive option (0.3.12–0.3.13); the known-bad-build test for both suites (1.4); the model table and launch validation (00.11–00.14); work profiles injected by work type, with a tool audit and then a mini-review (00.16–00.20, 3.5–3.8); `spec.md` as the feature map with one writer; the discovered-work protocol (00.21–00.28); the one sign-off ask (5.5).

## Build inventory

Everything the flow needs before it can run: files, templates, sub-agent task types, hooks and scripts. Node numbers point back to the diagram. Scaffold assets live in `.agents/`; the files below are created in the target project.

### Persistent files (`.workflow/` in the target project, shared by every feature)

All workflow data lives under one committed folder, `.workflow/` (D81). Only the app's own browser tests and root tool configs that a tool requires at the root stay outside it.

| Path | Node | Written by | Notes |
| --- | --- | --- | --- |
| `.workflow/GLOSSARY.md` | 00.1 | 0.2.3, 0.3.15, 0.4.3, 5.3; 6.6 from an initiative | Glossary only. Format in `.agents/skills/domain-modeling/assets/GLOSSARY-FORMAT.md` (D10). A project with several contexts adds `.workflow/GLOSSARY-MAP.md`. |
| `.workflow/capabilities.md` | 00.2 | 5.3 | One entry per capability with a stable `CAP-###` id and a link to the spec that introduced it. A spec in flight uses provisional `CAP-NEW-<slug>` ids; 5.3 assigns the real number (D44, D52). |
| `.workflow/rules.md` | 00.3 | 5.3 | Ownership and boundaries, shared core, cross-cutting policy, external systems, required versions, a `## Size budget` block (D58) and an optional `## Workflow settings` block (`task_review`, `main_branch`, `pr_template`), read through `rules-setting.sh`. The Ownership and Shared core sections are fenced `yaml` blocks (D15), because the import-boundary config is generated from them (D20). |
| `.workflow/decisions/adr/` | 00.4 | 0.3.7, 5.3 | One ADR per file, format in `.agents/skills/domain-modeling/assets/ADR-FORMAT.md`, template `.agents/skills/domain-modeling/assets/adr.md`. Superseded ADRs stay, marked. |
| `.workflow/decisions/pitfalls.md` | 00.4 | 5.3, 5.7 | Observed failures only: what happened, where, the spec, and what now prevents it. |
| `.workflow/decisions/retrospectives/` | 00.4 | 5.7 | One file per shipped feature, written by the `retrospective` skill (D25): its verdict, process lessons and action items. |
| `.workflow/review-lessons.md` | 00.4 | 5.7 only | Recorded review lessons, one fenced `yaml` block of `lessons:` with ids `RL-001` and up; checked by `review-lessons.sh`, template `.agents/skills/feature-workflow/assets/review-lessons.md`. The standards lens (4.1) and the combined review (4.10) read it. |
| `.workflow/tools/boundaries/` | 00.3 | `generate-boundary-config.sh` | Generated import-boundary config, one file per language adapter (D20). Never hand-edited. |
| `.workflow/deferred/` | 00.8 | 0.3.17, 3.14, and a stakeholder's shelf request at a batched ask or 5.9 | The shelf: one file per concept, written through the `deferred-handoff` module (D24) from `.agents/skills/feature-workflow/assets/deferred.md`. Review and sign-off never write one on their own. |
| `.workflow/deferred/archive/` | 00.10 | 00.9 | A shelf file with `superseded_by:` prepended once a spec takes it up. |
| `.workflow/specs/work-backlog/` | 00.27 | 00.26 and 5.9, and a new spec's 0.1.4 (marking a line `promoted`); main session only | The backlog: one list per spec, named after the spec (for example `.workflow/specs/work-backlog/00014-tracker-issue-spec-ids.md`), from `.agents/skills/feature-workflow/assets/work-backlog.md`. One line per item, `- [open] B<n> <kind> (<origin node>): <problem>. Evidence: <...>.`, with status `open` or `promoted` (D105). It holds work found while building that the stakeholder kept for later. It is not the shelf. |
| `.workflow/specs/done/` | — | 5.8, by `move-to-done.sh` only | The Done folder: every finished spec moves here, so the top level of `.workflow/specs/` lists only work in flight. |
| `.workflow/model-map.yaml` | 00.11 | `project-setup`; 00.14; 5.7 (observations) | The model table: one row per task type with `tier`, `claude`, `codex`, `why` and optional dated `observations` (D123). Seeded from `.agents/skills/project-setup/assets/model-map.yaml`. It is the only model source. |
| `.workflow/profiles/TEMPLATE.md` | 00.16 | `project-setup` | Fixed sections: File locations, Approved libraries per concern, Language and style rules, Toolchain (one fenced `yaml` block: `lint`, `typecheck`, `format`, `boundary`, `test`, `test_scoped`, `e2e`, plus `serve` and `serve_ready`, which `run-toolchain.sh` never runs; D15, D61, D62), Mini-review checklist. |
| `.workflow/profiles/` (one file per work type) | 00.17 | `project-setup`, 00.19 (a new file), 5.3 (an existing file); a `TODO:` toolchain key also at 3.3–3.5 | One file per work type, following the template. The scaffold ships filled `test-harness` and `e2e-browser` examples in `.agents/skills/project-setup/assets/profiles/examples/` (D26). |

### Per-feature files (in the spec folder)

A spec folder is `.workflow/specs/NNN-slug/`. From 1.1 on (0.3.20 on the light path) it lives in the spec worktree, `.workflow/.spec-worktrees/NNN-slug`, on the spec branch `spec/NNN-slug` (D111). After 5.8 it sits in `.workflow/specs/done/NNN-slug/`.

| File | Node | Written at | Notes |
| --- | --- | --- | --- |
| `spec.md` | 0.1.4 | 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 5.1, 5.3, 5.9 | Frontmatter: `status`, `tracker_issue`, `light_path`, `spec_branch`, `baseline_revision`, `impl_base_revision`, `budget`, `deferred`, `followup_review_recommended`, `blocked_condition`, `origin` (a seeded backlog line), `initiative` (a spec an initiative emitted). `status` and `blocked_condition` change only through `status-transition.sh`. |
| `.step` (gitignored) | — | every step change, by `status-transition.sh` only | The current step, a timestamp, a `seq` number that orders markers (D125), and `blocked_from` while the spec is `blocked`. Read by the write guard. Never written with Write or Edit. |
| `codebase-map.md` | 0.2.6 | 0.2.6, 0.4.6, and a later library evaluation | Agent extracts only: affected area, relevant code, seams and interfaces, prior decisions, library options (or one `Not evaluated:` line), module audit, not found. |
| `design-log.md` | 0.3.21 | every round and event | Append-only. Entry shapes in `.agents/skills/feature-workflow/assets/design-log.md`: Deeper prompt, Questioning round, Deep dive, Placement, Scope decision, Assumed, Impact classification, Breakdown quiz, Discovered work, Triage review pass, Sign-off, Origin. |
| `data-model.md` | 0.4.5 | 0.4.5 | Entities, validation rules, state transitions, ordered migrations. Full path only. |
| `verification-plan.md` | 0.5.4 | 0.5.1–0.5.3, 1.1 (Targets), 1.3 and 1.4 (journey checks), 1.5 (Suites) | End state, journeys with `JRN-###` ids, fixtures and oracles, targets, suites. Full path only. |
| `tasks.md` | 2.5 | 2.5, or a one-task file at 0.3.20 on the light path; afterwards only `status-transition.sh set-task` | The task index: a `tasks:` YAML array with `id`, `title`, `status`, `work_type`, `module`, `seam`, `capability`, `depends_on`, `touches_core`, `file`, `branch`, `predicted_files`, `size`, `mode`, `parallel_with`, `tests`, `issue`, `pr`; body: the waves table and the Mermaid graph. |
| `tasks/` (one `T<nn>-<slug>.md` per task) | 2.5 | 2.5 or 0.3.20, never edited afterwards | What to build, seam, acceptance criteria, predicted files, size, mode, notes. The implementer reads its own file. |
| `proposals.md` | 5.2 | review triage (a proposal route), 5.2, 5.3 | One row per proposed Tier A or profile change, with its status. |
| `report.md` | 5.4 | 5.4 | Real test output, targets against measured, journeys, review outcome, known gaps, open items; five lines for a one-task spec. |
| `pr-body.md` | 5.4 | 5.4, 5.3 (capability ids only) | The Sign-off PR description, checked by `check-pr-body.sh`; 5.8 publishes it. |
| `retrospective-draft.md` | 5.5 | 5.5 (draft), 5.7 (moved into the decision log) | The retrospective's draft verdict and numbered lessons, shown at the 5.5 ask. |
| `artifacts/` | 3.12 | agents, scripts and hooks | Per task: `toolchain.json`, `toolchain.txt`, `audit.json`, `implementation.yaml`, `mini-review.yaml`. Per integration batch: `integration.yaml`. Phase 1: `phase-1-<work_type>/` and `phase-1-known-bad/`. Gates: `gate-3.9-w<N>/`, `sign-off-5.4/`. Journey evidence by run and journey id. Review: one pass file per lens under `review/pass-<n>/`. |

### Templates

Templates live in the `assets/` folder of the skill that owns them (D8).

- `.agents/skills/feature-workflow/assets/`: `spec.md`, `codebase-map.md`, `design-log.md`, `data-model.md`, `verification-plan.md`, `tasks.md`, `task.md`, `deferred.md`, `work-backlog.md`, `proposals.md`, `report.md`, `pr-template.md`, `review-lessons.md`, and `initiative.md` and `questions.md` for an initiative folder.
- `.agents/skills/domain-modeling/assets/`: `adr.md`, `ADR-FORMAT.md`, `GLOSSARY-FORMAT.md` (D10).
- `.agents/skills/retrospective/assets/`: `retrospective.md` (D25).
- `.agents/skills/project-setup/assets/`: `GLOSSARY.md`, `model-map.yaml`, the profile template and examples under `profiles/`, and `rules.md`, `capabilities.md` and `decisions/pitfalls.md` under `docs/`. Setup copies them into `.workflow/` (D81).

### Sub-agent task types

Each row is one agent definition in `.agents/agents/` (D1) and one row of `.workflow/model-map.yaml` (D123). A definition carries no model. "Receives" is the whole of the agent's context beyond its launch header; the definition's own Receives or Input section is the authority. "Default tier" is what `project-setup` seeds (D23).

| Task type | Node(s) | Default tier | Purpose | Receives | Returns |
| --- | --- | --- | --- | --- | --- |
| `retrieval` | 0.2.4 | cheap | Read the code, Tier A decisions and rules, and the shelf for the affected area | Affected area, agreed terms | Cited extracts for `codebase-map.md` |
| `library-evaluation` | 0.2.5, or later when an answer brings in a library | cheap | Grade up to three candidates for a concern on a fixed rubric | Affected area, agreed terms, the External systems section of `.workflow/rules.md` | A bounded options report with a URL for every claim |
| `fact-lookup` | 0.3.10, 6.4 | cheap | Answer a factual question from the repo so it is never asked | Numbered questions, affected area | Each fact with its source, "not a fact", or "not determinable from the repo" |
| `module-audit` | 0.4.6 (or beside the first round) | strong | Deep read of the owning module | Owning module and its paths, what the feature changes in it | Reuse, gap and constraint findings, interface additions, out-of-scope lines |
| `implementation` | 3.3, and 1.2/1.3 under test profiles | strong | Build one task test-first in its own worktree | The whole profile (prepended by the hook), the task file path, the worktree, a `codebase-map.md` extract, any shared-core interface applied for it | `implementation.yaml` under `artifacts/`, plus a short summary |
| `integration` | 3.2 | strong | Apply one batch of shared-core change requests of one work type | The whole profile for the batch's work type, the numbered requests | `integration.yaml` with a verdict per request |
| `profile-mini-review` | 3.7 | cheap | Judge one task's diff against the profile checklist and the readable-code lines R1–R5 | The checklist section (prepended by the hook), the worktree and base commit, the 3.5 tool output, the implementer's `self_review` | `mini-review.yaml`: a verdict per item by number, and every readable-code breach with its exact fix |
| `review-standards` | 4.1 | strong | Standards across the whole change, including the recorded lessons | Header and pass number; reads the rules, profiles, placement ADR, glossaries, readable-code and smell baselines, review lessons, pitfalls and retrospective process lessons, and the 3.5 tool output itself | Its pass file and a summary |
| `review-end-state` | 4.2 | strong | Does the change do what the spec says, and nothing it does not | Header and pass number; reads `spec.md`, `verification-plan.md` and `artifacts/` itself | Its pass file and a summary |
| `review-targets` | 4.3 | cheap | Measure the running build against the Targets table | Header and pass number; reads the targets and the profile's `serve` and `serve_ready` itself | Its pass file with a `measurements:` table, and a summary |
| `review-combined` | 4.10 | strong | One reviewer for end state, standards and lessons on the light path | Header and pass number; reads what 4.1 and 4.2 read | One pass file in the lens shape, and a summary |
| `research` | 6.4 | strong | Answer one open initiative question from the repo, its docs, git history and the web | The question and its context | The answer with a source for every claim |
| `standards-discovery` | outside the flow, from `project-standards` (D80) | strong | Read-only brownfield scan of the conventions the code follows | Scope, candidate work types, `since_commit` on a refresh | Modules, conventions, versions, contradictions, unknowns, discovered work |

Every launch prompt starts with a launch header (D13, D37): a fenced block opened with ```` ```yaml launch-header ````, holding `task_type` and the fields its type requires. `resolve-launch.sh --requirements` prints them:

| Task type | Required header fields | Profile prepended |
| --- | --- | --- |
| `implementation` | `spec_dir` and `task_id` (`work_type` optional, looked up from `tasks.md`); a Phase 1 build (1.2, 1.3) carries `spec_dir` and an explicit `work_type` instead (D14) | whole |
| `integration` | `spec_dir`, `work_type` | whole |
| `profile-mini-review` | `spec_dir`, `task_id` (`work_type` optional) | checklist section only |
| `retrieval`, `library-evaluation`, `fact-lookup`, `module-audit`, `research` | `spec_dir` (an initiative folder for a launch from an initiative) | none |
| `review-standards`, `review-end-state`, `review-targets`, `review-combined` | `spec_dir` | none |
| `standards-discovery` | none | none |

Sub-agents do not launch sub-agents, so there is no nested-launch step (D13, D32). The orchestrator (3.1 on), the triage step (4.4) and everything in Phase 0 that is not marked as a sub-agent run in the main session. Inside a spec a sub-agent writes only its own result or pass file under `artifacts/`; the main session checks each with a script and never retypes it.

### Hooks

Hooks are the parts of the flow that must happen without anyone remembering. Each is a Bash script in `.agents/hooks/` and a thin Claude Code adapter: it reads the event JSON, calls a host-neutral script that holds the rule (D9), and turns the exit code into the host's decision. Hooks take paths from the payload `cwd` (D18). The wiring and the deny rules live in `.agents/hooks/claude-settings.template.json`, which `install.sh` merges into the target's Claude settings (D11, D36). Event names and payloads were verified by live runs (`PLAN/hook-verification.md`, `PLAN/hook-verification-codex.md`). On Codex, `.agents/hooks/codex-write-guard.sh`, `.agents/hooks/codex-pre-spawn.sh` and `.agents/hooks/codex-rules-sync.sh` make the same checks where a live Codex run showed the event works; elsewhere the step files call the scripts directly and enforcement is advisory (D9, D40).

| Hook | Fires on | Does | Nodes |
| --- | --- | --- | --- |
| Pre-launch (`pre-launch.sh`) | PreToolUse, matcher `Agent` | Reads the launch header from the start of `prompt` and calls `resolve-launch.sh`. Denies a launch missing a required header field, a task type with no model for this host in `.workflow/model-map.yaml` (00.14), or a coding launch with no profile (00.19). Otherwise returns `updatedInput`: the full input with the profile inserted after the header and `model` set from the task type's row (D13, D33, D123). | 00.11–00.14, 00.18–00.20 |
| Workflow write guard (`workflow-write-guard.sh`) | PreToolUse, matcher `Write\|Edit\|NotebookEdit` | One `check-write.sh` call per write (D125). Allows `spec.md` only at its writer steps and never a status change; `tasks.md` and the task files only at 2.5 or 0.3.20; the backlog only at 00.26, 5.9 or a new spec's 0.1.4; the glossary at the term-gate steps and 5.3; other Tier A at 0.3.7, 5.3 and 5.7; `.workflow/review-lessons.md` at 5.7; a new profile at 00.19, an existing one at 5.3, and a `TODO:` toolchain key at 3.3–3.5 (D126); never a `.step` marker or the Done folder. Denies every guarded path when the payload carries `agent_id` (a sub-agent). Fails closed on any error. Anything else in Tier A is redirected to a 5.2 proposal. | 0.1.4, Tier A |
| Worktree write guard (`worktree-write-guard.sh`) | PreToolUse, matcher `Bash\|Write\|Edit\|NotebookEdit` | For implementation and integration sub-agents: denies a write inside the checkout but outside the agent's worktree, except its own result file under `artifacts/` (D125), and a Bash command that does not start with `cd <worktree> &&`. Rule in `check-worktree-scope.sh`. | 1.2, 1.3, 3.2, 3.3 |
| Destructive git block (`block-destructive-git.sh`) | PreToolUse, matcher `Bash` | Blocks destructive git commands; blocks when it cannot read the command (D125). | all |
| Post-implementation audit (`post-implementation-audit.sh`) | SubagentStop, matcher `implementation\|integration` | Finds the task from the launch header in the agent transcript (D39), runs the profile toolchain through `run-toolchain.sh --reuse` in the agent's worktree (D91), and blocks the stop with the tool output while it fails; gives up after three identical failures. Warns instead of blocking when the header, transcript or worktree is missing (D55). The orchestrator then launches 3.7, because a hook cannot launch an agent (D19). | 3.5–3.6 |
| Rules to boundary config (`rules-boundary-config-sync.sh`) | PostToolUse, matcher `Write\|Edit\|NotebookEdit`, acting only on `.workflow/rules.md` | Re-runs `generate-boundary-config.sh` so the import-boundary tool enforces the rules as approved; fails the write if the YAML blocks do not parse (D20). | 00.3, 5.3 |
| Evidence capture (`evidence-capture.sh`) | PostToolUse and PostToolUseFailure, matcher `Bash` | After a browser-suite run, copies screenshots, traces, console and network logs into the spec's `artifacts/` by run and journey id. | 3.10, 3.12 |
| Session start (`session-start-resume.sh`) | SessionStart | Lists every spec that is not `done` and every handoff, and offers to resume through `feature-workflow` (D22). | 5.6 |

The permission deny rules `Edit(.workflow/specs/*/.step)` and `Edit(.workflow/initiatives/*/.step)` are the hard limit on the step markers. The write guards are accident prevention only, because Bash writes bypass them. `.agents/hooks/context-bridge.cjs` is the statusline script (D79), not part of this flow.

### Helper scripts

Called by the step files and the hooks. Each lives in the `scripts/` folder of the skill that owns it (D7); the shared rule scripts are host-neutral (D9). `jq` and mikefarah `yq` v4 are declared dependencies (D15, D38). Paths below are under `.agents/skills/feature-workflow/scripts/` unless named in full.

| Script | Does | Nodes |
| --- | --- | --- |
| `status-transition.sh` | The one writer of spec status, the `.step` marker and task records (`set-task`). Enforces the legal transitions (see Status). | every state change |
| `initiative-transition.sh` | The same for an initiative's status, marker, slices and questions. | 6.x |
| `check-write.sh` | The write rule behind the write guard, for every guarded path class. Called directly on Codex. | 0.1.4, Tier A |
| `check-worktree-scope.sh` | The worktree-confinement rule behind the worktree guards. | 3.2, 3.3 |
| `resolve-launch.sh` | Validates the launch header, resolves the model from `.workflow/model-map.yaml` and returns the profile text. On Codex the orchestrator runs it and spawns with its output. | 00.11–00.14, 00.18–00.20 |
| `next-spec-number.sh` | Prints the next spec number, or the new tracker issue's number and URL when a tracker is set up. | 0.1.1 |
| `spec-worktree.sh` | `create` branches `spec/NNN-slug` off the main branch, commits the spec folder as its first commit and adds the spec worktree; `remove` deletes both once merged. | 0.3.20, 1.1, 5.8 |
| `run-toolchain.sh` | Runs the profile's toolchain keys in a worktree and saves the evidence; `--reuse` copies a passing record for an unchanged tree (D91); scopes `test` to a task's own and changed suites (D92); refuses a `TODO:` value and names the key (D126). | 3.5–3.6, 3.9, 3.10, 5.4, 5.8 |
| `check-task-result.sh` | Checks one result file (`implementation.yaml`, `integration.yaml`, `mini-review.yaml`) and prints a bounded table of it (D97). | 1.2, 1.3, 3.2, 3.4, 3.7 |
| `check-merge-artifacts.sh` | Refuses a merge that would change the spec's `artifacts/` folder. | 1.2, 1.3, 3.2, 3.16 |
| `commit-workflow-data.sh` | Commits the workflow data the main session wrote onto the spec branch. | 3.16, wave start, hand off |
| `open-task-pr.sh` | Pushes a task branch and opens its PR/MR into the spec branch, per `task_review`. | 3.16, 6.11 |
| `rules-setting.sh` | Reads one setting from the `## Workflow settings` block of `.workflow/rules.md`. | 1.1, 3.16, 5.4, 5.8 |
| `task-waves.sh` | Derives the waves from `tasks.md`, with predicted-file overlaps as implied edges. | 2.5 |
| `budget-check.sh` | Read-only. Compares the task count and the changed or predicted files with the spec's `budget` (D58, D85, D87); exit 2 when over. | 2.6 (`--predicted`), 3.15, 5.4 |
| `check-review-findings.sh` | Checks one lens's pass file and prints a bounded table of its findings (D93). | 4.4 |
| `review-lessons.sh` | Checks `.workflow/review-lessons.md` against its entry rules, or prints the next id. | 5.7 |
| `check-pr-body.sh` | Checks the shape of `pr-body.md`. | 5.4, 5.8 |
| `move-to-done.sh` | `--check` lists open task records and backlog lines; without it, moves the spec into the Done folder, deletes `.step` and rewrites the spec's path in the `.workflow/` files that name it. | 5.7, 5.8 |
| `step-progress.sh` | Prints the progress line for a step from `steps.tsv` (D84). | all counted steps |
| `check-comments.sh` | The comment lint for shell files (D106). | 3.5 (shell profiles) |
| `.agents/skills/issue-tracking/scripts/issue-tracker.sh` | Files, fills and moves tracker issues; prints `skipped: no tracker` without one. | 0.1.1, 0.3.19, 0.3.20, 0.6, 2.6, 3.1, 3.3, 3.16, 5.8 |
| `.agents/skills/domain-modeling/scripts/term-list.sh` | Prints the glossary term list, or one entry. | 0.2.1 |
| `.agents/skills/project-setup/scripts/generate-boundary-config.sh` | Turns the `rules.md` YAML blocks into import-boundary config (D20). | 00.3, 5.3 |

### Processes outside the flow

| Process | What it does | Invoked by |
| --- | --- | --- |
| Install (`install.sh`) | Copies the payload named in `.agents/install-manifest.txt` into the target's `.agents/` (D72), prunes files a previous install shipped that the manifest no longer names, creates the Claude symlinks, merges the settings template (D36), writes the `.gitignore` block for local workflow state, and creates the Codex shim. Leaves out the scaffold-only files and this repo's own `.workflow/` (D11, D30). Never touches a project's `.workflow/`. | A human, once per project and on each upgrade |
| Project setup (`project-setup` skill) | Creates `.workflow/` from the templates (D81), agrees the work types, hands over to `project-standards` for the standards interview (D80, D82), installs each profile's toolchain, generates the boundary config (D20) and seeds `.workflow/model-map.yaml` (D23, D123). | A human, once per project or when a new work type appears |
| Multi-question interface | Presents a numbered round of questions, each with a recommended answer, and collects the answers in one turn. | 0.3.11, 00.22, 5.5 |

The workflow's entry points are skills only (D27). `feature-workflow` is the router; each phase is a step file in its `modules/` folder (D3), with shelf writes in the shared `deferred-handoff` module (D24). The `retrospective` and `deeper-prompt` skills are standalone but run inside the flow at 5.5–5.7 and 0.3.22.

## How to read the diagram

**Node shapes and colours**

| Shape / colour | Meaning |
| --- | --- |
| Rounded, grey | Entry or exit point of the whole flow |
| Rectangle, dark blue | A stage: work done in the main session |
| Rectangle, mid blue | A step: a smaller action inside a stage |
| Rectangle, purple | A sub-agent: a separate context that reads a lot and returns a little |
| Rectangle, grey dashed | A process outside this flow, shown because the flow depends on its output |
| Parallelogram, light blue | A document or artifact on disk |
| Parallelogram, teal | `spec.md`, the feature map and the one file to open first |
| Diamond, orange | A gate: a decision with named exits |

**Numbering**

- `00.x`: persistent artifacts that outlive any single feature, and the shared processes around them (the shelf 00.8–00.10, the model table 00.11–00.14, profiles 00.16–00.20, discovered work 00.21–00.28).
- `0.0.x`: intake, before a feature folder exists.
- `0.x.y`: Phase 0, substage `x`, node `y`; `0.6` is the Phase 0 exit gate.
- `1.x` to `5.x`: Phases 1 to 5.
- `6.x`: the large path, which plans an initiative and emits each settled slice as its own spec. Entered at 0.3.23.

Numbers identify nodes, not run order, and are never renumbered: records cite them. Removed nodes keep their numbers unused: 00.5–00.7, 0.2.7 and 0.2.8 (the generated caches, D117), 0.0.3 (the small path, D122), 00.15 (nested launches, D32) and 4.9 (the lessons lens, D118).

**Progress line (D84).** The orchestrator leads every phase or step update with `Phase <p> of <P> · step <s> of <S> — <phase>: <step> (<id>)`, printed by `step-progress.sh` from `steps.tsv`. Steps are numbered by run order within each phase (0.3.22 before 0.3.8; 0.3.23 before 0.3.20; 3.16 and 3.15 before 3.13 and 3.9; 5.4 and 5.5 before 5.3; 5.9 before 5.7). Full path: 6 phases of 46, 5, 6, 14, 8 and 9 steps. Light path: 4 phases, 34 (0.1.1 to 0.3.20), 15 (Phase 3 with 3.14), 6 (4.10 in place of the three lenses) and 9. Not counted: intake, the 00.x nodes (shown after the step they were entered from), and the side artifacts 0.3.21 and 3.12. A large-path step prints `Large path · step <s> of <S> — <step> (<id>)` over its 13 steps.

**Solid and dotted edges.** Solid edges are flow or a write. Dotted edges are a read, a reference or a conditional path. The fourteen dotted edges out of 00.12 mean "this launch runs on the model the pre-launch hook set"; they reach every purple node.

## Design rules the diagram encodes

1. **Use the smallest amount of process that safely fits the change.** *(BMad.)*
2. **Project context is authored, and the code is the rest.** Tier A holds what the code cannot say; agent proposes, human approves. Everything derivable is read from the code when needed. *(Adapted from BMad.)*
3. **The corpus never enters main context.** Tier A, the code and the shelf are read by a sub-agent that returns extracts. Two deliberate exceptions: the glossary's term list is read into the main session to interpret the request, and a work profile goes whole into a coding agent as its operating instructions.
4. **Model choice is looked up, not improvised.** *(Ours.)*
5. **Coding agents get their operating context by work type.** *(Ours.)*
6. **Tools before agents.** Anything a deterministic tool can check is checked by the tool before any agent reviews the code, and no agent re-derives what a tool reported. A reviewer that keeps catching the same thing is a candidate for a tool rule, proposed at 5.2. *(Ours; the rule set from anti-slop.)*
7. **Questions are asked in parallel, not one at a time.** *(Matt Pocock, grilling.)*
8. **Facts are the agent's job; decisions are the stakeholder's.** *(Matt Pocock; BMad.)*
9. **Only blocking questions wait.** Everything else is assumed, logged and offered for veto at the next blocking ask, and sub-agents whose input does not depend on the answer are launched before the ask. *(Ours; D115, D116.)*
10. **Every document has one home for each fact.** Terms in the glossary; what the system does in the capabilities index; project-wide policy in the rules; work-type conventions in the profiles; rationale, pitfalls and lessons in the decision log; goal, contract and status in `spec.md`; per-feature decisions in `design-log.md`; schema in `data-model.md`; acceptance in `verification-plan.md`; the system's shape in the code.
11. **`spec.md` is a living document with one writer.** *(BMad.)*
12. **A gate has named exits and no dead ends.**
13. **Nothing is claimed that has not been verified.** *(PROJECT_BRIEF.)*
14. **Fix the layer that is wrong.** *(BMad.)*
15. **Phase 0 is re-enterable.**

## Work profiles: the operating context for coding agents

Three stores are keyed by "what kind of work is this". They answer different questions and are read by different parties.

| Store | Question it answers | Who reads it | Enters an agent's context? |
| --- | --- | --- | --- |
| `.workflow/model-map.yaml` (00.11) | *Which model* runs this task type | The launcher: the pre-launch hook through `resolve-launch.sh` | No |
| Rules (00.3) | *What is true project-wide*: ownership, boundaries, policy | `retrieval`, the standards lens, `generate-boundary-config.sh` | As extracts only |
| Profiles (00.17) | *How this kind of work is done here*: file locations, libraries, language rules, toolchain, mini-review checklist | The pre-launch hook, which prepends it (the orchestrator on Codex) | Yes, in full, into coding agents |

**What a profile is.** One file per work type, with the five sections the template fixes. The mini-review checklist holds only what the toolchain cannot express.

**The order of audit is tools, then agent.** When the implementer tries to stop, the stop audit runs the toolchain (3.5). Nothing else happens until it is clean: a failure hands the tool output back to the same agent (D19). Then 3.7 launches the mini-review with the tool output attached, to judge what needs a reader. The implementer walks the same checklist and the readable-code lines over its own diff before it stops (D104).

**The checklist should shrink over time.** A mini-review finding that recurs is proposed at 5.2 as a tool rule, and its checklist line goes once the rule is in the toolchain.

**Where it is configured.** By `project-setup`, once per work type, from `.workflow/profiles/TEMPLATE.md`. The flow has a gate (00.18) for a task whose work type has none.

**How it is used.** At 3.1 the orchestrator records each task's work type in `tasks.md`. 00.18 checks a profile exists; 00.20 places it whole into the implementer's launch (3.3) and the integration batch's (3.2), and its checklist section into the mini-review's (3.7).

**Who changes a profile.** An existing profile changes only at 5.3, from an approved proposal. Two exceptions: a new profile at 00.19, when a task's work type has none (D50), and a toolchain key that still reads `TODO:` when `run-toolchain.sh` refuses it at 3.5 (D126). A coding agent that thinks the profile is wrong reports `profile-wrong` and stops.

**Relationship to the rules.** A line that would appear identically in every profile is a rule.

## Project context

*(Adapted from BMad's "Theory of Project Context": a document describing a system loses to the source it describes; what source cannot hold is intent, rationale, policy and what was rejected.)*

**The test.** Can the fact be derived from the code? If no, it is Tier A. If yes, it is read from the code when needed. The generated caches that once held derived facts were removed (D117): they went stale and nobody used them, so `retrieval` reads the code and Tier A directly.

**Tier A: authored, the source of truth, small.** The glossary (00.1), the capabilities index (00.2), the rules (00.3), the decision log (00.4) with the review lessons, and the profiles (00.17), which are the same in kind but kept in their own folder.

**Tier A is agent-proposed, human-approved.** At 5.2 the agent proposes in `proposals.md`; the stakeholder approves every row or names exceptions in the 5.5 ask; 5.3 writes them. The retrospective's lessons are approved in the same ask and written at 5.7. The term gates write the glossary inline because the stakeholder is in the conversation. The write guard holds Tier A writes to these steps (D16).

**Pitfalls: observed failure only.** A pitfall enters the decision log only when something actually went wrong, and leaves only when the thing it is about is gone or a tool enforces it.

## Status: the state `spec.md` carries in frontmatter

*(Adapted from BMad.)*

| Status | Set at | Meaning |
| --- | --- | --- |
| `draft` | 0.1.4; again on every loop back to 0.3.8 (0.6 before 1.1 starts, 2.2, 2.3, 4.5, 4.6, 5.6, 00.24) (D49) | Discovery under way. |
| `ready-for-dev` | 0.6 or 0.3.20 | Discovery complete enough to build. |
| `in-progress` | 3.1 | Implementation under way. |
| `in-review` | 3.11, or 3.14 on a light path missing a suite; 5.1 from `blocked` (D47) | Review and sign-off under way. |
| `done` | 5.7, from `in-review` only | Approved, retrospective recorded; 5.8 then moves the folder to the Done folder. |
| `blocked` | any halt, with `blocked_condition` | Cannot safely continue without a human. |

`blocked` is a routing signal. Conditions include: the rework ceiling hit with verified high findings open (4.7; otherwise the spec stays `in-review`, D48); suites that cannot be made to fail (1.4); a task whose work type has no profile and no human to define one (00.19); a Phase 1 build or task that cannot work inside its worktree; a blocker while the discovered-work protocol runs (00.21).

**Legal spec transitions** (enforced by `status-transition.sh`): `draft` → `ready-for-dev` (0.6, 0.3.20); `ready-for-dev` → `in-progress` (3.1); `in-progress` → `in-review` (3.11, 3.14); `ready-for-dev` or `in-review` → `draft` on a loop back (D49); `in-review` → `blocked` (4.7); any status → `blocked` on another halt, with `blocked_from` in `.step`; `blocked` → `in-review` at 5.1; `blocked` → `draft` at 00.24; `blocked` → the status in `blocked_from` once a human resolves the condition (00.28); `in-review` → `done` (5.7). There is no `in-progress` → `draft`: Phase 3 reaches discovery only through a blocker at 00.24.

**Task statuses** (written only by `set-task`, D45): `pending` → `in-progress` at 3.3; `in-progress` → `done` at the 3.16 merge; `done` → `in-progress` only for a 3.9 or 3.11 failure or a 4.7 rework; any open status → `blocked` on a halt and back once resolved; `split-out` (terminal) is no longer set, but records an older version wrote at a budget split are still read (D68). Nothing launches, counts or reviews a `split-out` task.

## Asking the stakeholder

*(Ours; D113–D116.)* The stakeholder's time is the most expensive resource in the flow, so the rules for asking live in one place, `.agents/skills/feature-workflow/references/conventions.md`, and the step files point to it.

- **Only blocking questions wait.** A question blocks when its answer changes scope or intent, or when the action it gates is hard to reverse: a merge to the main branch, a publish, a delete, a migration, anything outside the repo.
- **Assume and log the rest.** Any other question (a clear term, a clear shelf match, an assumed target threshold) takes the recommended answer at once and gets an **Assumed** entry in `design-log.md`.
- **Offer every assumption for veto.** The next blocking ask opens with the assumptions not yet offered.
- **Launch before asking.** Before a blocking ask, every sub-agent whose input does not depend on the answer is launched, so the wait is not idle: retrieval beside the 0.2.2 term gate, fact lookups and an early module audit beside the 0.3.11 round, the 1.2 build beside the breakdown quiz, the rest of a wave before a `hitl` pause.
- **Ride on an ask that happens anyway.** The deeper prompt's agreement and questions ride on the first round; the 0.3.19 summary rides on the last round; discovered-work items wait for the next blocking ask (00.25); sign-off asks once, at 5.5.

## Discovered work: the scope-creep guardrail (00.21–00.28)

*(Ours; D56–D58, D96, D102, D105.)* Work found outside the agreed scope while the feature is under way (a new requirement, a bug found along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer) is never folded into the current spec or tasks. It is found in Phases 1–4. Agents report it, as a `discovered-work` status, finding category or `out_of_scope_noticed` line, and never fix it; the main session runs the protocol in `.agents/skills/feature-workflow/modules/discovered-work.md`. Out-of-scope work raised in Phase 0 goes through the scope gate 0.3.16–0.3.17 to the shelf instead.

**Assess each report first.** The questions go in order, and the first that fits routes the report:

1. **Unproven?** No reproduction and no quoted line with its `path:line`, and none the main session can supply with one command: one design-log line, nothing else.
2. **Current work?** On lines or files this spec changes, with a simple fix: the worker that owns those lines fixes it in a fix round (3.8) or the 4.7 rework. The stakeholder is not asked.
3. **Blocker?** A success line or a journey cannot be met without it, or continuing builds on something known to be wrong: **00.21**.
4. **For the stakeholder.** Everything else that is proven (convoluted, scope-expanding or out of scope) gets a Discovered work entry with the ruling `to ask` and a recommendation, and the work continues at once.

The blocker path: **00.21** blocks the spec with `blocked_condition: "discovered work: <slug>"`; running tasks finish their gates, and nothing new launches or merges. **00.22** presents every blocker that has arrived in one call (problem, evidence, assessment, recommendation), together with the batched question and the assumptions not yet offered. **00.23** the stakeholder may overrule the assessment. **00.24** Yes sends the spec to discovery (`blocked` → `draft`, the problem is the first frontier question); No leaves it `blocked` until a human resolves it. Overruled to not a blocker, it is kept (00.26) or dropped. **00.28** restores the status in `blocked_from` and the work continues unchanged.

The `to ask` path: **00.25** asks one question over every waiting item at the next blocking ask the session makes (a 00.22 presentation, a questioning round, the breakdown quiz, a `hitl` pause), or at the sign-off ask (5.5) at the latest. Each item is folded in (a scope change through 5.6 or the next round), kept for later (00.26) or dropped. **00.26** matches a kept item by concept against the shelf and every open backlog line: a shelf match gets one Later requests line, a match on this spec's list adds nothing, and no match appends a `B<n>` line to this spec's list, **00.27**. A shelf file is written only when the stakeholder asks for one.

**The size budget is not discovered work.** It is never asked and never blocks: a breakdown predicted over it gets a split proposal in the 2.1 breakdown quiz (split pieces become `budget-split` backlog lines through 00.26; kept as one spec, 2.5 raises the budget), 2.6 runs only the predicted check and returns to that quiz when over, and an overrun at 3.15 is logged once and reported at sign-off (5.4).

**Backlog versus shelf.** The shelf, `.workflow/deferred/` (00.8–00.10), holds work ruled out of scope during discovery (0.3.17), suite gaps (3.14), and items the stakeholder explicitly asked to shelve. The backlog, `.workflow/specs/work-backlog/` (00.27), holds work found while building that the stakeholder kept for later. A backlog line becomes a spec when sign-off starts it at 5.9 or the stakeholder picks it later: the new spec's 0.1.4 records `origin:` and marks the line `promoted`.

## Model selection

Fourteen nodes are sub-agent launches: 0.2.4, 0.2.5, 0.3.10, 0.4.6, 1.2, 1.3, 3.2, 3.3, 3.7, 4.1, 4.2, 4.3, 4.10 and 6.4. `standards-discovery` is launched outside the flow and resolves its model the same way. The orchestrator writes each launch as a header plus a task body that carries only what the agent's definition lists. The pre-launch hook (00.12) calls `resolve-launch.sh`, which validates the header and returns the profile text and the model from the task type's row in `.workflow/model-map.yaml` for this host (D123). A missing row or host value denies the launch at 00.14: the stakeholder picks a model, it is recorded as that row, and the launch is retried. There is one model source: no precedence levels, no model in the agent definitions and no per-project override file. Rows hold tiered aliases per host, never dated version ids (D23). On Codex the orchestrator runs `resolve-launch.sh` itself and spawns with its model and prompt (D9, D67). The tool audit (3.5) is not a launch; it is a command run.

## The questioning loop

*(Matt Pocock, grilling; defer-to-deep-dive is ours.)* Nodes 0.3.8–0.3.19. Gates that route back into 0.3.8: 0.4.7, 0.6, 2.2, 2.3, 4.5, 4.6, 5.6 and 00.24. Loop-backs skip 0.3.22, which runs on first entry only (D73). One pass computes the frontier, asks all of it in one round with recommended answers and a defer option, processes the answers, and recomputes or exits. A small request usually needs one round, with the 0.3.19 summary as its last question (D122).

## Sizing

*(BMad.)* Trivial (0.0.1): no workflow. Light path (0.3.20): three facts clean (no intent gaps, no irreversible actions, a small footprint). It writes a one-task `tasks.md` and its task file (D14, D85), creates the spec branch and spec worktree, and goes straight to 3.1 with the suites that exist. It takes one questioning round unless a question stays open, the combined review at 4.10, a five-line report, and the retrospective inside the sign-off ask (D122). A suite that does not exist yet skips only its own gate and is recorded as a gap (3.13–3.14; D29, D60). Full path: everything else. Large path: a spec the questioning loop finds is several features converts into an initiative at 0.3.23. Both spec paths carry a soft size budget (D58), written to `spec.md` with `tasks.md` (2.5, or 0.3.20) and checked at 2.6 and after each wave at 3.15.

## The four gates of Phase 3

Phase 3 has four gates, cheapest first. **3.6 asks whether the tools object**: lint, type-check, format, import boundaries and the task's scoped tests, enforced by the stop audit before the implementer can finish (D19). **3.8 asks whether the work follows the profile** in the ways only a reader can tell, and whether names and comments meet R1–R5. **3.9 asks whether the code is correct**: the whole harness on the merged spec branch, with unfinished tasks' tests excluded until the last wave. **3.11 asks whether the feature works**: the browser suite drives the journeys. A 3.9 or 3.11 failure after a task is `done` reopens it (D59).

## Review: lenses, then triage

*(Lenses from Matt Pocock; triage, routing and the third-pass rule from BMad.)* Three independent lenses (4.1–4.3) on the full path, one combined review (4.10) on the light path (D118); finding-level triage (4.4); routing to patch, decision needed, discovered work, proposal or none (4.5); the third-pass rule (4.6); the ceiling of five reworks (4.7); the gaps line (4.8).

---

## Persistent artifacts (00.x)

### Tier A: authored

**00.1 — `.workflow/GLOSSARY.md`: canonical terms** *(Matt Pocock)*
Glossary only. Its term list is read at 0.2.1; single entries are read by term. Written inline at 0.2.3, 0.3.15 and 0.4.3 through `domain-modeling`, and at 5.3. The naming baseline for 4.1 and 4.10.

**00.2 — Capabilities index**
What the system does for users, one entry per capability with a stable id. Read at 0.3.1. Grows at 5.3.

**00.3 — Rules**
Project-wide standing constraints the code cannot express. Read at 0.2.1 and 0.3.3 (ownership), 0.3.20 and 2.4 (shared core), 4.1 (conformance). The Ownership and Shared core blocks generate the import-boundary config (D15, D20), so module boundaries are enforced at 3.5 rather than reviewed at 4.1. Changed only at 5.3.

**00.4 — Decision log: ADRs, pitfalls, retrospective lessons, review lessons** *(ADRs from Matt Pocock)*
Rationale and lessons. Written at 0.3.7, 5.3 and 5.7. Read by `retrieval` (0.2.4) and by the standards lens (4.1) or the combined review (4.10), which check the change against the recorded review lessons, pitfalls and retrospective process lessons (D118). Holds no feature status (D22).

### The shelf

**00.8 — `.workflow/deferred/` file** · **00.9 — Mark superseded and archive** · **00.10 — `.workflow/deferred/archive/` file**
One file per shelved concept, written so a fresh agent can act on it later, with a back-link to its originating spec. Read by `retrieval` at 0.2.4 of every later feature. Archived when a spec takes it up (0.1.5, or a shelf match at 0.2.6). Written and archived by the `deferred-handoff` module (D24).

### Model table

**00.11 — `.workflow/model-map.yaml`** · **00.12 — Pre-launch hook** · **00.13 — Model for this host?** · **00.14 — Assign a model**
One row per task type: tier, a model alias per host, why, and dated observations (D123). Read only by the launcher. Seeded by `project-setup`, written at 00.14 when a launch is denied for a missing value, and given observation lines by the retrospective at 5.7. The table never enters a sub-agent's context (D13). ~~**00.15 — Will this sub-agent launch sub-agents?**~~ Removed (D32).

### Work profiles

**00.16 — `.workflow/profiles/TEMPLATE.md`**
The fixed shape every profile follows. It is the contract between project setup and the flow: 00.20 injects its sections, 3.5 runs its toolchain, 3.7 checks its checklist.

**Project setup** *(outside this flow; the `project-setup` skill)*
Fills the template once per work type, starting from the shipped examples where they fit (D26). 00.19 is the in-flow fallback when setup missed a work type.

**00.17 — Work profile**
One file per work type. The operating context for every coding agent doing that kind of work. Injected whole (00.20); the source of the toolchain at 3.5; the checklist for 3.7; one baseline for 4.1; read by 2.1, because file locations constrain how slices are cut; read at 0.2.5 to decide whether library evaluation runs.

**00.18 — Task matches a work profile?**
Checked for each coding launch by the pre-launch hook, using the work type recorded on the task at 3.1 (or passed explicitly in Phase 1). A task that fits no profile is a finding: the task is badly cut, or a work type is missing.

**00.19 — Define the missing profile**
The main session creates the new profile with the human; the launch waits. With no human available, the spec is `blocked`.

**00.20 — Inject the profile**
The one place a Tier A document enters a sub-agent's context whole. The hook inserts it after the launch header (D33); on Codex the orchestrator builds it into the launch. Whole for 1.2, 1.3, 3.2 and 3.3; the checklist section only for 3.7.

### Discovered work

**00.21 — Block** · **00.22 — Present** · **00.23 — Blocker?** · **00.24 — Back to discovery?** · **00.25 — Batched ask** · **00.26 — Add the backlog line** · **00.27 — Backlog list** · **00.28 — Resume**
See the Discovered work section above. Every report gets exactly one design-log record: an Unproven line, a Discovered work entry with its ruling, or a duplicate line; current work is recorded by its fix round or triage row.

---

## Intake (0.0.x)

**0.0 — Feature request** · **0.0.1 — Trivial edit the stakeholder will review themselves?** *(BMad)* · **0.0.2 — Edit directly; no workflow**

Entry is the `feature-workflow` router, which first finds the state (an initiative, a spec, a resume offer, open backlog lines) and then sizes new work (D3, D27). Light versus full path is decided at 0.3.20, never at intake.

---

## Phase 0 — Discovery

### 0.1 — Initialise the feature folder

**0.1.1 — Scan the specs folder** *(Spec Kit)*: `next-spec-number.sh` prints the next number, or the new tracker issue's number. · **0.1.2 — Derive a slug** *(Spec Kit)* · **0.1.3 — Create the feature folder** · **0.1.4 — Write spec.md** *(fields, ids and single writer from BMad)*: status `draft` and `tracker_issue`; a spec seeded from a backlog line also records `origin:`, writes an Origin entry and marks the line `promoted`. · **0.1.5 — Came off the shelf?** A clear match is assumed and logged; `deferred-handoff` archives the shelf file. · **0.1.6 — Draft the goal**

### 0.2 — Retrieve existing system context

**0.2.1 — Identify the affected area**: modules and paths from the Ownership block, and the glossary term list. · **0.2.2 — Term gate**: clear terms are assumed and logged; `retrieval` (and `library-evaluation` when needed) launch in the same message as the ask, with the raised terms marked proposed. · **0.2.3 — Agree definition**: only an open term is asked. · **0.2.4 — Retrieve context** (sub-agent: the code, Tier A decisions and rules, and the shelf; extracts only) · **0.2.5 — Evaluate libraries** (sub-agent, conditional, D119: only when the request names a library, SDK or external API the project does not use yet, or a concern has no approved library in the work profile; otherwise `codebase-map.md` says `Not evaluated:` and why, and a later answer that brings in a library launches it then) · **0.2.6 — Write codebase-map.md** from the returns only; a shelf match it reports is assumed when clear.

### 0.3 — Frame the problem

**0.3.1 — Capability already exists?** (00.2) · **0.3.2 — Reframe** · **0.3.3 — Owning module clear?** (00.3) · **0.3.4 — Resolve placement** · **0.3.5 — Conflicts with an ADR or rule?** (a rule conflict becomes a 5.3 proposal) · **0.3.6 — Conform or supersede** · **0.3.7 — ADR** (through `domain-modeling`; a placement that fails the three-part test goes in `design-log.md`, D43) · **0.3.22 — Deeper prompt** (the `deeper-prompt` skill, first entry only; its agreement and its downstream, tools and gotchas questions ride on the first 0.3.11 ask; D73) · **0.3.8 — Compute the frontier** · **0.3.9 — Any answerable?** · **0.3.10 — Look up facts** (sub-agent) · **0.3.11 — Ask the round**: the whole frontier in one round; before it, the lookups and, when the footprint is plainly too big for the light path, the module audit are launched (D116) · **0.3.12 — Any deferred to deep dive?** · **0.3.13 — Deep dive** · **0.3.14 — Term gate** · **0.3.15 — Agree definition** · **0.3.16 — Outside agreed scope?** · **0.3.17 — Write the deferred handoff** (`deferred-handoff`; adds the file to `deferred` and Non-goals) · **0.3.18 — Questions remaining?** · **0.3.19 — Confirm or revise the goal**: the summary rides on the last round; writes `spec.md` with `light_path` and fills the tracker issue · **0.3.23 — Convert a spec into an initiative** (several features: the large path takes the design log into a new initiative on its own branch, deletes the draft spec folder and continues at 6.1) · **0.3.21 — design-log.md** · **0.3.20 — Light-path test** *(BMad)*: a pass writes the budget, the one-task `tasks.md` and its task file, creates the spec branch and spec worktree with `spec-worktree.sh`, files the task's tracker issue and sets `ready-for-dev`; a fail continues at 0.4.

### 0.4 — Model the impact (full path)

**0.4.1 — Map onto schema and interfaces** · **0.4.2 — Term gate** · **0.4.3 — Agree definition** · **0.4.4 — Classify the changes**: create, extend, refactor, unchanged · **0.4.5 — Write data-model.md** *(Spec Kit)* · **0.4.6 — Audit the owning module** (sub-agent; reuses the audit launched beside the first round unless the design changed; its out-of-scope lines go through the scope gate) · **0.4.7 — Conflicts with goal or placement?**

### 0.5 — Define the end state

**0.5.1 — End state as testable objectives** · **0.5.2 — Name the journeys** · **0.5.3 — Fixtures and reference systems** · **0.5.4 — Write verification-plan.md**

### 0.6 — Exit gate

**0.6 — Exit gate**: scope, system impact, data changes and testable objectives, each checked in a named file. Clear sets `ready-for-dev` and fills the tracker issue; not clear loops back to 0.3.8. The run continues into Phase 1 without asking; a handoff is offered only when the session is long (D107).

---

## Phase 1 — Verification setup *(PROJECT_BRIEF)*

**1.1 — Measurable targets**: on the full path, creates the spec branch `spec/NNN-slug` and its spec worktree with `spec-worktree.sh`, moves the session in, and records `spec_branch` and `baseline_revision` (D53, D85, D111). Then fills the Targets table; a threshold the spec does not give is assumed and logged. A spec with no new capability and no new suite runs **tests in tasks**: 1.2 and 1.3 are skipped, the tasks write their tests test-first, and 1.4 runs once on the merged last wave. · **1.2 — Harness and CI** (an `implementation` launch under the `test-harness` profile, in its own agent worktree; the breakdown quiz is asked while it runs) · **1.3 — Browser suite** (under `e2e-browser`, after the 1.2 merge, with one test per journey and a fault switch) · **1.4 — Suites fail a known-bad build?** Every new test must fail on an assertion against the baseline; the browser suite also under an injected fault; StrykerJS is optional (D63). No → back to 1.2 or 1.3; cannot be made to fail → `blocked`. · **1.5 — Record the suites** in `verification-plan.md` and commit Phase 1 on the spec branch, which is red by design until the last wave (D85).

The Phase 1 builds pass `work_type` explicitly in the header, the one exception to looking it up by task id (D14). Their stop audit skips `test`, since the new tests are red by design (D70). Each result is checked with `check-task-result.sh` and merged after `check-merge-artifacts.sh`.

---

## Phase 2 — Task breakdown

**2.1 — Split into vertical slices** *(Matt Pocock)*: each slice in one module, with predicted files, a size (S, M or L; L is a split signal) and a mode (`afk` or `hitl`); a predicted-file overlap within a wave becomes an edge unless the stakeholder approves `parallel_with`. The quiz shows the waves table, carries 2.2, offers the assumed 2.3 seams for veto, proposes a split when the draft is predicted over the size budget (never asks the budget itself), and is a blocking ask, so it also carries the batched discovered-work question. · **2.2 — Specifiable?** (No → `draft`, back to 0.3.8) · **2.3 — Interfaces under test agreed?** (seams assumed and logged; No → `draft`, back to 0.3.8) · **2.4 — Modifies shared core?** (a request for `integration`) · **2.5 — Write tasks.md**: the project-default budget into `spec.md` (raised when the quiz kept an over-budget breakdown as one spec), one task file per slice, the index, every Phase 1 test assigned to exactly one task, and the waves from `task-waves.sh` · **2.6 — Within the size budget?** (task count and predicted files, `budget-check.sh --predicted`). Yes → file each task's tracker issue, then commit the breakdown on the spec branch. No → back to the 2.1 quiz with a split proposal, never a block.

---

## Phase 3 — Implementation

**3.1 — Classify tasks and start** *(PROJECT_BRIEF; classification is ours)*
Records each task's work type through `set-task`, sets `in-progress`, moves the tracker issue, and records `impl_base_revision` (and, on the light path, `baseline_revision`). Then the wave loop runs, per wave: 3.2, the wave start (a task branch and worktree per task off the spec-branch tip, `.workflow/.worktrees/<task_name>`), 3.3, the gates 3.4–3.8, 3.16, 3.15, 3.13 and 3.9.

**3.2 — Integration batches**
Shared-core change requests from the wave's tasks, grouped one work type per batch, each launched in its own integration worktree and merged before the wave launches (D28).

**3.3 — Launch the wave** *(Matt Pocock, tdd)*
One `implementation` agent per frontier task, in the background, in its task worktree, under the injected profile. A `hitl` task is asked about after the rest of the wave is launched. Nothing new launches while the spec is `blocked`.

**3.4 — Negative and edge-case tests**
Read from `tests_added` in the result file the implementer wrote, after `check-task-result.sh` checks it (D97). The implementer's own self-review is in the same file (D104).

**3.5 — Run the toolchain**
A command run, not an agent. The stop audit runs `run-toolchain.sh --reuse` in the task worktree: `lint`, `typecheck`, `format`, `boundary` and `test`, never `serve`, with `test` scoped to the task's own and changed suites (D92). A passing record for the same tree is reused (D91). A key that still reads `TODO:` stops with the key named, and the main session may fix it in the profile on the spot (D126).

**3.6 — Tool audit clean?**
No → back to the same agent with the tool output. Yes → 3.7. No agent looks at the diff until this is yes.

**3.7 — Mini-review**
A `profile-mini-review` launch over the task's diff, judging the profile's checklist and the readable-code lines R1–R5 (D86, D120), with the 3.5 output attached. It writes `mini-review.yaml` itself and lists every readable-code breach in one pass, each with its exact fix: the comment to delete, the replacement text, or the new name. Every launch is a full review. Its out-of-scope lines go to discovered work.

**3.8 — Mini-review passes?**
When every failing item is a readable-code or wording fix, the orchestrator applies the listed fixes itself, reruns the toolchain when a name changed, and commits; there is no relaunch and no re-check (D120). A behaviour fix is a fresh launch followed by a full review. Five rounds per task at most.

**3.16 — Merge the wave**
Once every task in the wave has passed 3.8, in task-id order: a task PR/MR per `task_review` (`pr` by default, non-blocking; `pr-blocking` waits; `local` none), the artifacts gate, a `--no-ff` merge into the spec branch, the task set `done` and its tracker issue moved, the task branch and worktree removed, then the wave's workflow data committed (D85, D112). Held while the spec is `blocked`.

**3.15 — Within the size budget?**
After each wave's merges, `budget-check.sh` counts the changed files a reviewer of the feature's PR would see since `impl_base_revision`, tests apart (D85, D87). No → a Size budget overrun entry, once per spec, and the build goes on; sign-off reports the figures (5.4).

**3.13 — Both suites exist?**
Always yes on the full path. On the light path, a missing suite skips only its own gate.

**3.14 — Record the suite gap**
Light path only. Each missing suite is recorded on the shelf (a Later requests line when the project already has a file for that gap, else a new file through `deferred-handoff`) and under Known gaps in `spec.md`. With neither suite, sets `in-review`. Never reported as a pass.

**3.9 — Tests pass and CI green?**
The whole harness on the merged spec branch, through `run-toolchain.sh --exclude-unfinished --reuse`. Before the last wave it passes when nothing that passed at `impl_base_revision` regressed and every `done` task's tests pass; after the last wave everything must pass, after the deferred 1.4 check when Phase 1 ran as tests in tasks. No → the task is reopened.

**3.10 — Run the browser suite**
On the merged spec branch after the last wave, from the command in `## Suites`.

**3.11 — Journeys pass?**
Yes sets `in-review`. No reopens the task serving the failing journey.

**3.12 — Run artifacts** *(PROJECT_BRIEF)*
Filed by `evidence-capture` after each browser-suite run.

Before Phase 4, leftover agent worktrees are removed and the workflow data is committed.

---

## Phase 4 — Review and triage

**4.1 — Standards review** *(Matt Pocock)*
The whole change since `baseline_revision` against the rules, the profiles, the placement ADR, the glossary, the readable-code baseline, the Fowler smell baseline, and the project's recorded review lessons, pitfalls and retrospective process lessons (D118). Uses the 3.5 output and does not re-lint. Proves each finding with a reproduction or a quoted line, and writes its pass file itself (D93, D103).

**4.2 — End-state review** *(Matt Pocock)* (missing, unasked-for and wrong, each quoting the spec line) · **4.3 — Targets review** (starts the build with `serve`, measures each target, always stops it; D62, D94) · **4.10 — Combined review** (light path: one `review-combined` launch in place of 4.1 and 4.2, covering end state, standards and lessons; no targets, since there is no `verification-plan.md`) · **4.4 — Triage findings** *(BMad)*: each pass file checked with `check-review-findings.sh`; settled rows carried; proof checked; the claim verified at its location; one verdict (`high`, `medium`, `low`, `false`, `unproven`); noise dismissed with a reason, except that a proven R1 or R3 breach is never noise · **4.5 — Route findings** *(BMad)*: patch, decision needed (→ `draft`, back to 0.3.8), discovered work (→ the assessment), proposal (a `proposals.md` row for the 5.5 ask) or none · **4.6 — Third pass with findings?** *(BMad)*: a pass numbered 3 or more with a verified high patch sets `followup_review_recommended` and `draft`, back to 0.3.8; a further pass runs only after a high-severity patch · **4.7 — Rework attempts remaining?** (max 5): when every patch is a readable-code or low wording fix, the orchestrator patches it directly and the rework count is untouched; otherwise Yes reopens the owning tasks through the wave loop. No applies the readable-code patches, then sets `blocked` only when verified high findings are open; the rest go to discovered work and become known gaps at 5.1 (D48). · **4.8 — Record the gaps**: runs before every exit; writes one `Gaps:` line under the pass in `design-log.md` (unverifiable requirements and unmeasured targets) and no file. A gap one command can settle is settled now. 5.4 reports the gaps.

---

## Phase 5 — Sign-off

The steps run in the order 5.1, 5.2, 5.4, 5.5, then 5.3, 5.9, 5.7, 5.8. Everything before 5.5 prepares the one sign-off ask; everything after it applies the answers and asks nothing (D113, D114).

**5.1 — Reconcile spec.md**
Makes `spec.md` describe the feature as built. A spec that arrived `blocked` from 4.7 moves to `in-review`, and every open finding becomes a known gap (D47).

**5.2 — Propose Tier A updates**
Rows in `proposals.md`: capabilities, rules, decisions, pitfalls, profile changes and tool rules, each with why an agent would act differently without it, plus a `pr_template` row when a host PR template exists and none is set.

**5.4 — Report**
`report.md`, with every claim backed by evidence: the harness through `run-toolchain.sh --reuse`, targets against measured, journeys, the review outcome, known gaps and open items; five lines for a one-task spec. Then `pr-body.md` is filled from the chosen template and checked with `check-pr-body.sh`.

**5.5 — The sign-off ask**
The retrospective drafts its verdict and numbered lessons first, into `retrospective-draft.md`. Then one call asks, after the assumptions not yet offered for veto: approve the work and the PR description; approve every proposal or name exceptions; one question over the waiting discovered-work items and the open backlog lines (fold in, keep, drop, start next, or move to the shelf); and record the drafted lessons or name exceptions. A follow-up is asked only to confirm wording the main session had to write. Yes with nothing folded in → 5.3. No, or an item folded in → 5.6.

**5.6 — Re-enter on a change request**
Logs the request with `Outcome: loop back (5.6 change request)`, sets `draft` and returns to 0.3.8 with the request as the first frontier question. Nothing approved at 5.5 is applied; the answers are offered again next time. Also offered at session start by `session-start-resume`.

**5.3 — Apply the approved proposals**
Writes each approved or modified row to Tier A, the profiles or the lint config, assigns real `CAP-###` ids and replaces every `CAP-NEW-<slug>` (D44, D52), and reruns the harness after a rule or profile change. A `rules.md` change regenerates the boundary config (D20).

**5.9 — Carry out backlog rulings**
Applies each 5.5 ruling: keep (00.26 adds the line), drop (the line is deleted), start it (discovery 0.1 seeds a new spec, whose 0.1.4 marks the line `promoted`), or move it to the shelf when the stakeholder asked (D57, D105).

**5.7 — Retrospective** *(BMad)*
`move-to-done.sh --check` confirms every task and backlog line is closed. The `retrospective` skill finishes the draft without asking: it moves it into `.workflow/decisions/retrospectives/`, writes the approved process lessons, pitfalls and review lessons, feature notes in `design-log.md`, and model observations as dated lines in `.workflow/model-map.yaml` (D25). An accepted verdict sets `done`, from `in-review`.

**5.8 — Merge and close**
Commits what is left, fills the tracker issue, checks `pr-body.md`, runs `move-to-done.sh` to move the spec into `.workflow/specs/done/` (deleting `.step` and rewriting the spec's path), then publishes without a second ask: a PR/MR with `pr-body.md` as its description, or a local merge whose message holds it. Once merged it moves the tracker issue to done and removes the spec worktree and spec branch with `spec-worktree.sh remove`. A spec emitted by an initiative then runs the 6.13 check.

---

## Phase 6 — Large path

Plans one **initiative**, a subject too large or too uncertain for one spec, in rounds across sessions. It plans and never builds: each settled **slice** leaves as an ordinary spec that runs the light or full path on its own. Its folder is `.workflow/initiatives/NNN-slug/` on the branch `initiative/NNN-slug`; its status, step marker, slices and questions change only through `initiative-transition.sh`. Its steps are counted on their own, not as a phase of a spec.

**6.1 — Enter the initiative** (from 0.3.23, or from the router or the resume offer; reads the status where the initiative lives and switches to its branch; writes `initiative.md` at conversion)

### The round

**6.2 — Write back research** (each `researching` question with a returned agent is settled; the rest go back to `open`) · **6.3 — Compute the frontier** (open questions whose dependencies are settled, or whose spec dependencies are `done` on main) · **6.4 — Launch research and fact lookups** (one `research` agent per research question; one `fact-lookup` for decision questions a repo fact answers) · **6.5 — Ask the round** (every decision question on the frontier in one round, as at 0.3.11) · **6.6 — Term gate** (the only step where the large path writes the glossary) · **6.7 — Plan the slices** (slice records in `initiative.md`) · **6.8 — Log and commit the round** (appends the round to the design log, commits on the initiative branch, then routes: emit, next round, or planned)

### Emission

**6.9 — Emit a settled slice** (once its questions are settled and the stakeholder confirms: discovery 0.1 seeds a new spec from the slice; `initiative.md` records it as `emitted`)

### Planned and merged

**6.10 — Mark the initiative planned** (every slice emitted or done, no question open or researching) · **6.11 — Merge into main** (a PR/MR per `task_review`, or a local `--no-ff` merge) · **6.12 — Reopen exploration** (a `planned` initiative back to `exploring` on a fresh branch) · **6.13 — Close when every spec is done** (every emitted spec `done` on main, at the top level or in the Done folder: slices and initiative set `done`, merged as at 6.11)
