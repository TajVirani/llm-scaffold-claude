# llm-scaffold

An agent-agnostic scaffold for coding-agent skills and hooks, living in `.agents/`. Claude Code uses a thin `.claude/` shim to reach it; other agents read `.agents/` directly.

**Status:** workflow 2.0 is on `main` and unreleased. 1.x — the wiki scaffold — has been removed; see [CHANGELOG.md](./CHANGELOG.md).

## Layout

- `.agents/` — the distribution unit (skills, agents, hooks, output-styles)
- `.claude/` — Claude Code shim: `settings.json` (hooks, permissions, plugins, output style) plus `skills`, `agents`, and `output-styles` symlinks into `.agents/` (Claude Code still requires these under `.claude/`)
- `AGENTS.md` — project instructions
- `CLAUDE.md` — one-line `@AGENTS.md` import. Claude Code reads `AGENTS.md` natively since v2.1.277; kept for older versions, Bedrock and Vertex
- `.workflow/` — this repo's own workflow data (dogfooding; never installed). `.workflow/GLOSSARY.md` is the shared vocabulary
- `CHANGELOG.md` — release history
- `PROVENANCE.md` — first-party vs vendored inventory of `.agents/`
- `install.sh` — installs the scaffold into a target project (scaffold-only; see below)
- `tests/` — test suites for the scripts and hooks (scaffold-only)

## Index

Workflow skills (`.agents/skills/`):

- `feature-workflow` — entry point: sizes a request, runs discovery through sign-off, resumes in-flight specs (modules in `modules/`)
- `project-setup` — sets up a target project's `.workflow/` folder: glossary, rules, profiles, model map, then the standards interview, toolchain and boundary config
- `project-standards` — drafts, approves and writes a project's standards: rules, work profiles, ADRs, pr-quality checks, lint config
- `domain-modeling` — agrees terms and writes `.workflow/GLOSSARY.md` and ADRs
- `retrospective` — post-feature retrospective at sign-off
- `deeper-prompt` — rewrites a feature request into a deeper prompt the stakeholder agrees to, before the questioning loop (step 0.3.22)

Agents (`.agents/agents/`, one line each):

- `retrieval` — pulls cited extracts from the code, Tier A and `.workflow/deferred/`
- `library-evaluation` — grades candidate libraries for a feature
- `fact-lookup` — answers factual questions with file:line sources
- `module-audit` — deep-reads the owning module
- `implementation` — test-first coding for one task in a worktree
- `integration` — single owner of shared-core changes
- `profile-mini-review` — reviews one task's diff against the profile checklist
- `review-standards`, `review-end-state`, `review-targets` — Phase 4 review lenses (standards and recorded review lessons, spec conformance, measured targets)
- `review-combined` — one review lens for the light path, covering standards, spec conformance and review lessons
- `standards-discovery` — read-only brownfield standards scan for `project-standards`

Hooks live in `.agents/hooks/`, wired by `claude-settings.template.json`, `codex-hooks.template.json` and `codex-config.template.toml`. Each script carries a `# File:` header describing it; `PROVENANCE.md` is the full inventory.

Helper scripts:

- `feature-workflow/scripts/`: each script carries a `# File:` header describing it; `PROVENANCE.md` is the full inventory.
- `project-setup/scripts/`: see the folder.

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

- node and [dependency-cruiser](https://github.com/sverweij/dependency-cruiser), for the import-boundary config
- tsc (TypeScript), optional, for type checks
- the per-profile toolchain, for example Vitest for the test harness and Playwright for the browser suite. `project-setup` installs it per work profile.

## Install and upgrade

```sh
./install.sh <target-dir> [--host claude|codex|all] [--force] [--dry-run] [--matchers=merge|replace|keep]
```

- `<target-dir>` must be the top level of a git repository. `--host` defaults to `all`.
- It copies the first-party payload listed in `.agents/install-manifest.txt` into `<target>/.agents/` and writes `<target>/.agents/VERSION`. Vendored skills are never installed (D71, D72).
- Claude: it creates the `.claude/{skills,agents,output-styles}` symlinks and merges `.agents/hooks/claude-settings.template.json` into `.claude/settings.json`. The merge keeps your keys, hooks and deny rules, and it keeps your `outputStyle` and `statusLine` with a warning. The default `statusLine` is the context bar, `context-bridge.cjs` (D83).
- Codex: it generates `.codex/agents/*.toml` and merges the hook and config templates into `.codex/hooks.json` and `.codex/config.toml`, including a `[tui] status_line` of built-in items as the context bar (D83; a `[tui]` table you already have is kept with a warning). Afterwards, start Codex in the project, trust its `.codex/` layer and review the hooks with `/hooks`. Do this again after every upgrade.
- It adds `.workflow/specs/*/.step`, `.workflow/initiatives/*/.step`, `.workflow/.worktrees/`, `.workflow/.spec-worktrees/`, `.workflow/.handoff/`, `.workflow/.standards-staging/` and `.workflow/.slot` to `.gitignore`, for every `--host`. It does not create `.workflow/` itself; `project-setup` does.
- It never touches project-owned files: everything under `.workflow/` (the glossary, rules, profiles, model map, specs, deferred items and decisions), `e2e/` and the project's own `docs/` (D81). The one exception is an upgrade from an older format, below.
- `--dry-run` prints the changes and writes nothing. When something conflicts, it refuses before writing anything; `--force` replaces the conflicting entries instead (see the header of `install.sh`).

To upgrade, pull this repo and run the same command again. Changed payload files are overwritten. Files the previous install shipped that the manifest no longer lists are removed. A re-run with nothing new changes nothing.

An upgrade also clears what earlier versions left, so the project ends as a fresh install plus its own data:

- Removed: the old write-hook entries and the cache permissions in the host settings, the old Codex permission blocks and retired agent files, the `.workflow/.cache-staging/` ignore line, and the generated `.workflow/cache/` and `.workflow/.cache-staging/` folders.
- Converted, where nothing is lost: `.workflow/model-map/` and `agent-overrides.yaml` into `model-map.yaml`, per-item backlog files into backlog-list lines, and the dead keys `graph_extractor` (profiles), `small_path` (in-flight specs, which keep `light_path: true`) and `cache_stamps` (their codebase maps). Specs in the Done folder are never changed.
- Reported, not changed: a done spec still outside the Done folder, an unfinished task with no task branch, and a review lesson or shelf item that names a removed path, each with the command to run.

The run that does this ends with an "Upgrade from an older install" summary of all three. A second run prints none. To retire something later, add one entry to the matching table near the top of `install.sh`.

Hook matchers on upgrade: when an existing hook group runs a scaffold hook under a matcher that does not cover the template's (its `|` alternatives miss some of the template's), the upgrade resolves that group on its own. A match-all group and a covering one are left as they are, so a re-run asks nothing.

- `--matchers=merge|replace|keep` sets the outcome for every such group. `merge` adds the template's missing alternatives to yours, `replace` takes the template's matcher, and `keep` leaves the group as it is.
- Without `--matchers`, at a terminal the installer asks per group, and Enter merges. Without a terminal it never waits for input: it merges and prints a line under Warnings, but keeps a mixed group (one that also runs a hook of your own) with a warning.
- Merge cannot take a matcher that is not a plain `|` list, so it keeps that group with a warning. A malformed (non-string) matcher is kept in every mode. A group that runs the hooks of two template groups is rewritten into the template's groups when all its hooks are scaffold hooks, and kept when it also runs one of yours; either way a warning names it.
- `--dry-run` previews the matcher changes and asks nothing. `--force` leaves matchers alone.

Upgrade note (D75): `design-pattern-doc` conventions and `pr-quality`'s project-specific modules are now project-owned. If an earlier install gave your project `.agents/skills/design-pattern-doc/conventions.md`, or pr-quality's `modules/legend-state-review.md` or `modules/project-pitfalls.md`, the upgrade prunes them. Before upgrading, copy them to `.workflow/design-pattern-doc/conventions.md` and `.workflow/pr-quality/`. The athena originals were removed from this repo (its git history has them).

After the first install, run the `project-setup` skill in the target project. It creates the `.workflow/` folder, where every piece of workflow data lives (glossary, rules, capabilities, decisions, profiles, model map, specs, deferred items, tools and handoffs), and only `e2e/` (the app's browser tests) stays at the project root. It then runs the standards interview (`project-standards`) before offering example profiles or installing any toolchain. Installs made before this layout are not migrated (workflow 2.0 is unreleased); re-run `project-setup` on a clean project.

## Worktree setup

The workflow builds each spec in its own git worktree, the spec worktree, under `.workflow/.spec-worktrees/`. Each task, Phase 1 suite and integration batch then gets an agent worktree inside the spec checkout, under `.workflow/.worktrees/`. Worktree setup makes each new worktree ready to build and test, so nobody copies files or starts services by hand. One script does it: `.agents/skills/feature-workflow/scripts/worktree-setup.sh`. It creates every agent and scratch worktree and sets up every worktree; `spec-worktree.sh` calls it for each new spec worktree.

A project declares what it needs. `project-setup` asks when it creates `.workflow/rules.md`; later changes go through a sign-off proposal.

- `.worktreeinclude`, at the repository root: gitignore-style patterns for the gitignored files a worktree needs, such as `.env`. Each matching file the main checkout's git ignores is copied in as a regular file, never as a link. A tracked file is never copied, and a file the worktree already has is kept.
- `worktree_setup`, in the `## Workflow settings` block of `.workflow/rules.md`: one shell command that makes a new worktree ready, such as a dependency install. It runs in each new spec, agent and scratch worktree, after the copy. A non-zero exit fails the setup.
- `services_up`, in the same block: starts the services the test and e2e commands need. The toolchain run (`run-toolchain.sh`) runs it itself, once, in the spec worktree, just before the first test or e2e command it will really run. It must be safe to run when the services are already up. When it fails, the run fails and the tests are skipped.
- `services_down`, in the same block: stops what `services_up` started. It runs when the spec worktree is removed. A failure is reported and the removal goes on.

Each of these commands, and every toolchain command, receives five isolation values. The project's own commands turn them into ports, container names and database names, so two specs and the main checkout never share them. The workflow sets nothing project-specific.

- `WF_SLOT`: the spec's number among the live spec worktrees, 0 in the main checkout. A spec worktree takes the lowest free slot and keeps it in `.workflow/.slot`; its agent and scratch worktrees read it from there.
- `WF_INSTANCE`: `s<NNN>` for spec number NNN, or `main`.
- `WF_PORT_OFFSET`: the slot times 100.
- `WF_MAIN_ROOT`: the path of the main checkout.
- `WF_SPEC_ROOT`: the path of the spec worktree (the main checkout for a spec that runs there).

Setup ends with the link check, and every toolchain run starts with it. It fails when a symlink in the worktree, dependency folders included, resolves into the main checkout or another worktree of the repository. A link to a path outside the repository passes.

A project that declares none of these behaves as it did before: the workflow only adds each worktree.
