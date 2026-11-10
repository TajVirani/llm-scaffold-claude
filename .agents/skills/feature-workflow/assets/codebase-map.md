<!--
File: Template for .workflow/specs/NNN-slug/codebase-map.md: per-feature extracts of the existing system. Not Tier A: it holds what this feature needs, each item pointing back to its source.
Created by modules/discovery.md at 0.2.6. Filled at 0.2.4 (`retrieval`), 0.2.5 (`library-evaluation`) and 0.4.6 (`module-audit`, modules/discovery-impact.md). Source of recommended answers at 0.3.11; implementation launches receive the relevant extract.

Writing rules:
  - Every extract carries its source: `path/to/file.ext:line` for code, the document path and heading for Tier A and .workflow/deferred/ files.
  - Extracts describe what exists. Recommendations belong to the questioning loop and the design log, not here.
  - Each agent's section is written from its return only. The main session never pastes the full corpus in (design rule 3).
  - Delete a section's placeholder rows when it has entries; write "None." when the agent returned nothing.
  - Delete this comment in the finished file.
-->

# Codebase map: <feature title>

Affected area: <modules and paths identified at 0.2.1>

## Relevant code

<!-- From `retrieval` (0.2.4), drawn from the code. -->

| Item | What it does today | Source |
| --- | --- | --- |
| <module, function, type or flow> | <one line> | `<path:line>` |

## Seams and interfaces

<!-- From `retrieval` (0.2.4); `module-audit` (0.4.6) adds to it. The interfaces a change would go through or test against. -->

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| <name> | <signature or type> | <who uses it> | `<path:line>` |

## Prior decisions

<!-- From `retrieval` (0.2.4): ADRs, rules, pitfalls, retrospectives, and .workflow/deferred/ items that match the affected area by concept. -->

| Decision or item | What it says | Source |
| --- | --- | --- |
| <ADR, rule, pitfall or deferred item> | <the constraint or decision, one line> | `<docs/... or .workflow/deferred/...>` § <heading> |

## Library options

<!-- From `library-evaluation` (0.2.5), against .workflow/rules.md "External systems". -->

| Concern | Option | Cost | Licence | Fit | Source |
| --- | --- | --- | --- | --- | --- |
| <concern> | <library or API, version> | <price, size, maintenance load> | <SPDX id> | <fits / conflicts with: reason> | <docs URL or repo> |

## Module audit

<!-- From `module-audit` (0.4.6) on the owning module only. -->

Owning module: <module name from .workflow/rules.md Ownership>

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | <existing code the change should use> | `<path:line>` |
| gap | <what the module lacks for this change> | `<path:line>` |
| constraint | <invariant or convention the change must keep> | `<path:line>` |

## Not found

<!-- What an agent looked for and did not find, with where it looked. Absence is a finding. -->

- <what was searched for>: <paths searched>. Reported by <agent>.
