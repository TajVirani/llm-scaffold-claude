---
name: regenerate-caches
description: "Bulk or on-demand regeneration of the Tier B caches (.workflow/cache/modules.md, flows.md, architecture.md): checks commit stamps, launches one cache-regeneration agent per stale, missing or invalid cache, validates each staged body, and publishes it with a fresh stamp through publish-cache.sh. Use on a schedule, after merges, when caches are stale or missing, or when asked to regenerate, refresh or rebuild the caches. Inside a feature, discovery 0.2.8 does this for the affected area instead."
---

# Regenerate caches

Bring `.workflow/cache/modules.md`, `flows.md` and `architecture.md` back in line with the code at `HEAD`. You run in the main session and orchestrate: the `cache-regeneration` agent derives each cache into `.workflow/.cache-staging/`, and `scripts/publish-cache.sh` stamps it and moves it into `.workflow/cache/`. The result must be identical to what discovery 0.2.8 produces for the same scope and commit, because both launch the same agent, which runs the same scripts.

Schema and body shapes: [assets/cache-frontmatter.md](assets/cache-frontmatter.md).

## Ground rules

- **Never write under `.workflow/cache/` yourself.** `tier-b-write-guard` denies every Write/Edit there. Only `publish-cache.sh` moves files in, and always call it with exactly the prefix `.agents/skills/regenerate-caches/scripts/publish-cache.sh` (the sandbox exclusion matches that command line).
- **Work in the main checkout.** Every script defaults to the main checkout, even from a worktree. Caches describe `HEAD` of that checkout.
- **Regenerate, never patch.** Each run derives a cache from scratch. Never hand the agent the previous cache or any Tier A file.
- **Leave git alone.** Do not commit. The report tells the human which `.workflow/cache/` files changed.

## Modes

- **Stale-only** (default; a schedule or post-merge run): regenerate only the caches `cache-stamp-check.sh` reports as `stale`, `missing` or `invalid`.
- **Full** (the human asks to rebuild, or names caches): regenerate every named cache, or all three, whatever their stamps say.
- **Verify** (the human asks to check determinism): in either mode, run each launch twice and compare before publishing (step 6).

A scope the human gives (repo-relative paths, no globs) overrides the default scope in step 3 for every cache in the run.

## Steps

### 1. Check the tools

```bash
command -v git && command -v jq && command -v yq && yq --version
test -x node_modules/.bin/depcruise || npx --no-install depcruise --version
```

`yq` must be mikefarah v4. If dependency-cruiser is missing, stop and tell the human to add it as a dev dependency (it is in the TS/JS work profile's toolchain); nothing can be generated without it.

Done when git, jq, yq v4 and depcruise all answer.

### 2. Read the stamps

```bash
.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh
```

It prints `{head, stale, stamps, caches: [{cache_type, status, stale_paths, reason}]}`. Exit 0 all fresh, 1 some stale or missing, 2 some invalid or a tooling error. On a tooling or usage error (no `caches` in the output), stop and report it.

Select the caches to regenerate: stale-only mode takes every `stale`, `missing` and `invalid` one; full mode takes the named ones, or all three. If none are selected, report "all caches fresh at `<head>`" and stop.

### 3. Fix the scope for each selected cache

In this order:

1. The scope the human gave.
2. The cache's current scope, when its status is `fresh` or `stale`:
   ```bash
   yq --front-matter=extract '.scope[]' .workflow/cache/<type>.md
   ```
3. For a `missing` or `invalid` cache: the module roots of `.workflow/rules.md`, the same list the build script uses:
   ```bash
   .agents/skills/project-setup/scripts/generate-boundary-config.sh --print-intermediate . \
     | jq -r '[.modules[].owns[], .shared_core.paths[]] | map(sub("/\\*\\*$"; "") | sub("/\\*$"; "") | sub("/$"; "")) | map(select(test("[*?\\[\\]{}!]") | not)) | unique | .[]'
   ```
4. If that list is empty or `.workflow/rules.md` is missing, ask the human for the scope paths, recommending the source root (for example `src`).

**`architecture` also covers the boundary config.** Its Boundary violations section comes from `.workflow/tools/boundaries/dependency-cruiser.cjs`, which lies outside the source paths. So when that file exists, the `architecture` scope always includes the file path `.workflow/tools/boundaries/dependency-cruiser.cjs`, whichever rule above chose the rest. A `.workflow/rules.md` change regenerates the config, and that marks `architecture` stale. It is a stamp-only path: keep it out of the agent's `Scope` line, because `build-architecture.sh` would analyse it as a source file, and add it back when publishing (step 7). When rule 2 reads the current scope, split it off the same way.

Every scope path must exist. Then check that the scope is committed, since a cache describes `HEAD`:

```bash
git status --porcelain --untracked-files=all -- <scope paths>
```

If it prints anything, stop and ask the human to commit or stash those changes first.

### 4. Launch one agent per cache

```bash
mkdir -p .workflow/.cache-staging
git rev-parse HEAD
```

Launch one `cache-regeneration` per selected cache in a single message, so they run in parallel. A bulk launch carries **no** launch header: the prompt is the four task lines only.

```
Cache type: <modules | flows | architecture>
Scope: <path>[, <path> ...]
Commit: <the HEAD sha above>
Staging path: .workflow/.cache-staging/<type>.md
```

On Codex, resolve each launch first; with `--no-header` it builds no header, so `.prompt` is the four lines as given:

```bash
printf '%s\n' "Cache type: <type>" "Scope: <path>" "Commit: <sha>" "Staging path: .workflow/.cache-staging/<type>.md" |
  .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type cache-regeneration --no-header
```

Exit 2 is a deny: one naming **00.14** means no Codex model is set for `cache-regeneration`; record one in `.workflow/model-map/cache-regeneration.md` and rerun. Then spawn with `agent_type` `cache_regeneration` (the definition name with `-` replaced by `_`; `--task-type` keeps the hyphen), `.prompt` as its message, `.model` as its model, `task_name` `cache_<type>` (`cache_modules`, `cache_flows`, `cache_architecture`; `codex-pre-spawn.sh` accepts any `[a-z0-9_]` name for this type, and one without an `s<NNN>_` prefix names no spec) and `fork_turns: "none"` (a full-history fork may ignore the spawn `model` override).

For `architecture`, `Scope` lists the source paths only, never `.workflow/tools/boundaries/dependency-cruiser.cjs` (step 3).

Each agent returns `## Cache staged` with `check`, `mermaid` and `not determinable` lines, or a `LAUNCH ERROR` / `REGENERATION ERROR` line. An error leaves that cache as it was; record it for the report and do not publish it.

### 5. Gate each staged cache

For every `## Cache staged` return:

```bash
.agents/skills/regenerate-caches/scripts/check-staged-cache.sh <type> .workflow/.cache-staging/<type>.md
git rev-parse HEAD
```

Publish only when the check prints `ok` and `HEAD` still equals the commit you launched with. If `HEAD` moved, rerun steps 2-4 for that cache. If the check fails, report its problems and do not publish.

### 6. Verify mode only: compare two runs

Copy the staged file aside (`cp .workflow/.cache-staging/<type>.md .workflow/.cache-staging/<type>.first.md`), launch the same task again, and `diff` the two. Identical: delete the copy and go on. Different: do not publish; report the diff as a prompt fix needed in `.agents/agents/cache-regeneration.md`, then delete both staged files.

### 7. Publish

```bash
.agents/skills/regenerate-caches/scripts/publish-cache.sh .workflow/.cache-staging/<type>.md <type> <scope path> [<scope path> ...] [--generator dependency-cruiser]
```

Pass `--generator dependency-cruiser` for `architecture` only (the agent's return names the generator). For `architecture`, the scope paths are the source paths plus `.workflow/tools/boundaries/dependency-cruiser.cjs` when that file exists (step 3). Exit 0 prints the published path; exit 1 means the staged file is missing, empty or fails the schema, and nothing in `.workflow/cache/` changed.

### 8. Confirm and report

Run `cache-stamp-check.sh` again; every published cache must now be `fresh`. Then report:

| Cache | Before | Action | Scope | New stamp | Mermaid | Not determinable |
| --- | --- | --- | --- | --- | --- | --- |
| modules | stale | published | `src/billing`, `src/ledger` | `<sha>` | n/a | none |

- **Action** is `published`, `skipped (fresh)`, `failed: <reason>` or `not published: verify diff`.
- After the table, list the `.workflow/cache/` files that changed, for the human to commit.

**Done when** every selected cache is either published and `fresh`, or listed with the reason it was not, and `.workflow/.cache-staging/` holds no file this run left behind except ones a failure is reported for.
