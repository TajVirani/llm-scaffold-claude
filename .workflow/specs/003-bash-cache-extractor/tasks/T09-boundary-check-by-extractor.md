# T09: Boundary check only when a profile selects dependency-cruiser

Index: [../tasks.md](../tasks.md) · Blocked by: T1, T2, T4 (done; same files) · Parallel with: None

**What to build:** In `build-architecture.sh`, `render_boundary_violations` runs depcruise against `.workflow/tools/boundaries/dependency-cruiser.cjs` only when that file exists and some work profile selects `dependency-cruiser` (D16). `--violations-json` still overrides. With `--from-json` no profiles are read (D12), so the check keeps today's rule and runs when the config exists. When no selected extractor has a boundary checker, Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (<names>).`, `<names>` being the `--print-generator` value or `none` (D17). When `dependency-cruiser` is selected and the config is missing, today's `Not checked: no boundary config at ...` line stays. The architecture stamp scope is unchanged (D18).

**Seam:** `build-architecture.sh --cache architecture` output (the Boundary violations section).

**Acceptance criteria:**

- [ ] A bash-only project with a committed boundary config never runs depcruise, and Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (bash).`; the body passes `check-staged-cache.sh` (JRN-006 run 1).
- [ ] With a profile naming `dependency-cruiser` and the config present, depcruise runs and its violations are listed (JRN-006 run 2).
- [ ] `--violations-json` and `--from-json` behave as before.
- [ ] Existing `tests/scripts/build-architecture.sh` cases still pass, updated only where they assert the old "Not checked" wording for a project without `dependency-cruiser`.
- [ ] The header comment of `build-architecture.sh` (lines 45-46) states the new rule.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/build-architecture.sh`, `tests/scripts/build-architecture.sh`

**Phase 1 tests:** `tests/scripts/cache-boundary-check.sh` (JRN-006).

**Size:** S (2 files, about 40 changed lines).

**Mode:** afk.

**Notes:** A failed depcruise run rendering `None.` is out of scope: filed as [work-backlog/003-bash-cache-extractor-disc-004.md](../../work-backlog/003-bash-cache-extractor-disc-004.md).
