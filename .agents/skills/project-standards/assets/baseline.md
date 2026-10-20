<!--
File: Template for .workflow/.standards-staging/baseline.md, the project-standards staging draft (gitignored). Not a source of truth: every row is written to its Destination at step 7, and the draft is then discarded.
Columns:
  Line         one concrete, checkable rule, with an example where it helps (`users`, `idx_items_project_id`). A prohibition names the permitted alternative.
  Destination  rules.md § <section> | profile:<work-type> § <section> (when project-setup called project-standards, it writes the Toolchain rows itself) | adr:<slug> | pr-quality:<check> | lint:<config path> | agents-block § <section> | glossary | pitfall | drop
  Enforcement  boundary | lint | typecheck | test | mini-review | pr-quality | prose | adr | none (drop only). See enforcement-map.md.
  Evidence     a one-letter tag, then its source: D discovery `path:line` | H human <date> | H delegated <date> | I import <doc>:<line> | V <URL or command> (versions, library candidates) | A [ASSUMPTION] (your draft, nobody confirmed it)
  Cov          the coverage.md item the row answers (C1-C9), or blank. In an item that applies (coverage.md "Applies"), only an H tag covers it: an A, I or V row there blocks approval at step 6 until the human answers or delegates.
  Status       draft, then approved | modified | rejected at step 6
  Written      file and section, filled at step 7
Delete rows that do not apply; never leave a section with only the example row.
-->
# Standards baseline: {project}

Mode: {greenfield | brownfield | refresh | add-work-type} · Work types: {list} · Head: {sha} · Path: {coaching | fast ("<the human's words>")}
Evidence: {n} H · {n} D · {n} I · {n} V · {n} A (of which {n} in a mandatory coverage item) · Coverage open: {C-ids, or none}

## Stack

<!-- One row per C1 concern per work type: the picked library, its version, and the candidates it excludes. Toolchain commands are rows too, destination profile:{work-type} § Toolchain. -->

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 | C1 | Runtime: {tool} {version}. | rules.md § Required versions | prose | {V URL or D file:line}; H {date} | draft | |
| S2 | C1 | {Concern}: {library} {version}; not {excluded candidates}. | profile:{work-type} § Approved libraries per concern | {prose \| lint} | H {date}; V {URL} | draft | |
| S3 | C1 | Toolchain `{key}`: `{command}`. | profile:{work-type} § Toolchain | test | H {date} | draft | |

## Core decisions

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C1 | C2 | Paradigm: {layered, hexagonal, ...}; starter: {name or none}. | adr:project-baseline | adr | H human {date} | draft | |

## Naming

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N1 | C4 | {Kind}: {convention} → `{example}`. | profile:{work-type} § Language and style rules | {lint \| mini-review} | | draft | |

## Structure

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | C3 | Structure: {by feature \| by layer}; tests {colocated \| in `{path}`}; shared code is promoted {rule}; max depth {n}. | profile:{work-type} § File locations | prose | | draft | |
| T2 | C3 | `{folder}/`: {what lives here}. Never {what does not}. (One row per folder of the agreed layout tree.) | profile:{work-type} § File locations | {prose \| boundary \| lint} | | draft | |

## Boundaries

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B1 | C5 | Module `{name}` owns `{glob}` and may depend on {modules}. | rules.md § Ownership | boundary | | draft | |
| B2 | C5 | {Layer} imports only {layer}: {rule}. | lint:{config path} | lint | | draft | |

## Format and communication

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | C6 | Errors: `{shape}` → `{example}`. | profile:{work-type} § Language and style rules | {typecheck \| mini-review} | | draft | |

## Process patterns

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | C7 | {Pattern}: {rule}. | {destination} | {class} | | draft | |

## Bootstrap order

<!-- Greenfield only. A "must exist before" constraint is a rule (O1); the agreed step list is one row to adr:project-baseline § Bootstrap order (O2). -->

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| O1 | C8 | {A} exists before any {B}. | rules.md § Cross-cutting policy | pr-quality | | draft | |
| O2 | C8 | Bootstrap order: 1. {step} 2. {step} ... | adr:project-baseline § Bootstrap order | adr | | draft | |

## Deferred

| # | Cov | Line | Destination | Enforcement | Evidence | Status | Written |
| --- | --- | --- | --- | --- | --- | --- | --- |
| D1 | C9 | {Not decided yet}: {reason it can wait}. | adr:project-baseline § Deferred | adr | | draft | |

## Existing instructions

<!-- Brownfield, refresh and adoption: one row per independently meaningful instruction found at step 1. Action: retain | rewrite | relocate | automate | delete. A delete names its ground (stale, mechanically enforced, harmful or contradictory, approved as a line item). -->

| # | Source | Instruction | Action | To | Ground or reason | Status |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | `{file}:{line}` | {text} | {action} | {destination or —} | {reason} | draft |

## Open questions

- {Question} · recommended: {answer}
