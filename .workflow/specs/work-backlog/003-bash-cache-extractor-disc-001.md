---
origin_spec: .workflow/specs/done/003-bash-cache-extractor
origin_step: "3.4"
discovered_at: 2026-10-23
status: open
kind: bug
---

# No architecture cache when every profile names no graph extractor

## Problem

When every work profile sets `graph_extractor: none`, `build-architecture.sh --print-generator` prints an empty line, and `publish-cache.sh` rejects an empty `--generator`. So an architecture cache cannot be published for such a project. The regenerate-caches skill now skips architecture in that case and reports `failed: no graph extractor`; what the cache should hold then (no cache, an empty graph with a fixed generator name, or a clear "not applicable" status) is undecided.

## Evidence

- `.agents/skills/regenerate-caches/scripts/publish-cache.sh:68` rejects an empty `--generator`.
- T5 implementation result, `.workflow/specs/done/003-bash-cache-extractor/artifacts/T5/implementation.yaml`: "If every work profile names `none`, `--print-generator` prints an empty line, and `publish-cache.sh:68` rejects an empty `--generator`."

## Why not a blocker

Both capabilities' success lines and journeys JRN-001 to JRN-005 use profiles that name `bash` or `dependency-cruiser`; a project whose profiles all name `none` has no code graph to cache. CAP-NEW-selectable-graph-extractor and CAP-NEW-bash-graph-extractor are unaffected.

## Suggested scope and size

- Scope: decide the all-`none` outcome and make `build-architecture.sh`, `publish-cache.sh`, `cache-stamp-check.sh` and the regenerate-caches skill agree on it; leave extractor behaviour alone.
- Size: 1-2 tasks in regenerate-caches (and possibly feature-workflow discovery 0.2.7/0.2.8), well under the default budget of 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../done/003-bash-cache-extractor/spec.md)
- Design log entry: [design-log.md](../done/003-bash-cache-extractor/design-log.md) (section 2026-10-23 Discovered work: all-none-no-architecture)
