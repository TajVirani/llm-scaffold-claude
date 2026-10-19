<!--
Module of project-setup: create the shared project files from the templates in ../assets/.
Sources: first-party; plan PLAN/decision-flow-reference.md "Persistent files", 00.1-00.4, 00.8, 00.11, 00.16; assetlist D8, D15, D20, D22, D35, D44, D46. Single- vs multi-context glossary choice (offer multi-context only on monorepo signals) adapted from mattpocock/skills/skills/engineering/setup-matt-pocock-skills/SKILL.md@49dd158 Section C (MIT).
-->

# Shared files

Create each file only when it is absent; an existing file is kept and reported as "kept". `A` = `.agents/skills/project-setup/assets`.

| Target | Source | What to do when creating it |
| --- | --- | --- |
| `GLOSSARY.md` | `A/GLOSSARY.md` | Replace `{Context name}` and the one-line description with the human's answer. Leave the comment block: `domain-modeling` deletes it when the first term is added. |
| `docs/capabilities.md` | `A/docs/capabilities.md` | Delete the example `CAP-001` row, so the table has its header only. 5.3 numbers the first real capability `CAP-001` (highest + 1; D44). |
| `docs/rules.md` | `A/docs/rules.md` | Fill it with the human (see "Rules" below). |
| `docs/decisions/pitfalls.md` | `A/docs/decisions/pitfalls.md` | Copy as is. The comment holds the entry shape the retrospective follows at 5.7. |
| `deferred/.gitkeep` | none | Create an empty file so git keeps `deferred/`. `deferred/archive/` is created when the first item is archived (00.9). |
| `agent-overrides.yaml` | `A/agent-overrides.yaml` | Copy as is: comments only, no entries (D35). |
| `profiles/TEMPLATE.md` | `A/profiles/TEMPLATE.md` | Copy as is (00.16). Profiles are filled from it in [profiles.md](profiles.md). |

There is no `docs/decisions/status.md` (D22). `docs/decisions/adr/` and `docs/decisions/retrospectives/` are created when their first file is written. `docs/cache/` and `specs/` are created by the flow.

Write Tier A files (`GLOSSARY.md`, `docs/**`, `profiles/**`) with Write or Edit, so the guard sees each write.

## Multi-context glossary

Default to one root `GLOSSARY.md`. Only when step 2 found monorepo signals, offer the multi-context layout: a root `GLOSSARY-MAP.md` that lists one `GLOSSARY.md` per context. Create those files from the same template on a yes. The format is in `.agents/skills/domain-modeling/assets/GLOSSARY-FORMAT.md`.

## Rules

`docs/rules.md` has five sections. The headings **Ownership** and **Shared core** are fixed, and each holds exactly one fenced `yaml` block. `generate-boundary-config.sh` parses those blocks, and `resolve-launch`, `integration` and `review-standards` read them (D15, D20). The rules stay tool-neutral: write globs and module names in the blocks, never dependency-cruiser syntax.

1. **Ownership.** Propose modules from the directory layout: one module per top-level feature or domain folder, with its globs in `owns` and the modules it imports today in `may_depend_on`. Check the imports with a quick grep before proposing them. The human confirms or corrects the list. Write it into `modules:`, replacing `{}`. Keep the comment lines above it.
2. **Shared core.** Propose the folders every module imports (for example `src/shared/**` or `src/lib/**`). Write them into `shared_core.paths`. A project with no shared core keeps `paths: []`.
3. **Cross-cutting policy, External systems, Required versions.** Take required versions from the files that declare them (`engines`, `.nvmrc`, `packageManager`, `.tool-versions`, `go.mod`, `pyproject.toml`). Ask the human only for policy and external systems. Each line passes the line test in the template comment, and a prohibition names its permitted alternative. Replace each `{...}` placeholder bullet with real lines, or delete it when there is nothing to say yet.
4. Delete the template's top comment block once the file is filled.

A new project with no modules yet keeps `modules: {}`, which generates an empty but valid boundary config. Add modules when the code grows them (5.3).

Done when every file in the table exists, and `docs/rules.md` either has agreed Ownership and Shared core blocks or explicitly keeps them empty.
