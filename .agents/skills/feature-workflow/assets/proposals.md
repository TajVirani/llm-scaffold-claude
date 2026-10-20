<!--
File: Template for .workflow/specs/NNN-slug/proposals.md: the 5.2 proposed updates to Tier A and the profiles, each approved line by line at 5.3. No frontmatter.
Written by modules/sign-off.md at 5.2; the Status column is updated at 5.3, and only `approved` and `modified` lines are applied. Also the landing place for writes tier-a-write-guard redirected mid-feature: record them here as they happen, with the step in Origin.

Rules:
  - One row per proposal. Ids P1, P2, ... in order across the file, never reused.
  - Target: the file and section, e.g. `.workflow/rules.md` § Cross-cutting policy, `.workflow/profiles/<work-type>.md` § Approved libraries per concern.
  - Proposed text: the exact line to add, or "remove: <exact line>" / "replace: <old> -> <new>". Escape a literal pipe as \|.
  - Why: what an agent would do differently if this line were absent. A line that changes no behaviour, or restates what the code already shows, is not proposed.
  - Status: `proposed` until 5.3, then `approved`, `modified` (Decision column holds the text as modified) or `rejected` (Decision column holds the reason). Set by the human, line by line.
  - Tool rules: a mini-review finding that recurred is proposed as a tool rule (lint rule, boundary constraint, type-check setting), paired with removing the checklist line it replaces from the profile.
  - A rule conflict found at 0.3.5 lands here as a proposal, never as a mid-feature override.
  - Delete empty groups and this comment in the finished file.
-->

# Proposals: <feature title>

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-### \| <description> \| [.workflow/specs/NNN-slug](../specs/NNN-slug/spec.md) | <e.g. without it, 0.3.1 would not detect a duplicate request> | spec.md § Capabilities | proposed | |

## Rules

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P<n> | `.workflow/rules.md` § <section> | <line> | <behaviour change> | <design-log D<n>, finding F<n>, redirected write at <step>> | proposed | |

## Decisions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P<n> | `.workflow/decisions/adr/NNNN-slug.md` | <new ADR or supersede ADR-NNNN: summary> | <behaviour change> | <origin> | proposed | |

## Pitfalls

<!-- Observed failures only: something that actually went wrong in this feature. -->

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P<n> | `.workflow/decisions/pitfalls.md` | <what happened, where, this spec, the check that now prevents it> | <behaviour change> | <finding F<n> or task T<n>> | proposed | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P<n> | `.workflow/profiles/<work-type>.md` § <section> | <line> | <behaviour change> | <origin> | proposed | |

## Tool rules

<!-- Recurring mini-review findings turned into deterministic checks. Each row names the checklist line it retires. -->

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P<n> | `<lint config, .workflow/tools/boundaries via .workflow/rules.md, tsconfig>` and `.workflow/profiles/<work-type>.md` § Mini-review checklist | add: <rule and setting>; remove checklist line: <exact line> | <behaviour change> | <mini-review findings on T<n>, T<m>> | proposed | |
