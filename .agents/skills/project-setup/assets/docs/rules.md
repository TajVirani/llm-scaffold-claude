<!--
File: Template for .workflow/rules.md (Tier A rules). Copied by project-setup; read at 0.3.3, 2.4, 4.1; changed only at 5.3.
Contract: the headings "Ownership", "Shared core" and "Size budget" are fixed, and each holds exactly one fenced `yaml` block (parsed with mikefarah yq v4). "Workflow settings" is optional; when present it holds one fenced `yaml` block too, and a missing section or key takes the default shown. Prose in those sections is commentary, not source. The rules are tool-neutral: no boundary-tool syntax in the blocks.
Line test: a line stays only if removing it would change what an agent does. Prohibitions name the permitted alternative. Delete this comment when filling.
-->
# Rules

## Ownership

Each module owns paths and may depend only on the modules it lists. Anything not listed is forbidden.

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
modules: {}
```

## Shared core

Shared core changes only through the integration agent, between batches. Every module may depend on shared core. Shared core may not depend on any module.

```yaml
# shared_core.paths: globs (same glob syntax as above) for code every module may use.
# Adapter mapping: each module is allowed to import it (no rule emitted), and one rule per module N emits
#   { name: "shared-core-not-to-<N>", severity: "error", from: { path: <shared_core.paths> }, to: { path: <owns(N)> } }
# The integration agent treats any diff touching these paths as a shared-core change.
shared_core:
  paths: []
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

- {Rule that holds project-wide. Never X; use Y.}

## External systems

- {System}: {how it is reached, which module owns the integration, constraint.}

## Required versions

- {Tool or runtime}: {version, from the file that declares it.}
