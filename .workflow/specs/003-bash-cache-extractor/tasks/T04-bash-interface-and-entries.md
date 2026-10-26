# T04: Bash functions and test exclusion in modules and entries

Index: [../tasks.md](../tasks.md) · Blocked by: T2 (Unresolved edges in architecture), T3 (Bash graph extractor) · Parallel with: None

**What to build:** Without tsc output, a module's Public interface comes from the graph's `exports`: the sorted union of its files' functions, rendered `` - `name` (function) `` (D11); a module with no sourced file keeps `Not generated: ...`. Entry candidates also drop files matching any profile's Toolchain `test_patterns` (D13); the JS/TS rule stays. A bash project then gets all three caches end to end.

**Seam:** build-architecture.sh --cache modules and --cache entries output.

**Acceptance criteria:**

- [ ] JRN-001: a bash fixture project renders architecture, modules and entries with edges, unresolved edges, lib functions as Public interface and no test file as an entry, and both bodies pass `check-staged-cache.sh`.
- [ ] JRN-004: bash, dependency-cruiser and none profiles merge into one graph and `--print-generator` prints `bash,dependency-cruiser`.
- [ ] tsc-derived Public interface output is unchanged when tsc output exists.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/build-architecture.sh`

**Phase 1 tests:** `tests/scripts/cache-bash-project.sh`, `tests/scripts/cache-mixed-extractors.sh`

**Size:** S (1 files, about 80 changed lines).

**Mode:** afk.

**Notes:** Overlap with T2 on `build-architecture.sh` is settled by an edge.
