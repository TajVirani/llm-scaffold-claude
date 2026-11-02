# Discovery impact (Phase 0, after the questioning loop)

The questioning loop returns here at 0.3.20 with `spec.md` settled. Test whether the spec takes the light path; on the full path, model the impact (0.4), define the end state (0.5) and pass the exit gate (0.6). The first half of discovery, 0.1–0.3.7 and 0.3.22, is in [discovery.md](discovery.md). You run in the main session; the corpus (Tier A docs, Tier B caches, the shelf) reaches you only as sub-agent extracts, except the `.workflow/rules.md` blocks a step names (design rule 3). Conventions for status, step markers and guarded writes are in [../references/conventions.md](../references/conventions.md), and launches in [../references/launching.md](../references/launching.md); this step file names the exact calls.

Throughout, `ST` is shorthand for `.agents/skills/feature-workflow/scripts/status-transition.sh`: type the full path every time, because sandboxed projects allow that exact command line. `NNN-slug` is this feature's folder. Keep `spec.md` an index: link the support files, never copy them.

## 0.3.20 Light-path test

The questioning loop evaluated the three facts at 0.3.19 and wrote `light_path` into `spec.md`; at 0.3.20 spec.md is writable only for the size `budget` and `spec_branch`. Read it back:

```bash
yq --front-matter=extract '.light_path' .workflow/specs/NNN-slug/spec.md
```

The three facts (all must be clean for the light path):

| Fact | Clean when |
| --- | --- |
| Intent gaps | Nothing the stakeholder left unsaid that they would notice in the result; **Open Questions** in `spec.md` is empty. |
| Irreversible actions | No irreversible migration, data deletion, destructive external call, or removal of a public contract. |
| Footprint | One owning module, one capability, small: as a rule of thumb about 100 changed lines; more than five files that are not simple or mechanical is not small. Read it from `codebase-map.md`. |

- **`light_path: true` (pass).** Write the size budget, the one-task `tasks.md` index and its task file, create the spec worktree, which commits them on the spec branch, move the session into it, then set the status:

  ```bash
  ST step .workflow/specs/NNN-slug 0.3.20
  # Read the project defaults from .workflow/rules.md "## Size budget":
  awk '/^## /{f=($0 ~ /^## Size budget[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md | yq -o=json '.size_budget'
  # Edit the spec.md frontmatter line to `budget: {max_tasks: <n>, max_changed_files: <n>}` with those values,
  # unless the stakeholder agreed other values (log them in design-log.md). No block in rules.md: keep the template's 10 / 30.
  # Leave status and every other key alone.
  # Write .workflow/specs/NNN-slug/tasks/T01-<slug>.md from ../assets/task.md (what to build, seam,
  #   acceptance criteria from the capability's success line, predicted files, size, mode, notes).
  # Read the Shared core paths, for the task record's touches_core:
  awk '/^## /{f=($0 ~ /^## Shared core[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md | yq '.shared_core.paths'
  # Write the index .workflow/specs/NNN-slug/tasks.md from ../assets/tasks.md with one record:
  #   id: T1, title, status: pending, capability: <the spec's CAP id>, depends_on: [],
  #   touches_core: <true if a touched path is under Shared core>, work_type: null,
  #   module: <owning module>, seam: <interface under test agreed in the loop>,
  #   file: tasks/T01-<slug>.md, branch: task/NNN-slug/T01-<slug>, predicted_files, size, mode, parallel_with: [], pr: null
  # and a one-row Waves table; validate it with the yq validator in ../assets/tasks.md (prints true).
  # Spec branch in its own worktree off the main branch; the first commit carries the spec folder and discovery's other workflow data.
  .agents/skills/feature-workflow/scripts/spec-worktree.sh create .workflow/specs/NNN-slug   # prints `worktree <path>`; a loop-back finds it and changes nothing
  # Move the session into <path> (Claude Code: the EnterWorktree tool with that path; other hosts: reopen the session there).
  # In the spec worktree: Edit the spec.md frontmatter line to `spec_branch: spec/NNN-slug`.
  ST status .workflow/specs/NNN-slug ready-for-dev --step 0.3.20
  ```

  `spec-worktree.sh create` prints `worktree <path>` and `baseline <sha>`; exit 1 names what to fix first, as at [1.1](verification-setup.md#11-measurable-targets-and-the-baseline). T1 gets its task branch and worktree at wave start and merges `--no-ff` at 3.16, as a full-path task does; a `mode: hitl` T1 still gets the 3.3 pause.

  Seeded from a work item: now delete the item (see [Delete a promoted item file](#delete-a-promoted-item-file)).

  If `tasks.md` already exists (a loop-back on a light-path spec), keep it: its task records change only through `set-task`. If the revised goal needs work the existing task does not cover, take the full path instead. Then [offer a fresh session](#offer-a-fresh-session) and load [implementation-setup](implementation-setup.md) at 3.1 (it captures `baseline_revision` and `impl_base_revision` there).

  On the small path: make no fresh-session offer; load [implementation-setup](implementation-setup.md) at 3.1 at once.
- **`light_path: false` (full path).** Continue at 0.4.

## 0.4 Model the impact (full path)

1. **0.4.1 Map onto schema and interfaces.** From `codebase-map.md`, list each entity, field, relationship and interface the change touches.
2. **0.4.2 Term gate.** A new concept with no canonical name → `domain-modeling` for gate 0.4.2 (writes under step `0.4.3`).
3. **0.4.4 Classify** each part `create`, `extend`, `refactor` or `unchanged`. Append an **Impact classification** entry to `design-log.md`.
4. **0.4.5 Write `data-model.md`** from [../assets/data-model.md](../assets/data-model.md): Summary, Entities (GLOSSARY terms, validation rules with the CAP they come from, state transitions), ordered Migrations marked reversible or irreversible.
5. **0.4.6 Launch `module-audit`** on the owning module:

   ````markdown
   ```yaml launch-header
   task_type: module-audit
   spec_dir: .workflow/specs/NNN-slug
   ```

   Owning module: <name>, paths: <owns globs>
   What the feature changes in it: <the 0.4.4 rows for this module>
   ````

   Launch it on your host as [launching](../references/launching.md) says.

   Write its return into `codebase-map.md`: **Module audit** ← its `## Module audit` table; append its **Seams and interfaces (additions)** rows to **Seams and interfaces**; append its **Not found** lines. A `cache disagrees with code` line is a stamp problem: rerun 0.2.7–0.2.8 for that cache, never edit an extract.

   Its **Out of scope noticed** lines are never dropped and never folded into the change: run each one through the Phase 0 scope gate, the 0.3.16–0.3.17 deferred path ([questioning-loop](questioning-loop.md) step 8): [deferred-handoff](deferred-handoff.md#write) **Write** at step `0.3.17` writes `.workflow/deferred/<slug>.md`, adds it to `spec.md` `deferred` and Non-goals, and logs the **Scope decision**, with the line's kind, summary and evidence as the item. A `blocks-this-task` line whose fix the goal cannot do without is not deferred: it is a goal conflict for 0.4.7.
6. **0.4.7 Conflicts with the goal or the placement?**
   - **Goal** → `ST step .workflow/specs/NNN-slug 0.3.8`, load the questioning loop with the conflict as the first frontier question.
   - **Placement** → back to [0.3.3](discovery.md#03-frame-the-problem-placement-first) in discovery with the audit findings.
   - **No** → 0.5.

## 0.5 Define the end state

1. `ST step .workflow/specs/NNN-slug 0.5.1`.
2. Write `verification-plan.md` from [../assets/verification-plan.md](../assets/verification-plan.md):
   - **0.5.1 End state:** binary, observable objectives, each naming the capability it proves.
   - **0.5.2 Journeys:** `JRN-001`, `JRN-002`, ... with steps, expected outcome and the check that will run it (`MISSING` until 1.3 builds it).
   - **0.5.3 Fixtures and oracles:** where test data comes from and how a correct result is known.
   - Leave **Targets** for 1.1.
3. In `spec.md` (step 0.5.1 is still set), write the **Success signal** as the end-state summary and fill **Links**.

## 0.6 Exit gate

All four must be clear, each checkable in a named file:

| Check | Clear when |
| --- | --- |
| Scope | `spec.md` Non-goals and `deferred` list every ruled-out item; Open Questions is empty. |
| System impact | `codebase-map.md` has the module audit; no unresolved `cache disagrees with code`. |
| Data changes | `data-model.md` classifies every touched part and orders the migrations. |
| Testable objectives | Every capability in `spec.md` has an end-state objective and at least one journey in `verification-plan.md`. |

- **Not clear** → `ST step .workflow/specs/NNN-slug 0.3.8`, load the questioning loop with each gap as a frontier question.
- **Clear** → `ST status .workflow/specs/NNN-slug ready-for-dev --step 0.6`; for a spec seeded from a work item, delete the item (see [Delete a promoted item file](#delete-a-promoted-item-file)); then [offer a fresh session](#offer-a-fresh-session) and load verification-setup at 1.1.

## Delete a promoted item file

For a spec seeded from a work item ([discovery](discovery.md#seeded-from-a-work-item)), older item files only: when this spec passes 0.6 (Clear) or the 0.3.20 light-path test, remove the item so no stale copy remains: `rm .workflow/specs/work-backlog/<item file>`. The `origin` key and the design-log Origin entry keep the history. A promoted line stays on its list as the pointer to this spec.

## Offer a fresh session

The spec is `ready-for-dev`, so everything implementation needs is on disk. Load the next module now: the run continues without asking. When this session has looped back to 0.3.8 two or more times, its context is long, so add one line under the progress line of your next update: "This session is long: say *hand off* to continue `NNN-slug` in a fresh session." Then go on; it is an offer, never a question you wait for.

When the stakeholder takes it, load the `handoff` skill and write a handoff for this spec. Then tell them to clear the context (`/clear` in Claude Code) or open a new session and ask to resume `NNN-slug`. On the light path the spec already has its spec worktree (0.3.20), so name it: a new session opened there starts in the spec checkout, and one opened elsewhere moves in first ([Route by status](../SKILL.md#3-route-by-status), "Work in the spec checkout"). On the full path 1.1 creates it. The new session routes by the spec's status and `.step`. Stop here.

## Done

- `spec.md` is `ready-for-dev` (light or full path) and links every support file that exists; on the light path it carries `budget`.
- A spec seeded from an older work-item file has had that file deleted.
- `codebase-map.md` holds the module audit (full path); `design-log.md` holds the impact and scope decisions.
- Light path: `tasks.md` has one valid record with its task file, committed on `spec/NNN-slug`. Full path: `data-model.md` and `verification-plan.md` exist and pass 0.6.
