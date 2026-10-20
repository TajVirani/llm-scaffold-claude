<!--
Module of project-setup: seed <project>/.workflow/model-map/<task-type>.md for every task type.
Sources: first-party; plan PLAN/decision-flow-reference.md 00.11-00.14, "Sub-agent task types" (default tier column), "Model selection"; assetlist D12, D23, D34, D35, D80. Claude aliases are Claude Code built-ins (haiku, sonnet, opus). Codex defaults gpt-6-luna and gpt-6-sol are model names from the Codex 0.155.1 model list (G8 closed); they get retired, so they are checked against `codex debug models`. resolve-launch.sh treats empty values and `<...>` placeholders as unset and ignores `fallback`.
-->

# Seed the model map

`.workflow/model-map/` is the lowest-precedence model source. `resolve-launch.sh` uses it for a host only when neither `.workflow/agent-overrides.yaml[type][host]` nor the agent definition's `models.<host>` gives a model (D35). It is project-owned, and `install.sh` never touches it.

## Defaults

| Tier | Task types | Claude alias | Codex |
| --- | --- | --- | --- |
| cheap | `retrieval`, `fact-lookup`, `profile-mini-review`, `review-targets`, `library-evaluation` | `haiku` | `gpt-6-luna` |
| strong | `implementation`, `integration`, `review-standards`, `review-end-state`, `module-audit`, `cache-regeneration`, `standards-discovery` | `opus` | `gpt-6-sol` |

For Claude write aliases only, never a dated model ID (D23). The Codex values are model names, not aliases, and Codex retires them. When the project uses Codex (`.codex/` exists or the human says so), run `codex debug models` and confirm each Codex default is listed. If one is not, ask the human for the current cheap or strong model and write that instead. If Codex is not installed here, seed the defaults and say in the report that they are unchecked. Never leave the template's `<alias>` text in a seeded file.

Ask the human once: "Seed the defaults above (recommended), or change a tier's Claude alias or Codex model?" Apply the answer to every file in that tier.

## File shape

Write `.workflow/model-map/<task-type>.md` for each of the 12 task types. This is the filled form of `.agents/skills/project-setup/assets/model-map/TEMPLATE.md`, with every placeholder replaced and the template's guidance comments dropped:

```markdown
---
# Lowest-precedence model source (D35): .workflow/agent-overrides.yaml, then the agent definition's models key, then this file.
tier: cheap
claude: haiku
codex: gpt-6-luna
---
# retrieval

## Why this model

{Tier reason, below.}

## Observations

<!-- Appended at 5.7 by the retrospective skill, with approval. Dated, one line each. Keep this file free of any other field. -->
```

Tier reasons for "Why this model":

- **cheap**: "Bounded reading or checking task with a fixed return format; a fast, low-cost model is enough, and the strong tier is kept for writing and judging code."
- **strong**: "Writes or judges code across files, where a wrong call costs a rework loop; uses the strongest model."

## Existing files

- A file that exists with no `<...>` placeholder: keep it.
- A file that still holds a placeholder: replace only the placeholder fields with the tier default (D23), and leave the body untouched.

Check with `grep -l '<[a-z-]*>' .workflow/model-map/*.md`, which must print nothing when you are done.

Done when all 12 files exist, each `tier` matches the table, each `claude` is an alias, each `codex` is a model that `codex debug models` lists (or is reported unchecked), and the grep prints nothing.
