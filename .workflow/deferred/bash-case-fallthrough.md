---
origin_spec: .workflow/specs/done/005-cache-build-followups
created: 2026-10-28
---

# Bash case fall-through terminators

**Summary:** The bash graph extractor recognises the bash 4 `case` arm terminators `;&` and `;;&` as arm ends.
**Mode:** AFK
**Origin:** [005-cache-build-followups](../specs/done/005-cache-build-followups/spec.md), 0.3.17 scope decision, design-log entry 2026-10-28 Scope decision: bash case fall-through terminators

## Goal

A target project whose scripts use bash 4 `case` fall-through gets the same pattern-list handling as one using `;;`: no pattern is reported as a call, and every command is still reported.

## Background

Spec 005 teaches the extractor where a `case` block starts and ends and skips each arm's pattern list (decision D3). This repo pins bash 3.2, which has only `;;`, so `;&` and `;;&` never occur here; they matter only for target projects on bash 4 or later.

**Current behaviour:** the extractor's command splitting does not know `;&` or `;;&`, so the arm after one may not be recognised as starting with a pattern list.

**Desired behaviour:** after `;;`, `;&` or `;;&`, the next text up to the first unquoted `)` is a pattern list.

## Constraints

- A detected call is reported as unresolved, never filtered out (`.workflow/decisions/pitfalls.md`).
- The extractor itself still runs on bash 3.2 tooling (awk, jq, git).

## Decisions already made

- The `case` fix tracks `case ... in` / `esac` state and skips only arm pattern lists (design-log D3 in [.workflow/specs/done/005-cache-build-followups/design-log.md](../specs/done/005-cache-build-followups/design-log.md)).

## Evidence

- Command split points at `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:326` as of commit `d6edbc9`. Reported by module-audit (regenerate-caches) at 0.4.6 of spec 005; can wait.

## Acceptance criteria

- [ ] Fixture arms ending in `;&` and `;;&` are followed by a pattern list that is not reported as a call.
- [ ] A command in a fall-through arm body is still reported.
- [ ] `tests/run-all.sh` passes.

## Out of scope

- Any other bash 4 syntax in the extractor.
