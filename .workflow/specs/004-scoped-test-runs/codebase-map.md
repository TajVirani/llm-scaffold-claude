---
cache_stamps:            # generated_at_commit of each .workflow/cache/ file the extracts were drawn from; null when that cache was not read
  modules: null
  flows: null
  architecture: null
---

# Codebase map: Scoped test runs for the harness profiles

Affected area: tests (`tests/`, chiefly `tests/run-all.sh`, `tests/lib/common.sh`); work profiles `.workflow/profiles/shell-scripts.md`, `test-harness.md`, `agent-docs.md` (Toolchain block, via a 5.3 proposal); caller `.agents/skills/feature-workflow/scripts/run-toolchain.sh` (read only).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Test runner entry | Discovers suites with a glob over `tests/scripts/*.sh`, `tests/hooks/*.sh`, `tests/lint/*.sh`. `--suite NAME` selects a whole suite by basename or label; there is no per-test selection. Preflight and shellcheck presence are required. | `tests/run-all.sh:39`, `:53`, `:62-66`, usage `:4-7` |
| Shared helpers | `t`, `eq`, `check`, `skip`, `xfail` (known defect; fails once it starts passing), `finish`, `new_workdir`, `copy_agents`. Fixture repo helpers `git_init_repo`, `make_fixture_repo`. | `tests/lib/common.sh:37-48`, `:70-74`, `:110-122`, `:125-143` |
| Toolchain test key (all three profiles) | `test` is `tests/run-all.sh`. `shell-scripts` and `test-harness` set `lint` to shellcheck; `agent-docs` sets `lint` to four `run-all.sh --suite lint/...` calls. | `.workflow/profiles/shell-scripts.md:34,38`; `.workflow/profiles/test-harness.md:24,28`; `.workflow/profiles/agent-docs.md:29,33` |
| `test_scoped` in this repo's profiles | Empty string in all three profiles, so a failing `test` becomes `unscoped` whenever excluded selectors exist. | `.workflow/profiles/shell-scripts.md:39`; `.workflow/profiles/test-harness.md:29`; `.workflow/profiles/agent-docs.md:34` |
| `test_scoped` examples | The shipped test-harness example is a vitest command; the e2e-browser example uses playwright `--grep-invert`. Neither fits this repo's bash harness. | `.agents/skills/project-setup/assets/profiles/examples/test-harness.md:48`; `.agents/skills/project-setup/assets/profiles/examples/e2e-browser.md:99` |
| Profile template | Documents `test_scoped` as optional, with the env vars and the `unscoped` fallback. | `.agents/skills/project-setup/assets/profiles/TEMPLATE.md:30` |
| Run-toolchain flags | `--exclude-unfinished` for a gate run whose task id is not a record; `--skip` accepts `test`; `--e2e` adds the e2e key. | `.agents/skills/feature-workflow/scripts/run-toolchain.sh:18-21`, `:55-69` |
| Excluded-set computation | With a record id, or with `--exclude-unfinished`, the excluded set is the `tests` of every other record not `done`. Own set is the record's `tests`. | `run-toolchain.sh:123-135` |
| Key order and skip rules | Keys `lint typecheck format boundary test` (plus `e2e`). Empty keys are skipped. | `run-toolchain.sh:142-160` |
| Scoping branch | For `test` only: with a non-empty excluded set, `test_scoped` replaces `test` if non-empty; otherwise `unscoped=1`. | `run-toolchain.sh:152-156` |
| Scoping env vars | Exports `WF_EXCLUDE_TESTS`, `WF_TASK_TESTS` (space-separated), `WF_EXCLUDE_TESTS_FILE`, `WF_TASK_TESTS_FILE` (one per line, under the evidence dir), `WF_TASK_ID`, `WF_IMPL_BASE`, for the `test` key only. Selectors are suite paths such as `tests/lint/step-list.sh`. | `run-toolchain.sh:163-172`; `.workflow/specs/001-large-path/artifacts/T9/excluded-tests.txt` |
| Unscoped outcome | On failure with `unscoped=1`: status `unscoped`, not counted as failed, a warning is printed. | `run-toolchain.sh:183-187` |
| Digest and exit | Failures build the digest and exit 1; `unscoped` alone does not. | `run-toolchain.sh:197-220` |
| Phase 1 test skip | The stop audit passes `--skip test` for a launch with no task record (`phase-1-<work_type>`). | `.agents/hooks/post-implementation-audit.sh:228-231` |
| Task-record `tests` field | Optional list of Phase 1 test selectors per task; 2.5 assigns each Phase 1 test to exactly one task. | `.agents/skills/feature-workflow/assets/tasks.md:40` |
| Scoping test coverage | The scoping cases are in the `task-breakdown` suite, not the `run-toolchain` suite. | `tests/scripts/task-breakdown.sh:4-5`, `:205-254`; `tests/scripts/run-toolchain.sh:2-4` |
| Other `--skip test` user | The hook suite asserts the Phase 1 skip and that a failing `test` key is allowed. | `tests/hooks/audit-sync-resume.sh:114-119` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `tests/run-all.sh` | CLI: no args, `--suite NAME`, `--list`, `-v`. Exit 0 pass, 1 any suite failed, 2 missing prerequisite or unknown suite. Parses `RESULT passed=… failed=… skipped=… xfail=…` footers. | Hand-run gate (ADR-0001), profiles' `test:` key | `tests/run-all.sh:4-8`, `:81-103` |
| Suite footer | Each suite ends with `finish`, which prints the RESULT line and exits non-zero on failure. | `run-all.sh` | `tests/lib/common.sh:70-74` |
| `run-toolchain.sh` scoping contract | Child command reads `WF_EXCLUDE_TESTS(_FILE)`, `WF_TASK_TESTS(_FILE)`, `WF_TASK_ID`, `WF_IMPL_BASE`. Result carries `scoped` and `excluded` only when scoping applied. | `test_scoped` profile key; `toolchain.json` | `run-toolchain.sh:30-36`, `:193-194` |
| `--exclude-unfinished` | Gate-only flag for a task id that is not a record. | `implementation-orchestrator.md` at 3.9 | `run-toolchain.sh:20-21`; `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:189` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0001 (accepted) | CI is deferred; `tests/run-all.sh` run by hand is the gate. | `.workflow/decisions/adr/0001-project-baseline.md` § Deferred |
| Cross-cutting policy: tests | Nothing in `.agents/` depends on `tests/`; tests copy `.agents/` into a fixture. | `.workflow/rules.md` § Cross-cutting policy |
| Size budget and tests | `max_changed_files` excludes tests. | `.workflow/rules.md` § Size budget |
| Required versions | bash 3.2 or newer; shellcheck for tests and lint. | `.workflow/rules.md` § Required versions |
| Red by design (Phase 1) | Stop audit skips `test` at Phase 1; `lint`, `typecheck`, `format`, `boundary` still run. | `.agents/skills/feature-workflow/modules/verification-setup.md:57` |
| Red by design (3.9 gate) | Not-last-wave bar: scoped run exits 0 with tests of unmerged tasks excluded. Last-wave bar: whole harness must pass. | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:186-197` |
| Profile conventions | Every test-harness suite ends in `shellcheck_files`; fixtures stay inside `new_workdir`; external tools are stubbed. | `.workflow/profiles/test-harness.md` § Mini-review checklist |
| Deferred shelf | No match: `sign-off-scoped-commit.md`, `shared-path-normaliser.md`, `boundary-check-wording.md`, `retrospective-template-drift.md` cover other concerns. | `.workflow/deferred/` § Goal of each |
| Pitfalls, ADR-0002, retrospectives, capabilities | Nothing related; no capability row mentions tests or suites. | `.workflow/decisions/pitfalls.md`; `.workflow/decisions/adr/0002-review-lessons-placement.md`; `.workflow/capabilities.md` |

## Library options

None. No third-party concern: the change is a selector on a bash runner. `library-evaluation` was not launched.

## Module audit

Not run (light path candidate; 0.4.6 is full path only).

## Not found

- Tier B cache sections for tests, `run-toolchain.sh` or the profile Toolchain blocks: all three caches are missing in `.workflow/cache/`. Reported by retrieval.
- A deferred item about scoped or excluded test runs: all four files in `.workflow/deferred/`. Reported by retrieval.
- A selector or exclude flag in `tests/run-all.sh` beyond `--suite NAME`. Reported by retrieval.
- A rule or ADR defining "red by design" or "test_scoped": `.workflow/decisions/`, `.workflow/rules.md`. Reported by retrieval.
