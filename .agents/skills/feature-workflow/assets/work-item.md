---
origin_spec: .workflow/specs/NNN-slug         # the spec during whose work this was discovered
origin_step: "0.0"                  # plan step the work was found at, e.g. "3.4" or "4.4" (quoted string)
discovered_at: YYYY-MM-DD
status: open                        # open | promoted | moved-to-deferred | dismissed
# promoted_to: .workflow/specs/NNN-slug       # present only when status is promoted: the new spec seeded from this item
kind: bug                           # bug | requirement | refactor | scope-expansion | decision | budget-split
---
<!--
File: Template for .workflow/specs/work-backlog/<NNN-slug>-disc-<###>.md, one discovered-work item. <NNN-slug> is the origin spec; <###> increments per origin spec. The file sits outside the origin spec's folder because that spec will not solve it.
Written by the main session only: at 00.26 (user chose to tackle it as a next feature, or a size-budget split), at 5.9 (the `moved-to-deferred` status update only; 5.9 offers and hands off, it does not delete) and by the new spec's 0.1.4 (status `promoted` and promoted_to). Deletion of a promoted item happens at the new spec's 0.6 (0.3.20 on the light path). Sub-agents are denied (check-write.sh). Not the .workflow/deferred/ shelf (00.8-00.10), which holds out-of-scope work decided during discovery or review.

Frontmatter contract (read with mikefarah yq v4, `--front-matter=extract`):
  - origin_spec: repo-relative spec folder. origin_step: string. discovered_at: ISO date.
  - status: open | promoted | moved-to-deferred | dismissed. Set `open` at 00.26. At the new spec's 0.1.4: start it -> `promoted` (and promoted_to). At 5.9: move it to .workflow/deferred/ via deferred-handoff -> `moved-to-deferred`; keep it -> stays `open`; `dismissed` when the user drops it.
  - promoted_to: spec folder path; present only when status is promoted.
  - kind: bug | requirement | refactor | scope-expansion | decision | budget-split.
  Add no other keys.

Lifecycle: a promoted item is DELETED once the new spec it seeded finishes discovery (0.6, or 0.3.20 on the light path), so no stale doc remains. Before deleting, copy the item's problem, evidence and suggested scope into the new spec (its Why and Assumptions as fit) and set the new spec's `origin:` frontmatter to this file's name, with a one-line "Origin" note in the spec body. Items that are `open`, `moved-to-deferred` or `dismissed` stay until their own resolution.

Writing rules:
  - Facts only, with sources. Evidence is file:line, a failing test, or the agent's return quoted. Leave time estimates out.
  - Delete this comment in the finished file.

Validate the frontmatter (prints true, exits non-zero otherwise):
  yq --front-matter=extract -e '
    ((.origin_spec | tag) == "!!str") and
    ((.origin_step | tag) == "!!str") and
    ((.discovered_at | tag) == "!!str" or (.discovered_at | tag) == "!!timestamp") and
    (.status | test("^(open|promoted|moved-to-deferred|dismissed)$")) and
    (.kind | test("^(bug|requirement|refactor|scope-expansion|decision|budget-split)$")) and
    ((.status == "promoted") == ((.promoted_to // "") != ""))
  ' .workflow/specs/work-backlog/NNN-slug-disc-001.md
-->

# <Short title of the discovered work>

## Problem

<What is wrong or missing, in two or three sentences, without reference to the current implementation approach.>

## Evidence

- <`path:line`, a failing test name with its output, or the agent return that reported it, quoted>

## Why not a blocker

<Why the origin spec's goal can be met without this. Name the capability or journey that is unaffected.>

## Suggested scope and size

- Scope: <what a next feature would cover, and what it would leave out>
- Size: <number of tasks and modules likely touched, compared with the `## Size budget` defaults in .workflow/rules.md>

## Links

- Origin spec: [spec.md](../NNN-slug/spec.md)
- Design log entry: [design-log.md](../NNN-slug/design-log.md) (section <date>)
- Promoted to: <spec link, only when promoted>
- Deferred file: <.workflow/deferred/slug.md, only when moved-to-deferred>
