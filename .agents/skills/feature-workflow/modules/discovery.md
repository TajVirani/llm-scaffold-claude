# Discovery (Phase 0)

Turn a request into a spec folder that says what to build, where it goes, what it touches and how it will be proven. You run in the main session; the corpus (Tier A docs, Tier B caches, the shelf) reaches you only as sub-agent extracts, except `.workflow/GLOSSARY.md`, which you read whole (design rule 3). Conventions for status, step markers, guarded writes and launches are in [../SKILL.md](../SKILL.md#5-conventions-every-module-follows); this module names the exact calls.

Work raised during Phase 0 that sits outside the agreed scope goes through the scope gate 0.3.16–0.3.17 to `.workflow/deferred/`, never to `.workflow/specs/work-backlog/`; the discovered-work protocol (00.21–00.29) covers Phases 1–4 only.

Throughout, `ST` is shorthand for `.agents/skills/feature-workflow/scripts/status-transition.sh`: type the full path every time, because sandboxed projects allow that exact command line. `NNN-slug` is this feature's folder. Keep `spec.md` an index: link the support files, never copy them.

## 0.1 Initialise the feature folder

1. **0.1.1 Scan.** Find the highest number any spec has taken. A spec number lives on after its folder leaves the working tree: on a spec branch, in an initiative's emitted slices, and as the `origin` of an initiative a spec was converted into (that spec folder is deleted, and its number is never reused). So count the `NNN-slug` spec folders, the `spec/*` branches local and on `origin`, and every initiative's `origin` and `slices[].spec`, in the working tree and on each `initiative/*` branch:

   ```bash
   {
     for d in .workflow/specs/[0-9][0-9][0-9]-*/; do [ -d "$d" ] && basename "$d"; done
     git for-each-ref --format='%(refname:lstrip=3)' refs/heads/spec
     git for-each-ref --format='%(refname:lstrip=4)' refs/remotes/origin/spec
     for f in .workflow/initiatives/*/initiative.md; do [ -f "$f" ] && yq --front-matter=extract '.origin, (.slices // [] | .[].spec)' "$f"; done
     for ref in $(git for-each-ref --format='%(refname)' refs/heads/initiative refs/remotes/origin/initiative); do
       git show "$ref:.workflow/initiatives/${ref##*/}/initiative.md" 2>/dev/null | yq --front-matter=extract '.origin, (.slices // [] | .[].spec)'
     done
   } | grep -oE '^[0-9]{3}' | sort -n | tail -1
   ```

   `.workflow/specs/work-backlog/` and any other folder without a numeric prefix are not specs and never count. The new number is the highest plus one, zero-padded to three digits (`001` when nothing prints).
2. **0.1.2 Slug.** Two to four lowercase kebab-case words from the request, action-noun where it reads well, keeping technical terms ("Implement OAuth2 for the API" → `oauth2-api`). Use `.workflow/GLOSSARY.md` terms when the request names a known concept.
3. **0.1.3** `mkdir -p .workflow/specs/NNN-slug`.
4. **0.1.4 `spec.md`.** Set the step, write the template, then record the status through the script:

   ```bash
   ST step .workflow/specs/NNN-slug 0.1.4
   # Write .workflow/specs/NNN-slug/spec.md from ../assets/spec.md: frontmatter unchanged (status: draft), title filled, template comment removed
   ST status .workflow/specs/NNN-slug draft --step 0.1.4
   ```

5. **0.1.5 Off the shelf?** Yes when the stakeholder points at a `.workflow/deferred/` file, or names an item whose concept matches a file name in `.workflow/deferred/` (list names only) and confirms it is that item. Yes → run [deferred-handoff](deferred-handoff.md#archive) **Archive**. No → continue. A concept match found later by `retrieval` comes back to this step (see 0.2.6).
6. **0.1.6 Draft the goal.** `ST step .workflow/specs/NNN-slug 0.1.6`, then write the **Why** paragraph as understood from the request (or from the archived brief's Goal, or the work item's Problem). Leave other sections as placeholders; 0.3.19 settles them.

### Seeded from a work item

A request can come from a `.workflow/specs/work-backlog/<origin>-disc-<###>.md` item: sign-off chose **Start it** at 5.9 of the origin spec, or the stakeholder picked an open item at any later time. It is not off the shelf: 0.1.5 is No. The same steps apply however it started.

- **Seed.** Read the item whole. Its title and **Suggested scope and size** are the request for 0.1.2; its **Problem** drafts the Why at 0.1.6; its **Evidence** and **Why not a blocker** become the first facts for retrieval and the questioning loop.
- **At 0.1.4** (step 0.1.4 admits both writes), while writing `spec.md`:
  - add `origin: <item file name>` to the new spec's frontmatter (for example `origin: 007-csv-export-disc-002.md`);
  - edit the item's frontmatter to `status: promoted` and `promoted_to: .workflow/specs/NNN-slug` (Edit; on Codex check the write first with `check-write.sh`). Change nothing else in it.
- **Origin entry.** Create `design-log.md` from [../assets/design-log.md](../assets/design-log.md) if needed and append a dated **Origin** entry: the item file name, its origin spec and step, and its Problem and Evidence copied in full. This entry is the lasting record, because the item file is deleted below.
- **Started from 5.9:** after 0.1.6, hand the new folder name back to sign-off. The new spec waits in `draft` and resumes through the router.
- **Delete the item when discovery finishes.** When this spec passes 0.6 (Clear) or the 0.3.20 light-path test, remove the item so no stale copy remains: `rm .workflow/specs/work-backlog/<item file>`. The `origin` key and the design-log Origin entry keep the history.

### Seeded from a slice

The large path emits a settled slice of an initiative as a spec ([6.9](large-path.md#69-emit-a-settled-slice)). The session is on `initiative/NNN-slug` with the initiative's commit already made; 0.1.5 is No. Run 0.1.1–0.1.6 with these additions, then hand the new folder name back to the large path. The spec waits in `draft` and resumes through the router; its folder stays uncommitted until its own spec branch exists (1.1 or 0.3.20).

- **Seed.** The slice's title is the request for 0.1.2. At 0.1.6 the Why opens with `Origin: initiative <initiative NNN-slug>, slice S<n> (<title>).` and states the slice's goal from the initiative's goal and the slice's settled questions.
- **At 0.1.4**, while writing `spec.md`, add `initiative: <initiative NNN-slug>` to the frontmatter.
- **Origin entry.** Create `design-log.md` from [../assets/design-log.md](../assets/design-log.md) and make its first entry the template's `Origin: initiative <NNN-slug>, slice S<n>` entry, so the questioning loop never re-asks the slice's binding decisions: the initiative folder, the slice's id and title, and under Binding decisions each of the slice's questions with its settled line, verbatim. The loop treats these as settled decisions: they shorten it, and a later round may only supersede one with the stakeholder's explicit agreement.

## 0.2 Retrieve existing system context

1. **0.2.1 Affected area.** Read `.workflow/GLOSSARY.md` whole (and, with a `.workflow/GLOSSARY-MAP.md`, the context glossaries it maps to the area). Read the **Ownership** and **Shared core** YAML blocks of `.workflow/rules.md`. Name the affected area as module names plus repo-relative paths: the `owns` globs with any trailing `/**` or `*` removed, since the cache scripts take plain paths, never globs. Write it to yourself as the area list used below.
2. **0.2.2 Term gate.** Does the request use a new, ambiguous or conflicting term? Yes → invoke the `domain-modeling` skill for gate 0.2.2; it agrees the term with the stakeholder and writes the glossary under step `0.2.3`. Done when every raised term is agreed or confirmed as an existing entry. The agreed terms go to `retrieval`.
3. **0.2.7 Cache stamps match HEAD?** Run the check before any agent reads `.workflow/cache/`:

   ```bash
   .agents/skills/regenerate-caches/scripts/cache-stamp-check.sh --area <path> [--area <path> ...]
   ```

   When `.workflow/tools/boundaries/dependency-cruiser.cjs` exists, also pass `--area .workflow/tools/boundaries/dependency-cruiser.cjs`. It is in the `architecture` scope (its Boundary violations come from it), and `--area` checks only the scope paths that intersect an area.

   It prints one JSON object (`.stale`, `.stamps`, `.caches[] | {cache_type, status, stale_paths, reason}`). Exit 0 all fresh → step 5. Exit 1 some `stale` or `missing` → step 4. Exit 2 → read `.caches[].reason`: an `invalid` cache is treated like a stale one; a tooling or usage error stops the step and is reported to the stakeholder.
4. **0.2.8 Regenerate and restamp** each cache whose status is `stale`, `missing` or `invalid`.
   - Launch one `cache-regeneration` per cache type (parallel). On Codex, launch as the [SKILL.md "Host notes"](../SKILL.md#host-notes) Launch row says: `agent_type` `cache_regeneration`, `task_name` `s<NNN>_cache_<type>` (for example `s007_cache_modules`), `fork_turns: "none"`. It receives no Tier A and not the previous cache. The prompt is the launch header followed by exactly the four task lines `.agents/agents/cache-regeneration.md` defines:

     ````markdown
     ```yaml launch-header
     task_type: cache-regeneration
     spec_dir: .workflow/specs/NNN-slug
     ```
     Cache type: <modules | flows | architecture>
     Scope: <repo-relative path>[, <path> ...]
     Commit: <40-hex sha>
     Staging path: .workflow/.cache-staging/<cache type>.md
     ````

     `Scope` is the cache's current `scope` (`yq --front-matter=extract '.scope' .workflow/cache/<type>.md`), or the affected-area paths when the cache is missing; plain paths only, no globs. For `architecture`, leave `.workflow/tools/boundaries/dependency-cruiser.cjs` out of `Scope` (`build-architecture.sh` would analyse it as source) and add it back to the publish scope paths when it exists (regenerate-caches step 3). `Commit` is `git rev-parse HEAD`.

   - When each returns, check the staged body, then publish it:

     ```bash
     .agents/skills/regenerate-caches/scripts/check-staged-cache.sh <type> .workflow/.cache-staging/<type>.md
     .agents/skills/regenerate-caches/scripts/publish-cache.sh .workflow/.cache-staging/<type>.md <type> <scope-path> [<scope-path> ...]
     # architecture only: add --generator dependency-cruiser
     ```

     `check-staged-cache.sh` exit 0 → publish. Exit 1 (problems listed on stderr): resume the agent once with those lines; if it fails again, do not publish. `publish-cache.sh` exit 0 published; exit 1 means the staged file is missing, empty or fails validation. For any cache not published, carry it into the `retrieval` launch as stale (it then reads the code for it and reports its stamp as `null`) and tell the stakeholder which cache is out of date.

5. **0.2.4 / 0.2.5 Launch `retrieval` and `library-evaluation`** in one message.

   ````markdown
   ```yaml launch-header
   task_type: retrieval
   spec_dir: .workflow/specs/NNN-slug
   ```

   Affected area: <modules and paths>
   Agreed terms: <terms from 0.2.2, or "none raised">
   Stale caches (read the code for these, stamp null): <types, or "none">
   ````

   ````markdown
   ```yaml launch-header
   task_type: library-evaluation
   spec_dir: .workflow/specs/NNN-slug
   ```

   Affected area: <modules and paths>
   Agreed terms: <terms>
   External systems: .workflow/rules.md, section "External systems"
   ````

   On Codex, launch as the [SKILL.md "Host notes"](../SKILL.md#host-notes) Launch row says: `agent_type` `retrieval` and `library_evaluation`, `task_name` `s<NNN>_<agent>` (for example `s007_retrieval`, `s007_library_evaluation`), `fork_turns: "none"`.

6. **0.2.6 Write `codebase-map.md`** from [../assets/codebase-map.md](../assets/codebase-map.md) and the two returns only:
   - `cache_stamps` frontmatter ← the `cache_stamps` block of the `retrieval` return (after 0.2.8 these are the freshly published stamps).
   - **Affected area** ← the 0.2.1 list. **Relevant code**, **Seams and interfaces**, **Prior decisions**, **Not found** ← the same-named sections of the `retrieval` return.
   - **Library options** ← the `library-evaluation` report, pasted whole in place of the template table, with its Evidence URLs intact. A `Hold` or `Blocked: missing context` return goes in as returned and its missing items become questions for the loop.
   - Delete the template comment and placeholder rows; write `None.` for an empty section.
   - **Shelf match.** If **Prior decisions** reports a `.workflow/deferred/` file that matches this request by concept, ask the stakeholder whether this request is that item (quote the shelved reason). Yes → [deferred-handoff](deferred-handoff.md#archive) **Archive**, then revisit the goal at 0.3.19. No → continue.

   Done when every section holds either agent extracts with sources or `None.`, and the stamps are copied.

## 0.3 Frame the problem (placement first)

1. **0.3.1 Capability already exists?** Check the goal against the capabilities in **Prior decisions** and, for the candidate names, `grep -n -i '<term>' .workflow/capabilities.md`.
   - Yes → **0.3.2 Reframe** as a change to that capability: it keeps its `CAP-###`. Log the reframe in `design-log.md`; 0.3.19 writes it into `spec.md`.
   - No → a new capability gets a provisional `CAP-NEW-<slug>` (lowercase kebab-case, unique in this spec) until 5.3.
2. **0.3.3 Owning module clear?** Clear when every path the change touches falls under one module's `owns` in the Ownership block.
   - Yes → go to [0.3.22](#hand-off-to-the-questioning-loop). No placement ADR is needed.
   - No → **0.3.4 Resolve placement** with the stakeholder: put the candidate modules to them as one question with your recommendation (from **Seams and interfaces** and **Prior decisions**), then log a **Placement** entry in `design-log.md` (create it from [../assets/design-log.md](../assets/design-log.md) if missing; that is node 0.3.21).
3. **0.3.5–0.3.7 Conflicts and the ADR.** Invoke `domain-modeling` for placement: it checks the placement against the ADRs and `.workflow/rules.md` (0.3.5), has the stakeholder conform or supersede (0.3.6), and writes the placement ADR under step `0.3.7`, or a design-log entry when the placement fails the three-part ADR test. A rule conflict becomes a 5.3 proposal, never a mid-feature rule edit.

### Hand off to the questioning loop

1. **0.3.22 Deeper prompt.** Invoke the `deeper-prompt` skill. It restates the request one level up with its goals, downstream work, tools and gotchas, revises until the stakeholder explicitly agrees, and appends the agreed block to `design-log.md` as a **Deeper prompt** entry. Runs on both paths (light versus full is decided later, at 0.3.20), and only on this first entry: loop-backs to 0.3.8 go straight to the loop.
2. Load [questioning-loop.md](questioning-loop.md) with the agreed block as its input. It runs 0.3.8–0.3.19 and returns here at 0.3.20.

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

- **`light_path: true` (pass).** Create the spec branch, write the size budget, the one-task `tasks.md` index and its task file, commit them, then set the status:

  ```bash
  ST step .workflow/specs/NNN-slug 0.3.20
  # Spec branch (the light path has no task branch): off the main branch, carrying the uncommitted spec folder with it.
  git switch -c spec/NNN-slug "$(.agents/skills/feature-workflow/scripts/rules-setting.sh main_branch)"   # already on spec/NNN-slug (a loop-back): skip
  # Edit the spec.md frontmatter line to `spec_branch: spec/NNN-slug`.
  # Read the project defaults from .workflow/rules.md "## Size budget":
  awk '/^## /{f=($0 ~ /^## Size budget[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md | yq -o=json '.size_budget'
  # Edit the spec.md frontmatter line to `budget: {max_tasks: <n>, max_changed_files: <n>}` with those values,
  # unless the stakeholder agreed other values (log them in design-log.md). No block in rules.md: keep the template's 10 / 30.
  # Leave status and every other key alone.
  # Write .workflow/specs/NNN-slug/tasks/T01-<slug>.md from ../assets/task.md (what to build, seam,
  #   acceptance criteria from the capability's success line, predicted files, size, mode, notes).
  # Write the index .workflow/specs/NNN-slug/tasks.md from ../assets/tasks.md with one record:
  #   id: T1, title, status: pending, capability: <the spec's CAP id>, depends_on: [],
  #   touches_core: <true if a touched path is under Shared core>, work_type: null,
  #   module: <owning module>, seam: <interface under test agreed in the loop>,
  #   file: tasks/T01-<slug>.md, branch: null, predicted_files, size, mode, parallel_with: [], pr: null
  # and a one-row Waves table; validate it with the yq validator in ../assets/tasks.md (prints true).
  git add .workflow/specs/NNN-slug && git commit -m "Spec NNN-slug"   # the spec branch's first commit
  ST status .workflow/specs/NNN-slug ready-for-dev --step 0.3.20
  ```

  T1 commits straight onto the spec branch at 3.3 (`branch: null`); a `mode: hitl` T1 still gets the 3.3 pause.

  Seeded from a work item: now delete the item (see [Seeded from a work item](#seeded-from-a-work-item)).

  If `tasks.md` already exists (a loop-back on a light-path spec), keep it: its task records change only through `set-task`. If the revised goal needs work the existing task does not cover, take the full path instead. Then [offer a fresh session](#offer-a-fresh-session) and load implementation-orchestrator at 3.1 (it captures `baseline_revision` and `impl_base_revision` there).
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

   On Codex, launch as the [SKILL.md "Host notes"](../SKILL.md#host-notes) Launch row says: `agent_type` `module_audit`, `task_name` `s<NNN>_module_audit` (for example `s007_module_audit`), `fork_turns: "none"`.

   Write its return into `codebase-map.md`: **Module audit** ← its `## Module audit` table; append its **Seams and interfaces (additions)** rows to **Seams and interfaces**; append its **Not found** lines. A `cache disagrees with code` line is a stamp problem: rerun 0.2.7–0.2.8 for that cache, never edit an extract.

   Its **Out of scope noticed** lines are never dropped and never folded into the change: run each one through the Phase 0 scope gate, the 0.3.16–0.3.17 deferred path ([questioning-loop](questioning-loop.md) step 8): [deferred-handoff](deferred-handoff.md#write) **Write** at step `0.3.17` writes `.workflow/deferred/<slug>.md`, adds it to `spec.md` `deferred` and Non-goals, and logs the **Scope decision**, with the line's kind, summary and evidence as the item. A `blocks-this-task` line whose fix the goal cannot do without is not deferred: it is a goal conflict for 0.4.7.
6. **0.4.7 Conflicts with the goal or the placement?**
   - **Goal** → `ST step .workflow/specs/NNN-slug 0.3.8`, load the questioning loop with the conflict as the first frontier question.
   - **Placement** → back to 0.3.3 with the audit findings.
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
- **Clear** → `ST status .workflow/specs/NNN-slug ready-for-dev --step 0.6`; for a spec seeded from a work item, delete the item (see [Seeded from a work item](#seeded-from-a-work-item)); then [offer a fresh session](#offer-a-fresh-session) and load verification-setup at 1.1.

## Offer a fresh session

The spec is `ready-for-dev`, so everything implementation needs is on disk, while this session's context is full of discovery. Before loading the next module, ask the stakeholder: continue here, or start fresh?

- **Continue**: load the next module now.
- **Fresh**: load the `handoff` skill and write a handoff for this spec. Then tell the stakeholder to clear the context (`/clear` in Claude Code) or open a new session and ask to resume `NNN-slug`; the new session routes by the spec's status and `.step` ([Route by status](../SKILL.md#3-route-by-status)). Stop here.

## Done

- `spec.md` is `ready-for-dev` (light or full path) and links every support file that exists; on the light path it carries `budget`.
- A spec seeded from a work item carries `origin` and a design-log Origin entry; the item was marked `promoted` at 0.1.4 and deleted once discovery finished.
- A spec seeded from a slice carries `initiative` and a design-log Origin entry with the slice's binding decisions.
- `codebase-map.md` was written only from agent returns and carries the stamps; `design-log.md` holds the placement, impact and scope decisions.
- Light path: `tasks.md` has one valid record with its task file, committed on `spec/NNN-slug`. Full path: `data-model.md` and `verification-plan.md` exist and pass 0.6.
