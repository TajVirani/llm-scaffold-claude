<!--
Reference for project-standards steps 3-6: the mandatory coverage list. The interview is not finished, and the ledger is not approved, until every item below that applies has an `H` answer (or the human delegated it).
Sources: first-party. Shape taken from a user-supplied architecture document (stack table with one library per concern, core decisions with rationale, naming per layer with examples, structure principle plus full tree, boundaries and layering, format and communication, process patterns, bootstrap order, deferred list).
-->

# Mandatory coverage

**Applies** on greenfield to every item; on brownfield, add-work-type and refresh to every item discovery left `Unknown`, `mixed` or `confidence: low`. Repeat the per-work-type items (C1, C3, C4, C6) for each agreed work type.

An item is **covered** when its baseline row's Evidence is `H human <date>` (the human picked or confirmed it) or `H delegated <date>` (the human said "you choose" for that item; you then pick and the row says so). `A` rows never cover an item. "Not needed" is a valid answer: it becomes a Deferred row with the human's reason.

## C1. Libraries per concern (per work type)

Ask for each concern the work type has, with 2-3 verified candidates from discovery ([../modules/discovery.md](../modules/discovery.md) "Library candidates"). The human picks one per concern; the profile records it with the alternatives it excludes.

| Work type kind | Concerns |
| --- | --- |
| Backend / API | runtime and version; framework or router; HTTP middleware (CORS, request logging, recovery); DB driver; ORM, query builder or raw SQL (and codegen such as sqlc); migrations tool and when they run; validation; config and secrets loading; logging (structured, levels); auth (identity provider, session or token library); background jobs (if any); testing (runner, assertions, fakes, DB in tests); lint and format |
| Frontend / UI | framework and version; build and dev server; routing; server state and data fetching; client/UI state; forms; validation (shared with backend?); styling; component kit; HTTP client or RPC; dates and i18n (if any); testing (unit, component, browser); lint and format |
| CLI, worker, library, data, infra | entry and argument parsing; I/O and persistence; config; logging; error reporting; testing; packaging or release; lint and format |
| Every work type | package manager; monorepo tool (or none); the tool and exact command for each Toolchain key (`lint`, `typecheck`, `format`, `boundary`, `test`, `e2e`, `serve`, `serve_ready`), which project-setup writes into the profile verbatim; for each work type with a `test` key, also how its runner excludes a list of tests (`test_scoped`, optional: the `test` command with `$WF_EXCLUDE_TESTS` or `$WF_EXCLUDE_TESTS_FILE` excluded, e.g. Vitest `--exclude`, Playwright `--grep-invert`; without it a failing `test` while Phase 1 tests are still red is only recorded `unscoped`, a non-blocking warning). TS/JS `boundary` is always dependency-cruiser (the boundary check and the caches run it): state it, do not ask. For `test-harness` and `e2e-browser`, offer the D26 example profiles (`.agents/skills/project-setup/assets/profiles/examples/`) as the candidate answer |

## C2. Core decisions (project-wide, each with a rationale)

Paradigm (layered, hexagonal, ...); starter (or none); data store; ID scheme; timestamps and time zones; migrations policy; caching; search (if any); auth flow, session storage and authorization point; secrets handling; API style (REST, RPC, GraphQL) and shared contract source; real-time (if any); deployment target; logging destination.

## C3. Folder structure (per work type)

- **Methodology**: by feature or by layer; colocated tests and styles or a separate tree; the shared-code promotion rule (when code moves from a feature to a common parent, then to root-level shared folders); maximum depth; where config, env, assets, generated code and migrations live.
- **The concrete layout tree**: draft it from the methodology, show it, and get it confirmed. It is kept: it goes to the profile's File locations (one line per folder with what lives there and what never does), and the principle goes to rules or profile prose.

## C4. Naming per layer (per work type, each with an example)

Files (components, modules, tests); types and interfaces; functions and variables; constants; services and error types; DB tables, columns, foreign keys, indexes, enums; API routes, route params, query params; JSON and wire field casing; event or message names.

## C5. Boundaries and layering

Module ownership and allowed dependencies; shared core paths; layering inside a module (for example handler → service → repository) and what each layer may import; type-only imports across workspaces; the one data access path; side-effect pipelines (sync or async, failure isolation).

## C6. Format and communication contracts (per work type that has them)

Success response shape (envelope or not); error shape and code scheme; list and pagination shape; date and time wire format; JSON casing; message or event envelope; frontend state split (what lives in server state vs client state).

## C7. Process patterns

Error handling per side (where caught, how reported, never swallowed); loading UI; auth flow steps; validation timing (client, server, both); retry and backoff; optimistic updates or auto-save (if any); styling rules. Ask only the ones the stack has; mark the others Deferred with "not in scope".

## C8. Bootstrap order

The ordered setup steps and every "A must exist before B" constraint (for example auth before any data route). Constraints become rules; the step list itself goes to the project baseline ADR.

## C9. Deferred list

What this baseline deliberately leaves open (CI/CD, monitoring, scaling, caches, ...), each with the reason it can wait. Ask explicitly; an empty list needs the human's "nothing deferred".
