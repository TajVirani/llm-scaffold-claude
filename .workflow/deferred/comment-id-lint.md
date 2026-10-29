---
origin_spec: .workflow/specs/002-review-lessons
created: 2026-10-22
---

# Lint for ids and paths in shell comments

**Summary:** A lint suite that catches, by grep, the two mini-review findings that keep recurring in shell files: a body comment naming a decision, journey, finding or task id or a `.workflow/` path, and a single-bracket `[ ... ]` test in a new file.
**Mode:** AFK
**Origin:** [002-review-lessons](../specs/002-review-lessons/spec.md), 5.3 approved tool rule P13, design-log entry 2026-10-22 Triage, review pass 1

## Goal

The toolchain, not the 3.7 mini-review, catches a body comment that points at a record (decision, ADR, journey, finding or task id, or a `.workflow/` path) and a single-bracket test in a file added since the baseline, so review rounds stop being spent on them.

## Background

The same two breaches recurred across tasks and specs: journey ids in test comments shipped in spec 001 (F4) and again here (F2); path tokens in comments and a single-bracket test cost T1 of this spec three review rounds. Both are exact string patterns, so a grep expresses them. The checklist lines and the readable-code rules stay: the lint covers them (`tool-covered` at 3.7), it does not replace them.

**Current behaviour:** the profile-mini-review judges these by reading; findings recur.

**Desired behaviour:** `tests/run-all.sh` runs a lint suite that fails with the offending line when a tracked shell file's body comment (outside its `# File:` or `# Suite:` header block) names a decision id (`D<n>`, `ADR-`), a journey id (`JRN-`), a task id (`T<n>:`) or a `.workflow/` path, or when a shell file added since the spec's baseline uses `[ ... ]`; existing files keep their current test syntax (the profile's "never convert a file for style" rule).

## Constraints

- Test-harness profile: one suite per check under `tests/lint/`, built on `tests/lib/common.sh`, ending in a `shellcheck_files` assertion; no committed fixtures.
- The `# File:` and `# Suite:` header blocks are exempt (`.workflow/rules.md` § Cross-cutting policy; readable-code R4).
- Journey ids stay allowed in test-name strings and in `# Covers:` header lines; only body comments are checked.

## Decisions already made

- P7 and P8 of 002-review-lessons name the rule and the header exemption the lint enforces (proposals.md, approved 2026-10-22).

## Evidence

- Mini-review rounds for T1: `.workflow/specs/002-review-lessons/artifacts/T1/mini-review-r1.yaml`, `mini-review-rework-r1.yaml` (item 7, R4) as of commit `7a71bf00f7dba980ef78c4b29549793eb4fcb21b`.
- Triage pass 1 row F2 in `.workflow/specs/002-review-lessons/design-log.md`; spec 001's F4 in `.workflow/specs/001-large-path/design-log.md`.

## Acceptance criteria

- [ ] `tests/lint/comments.sh` (or a name the profile prefers) exists, is listed in `tests/README.md`, and fails on a fixture copy with each breach, naming the file and line.
- [ ] The suite passes on the repository as is, with the existing `# Covers:` journey ids and existing single-bracket tests untouched.
- [ ] The shell-scripts and test-harness profiles mark the two checklist items `tool-covered` by this suite.

## Out of scope

- Converting existing files from `[ ]` to `[[ ]]`.
- Comments in markdown skills or agent definitions.

## Later requests

- .workflow/specs/008-pr-description-template, 3.7: the Markdown asset templates under `.agents/skills/feature-workflow/assets/` also name `.workflow/` paths inside their guidance comments (e.g. `assets/codebase-map.md:53`), the same R4 breach in another file kind; the lint could cover them.
