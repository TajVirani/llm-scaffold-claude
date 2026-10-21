# Profile: test-harness
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 -->

## File locations

- One suite per component, grouped by the kind of component it tests; fixtures are built at run time, never committed.
- `tests/lib/common.sh`: shared helpers only. Never a test.
- `tests/hooks/<hook>.sh`, `tests/scripts/<script>.sh`, `tests/lint/<check>.sh`: one suite per component, named after it.
- `tests/README.md`: the suite table; add the row when you add a suite.
- Fixtures: a `mktemp` dir from `new_workdir`, removed on exit; components run from a copy of `.agents/` inside it. Never absolute or home paths, and never a write to the repo.

## Approved libraries per concern

- Assertions and fixtures: `tests/lib/common.sh` (`t`, `eq`, `check`, `skip`, `xfail`, `new_workdir`, `shellcheck_files`). Not bats.

## Language and style rules

- A suite opens with `# Suite:` and `# Covers:`, sources `lib/common.sh`, calls `preflight`, and ends with `finish`.

## Toolchain

```yaml
# Command keys, run by run-toolchain.sh at 3.5 in this order: lint, typecheck, format, boundary, test. Exact command per key; "" when not applicable. e2e is not run at 3.5: the orchestrator runs it at 3.10 via run-toolchain.sh `--e2e` (or the suite command); evidence-capture only collects the artifacts.
lint: "git ls-files -z -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR"
typecheck: ""   # e.g. tsc --noEmit
format: ""      # a check command, e.g. prettier --check .
boundary: ""    # e.g. depcruise --config .workflow/tools/boundaries/dependency-cruiser.cjs src (config generated from .workflow/rules.md)
test: "tests/run-all.sh"
test_scoped: "" # optional; runs in place of test while Phase 1 tests of unfinished tasks are excluded: $WF_EXCLUDE_TESTS / $WF_EXCLUDE_TESTS_FILE hold their selectors (space-separated / one per line), $WF_TASK_TESTS / $WF_TASK_TESTS_FILE this task's own, plus $WF_TASK_ID and $WF_IMPL_BASE. Without it a failing test is recorded `unscoped` (a warning, not a failure). e.g. npx vitest run $(sed "s/^/--exclude /" "$WF_EXCLUDE_TESTS_FILE")
e2e: ""         # run at 3.10 by the orchestrator (run-toolchain.sh --e2e); empty outside e2e work types, e.g. npx playwright test
# Descriptive keys (not commands; run-toolchain.sh never runs them):
serve: ""       # start command for the built app, used by review-targets (4.3), e.g. npm run start
serve_ready: "" # URL polled until the app answers, e.g. http://localhost:3000
# e2e_report: "test-results/e2e-results.json"  # e2e work types only: path to the Playwright JSON report (json reporter outputFile), relative to the run directory; read by evidence-capture
config:         # config file path per tool
  lint: ""
  typecheck: ""
rule_set: "shellcheck defaults"
test_patterns: [] # which paths are tests, kept out of the size-budget file count (budget-check.sh). [] or absent: the defaults
                  # ["*.test.*", "*.spec.*", "__tests__/", "tests/", "test/", "e2e/", "*_test.go", "test_*.py", "*_test.py"]. A list replaces them
                  # for this profile. "dir/" matches that folder at any depth; a pattern with another / matches the repo-relative path; else the file name.
```

## Mini-review checklist

- [ ] External tools and network are stubbed (stubs on PATH, recorded payloads, `file://` upstreams); no live network call.
- [ ] A new or changed script has a suite ending in a `shellcheck_files` assertion over its components.
- [ ] Fixtures stay inside the `new_workdir` temp dir; no committed fixture, absolute or home path.
