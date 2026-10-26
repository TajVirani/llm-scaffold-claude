---
# Lowest-precedence model source: .workflow/agent-overrides.yaml, then the agent definition's models key, then this file.
tier: cheap
claude: haiku
codex: gpt-6-luna
---
# profile-mini-review

## Why this model

Bounded reading or checking task with a fixed return format; a fast, low-cost model is enough, and the strong tier is kept for writing and judging code.

## Observations

<!-- Appended at 5.7 by the retrospective skill, with approval. Dated, one line each. Keep this file free of any other field. -->
- 2026-10-22 (claude, spec 002-review-lessons): six review rounds on one task, each failing round naming one new cosmetic item on lines an earlier round had passed, two of them header lines the rules exempt; the round that carried the earlier verdicts in its brief passed. No alias change.
- 2026-10-26 (claude, spec 003-bash-cache-extractor): caught a real dropped-call bug as out of scope on T3 and a needed reason comment twice; one re-check wrote `mini-review-r2.yaml` instead of the plain name and reported a false stale `tree` by comparing it with the git tree id. No alias change.
