---
# Lowest-precedence model source: .workflow/agent-overrides.yaml, then the agent definition's models key, then this file.
tier: strong
claude: opus
codex: gpt-6-sol
---
# implementation

## Why this model

Writes or judges code across files, where a wrong call costs a rework loop; uses the strongest model.

## Observations

<!-- Appended at 5.7 by the retrospective skill, with approval. Dated, one line each. Keep this file free of any other field. -->
- 2026-10-22 (claude opus, spec 002-review-lessons): six tasks done; every rework and fix round converged in one launch; T3 returned profile-wrong correctly on a lint key another task's pin had turned red. No change.
