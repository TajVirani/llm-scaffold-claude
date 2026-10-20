<!--
File: Template for .workflow/profiles/TEMPLATE.md and every .workflow/profiles/<work-type>.md. Copy it, fill every section, delete this comment.
Contract: the five headings below and the yaml keys under Toolchain (command keys lint, typecheck, format, boundary, test, e2e, optional test_scoped; descriptive keys serve, serve_ready, e2e_report, config, rule_set) are extracted by scripts (resolve-launch.sh, run-toolchain.sh, evidence-capture.sh) and the mini-review agent. Keep the heading text and key names exactly.
Injection: the whole file is prepended to the implementing agent's launch (00.20); only "Mini-review checklist" goes to the mini-review.
Line test: a line stays only if removing it would change what the agent does. A prohibition names the permitted alternative. Anything that would appear identically in every profile belongs in .workflow/rules.md.
Sources: first-party (assetlist D13, D15, D19, D26; plan 00.16, 00.17, 00.19); line test and "conventions that differ from defaults" adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/references/{template,best-practices}.md (MIT).
-->
# Profile: {work-type}

## File locations

- {Kind of artifact}: `{path}`. Never in `{path}`.

## Approved libraries per concern

- {Concern, e.g. validation}: {library}. Do not add another.

## Language and style rules

- {Strictness setting, banned construct and its alternative, naming, error handling}

## Toolchain

```yaml
# Command keys, run by run-toolchain.sh at 3.5 in this order: lint, typecheck, format, boundary, test. Exact command per key; "" when not applicable. e2e is not run at 3.5: the orchestrator runs it at 3.10 via run-toolchain.sh `--e2e` (or the suite command); evidence-capture only collects the artifacts.
lint: ""        # e.g. oxlint -c .oxlintrc.json
typecheck: ""   # e.g. tsc --noEmit
format: ""      # a check command, e.g. prettier --check .
boundary: ""    # e.g. depcruise --config .workflow/tools/boundaries/dependency-cruiser.cjs src (config generated from .workflow/rules.md)
test: ""        # REQUIRED (never ""); the unit/integration suite, also the 3.9 harness gate (D61), e.g. npx vitest run --coverage
test_scoped: "" # optional; runs in place of test while Phase 1 tests of unfinished tasks are excluded (D85): $WF_EXCLUDE_TESTS / $WF_EXCLUDE_TESTS_FILE hold their selectors (space-separated / one per line), $WF_TASK_TESTS / $WF_TASK_TESTS_FILE this task's own, plus $WF_TASK_ID and $WF_IMPL_BASE. Without it a failing test is recorded `unscoped` (a warning, not a failure). e.g. npx vitest run $(sed "s/^/--exclude /" "$WF_EXCLUDE_TESTS_FILE")
e2e: ""         # run at 3.10 by the orchestrator (run-toolchain.sh --e2e); empty outside e2e work types, e.g. npx playwright test
# Descriptive keys (not commands; run-toolchain.sh never runs them):
serve: ""       # start command for the built app, used by review-targets (4.3, D62), e.g. npm run start
serve_ready: "" # URL polled until the app answers, e.g. http://localhost:3000
# e2e_report: "test-results/e2e-results.json"  # e2e work types only: path to the Playwright JSON report (json reporter outputFile), relative to the run directory; read by evidence-capture
config:         # config file path per tool
  lint: ""
  typecheck: ""
rule_set: ""    # name the rules in force, e.g. vendored anti-slop rules plus project rules
```

## Mini-review checklist

<!-- Only what the toolchain cannot express and a reader must judge. One line each. Delete a line once a tool rule covers it. -->

- [ ] {Judgement item, e.g. error path matches how this domain reports failures}
