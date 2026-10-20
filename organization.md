# Organization proposal

> **Superseded by [assetlist.md](./assetlist.md).** This early layout proposal (with `.agents/subagents/`, `.agents/templates/`, `.agents/lib/`) is kept for history only. Where it disagrees with `assetlist.md`, `assetlist.md` wins. Like `PLAN/` and `assetlist.md`, it is a scaffold-only design doc and is not part of the install payload (D30).

This proposes the folder layout needed to run the workflow in `PLAN/decision-flow.mermaid` and `PLAN/decision-flow-reference.md`. It covers layout only. It does not cover file contents, implementation order, or code.

Node numbers such as `0.3.8` refer to the diagram. "Ref §X" means a section of `PLAN/decision-flow-reference.md`.

## Two trees, not one

The PLAN describes files in two places. Keeping them separate is the main organizing decision.

1. **Scaffold repo** (this repo): the workflow itself. That means the skills, sub-agent prompts, hooks, templates and shared scripts. It lives in `.agents/`, and `.claude/` is a shim over it.
2. **Target project** (any repo that uses the workflow): the data the workflow reads and writes. That means `GLOSSARY.md`, `docs/`, `deferred/`, the model map, `profiles/` and `specs/`. Project setup creates these from the scaffold's templates.

Ref §"Templates to author" requires this split: *"Templates live wherever the workflow's own files live, not in the project's `docs/`."*

Legend: `[existing]` unchanged · `[new]` to create · `[move]` relocate · `[remove]` delete · `[modify]` existing file gains entries

---

## 1. Scaffold repo tree

```
llm-scaffold-claude/
├── AGENTS.md                         [existing] [modify] add the two-tree explanation and placement rules below
├── CLAUDE.md                         [existing]
├── GLOSSARY.md                        [existing] [modify] scaffold vocabulary (Tier A, Tier B, work profile, task type, …)
├── CHANGELOG.md                      [existing]
├── README.md                         [existing] [modify] layout section
├── skills-lock.json                  [existing]
├── organization.md                   [new] this file
├── PLAN/                             [existing] design source for the workflow; not distributed
│   ├── decision-flow.mermaid
│   └── decision-flow-reference.md
│
├── .agents/                          the distribution unit
│   ├── README.md                     [existing] [modify] index of the workflow skills and hooks
│   │
│   ├── skills/
│   │   │  ── workflow skills: one per phase, plus a router ──
│   │   ├── feature-flow/             [new] entry point: intake and sizing (0.0–0.0.2), resume (5.6), phase routing
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── intake-sizing.md          0.0.1 trivial bypass, light versus full path summary
│   │   │       ├── status-routing.md         status → phase re-entry table (Ref §Status)
│   │   │       └── model-selection.md        how launches name a task type (00.11–00.15)
│   │   ├── discovery/                [new] Phase 0 (0.1–0.6)
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── init-feature-folder.md    0.1.x scan, slug, spec.md, off-the-shelf check
│   │   │       ├── retrieve-context.md       0.2.x term gate, retrieval, stamp check, regeneration
│   │   │       ├── frame-problem.md          0.3.1–0.3.7 capability, placement, ADR
│   │   │       ├── questioning-loop.md       0.3.8–0.3.19 answerable set, one round, deep dive, scope
│   │   │       ├── term-gates.md             shared by 0.2.2, 0.3.14, 0.4.2
│   │   │       ├── light-path-test.md        0.3.20
│   │   │       ├── model-impact.md           0.4.x
│   │   │       ├── end-state.md              0.5.x
│   │   │       └── exit-gate.md              0.6
│   │   ├── verification-setup/       [new] Phase 1 (1.1–1.5)
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── targets.md                1.1
│   │   │       └── known-bad-build.md        1.4
│   │   ├── task-breakdown/           [new] Phase 2 (2.1–2.5)
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── vertical-slices.md        2.1, profile-aware slicing
│   │   │       └── gates.md                  2.2–2.4
│   │   ├── implement/                [new] Phase 3 orchestrator (3.1–3.12)
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── orchestrator.md           3.1 classification, waves, integration batches (3.2)
│   │   │       ├── four-gates.md             3.6, 3.8, 3.9, 3.11 (Ref §"The four gates of Phase 3")
│   │   │       └── browser-suite.md          3.10–3.12
│   │   ├── review-triage/            [new] Phase 4 (4.1–4.8)
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── lenses.md                 launches 4.1–4.3 in parallel
│   │   │       ├── triage.md                 4.4 verify, severity, dismiss with reason
│   │   │       ├── routing.md                4.5 patch / defer / decision needed / none
│   │   │       └── rework-ceiling.md         4.6 third pass, 4.7 max five
│   │   ├── sign-off/                 [new] Phase 5 (5.1–5.8)
│   │   │   ├── SKILL.md
│   │   │   └── modules/
│   │   │       ├── reconcile-spec.md         5.1
│   │   │       ├── tier-a-proposals.md       5.2–5.3, including checklist → tool-rule conversion
│   │   │       ├── report.md                 5.4
│   │   │       └── retrospective.md          5.7
│   │   │
│   │   │  ── processes outside the flow (Ref §"Processes outside the flow") ──
│   │   ├── project-setup/            [new] creates the target-project tree; fills profiles; installs toolchains
│   │   │   ├── SKILL.md
│   │   │   ├── modules/
│   │   │   │   ├── scaffold-target.md        creates GLOSSARY.md, docs/, deferred/, model map, profiles/
│   │   │   │   ├── fill-profile.md           one pass per work type (also backs 00.19)
│   │   │   │   ├── toolchain.md              calls install-anti-slop for TS/JS profiles
│   │   │   │   └── seed-model-map.md
│   │   │   └── scripts/                      thin entry points into .agents/lib/
│   │   ├── regenerate-caches/        [new] bulk Tier B regeneration (00.5–00.7); same output as 0.2.8
│   │   │   └── SKILL.md
│   │   │
│   │   │  ── existing skills the workflow composes ──
│   │   ├── grilling/                 [existing] source of the questioning loop (0.3.8–0.3.13)
│   │   ├── grill-with-docs/          [existing] source of CONTEXT-FORMAT.md and ADR-FORMAT.md, copied into templates/
│   │   ├── tdd/                      [existing] referenced by the implementation sub-agent (3.3)
│   │   ├── code-review/              [existing] basis for review-standards and review-end-state (4.1–4.2)
│   │   ├── install-anti-slop/        [existing] called by project-setup (3.5 toolchain)
│   │   ├── proof-of-work/            [existing] backs 5.4 and design rule 12
│   │   ├── improve-codebase-architecture/  [existing] module/seam vocabulary
│   │   │
│   │   │  ── existing skills the workflow does not use ──
│   │   ├── clear-context/ wrap-up/ zoom-out/ diagnose/ glab/ deps-audit/ deps-update/
│   │   │   data-structure-audit/ design-pattern-doc/ pr-quality/ visual-change-report/
│   │   │   write-a-skill/ setup-matt-pocock-skills/ to-prd/ to-issues/      [existing]
│   │   └── grill-me/                 [remove] duplicate of grilling; already dropped from skills-lock (9259d8c)
│   │
│   ├── subagents/                    [new] one launch prompt per sub-agent task type (Ref §"Sub-agent task types")
│   │   ├── retrieval.md              0.2.4
│   │   ├── library-evaluation.md     0.2.5
│   │   ├── cache-regeneration.md     0.2.8, and used by regenerate-caches
│   │   ├── fact-lookup.md            0.3.10
│   │   ├── module-audit.md           0.4.6
│   │   ├── implementation.md         3.3, 1.2, 1.3
│   │   ├── integration.md            3.2
│   │   ├── profile-mini-review.md    3.7
│   │   ├── review-standards.md       4.1
│   │   ├── review-end-state.md       4.2
│   │   └── review-targets.md         4.3
│   │
│   ├── templates/                    [new] every artifact the flow writes (Ref §"Templates to author")
│   │   ├── feature/                  copied into specs/NNN-slug/
│   │   │   ├── spec.md
│   │   │   ├── codebase-map.md
│   │   │   ├── design-log.md
│   │   │   ├── data-model.md
│   │   │   ├── verification-plan.md
│   │   │   └── tasks.md
│   │   ├── project/                  used once by project-setup
│   │   │   ├── GLOSSARY.md                    from grill-with-docs/CONTEXT-FORMAT.md
│   │   │   ├── capabilities.md
│   │   │   ├── rules.md                      includes the structured ownership and shared-core blocks
│   │   │   ├── pitfalls.md
│   │   │   └── status.md
│   │   ├── decisions/
│   │   │   ├── adr.md                        from grill-with-docs/ADR-FORMAT.md
│   │   │   └── retrospective.md
│   │   ├── deferred.md
│   │   ├── model-map/
│   │   │   ├── entry.md                      shape of one model-map file
│   │   │   └── defaults/<task-type>.md       seeded default assignment per task type
│   │   ├── profiles/
│   │   │   ├── TEMPLATE.md                   the five fixed sections (00.16), the contract
│   │   │   └── examples/                     test-harness.md, e2e-browser.md (Ref Phase 1 note)
│   │   └── cache/
│   │       └── frontmatter.schema.md         generated_at_commit, generated_at, scope
│   │
│   ├── hooks/                        scripts only; wiring lives in .claude/settings.json
│   │   ├── block-destructive-git.sh  [existing]
│   │   ├── context-bridge.js         [existing]
│   │   ├── pre-launch-model.*        [new] 00.12–00.15
│   │   ├── pre-launch-profile.*      [new] 00.18–00.20
│   │   ├── post-implementation-audit.*  [new] 3.5–3.8
│   │   ├── spec-single-writer.*      [new] 0.1.4
│   │   ├── tier-a-write-guard.*      [new] Tier A
│   │   ├── tier-b-write-guard.*      [new] Tier B
│   │   ├── rules-boundary-sync.*     [new] 00.3 → 3.5
│   │   ├── cache-stamp-check.*       [new] 0.2.7
│   │   ├── evidence-capture.*        [new] 3.10
│   │   └── session-start.*           [new] 5.6
│   │
│   ├── lib/                          [new] logic shared by hooks and skills; one implementation each
│   │   ├── frontmatter.*             read and write spec.md and tasks.md frontmatter
│   │   ├── status-transition.*       the single status writer (Ref §Hooks "Status transition")
│   │   ├── workflow-step.*           reads and writes the current-step marker the guards check
│   │   ├── cache-stamps.*            stamp comparison against HEAD, by scope
│   │   ├── boundary-config.*         rules.md ownership blocks → import-boundary config
│   │   ├── profile-sections.*        extracts sections from a profile (whole or checklist only)
│   │   └── paths.*                   one table of target-project paths (Ref: "change them everywhere")
│   │
│   ├── commands/
│   │   ├── pr-quality.md             [existing]
│   │   ├── pr-review-data.md         [existing]
│   │   ├── feature.md                [new] alias → feature-flow
│   │   ├── resume.md                 [new] alias → feature-flow status routing (5.6)
│   │   ├── setup-project.md          [new] alias → project-setup
│   │   └── regen-caches.md           [new] alias → regenerate-caches
│   │
│   └── output-styles/
│       └── concise-technical.md      [existing]
│
├── .claude/                          Claude Code shim
│   ├── settings.json                 [existing] [modify] register the new hooks (see §4)
│   ├── skills        → ../.agents/skills          [existing]
│   ├── commands      → ../.agents/commands        [existing]
│   ├── output-styles → ../.agents/output-styles   [existing]
│   └── agents        → ../.agents/subagents       [new] symlink, if the prompts are also Claude subagent definitions
│
└── tests/                            [new] scaffold self-tests; not distributed
    ├── hooks/                        one suite per hook: allow and block cases
    ├── lib/
    └── fixtures/
        └── target-project/           a minimal target tree (see §2) with specs in each status
```

## 2. Target project tree (created by project-setup)

These paths come from the PLAN, with one rename (see §5, question 1).

```
<target-project>/
├── .agents/                          scaffold, installed (tree §1 minus PLAN/, tests/)
├── .claude/                          shim, installed
├── GLOSSARY.md                        00.1  Tier A  glossary only
├── docs/
│   ├── capabilities.md               00.2  Tier A  CAP-### entries
│   ├── rules.md                      00.3  Tier A  structured ownership and shared-core blocks
│   ├── decisions/                    00.4  Tier A
│   │   ├── adr/NNNN-slug.md
│   │   ├── pitfalls.md
│   │   ├── retrospectives/NNN-slug.md
│   │   └── status.md
│   └── cache/                        Tier B, generated, never hand-edited
│       ├── modules.md                00.5
│       ├── flows.md                  00.6
│       └── architecture.md           00.7
├── deferred/                         00.8  one file per shelved item
│   └── archive/                      00.10
├── model-map/                        00.11 PLAN calls this agents/ (see §5 Q1)
│   └── <task-type>.md
├── profiles/                         00.16–00.17 Tier A in nature
│   ├── TEMPLATE.md
│   └── <work-type>.md                e.g. frontend-react, backend-api, test-harness, e2e-browser
├── tools/
│   ├── oxlint/anti-slop/             vendored by install-anti-slop (Ref §Sources, anti-slop)
│   └── boundaries/                   generated import-boundary config; never hand-edited
└── specs/
    └── NNN-slug/
        ├── spec.md                   0.1.4 single writer
        ├── codebase-map.md           0.2.6
        ├── design-log.md             0.3.21 append-only
        ├── data-model.md             0.4.5
        ├── verification-plan.md      0.5.4
        ├── tasks.md                  2.5
        └── artifacts/                3.12
            ├── runs/<run-id>/<JRN-###>/   screenshots, traces, console and network logs
            └── tool-audit/<task-id>/      3.5 output
```

---

## 3. Rationale by folder

### Scaffold: `.agents/skills/` (workflow skills)
- **One skill per phase plus a router.** Each phase loads only its own instructions, following design rule 3 (the corpus never enters main context). Phases re-enter each other, for example seven gates route back to 0.3.8 (Ref §"The questioning loop"). The router `feature-flow` owns that routing, so phase skills don't need to know about each other.
- **Modules per substage.** This matches the existing `SKILL.md` + `modules/` pattern (`pr-quality`, `proof-of-work`). Module names track diagram substages, so a node number maps to one file.
- **`term-gates.md` is shared.** The three term gates (0.2.2, 0.3.14, 0.4.2) are one behavior, so they live in one file (design rule 9).
- **`project-setup` and `regenerate-caches` are separate skills.** Both sit outside the flow in the diagram (dashed grey). Ref §"Processes outside the flow" says a human or automation invokes them, not a flow node.
- **Existing skills stay where they are.** The workflow references them and does not copy them. Where the PLAN takes a *format* from one (CONTEXT-FORMAT, ADR-FORMAT), the format is copied into `templates/` so the workflow's templates live in one place.

### Scaffold: `.agents/subagents/`
- There are 11 files, one per row in Ref §"Sub-agent task types". Each file is the launch prompt, and its "Receives / Does not receive" columns form that prompt's contract.
- The folder is not named `agents/`. That avoids a clash with `.agents/` itself, with `skills/*/agents/openai.yaml`, and with the model map.
- Model choice stays out of these files. The model map owns it per project and 5.7 updates it (Ref §"Model selection"). The prompts are shared; the model assignments belong to each project.

### Scaffold: `.agents/templates/`
- It is one central folder rather than per-skill assets, because several phases write the same artifact. `spec.md` is written at 0.1.6, 0.3.19, 0.5.1 and 5.1. `deferred.md` is written at 0.3.17 and 4.8. `design-log.md` is written in nearly every phase.
- Subfolders follow the destination: `feature/` becomes `specs/NNN-slug/`, `project/` becomes the repo root and `docs/`, and so on. The template path then tells you where its output goes.

### Scaffold: `.agents/hooks/` and `.agents/lib/`
- There is one script per hook row in Ref §Hooks. File names match the row names.
- "Status transition" goes in `lib/`, not `hooks/`. It runs at workflow nodes, not on a host event. Both skills and hooks call it, and it is the single status writer.
- `lib/paths.*` holds the target-project path table. Ref §"Build inventory" says *"change them, but change them everywhere"*, and one table makes that a single edit.
- `boundary-config` goes in `lib/` because project setup and the `rules-boundary-sync` hook both run it (Ref §Hooks, "Rules → boundary config sync").

### Scaffold: `.agents/commands/`
- Thin aliases only, like the existing `pr-review-data.md`. The logic stays in skills.

### Scaffold: `tests/`
- The hooks enforce the workflow's guarantees: single writer, Tier A/B guards, pre-launch blocks. If a guard is wrong, it fails silently, so each needs allow and block tests against a fixture target project. `tests/` sits outside `.agents/` because it is not distributed.

### Target: `docs/`, `GLOSSARY.md`, `deferred/`, `profiles/`, `specs/`
- These follow Ref §"Persistent files" and §"Per-feature files" as written. The tier split is visible in the paths. Everything under `docs/cache/` is Tier B, and a single path prefix is what `tier-b-write-guard` matches on.
- `artifacts/` gets two subfolders because Ref names two kinds of content: browser runs (by run and journey ID) and tool-audit output (by task).
- `tools/boundaries/` is generated output. It sits next to the vendored anti-slop, where the profile toolchain sections point.

---

## 4. Placement rules

1. **Workflow logic goes in `.agents/`. Workflow data goes in the target project.** A file that ships with the workflow belongs under `.agents/`. A file the workflow writes about a specific project never does.
2. **`.claude/` holds only symlinks and `settings.json`** (AGENTS.md conventions). Hook scripts live in `.agents/hooks/`. `settings.json` only registers them:
   - PreToolUse on the sub-agent launch tool → `pre-launch-model`, `pre-launch-profile`
   - SubagentStop → `post-implementation-audit`
   - PreToolUse on Write/Edit → `spec-single-writer`, `tier-a-write-guard`, `tier-b-write-guard`
   - PostToolUse on Write/Edit → `rules-boundary-sync`
   - PreToolUse on Read (retrieval context) → `cache-stamp-check`
   - PostToolUse on Bash (browser-suite command) → `evidence-capture`
   - SessionStart → `session-start`

   Ref §Hooks asks that these event names be checked against current Claude Code docs before building.
3. **One home per fact** (design rule 9). If two skills need the same logic, it goes in `lib/`. If two skills write the same artifact, the template goes in `templates/`.
4. **Naming.**
   - Skills are verb or phase names (`implement`, `sign-off`).
   - Sub-agent files are the PLAN's task-type names exactly (`implementation.md`, `cache-regeneration.md`). Hooks and the model map look up by that string.
   - Hook files are the Ref §Hooks row names in kebab-case.
   - A skill and a task type never share a name (`implement` vs `implementation`, `regenerate-caches` vs `cache-regeneration`).
5. **Generated output is never placed next to authored files.** Examples are `docs/cache/`, `tools/boundaries/` and `specs/*/artifacts/`, each its own subtree so a guard can match it by prefix.
6. **Vendored skills keep their upstream layout** (tracked in `skills-lock.json`). Workflow additions go in new skills, not edits to vendored ones.

---

## 5. Open questions

1. **Model-map folder name.** The PLAN uses `agents/` at the target root. That sits right next to `.agents/`, so this proposes `model-map/`. Keep the PLAN name or accept the rename?
2. **Current-step marker.** `spec-single-writer` and `tier-a-write-guard` allow writes only "from" certain steps. That needs a persisted current-step value, which the PLAN doesn't place. Options: an extra `spec.md` frontmatter field (conflicts with the single-writer idea), or a gitignored `specs/NNN-slug/.step` file.
3. **Where 5.2 proposals live before approval** at 5.3. Not placed in the PLAN. Candidate: `specs/NNN-slug/proposals.md`.
4. **Where the 5.4 report lives.** Not placed. Candidate: `specs/NNN-slug/report.md`, with artifacts attached by link.
5. **Sub-agent prompts as Claude subagent definitions.** If `.agents/subagents/*.md` doubles as `.claude/agents/` definitions via the symlink, their frontmatter can't carry `model` without clashing with the model map. Symlink, or keep them as plain prompts the skills pass in?
6. **Other agents' shims.** The PLAN only names Claude Code hook events. Several skills ship `agents/openai.yaml` (Codex). Should this proposal include a `.codex/` or equivalent shim now, or only `.claude/`?
7. **Overlapping existing skills.** `code-review` (two-axis) overlaps `review-triage` (three lenses + triage). `to-prd`/`to-issues` overlap Phase 0/2. The `spec-kit` plugin enabled in `settings.json` overlaps Phases 0–2. Keep all of them, retire some, or fold `code-review` into the lens prompts?
8. **Install path.** The 2.0 reset removed the install flow. How `.agents/` + `.claude/` reach a target project (copy, submodule, `npx skills add`) affects whether `tests/fixtures/target-project/` mirrors a copy or a link.
9. **`PLAN/` long-term home.** Keep it as the scaffold's design folder, or move it under a scaffold-only `design/` once the workflow is built?
