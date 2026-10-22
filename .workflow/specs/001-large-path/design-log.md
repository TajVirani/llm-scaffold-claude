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

## 2026-10-21 Questioning round 1

**Q1. How does the router send work to the large path?**

- Why now: terms (0.2.3), placement (D1) and the deeper prompt are settled.
- Options: A: intake gate at 0.0.x · B: never at intake; discovery runs and the loop converts the spec when it finds several features · C: both
- Recommended: C, because the router already sizes at 0.0.1 and both boundary cases were routed to the large path (codebase-map.md, SKILL.md § 2 row)
- Answer: "1. B"
- Decision: **D2** No intake gate. Every request starts discovery as a spec; the questioning loop converts the spec into an initiative when it finds several features.

**Q2. Does the large path get node ids in `references/steps.tsv` as a third track?**

- Why now: placement in feature-workflow (D1) settled where ids live.
- Options: A: a `large` track with its own ids; lint pins and the two PLAN flow docs updated in step · B: no ids; resume from status and the questions file
- Recommended: A, because every guard and resume path keys off `.step` (codebase-map.md, steps.tsv and check-write.sh rows)
- Answer: "2. A"
- Decision: **D3** The large path has node ids in `references/steps.tsv` on a third track; `tests/lint/step-list.sh` pins and the PLAN flow docs are updated with them.

**Q3. Where does an initiative live?**

- Why now: the Initiative term is agreed (0.2.3).
- Options: A: `.workflow/initiatives/NNN-slug/` with its own numbering; emitted specs get normal spec numbers and carry `initiative: NNN-slug` · B: inside `.workflow/specs/` sharing the number space
- Recommended: A, because everything that enumerates specs globs `.workflow/specs/*/spec.md` (codebase-map.md, session-start-resume row)
- Answer: "3. A - but the specs generated to in the normal spec folder for each spec created. THe initiative can have a reference doc pointing to those specs"
- Decision: **D4** Initiatives live under `.workflow/initiatives/NNN-slug/` with their own numbering. Emitted specs are ordinary folders under `.workflow/specs/` with normal numbers; the initiative holds a reference document pointing at them.

**Q4. When are specs emitted?**

- Why now: the large path plans only (0.2.3), so emission is its output.
- Options: A: incrementally, each slice once its questions are decided and confirmed · B: all at once when the initiative is settled
- Recommended: A, because the comparison page warns that large maps drift into waterfall unless slices leave early
- Answer: "4. A"
- Decision: **D5** Specs are emitted incrementally, one slice at a time, while the rest of the initiative stays in exploration.

**Q5. What does an emitted spec receive?**

- Why now: depends on D5.
- Options: A: created at 0.1 seeded from the slice (Why, Origin entry with binding decisions, codebase-map), then normal discovery · B: skips to 0.3.19 with the goal settled
- Recommended: A, because it reuses the "seeded from a work item" pattern and skips no gate (codebase-map.md, discovery rows)
- Answer: "5. A"
- Decision: **D6** An emitted spec is created through discovery 0.1 seeded from its slice and runs discovery normally; carried decisions shorten its loop.

**Q6. Initiative status lifecycle?**

- Why now: depends on D4.
- Options: A: `exploring` → `planned` → `done`, written only by a sibling script with the spec script's exit contract · B: `open` → `closed` · C: reuse the spec statuses
- Recommended: A, because "planned" ends the large path's own job and "done" leaves room for cross-spec delivery (deeper prompt, Downstream)
- Answer: "6. A"
- Decision: **D7** Initiative status is `exploring` → `planned` (every slice emitted) → `done` (every emitted spec done), changed only through a new sibling script with the same exit-code contract as the spec single writer.

**Q7. Is an initiative bounded?**

- Why now: scope controls are the existing pattern (rules.md Size budget row).
- Options: A: soft `max_specs` in the rules.md Size budget block · B: no bound
- Recommended: A, because the size budget is the existing scope control
- Answer: "7. B"
- Decision: **D8** No spec-count bound on an initiative. The goal statement is its only limit.

**Q8. May research span sessions?**

- Why now: goal 2 of the deeper prompt (survives sessions).
- Options: A: research questions are launched to agents and may stay pending across a session end; written back on resume · B: research completes within its session
- Recommended: A, because it is Wayfinder's AFK research ticket and sub-agents never write, so write-back belongs to the resuming session
- Answer: "8. A"
- Decision: **D9** A research question may be launched and left pending when a session ends; its answer is written back into the initiative by the session that resumes it.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-21 Questioning round 2

**Q1. When does discovery convert a spec into an initiative?**

- Why now: D2 made conversion the only entrance to the large path.
- Options: A: the orchestrator may propose conversion at any round when the tree holds more than one capability with its own success signal or owning module; 0.3.19 adds a hard "one feature?" check · B: only the 0.3.19 check
- Recommended: A, because waiting for 0.3.19 wastes rounds on a tree that is several trees
- Answer: "1.A"
- Decision: **D10** Conversion is proposed as a frontier question at any round when the design tree shows several features; the stakeholder decides. 0.3.19 checks "one feature?" before writing spec.md and converts when the answer is no.

**Q2. What does conversion do to the spec folder?**

- Why now: depends on D4 and D10.
- Options: A: the initiative inherits `design-log.md` and `codebase-map.md` (moved, append-only log continues), the spec's Why becomes the initiative goal, the spec folder is deleted and its number not reused, the initiative log opens with an Origin entry · B: the spec stays as the first slice, re-scoped · C: the spec folder is moved under the initiative as an archive
- Recommended: A, because it mirrors how a promoted work item is absorbed and deleted and leaves no draft spec for the resume offer
- Answer: "2. A"
- Decision: **D11** On conversion the initiative is created with the next initiative number and inherits the spec's `design-log.md` and `codebase-map.md`; the spec's Why becomes the initiative goal; an Origin entry names the spec; the spec folder is deleted and its number is not reused.

**Q3. The initiative's files?**

- Why now: depends on D4.
- Options: A: `initiative.md` (frontmatter: status, goal, emitted-spec records with order and `depends_on`; body: the reference table linking each spec), `questions.md`, `design-log.md`, `codebase-map.md` · B: one `initiative.md`
- Recommended: A, because it follows the spec folder's split of one guarded index and unguarded support files
- Answer: "3. A"
- Decision: **D12** An initiative folder holds `initiative.md` (guarded index and the reference table of emitted specs), `questions.md`, `design-log.md` and `codebase-map.md`.

**Q4. Name for the unit that becomes one spec?**

- Why now: D5 made the unit real.
- Options: A: "slice" · B: "planned spec" · C: "stream"
- Recommended: A, because it is already in the comparison page's vocabulary and it is not a spec until emitted
- Answer: "4. A"
- Decision: **D13** The unit is a **slice**; written to the glossary at 0.3.15.

**Q5. The question record?**

- Why now: depends on D9 and D12.
- Options: A: id `IQ<n>`, kind `research` or `decision`, state `open` → `researching` → `settled`, `depends_on`, settled line with source or verbatim answer; the frontier computed as the loop does; called a "question", never "ticket" · B: Wayfinder's "ticket" vocabulary
- Recommended: A, because the frontier mechanics exist and "ticket" would collide with gh/glab issues downstream
- Answer: "5. A"
- Decision: **D14** `questions.md` holds **initiative questions** (`IQ<n>`, kind, state, `depends_on`, settled line); the frontier is computed from them. Term written to the glossary at 0.3.15.

**Q6. The exploration loop?**

- Why now: depends on D3 and D14.
- Options: A: a new module for the large path reusing the round shape over `questions.md`, with no "Open Questions must be empty" exit · B: run the existing questioning-loop module against the initiative folder
- Recommended: A, because the existing loop is bound to spec.md, its step ids and the light-path facts
- Answer: "6. A"
- Decision: **D15** The large path is a new module that reuses the round shape (compute frontier, fact lookup, one round, log) over `questions.md`.

**Q7. After a slice is emitted?**

- Why now: depends on D5 and D6.
- Options: A: offer the choice each time (keep exploring, or step into the new spec) · B: always stay in the initiative
- Recommended: A, mirroring 5.9 "Start it"
- Answer: "7. B - except if the spec is needed to refine other questions on the initiative. Then run the spec look for that spec, but once the spec is done go back to the initiative"
- Decision: **D16** After emission the session stays in the initiative, unless an open initiative question depends on the emitted spec; then that spec runs through the router and the initiative resumes when the spec is done.

**Q8. Resume offer and routing?**

- Why now: goal 2 of the deeper prompt; depends on D7.
- Options: A: the session-start offer lists in-flight initiatives beside specs; choosing one loads the large-path module; "Find the state" gets a branch for a request naming an initiative · B: resumed only by name
- Recommended: A, because the hook already reads one status per folder
- Answer: "8. A"
- Decision: **D17** The session-start resume offer lists initiatives (`exploring`, or `planned` with unstarted specs); the router's "Find the state" gains a branch for an initiative.

**Q9. Dependency between emitted specs?**

- Why now: depends on D12.
- Options: A: the router warns and asks when a `depends_on` spec is not done; never blocks · B: hard block
- Recommended: A, because specs are independent folders with their own status
- Answer: "9. This isn't an issue. Specing work doesn't mean code - and the coding piece may flag it... but I don't think this should guard."
- Decision: **D18** Spec order and `depends_on` in `initiative.md` are informational. The router neither blocks nor warns on them; discovered work during the build catches a real conflict.

Facts looked up instead of asked (0.3.10):
- Step id grammar: the lint pins ids to `(00|[0-5])(\.[0-9]+)+` and exactly six phase rows; `6.1` and `I.1.2` both fail it, and a letter id risks substring matches in the lint's id extraction (`tests/lint/step-list.sh:19,28,40-57,63`). `status-transition.sh:114` accepts digits and dots only. `step-progress.sh:67` is an exact lookup in `steps.tsv`.
- Paths: every script and hook takes the specs folder from `WF_SPECS` in `.agents/lib/workflow-paths.sh:25`; a sibling folder is one new `WF_<NAME>` line. Static files carry literal paths and are kept by hand: `.agents/hooks/claude-settings.template.json:147`, `.agents/hooks/codex-config.template.toml:9`, `.gitignore:9`; `install.sh:52` builds `GI_ENTRIES` from the `WF_` variables.
- Resume offer: `session-start-resume.sh:50-55` globs specs, backlog and handoffs; reads `[.status, .blocked_condition]` from spec.md and `[.step, .updated_at, .blocked_from]` from `.step` (`:104,113-117`); prints one JSON `additionalContext` block (`:147-170`).
- Shelf Archive: prepends `superseded_by: .workflow/specs/NNN-slug` and moves the file to `.workflow/deferred/archive/` (`modules/deferred-handoff.md:43-51`); no script implements it.
- Extra frontmatter keys: neither validator rejects an unknown key such as `initiative:`; `status-transition.sh` edits only `.status`, `.blocked_condition`, `.spec_branch`, `.impl_base_revision` in place (`status-transition.sh:393,469-475`; `tests/scripts/status-transition-check-write.sh:70,101`; `assets/spec.md:43-55`). The "Add no other keys" line in `assets/spec.md:34` is prose.

## 2026-10-21 Questioning round 3

**Q1. Where do the `large` track's step ids live?**

- Why now: D3 needs ids; the lint fact (round 2) pins the grammar to `(00|[0-5])(\.[0-9]+)+` and six phases.
- Options: A: new leading digit `6.x`, lint regex widened to 0-6, a seventh phase row, the `large` track prints its own progress line · B: reuse the `00.x` cross namespace
- Recommended: A, because `00.x` rows must be track `cross` and need an origin step, and read as side protocols (`tests/lint/step-list.sh:35`)
- Answer: "New leading digit 6.x (Recommended)"
- Decision: **D19** Large-path node ids are `6.x` on a `large` track in `references/steps.tsv`; the lint's id regex, phase rows and count loops are extended; `step-progress.sh` prints a large-path form of the progress line for that track.

**Q2. How is a `research` initiative question answered?**

- Why now: depends on D9 and D14.
- Options: A: a new read-only `research` task type (repo plus web, findings with sources for one question) with model-map entry, launch requirements and Codex toml · B: reuse fact-lookup, retrieval and library-evaluation only
- Recommended: A, because open-ended questions fit neither fact-lookup (repo facts) nor library-evaluation (one library)
- Answer: "New research task type (Recommended)"
- Decision: **D20** A new `research` task type answers open-ended initiative questions; fact-lookup, retrieval and library-evaluation remain for their kinds. The glossary's Task type list gains `research` through a 5.3 proposal.

**Q3. Who moves an initiative from `planned` to `done`?**

- Why now: depends on D7.
- Options: A: sign-off of a spec carrying `initiative:` checks the initiative's records at 5.7 and moves it to `done` when every emitted spec is done · B: the stakeholder closes it
- Recommended: A, because it needs no manual step and sign-off already runs per spec
- Answer: "Sign-off of the last spec (Recommended)"
- Decision: **D21** Sign-off of a spec that carries `initiative:` moves the initiative to `done` through the sibling script once every emitted spec is done.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-21 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Initiative (`.workflow/initiatives/NNN-slug/initiative.md`) | create | Guarded index: status, origin, slice records, reference table; see data-model.md § Initiative |
| Initiative question (`questions.md`) | create | `IQ<n>` records with kind, state, `depends_on`, settled line; see data-model.md § Initiative question |
| Slice (record inside `initiative.md`) | create | `S<n>`, status planned → emitted → done, `spec` once emitted; see data-model.md § Slice |
| Initiative step marker (`.workflow/initiatives/NNN-slug/.step`) | create | Same shape as the spec marker; written only by the initiative status script |
| `initiative-transition.sh` (sibling single writer) | create | Status and step transitions for initiatives; same exit contract (D7) |
| `modules/large-path.md` and `6.x` nodes | create | The exploration loop over `questions.md`, emission, planned transition (D15, D19) |
| `assets/initiative.md`, `assets/questions.md` | create | Templates for the two new files |
| `.agents/agents/research.md`, `.workflow/model-map/research.md` | create | New task type for open-ended research questions (D20) |
| `spec.md` frontmatter `initiative:` | extend | Optional string, the initiative folder name; validator admits it (fact: unknown keys pass) |
| `references/steps.tsv`, `step-progress.sh` | extend | Phase 6 row, `large` track, conversion node in phase 0; large-path progress line |
| `tests/lint/step-list.sh` | extend | Id regex 0-6, seven phase rows, count loops and pins |
| `PLAN/decision-flow-reference.md`, `PLAN/decision-flow.mermaid` | extend | Scaffold-only, lint-bound: the new nodes |
| `SKILL.md` router (§1, §3, §5, §6) | extend | Initiative branch in Find the state, route rows, guarded-write table, modules table (D17) |
| `modules/questioning-loop.md` | extend | Conversion proposal at 0.3.8; "one feature?" check at 0.3.19 (D10) |
| `modules/discovery.md` | extend | Conversion procedure; "Seeded from a slice" section; 0.1.4 admits `initiative:` (D6, D11) |
| `modules/sign-off.md` | extend | 5.7 moves the initiative to done when its last spec is done (D21) |
| `modules/deferred-handoff.md` | extend | Archive `superseded_by` may name an initiative; conversion re-points it |
| `assets/spec.md`, `assets/design-log.md` | extend | `initiative:` key; Conversion, Origin (initiative), Initiative round and Emission entry shapes |
| `check-write.sh`, `spec-single-writer-guard.sh` | extend | Guard class for `initiative.md` at `6.x` steps; initiative `.step` never by Write/Edit |
| `session-start-resume.sh` | extend | Lists initiatives beside specs (D17) |
| `resolve-launch.sh`, `hooks/pre-launch.sh`, `codex-pre-spawn.sh` | extend | `research` requirements; launches from an initiative folder; `i<NNN>_` task names |
| `.agents/lib/workflow-paths.sh` | extend | `WF_INITIATIVES`; shared core, integration agent |
| `install.sh` `GI_ENTRIES`, `.gitignore`, `claude-settings.template.json`, `codex-config.template.toml` | extend | `.workflow/initiatives/*/.step` ignore and deny entries kept by hand |
| `.agents/install-manifest.txt`, `PROVENANCE.md` | extend | New first-party files listed |
| `README.md` | extend | One line naming the large path |
| `tests/` suites | create / extend | New suites for the sibling script, guard class, resume listing, task names; step-progress and step-list suites updated |
| `status-transition.sh`, `.workflow/rules.md` Size budget, handoff skill, project-setup, retrospective | unchanged | Spec single writer untouched (D7); no spec-count bound (D8); non-goals |

## 2026-10-21 Scope decision: shared path normaliser

- Item: module-audit noticed that the spec-folder normaliser and main-checkout resolver are copied into four scripts and the large path adds a fifth copy for initiatives; it proposed a shared helper.
- Ruling: deferred, because the module's recorded convention is self-contained scripts that source only the path constants, and replacing the copies is a shared-core change that deserves its own decision; the large path works without it.
- Handoff: [.workflow/deferred/shared-path-normaliser.md](../../deferred/shared-path-normaliser.md) (AFK), also listed in spec.md `deferred`

## 2026-10-21 Questioning round 4 (loop-back from 0.4.7)

**Q1. Where does an initiative's folder live in git?**

- Why now: the module audit found that a 5.7 initiative write lands on the spec branch, and nothing said where a multi-session initiative is committed (codebase-map.md, Module audit constraints).
- Options: A: committed on main directly by the large-path module, push with a PR fallback, done flip at 5.8 · B: `initiative/NNN-slug` branch, PR into main at `planned`, lazy done flip on the next resume · C: uncommitted working tree like a draft spec
- Recommended: A, because only the large path writes the files, every spec branch sees them, and the size budget is untouched
- Answer: "Initiative branch, PR at planned"
- Decision: **D22** An initiative's folder lives on `initiative/NNN-slug`, created off main at conversion. The large-path module commits on it at conversion, after each round, at each emission and at each status change, and pushes when a remote exists. When the initiative reaches `planned` it is merged into main through a PR/MR (the `task_review` setting decides pr, pr-blocking or local, as for task branches). Emitted spec folders are never committed on the initiative branch.
- Decision: **D23 (supersedes D21)** The `done` flip is lazy: when a `planned` initiative is resumed, the large-path module checks that every emitted spec is `done` on main and, if so, re-creates `initiative/NNN-slug` off main, sets `done` through the initiative status script and merges it the same way as `planned`. Sign-off writes nothing into an initiative.
- Consequence: the session-start resume offer lists initiatives from their branches (`git for-each-ref refs/heads/initiative/*`, reading `initiative.md` at each tip) as well as from main; the Tier A gate and the size budget are untouched because initiative files never sit on a spec branch.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-21 Impact classification (revised after round 4)

Rows that change against the first classification; every other row stands.

| Part | Classification | Note |
| --- | --- | --- |
| Initiative branch `initiative/NNN-slug` | create | Created off main at conversion; every initiative commit lands on it (D22); see data-model.md § Initiative branch |
| Initiative PR/MR at `planned` and `done` | create | Opened through the gh/glab host switch that `open-task-pr.sh` already has, honouring `task_review` (D22, D23) |
| `modules/sign-off.md` | unchanged | Sign-off no longer writes into an initiative (D23 supersedes D21) |
| `session-start-resume.sh` | extend | Lists initiatives from `refs/heads/initiative/*` tips and from main (D22 consequence) |
| `budget-check.sh` | unchanged | Initiative files never sit on a spec branch, so the audit's budget gap closes |

## 2026-10-21 Scope decision: scoped final commit at sign-off

- Item: the delta module audit noticed that sign-off's "commit what is left" (5.8) stages without a folder scope, unlike 1.5 and 2.6, so an untracked draft spec folder in the checkout is swept into the finished spec's last commit; the large path multiplies such folders.
- Ruling: deferred, because the behaviour predates the large path, sign-off is unchanged by this spec (D23) and the fix is independent; the large path's own commits stay folder-scoped regardless (D22).
- Handoff: [.workflow/deferred/sign-off-scoped-commit.md](../../deferred/sign-off-scoped-commit.md) (AFK), also listed in spec.md `deferred`

## 2026-10-21 Questioning round 5 (loop-back from 0.4.7, delta audit)

**Q1. What does `task_review` mean for an initiative branch?**

- Why now: the delta audit found `local` means "no push" for task branches, colliding with "push the initiative branch when a remote exists" (D22); the push and merge steps cannot be written without one rule (codebase-map.md, delta audit gap and Out of scope).
- Options: A: same as task branches (`pr`/`pr-blocking` push and open the PR; `local` never pushes, merges locally with `--no-ff`) · B: always push when a remote exists · C: a separate `initiative_review` setting
- Recommended: A, because it is one rule read by the same script
- Answer: "Same as task branches (Recommended)"
- Decision: **D24** `task_review` governs the initiative branch as it governs task branches: `pr` and `pr-blocking` push at every commit point and open the PR/MR at `planned` and at `done` (`pr-blocking` waits for approval before merging); `local` never pushes and merges the branch into main locally with `--no-ff`. "Push when a remote exists" in D22 applies only under `pr` and `pr-blocking`.

**Q2. Which script opens the initiative's PR/MR into main?**

- Why now: the delta audit found `open-task-pr.sh` hard-wires task→spec and the gh/glab switch is already restated three times.
- Options: A: extend `open-task-pr.sh` with a generic head/base mode · B: a new `open-initiative-pr.sh` with its own copy of the switch
- Recommended: A, because it reuses the coded host switch, auth precheck, open-PR reuse and `skipped:` contract
- Answer: "Extend open-task-pr.sh (Recommended)"
- Decision: **D25** `open-task-pr.sh` gains a generic mode (`--head <branch> --base <branch> --title <t> [--record]`) used by the large path; the task mode is unchanged; `--record` in generic mode writes the URL through `initiative-transition.sh`. Sign-off's 5.8 prose is unchanged.

Facts looked up instead of asked (0.3.10): None.

**Orchestrator calls on the delta audit's remaining gaps** (routine mechanics; shown to the stakeholder at the 0.3.19 confirmation):

- Decision: **D26** When a folder is not in the working tree, the large path and the resume hook read `initiative.md` or `spec.md` with `git show <ref>:<path>`; the "every emitted spec is done" check reads each spec's frontmatter from the main branch, never from the working tree.
- Decision: **D27** When a remote exists, the large path fetches before re-creating the initiative branch and before the done check, and branches off `origin/<main_branch>` when that ref exists, else local `main_branch`.
- Decision: **D28** After the `planned` or `done` merge the local initiative branch is deleted, as task branches are after 3.16; reopen and the done flip re-create it.
- Decision: **D29** The large-path entry step requires a clean working tree and switches the main checkout to the initiative branch (fetching it when it exists only on the remote) before any other step.
- Decision: **D30** `check-write.sh` also scans `.workflow/initiatives/*/.step`; the large path's term-gate nodes join the glossary step list, so a Tier A write from an initiative is judged by the initiative's step.
- Decision: **D31** Discovery 0.1.1 also counts `refs/heads/spec/*`, `refs/remotes/origin/spec/*` and the `slices[].spec` records of every initiative when choosing the next spec number.
- Decision: **D32** `initiative.md` carries `merge_pr` (URL or null), written by `open-task-pr.sh --record` before `done`; the done PR is not recorded. `done` is terminal in the initiative script as in the spec script.
- The module audit is not re-run: round 5 chose among mechanics the delta audit already examined (its reuse rows for the host switch, `task_review`, fetch tests and branch cleanup).

## 2026-10-21 Impact classification (revised after round 5)

Rows that change against the earlier classifications; every other row stands.

| Part | Classification | Note |
| --- | --- | --- |
| `open-task-pr.sh` | extend | Generic `--head/--base/--title` mode beside the task mode; `--record` writes `merge_pr` through the initiative script (D25, D32) |
| `check-write.sh` | extend | Also scans `.workflow/initiatives/*/.step`; large-path term-gate nodes join the glossary step list (D30) |
| `modules/discovery.md` 0.1.1 | extend | Next spec number also counts spec branches and initiative slice records (D31) |
| `initiative.md` `merge_pr` | create | URL of the `planned` PR/MR, or null (D32) |
