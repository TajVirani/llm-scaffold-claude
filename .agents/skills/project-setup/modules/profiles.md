# Profiles and toolchains

A profile is the operating context for every coding agent doing one kind of work. It is injected whole into `implementation` and `integration` launches (00.20), and its checklist section into `profile-mini-review` (3.7). `run-toolchain.sh` runs its Toolchain block at 3.5. The five headings and the Toolchain keys are a parsed contract: keep their text exactly as in `.workflow/profiles/TEMPLATE.md`.

## Agree the work types

Propose work types from what the repo holds, for example `frontend-react`, `backend-api`, `data-migration`. Add the two test work types that Phase 1 launches under (1.2, 1.3):

- `test-harness`: unit and integration tests and CI checks. Recommend it for every project with code.
- `e2e-browser`: browser journeys (`JRN-###`). Recommend it only when the project has a browser UI.

For each, name the paths it covers. Tools and frameworks are not chosen here: the `project-standards` interview chooses them. The human confirms the list. In "add a work type" mode, the list is the one new work type.

Done when the list is agreed. A work type that already has a `.workflow/profiles/<work-type>.md` keeps it unchanged: editing an existing profile is a 5.3 proposal.

## Fill the Toolchain block

`project-standards` (`phase: standards`) has created each `.workflow/profiles/<work-type>.md`, filled its four prose sections, and returned the approved Toolchain rows: the tool per key, its version and its command, all chosen by the human in its interview. This step writes those rows into the block; it chooses nothing. A key with no approved row is a gap: ask `project-standards` to put it to the human, never fill it from the example profiles or a default.

The keys are a fixed set; keep them all.

- **Command keys**, each the exact command run from the project root, or `""` when it does not apply: `lint`, `typecheck`, `format` (a check command, never a writer), `boundary` (for TS/JS, `depcruise --config .workflow/tools/boundaries/dependency-cruiser.cjs <source dirs>`), `test` and `e2e`. `test` is **required** and never `""`: it is the unit/integration suite `run-toolchain.sh` runs at 3.5 and the 3.9 harness gate. `e2e` is non-empty only for e2e work types; `evidence-capture` matches on it, and the orchestrator runs it at 3.10. A command for a stack that does not exist yet stays the row's `TODO: <tool> <purpose>` line.
- **`test_scoped`** (optional, a command or absent): the `test` command with the Phase 1 tests of unfinished tasks excluded. The spec branch is red by design until the last wave, so `run-toolchain.sh` runs it in place of `test` at 3.5 and at the 3.9 gate whenever some task not yet `done` owns Phase 1 tests (its record's `tests` list, 2.5). It receives `$WF_EXCLUDE_TESTS` (the excluded selectors, space-separated; `$WF_EXCLUDE_TESTS_FILE`, one per line), `$WF_TASK_TESTS` (this task's own; `$WF_TASK_TESTS_FILE`), `$WF_TASK_ID` and `$WF_IMPL_BASE` (`impl_base_revision`, `""` when unset). Write it from an approved row like the other keys; the examples show Vitest `--exclude` and Playwright `--grep-invert`. Without it a failing `test` is recorded `unscoped`: a warning in `toolchain.json`, not a failure, so the gate cannot block on it.
- **`serve` and `serve_ready`**: the start command for the built app and the URL polled until it answers. `review-targets` uses them at 4.3; `run-toolchain.sh` never runs them. `""` when the work type has no runnable build.
- **`test_patterns`** (optional, a list or absent): which paths are tests for this work type, so `budget-check.sh` keeps them out of the size-budget file count and reports them apart. Absent or `[]` means the defaults (`*.test.*`, `*.spec.*`, `__tests__/`, `tests/`, `test/`, `e2e/`, `*_test.go`, `test_*.py`, `*_test.py`); write a list only when an approved row says the project's tests live elsewhere or a default folder holds real source. The union over all profiles applies.
- **Non-command keys** that `run-toolchain.sh` ignores: `e2e_report` (e2e work types only: the Playwright JSON reporter `outputFile`, relative to the run directory, which `evidence-capture` reads; default `test-results/e2e-results.json`), `config` (config file path per tool), `rule_set` (the rules in force) and `test_patterns`.

Write the block with Edit, then set each row's Written cell in `.workflow/.standards-staging/baseline.md` to `profile:<work-type> § Toolchain`.

Done when every agreed work type's Toolchain block holds only approved values, `test` is a real command or a `TODO` line, and every other command key is a command, a `TODO` line or `""`.

## Install the toolchain

Group the commands that the new Toolchain blocks name, then check which tools the project lacks. Install only tools an approved row names.

### TS/JS profiles

1. **Detect** the package manager from the lockfile (`pnpm-lock.yaml`, `bun.lock` or `bun.lockb`, `yarn.lock`, `package-lock.json`) and use it for every install. Keep the package manager the project already uses.
2. **List what is missing** from the tools the Toolchain blocks name, at the versions the approved rows pin. Two tools matter beyond the profiles:
   - `dependency-cruiser` is **required** in every TS/JS project, even when no profile sets `boundary`: the import-boundary check runs it, and `build-architecture.sh` uses it to build all three Tier B caches.
   - `typescript` (`tsc`) is **optional** for the caches: without it, `modules.md` has no Public interface entries. A profile whose `typecheck` uses it still needs it installed.
3. **Show the list** before changing the manifest. Install the tools as dev dependencies at the pinned version, or, where a row pins none, at the current version from `npm view <package> version`, not a remembered one. Follow the project's existing version style (exact or range), and leave unrelated dependency ranges unchanged.
4. **Lint: anti-slop**, when the approved lint tool is oxlint. Follow [anti-slop.md](anti-slop.md). It installs `oxlint` and `@oxlint/plugins` as an exact matching pair, and registers the base rules. Project lint rules (layering, banned libraries) come later, from `project-standards` `phase: lint`.
5. **Configure** only what a Toolchain command needs and the project lacks. Merge into an existing config file rather than replacing it. The boundary config comes from step 10 of the skill, never by hand; project lint rules come from `project-standards` at step 9.
6. **Run** each non-empty Toolchain command once. Findings in existing project code mean the tool works: report the counts, and fix them only when the human asks. A command that fails to start (not found, bad config) is a setup failure: fix it or report it.

### Other languages

The scaffold has no installer for non-TS/JS toolchains yet. Write the commands the human gives into the profile, check each binary with `command -v`, and list every missing one in the report as "not installed".

Done when every non-empty Toolchain command has run, or is in the report as not installed, with the reason.
