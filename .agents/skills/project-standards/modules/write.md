# Write

Write from the main session with Write or Edit, so the Tier A guard sees each write. Write only rows whose Status is `approved` or `modified` (the modified text). After each file, fill the row's Written cell with the file and section.

## Stamp placement

Every doc written this run gets one line, `<!-- verified_at_commit: <40-hex sha> -->`, with the sha from `git rev-parse HEAD`. Replace an existing stamp line; never add a second one.

| Doc | Where the stamp goes | Why it is safe |
| --- | --- | --- |
| `.workflow/rules.md` | The line after `# Rules` | `generate-boundary-config.sh` reads only the fenced blocks under `## Ownership` and `## Shared core` |
| `.workflow/profiles/<work-type>.md` | The line after `# Profile: <work-type>` | `run-toolchain.sh`, `resolve-launch.sh` and `evidence-capture.sh` read by `##` heading only |
| ADR | The line after the H1 | Frontmatter keeps only `status:` (ADR-FORMAT) |
| `.workflow/pr-quality/<check>.md` | The line after the H1 | pr-quality hands the whole file to the agent; a comment changes no check |
| AGENTS.md block | The provenance comment inside the markers | See [../assets/agents-block.md](../assets/agents-block.md) |

Lint config files are not stamped; the profile that names them is.

## .workflow/rules.md

When the file is absent (standalone, before project-setup), copy `.agents/skills/project-setup/assets/docs/rules.md`.

- **Ownership, Shared core**: write into the fenced `yaml` blocks only, in the tool-neutral schema the block comments give (module → `owns` globs → `may_depend_on` names; `shared_core.paths`). Keep the comment lines. Never write boundary-tool syntax there.
- **Cross-cutting policy, External systems, Required versions**: one terse imperative bullet per row. A prohibition names the permitted alternative. Delete each `{...}` placeholder bullet the section still holds.
- **Size budget**: leave it unchanged.

Done when every rules row is in its section and the file has no `{...}` placeholder in a section this run wrote.

## .workflow/profiles/<work-type>.md

When the file is absent, copy `.workflow/profiles/TEMPLATE.md` (else `.agents/skills/project-setup/assets/profiles/TEMPLATE.md`), and replace `{work-type}`. Delete the template comment wherever it is still present. Keep the five headings and the Toolchain keys exactly as written; scripts parse them.

- **File locations**: the structure principle first (by feature or by layer, test colocation, promotion rule, depth), then one line per folder of the agreed layout tree, in tree order, each naming what lives there and what never does.
- **Approved libraries per concern**, **Language and style rules**: one line per row. An approved library line names the concern, the library, its version, and the candidates it excludes.
- **Mini-review checklist**: one `- [ ] <item>` per `mini-review` row. Only judgement no tool can make.
- **Toolchain**: in the `phase: standards` call from project-setup, leave the block untouched; project-setup writes it from the approved Toolchain rows. In the `phase: lint` call (and standalone), set `config.lint` to the lint config path and extend `rule_set` with what this run added (for example `anti-slop plus project layering rules`); standalone, also write the approved Toolchain rows. Change a command key only through an approved row.

Done when every profile row is in its section and no placeholder line remains in a section this run wrote.

## ADRs

Follow `.agents/skills/domain-modeling/assets/ADR-FORMAT.md` and start from its `adr.md`. Number from the highest file in `.workflow/decisions/adr/` plus one; create the folder when it is absent.

- **The project baseline ADR** (`NNNN-project-baseline.md`, `0001` in a new project; write it once, supersede it later per ADR-FORMAT): `status: accepted`; the 1-3 sentence decision names the paradigm and the starter (or "no starter"); a `## Bootstrap order` list (the agreed steps, greenfield only); a `## Deferred` list with each deferred item and the reason it can wait; `## Considered Options` only when a rejected alternative is worth remembering.
- **Other `adr` rows**: one ADR each, only when the row passes the three-part test (hard to reverse, surprising without context, a real trade-off). A row that fails the test becomes a `prose` line in `.workflow/rules.md` or the profile instead; say so in the report.

Done when every `adr` row is an ADR or was rerouted with the human's agreement.

## .workflow/pr-quality/<check>.md

One file per group of related PR-level judgement rows (for example `auth-before-data.md`), copied from `.agents/skills/pr-quality/assets/project-check.template.md`. The H1 names the report section. Fill Objective, Scope (a trigger matched against the diff, and the self-skip), Checks (each a concrete rule: the pattern to flag and the sanctioned alternative), What to report and What NOT to flag. Delete the template comment. The scaffold never ships or overwrites these files.

Done when every `pr-quality` row is a Checks line in exactly one file.

## Lint config

Runs in the `phase: lint` call when project-setup called you (the config exists only once the toolchain is installed), else at step 7. Write `lint` rows into the config the profile's Toolchain names (`config.lint`, else the file the `lint` command reads). Merge into the existing file and keep every existing entry. Module-to-module rules stay in `.workflow/rules.md` § Ownership; the generated boundary config is never hand-edited. Lint config holds the rules finer than a module: layering inside a module, type-only imports, banned libraries.

For oxlint (`.oxlintrc.json`):

- Layering: one `overrides` entry per layer, `files` set to that layer's globs, with `no-restricted-imports` `patterns` entries (`group` globs plus a `message` naming the permitted path). Example: files `["server/src/features/*/routes.ts"]` with group `["**/repository"]` and message `Routes call the service; only services import repositories.`
- Type-only imports: `no-restricted-imports` `paths` entries with `allowTypeImports: true` (oxlint supports it on `paths`, not on `patterns`), one per import specifier.
- Banned libraries: `paths` entries naming the package and the approved alternative in `message`.

For another linter, use its equivalent (ESLint `no-restricted-imports` or `@typescript-eslint/no-restricted-imports` with `allowTypeImports`; Biome `noRestrictedImports` under `overrides`; Python import-linter `layers` contracts) and look up its current options before writing them.

Done when every `lint` row is a rule in the config, and the profile's `rule_set` names it.

## The AGENTS.md block

Fill [../assets/agents-block.md](../assets/agents-block.md) from the written docs.

- **AGENTS.md exists with the markers**: replace only the text between `<!-- project-standards:begin -->` and `<!-- project-standards:end -->`.
- **AGENTS.md exists without them**: append the block at the end of the file.
- **AGENTS.md is absent**: create it holding only the block.
- **CLAUDE.md**: when it is absent, create it as the single line `@AGENTS.md`. When it exists without that import, adding the line is an Existing instructions row like any other, approved at step 6.

Text outside the markers changes only through a settled Existing instructions row.

Done when the block sits between exactly one pair of markers, and every pointer in it names a path that exists.

## Other destinations

- `glossary`: hand the term to the `domain-modeling` skill; this skill does not write `.workflow/GLOSSARY.md`.
- `pitfall`: only with an observed failure as evidence; append it to `.workflow/decisions/pitfalls.md` in the entry shape its comment gives.
- `drop`: nothing is written; the reason goes in the report.
