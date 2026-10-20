<!--
File: Example filled profile for work type `test-harness`: Phase 1.2 harness and CI checks, unit and integration tests.
Use: project-standards offers its lines as candidate answers in the interview (coverage C1, C3, C4) for <project>/.workflow/profiles/test-harness.md; it is never copied in whole. Adopted lines are adapted to the project; this comment and the banner never reach the project.
Stack: Vitest, tsc, oxlint + vendored anti-slop, oxfmt (Prettier variant noted), dependency-cruiser.
-->
# Profile: test-harness

> **Example: adapt before use.** Every path, command and threshold below is a starting point for a TS/JS project on the example stack (Vitest, tsc, oxlint, oxfmt, dependency-cruiser). Check each line against the project, change what differs, then delete this banner.

## File locations

- Unit tests: next to the module they test, as `src/<module>/<name>.test.ts`. Never in a top-level `__tests__/` tree.
- Integration tests (more than one module, or a real adapter such as an in-memory database): `src/<module>/<name>.integration.test.ts`. Never in `e2e/`, which belongs to the `e2e-browser` profile.
- Fakes and in-memory adapters: `src/<module>/testing/`, exported only to tests. Never inside a test file when two test files need them.
- Fixtures and oracles from `verification-plan.md` ("Fixtures and oracles"): `test/fixtures/<fixture-name>.ts` (or `.json`). Never inline the same fixture in two tests.
- Interface stubs for a new module (1.2): the real module path from `codebase-map.md`, `src/<module>/index.ts`, returning a fixed placeholder value. Never a throwing stub, which fails on an error instead of an assertion.
- Vitest config: `vitest.config.ts` at the project root. CI check: `.github/workflows/test.yml` (or the project's existing CI file), job `test`.
- Machine-readable results for evidence: `--reporter=json --outputFile=.workflow/specs/NNN-slug/artifacts/<id>/harness.json`. Never rely on the default `.vitest/json/` path.

## Approved libraries per concern

- Test runner and assertions: `vitest` (`describe`, `it`, `expect`). Do not add Jest, Mocha or Chai.
- Coverage: `@vitest/coverage-v8` with `test.coverage.provider: 'v8'`. Do not add istanbul or c8.
- Test doubles: hand-written fakes at a seam the module owns, or `vi.fn()` for a callback argument. Module mocking (`vi.mock`, `vi.doMock`) is banned; anti-slop `no-module-mocking` enforces it.
- Time: `vi.useFakeTimers()` and `vi.setSystemTime()`. Do not add a date-mocking library.
- DOM-level component tests, if the project has them: `@testing-library/dom` (or the framework binding the project already uses) with `jsdom` as the Vitest environment for those files only. Browser journeys belong to `e2e-browser`.
- Mutation testing (optional at 1.4): `@stryker-mutator/core` with `@stryker-mutator/vitest-runner`. Do not add another mutation tool.

## Language and style rules

- TypeScript `strict: true` applies to test files too; `tsconfig.json` includes `src/**/*.test.ts`. Use a typed fixture builder instead of `as` casts in test data.
- One behaviour per `it`. Name it as behaviour plus condition: `it('rejects an expired card')`, not `it('validateCard')`.
- Import the module under test through its public entry (`src/<module>/index.ts`), never a file inside another module (the `boundary` key checks cross-module imports).
- Assert results and observable state with `expect(...).toEqual` / `toThrow` / `rejects.toThrow`. Use `toHaveBeenCalledWith` only for a callback the module's interface accepts, never for internal call order.
- No `it.only`, `describe.only` or `it.skip` in committed code; a deferred test is `it.todo('<behaviour>')` with the reason in the test name.
- Coverage thresholds live in `vitest.config.ts` (`test.coverage.thresholds: { lines, functions, branches, statements }`) and match the coverage target in `verification-plan.md` (1.1). Never lower a threshold to get green; that is a 5.3 proposal.
- Async tests `await` every promise they start; no floating promises and no `done` callbacks.

## Toolchain

```yaml
# Command keys, run by run-toolchain.sh at 3.5 in this order: lint, typecheck, format, boundary, test. e2e is empty: this is not an e2e work type.
lint: "npx oxlint -c .oxlintrc.json --deny-warnings"
typecheck: "npx tsc --noEmit -p tsconfig.json"
format: "npx oxfmt --check"          # Prettier variant: "npx prettier --check ."
boundary: "npx depcruise --config .workflow/tools/boundaries/dependency-cruiser.cjs --output-type err-long src"
test: "npx vitest run --coverage"    # the harness; also the 3.9 gate. Coverage thresholds in vitest.config.ts fail the run.
test_scoped: 'npx vitest run $(sed "s/^/--exclude /" "$WF_EXCLUDE_TESTS_FILE")'   # runs in place of test while other tasks' Phase 1 tests are excluded (3.5, 3.9); selectors are test file paths or globs. No --coverage: thresholds apply to the full run, which has nothing to exclude.
e2e: ""
# Descriptive keys (not commands; run-toolchain.sh never runs them):
serve: ""                            # the harness needs no running app
serve_ready: ""
config:
  lint: ".oxlintrc.json"
  typecheck: "tsconfig.json"
  format: ".oxfmtrc.json"
  boundary: ".workflow/tools/boundaries/dependency-cruiser.cjs"
  test: "vitest.config.ts"
rule_set: "oxlint defaults + vendored anti-slop (all generic rules at error, plus oxc/no-accumulating-spread) + project rules"
```

## Mini-review checklist

- [ ] Each test asserts observable behaviour through the module's public interface, not private state or call order.
- [ ] Each new test was seen failing for the right reason (an assertion message, not an import or setup error) before the code made it pass.
- [ ] Test names state the behaviour and its condition ("rejects an expired card"), not the function under test.
- [ ] Fixtures come from the verification-plan "Fixtures and oracles" table; no hand-typed expected values without a named oracle.
- [ ] Tests at a system boundary use a fake or in-memory adapter at a seam the module owns; module mocking is not reintroduced through another API (anti-slop `no-module-mocking` covers `vi.mock`).
- [ ] Coverage gaps on new branches are deliberate and named, not hidden by `/* v8 ignore */`.
- [ ] Negative and edge cases (3.4) cover the error path the module's convention defines (thrown error type, `Result` value or rejected promise), not just the happy path.
