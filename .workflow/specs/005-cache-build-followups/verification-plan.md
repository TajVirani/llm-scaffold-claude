# Verification plan: Cache build follow-ups from spec 003

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-005: Run on the `case` fixture, `extractors/bash.sh` reports no `case` arm pattern as an unresolved call. The fixture covers one-line, multi-line, `(pattern)`, `./x)` and `|`-alternation arms, plus `case ... in` and `esac` lines. Every command after an arm's `)` is still reported (D3).
- [ ] CAP-005: An architecture cache rebuilt for this repo at the feature's HEAD has no `install.sh:133` or `install.sh:187` entry under Unresolved edges. Every other unresolved edge from the cache stamped `e530f63` is still listed, unless its source line changed.
- [ ] CAP-004: With a depcruise stand-in that is not found, one that exits non-zero with empty output, and one that prints JSON without `.summary.violations`, `build-architecture.sh --cache architecture` exits 0. Boundary violations then reads `Not checked: depcruise did not run (not found).`, `... (exited <n> without a JSON report).` or `... (no .summary.violations in its output).` (D2, D9).
- [ ] CAP-004: With a stand-in that returns violations, Boundary violations lists them as before. A `--violations-json` file that does not parse still exits 2 (D9).
- [ ] Shared test-path helper (refactor, goal 3): `budget-check.sh` and `build-architecture.sh` source `.agents/lib/test-paths.sh` and keep no copy of the defaults or the matcher. For the same profiles and paths, both classify every path the same way, and each keeps its own exit code on an invalid `test_patterns` (1 and 2). The entry-candidate JS regex is unchanged (D8).
- [ ] Shared path normaliser (refactor, goal 4): the six scripts (status-transition, budget-check, task-waves, commit-workflow-data, initiative-transition, open-task-pr including `--record`) call `wf_norm_folder` / `wf_main_root` from `.agents/lib/workflow-paths.sh` and keep no copy. For a relative path, an absolute path under the main checkout, a worktree path and a rejected path, each script gives the same result, message and exit code as before. The only exception is that open-task-pr now rejects an absolute path whose parent is not `.workflow/specs` or `.workflow/initiatives` (D4, D5, D10).
- [ ] Agent ownership (refactor, goal 5): `.agents/agents/cache-regeneration.md` contains no `.agents/skills/` path outside `regenerate-caches`. `check-staged-cache.sh` runs the Mermaid validator when node, `mermaid` and `jsdom` are present. Otherwise it reports `not machine-validated` with the checklist path, its stdout `ok` contract and exit codes 0/1/2 stay the same, and P1 is in `proposals.md` (D7).
- [ ] `tests/run-all.sh` passes and shellcheck is clean on every changed shell file. `.agents/install-manifest.txt` lists `lib/test-paths.sh`.

## Journeys

The scaffold has no running application or browser suite. Each journey is an end-to-end run of the real scripts against a fixture repo, checked by a harness suite under `tests/`.

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | `case` patterns are not calls | CAP-005 | 1. Build a fixture repo whose scripts hold every `case` form in End state 1 plus real calls inside arm bodies. 2. Run `extractors/bash.sh --root <fixture> --scope .`. | No pattern text appears in `couldNotResolve` or as a resolved edge; every arm-body call is present. | MISSING (harness case in `tests/scripts/extractor-bash.sh`, built at 1.2-1.3) |
| JRN-002 | This repo's architecture cache drops the false entries | CAP-005 | 1. Run `build-architecture.sh --cache architecture` on this repo's architecture scope at HEAD. 2. Compare Unresolved edges with the oracle. | No `install.sh:133` or `:187`; the remaining entries match the oracle. | MISSING (harness case, built at 1.2-1.3) |
| JRN-003 | depcruise did not run | CAP-004 | 1. Fixture JS project with a boundary config. 2. Run the architecture build with `DEPCRUISE` set to each failing stand-in (not found, exits 3 with no output, JSON without `.summary.violations`). | Exit 0 each time; Boundary violations reads the matching fixed `Not checked: depcruise did not run (...)` line. | MISSING (harness case in `tests/scripts/cache-boundary-check.sh`) |
| JRN-004 | depcruise ran | CAP-004 | 1. Same fixture. 2. Run with a stand-in that returns violations. 3. Run with `--violations-json` pointing at a file that is not JSON. | Step 2 lists the violations; step 3 exits 2. | MISSING (harness case in `tests/scripts/cache-boundary-check.sh`) |
| JRN-005 | Budget and flows agree on test files | goal 3 | 1. Fixture repo with profiles setting `test_patterns` (a list, `[]`, absent, an invalid value) and files matching each matcher rule. 2. Run `budget-check.sh` and `build-architecture.sh --cache entries`. | The same paths count as tests in both; the invalid value exits 1 and 2 with each script's message; no copy of the defaults outside `.agents/lib/test-paths.sh` (grep). | MISSING (harness cases in `tests/scripts/budget-check.sh`, `tests/scripts/build-architecture.sh`) |
| JRN-006 | Folder paths validate the same everywhere | goal 4 | 1. For each of the six scripts, pass a relative spec or initiative path, an absolute main-checkout path, a path from a worktree, a bare `NNN-slug`, and an absolute path elsewhere. | Accept and reject results, messages and exit codes match the pre-change behaviour, except that open-task-pr (spec dir and `--record`) now rejects the absolute path elsewhere. | MISSING (harness cases in the existing per-script suites and a lib case) |
| JRN-007 | Cache-regeneration stays inside its ownership | goal 5 | 1. Grep `cache-regeneration.md` for `.agents/skills/` paths. 2. Run `check-staged-cache.sh flows <staged>` with node or the packages absent, and with a stand-in validator present. | Only regenerate-caches paths remain; `ok` and exit 0 on a valid body in both runs; the not-validated run prints the checklist path on stderr. | MISSING (harness case in `tests/scripts/cache-scripts.sh`) |
| JRN-008 | Caches published after the change | CAP-004, CAP-005 | 1. After the last wave, run the regenerate-caches skill for this repo. | `check-staged-cache.sh` prints `ok` for all three caches; the published architecture cache passes JRN-002's oracle. | MISSING (run by hand at 5.x, evidence under `artifacts/`) |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| `case` forms fixture | Scripts with one-line, multi-line, `(pattern)`, `./x)` and alternation arms, `case`/`esac` lines, and real calls inside arm bodies | Written in the harness from the forms in codebase-map Module audit (regenerate-caches constraints) | JRN-001 |
| Unresolved-edges oracle | Unresolved edges list from `.workflow/cache/architecture.md` stamped `e530f63`, minus `install.sh:133` and `install.sh:187` | The published cache at the spec's baseline; entries whose source line changed in this feature are re-derived by hand and noted | JRN-002, JRN-008 |
| depcruise stand-ins | Executables for `DEPCRUISE`: missing path, exit 3 with no output, JSON without `.summary.violations`, JSON with violations | Harness-written scripts; the existing answering stand-in in `tests/scripts/cache-boundary-check.sh` is the model | JRN-003, JRN-004 |
| Test-pattern profiles fixture | Profiles with `test_patterns` as a list, `[]`, absent, empty Toolchain block, invalid value; files hitting each matcher rule | Harness-written; expected classification computed from the rules in codebase-map Module audit (feature-workflow constraints) | JRN-005 |
| Pre-change normaliser behaviour | Accept/reject result, message and exit code per script and input | Recorded by running the six scripts at `baseline_revision` before Phase 3 | JRN-006 |
| Mermaid validator stand-in | A `node` on PATH plus stub `node_modules/mermaid` and `jsdom`, and an environment without them | Harness-written | JRN-007 |

## Targets

<!-- 1.1. -->

## Suites

<!-- 1.2-1.4. -->
