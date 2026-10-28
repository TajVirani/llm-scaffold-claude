# Design log: Cache build follow-ups from spec 003

## 2026-10-26 Origin: 003-bash-cache-extractor-disc-002.md

- Work item: 003-bash-cache-extractor-disc-002.md
- Origin spec and step: .workflow/specs/003-bash-cache-extractor, step 4.4 (started at its 5.9)

### Problem (copied from the item)

Two skills decide which files are tests with the same default pattern list and the same matcher, each holding its own copy: the size-budget count in feature-workflow and the entry-point candidates in regenerate-caches. Nothing keeps the copies in step, so a change to one makes the two disagree about which files are tests. The shell-scripts profile says code a second skill needs moves to `.agents/lib/`.

### Evidence (copied from the item)

- `.agents/skills/feature-workflow/scripts/budget-check.sh:60-68` and `.agents/skills/regenerate-caches/scripts/build-architecture.sh:518-526` hold identical default lists; the matchers are at `budget-check.sh:155-170` and `build-architecture.sh:527-567` (commit `48d8646`).
- review-standards RS-1, pass 1 (`.workflow/specs/003-bash-cache-extractor/artifacts/review/pass-1/review-standards.yaml`), triaged F1.
- `.workflow/profiles/shell-scripts.md` File locations: "Code a second skill needs moves to `.agents/lib/`."
- Related shelf file on the same copied-helper convention: [.workflow/deferred/shared-path-normaliser.md](../../deferred/shared-path-normaliser.md).

## 2026-10-26 Origin: 003-bash-cache-extractor-disc-003.md

- Work item: 003-bash-cache-extractor-disc-003.md
- Origin spec and step: .workflow/specs/003-bash-cache-extractor, step 3.4 (started at its 5.9)

### Problem (copied from the item)

The bash graph extractor treats each `|`-separated alternative of a `case` pattern as a command. A pattern such as `../*` then looks like a call to a script by a path relative to the working directory and is listed under Unresolved edges, though nothing is called. The architecture cache shows false unresolved entries; no edge is lost or wrong.

### Evidence (copied from the item)

- `install.sh:133` (`/* | ../* | */../* | */.. | ..) die ...`) and `install.sh:187` (`case "$f" in /* | ../* | ...`) each give a `couldNotResolve` entry `../*` from `extractors/bash.sh --root . --scope .` at commit `5cc1147` (task branch of T3, rework 1).
- T3 implementation result, `.workflow/specs/003-bash-cache-extractor/artifacts/T3/implementation.yaml`, `discovered_work`.

## 2026-10-26 Origin: 003-bash-cache-extractor-disc-004.md

- Work item: 003-bash-cache-extractor-disc-004.md
- Origin spec and step: .workflow/specs/003-bash-cache-extractor, step 2.1 (started at its 5.9)

### Problem (copied from the item)

When the architecture build runs the depcruise boundary check and depcruise does not run (for example, not installed but `npx` is on the path), the failure is hidden and Boundary violations reads `None.`. The cache then claims the project has no boundary violations although nothing was checked. This predates spec 003; after D16 it reaches only projects whose profiles name `dependency-cruiser`.

### Evidence (copied from the item)

- `.agents/skills/regenerate-caches/scripts/build-architecture.sh:248-254`: `tool_cmd` picks `npx --no-install depcruise` whenever `npx` exists, without checking that it runs.
- `build-architecture.sh:375`: the run ends `|| true`, because violations also make depcruise exit non-zero.
- `build-architecture.sh:381-384`: `jq` on the empty output prints nothing, so the section renders `None.`.
- Seen on this repo at 5.6: `npx --no-install depcruise --version` exits 1, and `build-architecture.sh --cache architecture` exits 0 with `None.` (design-log "Correction to the 5.6 change-request entry").

## 2026-10-26 Origin: 003-bash-cache-extractor-disc-005.md

- Work item: 003-bash-cache-extractor-disc-005.md
- Origin spec and step: .workflow/specs/003-bash-cache-extractor, step 4.4 (started at its 5.9)

### Problem (copied from the item)

The `cache-regeneration` agent runs regenerate-caches scripts and visual-change-report's Mermaid validator by `skills/<name>/` path. `.workflow/rules.md` Ownership lets the agents module depend only on feature-workflow, and it counts a `skills/<name>/` path reference as a dependency. So the agent breaks the ownership map, and nothing enforces it.

### Evidence (copied from the item)

- `.agents/agents/cache-regeneration.md:36` (`S=.agents/skills/regenerate-caches/scripts`, already at baseline `86609a6`), `:85` and `:88` (visual-change-report paths).
- `.workflow/rules.md:79-81`: `agents: owns: [".agents/agents/**"] may_depend_on: [feature-workflow]`.
- Found by review-standards, review pass 2 (RS-3, triage F8): `.workflow/specs/003-bash-cache-extractor/artifacts/review/pass-2/review-standards.yaml`.

## 2026-10-26 Combined into one spec

- Stakeholder, verbatim: "Combine the new work into a shared spec."
- Specs 005-shared-test-patterns, 006-bash-case-patterns, 007-boundary-check-failure and 008-agents-skill-dependencies (all `draft` at 0.1.6, never committed, no branches) became this one spec; folders 006-008 were deleted, so their numbers were never taken.
- `origin` holds one filename (003-bash-cache-extractor-disc-002.md); the other three items also point here through `promoted_to`. When discovery finishes (0.6 or 0.3.20), delete all four: 003-bash-cache-extractor-disc-002.md, -disc-003.md, -disc-004.md, -disc-005.md.

## 2026-10-26 Came off the shelf: shared path normaliser

- Came off the shelf: [.workflow/deferred/archive/shared-path-normaliser.md](../../deferred/archive/shared-path-normaliser.md)
- Retrieval (0.2.4) reported it as a concept match: the same copied-helper convention as the duplicated test-path rules (disc-002). Stakeholder, asked at 0.2.6 whether this spec is that item: "Yes, take it in".
- Its Goal: every script that takes a workflow folder path validates it the same way, from one place, so a new folder kind is one change rather than one per script.
- Its acceptance criteria: one helper under `.agents/lib/` resolves and validates a workflow folder path for both folder kinds (spec, initiative); the per-script copies are removed and every caller sources it; tests cover a spec path, an initiative path, an absolute path under the main checkout and a rejected path; `tests/run-all.sh` passes and shellcheck is clean.
- Its constraints carry over: `.agents/lib/` is shared core (integration agent only, between batches); revising the self-contained-scripts convention needs a design-log or ADR entry, not a silent change.
- Copies as of `0a662df`: `status-transition.sh:121-145`, `budget-check.sh:78-98`, `task-waves.sh:60-74`, `open-task-pr.sh:62` (all under `.agents/skills/feature-workflow/scripts/`).
- The goal is revisited at 0.3.19 to include it.

## 2026-10-26 Reframe (0.3.1-0.3.2)

- The `case` pattern fix (disc-003) is a change to CAP-005 (bash graph extractor): it keeps CAP-005.
- The failed-depcruise fix (disc-004) is a change to CAP-004 (graph extractor per work profile; the architecture cache build that renders Boundary violations): it keeps CAP-004.
- The shared test-path rules (disc-002), the shared path normaliser (off the shelf) and the agents ownership fix (disc-005) are refactors with no user-visible capability; 0.3.19 decides whether they need a CAP line.

## 2026-10-26 Placement (0.3.4)

- Touched modules: lib, feature-workflow, regenerate-caches, agents (tests for the suites). No single module owns every path.
- Shared helpers: the test-path rules (default patterns, profile loading, matcher) and the workflow-folder path normaliser move to `.agents/lib/` (shared core). Stakeholder chose the recommended option. Consequences: changes go through the integration agent between batches; the self-contained-scripts convention (feature-workflow scripts copy helpers, sourcing only `workflow-paths.sh`) is revised and needs a recorded decision.
- `case` pattern fix and failed-depcruise fix: regenerate-caches (`extractors/bash.sh`, `build-architecture.sh`).
- Agents ownership break (disc-005): stakeholder chose "Move the calls into the skill" over widening the rule. regenerate-caches gets one wrapper script that the cache-regeneration agent calls, which also runs the Mermaid check. The agent still names one regenerate-caches path, so `agents.may_depend_on` still needs `regenerate-caches`; regenerate-caches already may depend on standalone-skills, so the visual-change-report reference becomes legal once it lives in the skill.

## 2026-10-26 Placement check (0.3.5-0.3.7)

- 0.3.5 ADRs: no conflict with ADR-0001, ADR-0002 or ADR-0003. The "scripts are self-contained; helpers are copied per script; only `workflow-paths.sh` is sourced" convention was a spec 001 module-audit constraint, not an ADR or rule; `.workflow/profiles/shell-scripts.md` File locations already says "Code a second skill needs moves to `.agents/lib/`". This entry is the recorded decision that revises the convention for the two helpers.
- 0.3.5 Rules: one conflict. The agent will still call one regenerate-caches script, and `agents.may_depend_on` is `[feature-workflow]`. Not overridden mid-feature: proposal P1 in [proposals.md](proposals.md) for 5.3.
- 0.3.7 No placement ADR: the placement fails the three-part test. Moving helpers to `.agents/lib/` and adding a wrapper script are cheap to reverse and follow the existing profile rule, so a future reader would not be surprised.

## 2026-10-26 Deeper prompt (0.3.22)

- Round 1: drafted elevation and five goals; stakeholder answered downstream "none known", tools "no new deps", gotchas "those two gotchas cover it" (bash 3.2 has no `**`; the never-filter-a-detected-call pitfall).
- Round 2: full block restated; stakeholder agreed: "yes, pass it on".

**Ask:** Make the Tier B caches, and the rules around how they're built, tell the truth. A published cache lists only real calls and reports only checks that actually ran. Each shared rule lives in one place, and the ownership map matches the code.

**Goals:**
- A rebuilt architecture cache for this repo no longer lists the `install.sh:133,187` `case` patterns under Unresolved edges, and every real call the extractor finds is still listed.
- When depcruise doesn't run, Boundary violations says the check failed or wasn't made. It never says `None.`
- The size budget and the flow entry candidates use one definition of a test file, kept in `.agents/lib/`.
- All the feature-workflow scripts that take a workflow folder path validate it through one helper in `.agents/lib/`.
- The cache-regeneration agent calls only one regenerate-caches wrapper script, and after P1 is approved, no reference in it breaks `.workflow/rules.md` Ownership.

**Downstream:** none known.

**Tools and technologies:** no new dependencies. Use plain bash `case` for matching, the existing awk parser for `case` statements, and depcruise's JSON `summary` instead of its exit code.

**Gotchas:** bash 3.2 has no `**` globstar. The pitfall "report a detected call as unresolved; never filter it out" means the `case` fix must tell patterns apart from calls; it can't just drop entries.

**Not asked for:** a boundary checker for bash, other graph extractors, moving other copied helpers to `.agents/lib/`, a parser for the full bash grammar (mvdan/sh, tree-sitter), and node-version rules for depcruise.

**Original request:** "Combine the new work into a shared spec." (backlog items 003-disc-002 to -005), plus "Yes, take it in" for the shelved shared path normaliser.

## 2026-10-26 Questioning round 1 (0.3.8-0.3.11)

- **D1 One spec or initiative?** Options: keep one spec; convert to initiative; defer. Recommended: keep one spec (stakeholder asked to combine; small fixes, one theme, one review). Answer: "Keep one spec (Recommended)". Decision: one spec, no conversion.
- **D2 Depcruise could not run.** Options: render `Not checked: depcruise did not run (<reason>).` and carry on; fail the build; defer. Recommended: Not checked and carry on (matches the existing `Not checked: no boundary checker ...` wording, codebase-map Relevant code, build-architecture.sh:380-383). Answer: "Say Not checked, carry on (Recommended)". Decision: when depcruise is missing, fails, or prints output that is not JSON with `.summary`, Boundary violations reads `Not checked: depcruise did not run (<reason>).`; the build exits 0.
- Facts pending: fact-lookup Q1-Q5 (normaliser copies, test-pattern differences, agent skill references, bash.sh `case` handling, depcruise input path). The questions on the helper interfaces, the wrapper script and the `case` fix wait for them.

### Facts looked up for round 1-2 (fact-lookup, HEAD d6edbc9)

- Q1 normaliser copies: `norm_spec_dir` + `main_root` in status-transition.sh:122-145, budget-check.sh:78-99, task-waves.sh:54-75, commit-workflow-data.sh:30-58 (only copy with default exit 2); `norm_initiative_dir` in initiative-transition.sh:104-126; inline in open-task-pr.sh:111-134 (no parent-folder check on absolute paths, so `/anywhere/001-x` passes). All under `.agents/skills/feature-workflow/scripts/`. Same slug rule and message everywhere. About 15 other main-checkout resolvers exist in hooks, regenerate-caches and agent docs; they are not normaliser copies.
- Q2 test-path copies: same defaults, profile glob, awk reader, sort and matcher. Differences: budget-check dies exit 1 with two messages, build-architecture exit 2 with one; build-architecture lacks budget-check's empty-Toolchain-block guard (may die on an empty block; inferred, not run); yq v4 check only in budget-check. The JS regex at build-architecture.sh:604 also drops `__mocks__/` and `.d.ts` files, which are not tests, and repeats `__tests__`/`.test.`/`.spec.`.
- Q3 agent references: `$S` build-architecture.sh at cache-regeneration.md:41,44,49,63; check-staged-cache.sh :77; visual-change-report validate_mermaid.mjs :85 (needs node plus `mermaid` and `jsdom` in node_modules; the gate at :82 checks only the packages); visual-library.md checklist :88. No regenerate-caches script runs the Mermaid check today.
- Q4 bash.sh: no `case`/`esac` state. A `)`-ending first word is skipped (:403), but `|` splits arms, so `../*` in the middle of `/* | ../* | ..)` has no `)` and is reported by the cwd-relative rule (:341-360). Untested forms: `case`/`esac` lines, multi-line arms, `(pattern)` leading-paren arms (false positive), `./x)` arms (false positive).
- Q5 depcruise: build-architecture runs depcruise itself unless `--violations-json`; with npx present and depcruise absent, `|| true` and `2>/dev/null` leave an empty file, jq prints nothing, the section says `None.` Reached on `--from-json` runs or when the extractor succeeds and the second run fails. The extractor (dependency-cruiser.sh:51-52) dies loudly on the same failure. No test covers the silent path.

## 2026-10-28 Questioning round 2 (0.3.8-0.3.11)

Stakeholder answer to the whole round, verbatim: "use recomended".

- **D3 `case` fix.** Options: (a) awk tracks `case ... in` / `esac` state and skips only each arm's pattern list (up to its first unquoted `)`); (b) skip words ending in `)`; defer. Recommended (a): (b) cannot fix `install.sh:133` because `|` splitting leaves the middle `../*` without `)` (bash.sh:326, :341-360). Decision: (a); commands after the `)` are still scanned (pitfall kept); fixture tests for one-line, multi-line, `(pattern)`, `./x)` and alternation arms, plus `case`/`esac` lines.
- **D4 Path normaliser home.** Options: (a) `wf_main_root` and `wf_norm_folder spec|initiative <arg>` in `.agents/lib/workflow-paths.sh`; (b) a new `.agents/lib/workflow-folders.sh`; defer. Recommended (a): workflow-paths.sh is the one home for `.workflow/` paths and every caller already sources it. Decision: (a). The helper returns a status and a message; each script keeps its own `die` and exit code (commit-workflow-data stays exit 2).
- **D5 Which copies.** Options: (a) the six scripts with a normaliser (status-transition, budget-check, task-waves, commit-workflow-data, initiative-transition, open-task-pr); (b) also the ~15 other main-checkout resolvers; defer. Recommended (a): the others are Not asked for. Decision: (a); open-task-pr gains the parent-folder check on absolute paths.
- **D6 JS regex at build-architecture.sh:604.** Options: (a) drop its test parts so the shared helper is the only test definition, keep `__mocks__/` and `.d.ts` as a separate non-test filter; (b) leave it; defer. Recommended (a): goal 3, one definition of a test file. Decision: (a).
- **D7 Agent references.** Options: (a) move the Mermaid check into `check-staged-cache.sh` (runs validate_mermaid.mjs when node, `mermaid` and `jsdom` are present, else prints `not machine-validated` and the checklist path); (b) a new wrapper with subcommands; defer. Recommended (a): same outcome as the 0.3.4 choice ("move the calls into the skill") without a new interface. Decision: (a); this refines the 0.3.4 "one wrapper script" wording: check-staged-cache.sh is that script for the Mermaid check, and the agent's other calls are to regenerate-caches scripts, legal once P1 is approved.

## 2026-10-28 Impact classification (0.4.4)

- create: `.agents/lib/test-paths.sh`.
- extend: `.agents/lib/workflow-paths.sh` (`wf_main_root`, `wf_norm_folder`); Boundary violations "did not run" wording; `check-staged-cache.sh` Mermaid check.
- refactor: the six normaliser copies (status-transition, budget-check, task-waves, commit-workflow-data, initiative-transition, open-task-pr); the two test-path copies (budget-check, build-architecture) and the entry-candidate regex; `extractors/bash.sh` `case` handling; `cache-regeneration.md` step 4.
- unchanged: `budget-check.sh` and `build-architecture.sh` CLIs and outputs, extractor JSON shape, profile `test_patterns`, rules.md Ownership (P1 at 5.3).
- No data, no migrations. Full table in [data-model.md](data-model.md).

## 2026-10-28 Scope decision: main-checkout resolver (0.3.17)

- Item: module-audit (lib, feature-workflow) Out of scope lines: the other main-checkout resolver copies (rules-setting, check-write, run-toolchain, check-worktree-scope, resolve-launch, hooks, regenerate-caches, agent docs), incl. copies missing the worktree fallback and run-toolchain's un-normalised absolute spec dir. Assessed can-wait.
- Ruling: out of scope by D5 and the deeper prompt's Not asked for. Shelved AFK: [.workflow/deferred/main-checkout-resolver.md](../../deferred/main-checkout-resolver.md).

## 2026-10-28 Scope decision: bash case fall-through terminators (0.3.17)

- Item: module-audit (regenerate-caches) Out of scope line: bash 4 `;&` and `;;&` arm terminators not handled by the split at bash.sh:326. Assessed can-wait (this repo pins bash 3.2).
- Ruling: outside the agreed goals (this repo's cache). Shelved AFK: [.workflow/deferred/bash-case-fallthrough.md](../../deferred/bash-case-fallthrough.md).

## 2026-10-28 Questioning round 3 (0.4.7 goal conflicts, 0.3.8-0.3.11)

Loop-back from 0.4.7: the regenerate-caches module audit reported two blocks-this-task lines (codebase-map Module audit, regenerate-caches gaps), plus a feature-workflow gap on open-task-pr `--record`.

- **D8 (supersedes D6) JS regex at build-architecture.sh:604.** Conflict: dropping its test names makes `foo.test.ts` outside `tests/` a flow entry candidate in a project whose profiles all set `test_patterns`. Options: keep D6; revert D6 and keep the regex; always-on JS defaults in both budget and flows; defer. Recommended: keep D6. Answer: "Revert D6, keep regex". Decision: the regex stays unchanged. Budget and flows share the test-pattern helper; flows keeps the regex as an extra filter on entry candidates.
- **D9 (refines D2) When depcruise counts as run.** Options: fixed reasons, stderr never shown, bad `--violations-json` stays exit 2; show stderr's first line; defer. Recommended: fixed reasons. Answer: "Agree (Recommended)". Decision: depcruise ran only when its output parses as JSON with a `.summary.violations` array. Otherwise Boundary violations reads `Not checked: depcruise did not run (<reason>).` with reason `not found`, `exited <n> without a JSON report` or `no .summary.violations in its output`; exit 0. "not found" now renders instead of dying. A `--violations-json` file that does not parse still exits 2 (caller input, usage error).
- **D10 (extends D5) open-task-pr `--record`.** Options: include it; spec path only; defer. Recommended: include. Answer: "Yes, include it (Recommended)". Decision: `--record` goes through `wf_norm_folder initiative`; its message and `generic_usage` exit 2 stay.

## 2026-10-28 Goal confirmed again (0.3.19)

- Summary of the D8-D10 changes restated; stakeholder: "yes". spec.md goals, CAP-004 success and constraints revised; data-model.md rows updated (regex unchanged, `--record`, fixed reasons).
- Light-path facts: Open Questions empty; nothing irreversible; footprint four modules and ~12 non-mechanical files, so not small. `light_path: false` stands.
- 0.4.7 re-check: with D8-D10 the module-audit conflicts are resolved; no placement conflict. Continue at 0.5.

## 2026-10-28 Exit gate (0.6): clear

- Scope: Non-goals and `deferred` list every ruled-out item; Open Questions empty. System impact: module audits for lib, feature-workflow, regenerate-caches in codebase-map.md; no cache disagrees with code (two line-range drifts in retrieval rows noted, not cache problems). Data changes: data-model.md classifies every part; no migrations. Testable objectives: CAP-004 and CAP-005 each have objectives and journeys (JRN-001 to JRN-008).
- Status `ready-for-dev`. Work items 003-bash-cache-extractor-disc-002.md to -005.md deleted, as agreed in "Combined into one spec".

## 2026-10-28 Verification setup: targets and baseline (1.1)

- Spec branch `spec/005-cache-build-followups`; baseline `1f59f20ee80efb50bfac85ba56afa22301eced56` (carries the spec folder, the two new shelf files, the shared-path-normaliser archive move and the four promoted work items' deletion).
- Main has not moved since the handoff (`d6edbc9`); no contract change to note.
- Targets TGT-001 to TGT-007 in verification-plan.md. Stakeholder decisions: TGT-001 architecture build ≤ 1.2 s best of 3 ("≤ 1.2s (no regression)"; baseline 1.16-1.26 s); TGT-007 coverage not measured ("Unmeasurable, record reason").
- Stub interface for 1.2 (names not fixed by D4; set here so Phase 1 tests can call them): `.agents/lib/test-paths.sh` exports `wf_default_test_patterns` (prints the default list, one per line), `wf_load_test_patterns <profiles_dir>` (prints the merged list; on an invalid `test_patterns` returns 1 and prints the message) and `wf_is_test_path <path>` (reads the list from `WF_TEST_PATTERNS`, returns 0 for a test path, 1 otherwise). `.agents/lib/workflow-paths.sh` gains `wf_main_root` and `wf_norm_folder spec|initiative <arg>` (prints the normalised repo-relative folder; returns 1 and prints the message on reject). Each caller keeps its own `die` and exit code (D4).

## 2026-10-28 Phase 1 harness (1.2-1.5)

- 1.2: harness merged (`e302664`); 58 new cases red on assertions, 3001 existing pass. New suites `scripts/cache-repo-architecture`, `scripts/lib-test-paths`, `scripts/lib-workflow-paths`; oracle `tests/fixtures/architecture-oracle.sh` (236 entries, matched on file plus source text). Pre-change normaliser behaviour in `artifacts/phase-1-test-harness/normaliser-baseline.md`.
- JRN-003 "not found" is tested as `DEPCRUISE` naming a missing path, so the Phase 3 code checks the path before running it (else it reports "exited 127").
- Not pinned by the spec: what `check-staged-cache.sh` does when the Mermaid validator itself fails (node exits 1). Settle at task breakdown (2.2).
- 1.3: not applicable (no browser suite). 1.4: record in `artifacts/phase-1-known-bad/record.md`.

## 2026-10-28 Task breakdown (2.1-2.4)

- Breakdown approved as proposed: T1 feature-workflow (six scripts on the shared folder-path and test-path helpers), T2 regenerate-caches (entry candidates via the test-path helper), T3 regenerate-caches (Not checked wording, after T2: same file), T4 regenerate-caches (`case` arms), T5 regenerate-caches (Mermaid check in check-staged-cache.sh), T6 agents (after T5). Waves {T1, T2, T4, T5}, {T3, T6}; all afk. Stakeholder: "Approve (Recommended)".
- **D11 Mermaid validator fails on the staged body.** Options: invalid body, exit 1; warn, exit 0. Stakeholder: "Fix the validation project, that is low risk and can be done inline", clarified as "Exit 1; agent fixes Mermaid". Decision: `check-staged-cache.sh` exits 1 with the validator's error on stderr; the cache-regeneration agent fixes the Mermaid in its staged body and re-runs the check (T5, T6).
- Size budget: project defaults, 10 tasks and 30 changed files. Stakeholder: "Defaults 10 / 30 (Recommended)".
- 2.2: every slice specifiable (D11 settles the one open point). 2.3: every seam is an existing CLI or the new lib functions fixed at 1.1. 2.4: T1 and T2 touch shared core (`.agents/lib/`); their requests go to one shell-scripts integration batch before wave 1.

## 2026-10-28 Discovered work: result-file guard (3.2)

- Found by: integration batch `integration-shell-scripts` (3.2); the worktree write guard denied its result file in the main checkout. Kind: bug. Assessment: can wait (CAP-004, CAP-005 and JRN-001 to JRN-008 unaffected).
- Ruling: can be solved later; filed without a ruling, offered at 5.9: [005-cache-build-followups-disc-001.md](../work-backlog/005-cache-build-followups-disc-001.md).
- Workaround, stakeholder answer "Save it; agents write in worktree (Recommended)": the main session saved the integration block verbatim from the agent's report and checked it with `check-task-result.sh` (exit 0) after verifying the two commits, the toolchain pass and both lib suites itself. Wave agents write their result file at the same relative path in their worktree; the main session copies it to the main checkout before checking it.
- Integration merged (`23c0c58`). Interface notes for consumers: workflow-paths.sh refusals go to stderr with no program prefix (callers silence them and `die` with their own line); `wf_load_test_patterns` prints its reason on stdout in place of the list; budget-check keeps its own wording ("must be a list of path patterns").

## 2026-10-28 T2 gate 3.6 (3.5-3.6)

- T2 toolchain: lint pass; test fails only on `JRN-005 no shell file under .agents/ outside lib/test-paths.sh lists the default test patterns` (`got=budget-check.sh`), which T1 turns green. The 2.5 assignment put the whole `lib-test-paths` suite on T2 though that one case needs both T1 and T2. Treated as clean for 3.6; 3.16 merges T1 before T2 (id order) and the 3.9 gate runs `lib-test-paths` on the merged branch.
- 3.4: no tests added by T2; the Phase 1 `lib-test-paths` and `build-architecture` suites already hold the negative (invalid `test_patterns`, exit 2) and edge (empty Toolchain block, `[]`, absent) cases.

## 2026-10-28 Discovered work: TGT-001 noise (3.4)

- Found by: T4 implementation (`artifacts/T4/implementation-r1.yaml`). TGT-001 (≤ 1.2 s best of 3) is within run-to-run noise at the baseline; T4 itself adds nothing measurable. Kind: decision (agent said refactor). Assessment: can wait (CAP-005, JRN-001, JRN-002 unaffected; only the 4.3 number may flip).
- Ruling: can be solved later; filed without a ruling, offered at 5.9: [005-cache-build-followups-disc-002.md](../work-backlog/005-cache-build-followups-disc-002.md).
- T4 3.4: no edge tests added; resumed to add the nested, quoted-`)`, `case`-as-argument and `$(...)` cases it had tried by hand.
- T5 3.7: mini-review result file did not parse (L20 C97); resumed once to rewrite it.
- T5 3.7: mini-review pass with one out_of_scope entry on T5's own new code (temp file left on a write error, check-staged-cache.sh:176-178); handled as a behaviour fix round by resuming the T5 agent (one-line cleanup, its context kept), then a full mini-review. T2 3.8: re-check pass.
- T1 3.4-3.6: toolchain pass; no tests added (the Phase 1 per-script JRN-006 cases hold the reject paths). One message change: budget-check now reports a list with empty or non-string entries as 'must be a list of path patterns' (was 'must hold non-empty strings only'); still exit 1. Accepted: the spec asks for each script's own exit code, and the Phase 1 test pins this wording.
- 3.16 wave 1: T1, T2, T4, T5 merged in id order; task PRs skipped (open-task-pr.sh: "gh not installed"), pr stays null.
