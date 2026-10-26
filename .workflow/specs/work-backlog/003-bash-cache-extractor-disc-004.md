---
origin_spec: .workflow/specs/003-bash-cache-extractor
origin_step: "2.1"
discovered_at: 2026-10-23
status: promoted
kind: bug
promoted_to: .workflow/specs/007-boundary-check-failure
---

# A failed depcruise run reads as no boundary violations

## Problem

When the architecture build runs the depcruise boundary check and depcruise does not run (for example, not installed but `npx` is on the path), the failure is hidden and Boundary violations reads `None.`. The cache then claims the project has no boundary violations although nothing was checked. This predates spec 003; after D16 it reaches only projects whose profiles name `dependency-cruiser`.

## Evidence

- `.agents/skills/regenerate-caches/scripts/build-architecture.sh:248-254`: `tool_cmd` picks `npx --no-install depcruise` whenever `npx` exists, without checking that it runs.
- `build-architecture.sh:375`: the run ends `|| true`, because violations also make depcruise exit non-zero.
- `build-architecture.sh:381-384`: `jq` on the empty output prints nothing, so the section renders `None.`.
- Seen on this repo at 5.6: `npx --no-install depcruise --version` exits 1, and `build-architecture.sh --cache architecture` exits 0 with `None.` (design-log "Correction to the 5.6 change-request entry").

## Why not a blocker

D16 stops the check from running for bash-only projects, so JRN-006 and CAP-004's boundary success line hold without this fix. The false `None.` affects only a JS/TS project whose depcruise is broken, and the cache still renders.

## Suggested scope and size

- Scope: treat empty or unparseable boundary-check output as an error naming depcruise (`die`), keeping a non-zero exit with valid violations JSON as success; add a harness case with a depcruise stub that exits non-zero and prints nothing.
- Size: 1 task in regenerate-caches, well under the default budget of 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../003-bash-cache-extractor/spec.md)
- Design log entry: [design-log.md](../003-bash-cache-extractor/design-log.md) (section 2026-10-23 Discovered work: false-none-on-failed-depcruise)
