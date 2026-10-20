# Shared files

All workflow data lives under one committed folder, `.workflow/`; create it first (`mkdir -p .workflow`). Create each file only when it is absent; an existing file is kept and reported as "kept". `A` = `.agents/skills/project-setup/assets`.

| Target | Source | What to do when creating it |
| --- | --- | --- |
| `.workflow/GLOSSARY.md` | `A/GLOSSARY.md` | Replace `{Context name}` and the one-line description with the human's answer. Leave the comment block: `domain-modeling` deletes it when the first term is added. |
| `.workflow/capabilities.md` | `A/docs/capabilities.md` | Delete the example `CAP-001` row, so the table has its header only. 5.3 numbers the first real capability `CAP-001` (highest + 1). |
| `.workflow/rules.md` | `A/docs/rules.md` | Copy as is. `project-standards` fills it at step 6 of the skill (see "Rules" below). |
| `.workflow/decisions/pitfalls.md` | `A/docs/decisions/pitfalls.md` | Copy as is. The comment holds the entry shape the retrospective follows at 5.7. |
| `.workflow/deferred/.gitkeep` | none | Create an empty file so git keeps `.workflow/deferred/`. `.workflow/deferred/archive/` is created when the first item is archived (00.9). |
| `.workflow/agent-overrides.yaml` | `A/agent-overrides.yaml` | Copy as is: comments only, no entries. |
| `.workflow/profiles/TEMPLATE.md` | `A/profiles/TEMPLATE.md` | Copy as is (00.16). Profiles are filled from it in [profiles.md](profiles.md). |

There is no `.workflow/decisions/status.md`. `.workflow/decisions/adr/` and `.workflow/decisions/retrospectives/` are created when their first file is written. `.workflow/cache/` and `.workflow/specs/` are created by the flow.

Write Tier A files under `.workflow/` with Write or Edit, so the guard sees each write.

## Multi-context glossary

Default to one root `.workflow/GLOSSARY.md`. Only when step 2 found monorepo signals, offer the multi-context layout: a root `.workflow/GLOSSARY-MAP.md` that lists one `GLOSSARY.md` per context, each in that context's own directory. Create those files from the same template on a yes. The format is in `.agents/skills/domain-modeling/assets/GLOSSARY-FORMAT.md`.

## Rules

`.workflow/rules.md` is copied unfilled; `project-standards` fills Ownership, Shared core and the policy sections from discovery and the human's answers. Its fixed headings and `yaml` blocks are a parsed contract: `generate-boundary-config.sh` at step 10 parses them, and a new project with no modules keeps `modules: {}`, which generates an empty but valid boundary config.

Done when every file in the table exists, either created now or kept.
