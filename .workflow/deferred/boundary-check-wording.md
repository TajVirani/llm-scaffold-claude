---
origin_spec: .workflow/specs/003-bash-cache-extractor
created: 2026-10-22
---

# Boundary check wording for non-JS projects

**Summary:** The architecture cache's Boundary violations section names a dependency-cruiser config even in a project that has no JS/TS code and cannot use one.
**Mode:** AFK
**Origin:** [.workflow/specs/003-bash-cache-extractor](../specs/003-bash-cache-extractor/spec.md), 0.3.17 scope decision, design-log entry 2026-10-21 Scope decision: boundary-check-wording

## Goal

A project whose graph extractors include no boundary tool reads a Boundary violations line that says no boundary checker exists for its languages, instead of pointing at a missing JS tool config.

## Background

Found by the module audit of spec 003, which adds a bash graph extractor. A boundary checker for bash is a non-goal of that spec, so the section stays "Not checked"; only its wording is misleading. The output is valid and passes the cache shape check, so it can wait.

**Current behaviour:** with no boundary config, the section reads "Not checked: no boundary config at <path>/dependency-cruiser.cjs." whatever the project's languages.

**Desired behaviour:** when no profile names an extractor that has a boundary checker, the line says boundary checking is not available for the project's graph extractors. When dependency-cruiser is named and its config is missing, the current line stays.

## Constraints

- The Boundary violations section and its "Not checked" form stay valid for the cache shape check.

## Decisions already made

- Boundary checking for bash is out of scope (spec 003 Non-goals; design-log D1-D13 in [design-log.md](../specs/003-bash-cache-extractor/design-log.md)).

## Evidence

- "Not checked" line built from the boundary config path at `.agents/skills/regenerate-caches/scripts/build-architecture.sh:226-228` as of commit `6704f9384d7756d89752a831d12f364ba6f4aab1`.

## Acceptance criteria

- [ ] With only `graph_extractor: bash` profiles and no boundary config, the section's line does not name dependency-cruiser.
- [ ] With a `dependency-cruiser` profile and no config, the line is unchanged.
- [ ] Both bodies pass `check-staged-cache.sh architecture`.

## Out of scope

- A boundary checker for bash or any other language.
