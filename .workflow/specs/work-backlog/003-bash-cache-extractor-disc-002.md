---
origin_spec: .workflow/specs/003-bash-cache-extractor
origin_step: "4.4"
discovered_at: 2026-10-23
status: promoted
kind: refactor
promoted_to: .workflow/specs/005-shared-test-patterns
---

# One shared definition of which paths are tests

## Problem

Two skills decide which files are tests with the same default pattern list and the same matcher, each holding its own copy: the size-budget count in feature-workflow and the entry-point candidates in regenerate-caches. Nothing keeps the copies in step, so a change to one makes the two disagree about which files are tests. The shell-scripts profile says code a second skill needs moves to `.agents/lib/`.

## Evidence

- `.agents/skills/feature-workflow/scripts/budget-check.sh:60-68` and `.agents/skills/regenerate-caches/scripts/build-architecture.sh:518-526` hold identical default lists; the matchers are at `budget-check.sh:155-170` and `build-architecture.sh:527-567` (commit `48d8646`).
- review-standards RS-1, pass 1 (`.workflow/specs/003-bash-cache-extractor/artifacts/review/pass-1/review-standards.yaml`), triaged F1.
- `.workflow/profiles/shell-scripts.md` File locations: "Code a second skill needs moves to `.agents/lib/`."
- Related shelf file on the same copied-helper convention: [.workflow/deferred/shared-path-normaliser.md](../../deferred/shared-path-normaliser.md).

## Why not a blocker

The two copies are identical today, so entry candidates and the size-budget count agree. CAP-NEW-bash-graph-extractor (flows candidates exclude `test_patterns` files) and every journey hold without the move.

## Suggested scope and size

- Scope: one helper under `.agents/lib/` (shared core, through the integration agent) holding the default test patterns and the matcher; `budget-check.sh` and `build-architecture.sh` source it and drop their copies; tests for both callers. Could be done together with the shared path normaliser on the shelf.
- Size: 2-3 tasks across shared core, feature-workflow and regenerate-caches, well under the default budget of 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../003-bash-cache-extractor/spec.md)
- Design log entry: [design-log.md](../003-bash-cache-extractor/design-log.md) (section 2026-10-23 Triage, review pass 1)
