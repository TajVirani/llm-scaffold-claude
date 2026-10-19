---
cache_stamps:            # generated_at_commit of each docs/cache/ file the extracts were drawn from; null when that cache was not read
  modules: null
  flows: null
  architecture: null
---
<!--
File: Template for specs/NNN-slug/codebase-map.md: per-feature extracts of the existing system. Not a cache and not Tier A: it holds what this feature needs, each item pointing back to its source.
Created by modules/discovery.md at 0.2.6. Filled at 0.2.4 (`retrieval`), 0.2.5 (`library-evaluation`), 0.2.8 (stamps after `cache-regeneration` and publish-cache.sh) and 0.4.6 (`module-audit`). Source of recommended answers at 0.3.11; implementation launches receive the relevant extract.
Sources: section-per-agent layout and `cache_stamps` are first-party (PLAN/decision-flow-reference.md "Per-feature files", "Sub-agent task types", 0.2.4-0.2.8, 0.4.6). Inventory tables, path citations and a "not found" list adapted from .agents/skills/design-pattern-doc/TEMPLATE.md (first-party). "Document what exists, do not critique" and the commit stamp on research output adapted from humanlayer/humanlayer .claude/commands/research_codebase.md (Apache-2.0; idea only, no text copied). Stamp values follow regenerate-caches/assets/cache-frontmatter.md.

Frontmatter contract (mikefarah yq v4, `--front-matter=extract`; D38):
  - cache_stamps: a map with exactly the keys modules, flows, architecture (the Tier B cache types). Each value is the 40-hex `generated_at_commit` copied from that cache's frontmatter at the time it was read, or null when the cache was not read.
  - After 0.2.8 regenerates a cache, update its stamp here. A stamp that differs from the cache's current `generated_at_commit` means the extracts drawn from it may be stale.
  Add no other keys.

Writing rules:
  - Every extract carries its source: `path/to/file.ext:line` for code, the document path and heading for Tier A, Tier B and deferred/ files.
  - Extracts describe what exists. Recommendations belong to the questioning loop and the design log, not here.
  - Each agent's section is written from its return only. The main session never pastes the full corpus in (design rule 3).
  - A wrong cache is a stamp problem, fixed by regeneration, never by editing an extract to disagree with its source.
  - Delete a section's placeholder rows when it has entries; write "None." when the agent returned nothing.
  - Delete this comment in the finished file.

Validate the frontmatter:
  yq --front-matter=extract -e '
    ((.cache_stamps | keys | sort | join(",")) == "architecture,flows,modules") and
    ([.cache_stamps[] | select(. == null or (tostring | test("^[0-9a-f]{40}$")))] | length) == 3
  ' specs/NNN-slug/codebase-map.md
-->

# Codebase map: <feature title>

Affected area: <modules and paths identified at 0.2.1>

## Relevant code

<!-- From `retrieval` (0.2.4), drawn from Tier B caches and the code. -->

| Item | What it does today | Source |
| --- | --- | --- |
| <module, function, type or flow> | <one line> | `<path:line>` or `docs/cache/<type>.md` § <heading> |

## Seams and interfaces

<!-- From `retrieval` (0.2.4); `module-audit` (0.4.6) adds to it. The interfaces a change would go through or test against. -->

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| <name> | <signature or type> | <who uses it> | `<path:line>` |

## Prior decisions

<!-- From `retrieval` (0.2.4): ADRs, rules, pitfalls, retrospectives, and deferred/ items that match the affected area by concept. -->

| Decision or item | What it says | Source |
| --- | --- | --- |
| <ADR, rule, pitfall or deferred item> | <the constraint or decision, one line> | `<docs/... or deferred/...>` § <heading> |

## Library options

<!-- From `library-evaluation` (0.2.5), against docs/rules.md "External systems". -->

| Concern | Option | Cost | Licence | Fit | Source |
| --- | --- | --- | --- | --- | --- |
| <concern> | <library or API, version> | <price, size, maintenance load> | <SPDX id> | <fits / conflicts with: reason> | <docs URL or repo> |

## Module audit

<!-- From `module-audit` (0.4.6) on the owning module only. -->

Owning module: <module name from docs/rules.md Ownership>

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | <existing code the change should use> | `<path:line>` |
| gap | <what the module lacks for this change> | `<path:line>` |
| constraint | <invariant or convention the change must keep> | `<path:line>` |

## Not found

<!-- What an agent looked for and did not find, with where it looked. Absence is a finding. -->

- <what was searched for>: <paths searched>. Reported by <agent>.
