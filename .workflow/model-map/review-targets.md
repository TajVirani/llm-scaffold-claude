---
# Lowest-precedence model source: .workflow/agent-overrides.yaml, then the agent definition's models key, then this file.
tier: cheap
claude: haiku
codex: gpt-6-luna
---
# review-targets

## Why this model

Bounded reading or checking task with a fixed return format; a fast, low-cost model is enough, and the strong tier is kept for writing and judging code.

## Observations

<!-- Appended at 5.7 by the retrospective skill, with approval. Dated, one line each. Keep this file free of any other field. -->
- 2026-10-30 (claude, spec 008-pr-description-template): review cycle 1 reported TGT-003 (a plain lint command) as not_measurable; the main session measured it (pass). Cycle 2 measured all seven measurable targets. No alias change.
