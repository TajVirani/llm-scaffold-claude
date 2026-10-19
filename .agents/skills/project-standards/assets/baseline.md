<!--
File: Template for .standards-staging/baseline.md, the project-standards staging draft (gitignored). Not a source of truth: every row is written to its Destination at step 7, and the draft is then discarded.
Sources: first-party. Section list adapted from a user-supplied architecture document (stack, core decisions, naming, structure, boundaries, format and communication, process patterns, bootstrap order, deferred); invariants with an explicit Deferred list from bmad-code-org/BMAD-METHOD skills/bmad-architecture/assets/spine-template.md@8f0d50e (MIT; pattern only); the existing-instructions ledger and its actions from bmad-code-org/BMAD-METHOD skills/bmad-project-context/SKILL.md@8f0d50e step 1 (MIT; pattern only).
Columns:
  Line         one concrete, checkable rule, with an example where it helps (`users`, `idx_items_project_id`). A prohibition names the permitted alternative.
  Destination  rules.md § <section> | profile:<work-type> § <section> | adr:<slug> | pr-quality:<check> | lint:<config path> | agents-block § <section> | glossary | pitfall | drop
  Enforcement  boundary | lint | typecheck | test | mini-review | pr-quality | prose | adr | none (drop only). See enforcement-map.md.
  Evidence     discovery `path:line` | human <date> | import <doc>:<line> | <URL or command> (versions) | [ASSUMPTION] (fast path)
  Status       draft, then approved | modified | rejected at step 6
  Written      file and section, filled at step 7
Delete rows that do not apply; never leave a section with only the example row.
-->
# Standards baseline: {project}

Mode: {greenfield | brownfield | refresh | add-work-type} · Work types: {list} · Head: {sha} · Path: {coaching | fast}

## Stack

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Runtime: {tool} {version}. | rules.md § Required versions | prose | {declaring file:line or URL} | draft | |

## Core decisions

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Paradigm: {layered, hexagonal, ...}; starter: {name or none}. | adr:project-baseline | adr | human {date} | draft | |

## Naming

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| N1 | {Kind}: {convention} → `{example}`. | profile:{work-type} § Language and style rules | {lint \| mini-review} | | draft | |

## Structure

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| T1 | {Kind of file}: `{path}`. Never in `{path}`. | profile:{work-type} § File locations | prose | | draft | |

## Boundaries

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| B1 | Module `{name}` owns `{glob}` and may depend on {modules}. | rules.md § Ownership | boundary | | draft | |
| B2 | {Layer} imports only {layer}: {rule}. | lint:{config path} | lint | | draft | |

## Format and communication

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | Errors: `{shape}` → `{example}`. | profile:{work-type} § Language and style rules | {typecheck \| mini-review} | | draft | |

## Process patterns

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | {Pattern}: {rule}. | {destination} | {class} | | draft | |

## Bootstrap order

<!-- Greenfield only. A "must exist before" constraint is a rule; the step list itself is work for the first features, so it goes to drop with that reason. -->

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| O1 | {A} exists before any {B}. | rules.md § Cross-cutting policy | pr-quality | | draft | |

## Deferred

| # | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- |
| D1 | {Not decided yet}: {reason it can wait}. | adr:project-baseline § Deferred | adr | | draft | |

## Existing instructions

<!-- Brownfield, refresh and adoption: one row per independently meaningful instruction found at step 1. Action: retain | rewrite | relocate | automate | delete. A delete names its ground (stale, mechanically enforced, harmful or contradictory, approved as a line item). -->

| # | Source | Instruction | Action | To | Ground or reason | Status |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | `{file}:{line}` | {text} | {action} | {destination or —} | {reason} | draft |

## Open questions

- {Question} · recommended: {answer}
