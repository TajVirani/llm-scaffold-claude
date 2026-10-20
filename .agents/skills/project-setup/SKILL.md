---
name: project-setup
description: "Set up a project for the feature workflow, outside the flow: creates the .workflow/ tree (GLOSSARY.md, rules.md, capabilities.md, decisions/, deferred/, model-map/, profiles/, agent-overrides.yaml) from templates, agrees the work types, runs the project-standards interview, fills each profile's Toolchain from the agreed tools and installs it (anti-slop for TS/JS), then has project-standards write lint config, and generates the import-boundary config from .workflow/rules.md. Use when adopting the workflow in a project after install.sh, or when adding a new work type."
disable-model-invocation: true
---

# Project setup

Create every project-owned file the feature workflow assumes under `.workflow/`, hand the standards (rules, profiles, ADRs, lint config) to the `project-standards` skill, install the tools the human chose there, and generate the boundary config. Tool choices are made in the `project-standards` interview, never before it: this skill installs what that ledger approved. `install.sh` has already copied `.agents/`, created the `.claude/` shim and merged the hook settings; this skill owns only the project-owned files outside `.agents/`.

## Ground rules

- **Never overwrite project data.** Every path below is created only when absent. An existing file is kept as is and listed as "kept" in the closing report, so a re-run is always safe. The one exception is a seeded `.workflow/model-map/` file that still holds a `<...>` placeholder: fill only those fields. Content changes to `.workflow/rules.md`, `.workflow/profiles/<work-type>.md`, ADRs, lint config and the `AGENTS.md` managed block go through `project-standards` and its approval ledger. The one profile section this skill writes is the Toolchain block, verbatim from approved ledger rows (step 7).
- **Scan before you ask.** Read the repo (manifests, lockfiles, configs, CI, the directory layout) and ask the human only what no scan answers. Ask one section at a time and lead each question with your recommended answer; the human still answers each question.
- **Write from the main session.** `tier-a-write-guard` allows Tier A writes (`.workflow/GLOSSARY.md`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/profiles/`) when no feature is in flight. Run this skill only when every `.workflow/specs/*/spec.md` has `status: done` or there are no specs. If a spec is in flight, a missing profile is created inside that feature at 00.19; everything else waits until the spec is done.
- **Leave `install.sh`'s job alone.** Leave `.agents/`, `.claude/settings.json`, `.codex/` and `.gitignore` untouched. If `.agents/` is missing, stop and tell the human to run `install.sh <project>` first.

## Modes

- **Full setup** (no `.workflow/model-map/` or `.workflow/profiles/` yet): run every step.
- **Add a work type** (the project is set up and a new kind of work appears): run steps 1 and 5-10 for the new work type only.

## Steps

### 1. Check the tools

```bash
command -v git && command -v jq && command -v yq && yq --version
```

`yq --version` must name mikefarah and report v4; kislyuk's Python `yq` does not work. If a tool is missing or wrong, stop and give the install hint (for example `brew install jq yq`, or the mikefarah release binary).

Done when git, jq and mikefarah yq v4 are all on PATH.

### 2. Explore and report

Read what exists: the persistent files below, `.workflow/specs/`, the package manifests and lockfiles, existing lint, format, typecheck and test configs, CI workflows, and monorepo signals (`pnpm-workspace.yaml`, a `workspaces` field, populated `packages/*`). Report what is present, what is missing, and which mode applies.

Done when the human has seen the present/missing list and confirmed the mode.

### 3. Create the `.workflow/` tree

Read [modules/files.md](modules/files.md) and follow it: `.workflow/GLOSSARY.md`, `.workflow/capabilities.md`, `.workflow/rules.md` (copied from the template; `project-standards` fills it), `.workflow/decisions/pitfalls.md`, `.workflow/deferred/`, `.workflow/agent-overrides.yaml` and `.workflow/profiles/TEMPLATE.md`.

Done when each file exists, either created now or kept.

### 4. Seed the model map

Read [modules/model-map.md](modules/model-map.md) and write one `.workflow/model-map/<task-type>.md` for each of the 12 task types with the tier defaults.

Done when all 12 files exist and none holds a `<...>` placeholder.

### 5. Agree the work types

Follow "Agree the work types" in [modules/profiles.md](modules/profiles.md). Agree names and the paths each covers only; no profile is written and no tool is chosen here.

Done when the human has confirmed the work-type list.

### 6. Set the project standards

Run the `project-standards` skill with `phase: standards`, passing the agreed work types and the mode: greenfield (no tracked source yet), brownfield, or add-work-type with the one new work type. Its interview settles every tool and library per work type (the example profiles are offered there as candidate answers), and through one approval ledger it writes `.workflow/rules.md`, each `.workflow/profiles/<work-type>.md` except its Toolchain block, the ADRs (including `0001-project-baseline`), the `.workflow/pr-quality/` checks and the managed block in `AGENTS.md`.

Done when `project-standards` has returned its files written, the approved Toolchain rows per work type, the approved lint rows and its open items, and every profile has its four prose sections filled.

### 7. Fill the Toolchain blocks

Follow "Fill the Toolchain block" in [modules/profiles.md](modules/profiles.md), from the approved Toolchain rows only.

Done when every profile's Toolchain block names a real command, a `TODO: <tool> <purpose>` line, or `""` for each of `lint`, `typecheck`, `format`, `boundary`, `test` and `e2e`, every value traces to an approved row, and `test` is never `""`: without it 3.9 has nothing to run.

### 8. Install each work type's toolchain

Follow "Install the toolchain" in [modules/profiles.md](modules/profiles.md). For TS/JS work types whose approved lint tool is oxlint, this includes the anti-slop fetch in [modules/anti-slop.md](modules/anti-slop.md), which creates the base lint config.

Done when every non-empty Toolchain command either runs (a non-zero exit from findings in project code counts as running) or is listed in the report as not installed, with the reason.

### 9. Write the lint rules

Run `project-standards` again with `phase: lint`. It writes the approved lint rows (layering, type-only imports, banned libraries) into the config each profile names, merging with the base config step 8 registered, runs each profile's `lint` once as the parse proof, and stamps the docs. This skill never writes lint rules itself.

Done when `project-standards` has returned a lint result per profile with no config error.

### 10. Generate the boundary config

```bash
.agents/skills/project-setup/scripts/generate-boundary-config.sh .
```

| Exit | Meaning | Action |
| --- | --- | --- |
| 0 | Config written to `.workflow/tools/boundaries/dependency-cruiser.cjs` (or already up to date) | Continue. |
| 2 | The Ownership or Shared core block in `.workflow/rules.md` does not parse or validate (reason on stderr) | Fix the block through `project-standards`, then re-run. |
| 3 | jq or mikefarah yq v4 missing | Back to step 1. |

The config is derived from `.workflow/rules.md` and never hand-edited; the `rules-boundary-config-sync` hook re-runs the script on every approved write to `.workflow/rules.md`. With `modules: {}` the config has no rules, which is valid; say so in the report.

Done when the script exits 0.

### 11. Report

List each path as created, kept or skipped, with the reason; the toolchain commands that ran and their results; the anti-slop pin; the `project-standards` ledger summary, including its evidence counts; and every open item:

- Codex models in `.workflow/model-map/` that `codex debug models` did not list, or that were left unchecked because Codex is not installed here.
- Toolchains for non-TS/JS work types that were not installed.

Then point the human at `feature-workflow` as the way to start the first feature.

## Done

- Every persistent file the flow reads exists, and this skill changed no existing file except placeholder fields in `.workflow/model-map/`; standards content changed only through the `project-standards` ledger.
- Every work type has a profile written by `project-standards`, a Toolchain block traced to approved rows, and its toolchain installed or reported as not installed.
- `project-standards` ran both phases and its lint proof found no config error.
- `generate-boundary-config.sh` exited 0.
- The report lists created, kept and open items.
