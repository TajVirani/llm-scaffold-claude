---
status: accepted
---

# Remove the Tier B caches

The generated caches (`modules.md`, `flows.md`, `architecture.md`) and everything that built and guarded them are removed: the `regenerate-caches` skill, the `cache-regeneration` agent, the graph extractors, the Tier B write guard and its deny rule, discovery steps 0.2.7 and 0.2.8, and their tests. This repo's caches were 297 commits behind HEAD and spec 00014 recorded them as wrong, and the other projects that run the workflow kept none, so about 3,900 lines bought nothing a reader trusted. The retrieval agent reads the code and Tier A directly, and the `pr-quality` seam check reads the `rules.md` ownership block and the code.

Supersedes [ADR-0003](./0003-graph-extractor-per-profile.md).

## Consequences

- Work profiles no longer carry a `graph_extractor` key; a new language needs no extractor script.
- Discovery's context comes only from sub-agent reads of the code and Tier A, so a stale generated summary can no longer reach `codebase-map.md`.
