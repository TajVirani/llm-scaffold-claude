<!--
File: Template for .workflow/specs/NNN-slug/verification-plan.md: how the feature will be proven. No frontmatter.
Written by modules/discovery.md at 0.5.1-0.5.4 (End state, Journeys, Fixtures and oracles); Targets added by modules/verification-setup.md at 1.1. Drives the browser suite (1.3), review-end-state (4.2) and review-targets (4.3); report.md (5.4) reports against it.

Rules:
  - End state: each objective is binary (pass or fail), observable from outside the code, and names the CAP-### it proves. "Works correctly" is not an objective.
  - Journeys: stable ids JRN-001, JRN-002, ... never reused or renumbered. Each journey names the automated check that runs it; the browser suite (1.3) is built from this list, tags each test `@JRN-###` (Playwright `tag` detail, with the id also at the start of the title) and so evidence in artifacts/ is filed by run and journey id. A journey with no automated check yet says "MISSING" in Check until 1.3 builds it.
  - Fixtures and oracles: say where test data comes from and how a correct result is known (expected values, a reference system, a recorded baseline). An oracle that is "looks right" is not an oracle.
  - Targets: filled at 1.1. Each has a threshold and the exact command that measures it, so review-targets can measure without judgement. A target that cannot be measured says why.
  - Suites: commands are never written here from memory. The unit/integration suite is the profile Toolchain `test` key and the browser suite is the `e2e` key; this section points to them, and gates 3.9 and 3.10 run them.
  - Delete this comment in the finished file.
-->

# Verification plan: <feature title>

Spec: [spec.md](spec.md)

## End state

<!-- 0.5.1. Testable objectives. -->

- [ ] <CAP-###>: <objective a test or demonstration can decide, e.g. "a user with an expired card sees the renewal form and can complete payment">

## Journeys

<!-- 0.5.2. End-to-end paths through the running application. -->

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | <name> | CAP-### | <1. ... 2. ... 3. ...> | <what is observable at the end> | `@JRN-001` test in the browser suite / MISSING |

## Fixtures and oracles

<!-- 0.5.3. Test data and reference systems. -->

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| <seed data, recorded response, reference system> | <data or expected values> | <where it comes from; how it is refreshed> | JRN-### |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| <e.g. checkout page interactive> | performance / error / coverage | <e.g. p95 < 2 s> | `<command>` | <spec constraint, rule, or stakeholder decision D<n>> |

## Suites

<!-- 1.2-1.4. Filled by modules/verification-setup.md. Commands come from the profile Toolchain keys, not from this file: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` | `<value of test>` | <CI job name or "none"> | `artifacts/<path>` |
| Browser | `e2e` | `<value of e2e>` | <CI job name or "none"> | `artifacts/<path>` |
