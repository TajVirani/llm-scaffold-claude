# Profile: shell-scripts
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 -->

## File locations

- Organised by owner, not by layer. Depth stops at `.agents/skills/<s>/scripts/<file>`: no subfolders. Code a second skill needs moves to `.agents/lib/`.
- `.agents/lib/`: sourced helpers shared by hooks, skills and `install.sh`. Never an executable entry point.
- `.agents/hooks/`: thin host adapters (`_name.sh` = a sourced helper) and host config templates. Never business logic: call the owning skill's script instead.
- `.agents/skills/<s>/scripts/`: the skill's executable logic. Never sourced by another skill; shared code goes through `.agents/lib/`.
- `install.sh`: the installer. `scripts/`: scaffold maintenance tools, never installed.

## Approved libraries per concern

- JSON: jq. YAML and TOML: mikefarah yq v4. Text: awk and sed. Never python or perl inside a shell script.
- Paths under `.workflow/`: source `.agents/lib/workflow-paths.sh` and build them from its `WF_*` variables with `wf_path`. Never spell `.workflow/` in code.

## Language and style rules

- Script file names are kebab-case → `check-write.sh`. A sourced hook helper starts with `_` → `_guard-common.sh`.
- Functions are lowercase snake_case → `block_state`, each preceded by a usage comment `# name ARGS : what it does`.
- Every script opens with a header block starting `# File: <kind>: <summary>`. Hooks then use `Goals` / `Triggers/inputs` / `Outputs/handoff` / `Wiring` / `Notes`; helper scripts use `Purpose` / `Usage` / `Exit`. Both end with `# Sources:`.
- Executable scripts run under `set -euo pipefail`.
- Errors go through a one-line `die()` that prints `<prog>: <msg>` to stderr. Never swallow an error silently; report it or exit.
- Exit codes: `0` ok, `1` the check found a problem or refused, `2` usage, environment or preflight error, documented in `# Exit:`. Existing scripts keep their codes; changing one updates `# Exit:` and its test in the same change.
- Guard hooks fail closed: on an unparsable payload or a helper error they print the host's deny JSON and exit 0. Non-guard hooks (the stop audit) allow with a warning.
- Resolve sibling paths from `BASH_SOURCE` with `cd -P`, so a path reached through the `.claude/` symlinks resolves into `.agents/`.
- Test syntax: match the file being edited; new files use `[[ ]]`. Never convert a file for style. No line-length limit.
- A shellcheck directive carries its reason after `#` → `# shellcheck disable=SC2016 # expanded by eval`.

## Toolchain

```yaml
# Command keys, run by run-toolchain.sh at 3.5 in this order: lint, typecheck, format, boundary, test. Exact command per key; "" when not applicable. e2e is not run at 3.5: the orchestrator runs it at 3.10 via run-toolchain.sh `--e2e` (or the suite command); evidence-capture only collects the artifacts.
lint: "git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR"
typecheck: ""   # e.g. tsc --noEmit
format: ""      # a check command, e.g. prettier --check .
boundary: ""    # e.g. depcruise --config .workflow/tools/boundaries/dependency-cruiser.cjs src (config generated from .workflow/rules.md)
test: "tests/run-all.sh"
test_scoped: 'tests/run-all.sh --only-file "$WF_TASK_TESTS_FILE" --exclude-file "$WF_EXCLUDE_TESTS_FILE"' # runs in place of test while Phase 1 tests of unfinished tasks are excluded: the task's own suites, or every suite minus the excluded ones when it owns none
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

- [ ] A new `.workflow/` path is built from `workflow-paths.sh`, never spelled out.
- [ ] Hook logic stays thin: real work is in the owning skill's script.
- [ ] Every error path reaches `die()` or the guard's deny output; nothing is silently swallowed.
- [ ] A new or changed exit code matches 0/1/2 and is documented in `# Exit:`.
- [ ] Sibling paths resolve from `BASH_SOURCE` with `cd -P`.
- [ ] The header block has the shape for its kind (hook or helper) and names no decision ID.
- [ ] New files are kebab-case, run under `set -euo pipefail` and use `[[ ]]`; edited files keep their existing test syntax.
- [ ] Each new function has its `# name ARGS : what it does` line, and each shellcheck directive has its reason.
