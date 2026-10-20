<!--
File: Phase 2 module of `feature-workflow` (2.1-2.6): split the spec into vertical slices with predicted files, size and mode, settle file overlaps, write the tasks.md index plus one task file per slice and the spec's size budget, and check task count and predicted files against it.
Triggers/inputs: Handoff from modules/verification-setup.md after 1.5; spec status `ready-for-dev`, on the spec branch. Reads .workflow/specs/NNN-slug/{spec.md, data-model.md, verification-plan.md, codebase-map.md, design-log.md}, .workflow/rules.md (Ownership, Shared core, Size budget), .workflow/profiles/ (File locations), .workflow/GLOSSARY.md.
Outputs/handoff: .workflow/specs/NNN-slug/tasks.md from assets/tasks.md and tasks/Tnn-<slug>.md from assets/task.md, committed on the spec branch, consumed by modules/implementation-orchestrator.md; spec.md `budget` at 2.5. Gates 2.2 and 2.3 loop to modules/questioning-loop.md (0.3.8) with status `draft`. Discovered work at 2.1 and a task count or predicted size over budget at 2.6 go to modules/discovered-work.md (00.21-00.29).
Plan refs: PLAN/decision-flow.mermaid P2 (2.1-2.6); reference "Phase 2 - Task breakdown", "Per-feature files", "Discovered work", 00.3, 00.17, 00.21-00.29; assetlist D14, D15, D16, D28, D44, D45, D49, D56, D58, D68, D85.
Sources: first-party, adapted from mattpocock/skills/skills/engineering/to-tickets/SKILL.md@49dd158 (tracer-bullet vertical slices, prefactoring first, blocking edges, expand-contract for wide refactors, quiz the user until the breakdown is approved, work the frontier, one file per ticket numbered blockers-first and never one combined file), skills/engineering/to-spec/SKILL.md@49dd158 step 2 (prefer existing seams, the highest seam, as few seams as possible; confirm with the user) and skills/engineering/tdd/SKILL.md@49dd158 "Seams" (test only at pre-agreed seams; one line per seam on what it catches and misses) [MIT]; same-wave tasks sharing files get an edge, from open-gsd/gsd-core agents/gsd-planner.md "assign_waves" [MIT, (c) 2026 Open GSD]. to-tickets publishes to a tracker; this module writes the tasks.md index and task files instead. Predicted files, size points, AFK/HITL mode and approved parallel overlaps are first-party (D85). Patterns only; no substantial text copied.
-->

# Phase 2: Task breakdown

You cut the spec into **tracer-bullet** tasks and write them as the `tasks.md` index plus one task file each, every task with its seam, module, predicted files, size, mode and blocking edges. You are done when the stakeholder has approved the breakdown and its waves, every slice is specifiable and has an agreed seam, every predicted-file overlap is an edge or an approved `parallel_with`, `tasks.md` passes the schema validator with a wave for every task and a task file for every record, the files are committed on the spec branch, and the task count and predicted files are within the spec's size budget (or the stakeholder decided what to do about it).

Everything here runs in the main session at spec status `ready-for-dev`. Call the scripts from the project root exactly as written below, with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines; D36). Mark the phase as you enter it (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 2.1`) so a resumed session returns here.

## 2.1 Split into vertical slices

Read `spec.md` (capabilities and constraints), `data-model.md` (what is created, extended or refactored, and the migration order), `verification-plan.md` (journeys), `codebase-map.md` (seams and module findings), the `## Ownership` and `## Shared core` blocks of `.workflow/rules.md`, and the `## File locations` section of each profile in `.workflow/profiles/`. Use `.workflow/GLOSSARY.md` terms in titles.

Draft the slices:

- Each slice cuts a narrow but complete path through every layer it needs (schema, API, UI, tests), is verifiable on its own, and fits one fresh context window.
- One slice works in one module (a key under `modules` in the Ownership block), because one implementation agent owns one module (3.3).
- Respect the profiles' file-location rules, so a slice does not straddle two work types without need.
- Prefactoring comes first: "make the change easy, then make the easy change".
- Migrations follow the order in `data-model.md`.
- A **wide refactor** (one mechanical change whose blast radius spans the codebase) is the exception: sequence it expand, then migrate in batches, then contract, each its own task, each batch blocked by the expand and the contract blocked by every batch.
- Give each slice its blocking edges: the slices that must be done before it can start.
- Name the capability each slice serves: a `CAP-###` from `spec.md`, or its provisional `CAP-NEW-<slug>` (D44). A prefactoring slice names the capability it unblocks.
- **Predict its files**: the repo-relative paths or globs it will create or change, tests included, from `codebase-map.md` and the profile File locations. A Phase 1 harness or suite file counts only when the slice edits it.
- **Size it** from the prediction (D85): `files` (predicted file count), `est_lines` (estimated changed lines) and `points`: **S** up to 5 files and 150 lines, **M** up to 15 files and 400 lines, **L** beyond either or too big for one fresh context window. L is a split signal: propose the split in the quiz; an L slice stays only when the stakeholder keeps it.
- **Set its mode**: `hitl` when it needs a human decision, credential or manual step mid-task (the orchestrator asks before launching it, 3.3), otherwise `afk`. A decision you can settle now belongs in the quiz, not in a `hitl` task.

**Overlaps.** Derive the provisional waves from the edges (a slice with no blockers is wave 1; otherwise 1 + the highest wave among its blockers; 2.5 recomputes them by script), then compare `predicted_files` pairwise (glob intersection) among the slices of each wave. Each overlap becomes an edge from the lower id to the higher, so the two never share a wave, unless the stakeholder approves running them in parallel: then each lists the other in `parallel_with`, they share the wave and are merged in id order (3.16). Recompute the waves after adding edges and repeat until no wave holds an unapproved overlap.

**Discovered work.** Breaking the spec down can surface work the spec did not agree to: a bug in the code a slice would build on, a refactor the agreed slices do not need, a slice that would spread into another module, a decision nobody here can make. Prefactoring the spec's own capabilities need is a slice; anything else is not. Never add it as a slice: load [discovered-work.md](discovered-work.md) at 00.21 with origin node `2.1`, then continue the breakdown after 00.28 (or follow it to discovery).

**Quiz the stakeholder.** Present the breakdown as a numbered list, each entry with title, blocked by, what it delivers end to end, module, seam (2.3), capability and predicted files, followed by the waves table (the `## Waves` table of `assets/tasks.md`: wave, task, size points with files and lines, mode, overlaps and how each was settled). Ask whether the granularity is right, whether each edge genuinely gates its task, whether any slice should merge or split (every L first), whether each `hitl` task really needs a human, and whether any overlap edge may become an approved `parallel_with`. Iterate until they approve. Ask 2.2 and 2.3 in the same rounds, and the size budget for 2.5:

- Propose the project defaults from the `## Size budget` block of `.workflow/rules.md` (D58):

  ```bash
  awk '/^## /{f=($0 ~ /^## Size budget[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md | yq -o=json '.size_budget'
  ```

  No block: propose the `spec.md` template values (10 tasks, 30 changed files).
- The stakeholder may agree other values for this spec; log the agreed budget as a decision in `design-log.md`. A breakdown already over the default is not quietly absorbed: keep the default, and let 2.6 put split, re-scope or approve to them.

**Done when:** the stakeholder has approved the list and the waves table, every slice has predicted files, size and mode, and no wave holds an overlap without an approved `parallel_with`.

## 2.2 Specifiable?

A slice is specifiable when its acceptance criteria can be written from `spec.md`, `design-log.md` and `verification-plan.md` alone, with no decision left open. A slice that needs a decision nobody has made is not.

**No:** set status `draft` (D49) and load `modules/questioning-loop.md`, carrying the open decisions as the first questions of its frontier:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 2.2
```

## 2.3 Interfaces under test agreed?

For each slice, propose its seam: the public interface its tests will drive. Prefer an existing seam to a new one, the highest seam that reaches the behaviour, and as few seams across the feature as possible. Give each proposed seam one line on what it catches and what it misses, and confirm the set with the stakeholder. No test is written at an unagreed seam.

**No** (the seam needs an interface change discovery has not settled): set status `draft` and load `modules/questioning-loop.md` with the seam question:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 2.3
```

## 2.4 Modifies shared core?

Read the shared-core globs:

```bash
awk '/^## /{f=($0 ~ /^## Shared core[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md \
  | yq '.shared_core.paths'
```

A slice that must change a path matching them gets `touches_core: true`, and its task file's **Notes** states the shared-core change it needs as a request: the change at the shared-core interface and the contract its consumer needs. The orchestrator hands these requests to `integration` between waves, in batches of one work type each (D28). Implementation agents never change shared core.

## 2.5 Write the tasks.md index, the task files and the dependency graph

1. **Set the step.** `tasks.md` and the task files under `tasks/` are created or replaced only at 2.5 (or 0.3.20 on the light path):

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 2.5
   ```

2. **Write the budget into `spec.md`.** Edit its frontmatter `budget:` line (Edit, never Bash) to the agreed values, `budget: {max_tasks: <n>, max_changed_files: <n>}`. Leave `status` and every other key alone. Step 2.5 admits this write (D58); on Codex run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path .workflow/specs/NNN-slug/spec.md --proposed <file with the new content>` first.

3. **Write the task files**, one per slice, never one combined file: `.workflow/specs/NNN-slug/tasks/T<nn>-<slug>.md` from `assets/task.md`, numbered `T01`, `T02`, ... in dependency order (blockers first), `<slug>` kebab-case from the title. Each holds what to build, seam, acceptance criteria, predicted files, Phase 1 tests (step 5), size, mode and notes; delete the template comment.

4. **Write the index `.workflow/specs/NNN-slug/tasks.md`** from `assets/tasks.md`. One record per slice in the `tasks:` frontmatter, ids `T1`, `T2`, ... matching the task-file numbers, with `status: pending`, `work_type: null` (the orchestrator classifies at 3.1), `depends_on` from the edges (overlap edges included), `touches_core` from 2.4, `capability`, `title`, `module`, `seam`, `file: tasks/T<nn>-<slug>.md`, `branch: task/NNN-slug/T<nn>-<slug>`, `predicted_files`, `size`, `mode`, `parallel_with` (approved pairs only, else `[]`), `tests` (step 5) and `pr: null`. The body carries no per-task text: fill the `## Waves` table (wave from step 7, size, mode, overlaps) and the Mermaid graph, and delete the template comment. After this write, task records change only through `status-transition.sh set-task` (D45).

5. **Assign every Phase 1 test to exactly one task** in its record's `tests` list: the tests that task turns green. The list of Phase 1 tests is the set of new tests recorded red in the 1.4 known-bad runs under `.workflow/specs/NNN-slug/artifacts/phase-1-known-bad/` (`harness.json`, the e2e results beside it), the 1.2 and 1.3 records naming which suite each belongs to; the browser tests are also the Check column of `## Journeys` in `verification-plan.md`. Write each as a selector the owning profile's test runner understands (a test file path, a test id or a name pattern such as `@JRN-003`). Every Phase 1 test appears in exactly one task's `tests`; a test no task turns green means a slice is missing (back to 2.1). Omit `tests` on a task that owns none. run-toolchain.sh uses the lists to exclude the red tests of unfinished tasks from each task's `test` run and from the 3.9 gate (D85).

6. **Validate the records** with the yq validator in `assets/tasks.md` ("Read and validate with yq"); it must print `true`. Every `file` must exist: `yq --front-matter=extract '.tasks[].file' .workflow/specs/NNN-slug/tasks.md | while read -r f; do [ -f ".workflow/specs/NNN-slug/$f" ] || echo "missing $f"; done` prints nothing.

7. **Derive the waves** with the overlap check, and check the graph has no cycle or unknown id:

   ```bash
   .agents/skills/feature-workflow/scripts/task-waves.sh --spec-dir .workflow/specs/NNN-slug
   ```

   It prints the waves, a Mermaid graph, the overlap table and the 2.1 quiz table, then warnings (`--json` for the same as one object). Its overlap rule: two tasks overlap when some path could match a pattern from each of their `predicted_files` (identical strings, a literal matched by a glob, or two globs that can match a common path; `dir/` means `dir/**`; two different literal paths never overlap). An overlapping pair not already ordered through `depends_on` gets an implied edge from the lower id to the higher, unless both list each other in `parallel_with`; a `parallel_with` listed by one side only is a warning and the edge stays. The script never writes `tasks.md`.

   - **Exit 0, no implied edges:** the waves must match the table the stakeholder approved; copy them into `## Waves` and the edges into the Mermaid graph under `## Dependency graph`. Waves are derived, never stored as a key.
   - **Exit 0 with implied edges:** 2.1 missed an overlap. Add each implied edge to the record's `depends_on` (or take the pair back to the stakeholder for `parallel_with`), write the files again and re-run this step.
   - **Exit 2:** a cycle, an unknown id or a duplicate id (reason on stderr): fix the edges in 2.1 and write the files again. Exit 1 is an environment error: stop and report it.

**Done when:** `spec.md` carries `budget`, the validator prints `true`, every record's task file exists, `task-waves.sh` exits 0 with no implied edges and no warnings, and every Phase 1 test is in exactly one task's `tests`. Then 2.6.

After a 00.29 split the tasks that left are `split-out` in `tasks.md` (set by discovered-work through `set-task`, D68); do not rewrite the files. Run 2.6 again; `budget` stays as it is.

## 2.6 Within the size budget (task count and predicted files)?

Two checks before any code is written (D58, D85): the task count, and the sum of the predicted `size.files` of the tasks that are not `split-out` against `max_changed_files`.

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 2.6
.agents/skills/feature-workflow/scripts/budget-check.sh --spec-dir .workflow/specs/NNN-slug
.agents/skills/feature-workflow/scripts/budget-check.sh --spec-dir .workflow/specs/NNN-slug --predicted
```

Each prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source, basis}`; with `--predicted`, `changed_files` is the predicted sum (`basis: "predicted"`). Act on the worse exit of the two.

- **Exit 0 (within):** commit the breakdown on the spec branch so every task branch forks with its task file: `git add .workflow/specs/NNN-slug && git commit -m "Tasks for NNN-slug"` (only spec-folder files; the size budget never counts them). Then load `modules/implementation-orchestrator.md`.
- **Exit 2 (over):** load [discovered-work.md](discovered-work.md) at 00.21 with origin node `2.6`, condition `size budget: <tasks> tasks, max_tasks <max_tasks>` or `size budget: <n> predicted files, max_changed_files <max>` (name each entry in `over`), and the JSON as evidence. It runs 00.29: Split marks the tasks that leave `split-out` and returns here, Re-scope goes to discovery, Approve raises the budget and returns here; run 2.6 again, then commit and load the orchestrator.
- **Exit 1:** stop and report the environment error; never skip the check.

**Done when:** both `budget-check.sh` runs exited 0 (or the stakeholder approved the overrun at 00.29) and the breakdown is committed on the spec branch.
