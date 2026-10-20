---
# One file per task type, at .workflow/model-map/ in the project, named for the task type. Seeded by project-setup with the default tier for that task type.
# Lowest-precedence model source: used for a host only when neither .workflow/agent-overrides.yaml[type][host]
# nor the agent definition's per-host `models` entry gives one. If none gives a model, the launch is blocked at 00.14.
# Claude aliases are Claude Code built-ins.
tier: cheap            # cheap | strong. cheap: retrieval, fact-lookup, profile-mini-review, review-targets, library-evaluation. strong: implementation, integration, review-standards, review-end-state, module-audit, cache-regeneration.
claude: <alias>        # Claude Code alias: haiku | sonnet | opus. Aliases only, never a dated version ID. project-setup writes the tier default.
codex: <alias>         # Codex model name: gpt-6-luna (cheap) | gpt-6-sol (strong). Names get retired; project-setup checks them against `codex debug models`.
# fallback: <alias>    # optional; used when the primary alias is unavailable
---
# {task-type}

## Why this model

{One or two sentences: why this tier and alias fit this task type.}

## Observations

<!-- Appended at 5.7 by the retrospective skill, with approval. Dated, one line each. Keep this file free of any other field. -->
