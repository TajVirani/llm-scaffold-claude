---
origin_spec: .workflow/specs/003-bash-cache-extractor
origin_step: "3.4"
discovered_at: 2026-10-23
status: promoted
kind: bug
promoted_to: .workflow/specs/006-bash-case-patterns
---

# Bash graph extractor reads case patterns as script calls

## Problem

The bash graph extractor treats each `|`-separated alternative of a `case` pattern as a command. A pattern such as `../*` then looks like a call to a script by a path relative to the working directory and is listed under Unresolved edges, though nothing is called. The architecture cache shows false unresolved entries; no edge is lost or wrong.

## Evidence

- `install.sh:133` (`/* | ../* | */../* | */.. | ..) die ...`) and `install.sh:187` (`case "$f" in /* | ../* | ...`) each give a `couldNotResolve` entry `../*` from `extractors/bash.sh --root . --scope .` at commit `5cc1147` (task branch of T3, rework 1).
- T3 implementation result, `.workflow/specs/003-bash-cache-extractor/artifacts/T3/implementation.yaml`, `discovered_work`.

## Why not a blocker

Extra unresolved entries over-report; they never hide or invent an edge, so the "every statically resolvable edge, unresolved paths reported" success line of CAP-NEW-bash-graph-extractor and journeys JRN-001 to JRN-005 hold. This repo's architecture cache will list the two entries until fixed.

## Suggested scope and size

- Scope: skip `case` pattern lists (from `case ... in` or a line ending in a pattern `)` up to the `)`) when looking for calls; add a fixture line; leave call detection elsewhere unchanged.
- Size: 1 task in regenerate-caches, well under the default budget of 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../003-bash-cache-extractor/spec.md)
- Design log entry: [design-log.md](../003-bash-cache-extractor/design-log.md) (section 2026-10-23 Discovered work: case-patterns-as-calls)
