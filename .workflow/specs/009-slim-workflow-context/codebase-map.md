---
cache_stamps:
  modules: null
  flows: null
  architecture: null
---

# Codebase map: Slim the workflow context

Affected area: feature-workflow (`.agents/skills/feature-workflow`), output-styles (`.agents/output-styles`), domain-modeling (`.agents/skills/domain-modeling`), agents (`.agents/agents`), hooks (`.agents/hooks`), tests (`tests`).

Refreshed 2026-11-01 against `main` at 7a9b852 from the module-audit and fact-lookup returns, which read the code. The 2026-10-29 retrieval extracts had drifted, and the caches stamped 9e971ad report fresh while code under their scope has changed, so every cache stamp is `null`: the rows below come from code (design-log.md, 2026-11-01 Codebase map refresh).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Router and step-file wording | SKILL.md calls itself the router; phase logic lives in `modules/`; "load only the module the route names, read it fully, and follow it". | `.agents/skills/feature-workflow/SKILL.md:20` |
| SKILL frontmatter step-file list | Lists 11 step files (with `small-path`) and `progressive_loading: true`; no reader in the module. A test requires `small-path` in `.modules[]`; `progressive_loading` is not pinned. | `SKILL.md:4-16`; `tests/lint/small-path-docs.sh:51` |
| Find the state, "No hook offered one" | Bash block that lists in-flight specs from the main checkout, spec worktrees included; a test runs it from a spec worktree. | `SKILL.md:30`; `tests/scripts/spec-worktree.sh:165-167` |
| Size the request (0.0.1–0.0.3) | 0.0.3 small path names file, cause and test; "Yes" loads discovery and `modules/small-path.md`; pinned by the small-path docs lint. | `SKILL.md:53-65`; `tests/lint/small-path-docs.sh:52-56` |
| Route by status | Table mapping status and `.step` to the step file and resume node; `discovery` for every non-loop draft step, `implementation-orchestrator` for 3.1 and rework, no split by node; small-path line and the `in-review` 4.10 row pinned. | `SKILL.md:67-98`, `:81-87`; `tests/lint/small-path-docs.sh:57-60` |
| Re-entry and loop-back table (§4) | Gate table with owners and status calls, including the 0.6 scope-change route; no test pins its text. | `SKILL.md:123-134` |
| Conventions (§5) | One writer :140-149, Size budget :150, Set the step then write with the guarded-writes table (now with Done folder and path-only rewrite rows) :151-167, Never grow the spec :168, Sub-agent writes :169, Progress line :171-179. Only the Done folder bullet is pinned (`move-to-done.sh`). | `SKILL.md:136-179`; `tests/lint/done-folder-docs.sh:113` |
| Launching a sub-agent and Host notes | Launch header, 00.14/00.19 denies, the host Launch row with every `s<NNN>`/`i<NNN>` task-name form :181-204; non-launch host rows (Write guards, Resume offer, Question rounds, Other skills) and the Codex-hooks note :205-210. No test pins them. | `SKILL.md:181-210` |
| Modules table | Maps each step file to nodes, entries and exits; the `small-path` row and the deferred-handoff row (no "4.8") are pinned. | `SKILL.md:212-226`; `tests/lint/small-path-docs.sh:61`; `tests/lint/review-escalation-docs.sh:87-88` |
| Templates paragraph | The `assets/` line must name `pr-template.md`. | `SKILL.md:228`; `tests/scripts/sign-off-pr.sh:201-202` |
| small-path.md | Overlay loaded beside the step file while `small_path` is true: Leave the small path :9-19, Phase 0 changes :21-36, Phases 3–4 :38-40, Phase 5 :42-57. Every section is pinned by the small-path docs lint, which also checks its links resolve. | `modules/small-path.md:9-57`; `tests/lint/small-path-docs.sh:62-86` |
| Large-path local conventions | IT forms :9-19, step table with term-gate column :20-38, Progress :39, Main ref :40-54, Commit point :56-61, Launches :63, Sub-agents :64. | `modules/large-path.md:7-64` |
| Discovery reads the glossary and rules blocks | 0.2.1 reads `.workflow/GLOSSARY.md` whole plus the Ownership and Shared core blocks of rules.md, and builds the affected area from the Ownership `owns` globs. | `modules/discovery.md:3`, `:59` |
| Term gate in discovery | 0.2.2 asks about raised terms; `retrieval` and `library-evaluation` launch in the same message. | `modules/discovery.md:69-74`, `:101` |
| Discovery fenced blocks pinned | The 0.1.1 scan block is extracted and run by two suites; sections 0.3.20–0.6 are not pinned. | `modules/discovery.md:11`; `tests/scripts/spec-worktree.sh:85-88`; `tests/scripts/move-to-done.sh:343` |
| Implementation orchestrator pins | Agent and integration worktree text, check-merge-artifacts before the 3.2 and 3.16 merges, no `--ff-only`; "Discovered work (00.21)" must hold "**Current work.**"; the toolchain tree sentence; the missing-agent-worktree deny sentence. | `modules/implementation-orchestrator.md:31`, `:167`, `:305-318`; `tests/lint/agent-worktree-docs.sh:24`, `:94-112`; `tests/lint/review-escalation-docs.sh:29`, `:79`; `tests/scripts/run-toolchain.sh:243`; `tests/hooks/worktree-guard.sh:394-402` |
| Sign-off and large-path pins | sign-off.md and large-path 6.13 must name `specs/done`; fenced blocks in sign-off.md and large-path.md are run by suites. | `tests/lint/done-folder-docs.sh:19-20`, `:114`; `tests/scripts/move-to-done.sh:374`; `tests/scripts/sign-off-pr.sh:29`; `tests/scripts/spec-worktree.sh:180`; `tests/scripts/run-toolchain.sh:244` |
| Step ids under `.agents/` | Every `--step` id and `step <dir> <id>` call under `.agents/` must be a row of `steps.tsv`. | `tests/lint/step-list.sh:70-71`, `:109-110` |
| Proven-first escalation rule | Full rule with the three classes only in discovered-work "Assess each report first"; summaries in SKILL §5 "Never grow the spec", the orchestrator's 00.21 section and review-triage (Phase 4 proof check, verdicts, buckets, then loads discovered-work); sign-off asks one batched question at 5.5. Agent definitions carry only the prove-before-report half. | `modules/discovered-work.md:3`, `:24-45`, `:110-112`; `SKILL.md:168`; `modules/implementation-orchestrator.md:305-318`; `modules/review-triage.md:77-99`, `:116-119`; `modules/sign-off.md:117-133`; `.agents/agents/implementation.md:64` |
| Escalation text pins | Lens proof text, discovered-work order and classes, "at 5.5 at the latest", 00.25 and 00.26, triage text, sign-off 5.5 and 5.9; "filed without a ruling" must not appear. | `tests/lint/review-escalation-docs.sh:39-95` |
| Term gates in domain-modeling | Gates 0.2.2, 0.3.14, 0.4.2 with agree steps 0.2.3, 0.3.15, 0.4.3. Glossary format in `assets/GLOSSARY-FORMAT.md`; no `scripts/` folder exists. | `.agents/skills/domain-modeling/SKILL.md:10-13`, `:37-54`; `assets/GLOSSARY-FORMAT.md:1-44` |
| Vocabulary rule for output | Use only terms in `.workflow/GLOSSARY.md`, loaded at conversation start; add a missing term "following the existing format". | `.agents/output-styles/concise-technical.md:21`, `:23` |
| Session-start hook output | One JSON `additionalContext` with spec, initiative, backlog and handoff lines; names only `modules/large-path.md` (when an initiative is listed); never names small-path. | `.agents/hooks/session-start-resume.sh:253`, `:291`, `:310`, `:325` |
| Names of moved files outside feature-workflow | Only two regenerate-caches headers name `modules/discovery.md`, and PROVENANCE.md has per-file rows; no `SKILL.md#` anchor outside the module. | `.agents/skills/regenerate-caches/scripts/publish-cache.sh:4`; `.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh:4`; `PROVENANCE.md:11`, `:135`, `:150-159` |
| Agent definitions | Name feature-workflow steps by number only; `module-audit` names 0.4.6 (moves to the after-the-loop discovery file). | `.agents/agents/module-audit.md:3`; `.agents/agents/integration.md:3`; `.agents/agents/profile-mini-review.md:3` |
| Test suite discovery | Any `.sh` under `tests/scripts/`, `tests/hooks/` or `tests/lint/` runs as a suite and must end with `finish`; `resume_offer` runs the session-start hook on a fixture; `seed_draft_spec` makes a draft spec folder. | `tests/run-all.sh:86`, `:277`; `tests/lib/common.sh:70`, `:139`; `tests/fixtures/initiative.sh:34`, `:72`, `:150-154` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| Step-file load | "load only the module the route names, read it fully, and follow it"; discovery links back to `../SKILL.md#5-conventions-every-module-follows` | Router, step files | `SKILL.md:20`; `modules/discovery.md:3` |
| Launch header | First line ```` ```yaml launch-header ```` with `task_type` and `spec_dir`; `LAUNCH ERROR:` on a bad header | Every sub-agent launch | `SKILL.md:181-196`; `agents/retrieval.md:11-15` |
| Launch requirements | `resolve-launch.sh --requirements`; Phase 0 types take `spec_dir` only | Discovery, large-path | `SKILL.md:194` |
| Step set for Tier A writes | `status-transition.sh step <spec-dir> <node>` before a guarded write | domain-modeling, discovery, large-path, sign-off | `SKILL.md:151`; `domain-modeling/SKILL.md:21-22` |
| Progress line | `step-progress.sh --spec-dir <dir> [<step-id>] [--at <node>]`; large form `step-progress.sh <6.x>`; a 6.x id with `--spec-dir` exits 2 | Every step file that reports a step; large-path | `SKILL.md:173-179`; `scripts/step-progress.sh:7-19` |
| Write-step oracle | `check-write.sh --cwd <dir> --path <target> [--only …] [--proposed <file>]`; 0 allow, 2 deny, 1 error; denies every Done folder write first; step constants match the guarded-writes table | Write-guard hooks; Codex | `scripts/check-write.sh:74-83`, `:89`, `:236-238` |
| Initiative transitions | `initiative-transition.sh status/step/set-slice/set-question/set-pr`; exit 0/1/2 | large-path | `modules/large-path.md:9-19` |
| Step-file loads by path | Plain-text "load `modules/<name>.md`" and links to `<file>#<heading-anchor>` | All step files, router | `modules/review-triage.md:167`; `modules/large-path.md:230` |
| Result-file checker | `check-task-result.sh <yaml>`; 0 table, 1 shape error, 2 missing or usage | orchestrator, verification-setup | `scripts/check-task-result.sh:61-65` |
| Spec worktree | `spec-worktree.sh create\|remove <spec-dir> [--cwd]`; prints `worktree`, `baseline`; 1 refused, 2 usage | discovery 0.3.20, verification-setup 1.1, sign-off 5.8 | `scripts/spec-worktree.sh:8-29` |
| ready-for-dev → draft at 0.6 | `status <spec> draft --step 0.6`; refused once `spec_branch`, `baseline_revision` or a non-0.6 `.step` shows Phase 1 has begun | router §4 | `scripts/status-transition.sh` (2342afc); `SKILL.md:128` |
| Session-start hook on a fixture | `resume_offer DIR` pipes a SessionStart payload to `session-start-resume.sh` and reads `additionalContext` | tests | `tests/fixtures/initiative.sh:150-154` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Rules: feature-workflow ownership | Owns `.agents/skills/feature-workflow/**`; may depend on lib, regenerate-caches, domain-modeling, project-setup. | `.workflow/rules.md` § Ownership |
| Rules: domain-modeling, output-styles | domain-modeling may depend on feature-workflow; output-styles depends on nothing. | `.workflow/rules.md` § Ownership |
| Rules: agents ownership | `.agents/agents/**` may depend on feature-workflow and regenerate-caches only. | `.workflow/rules.md` § Ownership |
| Rules: comments | Body comments give the reason in plain words; no decision ids, doc paths or workflow paths. | `.workflow/rules.md` § Cross-cutting policy |
| Rules: adding an asset | New file under `.agents/` needs PROVENANCE.md; a first-party asset target projects need goes in `install-manifest.txt`; a derived one needs an `upstream-lineage.json` entry. | `.workflow/rules.md` § Cross-cutting policy |
| Rules: no dependency on tests | Nothing in `.agents/` depends on `tests/`. | `.workflow/rules.md` § Cross-cutting policy |
| ADR-0001 (accepted) | Host-neutral `.agents/` core with thin host shims; `install.sh` distributes exactly what `install-manifest.txt` lists. | `.workflow/decisions/adr/0001-project-baseline.md` |
| Install manifest | Lists `skills/feature-workflow` and `skills/domain-modeling` as whole folders, so new files need no manifest line. | `.agents/install-manifest.txt:11`, `:14` |
| Capabilities | CAP-002 and CAP-003 cover review lessons; no capability describes the router, step-file split or term gates. | `.workflow/capabilities.md` |
| Review lesson RL-001 | A new agent definition or task type must update the agents header, PROVENANCE count and model-map tier table. | `.workflow/review-lessons.md` § RL-001 |
| Pitfall: frontmatter edits | Edit frontmatter with Edit or `yq --front-matter=process`, never `--front-matter=extract -i`. | `.workflow/decisions/pitfalls.md` |
| Retrospective 004 | Discovery was thin and the change ran past the ~100-line light-path rule of thumb. | `.workflow/decisions/retrospectives/004-scoped-test-runs.md` § Process lessons |
| Doc mismatch: retrieval launch timing | `retrieval.md` says it launches after terms are agreed; discovery launches it beside the term-gate ask. | `.agents/agents/retrieval.md:3`; `modules/discovery.md:69-74` |
| Deferred shelf | No concept match among the non-archive `.workflow/deferred/` files. | `.workflow/deferred/*.md` |

## Library options

### Context size measurement (tokens)

Verdict: Use existing (in-house byte and line counts with `wc` and `awk`). Reject tiktoken and gpt-tokenizer. Do not put the Anthropic count_tokens API into scaffold runtime or tests; at most a one-off manual check.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| In-house: wc -c, wc -l, awk | caution: a byte count is a proxy, not tokens | pass: no dependency | pass: POSIX tools | pass: nothing added | pass: 0 deps |
| tiktoken@0.14.0 (Python) | fail: OpenAI encodings, not Claude's; adds a Python runtime | caution: deps.dev "non-standard"; repo MIT | pass | caution: no Scorecard | caution |
| gpt-tokenizer@4.1.0 (npm) | fail: OpenAI encodings; adds a JS runtime | pass: MIT | pass | pass | caution: npm dependency |
| Anthropic count_tokens API | caution: exact for a Claude model but needs key and network | unknown | pass: GA | caution: sends workflow text to a hosted API | caution: cannot run offline in tests |

Evidence: https://platform.claude.com/docs/en/build-with-claude/token-counting, https://platform.claude.com/docs/en/api/migration-2026-10-21, https://api.deps.dev/v3/systems/pypi/packages/tiktoken/versions/0.14.0, https://api.deps.dev/v3/systems/npm/packages/gpt-tokenizer/versions/4.1.0, https://github.com/openai/tiktoken

Risks: a byte threshold must be stated in bytes, not tokens; newer Claude tokenizers give about 30% more tokens for the same text.

### Markdown structure lint

Verdict: Build in-house (bash checks under `tests/lint/`, like `lint/frontmatter` and `lint/step-list`). Reject markdownlint-cli2 for now.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| In-house bash lint | pass: matches existing lint suites | pass | pass | pass | pass: about 1 day |
| markdownlint-cli2@0.24.0 (Node) | caution: needs Node, which the test preflight does not check | pass: MIT | pass | pass | caution: new npm install |

Evidence: https://api.deps.dev/v3/systems/npm/packages/markdownlint-cli2/versions/0.24.0

## Module audit

Owning module: feature-workflow. Re-audited at 7a9b852; paths under `.agents/skills/feature-workflow/`.

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | SKILL §5 already has the blocks conventions.md needs: One writer (ST forms, exit codes) :140-149, Size budget :150, Set the step then write (guarded-writes table with Done folder and path-only rewrite rows) :151-167, Never grow the spec :168, Sub-agent writes :169, Progress line :171-179. | `SKILL.md:136-179` |
| reuse | Launch header, the 00.14/00.19 denies and the host Launch row (every `s<NNN>`/`i<NNN>` task-name form) are in one place. | `SKILL.md:181-204` |
| reuse | Non-launch host rows (Write guards, Resume offer, Question rounds, Other skills) and the Codex-hooks note. | `SKILL.md:205-210` |
| reuse | The questioning-loop Entry seed table and the SKILL §4 gate table have the same rows, both 0.6 cases included; owner and status-call columns can be merged in. | `modules/questioning-loop.md:13-21`; `SKILL.md:123-134` |
| reuse | Questioning-loop already has its own Claude/Codex round format, duplicating the Question rounds host row. | `modules/questioning-loop.md:51-60`; `SKILL.md:207` |
| reuse | The guarded-writes table matches the `check-write.sh` step constants: use them to check the table after it moves. | `scripts/check-write.sh:74-83` |
| reuse | A step file that runs on its own defines `ST` locally; new step files copy that line. | `modules/discovery.md:7`; `modules/questioning-loop.md:5`; `modules/discovered-work.md:7`; `modules/small-path.md:7`; `modules/large-path.md:9` |
| reuse | Small-path changes and their future owners: 0.1.4 :25, 0.2.4–0.2.6 :26 and 0.3.22 :27 → discovery.md; 0.3.8–0.3.18 :28-32 and 0.3.19 with its loop-back clause :33-35 → questioning-loop; 0.3.20 with no fresh-session offer :36 → discovery-impact.md; 5.4 :44-54, 5.5 :56, 5.7 :57 → sign-off. Phases 3 and 4 (:38-40) change nothing; review-triage already says "the small path included". | `modules/small-path.md:25-57`; `modules/review-triage.md:21` |
| gap | Two parts of small-path.md have no home: "Leave the small path" (triggers at 0.3.3 in discovery, at the round and 0.3.19 in questioning-loop, plus the late library-evaluation launch) and the 0.0.3 intake load line. The router links `#leave-the-small-path`. | `modules/small-path.md:9-19`; `SKILL.md:62`, `:65`, `:94`, `:232` |
| gap | The proven-first escalation rule is written in full only in discovered-work "Assess each report first"; review-triage has a Phase 4 version (proof check, verdicts, buckets); the other copies are summaries. Phase 1–3 callers (1.2/1.3, 2.1, 3.2/3.4/3.7) reach it through discovered-work today. | `modules/discovered-work.md:3`, `:24-47`; `modules/review-triage.md:3`, `:77-99`, `:116-123`; `SKILL.md:168`; `modules/implementation-orchestrator.md:177`, `:307-318`; `modules/verification-setup.md:99`; `modules/task-breakdown.md:27` |
| gap | Nothing in the module produces a term list for 0.2.1. | `modules/discovery.md:3`, `:59` |
| gap | 0.2.1 builds the affected area from the Ownership `owns` globs; that area feeds `cache-stamp-check --area`, retrieval and library-evaluation (0.2.2–0.2.5), so 0.2.1 needs Ownership before 0.3.3. Shared core is first used at 0.3.20 `touches_core`. | `modules/discovery.md:59`, `:63`, `:109`, `:180` |
| gap | The Route table names `discovery` for every other draft step and `implementation-orchestrator` for 3.1 and rework, with no split by node. | `SKILL.md:81-87` |
| gap | The "Per-task gates" section also holds result routing and 3.4; only 3.5–3.8 are assigned (to gates). | `modules/implementation-orchestrator.md:161-166` |
| gap | 3.9 runs after every wave's 3.15. A 3.9 or 3.11 failure reopens a task through 3.5–3.8, 3.16, 3.15 and 3.9, so finish and waves load each other and both load gates; the 3.16 pr-blocking and conflict paths re-enter 3.5–3.8. | `modules/implementation-orchestrator.md:93`, `:217`, `:239`, `:254`, `:280`, `:287` |
| gap | The single "3.13-3.14" section splits across two files (3.13 in waves, 3.14 in finish); 3.1 step 4 decides which suites exist for 3.13. | `modules/implementation-orchestrator.md:87`, `:254`, `:289-303` |
| constraint | 3.2 links to Evidence (`#evidence-and-the-ledger` :114), Discovered work (:120, :121), Stops (:120), and in plain text "as 3.16 does" :121, "as at 3.5-3.6" :122. Launching agents links into 3.2 at :16, :30, :43; Stops rows name 3.2 at :326, :327, :330, :335, :336. | `modules/implementation-orchestrator.md:102-134` |
| constraint | 3.4–3.8 link to Evidence :163, :190; Discovered work :165, :177; Stops :165, :200; "merge at 3.16" :178. Launching agents links `#per-task-gates-34-38` at :45; the 3.7 launch uses table row :17 and the `_r<round>` name :41. | `modules/implementation-orchestrator.md:161-200` |
| constraint | Stops is linked from :31, :58, :100, :120, :151, :165, :200, :280, :287 and points back to Discovered work, Evidence and 3.15 (:328-331). Evidence is linked from :69, :114, :163, :190, :330. | `modules/implementation-orchestrator.md:320-337`, `:47-67` |
| constraint | The rework entry skips 3.1's status change. On resume, a spec at 3.16 or 3.15 runs 3.15 first. 3.1 runs again on resume (status and classification, step 4 suite lookup). | `modules/implementation-orchestrator.md:69`, `:71`, `:83` |
| constraint | Links whose anchors move: `../SKILL.md#host-notes` (5); `#5-conventions-every-module-follows`; `../SKILL.md#3-route-by-status`; `../SKILL.md#4-re-entry-56-and-loop-backs`; `discovery.md#0320-light-path-test` (3); `implementation-orchestrator.md#316-merge-the-wave`; `#leave-the-small-path`; SKILL's own `#progress-line`, `#4-…`. | `modules/discovery.md:3,76,125,216,254`; `modules/questioning-loop.md:44,78,90`; `modules/review-triage.md:34`; `modules/verification-setup.md:11`; `modules/implementation-orchestrator.md:7`; `modules/large-path.md:230`; `modules/small-path.md:15,32`; `SKILL.md:65,98,224` |
| constraint | Cross-file links the discovery split creates: discovery-impact → discovery `#seeded-from-a-work-item` (:193, :248); questioning-loop reads the 0.3.20 facts table at 0.3.19. | `modules/discovery.md:159-165`, `:193`, `:248`; `modules/questioning-loop.md:78` |
| constraint | Plain-text section references: "SKILL.md, Conventions every module follows"; "SKILL.md Host notes"; "Re-entry (5.6)" in SKILL.md. | `modules/review-triage.md:5`; `modules/sign-off.md:5`, `:147`; `modules/deferred-handoff.md:40` |
| constraint | Plain-text loads to re-point: rework and resume → waves; task-breakdown → setup; the discovery light pass → setup. | `modules/review-triage.md:17`, `:167`; `modules/task-breakdown.md:119-120`; `modules/discovery.md:195` |
| constraint | Script and asset headers that name moved or removed step files. | `scripts/check-merge-artifacts.sh:18`; `scripts/commit-workflow-data.sh:22`; `scripts/check-task-result.sh:64`; `scripts/open-task-pr.sh:37`; `scripts/rules-setting.sh:16,34-35`; `scripts/task-waves.sh:43`; `scripts/budget-check.sh:47`; `scripts/status-transition.sh:84`; `scripts/spec-worktree.sh:29`; `assets/task.md:3`; `assets/tasks.md:23`; `assets/codebase-map.md:9`; `assets/design-log.md:3`; `assets/data-model.md:3`; `assets/verification-plan.md:3`; `assets/report.md:4` |
| constraint | The two sub-agent write rules differ: large path "never write"; SKILL "only their own result file". | `modules/large-path.md:64`; `SKILL.md:169` |
| constraint | The large path uses the bare `<6.x>` progress form; a 6.x id with `--spec-dir` exits 2. | `modules/large-path.md:39`; `scripts/step-progress.sh:7-19` |
| constraint | Large-path Conventions parts that are initiative-only: IT forms :9-19, step table :20-38, Main ref :40-54, Commit point :56-61; shared or launch parts: Progress :39, Launches :63, Sub-agents :64. | `modules/large-path.md:7-64` |
| constraint | Codex launch details repeated in step files. | `modules/discovery.md:76,125,216`; `modules/questioning-loop.md:44`; `modules/review-triage.md:21,34-39`; `modules/implementation-orchestrator.md:32-43,106,138`; `modules/verification-setup.md:67`; `modules/large-path.md:63` |
| constraint | References added since 1058a0d. Spec worktree: `SKILL.md:30,71`; `discovery.md:11,185-191,254`; `implementation-orchestrator.md:7`; `sign-off.md:239-245`. 0.6 re-entry: `SKILL.md:80,128`; `questioning-loop.md:16`; `verification-setup.md:11`. Done folder: `SKILL.md:28,30,92,164-165`; `discovery.md:11,23`; `sign-off.md:5,196-212`; `large-path.md:40-54`. | as listed |
| constraint | Scripts are always called with the exact `scripts/` prefix. | `SKILL.md:140`; `modules/implementation-orchestrator.md:5` |
| constraint | `steps.tsv`, `step-progress.sh` and `check-write.sh` name no step file. | `references/steps.tsv:1-8`; `scripts/step-progress.sh:2-4` |

## Not found

- A term-list artifact or script in feature-workflow, or a `scripts/` folder in domain-modeling. Reported by module-audit and fact-lookup.
- A reader of `progressive_loading` or the SKILL `modules:` key in the module; a test pin for `progressive_loading`. Reported by module-audit and fact-lookup.
- A small-path note already in sign-off.md or questioning-loop.md. Reported by module-audit.
- A test pin for SKILL.md §4, the §5 rules other than the Done folder bullet, Host notes, or discovery.md sections 0.3.20–0.6. Reported by fact-lookup.
- A file outside feature-workflow that names `small-path.md`, `implementation-orchestrator.md` or a `SKILL.md#` anchor. Reported by fact-lookup.
- A size limit on skill or step files in `tests/` or `.workflow/rules.md`. Reported by retrieval (2026-10-29).
- A shelf match for this request. Reported by retrieval (2026-10-29).
- cache disagrees with code (resolved): the 2026-10-29 Relevant code and Seams line references had drifted (frontmatter, Route, Modules, Conventions, launch, check-write, step-file loads, checker); the rows above carry the audit's current lines. The old audit's "3.11 and 3.14 hand off to `#hand-off`" was wrong: only 3.11 does (`modules/implementation-orchestrator.md:286`, `:303`). Reported by module-audit.
