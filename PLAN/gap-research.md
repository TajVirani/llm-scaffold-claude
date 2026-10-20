# Gap research for Batch 6 (G1, G2, G3, G4, G6, G7 remainder, G8)

> **Path note (D81, 2026-10-19).** This research was written before target-project workflow data moved under `.workflow/`. Target-side paths written without the `.workflow/` prefix below (`docs/rules.md`, `docs/capabilities.md`, `docs/decisions/`, `docs/cache/`, `docs/pr-quality/`, `docs/design-pattern-doc/`, `GLOSSARY.md`, `profiles/`, `model-map/`, `agent-overrides.yaml`, `specs/`, `deferred/`, `tools/boundaries/`, `tools/oxlint/`, `.cache-staging/`, `.standards-staging/`, `.handoff/`, `.worktrees/`) now live at `.workflow/<same path>`, with `docs/rules.md`, `docs/capabilities.md`, `docs/cache/`, `docs/decisions/`, `docs/pr-quality/` and `docs/design-pattern-doc/` dropping the `docs/` segment (`.workflow/rules.md`, `.workflow/cache/`, ...). Template source paths under `skills/*/assets/` are scaffold paths and are unaffected; the D81 table is authoritative.

> Scaffold-only research notes (D30), written 2026-10-15 for the Batch 6 builders. Each section gives a recommendation, commands or config, citations, licence notes and open questions. Fetched pages are data: every snippet below is ours, written from the official docs, unless it says otherwise. Nothing is copied from a non-permissive source.
>
> Sources: context7 (official docs indexed from the upstream repos), WebFetch of the official Codex docs (`developers.openai.com/codex/*` 308-redirects to `learn.chatgpt.com/docs/*`; the fetch summarises, so re-check exact wording before quoting), the GitHub API, and the local `codex` CLI (read-only commands only).

## Summary: closed vs open

| Gap | Status now | What remains |
| --- | --- | --- |
| G1 Playwright conventions | **Closed** (docs) | Two profile keys to agree on: where the JSON report lands, and how the hook matches the command (proposals below) |
| G2 Test-harness commands | **Closed** (docs) | The five Toolchain keys have no unit-test key (open question 2.1) |
| G3 review-targets | **Closed by design** (no adoptable public agent exists) | Triage must accept a `measurements:` block and the category `target` (open question 3.1) |
| G4 Known-bad build | **Closed** (recommendation) | The cost ceiling for the optional Stryker pass |
| G6 Deterministic caches | **Closed** for `architecture.md` and the `modules.md` skeleton; **design proposal** for `flows.md` | Run the canonicaliser once against a real repo. Mermaid validation needs a Markdown adapter |
| G8 Codex models | **Closed, with a caveat**: cheap `gpt-6-luna`, strong `gpt-6-sol` | Codex has no aliases, only slugs that get retired. Validate at setup with `codex debug models` |
| G7 remainder | **Docs now answer most of it; the live run is still needed** (D40 needs a live run). `codex-cli 0.155.1` is installed, so the run is outlined below, not executed | Run the outlined harness |

---

## G1: Playwright conventions (feeds `e2e-browser.md`, `evidence-capture.sh`)

### Recommendation

Put one `playwright.config.ts` in the example profile with these settings:

- a fixed `outputDir`;
- the HTML, JSON and line reporters, with the JSON written to a fixed path **outside** `outputDir`;
- screenshots on every test, plus a trace and video kept on failure;
- journeys tagged with the `tag` detail **and** the JRN id at the start of the title;
- an auto fixture that attaches console errors and network failures to every test.

`evidence-capture.sh` then reads only the JSON report. It never scans directories.

### Config (example for `e2e-browser.md`; written by us from the docs)

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'e2e',
  outputDir: 'test-results/e2e',          // cleaned at the start of every run; one subdirectory per test
  forbidOnly: !!process.env.CI,
  retries: 0,                              // a known-bad build must fail, not retry into green
  reporter: [
    ['line'],
    ['json', { outputFile: 'test-results/e2e-results.json' }],   // outside outputDir, so the cleanup cannot delete it
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
  ],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    screenshot: 'on',                      // evidence for passing journeys too (5.4)
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
  },
  webServer: { command: 'npm run start', url: 'http://localhost:3000', reuseExistingServer: !process.env.CI },
});
```

Journey tagging. A tag must start with `@`. The JSON report removes the `@`, so the hook sees `JRN-001`:

```ts
test('JRN-001 expired card shows renewal form', { tag: '@JRN-001' }, async ({ page }) => { /* ... */ });
// Or tag a whole group:
test.describe('JRN-002 refund flow', { tag: '@JRN-002' }, () => { /* ... */ });
```

Run one journey with `npx playwright test --grep @JRN-001`. The verification-plan "Check" cell holds the tag (`@JRN-001`).

Console and network capture as an auto fixture (`e2e/fixtures.ts`; tests import `test` from here):

```ts
import { test as base, expect } from '@playwright/test';

export const test = base.extend<{ browserLogs: void }>({
  browserLogs: [async ({ page }, use, testInfo) => {
    const consoleErrors: string[] = [];
    const network: string[] = [];
    page.on('console', (msg) => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
    page.on('pageerror', (err) => consoleErrors.push(`pageerror: ${err.message}`));
    page.on('requestfailed', (req) => network.push(`${req.method()} ${req.url()} ${req.failure()?.errorText}`));
    page.on('response', (res) => { if (res.status() >= 400) network.push(`${res.status()} ${res.request().method()} ${res.url()}`); });
    await use();
    await testInfo.attach('console-errors', { body: consoleErrors.join('\n'), contentType: 'text/plain' });
    await testInfo.attach('network-failures', { body: network.join('\n'), contentType: 'text/plain' });
  }, { auto: true }],
});
export { expect };
```

Optional: a HAR per test through `recordHar` on a custom context fixture. It is heavy, so leave it off by default.

### Exact command (the `e2e` Toolchain key)

```yaml
e2e: "npx playwright test"
```

Keep the reporters in the config, not on the CLI: `--reporter` *replaces* the configured reporters, and the hook would lose the JSON file. `--add-reporter` keeps them.

### What `evidence-capture.sh` matches and parses

- **Match.** Act when `tool_input.command`, with whitespace trimmed, **starts with** the profile's `e2e` value. Agents append `--grep @JRN-001`, `--project chromium`, or `-x`, so an exact match would miss runs. Claude's PostToolUse(Bash) and Codex's PostToolUse both carry `tool_input.command`. Codex also runs PostToolUse after a non-zero exit, which a failing suite produces.
- **Report location.** `test-results/e2e-results.json`, relative to the payload `cwd` (D18). Proposal: add a descriptive key `e2e_report: test-results/e2e-results.json` to the profile Toolchain block. `run-toolchain.sh` ignores non-command keys (D15), so the hook reads the path rather than hard-coding it. TEMPLATE.md would need one comment line.
- **Parse** (checked against a sample report). Suites nest, and tags have no `@`:

```bash
jq -r '.. | objects | select(has("specs")) | .specs[] | . as $s
  | ($s.tags[]? | select(test("^JRN-[0-9]{3,}$"))) as $j
  | $s.tests[].results[] | .retry as $r
  | .attachments[] | select(.path != null)
  | [$j, ($r|tostring), .name, .path] | @tsv' test-results/e2e-results.json
```

  Attachments with `body` and no `path` (the console and network logs above) are written out from `.body`. Copy them to `specs/NNN-slug/artifacts/<run-id>/<JRN-###>/<name>[-retry<r>].<ext>`, where `<run-id>` is a UTC timestamp plus the short `HEAD` sha. Also copy the report itself to `artifacts/<run-id>/e2e-results.json`. Per-test status is at `.specs[].tests[].results[].status`, with values `passed`, `failed`, `timedOut`, `skipped` or `interrupted`.

### Citations

- Use options (screenshot, trace and video): https://playwright.dev/docs/test-use-options ("Recording options").
- `--trace` modes (`on`, `off`, `on-first-retry`, `on-all-retries`, `retain-on-failure`, `retain-on-first-failure`, `retain-on-failure-and-retries`), `--grep`, `--reporter` and `--add-reporter`, `--output`: https://playwright.dev/docs/test-cli ("All Options").
- `outputDir` (cleaned at the start of a run, one subdirectory per test): https://playwright.dev/docs/api/class-testconfig#test-config-output-dir.
- Reporters: the JSON `outputFile` and the variables `PLAYWRIGHT_JSON_OUTPUT_FILE`, `..._NAME` and `..._DIR`, and HTML `open: 'never'`: https://playwright.dev/docs/test-reporters ("JSON reporter", "HTML reporter").
- Tags (`{ tag }` on `test` and `test.describe`; tags must start with `@`): https://playwright.dev/docs/api/class-test, and https://playwright.dev/docs/test-annotations ("Tag tests").
- JSON schema (`JSONReportTestResult.attachments[{name,path?,body?,contentType}]`, `status`, `retry`; tags serialised with `@` removed): `microsoft/playwright` `packages/playwright/types/testReporter.d.ts` and `packages/playwright/src/reporters/json.ts` (`tags: test.tags.map(tag => tag.substring(1))`).
- Auto fixtures and `testInfo.attach`: https://playwright.dev/docs/test-fixtures ("Automatic fixtures"), https://playwright.dev/docs/api/class-testinfo.
- Events: `console` (https://playwright.dev/docs/api/class-consolemessage), `pageerror` and `response` (https://playwright.dev/docs/api/class-page), `requestfailed` (https://playwright.dev/docs/api/class-request).

**Licence.** Playwright is Apache-2.0. The snippets above are ours, written from the docs. Optional prior art: Playwright's test agents (planner, generator, healer; `npx playwright init-agents`), also Apache-2.0. If you adapt their prompts, keep the NOTICE and say what you changed.

### Open questions

- 1.1: Should a console error fail the test? This is a project choice. Default: attach, don't fail. Make `expect(consoleErrors).toEqual([])` a Mini-review checklist line instead.
- 1.2: Who owns adding the `e2e_report` key to `profiles/TEMPLATE.md` (built in 1A)? 6A could add it as a one-line, comment-level change, if the orchestrator allows it.

---

## G2: Test-harness commands for the D26 stack (feeds `test-harness.md`)

### Toolchain block (example)

```yaml
lint: "npx oxlint -c .oxlintrc.json --deny-warnings"
typecheck: "npx tsc --noEmit -p tsconfig.json"
format: "npx oxfmt --check"            # Prettier variant: "npx prettier --check ."
boundary: "npx depcruise --config tools/boundaries/dependency-cruiser.cjs --output-type err-long src"
e2e: ""                                # test-harness profile: empty (D26 stub)
config:
  lint: ".oxlintrc.json"
  typecheck: "tsconfig.json"
  format: ".oxfmtrc.json"
  boundary: "tools/boundaries/dependency-cruiser.cjs"
rule_set: "oxlint defaults + vendored anti-slop (all generic rules at error, plus oxc/no-accumulating-spread) + project rules"
```

Notes on each key:

- **oxlint.**
  - `-c` or `--config` disables nested config lookup.
  - Use `--deny-warnings` (or `--max-warnings 0`) so warnings fail the run.
  - Type-aware rules are opt-in, through `--type-aware` or `options.typeAware` in the root config.
  - Anti-slop loads through `jsPlugins` in `.oxlintrc.json`: `{"name": "anti-slop", "specifier": "./tools/oxlint/anti-slop/index.ts"}`. Add the ignore patterns for agent directories and enable the rule list, as in `skills/install-anti-slop/SKILL.md` step 3.
  - JS plugins are alpha (not semver). TS plugin files need Node `^20.19.0` or `>=22.18.0`, or Bun or Deno. Pin `oxlint` and `@oxlint/plugins` to the same exact version (install-anti-slop step 2).
- **tsc.** `--noEmit` with `-p`. Exit code 0 means clean.
- **oxfmt.**
  - `--check` checks files and shows statistics without writing. `--list-different` lists the files that would change.
  - Config files are `.oxfmtrc.json`, `.oxfmtrc.jsonc` or `oxfmt.config.ts`; the nearest one to each file wins.
  - Mirror the anti-slop ignore patterns in its `ignorePatterns`.
  - Prettier fallback: `prettier --check .`.
- **dependency-cruiser.**
  - The `err` and `err-long` output types print nothing and exit 0 when there are no violations. Otherwise they exit with the number of error-severity violations, which suits a gate.
  - Pass `--config <file>` explicitly, because the generated config is not at the auto-discovered `.dependency-cruiser.cjs` path.
  - `options.tsConfig.fileName` makes `paths` aliases resolve.
- **Vitest** (not a Toolchain key, see 2.1):
  - `npx vitest run` for a single CI-style run.
  - Coverage: `npx vitest run --coverage` with `test.coverage.provider: 'v8'` and `test.coverage.thresholds: { lines, functions, branches, statements, perFile? }`. Vitest fails the run when a threshold is missed.
  - Machine-readable results: `--reporter=json --outputFile=<path>`. Current docs say the JSON reporter defaults to `.vitest/json/output.json`, so always pass `--outputFile`.

### Mini-review checklist sample (judgement items no tool expresses)

```markdown
- [ ] Each test asserts observable behaviour through the module's public interface, not private state or call order.
- [ ] Each new test was seen failing for the right reason (an assertion message, not an import or setup error) before the code made it pass.
- [ ] Test names state the behaviour and its condition ("rejects an expired card"), not the function under test.
- [ ] Fixtures come from the verification-plan "Fixtures and oracles" table; no hand-typed expected values without a named oracle.
- [ ] Tests at a system boundary use a fake or in-memory adapter at a seam the module owns; module mocking is not reintroduced through another API (anti-slop `no-module-mocking` covers `vi.mock`).
- [ ] Coverage gaps on new branches are deliberate and named, not hidden by `/* v8 ignore */`.
```

The philosophy sources for these lines are `skills/tdd/{tests,mocking}.md` (MIT, Matt Pocock).

### Citations

- oxlint `-c`, `--deny-warnings`, `--max-warnings`, `--quiet`: https://oxc.rs/docs/guide/usage/linter/config.html, https://oxc.rs/docs/guide/usage/linter/quickstart.html ("Fail CI reliably").
- `jsPlugins` (alpha, object form `{name, specifier}`, TS plugin Node versions): https://oxc.rs/docs/guide/usage/linter/config-file-reference.html#jsplugins.
- Type-aware linting: https://oxc.rs/docs/guide/usage/linter/type-aware.
- oxfmt `--check` and `--list-different`: https://oxc.rs/docs/guide/usage/formatter/cli.html ("Output Options"). Config lookup: https://oxc.rs/docs/guide/usage/formatter/config.html. `ignorePatterns`: https://oxc.rs/docs/guide/usage/formatter/ignore-files.html.
- dependency-cruiser `err` output, `--config`, `--no-config`, `--output-type` list: https://github.com/sverweij/dependency-cruiser/blob/main/doc/cli.md.
- Vitest coverage thresholds (incl. `perFile` object): https://github.com/vitest-dev/vitest/blob/main/docs/config/coverage.md (https://vitest.dev/config/coverage). Reporters and `outputFile`: https://vitest.dev/guide/reporters.

**Licence.** All of these are MIT tools. We copy no text; the anti-slop config shape comes from the vendored MIT skill.

### Open questions

- 2.1: **The Toolchain block has no `test` key.** D15 and Batch 1 fixed exactly five keys: lint, typecheck, format, boundary, e2e. The harness (Vitest) gates at 3.9, but `run-toolchain.sh` never runs it. Options:
  - (a) add a sixth key, `test`, which amends D15 and touches 2C;
  - (b) have the 3.9 gate read the harness command from a descriptive key (`harness: "npx vitest run --coverage"`).

  Needs a user decision. Until then, 6A puts the Vitest command in a descriptive key.
- 2.2: oxfmt or Prettier: the example ships oxfmt, with the Prettier line as a comment.

---

## G3: `review-targets`, a measurement-only reviewer

### Prior art

**No adoptable public measurement agent exists.**

- The survey found only static reviewers (EveryInc `performance-reviewer.md`).
- A search this time found tech-leads-club/agent-skills `perf-lighthouse` (7k stars). Its repo LICENSE says the code is MIT but that skill content (`SKILL.md`) is **CC-BY-4.0**, which is outside build convention 3, so copy nothing from it. It also uses Lighthouse `budget.json`, where LHCI assertions are the better fit.

So the design below comes from the docs and our own plan.

### Design

The input is the verification-plan Targets table: Target, Kind, Threshold, exact command, source. Each target goes through the same loop:

1. If the command is missing, or names a tool or URL that is not available → `not_measurable`, with the reason. This is the "not measurable: reason" rule. Never estimate.
2. Run the command exactly as written, with the build already running. Who starts it is open question 3.2. Save stdout and stderr to `specs/NNN-slug/artifacts/targets/<run-id>/<target-slug>.txt`.
3. Read the measured number from the tool's machine output (table below). Compare it with the threshold. `pass` or `fail` is decided by the number alone; the tool's exit code is recorded as a cross-check.
4. No judgement: no "close enough", no reruns to fish for a pass. Rerun only if the tool itself aggregates runs (LHCI `numberOfRuns`).

| Kind | Exact command (in the Targets table) | Threshold lives in | Measured value read from | Fails how |
| --- | --- | --- | --- | --- |
| performance (page) | `npx lhci autorun --config=lighthouserc.json` (or `npx lhci collect --url=<url> -n 3 && npx lhci assert`) | `lighthouserc.json` → `ci.assert.assertions`, e.g. `"largest-contentful-paint": ["error", {"maxNumericValue": 2500, "aggregationMethod": "median-run"}]`, `"categories:performance": ["error", {"minScore": 0.9}]` | `.lighthouseci/lhr-*.json` → `.audits["<id>"].numericValue` and `.categories.performance.score` (take the run LHCI aggregates) | Non-zero exit on `error`-level failed assertions |
| performance (API load) | `k6 run --summary-export=artifacts/.../k6-summary.json load/checkout.js` (or `handleSummary` returning `{"<path>": JSON.stringify(data)}`) | the script's `options.thresholds`, e.g. `http_req_duration: ['p(95)<200']`, `http_req_failed: ['rate<0.01']` | the summary JSON → `metrics.http_req_duration["p(95)"]`, `metrics.http_req_failed.value` (check field names on first run) | Prints "some thresholds have failed" and exits non-zero (99) |
| coverage | `npx vitest run --coverage --coverage.reporter=json-summary --coverage.reporter=text` | `vitest.config.ts` → `test.coverage.thresholds` (or `--coverage.thresholds.lines=80`) | `coverage/coverage-summary.json` → `.total.lines.pct` (and `branches`, `functions`, `statements`) | Non-zero exit when a threshold is missed |
| error (browser) | `npx playwright test --grep @JRN-001` | the threshold says "0 console errors" | the `console-errors` attachment from G1 | Count is greater than 0 |

### Return format

This matches the `review-findings` block in `.agents/agents/review-standards.md`, with one addition. Each failed target becomes a finding. Every target, whatever its result, appears in `measurements`, the fixed table that 5.4 "Targets vs measured" copies.

```yaml review-findings
lens: review-targets
status: done                    # done | blocked (e.g. the build is not running)
blocked_reason: ""
baseline_revision: "<full sha>"
head: "<full sha>"
measurements:                   # one per Targets row, in table order
  - target: "checkout page LCP"
    kind: performance
    threshold: "LCP median <= 2500 ms"
    command: "npx lhci autorun --config=lighthouserc.json"
    measured: "2310 ms"
    result: pass                # pass | fail | not_measurable
    raw_output: "specs/007-checkout/artifacts/targets/20261015T0930Z-9f2c1d7/checkout-lcp.txt"
    reason: ""                  # required when not_measurable
findings:
  - id: RT-1
    category: target            # new category for this lens
    severity: high              # a missed target is always high: it is a spec'd threshold (no judgement)
    confidence: 100             # measured, not inferred
    location: "verification-plan.md#targets: <target>"
    claim: "<target> measured <value>, threshold <threshold>"
    consequence: "The build does not meet a target the spec committed to (source: <source column>)."
    evidence:
      basis: "<raw_output path>"
      diff: ""
    suggested_fix: ""           # the lens makes no fix suggestions
checked:
  - "<each target measured>"
not_checked:
  - "<target>: not measurable: <reason>"
```

### Citations

- LHCI assertions (`maxNumericValue`, `minScore`, `categories:<id>`, `aggregationMethod`, `preset`), the `collect` options (`numberOfRuns`, `startServerCommand`, `url`), and `upload.target: filesystem` with `outputDir`: https://github.com/GoogleChrome/lighthouse-ci/blob/main/docs/configuration.md ("assert", "collect", "upload").
- k6 thresholds and the failure output: https://grafana.com/docs/k6/latest/using-k6/thresholds/. Custom summary (`handleSummary`): https://grafana.com/docs/k6/latest/results-output/end-of-test/custom-summary/. The exit code 99 for failed thresholds is from k6's documented exit codes; confirm on the first run.
- Vitest coverage thresholds and reporters: as in G2. The `json-summary` reporter is an istanbul reporter that writes `coverage/coverage-summary.json`.

**Licence.** LHCI is Apache-2.0, k6 is AGPL-3.0 (we invoke the tool and copy nothing; scripts the project writes are its own), and Vitest is MIT. No text was copied.

### Open questions

- 3.1: `review-triage` (5C) must accept `category: target` and the extra `measurements:` key, or the table goes in a sibling block (` ```yaml review-measurements `). 6C and the triage owner should agree on this.
- 3.2: Who starts the running build at 4.3? Options: the orchestrator before the launch (simplest; pass `base_url` in the launch prompt), or LHCI `startServerCommand` and Playwright `webServer`. D31 lists only `spec_dir` as the required header field.
- 3.3: Should k6 be in the example stack? D26 does not list it. Ship it as an optional row; LHCI and Vitest coverage are the defaults.

---

## G4: Known-bad-build technique (step 1.4)

### Recommendation: targeted fault injection, with the baseline as the first known-bad build

At 1.4 the feature does not exist yet, so `baseline_revision` (captured at 1.1, D53) is a known-bad build for every new check. StrykerJS cannot drive the Playwright suite efficiently: only its generic command runner works, with no per-test coverage analysis, and every mutant would need a rebuild. So:

1. **Both suites against the baseline** (always, and cheap):
   - `npx vitest run --reporter=json --outputFile=artifacts/1.4/harness.json`
   - `npx playwright test` (JSON at `test-results/e2e-results.json`)

   **Pass criterion:** every new harness test and every new `@JRN-###` test has status `failed`, and its first error is an **assertion** failure, not an import, compile, setup or navigation-timeout error. Check Vitest `testResults[].assertionResults[].failureMessages`, and Playwright `results[].errors[].message` matching `expect(`. A new test that passes on the baseline, or fails only for setup reasons, is not proof → loop to 1.2.
2. **Injected fault for the browser suite** (always):
   - The e2e fixture honours `E2E_INJECT_FAULT=1` by routing the app's API to an error: `page.route('**/api/**', r => r.fulfill({ status: 500 }))`.
   - Run `E2E_INJECT_FAULT=1 npx playwright test`.
   - **Pass criterion:** every journey test fails. A journey that stays green under a dead backend is vacuous → 1.2.
3. **StrykerJS on the harness** (optional, only when the change modifies **existing** behaviour that the baseline run cannot prove):

   ```json
   // stryker.config.json
   { "testRunner": "vitest", "vitest": { "configFile": "vitest.config.ts", "related": true },
     "reporters": ["clear-text", "json"], "thresholds": { "high": 80, "low": 60, "break": 60 } }
   ```

   Run `npx stryker run --mutate "src/billing/**/*.ts,!src/billing/**/*.test.ts"`, with the scope set to the owning module from `codebase-map.md`.

   **Pass criterion:** exit 0, meaning the mutation score is at least `break`. Inspect the JSON report (`reports/mutation/mutation.json`) for `Survived` and `NoCoverage` mutants on changed lines.

If no fault can make a suite fail, set `blocked` (1.4 → `blocked`, D47 routing).

### Citations

- StrykerJS Vitest runner (`testRunner: "vitest"`, `vitest.configFile`, `vitest.related`): https://github.com/stryker-mutator/stryker-js/blob/master/docs/vitest-runner.md (https://stryker-mutator.io/docs/stryker-js/vitest-runner/).
- `mutate` globs, `--mutate file:lines`, and `thresholds.break` (the build fails with exit 1 when the score is below `break`; there is no CLI flag for it), reporters: https://stryker-mutator.io/docs/stryker-js/configuration/. Incremental mode: https://stryker-mutator.io/docs/stryker-js/incremental/.
- `page.route` / `route.fulfill`: https://playwright.dev/docs/network ("Modify responses").
- Red-for-the-right-reason discipline: `skills/tdd/SKILL.md` (MIT) and `skills/proof-of-work/modules/iron-law-enforcement.md` (MIT).

**Licence.** StrykerJS is Apache-2.0. We use the tool and copy no text.

### Open questions

- 4.1: A tests-first harness for a brand-new module fails on import, which is a setup error. Does 1.2 add a minimal interface stub (agreed at 2.3, which comes later) so the failure becomes an assertion failure? Or does 1.4 accept "module not found" for a module listed as new in `codebase-map.md`? Needs a decision for 5B's text.
- 4.2: A time or cost ceiling for the optional Stryker pass, as a profile-level setting.

---

## G6: Deterministic caches

### Principle

A script generates whatever can be generated. The agent writes only bounded prose into fixed slots. Every list is sorted by path. No timestamps or counts appear in bodies; the stamp lives in the frontmatter (D17).

### `architecture.md`: fully generated

Don't use the `mermaid` reporter directly. By default it *minifies*, hashing and shortening node names, and the docs do not promise any output order. Instead, emit JSON and canonicalise it ourselves:

```bash
npx depcruise --no-config --ts-config tsconfig.json \
  --include-only '^src/' --collapse '^src/[^/]+' \
  --output-type json src > "$STAGING/depcruise.json"

jq -r 'def id: gsub("[^A-Za-z0-9]"; "_");
  ([.modules[].source] | unique) as $n
  | ([.modules[] | .source as $f | .dependencies[] | select(.resolved != $f) | [$f, .resolved]] | unique) as $e
  | "flowchart LR", ($n[] | "  \(id)[\"\(.)\"]"), ($e[] | "  \(.[0]|id) --> \(.[1]|id)")' \
  "$STAGING/depcruise.json"
```

This was checked on a sample. `unique` sorts, so nodes and edges come out in byte order, and self-edges are dropped.

- Use `--no-config` so the boundary config's options (such as the `--init` template's `skipAnalysisNotInRules: true`) cannot change what gets cruised.
- Set the collapse pattern from the `docs/rules.md` Ownership paths, so the nodes are the modules the rules talk about.
- Body shape:
  - `## Module graph`: the Mermaid block above.
  - `## Edges`: a sorted `from → to` list (diff-friendly text).
  - `## Boundary violations`: output of `depcruise --config tools/boundaries/dependency-cruiser.cjs -T err-long src`, sorted, or "none".
- `generator: dependency-cruiser`.
- An id collision (for example `src/a-b` and `src/a_b`) must stop the script rather than merge the two nodes.

### `modules.md`: generated skeleton, agent-written purpose lines

One `## <module path>` section per collapsed module, sorted. Each section has:

- **Files**: from `depcruise -T json` without `--collapse`, using `.modules[].source` filtered by prefix, sorted.
- **Depends on** / **Used by**: from the collapsed edges above, sorted.
- **Public interface**:
  - the exported declarations of the module entry (`index.ts`), produced deterministically by `npx tsc -p tsconfig.json --declaration --emitDeclarationOnly --outDir "$STAGING/dts"`;
  - list the exported names sorted, with kind (function, type, class, const), one per line;
  - API Extractor's `.api.md` report (Microsoft, MIT) is a heavier alternative built for diffing.
- **Purpose**: the only agent-written slot. At most one sentence, present tense, no adjectives of quality, drawn from code and comments only (never Tier A or the previous cache, per the agent stub).

A generic repo-map alternative is Universal Ctags (`ctags --output-format=json --sort=yes -R src`). It is GPL-2.0, which is fine as an external binary when nothing is copied, but it is an extra dependency. Prior art for the "repo map" idea is Aider's repo map (tree-sitter, Apache-2.0); we use the idea only.

### `flows.md`: design proposal (agent-written, constrained)

- **Sources, in order:**
  1. Entry points: route, CLI or handler files. The `## Entry points` list in the cache is produced by a project-configured glob (from the profile or `rules.md`), sorted.
  2. The module chain each entry point reaches, from `depcruise --no-config --include-only '^src/' --focus '<entry file regex>' -T json` (deterministic reachability).
  3. The agent reads only those files to trace the call order.
- **One `## <entry point path>` section per entry**, sorted, each with one `sequenceDiagram`.
- **Canonicalisation rules** for the agent:
  - declare `participant`s up front in first-call order, named by module path (the same ids as `architecture.md`);
  - one arrow per call, `A->>B: functionName()`, with no prose labels, no `Note`, no `autonumber`, no `alt`/`loop` unless the code branches;
  - trace the happy path only, and list error branches as text bullets under the diagram, sorted.
- **Determinism check:** regenerate twice at the same commit and `diff`. Any difference means a prompt fix, not a tolerated drift.

### Mermaid validation

`skills/visual-change-report/scripts/validate_mermaid.mjs` parses `<pre class="mermaid">` blocks in **HTML** only, and needs `mermaid@11` and `jsdom`. For the Markdown caches, either wrap the staging file's ` ```mermaid ` fences into a temporary HTML file before calling it, or give the script a `--markdown` mode. `regenerate-caches` (6B) owns that choice; the script belongs to a vendored skill, so prefer the wrapper.

### Citations

- dependency-cruiser `--output-type` values (`json`, `mermaid`, `dot`, `archi`, `ddot`, `flat`, `text`, `err`, `err-long`, `metrics`, `d2`, ...), `--no-config`, `--collapse`, `--include-only`, `--focus`, `--ts-config`, `--output-to`: https://github.com/sverweij/dependency-cruiser/blob/main/doc/cli.md.
- The Mermaid reporter `minify` default (true; hashes and shortens names): https://github.com/sverweij/dependency-cruiser/blob/main/doc/options-reference.md (`reporterOptions.mermaid`). The `archi` `collapsePattern` is in the same file.
- JSON output shape (`modules[].source`, `dependencies[].resolved`, `summary`): https://github.com/sverweij/dependency-cruiser/blob/main/doc/output-format.md.
- `skipAnalysisNotInRules` in the init template: `src/cli/init-config/config-template.mjs` in the same repo.
- TypeScript `declaration` and `emitDeclarationOnly`: https://www.typescriptlang.org/tsconfig/#emitDeclarationOnly.

**Licence.** dependency-cruiser is MIT and TypeScript is Apache-2.0. Both are tool use only.

### Open questions

- 6.1: Run the canonicaliser once against a real TS repo to confirm that `--collapse` also collapses `dependencies[].resolved`. It is expected to, but this was not run here (no network install).
- 6.2: The entry-point glob for `flows.md` has no home yet. Candidates are a descriptive profile key or a `rules.md` block. A user decision is needed if it touches `rules.md` (Tier A).

---

## G8: Codex model aliases per tier

### Recommendation

| Tier (D23) | Codex model | Why |
| --- | --- | --- |
| cheap | `gpt-6-luna` | The docs describe Luna as "our most efficient model for focused, high-volume tasks" and recommend it for "clear, repeatable tasks". The docs' own read-only explorer agent example uses `model = "gpt-6-luna"` |
| strong | `gpt-6-sol` | "For complex coding and agentic workflows, use GPT-6.1 Sol when available to your account and client." `gpt-6.1-sol` is **not** in this account's catalog yet (CLI 0.155.1); `gpt-6-sol` is |
| (override, not seeded) | `gpt-6-astra` | "Choose Astra when a task needs the strongest capability across steps and tools." Use it through `agent-overrides.yaml` for the hardest types |

**Caveats.**

- **Codex has no model aliases.** The docs use slugs only; the closest mechanism is `notice.model_migrations`. Slugs get retired: `gpt-5.5` retired from Codex with ChatGPT sign-in on 2026-10-14, and `gpt-5.4` on 2026-08-31.
- The D23 "aliases, never dated IDs" rule can be met only in spirit: these are undated family slugs.
- Therefore `project-setup` should check the seeded values against the live catalog. Run `codex debug models | jq -r '.. | objects | select(has("slug")) | select(.visibility=="list") | .slug'` and, if a tier default is missing, write the model-map `fallback:` from that list (or stop at 00.14).
- Since `gpt-6.1-sol` is rolling out, set `fallback: gpt-6-sol` if a project pins `gpt-6.1-sol`.

**D35 interaction (important for 6D and 7A).** The docs say a custom agent file's `model` "takes precedence" over an explicit spawn value. Otherwise the order is: spawn value > `[agents]` default (`agents.default_subagent_model`) > the parent's model. So on Codex, writing the resolved model into the generated `.codex/agents/<name>.toml` at install or setup time is the authoritative route. A per-launch override (orchestrator, or a PreToolUse `updatedInput`) is ignored when the toml sets `model`.

### Evidence

- `codex debug models` (local, read-only, CLI 0.155.1, run 2026-10-15). The visible (`list`) slugs are `gpt-6-astra`, `gpt-6-sol`, `gpt-6-luna`, `gpt-5.6-sol`, `gpt-5.6-terra` and `gpt-5.6-luna`. The hidden ones are `gpt-reserve` and `codex-auto-review`.
- https://learn.chatgpt.com/docs/models (redirected from `developers.openai.com/codex/models`): sections "Recommended models", "GPT-6.1 Sol", "Choosing a model", "GPT-5.5 retirement", "Deprecated Codex models", "Configure your default local model".
- https://learn.chatgpt.com/docs/config-file/config-reference: `model` (example `gpt-6.1-sol`), `review_model`, `agents.default_subagent_model`, `agents.default_subagent_reasoning_effort`, and `notice.model_migrations`. There is no alias table.
- https://learn.chatgpt.com/docs/agent-configuration/subagents: the model precedence above, and the `.codex/agents/pr-explorer.toml` example with `model = "gpt-6-luna"`.

### Open questions

- 8.1: Accept "undated slug" as meeting D23 for Codex, or amend D23's wording for Codex only. This is a user decision.

---

## G7 remainder: Codex hooks (live verification)

### State

- **Installed:** `/opt/homebrew/bin/codex`, `codex-cli 0.155.1`. `codex features list` shows `hooks: stable, true`. The run is outlined below and was **not** executed.
- **The docs now answer most of the earlier unknowns.** D40 still needs a live run before anything is wired. From https://learn.chatgpt.com/docs/hooks:
  - **PreToolUse rewrite.** It returns `hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: {...}}`. For Bash and `apply_patch`, `updatedInput` must carry a string `command`. For MCP and other local function tools it is the replacement arguments object, and "`spawn_agent` also matches `Agent`". `"ask"` is not supported. Deny works through `permissionDecision: "deny"` or exit 2 with stderr.
  - **SubagentStop.**
    - Input: `turn_id, agent_id, agent_type, agent_transcript_path` ("Path to the subagent transcript file, if any"), `stop_hook_active, last_assistant_message`.
    - Output: `{"decision": "block", "reason": "..."}` continues the subagent; `continue: false` from any hook takes precedence. JSON on stdout is required; plain text is invalid.
  - **SubagentStart** input: `turn_id, agent_id, agent_type, permission_mode`. `continue: false` does not stop the start.
  - **Common fields:** `session_id` (subagent hooks use the parent's id), `transcript_path` (nullable), `cwd`, `hook_event_name`, `model`.
  - **PostToolUse** runs for Bash even after a non-zero exit. It carries `tool_input.command`, and `additionalContext` is supported. That is enough for `evidence-capture`.
  - **Trust.** The project `.codex/` layer must be trusted and each hook reviewed; trust is pinned to the hook hash. For automation, `--dangerously-bypass-hook-trust` runs enabled hooks without persisted trust. It is in this CLI's `codex exec --help`.
- **Per-path write deny: found, but it covers sandboxed commands.**
  - Permissions profiles (https://learn.chatgpt.com/docs/permissions) allow `default_permissions = "<name>"` with `[permissions.<name>.filesystem.":workspace_roots"]`, where `"." = "write"`, `"docs/cache" = "read"`, and `"**/*.env" = "deny"`.
  - "More specific entries override broader entries". For the same path, `deny` beats `write`, which beats `read`.
  - `read` and `write` globs are "less portable" on Linux, WSL and Windows, so a per-spec `specs/*/.step` rule is not reliable; `docs/cache` (a plain subpath) is.
  - The page speaks of "sandboxed commands". Whether this also covers `apply_patch` edits is **not stated**, so it must be part of the live test.
  - Note: extending `:workspace` keeps `.git`, `.agents`, `.codex` and `.aws` read-only by default. That suits us, because `.agents/` is scaffold-owned, but `install.sh` must run outside a Codex session.

### Outline of the live run (do not run here; same shape as `PLAN/hook-verification/run.sh`)

Proposed home: `PLAN/hook-verification/codex/` with `run.sh`, `hooks/*.sh` (reuse `log.sh`) and `probe/`.

1. **Scratch repo** in `mktemp -d`: `git init`, a README, one commit.
   - Add `.agents/skills/probe-skill/SKILL.md`.
   - Add `.codex/agents/probe.toml` (`name`, `description`, `developer_instructions`: "write probe.txt containing hi, then reply DONE"). Set **no** `model` key, so the rewrite test can see the model change.
   - Add `.codex/hooks.json` with logging hooks on `SessionStart`, `PreToolUse` (matcher `.*`), `PostToolUse` (`.*`), `SubagentStart`, `SubagentStop` and `Stop`, each appending `{event, input, pwd, env}` to `log.jsonl`.
   - Add behaviour hooks:
     - **T1** PreToolUse matcher `^(spawn_agent|Agent)$` returns `updatedInput`: the original `tool_input` with " Also say BANANA." appended to the message field, and a model field set to `gpt-6-luna` if a model field exists. Log the raw `tool_input` first, because the argument names are undocumented.
     - **T2** SubagentStop blocks once (marker file) with reason "write probe2.txt containing again", and checks `stop_hook_active` on the second stop.
     - **T3** SubagentStart returns `additionalContext: "SECRET-TOKEN-42"` (does it reach the subagent?).
     - **T4** two PreToolUse hooks on `apply_patch|Edit|Write`, allow plus deny for `denyme.txt` (does deny win?).
     - **T5** PostToolUse(Bash) logs `tool_input.command` and `tool_response` for `echo x; exit 3` (shape and non-zero behaviour, for `evidence-capture`).
   - Add `.codex/config.toml` with `default_permissions = "probe"`, a `[permissions.probe.filesystem.":workspace_roots"]` table with `"." = "write"` and `"locked" = "read"`, and `mkdir locked`.
2. **Run 1** (T1–T5 and the path deny):

   ```bash
   codex exec -C "$H/proj" --dangerously-bypass-hook-trust --json -m gpt-6-luna \
     -c 'projects."'"$H/proj"'".trust_level="trusted"' \
     -o "$H/runs/run1.last.txt" \
     "1) Spawn the probe agent with the message 'go' and report its final reply verbatim. 2) Use apply_patch to create denyme.txt containing x. 3) Run: echo x; exit 3 4) Use apply_patch to create locked/a.txt containing x. 5) Run: echo y > locked/b.txt"
   ```

   Confirm the `projects.<path>.trust_level` key on the first run. The docs page did not show it; if project-layer trust is not covered by `--dangerously-bypass-hook-trust`, trust the scratch project interactively once.
3. **Report** with jq, as `run.sh` does:
   - the key sets per event;
   - the raw `spawn_agent` `tool_input` (the argument names) and the PostToolUse view after the rewrite;
   - the subagent's model (is `model` in the payload, or in the transcript?);
   - BANANA in the reply;
   - the `probe2.txt` contents and `stop_hook_active`;
   - `agent_transcript_path` existence, and whether its first user message is the launch prompt (D39 needs this);
   - which file creations were blocked: `denyme.txt` (hook), `locked/a.txt` (apply_patch versus permissions), `locked/b.txt` (shell versus permissions);
   - the PostToolUse Bash fields after the non-zero exit.
4. **Record** the results in `PLAN/hook-verification-codex.md` (version, date, table, payload lists, design implications per D40). Wire only the events that behaved like Claude's in `.codex/hooks.json` (6D).

### Open questions

- 7.1: The `spawn_agent` argument names (message field, model field) are undocumented. The run logs them. If `spawn_agent` has no model argument, D35 on Codex relies on the generated toml `model` (see G8).
- 7.2: Does the permissions profile's `read` on `docs/cache` stop `apply_patch` as well as shell writes? If only shell writes, the Tier B limit stays a hook (PreToolUse on `apply_patch`) plus advisory.

---

## Licence notes (all gaps)

- Tools invoked, nothing copied: Playwright (Apache-2.0), Vitest (MIT), oxlint and oxfmt (MIT), TypeScript (Apache-2.0), dependency-cruiser (MIT), StrykerJS (Apache-2.0), Lighthouse CI (Apache-2.0), k6 (AGPL-3.0; invoked only), Universal Ctags (GPL-2.0; optional binary, invoked only).
- Every config and script snippet in this file is first-party, written from the docs. When a builder adapts one, record "first-party, from PLAN/gap-research.md (docs: <URL>)" in `Sources:`.
- Do not copy: tech-leads-club/agent-skills `SKILL.md` content (CC-BY-4.0, outside convention 3).
- The Codex docs are OpenAI documentation: cite them, don't copy them.
