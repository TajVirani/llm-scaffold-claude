# Data model: Tier B caches for bash projects

Spec: [spec.md](spec.md) · Placement: regenerate-caches

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Graph JSON (dependency-cruiser shape) | interface | unchanged | regenerate-caches |
| Graph JSON `exports` | field | create | regenerate-caches |
| Graph JSON `dependencies[].line` | field | create (D15) | regenerate-caches |
| Graph extractor script interface | interface | create | regenerate-caches |
| `build-architecture.sh` CLI (`--extractor`, `--print-generator` D14) | interface | extend | regenerate-caches |
| Work profile Toolchain `graph_extractor` | field | create | project-setup (template); each project (its profiles) |
| Tier B frontmatter `generator` | field | extend | regenerate-caches |
| Cache body shapes (`check-staged-cache.sh`) | interface | extend (architecture gains "Unresolved edges", D10) | regenerate-caches |
| Boundary violations section (when depcruise runs, "Not checked" wording) | interface | extend (D16, D17) | regenerate-caches |
| Cache stamp | interface | unchanged | regenerate-caches |

## Entities

### Graph JSON (unchanged shape, one new optional key)

What every **graph extractor** prints on stdout for a scope (D2). `build-architecture.sh`'s canonicalisation (`:166-191`) is its one reader.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `modules` | array | yes | `jq -e '.modules \| type == "array"'` (`build-architecture.sh:162`) | unchanged |
| `modules[].source` | string | yes | Repo-relative path of a file the extractor claims | unchanged |
| `modules[].dependencies[].resolved` | string | yes when resolved | Repo-relative path of an existing file (CAP-NEW-bash-graph-extractor) | unchanged |
| `modules[].dependencies[].couldNotResolve` | bool | no | `true` when the target path cannot be resolved statically; then `resolved` is absent and the edge is not drawn (D3, D9) | unchanged (now used by bash) |
| `modules[].dependencies[].module` | string | yes when unresolved | The source text of the `source` line or call (D9) | unchanged (now used by bash) |
| `modules[].dependencies[].line` | integer | no | 1-based line of the `source` line or call in `source`; rendered in Unresolved edges as `<file>:<line>`, or `<file>` alone when absent (D15) | create |
| `summary.violations` | array | boundary run only | Unchanged; bash has no boundary run | unchanged |
| `exports` | object, path -> string[] | no | Sorted unique function names per sourced file; read for Public interface only when tsc output is absent; a module's interface is the union over its files (D6, D9, D11) | create |

**Invalid states ruled out:** an edge to a guessed path cannot be represented: a dependency either has an existing `resolved` file or is `couldNotResolve`. Still representable: two extractors claiming the same file (duplicate `source`); the merge rejects it as an error.

### Graph extractor script (create)

`.agents/skills/regenerate-caches/scripts/extractors/<name>.sh` (D1). Contract: `<name>.sh --root DIR --scope PATH...` prints Graph JSON for the files it claims under the scopes; exit 0 on success (an empty `modules` is valid), 2 on usage or tool error, with the missing tool named on stderr. `<name>` is the `graph_extractor` value. Shipped: `dependency-cruiser`, `bash`.

### Work profile Toolchain `graph_extractor` (create)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `graph_extractor` | string | yes | `none` or the name of a script in `scripts/extractors/`; missing key is a breaking-change error naming the profile and the line to add (D5, D8) | create |

### Tier B frontmatter `generator` (extend)

Still a free-text string (`cache-frontmatter.md:23`); now the sorted, comma-joined names of the extractors that produced the graph (spec Assumptions).

### architecture.md body (extend)

Sections become `Module graph`, `Edges`, `Boundary violations`, `Unresolved edges`, in that order (D10). Unresolved edges: sorted bullets `` - `<file>:<line>` `<source text>` `` (`<file>` alone when the edge has no `line`, D15), or `None.`. `check-staged-cache.sh` accepts the section and checks it is sorted.

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | Shipped profile TEMPLATE and examples gain `graph_extractor` | extend | yes | - | none |
| M2 | Target projects add `graph_extractor` to each profile (breaking: the build errors until they do) | extend | yes (remove the key and downgrade) | M1 | Manual, guided by the error message (D8); no automatic edit |
| M3 | This repo's three profiles gain `graph_extractor` (`bash` for shell-scripts and test-harness, `none` for agent-docs) via proposals.md at 5.3 | extend | yes | M1 | none |
| M3b | Published architecture caches gain the "Unresolved edges" section on their next regeneration; an old cache without it still validates until then | extend | yes | - | Regenerated, never edited |
| M4 | This repo's three caches are built and published at 5.3 | create | yes (delete `.workflow/cache/*.md`) | M3 | none |

### Boundary violations section (extend)

The depcruise boundary check runs only when `.workflow/tools/boundaries/dependency-cruiser.cjs` exists and a work profile selects `dependency-cruiser`, or with `--violations-json`; under `--from-json` it runs whenever the config exists (D16). When no selected extractor has a boundary checker the section reads `Not checked: no boundary checker for this project's graph extractors (<names>).`, `<names>` being the `--print-generator` list or `none`; with `dependency-cruiser` selected and no config, today's `Not checked: no boundary config at ...` line stays (D17). Both forms stay valid for `check-staged-cache.sh`.
