---
cache_stamps:
  modules: e530f63f7103b9286d32d21f6b9f75055ef8c5d8
  flows: e530f63f7103b9286d32d21f6b9f75055ef8c5d8
  architecture: e530f63f7103b9286d32d21f6b9f75055ef8c5d8
---

# Codebase map: Cache build follow-ups from spec 003

Affected area: lib (`.agents/lib`), feature-workflow (`.agents/skills/feature-workflow`), regenerate-caches (`.agents/skills/regenerate-caches`), agents (`.agents/agents`), tests (`tests`).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| budget-check.sh default test patterns | Hard-coded list: `*.test.*`, `*.spec.*`, `__tests__/`, `tests/`, `test/`, `e2e/`, `*_test.go`, `test_*.py`, `*_test.py` | `.agents/skills/feature-workflow/scripts/budget-check.sh:60-68` |
| budget-check.sh pattern loading | Reads each profile's Toolchain `test_patterns`; a profile with no key or `[]` contributes the defaults; result is sorted and unique | `.agents/skills/feature-workflow/scripts/budget-check.sh:143-153` |
| budget-check.sh matcher | Pattern ending in `/` matches a folder at any depth; pattern with another `/` matches the whole repo path (glob); other patterns match the file basename (glob) | `.agents/skills/feature-workflow/scripts/budget-check.sh:155-170` |
| budget-check.sh test exclusion | Tests are dropped from the changed-file count (`test_files`, `excluded.tests`) | `.agents/skills/feature-workflow/scripts/budget-check.sh:338-340` |
| build-architecture.sh default test patterns | Second copy of the same nine defaults, with a comment that it must match the budget step | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:530-539` |
| build-architecture.sh `test_patterns()` | Same profile loop as budget-check; dies when a profile's `test_patterns` is not a list of non-empty strings | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:543-562` |
| build-architecture.sh `is_test_file()` | Same three matching rules as budget-check `is_test_path` | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:564-580` |
| build-architecture.sh entry candidates | Test filter is the pattern list above plus a hard-coded JS regex (`__tests__`/`__mocks__`, `.test.`/`.spec.`, `.d.ts`) | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:582-607` (regex at :604) |
| bash extractor, split on `\|` | Command splitting treats `\|`, `&&`, `\|\|`, `;`, `&` and backtick as separators, so a case pattern `a \| ../* \| b)` becomes several "commands" | `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:319-334` (split at :326) |
| bash extractor, cwd-relative call rule | Any command word starting `./` or `../` followed by a non-slash is reported as an unresolved call; a case arm `../*)` loses its `)` and matches | `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:341-360` (rule at :350; `add_edge(script, 0)` at :358) |
| bash extractor, bare-path rule | A word closed by `)` is skipped as a case pattern unless the command opened with `(` | `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:390-407` (skip at :403) |
| bash extractor, case example in this repo | `install.sh` case arm `/* \| ../* \| */../* \| */.. \| ..)` reaches the cache as an unresolved edge | `install.sh:133`; `.workflow/cache/architecture.md` § Unresolved edges (lines 96-97) |
| Boundary violations render | Calls `render_boundary_violations`, after Edges and before Unresolved edges | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:366-368` |
| Boundary violations, no checker | If no selected extractor is `dependency-cruiser`, prints `Not checked: no boundary checker for this project's graph extractors (<names>).` and returns before any config check | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:380-383` (set at :302-306) |
| Boundary violations, depcruise path | Config is `.workflow/tools/boundaries/dependency-cruiser.cjs`; depcruise runs with `\|\| true`, so its exit status is ignored | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:384-389` (run at :388) |
| Boundary violations, parse | Reads `.summary.violations`; dies when the key is missing; an empty list prints `None.` | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:394-397` |
| Module roots for the boundary check | Default module roots are read from the Ownership and shared core blocks through generate-boundary-config.sh | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:231-244` |
| Boundary config file | Present in the repo, but not read in the bash-only run (see the no-checker branch above) | `.workflow/tools/boundaries/dependency-cruiser.cjs` |
| cache-regeneration agent, skill references | Sets `S=.agents/skills/regenerate-caches/scripts` and calls `$S/build-architecture.sh` and `$S/check-staged-cache.sh` | `.agents/agents/cache-regeneration.md:36, 41, 49, 63, 77` |
| cache-regeneration agent, visual-change-report references | Runs `.agents/skills/visual-change-report/scripts/validate_mermaid.mjs` and cites `.agents/skills/visual-change-report/references/visual-library.md` "Mermaid syntax rules" | `.agents/agents/cache-regeneration.md:85, 88` |
| cache-regeneration agent, rules read | Says the build script reads the Ownership block of rules.md for module roots | `.agents/agents/cache-regeneration.md:28` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `build-architecture.sh --cache architecture\|modules\|entries --scope PATH ... [--violations-json FILE]` | Stdout or `--out`; violations JSON must hold `.summary.violations` | cache-regeneration agent; regenerate-caches | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:1-56` |
| `build-architecture.sh --print-generator` | Prints sorted, comma-joined names of selected extractors (`none` left out) | cache-regeneration agent (`generator:` line); publish-cache.sh | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:198-202`; `.agents/agents/cache-regeneration.md:44` |
| `extractors/<name>.sh --root DIR --scope PATH...` | Prints dependency-cruiser-shaped JSON (`modules[].source`, `dependencies[].resolved` or `couldNotResolve`, `line`) | build-architecture.sh `run_extractors` | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:262-283`; `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:19` |
| `budget-check.sh --spec-dir DIR [--cwd DIR] [--predicted]` | One JSON object; exit 0 within budget, 2 over | task-breakdown (2.6), implementation-orchestrator (3.15) | `.agents/skills/feature-workflow/scripts/budget-check.sh:7-47` |
| Profile Toolchain keys `test_patterns`, `graph_extractor` | YAML keys inside the Toolchain fence; both budget-check and build-architecture read `test_patterns`. Values: test-harness `["tests/"]`, shell-scripts `["tests/"]`, agent-docs `[]` (from a grep, not the full files) | both scripts above | `.agents/skills/feature-workflow/scripts/budget-check.sh:34-38`; `.agents/skills/regenerate-caches/scripts/build-architecture.sh:541-542` |
| `.agents/lib/` | Shared core; every module may use it; changes only through the integration agent | all modules | `.workflow/rules.md:99-110` |
| `workflow-paths.sh` (sourced) | `WF_*` repo-relative constants and `wf_path`; no side effects, no error modes, builtins only | all hooks, feature-workflow, data-structure-audit and regenerate-caches scripts; tests | `.agents/lib/workflow-paths.sh:1-49` |
| `wf_path <root> <rel>` | Prints `<root without trailing slash>/<rel>`; always status 0 | commit-workflow-data.sh; tests | `.agents/lib/workflow-paths.sh:46-49` |
| `status-transition.sh <mode> <spec-dir> ... [--cwd]` | Exit 0 ok, 1 usage/env (bad spec dir, not a repo), 2 illegal transition | phase modules | `.agents/skills/feature-workflow/scripts/status-transition.sh:4-12,78,225-226` |
| `initiative-transition.sh <mode> <initiative-dir> ... [--cwd]` | Exit 1 bad dir or env; 2 only from illegal; checks the folder exists after normalising | large-path module; open-task-pr `--record` | `.agents/skills/feature-workflow/scripts/initiative-transition.sh:9-23,69-71,228-234` |
| `task-waves.sh --spec-dir DIR [--cwd] [--json] \| --tasks-file F` | Exit 0 ok, 2 invalid graph, 1 usage/env; `--tasks-file` needs no git | task-breakdown 2.5, orchestrator | `.agents/skills/feature-workflow/scripts/task-waves.sh:7-13,41-42,95-99` |
| `commit-workflow-data.sh <spec-dir> -m MSG [--cwd]` | Exit 0 committed or nothing; 1 refused; 2 usage/env incl. bad spec dir | orchestrator wave start, 3.16 | `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh:12-20,79-80` |
| `open-task-pr.sh` task and generic modes | Usage errors exit 1 in task mode, 2 in generic mode | orchestrator 3.16; large-path 6.11/6.13 | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:11-34,97-136` |
| `render_boundary_violations` (fn) | Order: `--violations-json`, no-checker message, config + depcruise run, no-config message; parses `.summary.violations` or prints `None.`; dies when tool or JSON missing | `render_architecture` | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:366-368,376-398` |
| `check-staged-cache.sh <modules\|flows\|architecture> <file> [--html-out FILE]` | `ok` on stdout exit 0; problems on stderr exit 1; usage exit 2; Mermaid only in architecture and flows | regenerate-caches SKILL step 5; cache-regeneration agent | `.agents/skills/regenerate-caches/scripts/check-staged-cache.sh:12-15,83-85,121`; `SKILL.md:117` |
| `extract_awk` record stream | `M <file>`, `E <file> <line> <resolved\|""> <text>`, `F <file> <fn>`; `add_edge(token, anchored)` is the single output point | `graph_jq` | `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:74-75,411-415,420-438` |
| depcruise (boundary run) | npm CLI under node; located through `tool_cmd`; replaceable by `DEPCRUISE=` or `--violations-json` | `render_boundary_violations` | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:386-388` |
| validate_mermaid.mjs | visual-change-report (standalone-skills) file run under node with mermaid and jsdom; named only in comments and docs today; a `.mjs` call is not drawn as a bash edge | check-staged-cache.sh (planned) | `.agents/skills/regenerate-caches/scripts/check-staged-cache.sh:4-6`; `assets/cache-frontmatter.md:178`; `extractors/bash.sh:301-313` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0003 Graph extractor per profile (accepted) | Each work profile names `graph_extractor` (`bash`, `dependency-cruiser`, `none`); a profile without the key is an error. Unresolved paths are reported as `couldNotResolve`, never guessed as edges. | `.workflow/decisions/adr/0003-graph-extractor-per-profile.md` § Decision; § Consequences |
| Pitfall: report a detected call as unresolved; never filter it out | The bash extractor once dropped detected script calls through filters; prevention is call-form cases in `tests/scripts/extractor-bash.sh`. | `.workflow/decisions/pitfalls.md` § "Report a detected call as unresolved; never filter it out" (lines 35-39) |
| Retrospective 003, F1 duplicate test patterns | Accepted; started as a follow-up spec at 5.9. | `.workflow/decisions/retrospectives/003-bash-cache-extractor.md` findings table (line 44) |
| Retrospective 003, `case` patterns read as calls | Accepted; still present in the published architecture cache. | same file, line 45 |
| Retrospective 003, failed depcruise run renders `None.` | Accepted; its line numbers (`build-architecture.sh:248-254,375,381-384`) have drifted to :366-398. | same file, line 46 |
| Retrospective 003, agents module depends on forbidden skills (F8) | Accepted; cites `cache-regeneration.md:36,85,88`. | same file, line 47 |
| Retrospective 003, Mermaid not machine-validated | Accepted: the repo has no node toolchain, so Mermaid checks are by hand. | same file, line 49 |
| Retrospective 003, Non-goals | No bash boundary checker, no other extractors, no install.sh change were in scope for spec 003. | same file, line 28 |
| Ownership, module `agents` | `owns: [".agents/agents/**"]`, `may_depend_on: [feature-workflow]`; a script call or `skills/<name>/` path reference counts as a dependency. | `.workflow/rules.md` § Ownership (line 6; yaml lines 79-81) |
| Ownership, `regenerate-caches` and `standalone-skills` | regenerate-caches may depend on `[lib, project-setup, feature-workflow, standalone-skills]`; standalone-skills (incl. visual-change-report) may depend on nothing. Neither is in `agents` `may_depend_on`. | `.workflow/rules.md` yaml lines 48-50, 69-78 |
| Ownership, module `tests` | May depend on regenerate-caches and standalone-skills, among others. | `.workflow/rules.md` yaml lines 91-93 |
| Ownership: no boundary tool here | "No boundary tool runs here (dependency-cruiser cannot read bash)"; placement steered at 0.3.3, review at 4.1. | `.workflow/rules.md` § Ownership (line 6) |
| Shared core | `.agents/lib/**`; every module may depend on it; changes only through the integration agent. | `.workflow/rules.md` § Shared core (lines 101-109) |
| CAP-004 | Graph extractor per work profile, `graph_extractor` required. | `.workflow/capabilities.md` line 16 |
| CAP-005 | Bash graph extractor: file graph from `source`/`.` lines and script calls; unresolved calls under Unresolved edges. | `.workflow/capabilities.md` line 17 |
| Architecture cache, Boundary violations | Reads `Not checked: no boundary checker for this project's graph extractors (bash).`; matches the code. | `.workflow/cache/architecture.md` § Boundary violations (line 89) |
| Architecture cache, Unresolved edges | Lists `install.sh:133` and `install.sh:187` as `../*`, which are case patterns. | `.workflow/cache/architecture.md` § Unresolved edges (lines 96-97) |
| Deferred: shared-path-normaliser | One shared helper for workflow-folder path normalising, replacing per-script copies (`budget-check.sh:78-98`). Shelved because it changes a shared convention and touches shared core. | `.workflow/deferred/shared-path-normaliser.md` § Summary, § Background, § Locations |

## Library options

Concerns: (1) glob matching of repo paths against test-file patterns in bash 3.2; (2) parsing bash `case` in the bash graph extractor; (3) detecting whether dependency-cruiser ran versus found violations. Settled by rules: none. `.workflow/rules.md` "External systems" (line 149) is an empty heading. The only rules that apply are the required versions (rules.md:153-156: bash 3.2, no bash 4 constructs, git and jq any version, yq v4, shellcheck for lint only). No package.json, lockfile or Cargo/go.mod exists in the repo, so there is no JS or Go dependency manifest.

### Already in the project

- bash 3.2 builtins (`case`, `[[ == ]]`): no package; covers glob matching and case parsing for shell. Touchpoints: `.agents/skills/regenerate-caches/scripts/build-architecture.sh:531-543` (DEFAULT_TEST_PATTERNS, test_patterns()); `.agents/hooks/evidence-capture.sh:105,112` (case glob use).
- awk case-aware parser in the bash extractor: `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:319-334` (split_commands) and `:396-407` (report_bare_relative_calls, which skips `)`-terminated case patterns). Requires git, awk, jq only (bash.sh:23).
- dependency-cruiser@18.7.0 (npm, MIT): `.agents/skills/regenerate-caches/scripts/extractors/dependency-cruiser.sh:35-52` (runs `$DEPCRUISE`, `node_modules/.bin/depcruise` or `npx --no-install depcruise`); `.workflow/tools/boundaries/dependency-cruiser.cjs:1-3` (generated config); `README.md:76` (node and dependency-cruiser named as required for the architecture cache).

### 1. Glob matching of repo paths against test-file patterns

Verdict: Use existing (bash `case` / `[[ == ]]`). Build in-house is the only option that runs on bash 3.2 without a new runtime.
Deprecation check: not applicable (no external API). bash 3.2 has no globstar, so `**` acts as `*`. In `case`, `*` also crosses `/`, so `*.test.*` matches nested paths. Not confirmed by a 3.2 run.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| bash `case` (incumbent) | pass: builtin on 3.2; `**` not recursive, `*` crosses `/` | pass: bash GPL-3.0 is not linked or shipped; no new dependency | pass: platform builtin | pass: no third-party code | pass: 0 kB; ~0.5 day to add a fixture test |
| picomatch / minimatch (npm, JS) | caution: needs node at run time, which the bash-only extractor does not require | pass: MIT (not verified via deps.dev) | unknown | unknown | fail: new runtime for a 3-line check |

Evidence: https://www.gnu.org/software/bash/manual/bash.html (not fetched); https://mail.gnu.org/archive/html/bug-bash/2012-03/msg00207.html (globstar is bash 4); https://git.gitlab.arm.com/bazel/toolchain_utils/-/merge_requests/35 (3.2 lacks some syntax).
Risks: a pattern like `tests/**` would silently match only one level on macOS 3.2. Verdict changes only if a glob rule must match `**` recursively; then use `find` or an explicit depth.
Unverified: exact `case` behaviour of `*` across `/` under 3.2 (only bash 4+ docs were read).

### 2. Parsing bash `case` in the graph extractor

Verdict: Use existing (the awk parser in bash.sh). Hold any new parser until a fixture shows a case form that awk misses.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| awk parser in bash.sh (incumbent) | pass: already skips case patterns (bash.sh:403); heuristics, not a grammar | pass: first-party | pass: in repo | pass: no third-party code | pass: 0 new deps; ongoing edge-case upkeep |
| tree-sitter-bash@0.25.1 (npm, MIT) | caution: needs node and native bindings; required versions do not list node | pass: MIT (deps.dev) | caution: last release 2025-12-02 | pass: no advisories listed | fail: adds node to the bash-only extractor; ~2-3 days |
| mvdan.cc/sh/v3 (shfmt library, Go) | caution: would add a Go binary or module; CLI JSON AST output unverified | pass: BSD-3-Clause | pass: pseudo-versions published 2026-10-25 | unknown | caution: new binary to install; ~2-4 days |

Evidence: https://api.deps.dev/v3/systems/npm/packages/tree-sitter-bash ; https://api.deps.dev/v3/systems/npm/packages/tree-sitter-bash/versions/0.25.1 ; https://api.deps.dev/v3/systems/go/packages/mvdan.cc%2Fsh%2Fv3 ; https://raw.githubusercontent.com/mvdan/sh/master/LICENSE ; https://raw.githubusercontent.com/koalaman/shellcheck/master/LICENSE (lint only).
Deprecation check: no bash-grammar notice for tree-sitter-bash; none found for mvdan/sh (not searched separately).
Risks: awk parsing of multi-line case arms can miss a pattern; if fixtures show that, adopt mvdan/sh as Trial, not tree-sitter.
Unverified: whether mvdan/sh's CLI emits an AST as JSON; mvdan/sh Scorecard.

### 3. Detecting whether dependency-cruiser ran versus found violations

Verdict: Use existing depcruise (18.7.0) for the run. Detection is in-house: read the JSON on stdout and its `summary` fields, not the exit code alone.
Deprecation check: none found. 18.0.0-beta dropped Node 20 and 25; current engines are `^22||^24||>=26`, which rules.md does not state.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| dependency-cruiser@18.7.0 (incumbent) | pass: `--no-config`, `--ts-config`, `-T json` used at dependency-cruiser.sh:51 | pass: MIT | pass: 18.7.0 published 2026-10-19; single main maintainer (bus factor) | unknown: no advisories listed; Scorecard not retrieved | caution: 18 runtime deps; needs node ^22/^24/>=26 |
| Exit-code-only detection (in-house) | caution: depcruise exits with the error-violation count; npx's "not installed" exit is also non-zero | n/a | n/a | n/a | pass: no code |
| JSON-parse detection (in-house, recommended) | pass: `summary` with `totalCruised`, `error`, `violations` | n/a | n/a | n/a | pass: jq is already required; ~0.5 day |

Evidence: https://api.deps.dev/v3/systems/npm/packages/dependency-cruiser ; https://api.deps.dev/v3/systems/npm/packages/dependency-cruiser/versions/18.7.0 ; https://raw.githubusercontent.com/sverweij/dependency-cruiser/main/LICENSE ; https://raw.githubusercontent.com/sverweij/dependency-cruiser/main/package.json ; https://raw.githubusercontent.com/sverweij/dependency-cruiser/main/doc/cli.md ; https://raw.githubusercontent.com/sverweij/dependency-cruiser/main/doc/output-format.md ; https://github.com/sverweij/dependency-cruiser/releases/tag/v16.0.0
Risks: `summary` was confirmed only from a sample, not a `--no-config` run; if absent, detection needs a sentinel (the `modules` count). A depcruise major bump could break the run.
Unverified: `summary` presence under `--no-config`; Scorecard; `npx --no-install` exit codes across npm versions; node-version constraint is not in rules.md.

## Module audit

The change spans four modules (design-log 2026-10-26 Placement (0.3.4)); one audit per module with code changes. agents is a one-file doc change and was not audited.

### lib

Owning module: lib

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | `WF_SPECS`, `WF_INITIATIVES` are the roots `wf_norm_folder` matches; `WF_PROFILES` is the root the test-pattern loader globs. | `.agents/lib/workflow-paths.sh:25-27` |
| reuse | `wf_path`'s `${1%/}` idiom is the existing trailing-slash strip. | `.agents/lib/workflow-paths.sh:46-49` |
| reuse | Header block (File / Purpose / Usage / API / Sources) with the `cd -P` source lines is the file convention a new `test-paths.sh` follows. | `.agents/lib/workflow-paths.sh:1-16` |
| reuse | Lib checks use `lib_eval` (source in a clean `bash -c`) and shellcheck; the installed-copy check sources the installed lib and calls `wf_path`. | `tests/hooks/write-guards.sh:239-248`; `tests/scripts/install-payload.sh:78-79` |
| gap | No main-checkout helper; `wf_main_root` would be the first lib code to call git. | `.agents/lib/workflow-paths.sh:46-49` |
| gap | No lib function returns non-zero or reports an error; no convention for where the message goes. The new helpers set it. | `.agents/lib/workflow-paths.sh:46-49` |
| gap | No test-pattern code, YAML reading or glob matcher; no lib test suite, and nothing tests a lib error path. | `.agents/lib/`; `tests/hooks/write-guards.sh:239-248` |
| constraint | Sourced, not executable: no `set` options, no `exit`, no work when sourced; guard every expansion for callers with `set -u`; use `local`. | `.agents/lib/workflow-paths.sh:2,19-49` |
| constraint | `# shellcheck disable=SC2034` is file-wide in workflow-paths.sh; a new `test-paths.sh` does not inherit it. | `.agents/lib/workflow-paths.sh:17` |
| constraint | API paths are repo-relative with no trailing slash; write guards compare them case-insensitively. | `.agents/lib/workflow-paths.sh:12,15` |
| constraint | A lib file that sources another lib file resolves its own directory with `cd -P` (skills reach lib through a symlink). | `.agents/lib/workflow-paths.sh:7-9` |
| constraint | Every lib file is listed by hand in the install manifest; `test-paths.sh` needs an entry or it never reaches target projects. | `.agents/install-manifest.txt:36-37` |
| constraint | Tests pin `WF_SPECS`, `WF_INITIATIVES`, `WF_REVIEW_LESSONS`, `wf_path` and a shellcheck-clean lib. Fourteen scripts source workflow-paths.sh, so new names must not clash with callers' functions. | `tests/hooks/write-guards.sh:242-248`; `.agents/hooks/_guard-common.sh:53` |

### feature-workflow

Owning module: feature-workflow

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | All six target scripts already source workflow-paths.sh. | `.agents/skills/feature-workflow/scripts/status-transition.sh:86`, `budget-check.sh:55`, `task-waves.sh:51`, `commit-workflow-data.sh:28`, `initiative-transition.sh:60`, `open-task-pr.sh:44` |
| reuse | check-write's `main_root` returns a status and the caller supplies the message (`\|\| die ...`): the pattern the helpers follow. | `.agents/skills/feature-workflow/scripts/check-write.sh:141-149,253` |
| reuse | Every script has its own `die` with a per-script exit code (commit-workflow-data `${2:-2}`). | `status-transition.sh:92`, `task-waves.sh:54`, `commit-workflow-data.sh:32`, `initiative-transition.sh:69`, `open-task-pr.sh:48` |
| reuse | The four full spec copies are byte-equivalent (git-common-dir, worktree-list fallback, strip `/` and `./`, absolute path mapped only if parent ends in `/$WF_SPECS`, slug regex); the initiative copy differs only in `$WF_INITIATIVES`. | `status-transition.sh:122-145`, `budget-check.sh:78-100`, `task-waves.sh:60-76`, `commit-workflow-data.sh:36-59`, `initiative-transition.sh:104-127` |
| constraint | Exit codes on a bad folder or not-a-repo stay per script: 1 for status-transition, task-waves, initiative-transition, budget-check, open-task-pr task mode; 2 for commit-workflow-data and open-task-pr generic mode (`generic_usage` also prints usage). | `commit-workflow-data.sh:17-20,32`; `open-task-pr.sh:31-34,111,121-123` |
| constraint | Error texts stay: `spec dir must be $WF_SPECS/NNN-slug: <arg>`, `initiative dir must be $WF_INITIATIVES/NNN-slug: <arg>`, `--record must be $WF_INITIATIVES/NNN-slug: <arg>`, `not inside a git repository: <dir>`. | `status-transition.sh:141-144`, `initiative-transition.sh:121-125`, `open-task-pr.sh:111,122,134` |
| constraint | open-task-pr runs `set -uo pipefail` without `-e`: every helper call needs an explicit `\|\| die`. The other five use `set -euo pipefail`; task-waves embeds the call in a string (`TASKS_FILE=...`) and must split it out; `--tasks-file` mode must stay git-free. | `open-task-pr.sh:41`; `task-waves.sh:97-98` |
| constraint | budget-check checks jq and yq v4 before loading anything; its loader errors are exit-1 `die` calls prefixed `budget-check.sh:`, documented in the header and the orchestrator module. | `budget-check.sh:46,205-207,135-140,249`; `modules/implementation-orchestrator.md:224` |
| constraint | Test-pattern rules to keep: missing/empty Toolchain block contributes nothing; TEMPLATE.md skipped; absent or `[]` gives defaults; non-seq or non-string/empty items die; `sed '/^$/d' \| LC_ALL=C sort -u`; no profiles gives defaults. Output feeds `test_files`, `excluded.tests` and `--predicted`. | `budget-check.sh:126-170,249,262,339` |
| constraint | Header comments and Sources lines describe the copied code and must stay accurate. | `budget-check.sh:34-38,50`; `commit-workflow-data.sh:23` |
| constraint | The six copies resolve the root with plain `dirname`, check-write with `cd -P`; changing the form changes paths printed in messages. | `check-write.sh:145`; `status-transition.sh:126,238` |
| gap | open-task-pr does no parent-folder check on absolute paths, in both the spec-dir and the `--record` normalising. | `open-task-pr.sh:117-123,131-134` |
| gap | The module has no tests of its own; message and exit-code pins live in `tests/`, not audited. | `.agents/skills/feature-workflow/` |

### regenerate-caches

Owning module: regenerate-caches

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Skill-to-lib source form (`# shellcheck source=...` plus `cd -P` path); the bash extractor already resolves it as an edge to lib. | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:60-61`; `extractors/bash.sh:84,211-217` |
| reuse | `toolchain_block` is also used by `profile_extractors`, so it stays in build-architecture.sh. | `build-architecture.sh:143-150,161,549` |
| reuse | `tool_cmd ENVVAR NAME` (env var, `node_modules/.bin`, `npx --no-install`) is the existing tool-presence pattern. | `build-architecture.sh:250-257` |
| reuse | `mermaid_blocks` and the `--html-out` wrapper already build the HTML validate_mermaid.mjs reads. | `scripts/check-staged-cache.sh:72,140-150` |
| reuse | `unquoted_code` is a quote-aware scanner carrying open quotes across lines; per-file state resets at `FNR == 1`; the `\036` marker tells a `(`-opened command from a case-pattern `)`. | `extractors/bash.sh:88-96,324-328,365-388` |
| gap | `test_patterns()` relies on build-architecture's `die`, `$root`, `$WF_PROFILES`, `toolchain_block` and `\|\| exit 2`; a lib cannot rely on any of these. | `build-architecture.sh:543-562,584` |
| gap | Dropping `__tests__`, `.test.`, `.spec.` from the regex: when every profile sets its own `test_patterns`, defaults never apply, so `foo.test.ts` outside `tests/` becomes an entry candidate. | `build-architecture.sh:553-558,604` |
| gap | Boundary failure paths exit 2 today (tool not found; no `.summary.violations`); stderr goes to `/dev/null` and the exit status is dropped, so no `<reason>` survives. Behaviour for an unparseable `--violations-json`, or `.summary` without `.violations`, is undecided. | `build-architecture.sh:379-380,386-396` |
| gap | With `--from-json`, depcruise runs whenever the config exists, which it does in this repo, so `--from-json` tests hit the depcruise path. | `build-architecture.sh:286-292,384` |
| gap | check-staged-cache.sh has no root resolution, so it cannot find the sibling skill's validator or `node_modules/{mermaid,jsdom}`; no node/package detection. | `check-staged-cache.sh:16-35,140` |
| gap | `report_cwd_relative_calls` has no case-pattern skip; the anchored-token loop also scans pattern text (`"$d"/*.sh)` yields `$d/*.sh`); `\|` splitting makes each alternative a command, `;;` gives empty ones. | `extractors/bash.sh:144-157,326,341-360` |
| constraint | Never filter a detected call: only the pattern list may be skipped; commands after `)` on the same line are still scanned. | `extractors/bash.sh:5-12,340`; `build-architecture.sh:459-466` |
| constraint | `unquoted_code` mutates global quote state; calling it twice per line advances it twice. Case skipping must agree across the assignment, source, token-loop, cwd and bare scanners, each with its own preprocessing. | `extractors/bash.sh:100-107,121-160,365-368` |
| constraint | The module's own scripts use one-line `case ... in a\|b) ;; *) ... ;; esac`, multi-arm blocks and `case` inside `while`. | `build-architecture.sh:85-99,103,459-467`; `check-staged-cache.sh:33,43-47` |
| constraint | Extractor JSON shape and sort order fixed; cache body deterministic under `LC_ALL=C`. A `<reason>` from depcruise stderr could carry machine-specific paths. | `extractors/bash.sh:19-20,418-438`; `build-architecture.sh:52-53,62,561` |
| constraint | build-architecture.sh documents exit 2 for unparseable JSON and two `Not checked:` strings; check-staged-cache prints `ok` on stdout, problems on stderr, exits 0/1/2, and SKILL step 5 publishes only on `ok`. | `build-architecture.sh:44-48,54-56`; `check-staged-cache.sh:14-15,152-156`; `SKILL.md:121` |
| constraint | Docs that change with the behaviour: Boundary violations wording and Mermaid validation text in cache-frontmatter.md; entries test-filter description in build-architecture.sh. | `assets/cache-frontmatter.md:112,176-178`; `build-architecture.sh:6-7,40-41,530` |
| constraint | `test_patterns` needs yq only when a profile exists, so defaults print without yq. | `build-architecture.sh:548,561` |

Friction: each bash.sh line passes five scanners with their own preprocessing, and existing case awareness lives in one; build-architecture.sh mixes boundary rendering with tool lookup and exit policy. History: build-architecture.sh 11 commits, bash.sh 9 (recent call-detection fixes), check-staged-cache.sh 3; initiative-transition.sh 8, open-task-pr.sh 4.

## Not found

- Deferred items matching the test-pattern defaults or matcher, the `case` pattern bug or the depcruise failure path: all 11 non-archive files in `.workflow/deferred/`. Reported by retrieval.
- `.workflow/deferred/archive/boundary-check-wording.md` is archived, so not a shelf match; its subject is the wording architecture.md line 89 now has. Reported by retrieval.
- Retrospective 003 row F1 names the follow-up spec `005-shared-test-patterns`; this spec is `005-cache-build-followups` (renamed when the four items were combined). Reported by retrieval.
- Code and cache disagreement: none in architecture § Boundary violations and § Unresolved edges; modules.md and flows.md bodies were not checked. Reported by retrieval.
- Existing glob matcher, test-pattern list, YAML reader, folder normaliser, error convention or `set` options in lib: `.agents/lib/**`. Reported by module-audit (lib).
- Existing case/esac state in the extractor; node, mermaid or jsdom detection in module scripts; capture of depcruise stderr or exit status in the boundary path: `.agents/skills/regenerate-caches/scripts/**`. Reported by module-audit (regenerate-caches).
- Other test-pattern copies: only budget-check.sh and build-architecture.sh (task-breakdown.md:109 describes them in prose). Reported by module-audit (feature-workflow, regenerate-caches).
- Tests pinning the normaliser messages and exit codes: none inside feature-workflow; they live in `tests/`, not audited. Reported by module-audit (feature-workflow).
- Line-range drift in this map (not a cache problem; the rows came from retrieval and the shelf item): budget-check `norm_spec_dir` ends at :100, not :98; `profile_test_patterns` starts at :126, not :143. The module audit tables above carry the current ranges. Reported by module-audit (feature-workflow).
