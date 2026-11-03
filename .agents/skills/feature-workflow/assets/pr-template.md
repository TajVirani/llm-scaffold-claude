<!--
File: Template for .workflow/specs/NNN-slug/pr-body.md: the Sign-off PR description. No frontmatter.
Filled by modules/sign-off.md at 5.4 and approved by the stakeholder at 5.5. At 5.8 it moves with the spec into the Done folder
and is published unchanged apart from the spec path the move rewrites, as the PR/MR description or the local merge message.
scripts/check-pr-body.sh checks the filled body at 5.4, and at 5.8 before and after the move.

Rules:
  - Keep the ten `##` headings exactly as written and in this order; reviewers and later checks read each section on its own.
  - Fill each section from evidence in the spec folder (commands run and their output, review findings, report.md), never from claims.
  - Replace each section's guidance comment with its text. HTML comments do not count as content: a section left holding
    only its comment fails the check as empty. Write "None." in a section with nothing to say rather than leaving it blank.
  - Delete this comment in the filled file.
-->

## Link to issue

<!-- The tracker issue this spec delivers: the `tracker_issue` URL from spec.md on one line, then `Closes #<n>` on the
next, <n> being the number the URL ends in, so merging the PR closes the issue. When `tracker_issue` is "" or absent
(the project has no tracker), use this fixed stub line:
No tracker issue yet: the workflow does not create one when a spec starts. -->

## What changed

<!-- Bullets, one per user-visible or reviewer-visible change, from report.md Summary and Capabilities. -->

## Why the change

<!-- Bullets from spec.md Why and Capabilities (each capability's intent): the problem and who it is for. -->

## Why this approach

<!-- From design-log.md: the Placement entry (owning module and the alternatives ruled out) and the Impact
classification (what is created, extended or refactored). Say why this shape over the alternatives. -->

## Special things to note

<!-- Always link the spec's report.md and each task PR/MR (`pr` on the task records). Then list, from report.md
Known gaps and Deferred, skipped gates, known limits and follow-up items with their links to the deferred files;
when both are empty, write "None." in place of that list, after the links. -->

## How to test

<!-- Numbered steps a reviewer can run, each with its expected result, from report.md How to verify. -->

## Blast radius

<!-- What the change can affect, from the `files` list of budget-check.sh (the reviewed files, tests excluded):
the modules and callers those files reach, and what stays untouched. -->

## Risk and reversibility

<!-- Two lines, each a score from its scale, then " - " and the reason, drawn from report.md Known gaps and Deferred:
Risk: Low|Medium|High - <what could go wrong and how likely>
Reversibility: Easy|Moderate|Hard|Irreversible - <what undoing it takes>
Irreversible requires Risk: High. -->

## Areas, concepts and seams changed

<!-- From codebase-map.md Seams and interfaces and Module audit: the modules, glossary concepts and interfaces this
change touches, with the interfaces whose shape changed named first. -->

## How to undo this PR

<!-- The steps to undo the change after merge (revert commit, data or settings to restore). When it cannot be undone,
say why here and set Risk: High above. -->
