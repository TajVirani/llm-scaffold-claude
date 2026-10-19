<!--
Module of project-setup: fill one profile per work type, then install the toolchain each profile names.
Sources: first-party; plan PLAN/decision-flow-reference.md "Work profiles", 00.16-00.20, 1.2-1.3, 3.5, 3.7; assetlist D15, D19, D26 (example stack: Vitest, tsc, oxlint + anti-slop, oxfmt or Prettier, dependency-cruiser, Playwright), D50. "Install current compatible versions instead of remembered ones; keep the package manager; preserve unrelated ranges" adapted from dmmulroy/anti-slop/skills/install-anti-slop/SKILL.md@c44ef22 step 2 (MIT). Non-TS/JS toolchains are gap G11.
-->

# Profiles and toolchains

A profile is the operating context for every coding agent doing one kind of work. It is injected whole into `implementation` and `integration` launches (00.20), and its checklist section into `profile-mini-review` (3.7). `run-toolchain.sh` runs its Toolchain block at 3.5. The five headings and the Toolchain keys are a parsed contract: keep their text exactly as in `profiles/TEMPLATE.md`.

## Agree the work types

Propose work types from what the repo holds, for example `frontend-react`, `backend-api`, `data-migration`. Add the two test work types that Phase 1 launches under (1.2, 1.3):

- `test-harness`: unit and integration tests and CI checks. Recommend it for every project with code.
- `e2e-browser`: browser journeys (`JRN-###`). Recommend it only when the project has a browser UI.

The human confirms the list. In "add a work type" mode, the list is the one new work type.

Done when the list is agreed. A work type that already has a `profiles/<work-type>.md` keeps it unchanged: editing an existing profile is a 5.3 proposal.

## Fill each profile

1. **Starting point.** If `.agents/skills/project-setup/assets/profiles/examples/<work-type>.md` exists and has no `STUB:` line, offer it as the starting point. It is marked "adapt before use": adapt it with the human and delete the banner. Otherwise copy `profiles/TEMPLATE.md`.
2. **File locations, Approved libraries per concern, Language and style rules.** Fill them from what the code already does (directory layout, dependencies in the manifest, tsconfig strictness, existing lint rules), and ask the human only for what the scan cannot settle. Each line passes the line test in the template comment. A line that would appear in every profile goes in `docs/rules.md` instead.
3. **Toolchain.** The keys are a fixed set; keep them all.
   - **Command keys**, each the exact command run from the project root, or `""` when it does not apply: `lint`, `typecheck`, `format` (a check command, never a writer), `boundary` (for TS/JS, `depcruise --config tools/boundaries/dependency-cruiser.cjs <source dirs>`), `test` and `e2e`. `test` is **required** and never `""`: it is the unit/integration suite `run-toolchain.sh` runs at 3.5 and the 3.9 harness gate (D61). `e2e` is non-empty only for e2e work types; `evidence-capture` matches on it, and the orchestrator runs it at 3.10.
   - **`serve` and `serve_ready`**: the start command for the built app and the URL polled until it answers. `review-targets` uses them at 4.3 (D62); `run-toolchain.sh` never runs them. `""` when the work type has no runnable build.
   - **Non-command keys** that `run-toolchain.sh` ignores: `e2e_report` (e2e work types only: the Playwright JSON reporter `outputFile`, relative to the run directory, which `evidence-capture` reads; default `test-results/e2e-results.json`), `config` (config file path per tool) and `rule_set` (the rules in force).
4. **Mini-review checklist.** List only judgement items that no tool can check, one line each.
5. Delete the template comment, then write `profiles/<work-type>.md` with Write.

Done when every section holds real lines, `test` is a real command, and every other command key is a command or `""`.

## Install the toolchain

Group the commands that the new profiles name, then check which tools the project lacks.

### TS/JS profiles

1. **Detect** the package manager from the lockfile (`pnpm-lock.yaml`, `bun.lock` or `bun.lockb`, `yarn.lock`, `package-lock.json`) and use it for every install. Keep the package manager the project already uses.
2. **List what is missing**, using the D26 stack as the default for each concern: oxlint with anti-slop (lint), `typescript` (typecheck), `oxfmt` or `prettier` (format; keep a formatter the project already has), `dependency-cruiser` (boundary), `vitest` (test-harness), `@playwright/test` (e2e-browser). Two tools matter beyond the profiles:
   - `dependency-cruiser` is **required** in every TS/JS project, even when no profile sets `boundary`: the import-boundary check runs it, and `build-architecture.sh` uses it to build all three Tier B caches.
   - `typescript` (`tsc`) is **optional** for the caches: without it, `modules.md` has no Public interface entries. A profile whose `typecheck` uses it still needs it installed.
3. **Show the list and get approval** before changing the manifest. Install approved tools as dev dependencies, at the current version from `npm view <package> version`, not a remembered one. Follow the project's existing version style (exact or range), and leave unrelated dependency ranges unchanged.
4. **Lint: anti-slop.** Follow [anti-slop.md](anti-slop.md). It installs `oxlint` and `@oxlint/plugins` as an exact matching pair, and registers the rules.
5. **Configure** only what a Toolchain command needs and the project lacks. Merge into an existing config file rather than replacing it. The boundary config comes from step 7 of the skill, never by hand.
6. **Run** each non-empty Toolchain command once. Findings in existing project code mean the tool works: report the counts, and fix them only when the human asks. A command that fails to start (not found, bad config) is a setup failure: fix it or report it.

### Other languages (TODO(G11))

The scaffold has no installer for non-TS/JS toolchains yet. Write the commands the human gives into the profile, check each binary with `command -v`, and list every missing one in the report as "not installed (G11)".

Done when every non-empty Toolchain command has run, or is in the report as not installed, with the reason.
