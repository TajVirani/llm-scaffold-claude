# Profile: agent-docs
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 -->

## File locations

- Organised by asset kind under `.agents/`; each skill is self-contained in its folder.
- `.agents/skills/<s>/SKILL.md`: the skill's entry point, the only file at the skill root.
- `.agents/skills/<s>/modules/`: steps loaded on demand. `references/`: disclosed reference material. `assets/`: templates. `agents/openai.yaml`: Codex invocation policy. Never a template outside `assets/`.
- `.agents/agents/<name>.md`: host-neutral sub-agent definitions. Codex tomls are generated from them; never hand-write one.
- `.agents/output-styles/`: output styles.
- New skills, agents, hooks and output styles go in `.agents/`, never directly in `.claude/`; `.claude/` holds only `settings.json` and the `skills`, `agents` and `output-styles` symlinks.
- Root docs: `AGENTS.md` (edit it, never `CLAUDE.md`) and `README.md`.

## Approved libraries per concern

- Writing a skill, sub-agent definition, AGENTS.md or a doc an agent reaches through a pointer: follow the `writing-for-agents` skill. Do not use another style guide.

## Language and style rules

- A skill's or agent's `name` matches its folder or file name.
- Agent frontmatter is exactly `name`, `description`, `tools`; never `model:` (models come from `.workflow/model-map/` and overrides).
- Agent descriptions lead with the role and the workflow step: `<role> (step X.Y)`.
- New agents follow `.agents/skills/writing-for-agents/assets/agent.template.md` (Input / Steps / Return). Existing agents change shape only when touched for another reason.

## Toolchain

```yaml
# Command keys, run by run-toolchain.sh at 3.5 in this order: lint, typecheck, format, boundary, test. Exact command per key; "" when not applicable. e2e is not run at 3.5: the orchestrator runs it at 3.10 via run-toolchain.sh `--e2e` (or the suite command); evidence-capture only collects the artifacts.
lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage"
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
rule_set: "scaffold lint suites (frontmatter, step-list, symlinks, upstream-lineage)"
test_patterns: [] # which paths are tests, kept out of the size-budget file count (budget-check.sh). [] or absent: the defaults
                  # ["*.test.*", "*.spec.*", "__tests__/", "tests/", "test/", "e2e/", "*_test.go", "test_*.py", "*_test.py"]. A list replaces them
                  # for this profile. "dir/" matches that folder at any depth; a pattern with another / matches the repo-relative path; else the file name.
```

## Mini-review checklist

- [ ] Every skill `description` the diff adds or changes carries a trigger clause ("Use when …").
- [ ] A new agent follows the agent template; its description leads with `<role> (step X.Y)`.
