---
# Lowest-precedence model source: .workflow/agent-overrides.yaml, then the agent definition's models key, then this file.
tier: cheap
claude: haiku
codex: gpt-6-luna
---
# review-lessons

## Why this model

Bounded reading and matching task with a fixed return format: it reads the recorded review lessons, pitfalls and retrospectives and looks for their symptoms in one diff; a fast, low-cost model is enough, and the strong tier is kept for writing and judging code.

## Observations

<!-- Appended at 5.7 by the retrospective skill, with approval. Dated, one line each. Keep this file free of any other field. -->
- 2026-10-22 (claude haiku, spec 002-review-lessons): three live runs of one fixture journey gave pass, fail, pass on an unchanged definition before a fix to its matching rules; the miss weighed a lesson's consequence clause. Run 3 appended notes after the summary block and left a scratch file in the temp dir. No alias change.
