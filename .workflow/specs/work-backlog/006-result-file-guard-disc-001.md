---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "1.2"
discovered_at: 2026-10-29
status: open
kind: refactor
---

# Split the slow install-upgrade suite

## Problem

`tests/scripts/install-upgrade.sh` now runs about 26 `install.sh` runs and is the slowest suite in a full harness run. It breaks the `tests/README.md` promise that every suite takes under a minute, so it holds up a parallel `tests/run-all.sh`.

## Evidence

- Phase 1 harness agent, `.workflow/specs/006-result-file-guard/artifacts/phase-1-test-harness/implementation.yaml` `discovered_work[0]`: "tests/scripts/install-upgrade.sh now runs about 26 install.sh runs and takes about 66 s alone (156 s under a parallel tests/run-all.sh)".
- Run summary quoted there: `scripts/install-upgrade passed=43 failed=21 156s`.
- `tests/README.md:29`: "Every suite takes under a minute."

## Why not a blocker

Suite speed does not affect correctness. CAP-NEW-result-file-write and journeys JRN-006 and JRN-011 to JRN-013 are checked the same way whichever suite file holds the cases.

## Suggested scope and size

- Scope: move the matcher-resolution cases (JRN-011 to JRN-013) into their own `tests/scripts/install-*.sh` suite, as the other `install.sh` suites are split by concern, and update the `cache-repo-architecture` oracle if the `install.sh` call sites it matches move. Leave the cases themselves unchanged.
- Size: 1 task in the tests module, 2 to 3 files, all tests; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: slow-install-upgrade-suite)
