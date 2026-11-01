# Design log: Slim the workflow context

Spec: [spec.md](spec.md)

## 2026-10-29 Term gate 0.2.2

Agreed and written to `.workflow/GLOSSARY.md` at 0.2.3: **Router**, **Step file**, **Term list**, **Workflow conventions**, and a flagged ambiguity resolving bare "module" to the code module. The stakeholder chose "Step file" over the recommended "Phase module".

## 2026-10-29 Placement: feature-workflow

- Owning module: feature-workflow (the router, the step files, the workflow conventions).
- Also touched: domain-modeling (new term-list script beside `assets/GLOSSARY-FORMAT.md`), output-styles (`concise-technical.md` inlines a one-line grep instead of naming the script, since output-styles may depend on nothing), hooks (only if a step-file path the hook names changes), tests.
- Alternatives considered: feature-workflow scripts/ for the term-list script: domain-modeling and the output style could not reference it without new dependencies (a 5.3 rule proposal). lib (shared core): would route a small script through the integration agent for no gain.
- Folder: keep `feature-workflow/modules/`; docs call its files step files. pr-quality, project-standards and project-setup also use `modules/`, so renaming only this one breaks the pattern.
- Conflict with an ADR or rule: none. feature-workflow → domain-modeling and hooks → feature-workflow are already allowed in `.workflow/rules.md` Ownership. Fails the ADR test (easy to reverse), so no placement ADR.
- Decision: **D1** feature-workflow owns the change; the term-list script lives in domain-modeling; the output style inlines the grep; `modules/` keeps its name.

## 2026-10-29 Deeper prompt

**Ask:** Load only the instructions the current step needs, so a session spends its context on the work rather than on workflow text it never uses. The workflow's behaviour stays exactly the same.

**Goals:**
- Starting a new feature and resuming at implementation each load clearly fewer bytes than today's 68 KB and 66 KB, measured with `wc -c`.
- Every rule lives in exactly one file. The **Workflow conventions** file is the one place for them, and both the **Router** and `large-path.md` point to it.
- A session loads the **Term list** and reads one glossary definition only when a term in play matches.
- Every route, step id, guard, script and test behaves as it does today, and `tests/run-all.sh` passes.

**Downstream:** Clear-and-resume offers at phase changes, a lint that caps step-file size, and the same slimming applied to other skills will probably build on this, so the step-file layout and the term-list script should be reusable outside feature-workflow.

**Tools and technologies:** No preference. The default is plain `wc` byte counts and in-house bash checks, with no new dependencies.

**Gotchas:** None known.

**Not asked for:** Clear-and-resume offers at phase changes; renaming `modules/`; slimming skills other than feature-workflow; a size-cap lint.

**Original request:** "Start a spec: reduce the context the workflow loads. Scope: (1) slim SKILL.md to a router — move sub-agent launch rules, host notes and the loop-back table into the modules that use them, delete the Modules table; (2) split discovery.md into 0.1–0.2 and 0.4–0.6; (3) glossary terms-only index (grep of **Term**: lines) with a script to look up one definition on match, and switch the always-load to the index; (4) split implementation-orchestrator.md into setup (3.1), wave loop (3.2–3.8), rework and handoff to review; (5) merge large-path.md conventions with SKILL.md conventions into one source both reference. Out of scope for now: phase-change resets (clear-and-resume offers)."

Revisions: round 1 added downstream (the later features probably apply), no tool preference, no known gotchas; agreed as restated ("ready to pass").

## 2026-10-29 Questioning round 1

**Q1. Where do the sub-agent launch rules and host notes go when they leave SKILL.md?**

- Why now: the deeper prompt requires every rule to live in one file, so copying them into each step file is out.
- Options: A: `references/launching.md`, read only at a launching step · B: fold into the workflow conventions file (always loaded) · defer
- Recommended: A, because sessions that launch nothing never pay for about 3.8 KB of launch and Codex text (codebase-map.md, Relevant code: Conventions section `SKILL.md:124-196`).
- Answer: "references/launching.md (Recommended)"
- Decision: **D2** Launch header rules, the 00.14/00.19 denies and the Claude and Codex launch rows move to `feature-workflow/references/launching.md`; step files read it at the step that launches.

**Q2. Where does the 5.6 re-entry and loop-back table go?**

- Why now: it leaves the router (scope item 1).
- Options: A: merge into the questioning loop's Entry seed table · B: workflow conventions · defer
- Recommended: A, because every loop-back already loads the questioning loop, and each gate's step file already makes its own status call.
- Answer: "Questioning-loop Entry (Recommended)"
- Decision: **D3** The gate table merges into the questioning-loop Entry; each gate's step file keeps its status call; the router keeps only the 5.6 call it owns.

**Q3. Where is discovery.md split?**

- Why now: scope item 2 named 0.1–0.2 | 0.4–0.6, but 0.3.1–0.3.7 runs before the questioning loop.
- Options: A: 0.1–0.3.22 | 0.3.20 + 0.4–0.6 · B: 0.1–0.2 | 0.3 + 0.4–0.6 · defer
- Recommended: A, because the split then falls at the questioning loop, so each session loads one half only.
- Answer: "0.1–0.3.22 | 0.3.20 + 0.4–0.6 (Recommended)"
- Decision: **D4** Discovery splits into a before-the-loop step file (0.1–0.3.7, 0.3.22) and an after-the-loop step file (0.3.20, 0.4–0.6, the fresh-session offer).

**Q4. Does the term list print `_Avoid_` aliases?**

- Why now: the term gates check a raised word against the glossary; with names only, a conflicting alias is missed.
- Options: A: names plus aliases · B: names only · defer
- Recommended: A, so a term gate can spot a conflicting word from the list alone.
- Answer: "Names plus aliases (Recommended)"
- Decision: **D5** The term list prints one line per term with its `_Avoid_` aliases.

Facts looked up instead of asked (0.3.10):
- implementation-orchestrator.md sections: Launching agents 6,628 B (3.2, 3.3, 3.7, 3.8); Evidence and the ledger 4,134 B (holds the 4.7 rework entry); 3.1 2,542 B; wave loop with 3.2, wave start, 3.3, per-task gates (6,860 B), 3.16 (4,330 B), 3.15 (2,570 B); then 3.9 2,081 B, 3.10–3.11 1,584 B, 3.13–3.14 989 B, Discovered work 2,531 B, Stops 2,284 B, Hand off 561 B. `#stops` and `#evidence-and-the-ledger` are linked from many sections; `large-path.md:223` links `#316-merge-the-wave` (source `modules/implementation-orchestrator.md`).
- No lint checks markdown links or anchors (source `tests/lint/*.sh`).
- No `.workflow/GLOSSARY-MAP.md` exists; an entry is `**Term**:`, a definition line, an optional `_Avoid_:` line (source `domain-modeling/assets/GLOSSARY-FORMAT.md:3-44`).
- Seven links to SKILL.md anchors, all from step files: `#host-notes` (review-triage.md:34, questioning-loop.md:42, discovery.md:78, 127, 218), `#5-conventions-every-module-follows` (discovery.md:3), `#3-route-by-status` (discovery.md:257).
- install-manifest lists `skills/feature-workflow` as one directory line, so new files need no manifest line; PROVENANCE.md has per-file bullets for step files (rules.md:142 requires updating it); upstream-lineage.json needs an entry only for a file naming an upstream (source `install.sh:126-162`, `PROVENANCE.md:134-156`).
- Nothing in `.codex/` or install.sh reads SKILL.md or step-file sections specially (source `.codex/README.md:16`, `install.sh:495`).

## 2026-10-29 Questioning round 2

**Q1. How is implementation-orchestrator.md split?**

- Why now: the round 1 facts give its section sizes and cross-links.
- Options: A: setup (3.1) | waves (3.2–3.8, 3.16, 3.15, launching, evidence, stops, discovered work, 4.7 rework entry) | finish (3.9, 3.10–3.11, 3.13–3.14, hand off) · B: waves | finish, 3.1 kept in waves · defer
- Recommended: A, the stakeholder's three-way split with rework kept beside the waves because rework relaunches tasks; peak load in one unbroken session stays about the same, savings show on resume and rework.
- Answer: "Setup | waves | finish (Recommended)"
- Decision: **D6** implementation-orchestrator splits into setup (3.1, skipped on resume once `impl_base_revision` is set), waves (wave loop and its shared sections plus the 4.7 rework entry) and finish (3.9–3.14 and hand off).

**Q2. How is the workflow conventions file loaded?**

- Options: A: the router's route step reads it with the step file · B: each step file links it at the top · defer
- Recommended: A, one line in one place.
- Answer: "Router loads it (Recommended)"
- Decision: **D7** The router loads the workflow conventions together with the first step file.

**Q3. How do we prove the split broke no link?**

- Why now: no lint checks markdown links or anchors (round 1 fact).
- Options: A: new in-house suite `tests/lint/md-links.sh` checking relative links and anchors under `.agents/` · B: one-off check in review · defer
- Recommended: A, in-house bash per the library evaluation (codebase-map.md, Library options).
- Answer: "Add a link lint (Recommended)"
- Decision: **D8** Add a link-and-anchor lint suite for markdown under `.agents/`, run by `tests/run-all.sh`.

**Q4. What byte targets make the size goal pass?**

- Options: A: new-feature start ≤ 45 KB and implementation resume ≤ 55 KB, measured once with `wc -c` · B: any reduction · defer
- Recommended: A; estimates are ~40 KB and ~54 KB; measured once, not enforced by a test (a size-cap lint is not asked for).
- Answer: "≤45 KB and ≤55 KB (Recommended)"
- Decision: **D9** Targets: new-feature start ≤ 45 KB (AGENTS.md, hook output, router, conventions, first discovery step file, term list, rules.md blocks); implementation resume ≤ 55 KB (AGENTS.md, hook output, router, conventions, waves step file). Measured with `wc -c` and recorded in the report.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-29 Questioning round 3

**Q1. How do the large-path conventions merge with SKILL.md's?**

- Why now: D7 settled how the conventions file loads; `large-path.md:7-58` repeats one-writer, exit codes, set-the-step, progress line, launches and sub-agent writes.
- Options: A: shared rules once in the conventions file; large-path keeps only initiative-specific facts · B: everything, including the IT forms and the 6.x table, in the conventions file · defer
- Recommended: A, so spec sessions do not load initiative-only text.
- Answer: "Shared rules once (Recommended)"
- Decision: **D10** The workflow conventions file states once, for specs and initiatives: one writer per state, exit codes 0/1/2, set the step then write, the progress line, sub-agents write only their own result file. large-path keeps the IT command forms, its 6.x writer and term-gate table, the main ref and the commit point. The Codex `i<NNN>` task names move to `references/launching.md`.

**Q2. Who else switches to the term list?**

- Options: A: also domain-modeling's challenge step and large-path 6.6 · B: only the output style and discovery 0.2.1 · defer
- Recommended: A.
- Answer: "Only the two named"
- Decision: **D11** Only the output style and discovery 0.2.1 switch to the term list; domain-modeling term gates and large-path 6.6 keep reading the glossary as today.

**Q3. Does the term-list script support a glossary map?**

- Options: A: with a `GLOSSARY-MAP.md`, list every mapped glossary labelled by context, else the root glossary; `--define <term>` prints one entry · B: root glossary only · defer
- Recommended: A, for target projects with several contexts and later reuse.
- Answer: "Support the map (Recommended)"
- Decision: **D12** The domain-modeling term-list script lists terms with aliases from every glossary a `GLOSSARY-MAP.md` names (or the root glossary when there is none) and prints one whole entry with `--define <term>`.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-29 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Router `SKILL.md` (Route table, step-file load line, frontmatter `modules:` list) | refactor | Loads conventions with the step file; routes to the new step files; see data-model.md § Summary |
| Workflow conventions `references/conventions.md` | create | Shared rules from SKILL.md §5 and large-path.md Conventions (D10) |
| Launch reference `references/launching.md` | create | Launch header, denies, host rows, Codex task names (D2) |
| Discovery step files | refactor | Split before / after the questioning loop (D4) |
| Implementation step files | refactor | Split setup / waves / finish (D6) |
| Questioning-loop Entry seed table | extend | Takes the gate table (D3) |
| large-path.md Conventions | refactor | Keeps only initiative-specific facts (D10) |
| Term-list script in domain-modeling | create | List with aliases, map support, `--define` (D5, D12) |
| Output style vocabulary rule; discovery 0.2.1 glossary read | refactor | Read the term list, look up on match (D11) |
| Link lint `tests/lint/md-links.sh` | create | Relative links and anchors under `.agents/` (D8) |
| Links into moved anchors (step files, large-path.md:223) | refactor | Re-pointed to the new homes |
| `status-transition.sh`, `step-progress.sh`, `steps.tsv`, step ids, guards, `session-start-resume.sh` | unchanged | Behaviour unchanged (Constraints) |
| PROVENANCE.md feature-workflow and domain-modeling rows | extend | New files need rows (rules.md Cross-cutting policy) |

## 2026-10-29 Questioning round 4

Loop-back from 0.4.7: the module audit found 3.9 and 3.13 run after every wave and a 3.9 or 3.11 failure reopens a task through the wave loop (codebase-map.md, Module audit), which conflicts with D6's finish file.

**Q1. Where do 3.9 and 3.13 live?**

- Options: A: in waves with the On resume paragraph; finish keeps only 3.10–3.11, 3.14 and the hand-off · B: setup | waves, no finish · defer
- Recommended: A, so waves never loads finish mid-loop; the Codex launch copies point to launching.md (D2) to keep the implementation resume near 55 KB.
- Answer: "In waves; finish is small (Recommended)"
- Decision: **D13 (supersedes D6)** implementation-setup.md holds 3.1; implementation-waves.md holds the wave loop (3.2–3.8, 3.16, 3.15, 3.13, 3.9), Launching agents, Evidence and the ledger, On resume, Stops, Discovered work and the 4.7 rework entry; implementation-finish.md holds 3.10–3.11, 3.14 and Hand off. The orchestrator's Codex launch copies point to launching.md.

**Q2. What happens to the unread `modules:` and `progressive_loading` frontmatter keys?**

- Options: A: keep and update the list · B: defer to the shelf · C: remove them now
- Recommended: A.
- Answer: "Remove them now"
- Decision: **D14** Remove `modules:` and `progressive_loading:` from the feature-workflow SKILL.md frontmatter in this change.

Facts looked up instead of asked (0.3.10): None.

## 2026-11-01 Questioning round 5

Loop-back from 0.6 (scope change before 1.1). `main` moved from 1058a0d to 7a9b852 while the spec waited (decisions D102–D112 of the scaffold's workflow-review fix: proven-first review escalation, the small path, spec worktrees). A re-check agent measured the loads on current `main` with D9's file list: new-feature start about 81 KB and implementation resume about 85 KB; with the planned split about 50 KB and 72 KB, so neither target holds. The stakeholder's change, verbatim: "I think the reason we had 009 was because loading our instructions was killing our context window with too much information. Splitting was how we were going to reduce this. I think your recommendations go against that principle." and then "add the size check as well".

**Q1. Do the targets move now that the files grew?**

- Options: A: keep 45 KB and 55 KB and cut further · B: raise the targets to fit the grown files · defer
- Recommended (after the stakeholder's objection to B): A.
- Answer: A (the stakeholder rejected raising the targets as against the reason for the spec).
- Decision: **D15 (amends D9)** The targets stay: new-feature start at most 45 KB, implementation resume at most 55 KB, counting every file a session loads at that point, hook output included. A small-path start meets the same 45 KB. The `rules.md` Ownership and Shared core blocks leave the new-feature start: they are read at placement (0.3.3) and at review, where they are used.

**Q2. What else leaves the implementation resume?**

- Options: A: the 3.2 shared-core batch step moves into its own step file, loaded only when a wave has shared-core requests; Codex-only text loads only on Codex · B: no further split · defer
- Recommended: A.
- Answer: A.
- Decision: **D16 (amends D13)** 3.2 moves from the waves step file to its own step file, loaded only when a wave has shared-core change requests. Codex-only text (host rows, task-name forms, the orchestrator's Codex copies) lives only in `references/launching.md` (D2) and loads only on Codex or at a launch.

**Q3. Where does the small path go under the split?**

- Options: A: fold `small-path.md` into the step files it changes as short "On the small path:" notes, the 0.0.3 sizing rule in the router, no overlay file · B: keep `small-path.md` whole, loaded only on the small path, exempt from the one-step-one-file check · defer
- Recommended (after the stakeholder's objection to B): A.
- Answer: A.
- Decision: **D17** `small-path.md` is removed: each step it changes carries a short "On the small path:" note in the step file that owns that step, and the 0.0.3 sizing and routing rule lives in the router. A small-path session loads the same files as any other session.

**Q4. Where does the proven-first review-escalation rule live?**

- Options: A: one home in `review-triage.md`, a one-line pointer from the router, `discovered-work.md` and the waves step file · B: one home in the conventions file · C: leave the four copies · defer
- Recommended: A, so the rule is not in every session's load.
- Answer: A.
- Decision: **D18** The proven-first escalation rule (prove, fix current-work findings through the worker, ask the stakeholder only convoluted, scope-expanding or out-of-scope findings in one batched question) is written once, in `review-triage.md`. The router, `discovered-work.md` and the waves step file each carry a one-line pointer to it.

**Q5. Are the byte targets enforced?**

- Options: A: a test suite measures both loads and fails above the targets · B: measured once, as D9 said · defer
- Recommended: A (the loads grew by about 11 KB within three days of the plan).
- Answer: "add the size check as well"
- Decision: **D19 (supersedes D9's "measured once, not enforced" and the matching Non-goal)** A test suite run by `tests/run-all.sh` measures the new-feature start and the implementation resume with `wc -c` and fails when either is above its target.

Facts looked up instead of asked (0.3.10): the re-check of this spec against `main` (line references, header list, test pins and byte counts), done by a sub-agent on 2026-11-01; its stale facts are refreshed into `codebase-map.md` before 0.6.

## 2026-11-01 Questioning round 6

**Q1. What else leaves the implementation resume, which is still about 62 KB after D16?**

- Options: A: the per-task gates (3.5–3.8) move into their own step file, loaded when a task reaches its gates · B: Evidence and the ledger load only when a result is checked (about 5 KB) · defer
- Recommended: A, bringing the resume to about 53 KB.
- Answer: "Split the gates (Recommended)"
- Decision: **D20 (amends D13)** The per-task gates 3.5–3.8 move from the waves step file to their own step file, loaded when the first task of a wave reaches its gates. The waves file keeps the loop, launches, merges (3.16, 3.15), 3.13, 3.9, On resume, Stops and the 4.7 rework entry.

**Q2. How does the size check count the hook output?**

- Options: A: run the session-start hook in a test fixture with one in-flight spec and no handoffs, and count its output · B: count a flat 2 KB · defer
- Recommended: A, a deterministic number on every run.
- Answer: "Fixture hook run (Recommended)"
- Decision: **D21** The size check runs `session-start-resume.sh` in a fixture holding one in-flight spec and no handoffs, and adds its output to both loads.

**0.3.19 summary.** Router, conventions, one step file and the term list; launch and Codex text load only at a launch or on Codex; the `rules.md` blocks load at placement and review; 3.2 and the per-task gates get their own step files; `small-path.md` is folded into the step files; the escalation rule lives once in `review-triage.md`; a test suite fails a new-feature start above 45 KB or a resume above 55 KB.
- Answer: "Yes"

Facts looked up instead of asked (0.3.10): None.

## 2026-11-01 Impact classification

Re-run against `main` at 7a9b852 after Questioning rounds 5 and 6 (D15–D21). Supersedes the 2026-10-29 Impact classification.

| Part | Classification | Note |
| --- | --- | --- |
| Router `SKILL.md` (Route table, step-file load line, 0.0.3 sizing and routing, frontmatter) | refactor | Loads conventions with the step file (D7); routes to the new step files; takes the 0.0.3 small-path rule (D17); one-line pointer to the escalation rule (D18); drops the Modules table, `modules:` and `progressive_loading:` (D14) |
| Workflow conventions `references/conventions.md` | create | Shared rules from SKILL.md §5 and large-path.md Conventions (D10), plus Size budget, Never grow the spec mid-build and the non-launch host rows |
| Launch reference `references/launching.md` | create | Launch header, denies, host rows, every Codex task-name form and the orchestrator's Codex copies; loaded only at a launch or on Codex (D2, D16) |
| Discovery step files `discovery.md`, `discovery-impact.md` | refactor | Split before / after the questioning loop (D4); 0.2.1 reads the term list (D11) and no longer the `rules.md` blocks, which move to 0.3.3 (D15); small-path notes for 0.1.4 and 0.2.4–0.2.6 (D17) |
| Implementation step files `implementation-setup.md`, `implementation-waves.md`, `implementation-finish.md` | refactor | Split per D13 |
| `implementation-shared-core.md` (3.2) | create | Loaded only when a wave has shared-core change requests (D16) |
| `implementation-gates.md` (3.5–3.8) | create | Loaded when the first task of a wave reaches its gates (D20) |
| Questioning-loop Entry and round | extend | Takes the gate table (D3) and the question-rounds host row; small-path notes for 0.3.8–0.3.22 (D17) |
| `review-triage.md` | extend | Sole home of the proven-first escalation rule (D18); small-path notes for its steps (D17) |
| `discovered-work.md` | refactor | Its escalation text becomes a one-line pointer to review-triage (D18) |
| `sign-off.md` | extend | Small-path notes for 5.4, 5.5 and 5.7 (D17) |
| `small-path.md` | refactor | Removed; folded into the step files it changes (D17) |
| large-path.md Conventions | refactor | Keeps only initiative-specific facts (D10) |
| Term-list script in domain-modeling | create | List with aliases, map support, `--define` (D5, D12) |
| Output style vocabulary rule | refactor | Inline term-list grep, look up on match (D1, D11) |
| Link lint `tests/lint/md-links.sh` | create | Relative links and anchors under `.agents/` (D8) |
| Size-check suite with a session-start hook fixture | create | Fails a new-feature start above 45 KB or a resume above 55 KB, hook output included (D15, D19, D21) |
| Tests that pin moved files or sections | refactor | Re-pointed to the new homes; behaviour unchanged |
| Links into moved anchors and plain-text step-file loads | refactor | Re-pointed to the new homes |
| Script and asset headers naming moved step files | refactor | Re-pointed (Assumptions) |
| PROVENANCE.md feature-workflow and domain-modeling rows | extend | New and removed files (rules.md Cross-cutting policy) |
| `status-transition.sh`, `step-progress.sh`, `steps.tsv`, step ids, `check-write.sh` constants, guards, `session-start-resume.sh` | unchanged | Behaviour unchanged (Constraints) |

Term gate 0.4.2: no new concept. The new files are named in Assumptions; "size check" names a test suite, not a workflow concept.

## 2026-11-01 Codebase map refresh

- `codebase-map.md` rewritten from the 0.4.6 module-audit return and a fact-lookup on the stale facts, both read from code at 7a9b852.
- Cache stamps set to `null`: the caches stamped 9e971ad hold their scope as one space-joined string, so `cache-stamp-check.sh` reports them fresh although code under their scope changed; the map takes nothing from them. Shelved as cache-scope-paths below.
- The audit's other out-of-scope line, review-triage naming "the 00.22 rule" for the blocker test that lives in discovered-work "Assess each report first", is on text this spec rewrites for the escalation rule's one home; it is fixed there, not shelved.

## 2026-11-01 Scope decision: cache scope paths

- Item: `publish-cache.sh` accepts a scope path that does not exist, and `cache-stamp-check.sh` reports such a cache fresh (found at 0.2.7 on this resume).
- Ruling: deferred, because 009 changes how the workflow loads instructions, not how caches are published or checked
- Handoff: [.workflow/deferred/cache-scope-paths.md](../../deferred/cache-scope-paths.md) (AFK), also listed in spec.md `deferred`

## 2026-11-01 Scope decision: hand-off on every route to review

- Item: the 3.14 routes to review skip the hand-off (module-audit, Out of scope noticed, can wait).
- Ruling: deferred, because 009 keeps behaviour unchanged and carries the gap over as is
- Handoff: [.workflow/deferred/in-review-hand-off.md](../../deferred/in-review-hand-off.md) (AFK), also listed in spec.md `deferred`

## 2026-11-01 Conflict check 0.4.7

Goal conflicts from the module audit (codebase-map.md, Module audit), sent to the questioning loop as Questioning round 7:

1. D15 moves the `rules.md` Ownership and Shared core blocks to 0.3.3, but 0.2.1 builds the affected area from the Ownership `owns` globs, and 0.2.2–0.2.5 use it before 0.3.3.
2. D18 puts the escalation rule's one home in `review-triage.md`, but the full rule (with the three classes) lives only in discovered-work "Assess each report first", which Phase 1–3 callers already load; review-triage holds a Phase 4 triage version and then loads discovered-work.
3. D17 folds `small-path.md` into the step files, but "Leave the small path" has triggers in two step files (0.3.3 in discovery; the round and 0.3.19 in the questioning loop) and no assigned home.
4. D20 moves 3.5–3.8 into the gates step file, but the "Per-task gates" section also holds 3.4 and the result routing that decides which gate runs next.

No placement conflict.

## 2026-11-01 Questioning round 7

Loop-back from 0.4.7 (Conflict check 0.4.7 above). Asked in the chat format (five questions).

**Q1. What does 0.2.1 read from `rules.md`, given it builds the affected area from the Ownership `owns` globs before 0.3.3?**

- Options: A: an inline `yq` command prints only module names and `owns` paths (about 1 KB); the full Ownership block is read at 0.3.3 and Shared core at 0.3.20 · B: read the whole Ownership block (4.3 KB) at 0.2.1 · defer
- Recommended: A, keeping D15's saving (codebase-map.md, Module audit gap on 0.2.1).
- Answer: "Yes, all"
- Decision: **D22 (amends D15)** 0.2.1 runs an inline `yq` command that prints each module's name and `owns` paths and reads nothing else from `rules.md`; the full Ownership block is read at 0.3.3 (placement) and the Shared core block at 0.3.20 (`touches_core`) and at review.

**Q2. Where is the escalation rule's one home?**

- Options: A: discovered-work "Assess each report first"; review-triage keeps only its Phase 4 proof, verdict and patch steps and points there; router and waves step file carry one-line pointers · B: review-triage, as D18 said · defer
- Recommended: A, since the full text and its Phase 1–3 callers are already in discovered-work (codebase-map.md, Relevant code: Proven-first escalation rule).
- Answer: "Yes, all"
- Decision: **D23 (supersedes D18)** The proven-first escalation rule is written once, in `discovered-work.md` "Assess each report first". `review-triage.md` keeps its Phase 4 proof check, verdicts and routing buckets and points to discovered-work for the escalation classes; the router, the waves step file and the orchestrator's 00.21 section carry a one-line pointer. The inexact "00.22 rule" pointer in review-triage is corrected in the same edit.

**Q3. Where does "Leave the small path" live?**

- Options: A: questioning-loop, with discovery's 0.3.3 note linking to it · B: discovery · C: the router · defer
- Recommended: A: two of its three triggers and the `small_path: false` write are there.
- Answer: "Yes, all"
- Decision: **D24 (amends D17)** "Leave the small path" (its triggers, the design-log line, the late `library-evaluation` launch and the 0.3.19 `small_path: false` write) lives in `questioning-loop.md`; discovery's 0.3.3 small-path note links to it, and the router's 0.0.3 rule loads discovery alone.

**Q4. Where do 3.4 and the result routing go?**

- Options: A: the gates step file takes 3.4–3.8 and the routing, loaded when a wave's first implementation agent returns · B: they stay in waves · defer
- Recommended: A, matching the current "Per-task gates (3.4–3.8)" section and keeping the resume under 55 KB.
- Answer: "Yes, all"
- Decision: **D25 (amends D20)** `implementation-gates.md` holds the whole "Per-task gates (3.4–3.8)" section, result routing included, and is loaded when the first implementation agent of a wave returns.

**0.3.19 summary.** Router, conventions, one step file and the term list; 0.2.1 reads only module names and `owns` paths, the full `rules.md` blocks load at 0.3.3 and 0.3.20; launch and Codex text only at a launch or on Codex; 3.2 and the gates 3.4–3.8 get their own step files; `small-path.md` is folded into the step files, its Leave rule in the questioning loop; the escalation rule lives once in discovered-work; a size-check suite fails a new-feature start above 45 KB or a resume above 55 KB.
- Answer: "Yes, all"

Facts looked up instead of asked (0.3.10): None; the conflicts came from the 0.4.6 module audit and the fact-lookup in codebase-map.md.

## 2026-11-01 Impact classification (amended after round 7)

Changes to the 2026-11-01 Impact classification above; every other row stands.

| Part | Classification | Note |
| --- | --- | --- |
| Discovery 0.2.1 `rules.md` read | refactor | Inline `yq` prints module names and `owns` paths only; full blocks at 0.3.3 and 0.3.20 (D22) |
| `discovered-work.md` | extend | Sole home of the escalation rule; gains the pointers' target anchor, no new rule text (D23) |
| `review-triage.md` | refactor | Keeps Phase 4 proof, verdicts and buckets; points to discovered-work for the escalation classes; "00.22 rule" pointer corrected (D23) |
| `questioning-loop.md` | extend | Also takes "Leave the small path" (D24) |
| `implementation-gates.md` | create | 3.4–3.8 with result routing (D25) |

## 2026-11-01 Conflict check 0.4.7 (after round 7)

D22–D25 settle the four conflicts and touch only feature-workflow paths the 0.4.6 audit already read (codebase-map.md, Module audit), so no new audit is needed. No goal or placement conflict remains.
