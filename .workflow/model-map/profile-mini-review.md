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
- 2026-10-30 (claude, spec 008-pr-description-template): caught real faults (T1 accepting a literal @template_path, T2 a missing reason on an early return, T6 a .workflow/ path in an asset), but in T2 round 1 asked for single-bracket tests against retrospective 002 (later F5), and the T6 re-check again reported a false toolchain.json tree mismatch, as in 003. No alias change.
- 2026-10-30 (claude, spec 00010-worktree-guard-followups): caught real wording faults (T2: a missing reason comment, journey ids on changed suite-header lines) and reported three real out-of-scope bugs in the guard (later shelved); one T1 result file held unquoted YAML and needed a resume. No alias change.
- 2026-10-31 (claude, spec 007-done-folder): caught real faults (unchecked writes under suspended `set -e` three times in T5, the sweep's partial state, a missing reason comment), but wrote an unreadable result file twice (missing `location` fields; an unquoted `: ` in a note), each needing a resume, and twice again reported a false `toolchain.json` tree mismatch. No alias change.
- 2026-11-02 (claude, spec 009-slim-workflow-context): its full re-review of T1 in rework 1 caught a missing `# die MSG :` comment that four earlier rounds had passed, and T1 round 1 again asked for single-bracket tests in a new file (as in 008; profile line clarified at 5.3, P4); one result file missed an item `location` and needed a resume. No alias change.
