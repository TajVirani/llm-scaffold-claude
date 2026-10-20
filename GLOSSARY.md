# llm-code-wiki

An agent-agnostic scaffold for coding-agent skills and hooks, living in `.agents/`. This glossary holds the workflow 2.0 vocabulary.

## Language

### Project knowledge

**Tier A**:
Authored project knowledge that cannot be derived from code: `.workflow/GLOSSARY.md`, capabilities, rules, the decision log and the work profiles, all under the target's `.workflow/` folder. The source of truth; agent-proposed, human-approved.
_Avoid_: Docs, wiki

**Tier B**:
Generated caches of facts derivable from code (module map, flow diagrams, architecture structure). Stamped with a commit, never hand-edited, never the source of truth.
_Avoid_: Generated docs, index

**Cache stamp**:
The commit a **Tier B** cache was derived from, plus the paths it covers. A cache is stale when any covered path changed since that commit.
_Avoid_: Cache timestamp, cache version

**Placement ADR**:
The decision record that says which module owns a change and why, written before requirements are settled.
_Avoid_: Placement note

**Term gate**:
A point in discovery where a new or ambiguous term must be agreed with the stakeholder and written to `.workflow/GLOSSARY.md` before work continues.
_Avoid_: Naming check

**Deferred handoff**:
Shelving an out-of-scope item as one file in `.workflow/deferred/` with a back-link to its originating spec, so a later feature can pick it up.
_Avoid_: Parking lot, TODO list

### Work classification

**Work type**:
The kind of work a task is (for example frontend or test harness). Each work type has one **work profile**.
_Avoid_: Task category

**Work profile**:
The per-work-type file of operating instructions for coding agents: file locations, approved libraries, language rules, toolchain commands and a mini-review checklist. Injected whole into the agent's launch.
_Avoid_: Persona, config

**Task type**:
The kind of sub-agent a launch runs, one per agent definition: retrieval, library-evaluation, cache-regeneration, fact-lookup, module-audit, implementation, integration, profile-mini-review, review-standards, review-end-state, review-targets, standards-discovery. Not the same as **work type**.
_Avoid_: Agent role

**Model map**:
The project-owned table that assigns a model tier and host model alias to each **task type**. Lowest-precedence source: agent overrides and the agent definition win over it.
_Avoid_: Model config

**Launch header**:
The fenced YAML block at the start of every sub-agent launch prompt, naming the **task type** and the fields that type requires.
_Avoid_: Prompt preamble

### Flow

**Light path**:
The short route for a small, clear request: three facts clean (no intent gaps, no irreversible actions, small footprint) lead to a one-task plan and straight to implementation against the existing suites.
_Avoid_: Fast track, quick mode

**Full path**:
The complete route for any request that does not qualify for the **light path**: discovery, verification setup, task breakdown, implementation, review and sign-off.
_Avoid_: Heavy path

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

### Scope control

**Discovered work**:
Work found outside a spec's agreed scope while the feature is under way. Agents report it and never fix it; it is ruled on by the user before anything continues.
_Avoid_: Scope creep, side quest

**Work backlog**:
The project-level folder of small work items created from discovered work that is not a blocker and that the user wants as a next feature.
_Avoid_: Deferred shelf, issue tracker

**Size budget**:
The soft limit on a spec's task count and changed-file count. Crossing it stops the work for a ruling: split, re-scope or approve the overrun.
_Avoid_: Quota, cap

## Relationships

- A **Work type** has exactly one **Work profile**; a launch's **Work profile** is chosen from the task's **Work type**.
- A **Task type** is resolved to a model through the **Model map**, using the **Launch header**.
- **Tier B** caches carry a **Cache stamp**; **Tier A** does not.
- **Discovered work** that is not a blocker becomes an item in the **Work backlog**; out-of-scope items found during discovery go through a **Deferred handoff** instead.
- A crossed **Size budget** is handled like **Discovered work**.
- The **Deeper prompt** is the input from which the questioning loop computes its first **Frontier**.
- Each task has one **Task file** and, on the full path, one **Task branch**; every **Task branch** forks from and merges into the spec's one **Spec branch**.
