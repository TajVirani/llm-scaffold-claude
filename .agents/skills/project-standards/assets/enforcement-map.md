<!--
Reference for project-standards steps 5 and 7: which kind of standard goes where, and which mechanism holds it.
Sources: first-party; homes from PLAN/decision-flow-reference.md 00.3, 00.4, 00.16-00.17, "Work profiles" ("if a line would appear identically in every profile, it is a rule"; "tools, then agent") and assetlist D15, D20, D75. "Prefer a check over a line" and the exclude list (aspirational state, manifest restatements) adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/references/best-practices.md@8f0d50e (MIT; pattern only).
-->

# Enforcement map

Each baseline row has one **Destination** (where the line is written) and one **Enforcement** class (what fails when the line is broken). Pick the cheapest class that holds the rule: a tool before judgement, judgement before prose. The classes match the `enforce_by` values `standards-discovery` returns.

## Enforcement classes

| Class | What fails | Who runs it |
| --- | --- | --- |
| `boundary` | the generated dependency-cruiser config (from `.workflow/rules.md` Ownership and Shared core) | the profile `boundary` command at 3.5 |
| `lint` | a rule in the profile's lint config | the profile `lint` command at 3.5 |
| `typecheck` | a compiler setting or a shared type | the profile `typecheck` command at 3.5 |
| `test` | a test that pins the behaviour | the profile `test` command at 3.5 and 3.9 |
| `mini-review` | a profile checklist item judged per task | `profile-mini-review` at 3.7 |
| `pr-quality` | a project check judged across the whole PR | `pr-quality`, one agent per `.workflow/pr-quality/*.md` |
| `prose` | nothing mechanical; the line steers the agent that reads it | coding agents (profile, injected whole), `review-standards` at 4.1 (rules) |
| `adr` | nothing mechanical; records a decision and why | `retrieval` at 0.2.4, `review-standards` at 4.1 |

## Destinations by kind of standard

| Kind of standard | Destination | Enforcement | Note |
| --- | --- | --- | --- |
| Which module owns which paths, and which modules it may import | `.workflow/rules.md` § Ownership | `boundary` | Tool-neutral YAML; the config is generated, never hand-edited (D20) |
| Code every module may import | `.workflow/rules.md` § Shared core | `boundary` | Changed only through the `integration` agent |
| Layering inside a module (route → service → repository) | lint config of the profile | `lint` | Not a rules.md schema change; one `overrides` entry per layer |
| Type-only imports across workspaces (client takes only types from shared schema) | lint config of the profile | `lint` | oxlint: `paths` with `allowTypeImports` |
| Banned library, with its approved alternative | profile § Approved libraries per concern + lint config | `lint` | The profile line names the approved library; the lint rule bans the alternative |
| One library per concern | profile § Approved libraries per concern | `prose` | Injected whole into coding agents |
| File and test placement per work type | profile § File locations | `prose`, or `lint` where a rule exists (file-name case) | |
| Identifier and file naming | profile § Language and style rules | `lint` where the linter has the rule, else `mini-review` | Database naming is usually `mini-review` |
| Compiler strictness | tsconfig (or equivalent) | `typecheck` | The profile line names the setting only when an agent might weaken it |
| Formatting | formatter config | the profile `format` check | No prose line |
| Error shape, response envelope, wire format, message shape | a shared type when expressible, else profile § Language and style rules | `typecheck`, else `mini-review` | |
| Process patterns (error recovery, retry, loading, validation timing) for one work type | profile § Language and style rules + § Mini-review checklist | `mini-review` | |
| Project-wide policy (secrets, frozen or generated paths, never swallow errors) | `.workflow/rules.md` § Cross-cutting policy | `prose` | Would appear in every profile, so it is a rule |
| A policy judged across files or the whole PR (every data route behind auth; a new table has a migration) | `.workflow/pr-quality/<check>.md` + the rules.md policy line | `pr-quality` | |
| Required ordering (A must exist before B) | `.workflow/rules.md` § Cross-cutting policy | `pr-quality` when a diff can break it, else `prose` | |
| External systems and who integrates them | `.workflow/rules.md` § External systems | `prose` | |
| Runtime and tool versions | `.workflow/rules.md` § Required versions | `prose` | From the declaring file, never from this session's environment |
| Paradigm, starter, the deferred list | `.workflow/decisions/adr/NNNN-project-baseline.md` | `adr` | |
| Hard-to-reverse choice with real alternatives (data store, auth provider, API style) | its own ADR | `adr` | Three-part test; failing it reroutes to `prose` |
| How to run and verify the project | AGENTS.md block § Running and verifying | `prose` | Commands come from the profiles' Toolchain blocks |
| A term with one meaning here | `.workflow/GLOSSARY.md` via `domain-modeling` | `prose` | |
| An observed agent mistake | `.workflow/decisions/pitfalls.md` | `prose` | Observed failures only |
| The agreed layout tree (C3) | profile § File locations, one line per folder (what lives there, what never does), with the organising principle as the first line | `prose`, plus `boundary` or `lint` for every folder rule a tool can fail | Kept: it is the decision two builders would otherwise diverge on |
| The bootstrap step list (C8) | `.workflow/decisions/adr/NNNN-project-baseline.md` § Bootstrap order | `adr` | Its "A before B" constraints are separate rules rows |
| Aspirational state, a version list the manifest already states | `drop` | none | The code and the manifests hold these; a stored copy goes stale |

## Moving a line down the ladder

A `mini-review` item that keeps failing in the same way is a candidate `lint` rule; when the rule lands, delete the checklist line (5.2, "Tool rules"). A `prose` line that a tool now fails is deleted on the "mechanically enforced" ground.
