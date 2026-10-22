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

## 2026-10-22 Discovered work (Phase 1)

- Dismissed discovered work: no-e2e-work-type: verification-setup 1.3 and 1.4 step 2 assume an e2e-browser work type and this project has none, every journey being a harness suite (`.agents/skills/feature-workflow/modules/verification-setup.md` § 1.3, § 1.4), not a blocker, user chose not to pursue; this spec records the Browser suite as `none` and 1.4 step 2 as not applicable.
- Dismissed discovered work: spec-number-origin: D31's next-number count omits a converted spec that left no folder and no branch, while the end state says its number is not reused (`.workflow/specs/001-large-path/design-log.md:316`, `tests/fixtures/initiative.sh` `next_spec_number`), not a blocker, user chose not to pursue a loop-back; clarification recorded: D31's count also includes each initiative's `origin`, as JRN-001 pins.

## 2026-10-22 Size budget (2.6)

- Approved budget overrun: max_changed_files reached 31 against 30 (predicted, `budget-check.sh --predicted`: 40 predicted files, 9 of them tests; 9 tasks against 10). Reason: "Approve the overrun (Recommended)", accepting the assessment that the one-file overrun is the scaffold-doc files granted at 2.1 (PLAN flow docs, `.gitignore`, PROVENANCE) and that a split would leave a capability's success line unmet. Budget raised to {max_tasks: 10, max_changed_files: 35} for this spec only (spec.md `budget`).

## 2026-10-22 Discovered work (Phase 3, wave 1)

- Dismissed discovered work: agent-docs-lint-chain: the agent-docs profile's `lint` key chains the four lint suites with `&&`, so while `lint/step-list` is red by design the symlinks and upstream-lineage suites never run in the toolchain (`.workflow/profiles/agent-docs.md` Toolchain `lint`; reported by the T8 and T3 implementation agents, artifacts/T8 and artifacts/T3 `toolchain.txt`), not a blocker, user chose not to pursue; proposal P3 in proposals.md for 5.3; until T2 merges, each agent-docs task's lint is judged by the three other suites plus the step-list assertions that are not JRN-007, run by the orchestrator and recorded as `lint-interim.txt` in the task's artifacts.
- Dismissed discovered work: signoff-flip-timing: T9's task-file criterion said sign-off 5.7 flips the initiative to `done`, which contradicts the rules that sign-off writes nothing into an initiative and that a spec is `done` only on main after 5.8 (`.workflow/specs/001-large-path/design-log.md:266,311`; T9 implementation return), not a blocker, user chose not to pursue; reading confirmed: the flip runs on the initiative's next resume after the 5.8 merge, as the spec's CAP-NEW-initiative-close success line says, with sign-off handing off to the large path's close step (6.13); T9 stands as written and the task-file wording was the orchestrator's mis-statement.

## 2026-10-22 Discovered work: test-scoped-missing

- Found at 3.7 by the T1 profile-mini-review (`out_of_scope_noticed`, kind decision; the T8 mini-review reported the same, kind refactor). Kind recorded: refactor.
- Problem: no profile has a `test_scoped` command and `tests/run-all.sh` has only `--suite NAME`, so the toolchain cannot exclude unfinished tasks' Phase 1 tests; every task's `test` key is reported unscoped and judged by hand.
- Evidence: `artifacts/T1/toolchain.json` warnings; `.workflow/profiles/*.md` `test_scoped: ""`; `tests/run-all.sh` usage header.
- Assessment: can be solved later; no capability or journey depends on it. Ruling: not a blocker, tackle it as a next feature.
- Backlog item: [work-backlog/001-large-path-disc-001.md](../work-backlog/001-large-path-disc-001.md)

## 2026-10-22 Wave 1 merged (3.16)

- Task PR/MR records skipped for T1, T3, T8 and T9: `open-task-pr.sh` printed `skipped: gh not installed` (the origin is GitHub and `task_review` is `pr`), so `pr` stays null on all four records; the spec branch was pushed to origin (`spec/001-large-path`, new branch) after the merges.
- Gate 3.9 after wave 1 (`artifacts/gate-3.9-w1/`): lint pass; `test` unscoped (no `test_scoped`, see work item disc-001), judged by hand: the 21 suites outside the exclusion list pass (TOTAL passed=2096 failed=92, 31 suites), and the only failing suites are the ten owned by pending tasks and listed in `excluded-tests.txt`. Passes the scoped bar.

## 2026-10-22 Discovered work (Phase 3, wave 2)

- Dismissed discovered work: repo-settings-deny-entry: this repo's own `.claude/settings.json` has no owning module and will still lack the deny rule `Edit(.workflow/initiatives/*/.step)` that T6 adds to the settings templates (`.claude/settings.json:158` names only the spec marker; T6 implementation return), not a blocker, user chose not to pursue; a one-line config edit outside the spec, to be reminded at sign-off.

## 2026-10-22 Discovered work: validator-stderr-hidden

- Found at 3.7 by the T4 profile-mini-review (`out_of_scope_noticed`, kind bug).
- Problem: both single writers send the validator's stderr to `/dev/null` when checking a prepared write, so a yq runtime error is reported as a validator refusal and its diagnostic is lost.
- Evidence: `initiative-transition.sh:189`; `status-transition.sh:344`.
- Assessment: can be solved later; no file is corrupted (the copy is discarded before the move). Ruling: not a blocker, tackle it as a next feature.
- Backlog item: [work-backlog/001-large-path-disc-002.md](../work-backlog/001-large-path-disc-002.md)
- Note: work item disc-001 (test-scoped-missing) was promoted by another session to `.workflow/specs/004-scoped-test-runs` while this wave ran.

## 2026-10-22 Discovered work: initiative-branch-lookup-duplicated

- Found at 3.7 by the T6 profile-mini-review, round 2 (`out_of_scope_noticed`, kind refactor).
- Problem: the rules for finding an initiative by its `initiative/NNN-*` branch (local and origin, `git show` from the tip) are written twice, in `codex-pre-spawn.sh` and `session-start-resume.sh`; both copies agree today.
- Evidence: `codex-pre-spawn.sh:100-110`; `session-start-resume.sh:64-72,126-135`.
- Assessment: can be solved later; behaviour unchanged and pinned by both hook suites. Ruling: not a blocker, tackle it as a next feature (a lib helper, shared core, with the shelved normaliser).
- Backlog item: [work-backlog/001-large-path-disc-003.md](../work-backlog/001-large-path-disc-003.md)

## 2026-10-22 Wave 2 merged (3.16)

- T2, T4 and T6 merged in id order after 2, 5 and 4 review rounds (T4's final round re-judged by its round-4 reviewer; the orchestrator ran the shell-scripts shellcheck at T4's head before merging). PR records skipped again (`gh` not installed); the spec branch was pushed to origin.
- Gate 3.9 after wave 2 (`artifacts/gate-3.9-w2/`): lint pass; `test` unscoped, judged by hand: TOTAL passed=2219 failed=24 (31 suites); the three excluded suites (T5's and T7's) are red as expected; outside the excluded set only four assertions fail, all on T7's pending seam (the three `research` checks in `hooks/codex-pre-spawn-initiative`, which need the `research` row in `resolve-launch.sh`, and the one `lint/step-list` line "check-write.sh step lists name 6.x steps"), both named in T6's and T2's returns; every other suite passes. Passes the scoped bar; T7 is launched in wave 3.

## 2026-10-22 Wave 3 merged (3.16)

- T5 and T7 merged in id order after 2 review rounds each (T5's last round was a test-only addition, no further review). PR records skipped again (`gh` not installed); the spec branch was pushed to origin. Every task is `done`.
- Gate 3.9 after wave 3, the last wave (`artifacts/gate-3.9-w3/`): nothing excluded; lint pass; `test` pass: TOTAL passed=2280 failed=0 (31 suites). The 1.1 coverage target reads 0 uncovered scripts. CI: none in this project (the run by hand is the gate).
- 3.10-3.11: the Browser suite is `none` (discovered work no-e2e-work-type, dismissed at 1.3); every journey JRN-001 to JRN-008 is a harness suite named in the Check column and every one passes in the gate above, so the spec moves to `in-review` at 3.11.

## 2026-10-22 Triage, review pass 1

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | review-standards (RS-1) | The initiative single writer is committed without the executable bit while the module runs it directly; no `Bash(...initiative-transition.sh:*)` allow entry in the settings template; the suites call it through `bash` | `.agents/skills/feature-workflow/scripts/initiative-transition.sh` (mode 100644); `.agents/hooks/claude-settings.template.json:132-140`; `tests/fixtures/initiative.sh:59` | high | `git ls-files -s` shows 100644 against 100755 for every sibling; the template lists every sibling script and not this one; the fixture's `IT` helper runs `bash "$p/$IT_REL"`, so no suite exercises the direct call the module prescribes; every `IT` call as written exits 126 | patch (T4: executable bit and a direct call in the fixture; T6: the allow entry) |
| F2 | review-standards (RS-2) | PROVENANCE's feature-workflow row lists none of the module, the two templates and the script this change adds; the test-harness row still says 23 suites | `PROVENANCE.md:11,37` | medium | grep finds no `large-path`, `initiative-transition`, `initiative.md` or `questions.md` in the feature-workflow row; the harness row reads "23 suites" against 31 now | patch (T8) |
| F3 | review-standards (RS-3) | The new writer's exit codes (1 usage or environment, 2 illegal) are the profile's other way round | `initiative-transition.sh:50-51,69-83` | low | real, but the spec constraint requires "the spec single writer's exit-code contract" and the module and suites rely on it; the fix is to the profile | defer (proposal P5) |
| F4 | review-standards (RS-4) | Two test comments carry a `JRN-007:` prefix pointing at this spec's verification plan | `tests/lint/step-list.sh:86`; `tests/scripts/step-progress.sh:89` | medium | both lines read `# JRN-007: ...`; readable-code R4 at 4.1 grades medium; labels may carry the tag, comments may not | patch (T2) |
| F5 | review-standards (RS-5) | Design-log entry shapes written twice (template and inline in the modules) and already diverging | `modules/large-path.md:83-87,185-198`; `modules/discovery.md:60-65`; `assets/design-log.md` | medium | the module's conversion entry has Spec and Reason; the template's has Spec, Initiative created, Number consumed, Reason, Re-pointed; the round entries differ field for field | patch (T9) |
| F6 | review-standards (RS-6) | Journey-named suites and `tests/fixtures/` conflict with the profile's one-suite-per-component and lib/common.sh rules | the eight new suites; `tests/fixtures/initiative.sh` | low | real; the verification plan agreed the layout at Phase 0 and the suites pass; the fix is to the profile | defer (proposal P6) |
| F7 | review-end-state (RE-1) | Sign-off hands every merged spec carrying `initiative:` to 6.13 without checking the initiative is `planned` on main; for an `exploring` initiative the spec list from the main ref is empty, so 6.13 takes the "None listed" branch and tries to flip it | `modules/sign-off.md:133`; `modules/large-path.md` 6.13 | high | read both: no status check before the loop; `git show` of a file absent from the ref yields empty output and exit 0 through yq, so "None listed" fires; `git switch -c` then fails on the existing branch or creates an empty one; the common case (first emitted spec signs off while the initiative explores) ends in an error, and an agent may improvise past the single writer | patch (T9) |
| F8 | review-end-state (RE-2) | The 6.4 research launch body (Question, Settled context, Affected area) does not match research.md's Input (question with id, the initiative's goal, settled lines) | `modules/large-path.md` 6.4; `.agents/agents/research.md` Input | low | read both lists; the goal is missing from the body and Affected area is not an input the agent names | patch (T9) |
| F9 | review-standards (not_checked, orchestrator) | AGENTS.md lists the gitignore block's entries without `.workflow/initiatives/*/.step`, which T1 added to `GI_ENTRIES` | `AGENTS.md:27` | low | the line enumerates the five old entries; the repo rule says the block is kept in step with `GI_ENTRIES` | patch (T1) |
| F10 | review-end-state (not_verifiable) | This repo has no `.workflow/model-map/research.md`, which the spec's Assumptions say it records; the first research launch here would stop at 00.14 | `.workflow/model-map/` | gap (no verdict) | `ls` finds no file; the model is a stakeholder choice | defer ([.workflow/deferred/research-model-map.md](../../deferred/research-model-map.md)) |
| F11 | review-end-state (not_verifiable) | The success line "the next session writes the answer back" is met only when a research return is in hand; otherwise 6.2 resets the question to `open` and relaunches, and whether a host keeps a sub-agent result across sessions lives outside the repo | `modules/large-path.md` 6.2 | maybe-false (medium if true, unverified) | settled by the stakeholder accepting relaunch-on-new-session at 5.5, or by a host mechanism that preserves the result | defer ([.workflow/deferred/research-across-sessions.md](../../deferred/research-across-sessions.md)) |
| F12 | review-end-state (not_verifiable) | The journeys are proven by harness replays of the module's command sequences, not by an orchestrator running the module | the eight JRN suites | gap (no verdict) | inherent to a prose deliverable; only a live initiative shows the module is followed as the suites replay it | defer ([.workflow/deferred/large-path-live-run.md](../../deferred/large-path-live-run.md)) |
| F13 | review-targets (not_measurable) | The session-start hook wall-time target has no threshold or command, by the 1.1 decision | `verification-plan.md` Targets row 5 | gap (no verdict) | the measurements table reports `not_measurable` with the 1.1 reason | defer ([.workflow/deferred/session-start-timing-target.md](../../deferred/session-start-timing-target.md)) |

Failed lenses: none
Outcome: rework 1 of 5

## 2026-10-22 Discovered work: codex-adapters-flaky-check

- Found at 3.4 (rework 1) by the T1 implementation agent. Kind: bug.
- Problem: the check "workflow not installed -> silent allow" in `tests/hooks/codex-adapters.sh` failed once in a full run and passed four times after; two checks share the name, so the failure cannot be traced to a line; six harness runs were executing in parallel at the time.
- Evidence: `tests/hooks/codex-adapters.sh:146,203`; the first T1 rework toolchain run.
- Assessment: can be solved later; not touched by this spec. Ruling: not a blocker, tackle it as a next feature.
- Backlog item: [work-backlog/001-large-path-disc-004.md](../work-backlog/001-large-path-disc-004.md)

## 2026-10-22 Rework 1 merged (3.16)

- T1, T2, T4, T6, T8 and T9 rework branches merged in id order after one review round each (every patch from review pass 1 landed: the writer's executable bit and direct fixture call, the settings-template allow entry, the PROVENANCE rows, the two comment prefixes, the 6.13 status gate with its sign-off sentence and JRN-005 assertion, the entry shapes pointing at the template, the research launch body, the AGENTS.md gitignore line). PR records skipped (`gh` not installed); the spec branch was pushed.

## 2026-10-22 Gate 3.9 after rework 1: lint fix round (T9)

- First run ([artifacts/gate-3.9-rework1/](artifacts/gate-3.9-rework1/toolchain.txt)): harness 2281/2281 over 31 suites, but the test-harness lint key (shellcheck over `tests/`) exited 1 on three warnings in `tests/scripts/initiative-merge.sh`, all in the JRN-005 check the T9 rework added: SC1010 twice (`done` passed as a status value on a `for` line) and SC2034 (`before` read only inside the eval'd check expression). T9's own toolchain is the agent-docs one, which does not shellcheck `tests/`, so the warnings reached the gate.
- T9 reopened at 3.9 (`done` -> `in-progress`) for one fix round in a fresh worktree off 93b12bc: the two status arguments quoted, SC2034 added to the file's header disable list with its reason extended. The agent's first commit displaced the `gh and glab are stubs` header line; a second commit restored it. Toolchain pass on the agent's run and the orchestrator's; shellcheck over `tests/` exit 0 ([artifacts/T9/lint-test-harness.txt](artifacts/T9/lint-test-harness.txt)); mini-review pass (readable-code items only, the agent-docs checklist not applicable). Merged as f534388 (`Merge T9 fix`), spec branch pushed; PR skipped (`gh` not installed). Budget after the merge: 9 tasks of 10, 31 changed files of 35 (the suite counts as a test file).
- Second run ([artifacts/gate-3.9-rework1b/](artifacts/gate-3.9-rework1b/toolchain.txt)): lint pass, harness 2281/2281 over 31 suites, nothing excluded (every task `done`). CI: none to run. 3.10-3.11: Browser suite `none` as recorded at wave 3; every journey is a harness suite and passes, so the spec returns to `in-review` at 3.11 for review pass 2.

## 2026-10-22 Triage, review pass 2

Head reviewed: f534388 (rework 1 and its lint fix round merged). Lenses: review-standards (no findings), review-end-state (one finding), review-targets (no findings; four targets pass, the wall-time row `not_measurable` as decided at 1.1). Every pass 1 patch (F1, F2, F4, F5, F7, F8, F9) was confirmed in place by the lenses; none of the pass 1 findings reappeared, so nothing is carried.

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F14 | review-end-state (RE-1) | 6.13 reads the initiative's status only from the main ref, so a `planned` initiative that was reopened at 6.12 (branch `initiative/NNN-slug` re-created with status `exploring`, main still `planned`) is taken as closable when its last original emitted spec signs off: `git switch -c` fails on the existing local branch, or, when the reopened branch lives only on `origin`, the stale main copy is flipped `done` and merged while exploration continues on the branch | `.agents/skills/feature-workflow/modules/large-path.md` 6.13, `planned` / None listed; `tests/scripts/initiative-merge.sh` JRN-005 (covers only the absent-from-main case) | medium | read 6.12 and 6.13: 6.12 re-creates the branch from main and sets `exploring` on the branch only; 6.13 checks nothing but `git show "$main_ref:..." \| yq .status` before the flip; `initiative-transition.sh` has no branch guard, so after a failed switch the following `IT` calls would write the working tree on the current branch. Caused by the rework 1 patch (F7). Harm: a stakeholder who reopened a planned initiative and then signs off an original spec gets a git error, or a `done` initiative on main that abandons the reopened branch and conflicts at its next merge; uncommon path, recoverable by hand, so medium | patch (T9: an existing `initiative/NNN-slug`, local or on `origin`, means reopened and still exploring: report, write nothing; a JRN-005 assertion for the reopened case) |

Gaps carried from pass 1, already shelved, not re-deferred: F10 (`.workflow/model-map/research.md` absent), F11 (research answer across a session end), F12 (no live run of the module), F13 (hook wall time not measured). The standards lens's below-threshold note that `# Suite:` and `# Covers:` headers name JRN ids was ruled at pass 1 (headers and labels carry the tag, body comments do not) and is not reopened.

Notes for sign-off: the targets lens measured 2303 checks over 32 suites because the working tree holds another session's untracked suite `tests/scripts/commit-workflow-data.sh` (22 checks); this spec's gate at f534388 is 2281 over 31 suites. The working tree also holds other sessions' uncommitted edits (`modules/implementation-orchestrator.md`, `PROVENANCE.md`, `tests/README.md`, the two `commit-workflow-data.sh` files, `decisions/adr/0002-review-lessons-placement.md`): none is this spec's work and none may enter its sign-off commit. The four `.workflow/deferred/` files this spec wrote are untracked and are committed at sign-off with the spec folder.

Failed lenses: none
Outcome: rework 2 of 5

## 2026-10-22 Rework 2 merged (3.16) and gate 3.9

- T9 rework 2 (F14) merged as 782c9ae (`Merge T9 rework 2`) after one review round: 6.13 checks for an existing `initiative/NNN-slug` (local or on `origin`) before listing specs, and a present branch means the planned initiative was reopened and is still exploring (report, write nothing); `close_check` in `tests/scripts/initiative-merge.sh` replays the check and four JRN-005 assertions cover the reopened case with a local branch and with the branch only on `origin` (red first, then green). Toolchain pass on the agent's run and the orchestrator's; shellcheck over `tests/` exit 0; mini-review pass. PR skipped (`gh` not installed); spec branch pushed. Budget: 9 tasks of 10, 31 changed files of 35.
- Gate ([artifacts/gate-3.9-rework2/](artifacts/gate-3.9-rework2/toolchain.txt)): lint pass; harness 2311 passed, 0 failed, 32 suites, nothing excluded. The 32nd suite is another session's untracked `tests/scripts/commit-workflow-data.sh` (26 checks), which `tests/run-all.sh` picks up from the working tree; this spec's suites are 31 with 2285 checks. No stray output, no temp dirs, worktrees or branches left behind, no tracked file touched by the run. CI: none. 3.10-3.11: Browser suite `none`; every journey suite passes, so the spec returns to `in-review` at 3.11 for review pass 3.
- Stakeholder note (2026-10-22, after the gate): the stakeholder said the tests are not working right and told the orchestrator to continue without waiting on them. Recorded as said; the gate result above stands as run. Carried to the 5.4 report.

## 2026-10-22 Triage, review pass 3

Head reviewed: 782c9ae (rework 2 merged). Lenses: review-standards (three findings), review-end-state (one finding), review-targets (no findings; four targets pass, the wall-time row `not_measurable` as decided at 1.1). F14 was confirmed fixed for both cases it named; its fix is the cause of F15.

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F15 | review-end-state (RE-1) | The rework 2 check at 6.13 treats an existing `refs/remotes/origin/initiative/NNN-slug` as proof that the initiative was reopened. Under `task_review: pr` or `pr-blocking` (the default, and this repo's setting) the branch is pushed at every commit point, 6.11 deletes only the local branch after the `planned` merge, and the Conventions fetch does not prune, so the remote branch is always there: 6.13 reports "reopened, still exploring" and a planned initiative never closes | `.agents/skills/feature-workflow/modules/large-path.md` 6.13 (`planned`, branch present); 6.11 (`git branch -d` only); Conventions commit point (`git push -u origin initiative/NNN-slug`) and main ref (`git fetch -q origin`) | high | read the module at HEAD: line 53 pushes the branch under `pr`, lines 232-233 push main and delete only the local branch, line 44 fetches without `--prune`; no `push --delete`, `:refs` or prune anywhere in the module, `open-task-pr.sh` or the hooks. The merge suite runs the done flip only in the `local` fixture, so no assertion met this. Undoes CAP-NEW-initiative-close in the default review mode; caused by rework 2 (F14) | patch (T9: a reopened initiative is told apart by what the branch holds, the branch tip's `initiative.md` reading `exploring`, never by the branch existing; a JRN-005 assertion under `pr`: planned merge, branch left on origin, every spec done, 6.13 flips to `done`) |
| F16 | review-standards (RS-1) | `session-start-resume.sh` holds the initiative-listing rules inline (which ref wins, the done-on-main test, hiding a `planned` initiative whose specs are all done) instead of calling a skill script; the router's own listing in `SKILL.md` branch 4 shows every initiative unfiltered | `.agents/hooks/session-start-resume.sh:66-200`; `SKILL.md:29-33` | low | real as a profile reading, but the hook listed specs inline the same way before this change (171 lines at the baseline, no script), T6's brief and the capability's success line prescribe exactly this offer (`exploring`, or `planned` with an emitted spec not yet `done`), and T6's mini-review judged the thin-hook criterion; the router's unfiltered list is harmless (a picked planned-all-done initiative goes to 6.13 and closes). Harm is maintenance only: the resume rules would drift from the module. Grouped with F17 (same root cause: initiative lookup and listing rules live in the hooks) | discovered work, already ruled: [work-backlog disc-003](../work-backlog/001-large-path-disc-003.md) (2026-10-22, not a blocker, next feature); the listing helper belongs in that item's shared lookup, to be noted when it is taken up (offered again at 5.9) |
| F17 | review-standards (RS-3) | The initiative branch scan (`for-each-ref` over local and `origin` `initiative/*`, with the same comment) is written twice, in `codex-pre-spawn.sh` and `session-start-resume.sh`, and the copies already differ in how they match names | `.agents/hooks/codex-pre-spawn.sh:100-113`; `.agents/hooks/session-start-resume.sh:66-73` | medium | this is the duplicated lookup found at 3.4 and ruled by the stakeholder; the copies differ as the lens says, so the two hooks can disagree on whether an initiative exists | discovered work, already ruled: work-backlog disc-003, as F16 (group verdict medium) |
| F18 | review-standards (RS-2) | `initiative-transition.sh` exits 1 on usage or environment errors and 2 on a refused transition, the reverse of the profile's convention for new scripts | `initiative-transition.sh:50-51` | low | carried from F3 | defer (proposal P5) |

Gaps carried from pass 1, already shelved, not re-deferred: F10 (`.workflow/model-map/research.md` absent), F11 (research answer across a session end), F12 (no live run of the module), F13 (hook wall time not measured). Below-threshold notes not raised: `sign-off.md:133` describes 6.13 without the branch-present case (moot once F15 is settled); `tests/fixtures/` is not in the test-harness profile's File locations (proposal P6 covers the layout). The end-state lens asks what the stakeholder meant by the tests not working right; the stakeholder has said to continue without further test checks, and the note stands in the Rework 2 entry for the 5.4 report.

Failed lenses: none
Outcome: loop back (4.6 third pass)

## 2026-10-22 Questioning round 6 (loop-back from 4.6, review pass 3)

**Q1. How does 6.13 recognise a reopened initiative?**

- Why now: review pass 3 F15: the rework 2 check treats an existing `initiative/NNN-slug` branch, local or on `origin`, as proof of a reopen; under `task_review: pr` or `pr-blocking` the branch is pushed at every commit point and 6.11 deletes only the local copy, so the remote branch is always there and a planned initiative never closes.
- Options: A: by the branch's status: reopened means the branch tip's `initiative.md` reads `exploring` (6.12 sets that); a branch whose tip reads `planned` (the stale remote under `pr`) is ignored and the done flip proceeds · B: keep the existence check and have 6.11 delete `origin/initiative/NNN-slug` after each merge, with a pruning fetch · C: both · defer to deep dive
- Recommended: A, because it is the smallest fix, changes no push or merge step, and matches 6.12's own semantics (the branch carries `exploring` only when the initiative was reopened); B still breaks on a host that keeps branches or a clone that has not pruned.
- Answer: "By the branch's status (Recommended)"
- Decision: **D33** 6.13 recognises a reopened initiative by the status its branch tip carries: when `initiative/NNN-slug` exists locally or on `origin` and its `initiative.md` reads `exploring`, the initiative is still exploring and 6.13 writes nothing; a branch whose tip reads anything else is not a reopen, and the status on main decides as before. A stale `origin/initiative/NNN-slug` left by a `pr` merge never stops the close. Supersedes the "branch present" rule written at rework 2 (F14 stays fixed: a reopened branch carries `exploring`).

Facts looked up instead of asked (from the module and the suite at 782c9ae): the commit point pushes the branch under `pr` and `pr-blocking` (large-path.md:53); 6.11 pushes main and deletes only the local branch (:232-233); the main-ref fetch does not prune (:44); 6.12 re-creates the branch from main and sets `exploring` on the branch only; the merge suite runs the done flip only in its `local` fixture. Term gate: no new term. Scope gate: nothing out of scope.

## 2026-10-22 Impact classification (revised after round 6)

Rows that change against the earlier classifications: none. D33 changes the prose of one step (6.13 in `modules/large-path.md`, with the matching sentence in `modules/sign-off.md`) and the JRN-005 replay in `tests/scripts/initiative-merge.sh`; no entity, field, script interface or migration in `data-model.md` moves. 0.4.6: the module audit on file stands; the delta touches no interface the audit would re-read, so no audit was relaunched. 0.4.7: no conflict with the goal or the placement.

## 2026-10-22 Phase 1 re-entry (1.3-1.5) after the 4.6 loop back

- 1.1: spec branch, baseline and Targets unchanged. 1.3: one Phase 1 build added five JRN-005 checks for step 5 (the done flip under `pr` with the stale remote branch) to `tests/scripts/initiative-merge.sh`; merged as 1a2718a; stop audit clean (lint pass, test skipped by design). 1.4: Run 3 in [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md): the two flip checks fail on assertions at HEAD, the three setup checks pass. 1.5: Suites table unchanged; the spec folder is committed on the spec branch. The branch is red by design again until the task for D33 lands.

## 2026-10-22 Task breakdown re-entry (2.1-2.6) after the 4.6 loop back

- 2.1: one slice, T10 "Close recognises a reopened initiative by its branch status" (D33), approved as drafted by the stakeholder; the nine existing tasks stay `done`. 2.5: task file and record written, `depends_on: [T9]` for the shared module files (T9 is done, so T10 runs alone in its wave); `tests` names the five "JRN-005 under pr" checks in `tests/scripts/initiative-merge.sh` (the suite file itself stays T5's). 2.6: 10 tasks of 10, changed files unchanged; within budget on both checks.
