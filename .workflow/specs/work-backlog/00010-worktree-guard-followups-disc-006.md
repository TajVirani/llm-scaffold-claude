---
origin_spec: .workflow/specs/00010-worktree-guard-followups
origin_step: "3.7"
discovered_at: 2026-10-30
status: moved-to-deferred
kind: decision
---

# Journey ids in test-suite headers

## Problem

Test-suite header comments name journey ids (`JRN-001` ...) as shorthand for the behaviour each block of checks covers. Journey ids are numbered per spec, so the same id means different journeys in different specs, and a reader of the suite cannot tell which is meant. The readable-code check fails them on changed lines, while 39 suites under `tests/` carry them, so whether a suite header may name a journey id is unsettled.

## Evidence

- `tests/hooks/worktree-guard.sh:8-21` (Suite header; lines 14 and 17 were cleaned in spec 00010's rework, the rest still carry ids).
- T2 rework mini-review, `.workflow/specs/00010-worktree-guard-followups/artifacts/T2/mini-review-r3.yaml`: R5 fail on lines 14 and 17, and `out_of_scope_noticed[0]` for the other header lines.
- `grep -l '^#.*JRN-0' tests/*/*.sh` lists 39 suites; `tests/README.md` maps each tag to its spec.
- `.workflow/rules.md` Cross-cutting policy bans journey ids in body comments; the `# File:` header rule names only decision ids.

## Why not a blocker

Wording only: no check's behaviour depends on the header, and CAP-007, CAP-008 and CAP-NEW-extract-write-deny are unaffected.

## Suggested scope and size

- Scope: decide whether suite headers may name journey ids (with the README mapping) or must describe behaviour in words; then either record the exception in the test-harness profile or rewrite the headers, and add a lint so the choice holds.
- Size: 1 to 2 tasks in tests (and a 5.3 profile change), up to 39 files if headers are rewritten; the file count may exceed the 30-file default, so a split by suite folder may be needed.

## Links

- Origin spec: [spec.md](../00010-worktree-guard-followups/spec.md)
- Design log entry: [design-log.md](../00010-worktree-guard-followups/design-log.md) (section 2026-10-30 Discovered work: suite-header journey ids)
- Deferred file: [.workflow/deferred/comment-id-lint.md](../../deferred/comment-id-lint.md)
