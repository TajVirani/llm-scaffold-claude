---
cache_stamps:
  modules: null
  flows: null
  architecture: null
---

# Codebase map: Tier B caches for bash projects

Affected area: regenerate-caches (`.agents/skills/regenerate-caches`), agents (`.agents/agents`), project-setup (`.agents/skills/project-setup`), feature-workflow (`.agents/skills/feature-workflow`), tests (`tests`).

All three caches are missing (`.workflow/cache/` is empty), so every extract below was read from code. 0.2.8 was not run: `build-architecture.sh` needs dependency-cruiser, which is the defect this spec fixes.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| build-architecture.sh: tool lookup | Requires depcruise for every `--cache` type (architecture, modules, entries) unless `--from-json` is given. Lookup order: `$DEPCRUISE`, `<root>/node_modules/.bin/depcruise`, `npx --no-install depcruise`. Missing gives exit 2 "depcruise not found". | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:141-160` |
| build-architecture.sh: depcruise run | Runs `depcruise --no-config --ts-config tsconfig.json --exclude node_modules -T json <scopes>` (tsconfig flag only if the file exists). Output must be JSON with `.modules`. | same, `:152-162` |
| build-architecture.sh: graph canonicalisation | jq turns depcruise JSON into `{files, file_edges, node_of, nodes, edges, collisions}`. Mermaid id collisions are fatal; zero files in scope is fatal. | same, `:164-195` |
| build-architecture.sh: module roots | With no `--module`, roots come from `.workflow/rules.md` Ownership and Shared core via `generate-boundary-config.sh --print-intermediate`. Glob-bearing entries are skipped. | same, `:122-135` |
| build-architecture.sh: architecture renderer | Mermaid module graph, sorted edges, then Boundary violations. Violations run only when `.workflow/tools/boundaries/dependency-cruiser.cjs` exists; otherwise "Not checked: no boundary config at ...". | same, `:198-234` |
| build-architecture.sh: modules renderer | One `## <module>` per node with the Purpose slot, Files, Depends on, Used by. Public interface comes from `tsc --declaration --emitDeclarationOnly`; without tsconfig or tsc it reads "Not generated: ...". | same, `:309-350` |
| build-architecture.sh: flows candidates | `--cache entries` prints JSON candidates: files nothing in scope imports, excluding tests and `.d.ts`, each with `reaches_files` and `reaches_modules`. | same, `:352-370` |
| build-architecture.sh: scope rules | `.workflow/tools/boundaries/` scopes are dropped with a warning. Dirty scope paths are refused unless `--allow-dirty`. `--out` under `.workflow/cache/` is refused. | same, `:95-120` |
| cache-stamp-check.sh | Missing file gives `missing`; invalid frontmatter gives `invalid`; stale when `git log <stamp>..HEAD -- <scope>` is non-empty. Stamps are null unless fresh or stale. | `.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh:98-139` |
| generate-boundary-config.sh | Parses the rules.md Ownership and Shared core YAML and emits config per adapter. `ADAPTERS=(dependency-cruiser)` is the only adapter; output goes to `.workflow/tools/boundaries/dependency-cruiser.cjs`. | `.agents/skills/project-setup/scripts/generate-boundary-config.sh:3-5, 31, 135-138` |
| regenerate-caches tool check | Requires git, jq, yq v4 and depcruise. Stops and asks the human to add dependency-cruiser as a dev dependency if missing. | `.agents/skills/regenerate-caches/SKILL.md:31-38` |
| project-setup dependency-cruiser requirement | dependency-cruiser is required in every TS/JS project, even with no `boundary` key; typescript is optional for the caches. | `.agents/skills/project-setup/modules/profiles.md:39-41` |
| Work profile contract | Each `.workflow/profiles/<work-type>.md` has five headings and a Toolchain YAML block. Command keys: lint, typecheck, format, boundary, test, e2e, plus test_scoped. `test` is required. | `.agents/skills/project-setup/assets/profiles/TEMPLATE.md:3, 21-43` |
| Work profile: boundary key example | `boundary:` shows the depcruise command against `.workflow/tools/boundaries/dependency-cruiser.cjs`. | `.agents/skills/project-setup/assets/profiles/TEMPLATE.md:28` |
| Work types to agree | `test-harness` (recommended for every project with code) and `e2e-browser` (only with a browser UI). An existing profile is not changed. | `.agents/skills/project-setup/modules/profiles.md:5-14` |
| Tests: build-architecture | Fixtures stand in for depcruise and tsc output; `--from-json` is used for architecture. One case forces depcruise to fail with `DEPCRUISE=/nonexistent/depcruise`. | `tests/scripts/build-architecture.sh:3-7, 185-196` |
| Tests: cache-scripts | Covers `publish-cache.sh` and `cache-stamp-check.sh` only (fresh, stale, missing, invalid, worktree). Does not run build-architecture.sh. | `tests/scripts/cache-scripts.sh:2-4, 26-60` |
| Test suite map | `scripts/build-architecture` suite: "no node needed: dependency-cruiser and tsc output are fixtures". | `tests/README.md:53` |
| Project state in this repo | No `package.json`, `tsconfig.json`, `node_modules/.bin/depcruise` or `.workflow/tools/boundaries/` at the repo root. | repo root (Glob) |
| Project state in this repo (2026-10-23 correction) | `.workflow/tools/boundaries/dependency-cruiser.cjs` exists and is tracked (committed at spec 002 sign-off, `6cf0ac7`), so the Boundary violations branch runs depcruise here. | `git ls-files .workflow/tools` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| build-architecture.sh | `--cache architecture\|modules\|entries --scope PATH... [--module PATH] [--out FILE] [--root DIR] [--allow-dirty] [--from-json FILE] [--violations-json FILE] [--dts-dir DIR]`. Exit 0 printed or written; 2 on usage, dirty scope, missing depcruise, bad JSON or id collision. | cache-regeneration agent (`.agents/agents/cache-regeneration.md:41, 49, 63`) | `.agents/skills/regenerate-caches/scripts/build-architecture.sh:1-35` |
| cache-stamp-check.sh | `[--area PATH]... [--cache-dir DIR] [--root DIR]`. Stdout JSON `{head, stale, stamps, caches[]}`. Exit 0 fresh; 1 stale or missing; 2 invalid or tooling error. | discovery 0.2.7 (`.agents/skills/feature-workflow/modules/discovery.md:44`); regenerate-caches step 2 (`SKILL.md:43`) | `.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh:7-29` |
| generate-boundary-config.sh | `--print-intermediate ROOT` prints the parsed rules JSON; `--adapter NAME` renders one adapter. Non-zero when the rules blocks do not parse. | build-architecture.sh (`:126`); the profile `boundary` command | `.agents/skills/project-setup/scripts/generate-boundary-config.sh:5, 13, 31` |
| publish-cache.sh | `<staged file> <type> <scope path>... [--generator NAME]`. Stamps and moves a staged body into `.workflow/cache/`. | discovery 0.2.8 (`discovery.md:70-71`); regenerate-caches | `.agents/skills/regenerate-caches/scripts/publish-cache.sh:4` |
| check-staged-cache.sh | `<type> <staged file> [--html-out FILE]`. Exit 0 when the body passes its shapes. | cache-regeneration agent (`cache-regeneration.md:77`); discovery 0.2.8 (`discovery.md:69`) | `.agents/skills/regenerate-caches/scripts/check-staged-cache.sh:7-8` |
| `tool_cmd` | `tool_cmd ENV_VALUE NAME` sets global `cmd=()`; returns 1 only with no env value, no local bin and no `npx`; with `npx` present but the package missing, the later run fails with "depcruise failed". | build-architecture.sh `:158`, `:222`, `:315` | `build-architecture.sh:141-148` |
| Graph intermediate `graph.json` | `{files[], file_edges[[from,to]], node_of{file:node}, nodes[], edges[[n,n]], collisions[[..]]}`, jq `-S`, sorted and unique; every renderer reads only this. | `render_architecture`, `render_modules`, `render_entries` | `build-architecture.sh:165-191` |
| depcruise-shaped input | `.modules[]` of `{source, dependencies[]?: {resolved}}`; `couldNotResolve` and `module` are ignored today. | canonicaliser | `build-architecture.sh:179-184` |
| Violations input | `.summary.violations[] {rule.name, from, to}`; missing gives exit 2. | `render_architecture` | `build-architecture.sh:230-232` |
| `render_modules` Public interface | Per node: `none exported` \| a list of names \| `Not generated: <reason>.` | modules cache | `build-architecture.sh:338-347` |
| SKILL.md step 1 preflight | Fixed list (git, jq, yq v4, depcruise); depcruise missing means stop. | regenerate-caches runs | `SKILL.md:29-38` |
| External tools | dependency-cruiser, tsc, npx; substitutable via `$DEPCRUISE`, `$TSC`, `--from-json`, `--violations-json`, `--dts-dir`. | build-architecture.sh | `build-architecture.sh:27-31` |
| Tier B frontmatter | Required fields: `generated_at_commit` (40 hex), `generated_at` (quoted UTC), `scope` (list, no globs), `cache_type`, `generator`. | publish-cache.sh; cache-stamp-check.sh; retrieval | `.agents/skills/regenerate-caches/assets/cache-frontmatter.md:15-25` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Ownership: regenerate-caches | Owns `.agents/skills/regenerate-caches/**`; may depend on lib, project-setup, feature-workflow, standalone-skills. | `.workflow/rules.md` § Ownership |
| Ownership: project-setup | Owns `.agents/skills/project-setup/**`; may depend on lib, domain-modeling, feature-workflow, project-standards. | `.workflow/rules.md` § Ownership |
| Ownership: feature-workflow | Owns `.agents/skills/feature-workflow/**`; may depend on lib, regenerate-caches, domain-modeling, project-setup. | `.workflow/rules.md` § Ownership |
| Ownership: lib (shared core) | Owns `.agents/lib/**`, no dependencies. `workflow-paths.sh` is the one home for `.workflow/` paths. | `.workflow/rules.md` § Ownership; `AGENTS.md` § Layout |
| No boundary tool in this repo | "No boundary tool runs here (dependency-cruiser cannot read bash)". The module rules steer placement and review only. | `.workflow/rules.md` § Ownership |
| Adapter notes | The dependency-cruiser config is generated from the rules, never hand-edited. | `.workflow/rules.md` § Ownership (comments) |
| Deferred: shared-path-normaliser | Shelved shared helper for workflow-folder path validation. Different concept; not a match. | `.workflow/deferred/shared-path-normaliser.md` |
| ADR-0002 review lessons | Accepted; owned by retrospective. Not in this area. | `.workflow/decisions/adr/0002-review-lessons-placement.md` |
| ADR-0001 project baseline | Keyword scan for the area terms found no match. | `.workflow/decisions/adr/0001-project-baseline.md` |
| Pitfalls | The one entry concerns the README tree; not in this area. | `.workflow/decisions/pitfalls.md` |
| Capabilities | Header only, no rows. | `.workflow/capabilities.md` |
| Required versions | bash 3.2 (no bash 4 constructs); shellcheck for lint and tests only. | `.workflow/rules.md:151-156` |

## Library options

Concerns: bash graph extractor (files, `source`/`.` edges, entry-point candidates, bash 3.2). Settled by rules: none; "External systems" (`.workflow/rules.md:149`) is empty. "Required versions" (`rules.md:151-156`) settles bash 3.2 and shellcheck as lint/test-only.

### Already in the project

- No package manifest or lockfile in the repo. Nothing pinned.
- dependency-cruiser (JS/TS only, not installed here): `build-architecture.sh:158,220-224`; `project-setup/modules/profiles.md:40`. Does not cover bash.
- shellcheck: `install.sh:50`; `rules.md:156` allows it for tests and lint only.
- bash/awk/grep/jq are already the toolchain. No bash graph capability exists.

### Bash source-graph extractor

Verdict: reject all external options; build in-house (awk/grep over `source`/`.` lines, no new dependency). The external parsers add a runtime to a repo with no manifest, and neither outputs a dependency graph.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| bash-language-server@5.8.1 (npm) | fail: LSP server; no graph export; needs Node 20+ | pass: MIT | pass: published 2026-09-19 | unknown: no advisories; no Scorecard | fail: new Node toolchain; ~3 days |
| tree-sitter-bash@0.25.1 (npm grammar) | caution: parse tree only; graph logic still to write; needs tree-sitter core or wasm | pass: MIT | caution: last release 2025-12-02 | pass: no advisories | caution: native or wasm build; core 0.25 to 0.26 churn; ~2 days |
| shellcheck (GPL-3.0) | caution: `-x` follows `source` for lint only; no verified edge-list output | caution: GPL-3.0; tool use only | unknown | unknown | pass: already a dev tool; ~0.5 day as a cross-check |
| In-house awk/grep extractor | pass: bash 3.2 and BSD awk; rules-approved tools only | pass: first-party | pass: no upstream | pass: no new surface | caution: heuristic; ~2-3 days with tests |

Evidence:
- official docs: https://github.com/koalaman/shellcheck
- official docs: https://github.com/bash-lsp/bash-language-server
- registry: https://api.deps.dev/v3/systems/npm/packages/bash-language-server
- registry: https://api.deps.dev/v3/systems/npm/packages/bash-language-server/versions/5.8.1
- registry: https://api.deps.dev/v3/systems/npm/packages/tree-sitter-bash
- registry: https://api.deps.dev/v3/systems/npm/packages/tree-sitter-bash/versions/0.25.1
- registry (search result only): https://archlinux.org/packages/extra/x86_64/tree-sitter-bash/
- community (search result only, unverified): https://graphify.com/languages/bash
- community (search result only): https://socket.dev/npm/package/unbash/overview/4.0.10

Risks:
- Heuristic parsing misses dynamic `source "$DIR/x.sh"` paths: report them as unresolved edges, never guessed ones.
- Entry-point candidates (scripts nothing sources, with a shebang) are simple to find in-house.
- The verdict changes only if the in-house extractor cannot meet bash 3.2 or the determinism rule, or a maintained, MIT, dependency-light bash graph tool appears.
- shellcheck `-x` could cross-check resolved `source` targets; its edge output is unverified.

Unverified: Scorecard and advisories for bash-language-server and tree-sitter-bash; their dependency lists; shellcheck latest release and `-x` edge output; Graphify licence and maturity.

## Module audit

Owning module: regenerate-caches (`.agents/skills/regenerate-caches/`)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | `tool_cmd ENV NAME` lookup (env var, `<root>/node_modules/.bin/NAME`, `npx --no-install NAME`) sets the global `cmd` array; moves into `extractors/dependency-cruiser.sh` unchanged. | `build-architecture.sh:141-149` |
| reuse | The exact depcruise call (`ts_args` tsconfig switch, `--exclude '(^\|/)node_modules/'`, `-T json`, scopes) and its error text "depcruise failed: <first 5 stderr lines>"; identical output means keeping these flags byte for byte. | `build-architecture.sh:151-160` |
| reuse | Shape gate `jq -e '.modules \| type == "array"'` can run on each extractor's output before the merge. | `build-architecture.sh:162` |
| reuse | Canonicalisation runs `unique` over `.modules[].source` and the `[from, resolved]` pairs, so concatenated `.modules` arrays collapse duplicates. | `build-architecture.sh:179-185` |
| reuse | File-to-module mapping and the Mermaid id rule are language-independent. | `build-architecture.sh:167-178,189` |
| reuse | Public interface lines `"name<TAB>kind"` rendered as `` - `name` (kind) ``; `function` is an allowed kind, so `exports` can feed this format. | `build-architecture.sh:236-239,345`; `assets/cache-frontmatter.md:131` |
| reuse | `publish-cache.sh --generator` accepts any non-empty string; `bash,dependency-cruiser` passes the `!!str` check unchanged. | `scripts/publish-cache.sh:50,68,96,110` |
| reuse | Module patterns: `${arr[@]+"${arr[@]}"}`, `while IFS= read`, `die` exit 2, `HERE`, `export LC_ALL=C`. | `build-architecture.sh:41,43,51,134` |
| gap | Nothing in the module reads `.workflow/profiles/*.md` or a Toolchain block; the only YAML-in-markdown parsing is delegated to `generate-boundary-config.sh --print-intermediate`. | `build-architecture.sh:123-131` |
| gap | build-architecture.sh never checks for `yq` itself; reading profile YAML here is a new direct tool requirement. | `build-architecture.sh:36,79-80` |
| gap | Unresolved edges are dropped: `.resolved != null and $in[.resolved]` removes them, and no renderer has a place to report them. | `build-architecture.sh:184` |
| gap | Public interface comes only from tsc; `render_modules` has no branch for an `exports` map, and nothing rolls file-level exports up to a directory module. | `build-architecture.sh:287-307,311-325,338-347` |
| gap | The entries test exclusion is JS/TS only (`__tests__`, `.test.*`/`.spec.*`, `.d.ts`); bash test scripts would be listed as entry candidates. | `build-architecture.sh:366` |
| gap | No `scripts/extractors/` directory and no extractor interface: one inline depcruise run, replaceable only by `--from-json`. | `build-architecture.sh:154-161` |
| constraint | Architecture body sections are pinned to `Module graph`, `Edges`, `Boundary violations`; module sections pin five fields in order. | `scripts/check-staged-cache.sh:76-77,90-92` |
| constraint | Boundary violations runs depcruise a second time through `tool_cmd "${DEPCRUISE:-}" depcruise` whenever the boundary config exists; changing `:141-160` alone leaves it hardwired. | `build-architecture.sh:218-225` |
| constraint | `--from-json` skips every tool lookup and the test suite relies on it; profile and extractor resolution must define how they interact with it. | `build-architecture.sh:27,155-156` |
| constraint | Fatal messages name dependency-cruiser ("dependency-cruiser output is not JSON with .modules", "could not canonicalise dependency-cruiser JSON", "dependency-cruiser found no source files under the scope"); exit 2. | `build-architecture.sh:35,162,191,194-195` |
| constraint | Extractor paths must be repo-root relative, exclude `node_modules`, fully sorted and deterministic; colliding ids (`a-b.sh`, `a_b.sh`) stop the build. | `build-architecture.sh:93,180,189,194`; `assets/cache-frontmatter.md:74-76` |
| constraint | Text naming dependency-cruiser as the only generator: script header and `--help` (lines 2-36), SKILL.md preflight, publish `--generator dependency-cruiser`, frontmatter asset. | `build-architecture.sh:2-36,72`; `SKILL.md:31-38,123,126`; `assets/cache-frontmatter.md:23,70,81` |
| constraint | SKILL.md takes the generator name from the cache-regeneration agent's return. | `SKILL.md:126` |
| constraint | Scope paths under `.workflow/tools/boundaries/` are dropped before any extractor runs; dirty scopes are refused unless `--allow-dirty`. | `build-architecture.sh:95-120` |

Friction: the dependency-cruiser JSON shape has no documented interface; the canonicaliser (`:166-191`), the violations parser (`:230-232`) and three error strings assume it. Recent history: 4 commits on the module, none churning.

## Not found

- Tier B cache files (`.workflow/cache/*.md`).
- A dependency-cruiser boundary config (`.workflow/tools/boundaries/*`).
- Root `package.json`, `tsconfig.json`, `node_modules/.bin/depcruise`.
- `.workflow/decisions/retrospectives/`.
- Capability rows for the area in `.workflow/capabilities.md`.
- No profile or Toolchain reader, no `graph_extractor`, `couldNotResolve` or `module` handling, no extractor directory, no shell-test exclusion in entries, no direct `yq` check in build-architecture.sh. Reported by module-audit.
- Retrieval extract corrected by module-audit (no cache involved; all stamps null, so this is not a stamp problem): the depcruise exclude is the regex `'(^|/)node_modules/'` (`build-architecture.sh:159`); violations also run with `--violations-json` (`:218-219`); with `npx` on PATH the lookup never fails and a missing package shows as "depcruise failed" (`:145`). The module-audit rows above are the accurate ones.
