# Seed the model map

`.workflow/model-map.yaml` is the one model table: one row per sub-agent task type, with its tier, the model per host and why. `resolve-launch.sh` reads the launch's model from it as `<task type>.<host>`; a missing value denies the launch with 00.14. It is project-owned: `install.sh` writes it only when it converts an older install's `.workflow/model-map/` folder.

## Defaults

| Tier | Task types | Claude alias | Codex |
| --- | --- | --- | --- |
| cheap | `retrieval`, `fact-lookup`, `profile-mini-review`, `review-targets`, `library-evaluation` | `haiku` | `gpt-6-luna` |
| strong | `implementation`, `integration`, `review-standards`, `review-end-state`, `review-combined`, `module-audit`, `standards-discovery`, `research` | `opus` | `gpt-6-sol` |

The template, [../assets/model-map.yaml](../assets/model-map.yaml), holds these 13 rows filled, each with its `why`.

For Claude write aliases only, never a dated model ID. The Codex values are model names, not aliases, and Codex retires them. When the project uses Codex (`.codex/` exists or the human says so), run `codex debug models` and confirm each Codex default is listed. If one is not, ask the human for the current cheap or strong model and write that instead. If Codex is not installed here, seed the defaults and say in the report that they are unchecked.

Ask the human once: "Seed the defaults above (recommended), or change a tier's Claude alias or Codex model?" Apply the answer to every row in that tier.

## Write it

- **No file yet:** copy the template to `.workflow/model-map.yaml`, then apply the answer above to the rows of the tier it changed.
- **The file exists:** keep every row and value in it. Add only the rows the template has and the file lacks, copied from the template with the answer applied; replace only a value that still reads `<...>`.

Check that every task type has both hosts filled:

```bash
yq '.[] | select(.claude == null or .codex == null or ((.claude + .codex) | test("<")))' .workflow/model-map.yaml
```

Done when `.workflow/model-map.yaml` holds the 13 rows of the table, each `tier` matches it, each `claude` is an alias, each `codex` is a model that `codex debug models` lists (or is reported unchecked), and the check prints nothing.
