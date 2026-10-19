---
origin_spec: specs/NNN-slug      # the spec this item was shelved from
created: YYYY-MM-DD
severity: medium                 # review findings only (4.8): high | medium | low. Delete the key for any other item.
---
<!--
File: Template for deferred/<slug>.md: one self-contained handoff per shelved concept. Written through modules/deferred-handoff.md (D24) from questioning-loop (0.3.17), review-triage (4.8) and the light-path suite gap (3.14, D29). Read by `retrieval` at 0.2.4.
Archival (00.9): when the item gets a spec of its own, deferred-handoff prepends `superseded_by: specs/NNN-slug` to the frontmatter and moves the file to deferred/archive/<slug>.md. Nothing else changes.
Sources: brief structure (summary, current vs desired behaviour, acceptance criteria, out of scope; durable and behavioural rather than procedural) adapted from mattpocock/skills/skills/engineering/triage/AGENT-BRIEF.md@49dd158 (MIT). One file per concept, kebab-case concept name, durable reasons, later requests appended rather than duplicated: mattpocock/skills triage/OUT-OF-SCOPE.md (MIT). "Reference other artifacts, do not duplicate; redact secrets": mattpocock/skills handoff/SKILL.md (MIT). HITL/AFK: mattpocock/skills wayfinder/SKILL.md "Ticket Types" (MIT). Frontmatter fields and body headings (goal, background, constraints, decisions already made, evidence, back-link) are plan-specified: PLAN/decision-flow-reference.md "Persistent files" 00.8-00.10; assetlist D24, D29.

Frontmatter contract (mikefarah yq v4, `--front-matter=extract`; D38):
  - origin_spec: string, repo-relative spec folder (specs/NNN-slug).
  - created: date, YYYY-MM-DD.
  - severity: high | medium | low. Only on items deferred from review triage (4.8). An unverified (maybe-false) finding carries the severity it would have if true, and says "unverified" under Evidence.
  - superseded_by: string, specs/NNN-slug. Added only at archival, as the first key.
  Add no other keys.

Writing rules:
  - Name the file for the concept, not the incident: deferred/csv-export.md, not deferred/review-finding-3.md. Check deferred/ first; if the concept already has a file, append to it under "Later requests" instead of writing a second one.
  - Durable: the item may wait months. Describe behaviour, interfaces and contracts. File paths and line numbers go only under Evidence, tied to a commit.
  - Self-contained: a fresh agent with no access to the original conversation can act on it. Link the originating spec, design-log entry and ADRs rather than copying them.
  - Redact secrets, credentials and personal data.
  - Delete this comment and any optional section left empty.
-->

# <Concept name>

**Summary:** <one line: what is shelved.>
**Mode:** <HITL (needs a human to decide or do something) | AFK (an agent can act on it alone)>
**Origin:** [<origin spec>](../specs/NNN-slug/spec.md), <step: 0.3.17 scope decision | 4.8 review finding | 3.14 suite gap>, design-log entry <YYYY-MM-DD title>

## Goal

<What should be true once this is done, from the user's or system's point of view.>

## Background

<Why it came up and why it was shelved rather than done. The reason is durable: scope, a technical constraint, or a strategic decision, not "no time this week".>

**Current behaviour:** <what happens now.>

**Desired behaviour:** <what should happen, including edge cases and error conditions.>

## Constraints

- <A non-negotiable the eventual work must respect, e.g. an existing ADR or rule.>

## Decisions already made

- <decision> (design-log D<n> in [specs/NNN-slug/design-log.md](../specs/NNN-slug/design-log.md), or [ADR-NNNN](../docs/decisions/adr/NNNN-slug.md))

## Evidence

- <finding, measurement or observation>, at `<path:line>` as of commit `<sha>`. <For review findings: verdict and what verified it, or "unverified: <what would settle it>".>

## Acceptance criteria

- [ ] <specific, independently verifiable criterion>

## Out of scope

- <adjacent work this item does not cover.>

## Later requests

<!-- Optional. A later spec or finding that matched this concept. -->

- <specs/NNN-slug or finding>: <one line>
