# llm-code-wiki

This repo is being reset to implement workflow 2.0 — an agent-agnostic scaffold whose distribution unit lives in `.agents/` (skills, agents, hooks, output styles). Project instructions live in this file. Claude Code reaches the scaffold through a thin `.claude/` shim; other agents read `.agents/` directly. The previous wiki system, install flow, tests, and docs were removed in the 2.0 reset (see [CHANGELOG.md](./CHANGELOG.md)).

## Two trees

This repo is the **scaffold repo**: it builds and tests the workflow. A **target project** is any repo that runs `install.sh` against it.

- Scaffold repo: holds everything below, including the scaffold-only docs.
- Target project: gets only the first-party payload listed in `.agents/install-manifest.txt`, copied into its own `.agents/`, plus the host shims. All its workflow data lives in one committed folder, `.workflow/` (glossary, rules, capabilities, decisions, caches, profiles, model map, specs, deferred items, tools; D81), created by the `project-setup` skill and owned by that project. Only `e2e/` (the app's browser tests) and the project's own `docs/` stay outside it.

Edit the scaffold here; never edit an installed copy.

## Layout

- `.agents/` — the distribution unit (skills, agents, hooks, output-styles, `install-manifest.txt`)
- `.agents/agents/` — sub-agent definitions, one `.md` per task type (host-neutral; Codex tomls are generated from them)
- `.agents/lib/` — shared sourced shell helpers; `workflow-paths.sh` is the one home for target-project paths under `.workflow/` (D81), so hooks and skill scripts build paths from it
- `.claude/` — Claude Code shim: `settings.json` (hooks, permissions, plugins, output style) plus `skills`, `agents`, and `output-styles` symlinks into `.agents/` (Claude Code still requires these under `.claude/`; `.claude/agents` is the agents symlink)
- `.codex/` — Codex shim docs (`README.md`). The Codex config and agent tomls are created in target projects by `install.sh`, not kept here
- `install.sh` — installs the manifest payload and host shims into a target project
- `tests/` — suites for the scripts and hooks, run with `tests/run-all.sh`
- `AGENTS.md` — project instructions (this file)
- `CLAUDE.md` — one-line `@AGENTS.md` import. Claude Code reads `AGENTS.md` natively since v2.1.277; kept for older versions, Bedrock and Vertex
- `GLOSSARY.md` — shared vocabulary
- `CHANGELOG.md` — release history
- `PROVENANCE.md` — first-party vs vendored inventory of `.agents/`
- `upstream-lineage.json` — lineage of every first-party asset derived from upstream: runtime copies, rewrites, pinned add-ons (scaffold-only, D74, D77)
- Scaffold-only docs, never installed (D30): `PLAN/` (decision-flow reference, mermaid, research, verification records), `assetlist.md` (assets and decisions D1+), `organization.md` (superseded by `assetlist.md`), `checklist.md` (open work)

## Conventions

- New skills, agents, hooks, and output styles go in `.agents/`, never directly in `.claude/`.
- `.claude/` holds only Claude-specific wiring. Do not add content there that another agent would need.
- Edit `AGENTS.md`, not `CLAUDE.md`.
- Code comments in this repo follow [readable-code.md](./.agents/skills/feature-workflow/references/readable-code.md): a comment gives the reason in plain words. Decision IDs and doc paths go in `assetlist.md`, `upstream-lineage.json` or `PROVENANCE.md`, never in code comments.
- Skill templates live in the skill's `assets/` folder.
- Update [PROVENANCE.md](./PROVENANCE.md) whenever you add, vendor, or remove anything under `.agents/`.
- Vendored skills are temporary references, removed once rewritten. None remain: `handoff` and `writing-for-agents` are now first-party and shipped, all others were deleted (D78). We ship a first-party version of anything that affects how agents work; delete the vendored skill once that version exists and its lineage is in [upstream-lineage.json](./upstream-lineage.json). Cite upstream (`<repo>/<path>@<commit>`) in `Sources:` lines, never a vendored path. Vendored skills are never installed into target projects, and first-party assets must not depend on them at runtime. Add-ons unrelated to how agents work (anti-slop Oxlint plugins) are installed from upstream at a pinned commit instead of rebuilt (D71, D77, D78).
- Every first-party asset derived from upstream (skill, module, reference, agent, hook, script, template) gets an `upstream-lineage.json` entry: `kind` `copy`, `derived` or `pinned-addon`, upstream repo, path and commit, `changes`, `why`, `reviewed_at`. To pick up a vendor update, diff each `upstream_path` from its pinned commit, review with the user, bring in what we want, then update the entry (D77).
- If a first-party asset needs an upstream file at runtime, copy it into the consuming skill's `references/` folder with a `Copied from … @ <commit> (<license>). Local edits: …` header and a vendor LICENSE beside it, point every reference at the copy, and add a `kind: copy` entry to `upstream-lineage.json`. On an upstream update, apply the accepted changes to the copy (keep its local edits), then update the commit and sha256 in the entry and the copy's header (D74).
- When you add a first-party asset that target projects need, add it to `.agents/install-manifest.txt` and PROVENANCE.md in the same change. `install.sh` ships only what the manifest lists (D72).
