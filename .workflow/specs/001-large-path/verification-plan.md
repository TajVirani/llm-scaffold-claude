# Verification plan: Large path: planning a large subject into several specs

Spec: [spec.md](spec.md)

The "running application" is the scaffold itself: its scripts, hooks and modules run inside a fixture repo that the test harness builds from a copy of `.agents/` (rules: nothing in `.agents/` depends on `tests/`). Every objective below is decided by a harness suite, never by reading the module prose.

## End state

- [ ] CAP-NEW-initiative-conversion: in a fixture repo with a draft spec whose step marker is at the conversion node, running the conversion leaves `.workflow/initiatives/001-<slug>/` on a new branch `initiative/001-<slug>` with `initiative.md` (`status: exploring`, `origin: <spec>`, `branch`, `merge_pr: null`, empty `slices`), the spec's `design-log.md` and `codebase-map.md` moved in, an Origin entry naming the spec, the spec folder gone, the spec's number not reused by the next 0.1.1 scan, and the session-start hook's output no longer naming the spec.
- [ ] CAP-NEW-initiative-exploration: `initiative-transition.sh` refuses every illegal question and slice transition with exit 2 and a reason, and accepts the legal ones; a `research` question left `researching` with `launched` set survives a session end, the session-start hook lists the initiative with its pending research count, and after the answer is written back the next frontier excludes it and includes the questions that depended on it.
- [ ] CAP-NEW-slice-emission: with every question of slice `S1` settled, emission creates `.workflow/specs/NNN-<slug>/spec.md` with `initiative: 001-<slug>`, a Why from the slice and an Origin entry carrying the binding decisions; `initiative.md` shows `S1` as `emitted` with its `spec`; the initiative commit made at emission does not contain the spec folder; the spec validator accepts the new key.
- [ ] CAP-NEW-initiative-close: with the checkout on main and the initiative only on its branch, the session-start hook lists it as `exploring` by reading the branch tip; a `planned` initiative whose emitted specs are all `done` on main flips to `done` on resume through the script, and the merge follows `task_review` (`pr`: the generic PR command is printed in dry-run form; `local`: a `--no-ff` merge commit lands on main and the local branch is deleted).
- [ ] CAP-NEW-initiative-exploration (guards): a Write to `initiative.md` is denied unless the initiative's `.step` is at a `6.x` writer step; a Write to `questions.md` is allowed at any step; a glossary write with an initiative at a `6.x` term-gate step and no spec in flight is allowed, and denied at any other `6.x` step.
- [ ] Constraint (step ids): `tests/run-all.sh` passes with the `large` track present: the step-list lint accepts `6.x`, the per-track pins hold, every `6.x` row prints `Large path · step n of m — <title> (6.x)` from `step-progress.sh`, and the spec single writer's own suite passes unchanged.
- [ ] Constraint (launches): `resolve-launch.sh --requirements` lists `research`; a `research` launch header with `spec_dir` naming an initiative folder resolves; the Codex pre-spawn hook accepts `i001_research` and rejects a malformed name.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Convert a draft spec into an initiative | CAP-NEW-initiative-conversion | 1. Build a fixture repo with a draft spec at the conversion node, a shelf item with `origin_spec` pointing at it and a work item with `promoted_to` pointing at it. 2. Run the conversion steps as the module states them. 3. Run the session-start hook. 4. Run the 0.1.1 numbering scan. | Initiative folder and branch exist as the end state says; the shelf item and work item point at the initiative; the hook output names the initiative, not the spec; the next spec number skips the converted one. | `tests/scripts/initiative-conversion.sh` |
| JRN-002 | Explore across sessions | CAP-NEW-initiative-exploration | 1. Seed `questions.md` with IQ1 (research), IQ2 (decision, depends on IQ1), IQ3 (decision). 2. Compute the frontier. 3. Launch IQ1 (`set-question --state researching --launched research`). 4. Run the session-start hook. 5. Settle IQ1 with a source. 6. Compute the frontier again. | Frontier 1 = IQ1, IQ3; the hook lists the initiative with one pending research question; frontier 2 = IQ2, IQ3; every illegal transition tried on the way exits 2. | `tests/scripts/initiative-transition.sh` |
| JRN-003 | Emit a slice as a seeded spec | CAP-NEW-slice-emission | 1. Settle every question of S1. 2. Run emission as the module states it. 3. Validate the new spec's frontmatter. 4. Inspect the initiative commit. | New spec folder with `initiative:` and an Origin entry; S1 `emitted` with `spec`; `git show --name-only` of the initiative commit lists only `.workflow/initiatives/**`. | `tests/scripts/initiative-emission.sh` |
| JRN-004 | Resume offer reads initiatives | CAP-NEW-initiative-close | 1. Commit an initiative on its branch; switch the checkout to main. 2. Run the session-start hook. 3. Merge the branch (local) and run the hook again. | The hook lists the initiative from the branch tip, then from main, once each, with status, step and pending research count. | `tests/hooks/session-start-initiatives.sh` |
| JRN-005 | Planned initiative merges and later flips done | CAP-NEW-initiative-close | 1. With every slice emitted and no open question, set `planned`. 2. Run the merge step under `task_review: local`, then under `pr` with `--dry-run`. 3. Mark every emitted spec `done` on main. 4. Resume the initiative. | `local`: a `--no-ff` merge on main, local branch deleted; `pr`: the printed gh/glab command names head `initiative/001-<slug>` and base main, and `merge_pr` is recorded; the resume sets `done` and every later subcommand exits 2. | `tests/scripts/initiative-merge.sh` |
| JRN-006 | Write guards for initiative files | CAP-NEW-initiative-exploration | 1. Set the initiative `.step` to a non-writer `6.x` node and send a Write payload for `initiative.md` through the guard. 2. Set a writer node and repeat. 3. Send a `questions.md` Write. 4. Set a term-gate node and send a glossary Write; set another node and repeat. | Deny, allow, allow, allow, deny, each with the guard's reason text. | `tests/hooks/initiative-write-guards.sh` |
| JRN-007 | Large track in the step list and progress line | Constraint (step ids) | 1. Run the step-list lint. 2. Run `step-progress.sh` for the first and last `6.x` row and for a phase 0 row. | Lint passes with the new pins; large rows print the large form; the phase 0 row still prints `Phase 1 of 6`. | `tests/lint/step-list.sh`, `tests/scripts/step-progress.sh` (extended) |
| JRN-008 | Launch from an initiative | Constraint (launches) | 1. Run `resolve-launch.sh --requirements`. 2. Resolve a `research` header whose `spec_dir` is an initiative folder. 3. Run the Codex pre-spawn hook with `i001_research` and with `s001_research`. | `research` is listed with its fields; the resolve returns a prompt and model; the hook accepts the first name and denies the second with a reason. | `tests/scripts/resolve-launch-initiative.sh`, `tests/hooks/codex-pre-spawn-initiative.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Fixture repo | A git repo with a copy of `.agents/`, a minimal `.workflow/` (rules.md Ownership and Shared core blocks, GLOSSARY.md, model-map entries), an `origin` remote as a bare repo for push and fetch tests | `tests/lib/common.sh` builders, extended under `tests/fixtures/` | all |
| Draft spec at the conversion node | A spec folder with `spec.md` (`draft`), `design-log.md` with a Deeper prompt entry, `codebase-map.md`, `.step` at the conversion node; a shelf item and a work item pointing at it | new fixture builder | JRN-001 |
| Seeded initiative | `initiative.md` and `questions.md` from the templates with S1, S2 and IQ1–IQ3 as JRN-002 states | new fixture builder | JRN-002, JRN-003, JRN-005, JRN-006 |
| Frontmatter oracle | Expected values asserted with `yq --front-matter=extract`; exit codes 0, 1, 2 and the reason text on stderr | the templates' validators and the script usage headers | all |
| Git oracle | `git branch --list`, `git show --name-only`, `git log --merges`, `git show <ref>:<path>` compared against expected lists | git | JRN-001, JRN-003, JRN-004, JRN-005 |
| Hook output oracle | The hook's `additionalContext` text parsed with jq; expected lines for one initiative on a branch, one on main, pending research count | `session-start-resume.sh` output contract | JRN-001, JRN-002, JRN-004 |
| PR command oracle | `open-task-pr.sh --dry-run` prints the gh or glab command it would run; expected head, base and title; no network | `open-task-pr.sh` dry-run contract | JRN-005 |
| Progress line oracle | Expected strings derived from `references/steps.tsv` rows | `steps.tsv` | JRN-007 |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Harness green with the `large` track | errors | exit 0; 0 failed suites in the summary | `tests/run-all.sh` | `spec.md` Constraints (step ids: "`tests/run-all.sh` passes with the `large` track present") and Success signal |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Every script this spec adds or changes has a suite | coverage | `0` printed (no uncovered script) | the `coverage` command below: scripts under `.agents/` added or modified since `baseline_revision` whose file name no file under `tests/` mentions | `.workflow/profiles/test-harness.md` § Mini-review checklist ("A new or changed script has a suite ending in a `shellcheck_files` assertion") |
| Session-start hook wall time | performance | none | not measured: stakeholder decision at 1.1 (no performance target). The required stack has no bash profiler or coverage tool (kcov, bashcov absent), and the hook's 10 s timeout in `.claude/settings.json` is the only ceiling | stakeholder decision, 1.1 (2026-10-22) |

Commands referenced above (pipes keep them out of the table cells); each runs from the project root:

```bash
# script-lint
git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# coverage: prints the count of uncovered scripts; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/001-large-path/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
```

## Suites

<!-- 1.2-1.4. Filled by modules/verification-setup.md. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md), full log [harness.log](artifacts/phase-1-known-bad/harness.log): 93 failures across the 8 new suites and the 2 extended ones, all assertions |
| Browser | none: the project has no e2e work type, every journey is a harness suite (discovered work `no-e2e-work-type`, dismissed 00.25 No, 2026-10-22) | none | none | not applicable; see record.md Run 2 |
