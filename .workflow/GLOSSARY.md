# llm-scaffold

An agent-agnostic scaffold for coding-agent skills and hooks, living in `.agents/`. This glossary holds the workflow 2.0 vocabulary.

## Language

### Project knowledge

**Tier A**:
Authored project knowledge that cannot be derived from code: `.workflow/GLOSSARY.md`, capabilities, rules, the decision log, the review lessons and the work profiles, all under the target's `.workflow/` folder. The source of truth; agent-proposed, human-approved.
_Avoid_: Docs, wiki

**Tier B**:
Generated caches of facts derivable from code (module map, flow diagrams, architecture structure). Stamped with a commit, never hand-edited, never the source of truth.
_Avoid_: Generated docs, index

**Cache stamp**:
The commit a **Tier B** cache was derived from, plus the paths it covers. A cache is stale when any covered path changed since that commit.
_Avoid_: Cache timestamp, cache version

**Graph extractor**:
The per-language tool that reads a scope's source files and outputs the file graph (files, their import or `source` edges, and candidate entry points) that the **Tier B** caches are built from. Each **work profile** names one with `graph_extractor`: `dependency-cruiser` for JS/TS, `bash` for shell scripts, or `none`. Not the boundary-config adapter, which generates lint config from `.workflow/rules.md`.
_Avoid_: Extractor, parser, cache adapter

**Placement ADR**:
The decision record that says which module owns a change and why, written before requirements are settled.
_Avoid_: Placement note

**Term gate**:
A point in discovery where a new or ambiguous term must be agreed with the stakeholder and written to `.workflow/GLOSSARY.md` before work continues.
_Avoid_: Naming check

**Deferred handoff**:
Shelving an out-of-scope item as one file in `.workflow/deferred/` with a back-link to its originating spec, so a later feature can pick it up.
_Avoid_: Parking lot, TODO list

**Review lesson**:
A lesson a retrospective recorded for the Phase 4 review: a symptom to look for in a set of paths, with the spec it came from and the date, one entry per lesson in the project's review-lessons file (**Tier A**). The review-lessons lens checks every change against them. A lesson a rule, a lint or a profile checklist line already enforces is not one.
_Avoid_: Pitfall, watch item, recurrence check, review rule

**Term list**:
The canonical term names from a glossary, without their definitions, printed by a script and loaded in place of the whole glossary. A definition is looked up by name only when a term in play matches one on the list.
_Avoid_: Glossary index, term map (clash with the glossary map)

### Work classification

**Work type**:
The kind of work a task is (for example frontend or test harness). Each work type has one **work profile**.
_Avoid_: Task category

**Work profile**:
The per-work-type file of operating instructions for coding agents: file locations, approved libraries, language rules, toolchain commands and a mini-review checklist. Injected whole into the agent's launch.
_Avoid_: Persona, config

**Task type**:
The kind of sub-agent a launch runs, one per agent definition: retrieval, library-evaluation, cache-regeneration, fact-lookup, module-audit, implementation, integration, profile-mini-review, review-standards, review-end-state, review-targets, review-lessons, standards-discovery. Not the same as **work type**.
_Avoid_: Agent role

**Model map**:
The project-owned table that assigns a model tier and host model alias to each **task type**. Lowest-precedence source: agent overrides and the agent definition win over it.
_Avoid_: Model config

**Launch header**:
The fenced YAML block at the start of every sub-agent launch prompt, naming the **task type** and the fields that type requires.
_Avoid_: Prompt preamble

### Flow

**Router**:
The feature-workflow `SKILL.md`: it finds the feature's state, sizes a new request and loads the one **Step file** the spec's status and **Step marker** name. It holds no phase logic.
_Avoid_: Entry skill, dispatcher, main skill

**Step file**:
One file of feature-workflow steps that the **Router** or another step file loads when the work reaches those steps, read whole and followed. A file split into parts gives several step files.
_Avoid_: Module, phase module, stage file

**Workflow conventions**:
The rules every **Step file** follows for status changes, the **Step marker**, guarded writes, the **Progress line** and sub-agent launches, kept in one file that the **Router** and the step files point to.
_Avoid_: Common rules, shared rules (clash with shared core)

**Light path**:
The short route for a small, clear request: three facts clean (no intent gaps, no irreversible actions, small footprint) lead to a one-task plan and straight to implementation against the existing suites.
_Avoid_: Fast track, quick mode

**Full path**:
The complete route for any request that does not qualify for the **light path**: discovery, verification setup, task breakdown, implementation, review and sign-off.
_Avoid_: Heavy path, medium path

**Large path**:
The planning route for a request whose route is unknown at intake, or that discovery finds is several features: it explores and settles the subject across sessions and emits several ordered specs, each of which then takes the **light path** or the **full path**. It plans; it never builds. A large but well-understood change stays on the full path.
_Avoid_: Epic mode, roadmap mode, planning mode

**Initiative**:
The planning unit a **large path** creates: the subject's goal, its exploration record (what is known, unknown and decided) and the ordered specs it emits. An initiative plans; its specs build.
_Avoid_: Epic, map, program, roadmap, theme

**Slice**:
A planned part of an **initiative** that becomes exactly one spec once its questions are settled and the stakeholder confirms it. A slice is not a spec until it is emitted.
_Avoid_: Child spec, sub-spec, stream, planned spec

**Initiative question**:
One recorded uncertainty inside an **initiative**: a research question that agents answer, or a decision the stakeholder makes. It may depend on other questions or on an emitted spec, and it stays open until settled.
_Avoid_: Ticket, decision ticket, research ticket

**Deeper prompt**:
The stakeholder-agreed rewrite of a feature request (the ask one level up, its goals, downstream work, tools and gotchas, scope unchanged) that the questioning loop takes as its input. Produced at step 0.3.22.
_Avoid_: Expanded prompt, pre-grill

**Frontier**:
The open decisions whose prerequisites are all settled, so the questioning loop can ask them now; recomputed after every round and asked together in one round. Implementation waves use the same word for the pending tasks whose dependencies are all done.
_Avoid_: Answerable set, question queue

**Step marker**:
The gitignored per-spec file recording the workflow step the spec is currently at (and, while blocked, where it blocked from). Write guards read it to decide what may be written.
_Avoid_: Progress file

**Progress line**:
The line that leads every orchestrator update to the stakeholder: the phase and the step's position in it, counted on the spec's path (`Phase 1 of 6 · step 23 of 47 — Discovery: Compute the frontier (0.3.8)`). Display only; derived from the **Step marker**, never stored (D84).
_Avoid_: Status line (the host's context bar), progress bar

### Branches and tasks

**Spec branch**:
The branch `spec/NNN-slug` that carries all of one spec's work, created off main at 1.1 (0.3.20 on the light path). Red by design from the Phase 1 commit until the last wave merges; reaches main only through the sign-off PR (D85).
_Avoid_: Feature branch, integration branch

**Task branch**:
The short-lived branch `task/NNN-slug/Tnn-<slug>` one implementer works on, in its own worktree under `.workflow/.worktrees/`, forked from the **Spec branch** tip at wave start and deleted after it merges back (D85).
_Avoid_: Worktree branch, feature branch

**Task file**:
The Markdown file `tasks/Tnn-<slug>.md` that holds one task's body (what to build, seam, acceptance criteria, predicted files, size, mode). The `tasks.md` index holds the task's record; the task file holds what the implementer reads (D85).
_Avoid_: Ticket, task section

**Agent worktree**:
The git worktree under `.workflow/.worktrees/<name>` that the orchestrator creates for one coding launch (a Phase 3 task, a Phase 1 build or an integration batch), named `s<NNN>_t<N>`, `s<NNN>_phase_1_<work type>` or `s<NNN>_integration_<work type>`. The worktree guard confines the agent to it.
_Avoid_: Task worktree (Phase 1 and integration are not tasks), named worktree, isolation worktree (Claude Code's own `isolation: "worktree"`)

**Result file**:
The one YAML file a coding or review sub-agent (implementation, integration, profile-mini-review) writes under `<spec_dir>/artifacts/<id>/` in the main checkout, holding its structured result for the orchestrator to check by script. Not a Phase 4 lens's pass file.
_Avoid_: Return file, output file, result block (the block is its content)

**Done folder**:
The folder `.workflow/specs/done/` that a spec moves into once its sign-off PR has merged, with the spec and every task record marked complete. Keeps the top level of `.workflow/specs/` to specs still in flight; a spec in it is read as context only and its number is never reused.
_Avoid_: Spec archive, closed specs, z_ prefix

**Sign-off PR**:
The one PR/MR that merges a **Spec branch** into the main branch, opened at sign-off (5.8). Its description follows the **PR template**. Not a task PR, which only records a **Task branch** merging into the spec branch.
_Avoid_: Feature PR, merge PR, final PR

**PR template**:
The fixed sections a **Sign-off PR** description must fill: link to issue, what changed, why the change, why this approach, things to note, step-by-step test instructions, **Blast radius**, risk and reversibility scores, the areas and seams that changed, and how to undo the PR. Each section is filled from evidence in the spec folder, not claims.
_Avoid_: PR description template, PR body format, MR template

### Scope control

**Blast radius**:
Everything outside the changed files that a change can affect if it is wrong: the modules and scripts that call the changed code, the steps that run it, and the target projects that install it. Reported in the **PR template** so a reviewer knows where a failure would show up.
_Avoid_: Impact area, footprint (the light-path test's size measure)

**Discovered work**:
Work found outside a spec's agreed scope while the feature is under way. Agents report it and never fix it; a blocker is ruled on by the user before anything continues, and a can-wait item is filed to the **Work backlog** without a ruling and offered at sign-off.
_Avoid_: Scope creep, side quest

**Work backlog**:
The project-level folder of small work items created from discovered work that is not a blocker: filed without a ruling, or chosen by the user as a next feature, and offered at sign-off.
_Avoid_: Deferred shelf, issue tracker

**Size budget**:
The soft limit on a spec's task count and changed-file count. The changed-file count is the review load of the feature's PR/MR: files a reviewer sees against the main branch that changed since Phase 3 began, minus tests. Crossing it stops the work for a ruling: split, re-scope or approve the overrun.
_Avoid_: Quota, cap

## Relationships

- A **Work type** has exactly one **Work profile**; a launch's **Work profile** is chosen from the task's **Work type**.
- A **Task type** is resolved to a model through the **Model map**, using the **Launch header**.
- **Tier B** caches carry a **Cache stamp**; **Tier A** does not.
- **Discovered work** that is not a blocker becomes an item in the **Work backlog**; out-of-scope items found during discovery go through a **Deferred handoff** instead.
- A crossed **Size budget** is handled like **Discovered work**.
- The **Deeper prompt** is the input from which the questioning loop computes its first **Frontier**.
- Each task has one **Task file** and, on the full path, one **Task branch**; every **Task branch** forks from and merges into the spec's one **Spec branch**.
- A **Large path** runs on exactly one **Initiative** and emits one or more specs; each emitted spec takes the **Light path** or the **Full path**.
- A spec whose discovery finds several features converts into an **Initiative**; a **Deferred handoff** item that grows large or unclear seeds one.
- An **Initiative** holds many **Initiative questions** and many **Slices**; each **Slice** becomes exactly one spec, and an **Initiative question** may depend on an emitted spec.
- A **Review lesson** is written by the retrospective of exactly one spec and checked by the review-lessons **Task type** on every later spec's review.
- Each spec has one **Sign-off PR**, and its description follows the **PR template**, which reports the change's **Blast radius**.

## Flagged ambiguities

- "medium path" was used for the **Full path**: resolved, the full path keeps its name; the **Large path** is a planning route, not a larger build route.
- "map" was proposed for the **Initiative**: resolved, "map" already names the codebase map, the **Model map** and the glossary map, so the planning unit is an **Initiative**.
- "module" was used both for a code module that owns paths (`.workflow/rules.md` Ownership) and for a file of workflow steps: resolved, bare "module" means the code module; a file of workflow steps is a **Step file**.
