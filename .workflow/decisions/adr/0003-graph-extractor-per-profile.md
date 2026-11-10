---
status: superseded by ADR-0006
---

# Graph extractor per work profile, one graph format

The Tier B caches could only be built for JS/TS code, because `build-architecture.sh` ran dependency-cruiser as the only parser. We let each work profile name its graph extractor with a required `graph_extractor` key (`bash`, `dependency-cruiser` or `none`). Every extractor is one script, `regenerate-caches/scripts/extractors/<name>.sh --root DIR --scope PATH...`, that prints dependency-cruiser's JSON shape; `build-architecture.sh` runs the ones the profiles name, merges their graphs and stays the one reader of that shape. A profile without the key is a breaking-change error that names the profile and the line to add, not a silent default. Only `--from-json` skips the profiles; `--extractor NAME` overrides which extractor runs but still requires the key.

## Considered Options

- A graph format of our own, with dependency-cruiser translated into it: one more format to keep in step, and no gain while dependency-cruiser's shape already carries files, resolved and unresolved edges.
- Detecting the language from the files instead of a profile key: a guess per file, and no place for a project to say a work type has no code graph.
- Defaulting a missing key to `dependency-cruiser`: keeps old JS/TS projects quiet, but a bash project would then fail with a misleading "depcruise not found".

## Consequences

- A new language is one new extractor script plus its tests; the canonicalisation and the three renderers do not change.
- Every target project must add `graph_extractor` to each profile before its next cache build; the error message tells it how.
- The generator name a cache records is the sorted, comma-joined list the profiles select, read with `build-architecture.sh --print-generator`.
- An extractor reports a path it cannot resolve as `couldNotResolve` (with an optional `line`), never a guessed edge; architecture.md lists them under Unresolved edges.
