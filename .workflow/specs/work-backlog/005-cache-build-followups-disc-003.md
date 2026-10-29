---
origin_spec: .workflow/specs/005-cache-build-followups
origin_step: "5.9"
discovered_at: 2026-10-28
status: open
kind: bug
---

# Bash extractor reads multi-line quoted text as commands

## Problem

The bash graph extractor does not track a single-quoted string that spans lines. Text on the second and later lines of such a string (a multi-line jq program, an awk script) is read as commands, so a path-like word inside it is reported as an unresolved call. The published architecture cache then lists a call that does not exist.

## Evidence

- JRN-008 regenerate-caches run at commit `99801e5`: the published `.workflow/cache/architecture.md` lists `tests/scripts/extractor-bash.sh:205` `./x` under Unresolved edges. Line 205 is the second line of a single-quoted jq program that opens on line 204. See `.workflow/specs/005-cache-build-followups/artifacts/JRN-008/record.md` and `oracle-diff.txt`.
- The behaviour predates spec 005: the `case` fix changed only how arm pattern lists are read.

## Why not a blocker

The entry is reported as unresolved, never filtered out, so no real call is lost. It only adds a false entry to the cache. Spec 005's goals cover `case` patterns, and the fix is a separate change to the extractor's quote tracking.

## Suggested scope and size

- Scope: track single- and double-quoted strings across lines in `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`, so text inside them is never read as a command. Add fixture cases to the extractor-bash suite for a multi-line jq program, an awk script and a heredoc-free quoted block. A detected call still stays reported as unresolved.
- Size: 1 task, 1 module (regenerate-caches); well within 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../005-cache-build-followups/spec.md)
- Design log entry: [design-log.md](../005-cache-build-followups/design-log.md) (section 2026-10-28 Sign-off: stakeholder approval (5.5))
