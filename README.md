# llm-code-wiki

An agent-agnostic scaffold for coding-agent skills and hooks, living in `.agents/`. Claude Code uses a thin `.claude/` shim to reach it; other agents read `.agents/` directly.

**Status:** workflow 2.0 is in progress on this branch. 1.x — the wiki scaffold — has been removed; see [CHANGELOG.md](./CHANGELOG.md).

## Layout

- `.agents/` — the distribution unit (skills, agents, hooks, output-styles)
- `.claude/` — Claude Code shim: `settings.json` (hooks, permissions, plugins, output style) plus `skills`, `agents`, and `output-styles` symlinks into `.agents/` (Claude Code still requires these under `.claude/`)
- `AGENTS.md` — project instructions
- `CLAUDE.md` — one-line `@AGENTS.md` import. Claude Code reads `AGENTS.md` natively since v2.1.277; kept for older versions, Bedrock and Vertex
- `GLOSSARY.md` — shared vocabulary
- `CHANGELOG.md` — release history
- `PROVENANCE.md` — first-party vs vendored inventory of `.agents/`
- `install.sh` — installs the scaffold into a target project (scaffold-only; see below)
- `tests/` — test suites for the scripts and hooks (scaffold-only)

## Index

Workflow skills (`.agents/skills/`):

- `feature-workflow` — entry point: sizes a request, runs discovery through sign-off, resumes in-flight specs (modules in `modules/`)
- `project-setup` — sets up a target project: glossary, docs, profiles, model map, toolchain, boundary config
- `regenerate-caches` — regenerates and publishes the Tier B caches
- `domain-modeling` — agrees terms and writes `GLOSSARY.md` and ADRs
- `retrospective` — post-feature retrospective at sign-off
- `deeper-prompt` — rewrites a feature request into a deeper prompt the stakeholder agrees to, before the questioning loop (step 0.3.22)

Agents (`.agents/agents/`, one line each):

- `retrieval` — pulls cited extracts from Tier A, Tier B and `deferred/`
- `library-evaluation` — grades candidate libraries for a feature
- `cache-regeneration` — derives one Tier B cache from code
- `fact-lookup` — answers factual questions with file:line sources
- `module-audit` — deep-reads the owning module
- `implementation` — test-first coding for one task in a worktree
- `integration` — single owner of shared-core changes
- `profile-mini-review` — reviews one task's diff against the profile checklist
- `review-standards`, `review-end-state`, `review-targets` — Phase 4 review lenses (standards, spec conformance, measured targets)

Hooks (`.agents/hooks/`; wiring in `claude-settings.template.json`, `codex-hooks.template.json`, `codex-config.template.toml`):

- `pre-launch.sh` — validates and rewrites sub-agent launches (profile, model)
- `post-implementation-audit.sh` — runs the toolchain when an `implementation` agent stops
- `spec-single-writer-guard.sh`, `tier-a-write-guard.sh`, `tier-b-write-guard.sh` (with `_guard-common.sh`) — write guards
- `rules-boundary-config-sync.sh` — regenerates the boundary config when rules change
- `evidence-capture.sh` — saves browser-suite evidence
- `session-start-resume.sh` — offers to resume in-flight specs and the work backlog
- `block-destructive-git.sh` — blocks destructive git commands
- `context-bridge.js` — Claude status line: context-usage bar, plus a `<tmpdir>/claude-ctx-<session_id>.json` bridge file (D79)
- `_codex-patch.sh`, `codex-pre-spawn.sh`, `codex-rules-sync.sh`, `codex-write-guard.sh`, `generate-codex-agents.sh` — Codex adapters and agent generator

Helper scripts:

- `feature-workflow/scripts/`: `status-transition.sh` (status, tasks, step marker), `resolve-launch.sh` (launch validation, profile and model), `run-toolchain.sh` (profile toolchain), `check-write.sh` (write guard logic), `budget-check.sh` (size budget)
- `regenerate-caches/scripts/`: `cache-stamp-check.sh`, `publish-cache.sh`, `build-architecture.sh`, `check-staged-cache.sh`
- `project-setup/scripts/`: `generate-boundary-config.sh`

Other first-party skills: `data-structure-audit`, `pr-review-data`, `deps-audit`, `deps-update`, `design-pattern-doc`, `glab`, `pr-quality`, `visual-change-report`. `handoff` and `writing-for-agents` (first-party rewrites, D78) ship too. Nothing vendored remains in `.agents/skills/`; `PROVENANCE.md` has the full inventory.

## Tests

```sh
tests/run-all.sh                     # all suites
tests/run-all.sh --suite pre-launch  # one suite (--list shows names)
```

Needs shellcheck on top of the install requirements below. See [tests/README.md](./tests/README.md).

## Requirements

To install (checked by `install.sh`):

- bash 3.2 or newer (the macOS default works)
- git
- jq
- [mikefarah yq](https://github.com/mikefarah/yq) v4. The Python `yq` is not supported (D38).

To run this repo's tests: the above plus [shellcheck](https://www.shellcheck.net/) (`tests/run-all.sh`; see `tests/README.md`).

In target projects, used by the workflow at runtime:

- node and [dependency-cruiser](https://github.com/sverweij/dependency-cruiser), for the import-boundary config and the architecture cache
- tsc (TypeScript), optional, for type checks and the architecture cache
- the per-profile toolchain, for example Vitest for the test harness and Playwright for the browser suite. `project-setup` installs it per work profile.

## Install and upgrade

```sh
./install.sh <target-dir> [--host claude|codex|all] [--force] [--dry-run]
```

- `<target-dir>` must be the top level of a git repository. `--host` defaults to `all`.
- It copies the first-party payload listed in `.agents/install-manifest.txt` into `<target>/.agents/` and writes `<target>/.agents/VERSION`. Vendored skills are never installed (D71, D72).
- Claude: it creates the `.claude/{skills,agents,output-styles}` symlinks and merges `.agents/hooks/claude-settings.template.json` into `.claude/settings.json`. The merge keeps your keys, hooks and deny rules, and it keeps your `outputStyle` with a warning.
- Codex: it generates `.codex/agents/*.toml` and merges the hook and permission templates into `.codex/hooks.json` and `.codex/config.toml`. Afterwards, start Codex in the project, trust its `.codex/` layer and review the hooks with `/hooks`. Do this again after every upgrade.
- It adds `specs/*/.step`, `.cache-staging/` and `.worktrees/` to `.gitignore`.
- It never touches project-owned files: `agent-overrides.yaml`, `model-map/`, `profiles/`, `GLOSSARY.md`, `docs/`, `deferred/` and `specs/`.
- `--dry-run` prints the changes and writes nothing. When something conflicts, it refuses before writing anything; `--force` replaces the conflicting entries instead (see the header of `install.sh`).

To upgrade, pull this repo and run the same command again. Changed payload files are overwritten. Files the previous install shipped that the manifest no longer lists are removed. A re-run with nothing new changes nothing.

Upgrade note (D75): `design-pattern-doc` conventions and `pr-quality`'s project-specific modules are now project-owned. If an earlier install gave your project `.agents/skills/design-pattern-doc/conventions.md`, or pr-quality's `modules/legend-state-review.md` or `modules/project-pitfalls.md`, the upgrade prunes them. Before upgrading, copy them to `docs/design-pattern-doc/conventions.md` and `docs/pr-quality/` (or take athena's originals from `PLAN/archive/` in this repo).

After the first install, run the `project-setup` skill in the target project.
