<!--
File: Phase 2 module of `feature-workflow` (2.1-2.6): split the spec into vertical slices, write tasks.md with its dependency graph and the spec's size budget, and check the task count against it.
Triggers/inputs: Handoff from modules/verification-setup.md after 1.5; spec status `ready-for-dev`. Reads specs/NNN-slug/{spec.md, data-model.md, verification-plan.md, codebase-map.md, design-log.md}, docs/rules.md (Ownership, Shared core), profiles/ (File locations), GLOSSARY.md.
Outputs/handoff: specs/NNN-slug/tasks.md from assets/tasks.md, consumed by modules/implementation-orchestrator.md; spec.md `budget` at 2.5. Gates 2.2 and 2.3 loop to modules/questioning-loop.md (0.3.8) with status `draft`. Discovered work at 2.1 and a task count over budget at 2.6 go to modules/discovered-work.md (00.21-00.29).
Plan refs: PLAN/decision-flow.mermaid P2 (2.1-2.6); reference "Phase 2 - Task breakdown", "Per-feature files", "Discovered work", 00.3, 00.17, 00.21-00.29; assetlist D14, D15, D16, D28, D44, D45, D49, D56, D58, D68.
Sources: first-party, adapted from mattpocock/skills/skills/engineering/to-tickets/SKILL.md@49dd158 (tracer-bullet vertical slices, prefactoring first, blocking edges, expand-contract for wide refactors, quiz the user until the breakdown is approved, work the frontier), skills/engineering/to-spec/SKILL.md@49dd158 step 2 (prefer existing seams, the highest seam, as few seams as possible; confirm with the user) and skills/engineering/tdd/SKILL.md@49dd158 "Seams" (test only at pre-agreed seams; one line per seam on what it catches and misses) [MIT]; same-wave tasks sharing files get an edge, from open-gsd/gsd-core agents/gsd-planner.md "assign_waves" [MIT, (c) 2026 Open GSD]. to-tickets publishes to a tracker; this module writes tasks.md instead. Patterns only; no substantial text copied.
-->

# Phase 2: Task breakdown

You cut the spec into **tracer-bullet** tasks and write them to `tasks.md`, each with its seam, module and blocking edges. You are done when the stakeholder has approved the breakdown, every slice is specifiable and has an agreed seam, `tasks.md` passes the schema validator with a wave for every task, and the task count is within the spec's size budget (or the stakeholder decided what to do about it).

Everything here runs in the main session at spec status `ready-for-dev`. Call the scripts from the project root exactly as written below, with the repo-relative `.agents/skills/feature-workflow/scripts/` prefix (sandboxed projects exclude these exact command lines; D36). Mark the phase as you enter it (`.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 2.1`) so a resumed session returns here.

## 2.1 Split into vertical slices

Read `spec.md` (capabilities and constraints), `data-model.md` (what is created, extended or refactored, and the migration order), `verification-plan.md` (journeys), `codebase-map.md` (seams and module findings), the `## Ownership` and `## Shared core` blocks of `docs/rules.md`, and the `## File locations` section of each profile in `profiles/`. Use `GLOSSARY.md` terms in titles.

Draft the slices:

- Each slice cuts a narrow but complete path through every layer it needs (schema, API, UI, tests), is verifiable on its own, and fits one fresh context window.
- One slice works in one module (a key under `modules` in the Ownership block), because one implementation agent owns one module (3.3).
- Respect the profiles' file-location rules, so a slice does not straddle two work types without need.
- Prefactoring comes first: "make the change easy, then make the easy change".
- Migrations follow the order in `data-model.md`.
- A **wide refactor** (one mechanical change whose blast radius spans the codebase) is the exception: sequence it expand, then migrate in batches, then contract, each its own task, each batch blocked by the expand and the contract blocked by every batch.
- Give each slice its blocking edges: the slices that must be done before it can start. Two slices that would edit the same files get an edge between them, so they never land in the same wave.
- Name the capability each slice serves: a `CAP-###` from `spec.md`, or its provisional `CAP-NEW-<slug>` (D44). A prefactoring slice names the capability it unblocks.

**Discovered work.** Breaking the spec down can surface work the spec did not agree to: a bug in the code a slice would build on, a refactor the agreed slices do not need, a slice that would spread into another module, a decision nobody here can make. Prefactoring the spec's own capabilities need is a slice; anything else is not. Never add it as a slice: load [discovered-work.md](discovered-work.md) at 00.21 with origin node `2.1`, then continue the breakdown after 00.28 (or follow it to discovery).

**Quiz the stakeholder.** Present the breakdown as a numbered list, each entry with title, blocked by, what it delivers end to end, module, seam (2.3) and capability. Ask whether the granularity is right, whether each edge genuinely gates its task, and whether any slice should merge or split. Iterate until they approve. Ask 2.2 and 2.3 in the same rounds, and the size budget for 2.5:

- Propose the project defaults from the `## Size budget` block of `docs/rules.md` (D58):

  ```bash
  awk '/^## /{f=($0 ~ /^## Size budget[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' docs/rules.md | yq -o=json '.size_budget'
  ```

  No block: propose the `spec.md` template values (10 tasks, 30 changed files).
- The stakeholder may agree other values for this spec; log the agreed budget as a decision in `design-log.md`. A breakdown already over the default is not quietly absorbed: keep the default, and let 2.6 put split, re-scope or approve to them.

**Done when:** the stakeholder has approved the list.

## 2.2 Specifiable?

A slice is specifiable when its acceptance criteria can be written from `spec.md`, `design-log.md` and `verification-plan.md` alone, with no decision left open. A slice that needs a decision nobody has made is not.

**No:** set status `draft` (D49) and load `modules/questioning-loop.md`, carrying the open decisions as the first questions of its frontier:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug draft --step 2.2
```

## 2.3 Interfaces under test agreed?

For each slice, propose its seam: the public interface its tests will drive. Prefer an existing seam to a new one, the highest seam that reaches the behaviour, and as few seams across the feature as possible. Give each proposed seam one line on what it catches and what it misses, and confirm the set with the stakeholder. No test is written at an unagreed seam.

**No** (the seam needs an interface change discovery has not settled): set status `draft` and load `modules/questioning-loop.md` with the seam question:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug draft --step 2.3
```

## 2.4 Modifies shared core?

Read the shared-core globs:

```bash
awk '/^## /{f=($0 ~ /^## Shared core[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' docs/rules.md \
  | yq '.shared_core.paths'
```

A slice that must change a path matching them gets `touches_core: true`, and its body's **Notes** states the shared-core change it needs as a request: the change at the shared-core interface and the contract its consumer needs. The orchestrator hands these requests to `integration` between waves, in batches of one work type each (D28). Implementation agents never change shared core.

## 2.5 Write tasks.md and its dependency graph

1. **Set the step.** `tasks.md` is created or replaced only at 2.5 (or 0.3.20 on the light path):

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 2.5
   ```

2. **Write the budget into `spec.md`.** Edit its frontmatter `budget:` line (Edit, never Bash) to the agreed values, `budget: {max_tasks: <n>, max_changed_files: <n>}`. Leave `status` and every other key alone. Step 2.5 admits this write (D58); on Codex run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path specs/NNN-slug/spec.md --proposed <file with the new content>` first.

3. **Write `specs/NNN-slug/tasks.md`** from `assets/tasks.md`. One record per slice in the `tasks:` frontmatter, ids `T1`, `T2`, ... in dependency order, with `status: pending`, `work_type: null` (the orchestrator classifies at 3.1), `depends_on` from the edges, `touches_core` from 2.4, `capability`, `title`, `module` and `seam`. Add a body section per record (what to build, seam, acceptance criteria, notes) and delete the template comment. After this write, task records change only through `status-transition.sh set-task` (D45).

4. **Validate the records** with the yq validator in `assets/tasks.md` ("Read and validate with yq"); it must print `true`.

5. **Derive the waves** and check the graph has no cycle or unknown id:

   ```bash
   yq --front-matter=extract -o=json '.tasks' specs/NNN-slug/tasks.md | jq -r '
     (map({key: .id, value: .depends_on}) | from_entries) as $d
     | reduce range($d | length) as $_ ({}; . as $w
         | reduce ($d | to_entries[]) as $e ($w;
             if ([$e.value[] | $w[.]] | all(. != null))
             then .[$e.key] = (([$e.value[] | $w[.]] | max // 0) + 1) else . end))
     | if length < ($d | length)
       then "cycle or unknown id among: \((($d | keys) - keys) | join(", "))\n" | halt_error(1)
       else to_entries | group_by(.value)[] | "Wave \(.[0].value): \(map(.key) | join(", "))" end'
   ```

   A non-zero exit means the edges are wrong: fix them in 2.1 and write the file again. Copy the wave lines and a Mermaid graph of the edges into `## Dependency graph`. Waves are derived, never stored as a key.

**Done when:** `spec.md` carries `budget`, the validator prints `true`, the wave command exits 0, and every record has a body section. Then 2.6.

After a 00.29 split the tasks that left are `split-out` in `tasks.md` (set by discovered-work through `set-task`, D68); do not rewrite the file. Run 2.6 again; `budget` stays as it is.

## 2.6 Within the size budget (task count)?

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 2.6
.agents/skills/feature-workflow/scripts/budget-check.sh --spec-dir specs/NNN-slug
```

It prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source}`.

- **Exit 0 (within):** load `modules/implementation-orchestrator.md`.
- **Exit 2 (over):** load [discovered-work.md](discovered-work.md) at 00.21 with origin node `2.6`, condition `size budget: <tasks> tasks, max_tasks <max_tasks>` (name each entry in `over`), and the JSON as evidence. It runs 00.29: Split marks the tasks that leave `split-out` and returns here, Re-scope goes to discovery, Approve raises the budget and returns here; run 2.6 again, then load the orchestrator.
- **Exit 1:** stop and report the environment error; never skip the check.

**Done when:** `budget-check.sh` exited 0, or the stakeholder approved the overrun at 00.29.
