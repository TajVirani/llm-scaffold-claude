# Rules
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 -->

## Ownership

Each module owns paths and may depend only on the modules it lists. Anything not listed is forbidden. No boundary tool runs here (dependency-cruiser cannot read bash), so these modules steer placement at 0.3.3 and review at 4.1; a `source` line, a script call or a `skills/<name>/` path reference counts as a dependency.

```yaml
# modules: map of module name -> owns (globs, repo-relative) and may_depend_on (module names).
# Example (replace):
#   modules:
#     billing:
#       owns: ["src/billing/**"]
#       may_depend_on: [ledger]
#     ledger:
#       owns: ["src/ledger/**"]
#       may_depend_on: []
#
# Adapter mapping notes (dependency-cruiser; generate-boundary-config.sh):
#   - Format: config file .workflow/tools/boundaries/dependency-cruiser.cjs exporting { forbidden: [...], options: {...} }.
#     A `forbidden` rule is { name, comment, severity, from: { path }, to: { path } }; path values are regexes
#     matched against repo-relative paths; severity: error fails `depcruise --config <file> <src>`.
#   - Glob to regex: anchor with ^, escape ".", "**" -> ".*", "*" -> "[^/]*".
#   - Modules become forbidden pairs: for each module M and each other module N not in M.may_depend_on and not
#     shared core, emit
#       { name: "<M>-not-to-<N>", severity: "error", from: { path: <owns(M)> }, to: { path: <owns(N)> } }
#     (to.path may be an array of regexes when N has several owns entries; likewise from.path).
#   - Capture groups: for peer folders sharing one pattern (e.g. "^src/features/([^/]+)/"), one rule may use
#       from: { path: "(^src/features/)([^/]+)/" }, to: { path: "^$1", pathNot: "$1$2" }
#     ($1, $2 refer to groups in from.path). Optional optimisation; per-pair rules are always valid.
#   - options.tsConfig: { fileName: "tsconfig.json" } for TypeScript path resolution.
modules:
  lib:
    owns: [".agents/lib/**"]
    may_depend_on: []
  hooks:
    owns: [".agents/hooks/**"]
    may_depend_on: [lib, feature-workflow, project-setup]
  feature-workflow:
    owns: [".agents/skills/feature-workflow/**"]
    may_depend_on: [lib, regenerate-caches, domain-modeling, project-setup]
  project-setup:
    owns: [".agents/skills/project-setup/**"]
    may_depend_on: [lib, domain-modeling, feature-workflow, project-standards]
  project-standards:
    owns: [".agents/skills/project-standards/**"]
    may_depend_on: [project-setup, feature-workflow, domain-modeling, standalone-skills]
  regenerate-caches:
    owns: [".agents/skills/regenerate-caches/**"]
    may_depend_on: [lib, project-setup, feature-workflow, standalone-skills]
  domain-modeling:
    owns: [".agents/skills/domain-modeling/**"]
    may_depend_on: [feature-workflow]
  retrospective:
    owns: [".agents/skills/retrospective/**"]
    may_depend_on: [feature-workflow]
  deeper-prompt:
    owns: [".agents/skills/deeper-prompt/**"]
    may_depend_on: [feature-workflow]
  data-structure-audit:
    owns: [".agents/skills/data-structure-audit/**"]
    may_depend_on: [lib]
  pr-review-data:
    owns: [".agents/skills/pr-review-data/**"]
    may_depend_on: [data-structure-audit]
  deps-audit:
    owns: [".agents/skills/deps-audit/**"]
    may_depend_on: [standalone-skills]
  standalone-skills:
    owns:
      - ".agents/skills/deps-update/**"
      - ".agents/skills/design-pattern-doc/**"
      - ".agents/skills/glab/**"
      - ".agents/skills/handoff/**"
      - ".agents/skills/pr-quality/**"
      - ".agents/skills/visual-change-report/**"
      - ".agents/skills/writing-for-agents/**"
    may_depend_on: []
  agents:
    owns: [".agents/agents/**"]
    may_depend_on: [feature-workflow]
  output-styles:
    owns: [".agents/output-styles/**"]
    may_depend_on: []
  installer:
    owns: ["install.sh", ".agents/install-manifest.txt"]
    may_depend_on: [lib, hooks]
  scaffold-scripts:
    owns: ["scripts/**"]
    may_depend_on: []
  tests:
    owns: ["tests/**"]
    may_depend_on: [lib, hooks, feature-workflow, project-setup, project-standards, regenerate-caches, domain-modeling, retrospective, deeper-prompt, data-structure-audit, pr-review-data, deps-audit, standalone-skills, agents, output-styles, installer, scaffold-scripts]
  root-docs:
    owns: ["AGENTS.md", "README.md", ".agents/README.md"]
    may_depend_on: []
```

## Shared core

Shared core changes only through the integration agent, between batches. Every module may depend on shared core. Shared core may not depend on any module.

```yaml
# shared_core.paths: globs (same glob syntax as above) for code every module may use.
# Adapter mapping: each module is allowed to import it (no rule emitted), and one rule per module N emits
#   { name: "shared-core-not-to-<N>", severity: "error", from: { path: <shared_core.paths> }, to: { path: <owns(N)> } }
# The integration agent treats any diff touching these paths as a shared-core change.
shared_core:
  paths: [".agents/lib/**"]
```

## Size budget

Soft per-spec limits, copied into each spec's `budget` frontmatter when `tasks.md` is written (2.5, or 0.3.20 on the light path). Crossing either one pauses the work for a human decision (split, re-scope or approve the overrun). `max_changed_files` limits the review load on whoever approves the feature's PR/MR, so it counts only what that reviewer sees, minus tests: changes merged in from `main_branch` drop out by the merge-base, the Phase 1 harness and suite count only when Phase 3 changes them again, and test files (each profile's `test_patterns`) are reported apart. Changed only at 5.3.

```yaml
size_budget:
  max_tasks: 10
  max_changed_files: 30   # files a reviewer sees in the feature's PR/MR (diff from the merge-base with main_branch), changed since impl_base_revision, excluding tests, the spec folder and the work-backlog; 2.6 also checks the predicted sum less predicted tests
```

## Workflow settings

Optional. How the orchestrator reviews each task branch before merging it into the spec branch at 3.16, and the branch each feature's PR/MR targets. Delete the section, or a key, to keep the default. Changed only at 5.3.

```yaml
task_review: pr   # pr (default): open a PR/MR into the spec branch as a non-blocking review record, merge locally and continue
                  # pr-blocking: open it and wait for approval before merging
                  # local: no push, no PR
# main_branch: main   # the branch spec branches fork from and merge into at sign-off (the PR/MR target; the size budget counts from
                      # its merge-base). Default: the branch origin/HEAD names, else main. Read with rules-setting.sh main_branch.
```

## Cross-cutting policy

- Scripts are bash. Another language (bun TS, python3, node) only inside one skill when bash cannot do the job, with an ADR and a test suite for each new file.
- Body comments follow `.agents/skills/feature-workflow/references/readable-code.md` (a comment gives the reason in plain words; no decision IDs, doc or workflow paths). The `# File:` header block is a script's interface doc: it may name the paths the script reads or writes and the step that calls it, never a decision ID (`D12`, `G8`, `ADR-…`). Decision IDs and doc paths go in `assetlist.md`, `upstream-lineage.json` or `PROVENANCE.md`.
- Nothing in `.agents/` depends on `tests/`; tests copy `.agents/` into a fixture and run from the copy.
- Vendored skills are frozen: feature work never edits them.
- Vendored skills are temporary references and are never installed into target projects; first-party assets must not depend on them at runtime. Ship a first-party version of anything that affects how agents work; delete the vendored skill once that version exists and its lineage is in `upstream-lineage.json`. Add-ons unrelated to how agents work (anti-slop Oxlint plugins) are installed from upstream at a pinned commit instead of rebuilt.
- Cite upstream in `Sources:` lines as `<repo>/<path>@<sha>` (at least 7 hex), never a vendored path; `upstream-lineage.json` holds the full 40-hex commit.
- Adding, vendoring or removing anything under `.agents/`: update `PROVENANCE.md` in the same change. A first-party asset target projects need also goes in `.agents/install-manifest.txt` (`install.sh` ships only what it lists).
- Every first-party asset derived from upstream (skill, module, reference, agent, hook, script, template) gets an `upstream-lineage.json` entry: `kind` `copy`, `derived` or `pinned-addon`, upstream repo, path and commit, `changes`, `why`, `reviewed_at`. To pick up a vendor update, diff each `upstream_path` from its pinned commit, review with the user, bring in what we want, then update the entry.
- A first-party asset that needs an upstream file at runtime gets a copy in the consuming skill's `references/` with a `Copied from … @ <commit> (<license>). Local edits: …` header and the vendor LICENSE beside it; every reference points at the copy, and it gets a `kind: copy` lineage entry. On an upstream update, apply the accepted changes to the copy (keep its local edits), then update the commit and sha256 in the entry and the copy's header.
- Commit subjects are Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`). Never a `Co-Authored-By` trailer or a mention of an AI assistant; the message reads as written by the developer.
- The README never restates the hooks or scripts tree; point at the folder instead.
- Keep the `.gitignore` workflow marker block in step with `GI_ENTRIES` in `install.sh`; `install.sh` refuses to target this repo, so nothing refreshes it here.

## External systems

## Required versions

- bash: 3.2 or newer; no bash 4 constructs (`declare -A`, `mapfile`, `${x,,}`, `declare -n`, `coproc`, `|&`, `&>>`) (`install.sh:89`, `tests/README.md:7`).
- git, jq: any version (`install.sh:93-94`).
- yq: mikefarah v4, never the Python `yq` (`install.sh:99-100`).
- shellcheck: any version, tests and lint only (`tests/run-all.sh:63`).
