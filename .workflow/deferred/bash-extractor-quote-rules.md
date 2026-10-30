---
origin_spec: .workflow/specs/00012-extractor-multiline-quotes
created: 2026-10-30
severity: medium
---

# One set of quote rules for the bash graph extractor

**Summary:** The bash graph extractor pairs quotes in several places with different rules, and one of them drops a real call that follows an escaped quote inside an ANSI-C `$'...'` string on the same line.
**Mode:** AFK
**Origin:** [00012-extractor-multiline-quotes](../specs/00012-extractor-multiline-quotes/spec.md), 4.8 review finding, design-log entry 2026-10-30 Triage, review pass 1 (F2)

## Goal

The extractor decides what is quoted text in one place, with one set of rules that matches the shell, and every reader (calls, `source` lines, anchored tokens, `case` patterns) works from that decision, so no real call is lost to a quoting rule one reader gets wrong.

## Background

Spec 00012 added a walker that carries quotes across lines and shares that state with every reader. It left the older per-line pairers in place, each with its own rules for escapes and `$'...'` strings. Consolidating them is a redesign of the extractor's reading loop, larger than the smallest fix that spec needed, so it was shelved.

**Current behaviour:** On a line such as `y=$'it\'s'; ./run.sh`, the call `./run.sh` is not reported, by the extractor before and after spec 00012. Multi-line quoted strings are handled by the shared walker; same-line strings by the older pairers.

**Desired behaviour:** A call after any well-formed quoted string on the same line, including `$'...'` with escaped quotes and the `'"'"'` idiom, is reported; quoted text is never read as a command; the output JSON shape and CLI are unchanged.

## Constraints

- Stays in the extractor's awk program; no new parser or binary ([codebase-map of 00012](../specs/00012-extractor-multiline-quotes/codebase-map.md) § Library options).
- A detected call is never filtered: it is an edge or `couldNotResolve` (`.workflow/decisions/pitfalls.md`, "Report a detected call as unresolved; never filter it out"; [ADR-0003](../decisions/adr/0003-graph-extractor-per-profile.md)).
- bash 3.2 rules for the scripts themselves (`.workflow/rules.md` § Required versions).

## Decisions already made

- One quote state per line, shared by every reader (D1); a word-initial `#` outside quotes ends the code (D2); plain text in a multi-line double quote is data while a command substitution in it is code (D3); a quoted `<<` is not a heredoc (D4), in [design-log.md of 00012](../specs/00012-extractor-multiline-quotes/design-log.md).

## Evidence

- Probe at commit `783c26fbe70f8422723b827a065b63c7a98b8a89`: a file holding `y=$'it\'s'; ./same-line-after-ansi.sh` gives no record for `./same-line-after-ansi.sh` from `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`, nor from the pre-00012 extractor at `6f37f4c`. Verified (medium): a real call is dropped.
- review-standards RS-1, `.workflow/specs/00012-extractor-multiline-quotes/artifacts/review/pass-1/review-standards.yaml`: walk_quotes, blank_case_patterns, split_commands and unquoted_code in `bash.sh` follow different quoting rules.

## Acceptance criteria

- [ ] A call after `$'...'` holding an escaped quote, on the same line, is reported.
- [ ] Quote pairing lives in one function whose result every reader uses.
- [ ] A repo-wide before/after run of the extractor shows only restored calls and no new edge from quoted text.

## Out of scope

- Multi-line quoted strings, comments and quoted heredoc markers, handled by spec 00012.
- `case` fall-through terminators (`.workflow/deferred/bash-case-fallthrough.md`).
