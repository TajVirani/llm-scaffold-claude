# T02: Flow entry candidates read test files through the shared helper

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately; needs the wave-1 integration batch merged first) · Parallel with: None

**What to build:** `build-architecture.sh` loads the profiles' `test_patterns` and decides which files are tests through `.agents/lib/test-paths.sh`, so the flow entry candidates and the size budget agree on test files. It keeps no copy of the defaults, the loader or the matcher. The entry-candidate JS regex stays unchanged as an extra filter (D8).

**Seam:** `build-architecture.sh --cache entries` on the test-pattern profiles fixture, and the `wf_default_test_patterns` / `wf_load_test_patterns` / `wf_is_test_path` functions sourced in `tests/scripts/lib-test-paths.sh`.

**Acceptance criteria:**

- [ ] build-architecture sources `.agents/lib/test-paths.sh` and holds no default list, loader or `is_test_file` matcher; `git grep -l -F '*_test.go' -- '.agents/*.sh'` lists only `.agents/lib/test-paths.sh` once T01 is merged (TGT-004).
- [ ] For each profile shape in the fixture, `--cache entries` drops the same test files as budget-check counts in `test_files`.
- [ ] An invalid `test_patterns` still exits 2 with build-architecture's own message; the empty-Toolchain-block guard now applies here too (spec Assumptions).
- [ ] The JS regex line is byte-identical to the baseline.
- [ ] `tests/scripts/lib-test-paths.sh` passes once T01 is also merged (its grep case needs both); `tests/scripts/build-architecture.sh` still passes; shellcheck clean.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/build-architecture.sh`

**Phase 1 tests:** `tests/scripts/lib-test-paths.sh`

**Size:** S (1 file, about 80 changed lines).

**Mode:** afk.

**Notes:** Shared-core request (touches_core), for the integration batch before wave 1: `.agents/lib/test-paths.sh`, replacing the Phase 1 stubs. `wf_default_test_patterns` prints the default list one per line (`*.test.*`, `*.spec.*`, `__tests__/`, `tests/`, `test/`, `e2e/`, `*_test.go`, `test_*.py`, `*_test.py`). `wf_load_test_patterns <profiles_dir>` reads every profile's Toolchain `test_patterns` (skipping TEMPLATE.md), merges, sorts and prints the list; `[]` or absent means the defaults; it keeps budget-check's empty-Toolchain-block guard; on an invalid value it returns 1 and prints the message, never exits. `wf_is_test_path <path>` reads the list from `WF_TEST_PATTERNS` and returns 0 for a test path, 1 otherwise, by the three rules (`dir/` at any depth; a pattern with another `/` against the repo-relative path; else the file name). Behaviour is the union of today's copies (`budget-check.sh:60-68,155-170`, `build-architecture.sh:518-580`); the yq v4 check stays in each caller. Pinned by `tests/scripts/lib-test-paths.sh`.
