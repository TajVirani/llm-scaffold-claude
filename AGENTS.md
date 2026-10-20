# llm-code-wiki

An agent-agnostic scaffold for workflow 2.0. The distribution unit lives in `.agents/` (skills, agents, hooks, output styles). Claude Code reaches it through a thin `.claude/` shim; other agents read `.agents/` directly.

## Two trees

This repo is the **scaffold repo**: it builds and tests the workflow. A **target project** is any repo that runs `install.sh` against it.

- Scaffold repo: holds everything, including the scaffold-only docs (`PLAN/`, `assetlist.md`, `checklist.md`, `upstream-lineage.json`), which are never installed.
- Target project: gets only the first-party payload listed in `.agents/install-manifest.txt`, copied into its own `.agents/`, plus the host shims. All its workflow data lives in one committed folder, `.workflow/`, created by the `project-setup` skill and owned by that project. Only `e2e/` and the project's own `docs/` stay outside it.

Edit the scaffold here; never edit an installed copy.

## Layout (non-obvious parts)

- `.claude/` is Claude-specific wiring only: `settings.json` plus `skills`, `agents` and `output-styles` symlinks into `.agents/`. Do not add content there that another agent would need.
- `.agents/lib/workflow-paths.sh` is the one home for target-project paths under `.workflow/`; hooks and skill scripts build paths from it.
- `.agents/agents/` holds host-neutral sub-agent definitions; Codex tomls are generated from them.
- `.codex/` holds shim docs only; `install.sh` creates the Codex config and agent tomls in target projects.
- `CLAUDE.md` is a one-line `@AGENTS.md` import. Edit `AGENTS.md`, not `CLAUDE.md`.

## Conventions

- New skills, agents, hooks and output styles go in `.agents/`, never directly in `.claude/`.
- Code comments follow [readable-code.md](./.agents/skills/feature-workflow/references/readable-code.md): a comment gives the reason in plain words. Decision IDs and doc paths go in `assetlist.md`, `upstream-lineage.json` or `PROVENANCE.md`, never in code comments.
- Skill templates live in the skill's `assets/` folder.
- Update [PROVENANCE.md](./PROVENANCE.md) whenever you add, vendor or remove anything under `.agents/`.
- When you add a first-party asset that target projects need, add it to `.agents/install-manifest.txt` and PROVENANCE.md in the same change. `install.sh` ships only what the manifest lists.
- Vendored skills are temporary references and are never installed into target projects; first-party assets must not depend on them at runtime. We ship a first-party version of anything that affects how agents work; delete the vendored skill once that version exists and its lineage is in [upstream-lineage.json](./upstream-lineage.json). Cite upstream (`<repo>/<path>@<commit>`) in `Sources:` lines, never a vendored path. Add-ons unrelated to how agents work (anti-slop Oxlint plugins) are installed from upstream at a pinned commit instead of rebuilt.
- Every first-party asset derived from upstream (skill, module, reference, agent, hook, script, template) gets an `upstream-lineage.json` entry: `kind` `copy`, `derived` or `pinned-addon`, upstream repo, path and commit, `changes`, `why`, `reviewed_at`. To pick up a vendor update, diff each `upstream_path` from its pinned commit, review with the user, bring in what we want, then update the entry.
- If a first-party asset needs an upstream file at runtime, copy it into the consuming skill's `references/` folder with a `Copied from … @ <commit> (<license>). Local edits: …` header and a vendor LICENSE beside it, point every reference at the copy, and add a `kind: copy` entry to `upstream-lineage.json`. On an upstream update, apply the accepted changes to the copy (keep its local edits), then update the commit and sha256 in the entry and the copy's header.

## Verifying

- Run `tests/run-all.sh` before reporting work done, and show its result.

## Compaction

- When compacting, keep the files modified so far, the failing or pending test output, and the current task and its status.
