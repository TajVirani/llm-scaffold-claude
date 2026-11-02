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
- 2026-10-26 (claude, spec 003-bash-cache-extractor): T9 and T10 passed in one launch each; T3 rework 2 took three rounds (one behaviour fix for a continued line after an operator, two for missing reason comments on new parsing clauses), and the agent itself caught a first fix that added about 100 false edges on this repo. No alias change.
- 2026-10-30 (claude, spec 008-pr-description-template): T4 built beyond its task file (a 5.5 hash check and a separate PR-description approval; the stakeholder removed one and kept the other, D17, D18); T2 was resumed once to add tests for behaviour beyond Phase 1; T1 needed one behaviour fix round. No alias change.
- 2026-11-02 (claude, spec 009-slim-workflow-context): wrote `self_review[].item` as a quoted string in T1 and T2 (wave 1) and again in T1, T9 and T10 (rework 1), each fixed in one resume (backlog B2); every rework converged in one launch. No alias change.
