---
name: project-setup
description: "Set up a project for the feature workflow, outside the flow: creates GLOSSARY.md, docs/, deferred/, model-map/, profiles/ and agent-overrides.yaml from templates, installs each work type's toolchain (anti-slop for TS/JS), calls project-standards to fill docs/rules.md and the work profiles, and generates the import-boundary config from docs/rules.md. Use when adopting the workflow in a project after install.sh, or when adding a new work type."
---

<!--
Sources: first-party; plan PLAN/decision-flow-reference.md "Processes outside the flow" (Project setup), "Persistent files", "Work profiles", 00.1-00.4, 00.11, 00.16-00.17; assetlist D8, D10, D11, D12, D15, D20, D22, D23, D26, D35, D36, D38, D41, D42, D50, D80. Explore-then-confirm interview and one-section-at-a-time questions with a recommended answer adapted from mattpocock/skills/skills/engineering/setup-matt-pocock-skills/SKILL.md@49dd158 (MIT). "Scan before you ask; ask only what no scan reaches" adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/SKILL.md steps 3-4 (MIT; pattern only). Re-run safety (skip what exists, verify earlier files still exist) after wshobson/agents plugins/conductor/commands/setup.md "Resume Handling" (Apache-2.0; pattern only, no text copied). Health-check posture (report missing tools, install only what the project uses) after EveryInc/compound-engineering-plugin skills/ce-setup/SKILL.md (MIT; pattern only). Anti-slop step: see modules/anti-slop.md.
-->

# Project setup

Create every project-owned file the feature workflow assumes, install the tools each work type needs, hand the standards (rules, profiles, ADRs, lint config) to the `project-standards` skill, and generate the boundary config. `install.sh` has already copied `.agents/`, created the `.claude/` shim and merged the hook settings (D11, D36); this skill owns only the project-owned files outside `.agents/`.

## Ground rules

- **Never overwrite project data.** Every path below is created only when absent. An existing file is kept as is and listed as "kept" in the closing report, so a re-run is always safe. The one exception is a seeded `model-map/` file that still holds a `<...>` placeholder: fill only those fields (D23). Content changes to `docs/rules.md`, `profiles/<work-type>.md`, ADRs, lint config and the `AGENTS.md` managed block go through `project-standards` and its approval ledger, never through this skill (D80).
- **Scan before you ask.** Read the repo (manifests, lockfiles, configs, CI, the directory layout) and ask the human only what no scan answers. Ask one section at a time and lead each question with your recommended answer, so a one-word reply accepts it.
- **Write from the main session.** `tier-a-write-guard` allows Tier A writes (`GLOSSARY.md`, `docs/`, `profiles/`) when no feature is in flight. Run this skill only when every `specs/*/spec.md` has `status: done` or there are no specs. If a spec is in flight, a missing profile is created inside that feature at 00.19 (D50); everything else waits until the spec is done.
- **Leave `install.sh`'s job alone.** Leave `.agents/`, `.claude/settings.json`, `.codex/` and `.gitignore` untouched. If `.agents/` is missing, stop and tell the human to run `install.sh <project>` first.

## Modes

- **Full setup** (no `model-map/` or `profiles/` yet): run every step.
- **Add a work type** (the project is set up and a new kind of work appears): run steps 1, 5, 6, 7 and 8 for the new work type only.

## Steps

### 1. Check the tools

```bash
command -v git && command -v jq && command -v yq && yq --version
```

`yq --version` must name mikefarah and report v4 (D38); kislyuk's Python `yq` does not work. If a tool is missing or wrong, stop and give the install hint (for example `brew install jq yq`, or the mikefarah release binary).

Done when git, jq and mikefarah yq v4 are all on PATH.

### 2. Explore and report

Read what exists: the persistent files below, `specs/`, the package manifests and lockfiles, existing lint, format, typecheck and test configs, CI workflows, and monorepo signals (`pnpm-workspace.yaml`, a `workspaces` field, populated `packages/*`). Report what is present, what is missing, and which mode applies.

Done when the human has seen the present/missing list and confirmed the mode.

### 3. Create the shared files

Read [modules/files.md](modules/files.md) and follow it: `GLOSSARY.md`, `docs/capabilities.md`, `docs/rules.md` (copied from the template; `project-standards` fills it at step 7), `docs/decisions/pitfalls.md`, `deferred/`, `agent-overrides.yaml` and `profiles/TEMPLATE.md`.

Done when each file exists, either created now or kept.

### 4. Seed the model map

Read [modules/model-map.md](modules/model-map.md) and write one `model-map/<task-type>.md` for each of the 12 task types with the tier defaults.

Done when all 12 files exist and none holds a `<...>` placeholder.

### 5. Agree the work types and seed their profiles

Read [modules/profiles.md](modules/profiles.md). Agree the work types with the human, then write `profiles/<work-type>.md` for each from `profiles/TEMPLATE.md` with only the Toolchain block filled. The other four sections stay as template text for `project-standards` (step 7).

Done when every agreed work type has a profile whose Toolchain block names a real command, or `""`, for each of `lint`, `typecheck`, `format`, `boundary`, `test` and `e2e`. `test` is required and must be a real command, never `""`: without it 3.9 has nothing to run.

### 6. Install each work type's toolchain

Follow "Install the toolchain" in [modules/profiles.md](modules/profiles.md). For TS/JS work types this includes the anti-slop fetch in [modules/anti-slop.md](modules/anti-slop.md) (D10, D42).

Done when every non-empty Toolchain command either runs (a non-zero exit from findings in project code counts as running) or is listed in the report as not installed, with the reason.

### 7. Set the project standards

Run the `project-standards` skill (D80). Pass it the agreed work types and the mode: greenfield (no tracked source yet), brownfield, or add-work-type with the one new work type. Through one approval ledger it fills `docs/rules.md` (Ownership, Shared core, policy, required versions), the remaining sections of each `profiles/<work-type>.md`, the ADRs (including `0001-project-baseline`), the `docs/pr-quality/` checks, each profile's lint config and the managed block in `AGENTS.md`. It skips the boundary-config run; step 8 does it.

Done when `project-standards` has returned its files written, lint result per profile and open items, every profile has all five sections filled, and `docs/rules.md` has agreed Ownership and Shared core blocks or explicitly keeps them empty.

### 8. Generate the boundary config

```bash
.agents/skills/project-setup/scripts/generate-boundary-config.sh .
```

| Exit | Meaning | Action |
| --- | --- | --- |
| 0 | Config written to `tools/boundaries/dependency-cruiser.cjs` (or already up to date) | Continue. |
| 2 | The Ownership or Shared core block in `docs/rules.md` does not parse or validate (reason on stderr) | Fix the block through `project-standards` (step 7), then re-run. |
| 3 | jq or mikefarah yq v4 missing | Back to step 1. |

The config is derived from `docs/rules.md` and never hand-edited; the `rules-boundary-config-sync` hook re-runs the script on every approved write to `docs/rules.md` (D20). With `modules: {}` the config has no rules, which is valid; say so in the report.

Done when the script exits 0.

### 9. Report

List each path as created, kept or skipped, with the reason; the toolchain commands that ran and their results; the anti-slop pin; the `project-standards` ledger summary; and every open item:

- Codex models in `model-map/` that `codex debug models` did not list, or that were left unchecked because Codex is not installed here.
- Toolchains for non-TS/JS work types that were not installed (G11).

Then point the human at `feature-workflow` as the way to start the first feature.

## Done

- Every persistent file the flow reads exists, and this skill changed no existing file except placeholder fields in `model-map/`; standards content changed only through the `project-standards` ledger.
- Every work type has a profile written by `project-standards`, and its toolchain is installed or reported as not installed.
- `generate-boundary-config.sh` exited 0.
- The report lists created, kept and open items.
