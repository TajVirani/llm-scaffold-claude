# T01: Graph extractor per work profile

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `build-architecture.sh` stops running depcruise inline. It reads `graph_extractor` from every `.workflow/profiles/*.md` Toolchain block (skipping `TEMPLATE.md`), runs each named extractor from `scripts/extractors/<name>.sh --root DIR --scope PATH...` (skipping `none`), checks each output has `.modules` as an array, and merges the graphs before today's canonicalisation. Today's depcruise lookup and call move unchanged into `extractors/dependency-cruiser.sh`, replacing the Phase 1 stub. The boundary-violations depcruise run stays as it is.

**Seam:** build-architecture.sh CLI (profile resolution, --extractor, --print-generator, --from-json) and the extractors/dependency-cruiser.sh contract.

**Acceptance criteria:**

- [ ] A profile without `graph_extractor` makes the build exit 2 with a message that says it is a breaking change, names the profile and gives the line to add; `--extractor NAME` still requires the key and only overrides which extractor runs; `--from-json` bypasses profile resolution (D5, D12).
- [ ] An unknown extractor name exits 2 naming it.
- [ ] `--print-generator` prints the sorted, comma-joined names of the extractors the profiles select, `none` left out, and exits 0 (D14).
- [ ] Two extractors claiming the same `source` file exit 2 naming the file, with no body printed.
- [ ] `extractors/dependency-cruiser.sh` keeps today's flags, tool lookup order and `depcruise failed:` message byte for byte, exits 2 on depcruise failure and on missing arguments.
- [ ] `yq` is checked as a tool requirement when profiles are read; fatal messages no longer claim dependency-cruiser produced a graph it did not.
- [ ] The header and `--help` describe the extractors, the new flags and the profile key.
- [ ] Existing `tests/scripts/build-architecture.sh` cases still pass (they use `--from-json`).

**Predicted files:** `.agents/skills/regenerate-caches/scripts/build-architecture.sh`, `.agents/skills/regenerate-caches/scripts/extractors/dependency-cruiser.sh`

**Phase 1 tests:** `tests/scripts/cache-missing-extractor-key.sh`

**Size:** M (2 files, about 220 changed lines).

**Mode:** afk.

**Notes:** The profile reader is a small awk + yq read of the Toolchain block inside this script, as `budget-check.sh` does; no shared-core change. `scripts/extractors/` conflicts with the shell-scripts profile's no-subfolder line: P1 in proposals.md covers it at 5.3, so it is not a mini-review finding.
