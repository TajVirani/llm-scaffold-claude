<!--
File: Example filled profile for work type `e2e-browser` (D26): Phase 1.3 browser suite, one Playwright test per JRN-### journey.
Use: project-setup offers it as the starting point for <project>/profiles/e2e-browser.md (modules/profiles.md). Adapt every line to the project, then delete this comment and the banner.
Stack: Playwright, tsc, oxlint + vendored anti-slop, oxfmt (Prettier variant noted), dependency-cruiser (D26).
Contract: hooks/evidence-capture.sh matches Bash commands that start with the `e2e` value and reads the JSON report at `e2e_report` (a descriptive key; run-toolchain.sh never runs it).
Sources: first-party, from PLAN/gap-research.md G1 and G4, written from the Playwright docs (Apache-2.0; no text copied): https://playwright.dev/docs/test-use-options, https://playwright.dev/docs/test-cli, https://playwright.dev/docs/api/class-testconfig#test-config-output-dir, https://playwright.dev/docs/test-reporters, https://playwright.dev/docs/test-annotations, https://playwright.dev/docs/test-fixtures, https://playwright.dev/docs/network; structure from profiles/TEMPLATE.md. Plan refs: 1.3, 1.4, 3.10-3.12, 4.3; assetlist D15, D26, D61, D62, D63.
-->
# Profile: e2e-browser

> **Example: adapt before use.** Every path, command, URL and port below is a starting point for a TS/JS web app on the D26 stack. Check each line against the project, change what differs, then delete this banner.

## File locations

- Journey tests: `e2e/journeys/jrn-<###>-<slug>.spec.ts`, one file per `JRN-###` journey from `verification-plan.md`. Never under `src/`, which belongs to the application and `test-harness` profiles.
- Shared fixtures (console and network capture, fault switch, logged-in state): `e2e/fixtures.ts`. Every test imports `test` and `expect` from `./fixtures` (or `../fixtures`), never from `@playwright/test` directly, so the capture fixture always runs.
- Page objects, when two journeys drive the same screen: `e2e/pages/<screen>.ts`. Never a page object for a screen only one journey uses.
- Test data seeded through the app's API or a seed script: `e2e/data/`. Never hand-edited database rows.
- Playwright config: `playwright.config.ts` at the project root (shape below). TypeScript: `tsconfig.json` includes `e2e/**/*.ts`.
- Run output: `test-results/e2e/` (`outputDir`, cleaned at the start of every run), the JSON report at `test-results/e2e-results.json` (outside `outputDir`, so the cleanup cannot delete it) and the HTML report in `playwright-report/`. All three are gitignored. Evidence is filed from the JSON report into `specs/NNN-slug/artifacts/` by the evidence-capture hook (3.12); never copy run output into `specs/` by hand.

## Approved libraries per concern

- Browser driver, runner and assertions: `@playwright/test`. Do not add Cypress, Puppeteer, WebdriverIO or a second assertion library.
- Selectors: Playwright locators by role, label or test id (`getByRole`, `getByLabel`, `getByTestId`). Do not add a selector helper library.
- Network faults and stubs: `page.route` / `route.fulfill`. Do not add MSW or a proxy for the browser suite.
- Accessibility checks, if a target in `verification-plan.md` asks for them: `@axe-core/playwright`. Do not add another a11y engine.
- Visual comparison, if a target asks for it: `expect(page).toHaveScreenshot()`. Do not add a visual-diff service.

## Language and style rules

- One `test` per journey, titled with the journey id first and tagged with it: `test('JRN-001 expired card shows renewal form', { tag: '@JRN-001' }, async ({ page }) => { ... })`. A journey split over several tests uses `test.describe('JRN-002 refund flow', { tag: '@JRN-002' }, () => { ... })`. The tag is the Check value in `verification-plan.md` `## Journeys` (`@JRN-001`); run one journey with `npx playwright test --grep @JRN-001`.
- Each step of the journey ends in a web-first assertion (`await expect(locator).toBeVisible()`, `toHaveText`, `toHaveURL`) on what the user sees. Never `page.waitForTimeout`; wait on a locator or a response instead.
- Navigate with relative URLs (`page.goto('/billing')`) against `baseURL`. Never hard-code a host.
- `retries: 0`. A known-bad build must fail, not retry into green (1.4).
- Keep reporters in the config. Never pass `--reporter` on the command line: it replaces the configured reporters and the JSON report is lost. Use `--add-reporter` to add one.
- Console errors and network failures are attached, not asserted, by the capture fixture. A journey that must be error-free asserts it in the test (`expect(consoleErrors).toEqual([])` through a fixture that exposes the list).

### Required `playwright.config.ts`

```ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'e2e',
  outputDir: 'test-results/e2e',          // cleaned at the start of every run; one subdirectory per test
  forbidOnly: !!process.env.CI,
  retries: 0,                              // a known-bad build must fail, not retry into green
  reporter: [
    ['line'],
    ['json', { outputFile: 'test-results/e2e-results.json' }],   // = Toolchain e2e_report; outside outputDir
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

### Required `e2e/fixtures.ts`

An auto fixture attaches console errors and network failures to every test, and honours the 1.4 fault switch: with `E2E_INJECT_FAULT=1`, every app API request is answered with a 500, so every journey must fail (D63).

```ts
import { test as base, expect } from '@playwright/test';

export const test = base.extend<{ browserLogs: void }>({
  browserLogs: [async ({ page }, use, testInfo) => {
    if (process.env.E2E_INJECT_FAULT === '1') {
      await page.route('**/api/**', (route) => route.fulfill({ status: 500, body: 'E2E_INJECT_FAULT' }));
    }
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

Change `'**/api/**'` to the app's API prefix. A HAR per test (`recordHar` on a custom context fixture) is optional and heavy; leave it off unless a journey needs request bodies as evidence.

## Toolchain

```yaml
# Command keys, run by run-toolchain.sh at 3.5 in this order: lint, typecheck, format, boundary, test. e2e is not run at 3.5: the orchestrator runs it at 3.10 (run-toolchain.sh --e2e, or the command itself); evidence-capture files the artifacts.
lint: "npx oxlint -c .oxlintrc.json --deny-warnings"
typecheck: "npx tsc --noEmit -p tsconfig.json"
format: "npx oxfmt --check"          # Prettier variant: "npx prettier --check ."
boundary: "npx depcruise --config tools/boundaries/dependency-cruiser.cjs --output-type err-long src"
test: "npx playwright test --list"   # 3.5 for this work type: the suite compiles and every test is collected, without a running app (journeys are red until the feature exists). The harness gate (3.9) uses profiles/test-harness.md.
e2e: "npx playwright test"           # evidence-capture matches commands that start with this; append --grep @JRN-001, --project chromium or -x freely
# Descriptive keys (not commands; run-toolchain.sh never runs them):
serve: "npm run start"               # start command for the built app (review-targets, 4.3, D62)
serve_ready: "http://localhost:3000" # URL polled until the app answers
e2e_report: "test-results/e2e-results.json"   # JSON reporter outputFile, relative to the run directory; read by evidence-capture
config:
  lint: ".oxlintrc.json"
  typecheck: "tsconfig.json"
  format: ".oxfmtrc.json"
  boundary: "tools/boundaries/dependency-cruiser.cjs"
  e2e: "playwright.config.ts"
rule_set: "oxlint defaults + vendored anti-slop (all generic rules at error, plus oxc/no-accumulating-spread) + project rules; Playwright config above"
```

## Mini-review checklist

- [ ] Every journey row in `verification-plan.md` has exactly one test (or describe block) titled and tagged with its `JRN-###` id, and each test drives only that journey's steps.
- [ ] Each journey ends by asserting the expected outcome the journey row names, as the user sees it, not an intermediate state or a network call.
- [ ] Assertions use user-facing locators (role, label, text) or an agreed test id; no CSS or XPath chains tied to markup structure.
- [ ] No test depends on another test's state or run order; each seeds its own data from `e2e/data/` or the fixtures.
- [ ] The journey would fail under `E2E_INJECT_FAULT=1`: it asserts something that needs the backend, not only static page content (D63).
- [ ] Stubs with `page.route` are limited to third-party services the journey row names as out of scope; the app's own API is never stubbed outside the fault switch.
- [ ] Whether a console error should fail this journey is decided per journey and stated in the test (assert empty, or leave it attached), not left implicit.
