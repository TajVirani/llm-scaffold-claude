# llm-scaffold

An agent-agnostic scaffold for workflow 2.0. The distribution unit lives in `.agents/` (skills, agents, hooks, output styles). Claude Code reaches it through a thin `.claude/` shim; other agents read `.agents/` directly.

## Two trees

This repo is the **scaffold repo**: it builds and tests the workflow. A **target project** is any repo that runs `install.sh` against it.

- Scaffold repo: holds everything, including the scaffold-only files (`PLAN/`, `assetlist.md`, `checklist.md`, `upstream-lineage.json`, `wayfinder-comparison.html`, `testprompt.md` and this repo's own `.workflow/`), which are never installed.
- Target project: gets only the first-party payload listed in `.agents/install-manifest.txt`, copied into its own `.agents/`, plus the host shims. All its workflow data lives in one committed folder, `.workflow/`, created by the `project-setup` skill and owned by that project. Only `e2e/` and the project's own `docs/` stay outside it.

Edit the scaffold here; never edit an installed copy.

### This repo also runs the workflow on itself

The scaffold repo is its own target project, so work on it goes through `feature-workflow` like any other project.

- Its `.workflow/` is set up by `project-setup` (`install.sh` refuses to target its own repo). It is committed, owned by this repo, and never installed: it is not in `.agents/install-manifest.txt`.
- `.workflow/GLOSSARY.md` is the shared vocabulary; there is no root `GLOSSARY.md`.
- Keep the two roles apart: a change to how the workflow behaves goes in `.agents/`; a fact about this repo (its rules, profiles, decisions) goes in `.workflow/`.
- Run `.agents/` straight from source; there is no installed copy to sync.

## Layout (non-obvious parts)

- `.claude/` is Claude-specific wiring only: `settings.json` plus `skills`, `agents` and `output-styles` symlinks into `.agents/`. Do not add content there that another agent would need.
- `.agents/lib/workflow-paths.sh` is the one home for paths under `.workflow/` (in target projects and in this repo); hooks and skill scripts build paths from it.
- The `.gitignore` block for local workflow state (`.workflow/specs/*/.step`, `.workflow/initiatives/*/.step`, `.cache-staging/`, `.worktrees/`, `.handoff/`, `.standards-staging/`) is written by `install.sh` in target projects. In this repo it was added by hand and must be kept in step with `GI_ENTRIES` in `install.sh`.
- `.agents/agents/` holds host-neutral sub-agent definitions; Codex tomls are generated from them.
- `.codex/` holds shim docs only; `install.sh` creates the Codex config and agent tomls in target projects.
- `CLAUDE.md` is a one-line `@AGENTS.md` import. Edit `AGENTS.md`, not `CLAUDE.md`.

## Verifying

- Run `tests/run-all.sh` before reporting work done, and show its result.

<!-- project-standards:begin -->
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 · 2026-10-21 · Managed by project-standards: text between these markers is replaced on refresh; keep your own lines outside them. -->

## llm-scaffold standards

The scaffold is bash 3.2 scripts plus markdown skills and agent definitions, tested by a homegrown bash harness under `tests/`. Plan changes to it through the `feature-workflow` skill; specs live in `.workflow/specs/`.

## Where the standards are

- Writing or changing anything: follow `.workflow/rules.md` (ownership, shared core, cross-cutting policy including comments, vendoring, PROVENANCE, manifest, lineage and commits; required versions).
- Code under `.agents/hooks/`, `.agents/lib/`, `.agents/skills/*/scripts/`, `install.sh`, `scripts/`: follow `.workflow/profiles/shell-scripts.md`.
- Markdown under `.agents/`, `AGENTS.md`, `README.md`: follow `.workflow/profiles/agent-docs.md`.
- Anything under `tests/`: follow `.workflow/profiles/test-harness.md`.
- Naming a workflow concept: use the term in `.workflow/GLOSSARY.md`.
- Changing the core/shim split, the distribution model or a deferred item: read `.workflow/decisions/adr/0001-project-baseline.md` first.
- Before merging: run the `pr-quality` skill; project checks are in `.workflow/pr-quality/`.
- Read workflow files under `.workflow/` by explicit path; when searching, include hidden dirs (e.g. `rg --hidden`), and read gitignored state like `.step` by path.

## Running and verifying

- shell-scripts: lint `git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR` · test `tests/run-all.sh`.
- agent-docs: lint `tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage` · test `tests/run-all.sh`.
- test-harness: lint `git ls-files -z -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR` · test `tests/run-all.sh`.
- No CI: `tests/run-all.sh` run by hand is the whole gate. `--suite <name>` runs one suite; `--list` names them.

## Compaction

- When compacting, keep the active spec path under `.workflow/specs/`, its current step and status, the files modified so far, the failing or pending test output, and the current task and its status.
<!-- project-standards:end -->
