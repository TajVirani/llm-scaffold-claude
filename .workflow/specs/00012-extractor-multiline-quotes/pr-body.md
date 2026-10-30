## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- `extractors/bash.sh` keeps one quote state across lines and shares it with every reader (`source`/`.` lines, anchored tokens, cwd-relative and bare relative calls), so text inside a quoted string that spans lines is never reported as a call.
- In the lines a double-quoted string spans, plain text is data, while a `$(...)` or backtick substitution inside it is still read as code.
- A `#` that starts a word outside quotes ends the code on its line, so an apostrophe in a trailing comment no longer mis-pairs quotes and drops later calls; a quoted `<<` no longer starts a heredoc skip.
- `tests/scripts/extractor-bash.sh` gains cases for each rule and checks the suite's own multi-line jq program; `tests/fixtures/architecture-oracle.sh` drops four false Unresolved edges that came from quoted text.
- Tier A: CAP-005 now names the quoting rule and links this spec.

## Why the change

- The extractor read the later lines of a multi-line jq or awk program as commands, so the published architecture cache listed calls that do not exist (`tests/scripts/extractor-bash.sh` `./x`, backlog item `005-cache-build-followups-disc-003.md`).
- CAP-005 intent: the cache build can trust that every unresolved call is a real command, and that no real call is lost to quoting or comments.

## Why this approach

- Owning module: `regenerate-caches`, with its suite in `tests`; CAP-005 is extended, no placement ADR.
- One shared quote state (D1) fixes all four readers at once; teaching each reader separately would drift. Comments (D2), command substitutions in double quotes (D3) and quoted heredoc markers (D4) use the same state, because each would otherwise drop real calls.
- Staying in the extractor's awk keeps the install contract (git, awk, jq); every parser candidate (mvdan/sh, tree-sitter-bash, bash-parser) adds a runtime.

## Special things to note

- Report: [report.md](report.md). Task PRs: none (light path, T1 committed on the spec branch).
- Browser gate skipped: this repo has no browser suite ([.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)).
- Deferred (medium, pre-existing): a same-line call after an escaped quote inside `$'...'` is still dropped; consolidating the extractor's quote pairers is shelved in [.workflow/deferred/bash-extractor-quote-rules.md](../../deferred/bash-extractor-quote-rules.md).
- The published architecture cache still lists the five removed edges until the next regeneration.

## How to test

1. Run `tests/run-all.sh --suite scripts/extractor-bash`: expect `RESULT passed=54 failed=0`.
2. Run `.agents/skills/regenerate-caches/scripts/extractors/bash.sh --root . --scope tests/scripts/extractor-bash.sh` and filter for `./x`: expect no record.
3. Read `.workflow/specs/00012-extractor-multiline-quotes/artifacts/oracle/oracle-diff.txt`: 437 records before, 432 after, five in-quote removals and nothing added.

## Blast radius

- Reviewed files (tests excluded): `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`, `.workflow/deferred/bash-extractor-quote-rules.md`, `.workflow/deferred/browser-suite.md`.
- The extractor's one caller is `build-architecture.sh`, which builds `.workflow/cache/architecture.md` and modules.md for every Tier B regeneration (0.2.8 and the regenerate-caches skill) in this repo and in target projects, whose `graph_extractor` is `bash`. A wrong rule would add or drop Unresolved edges and file-graph edges in those caches.
- The CLI and output JSON are unchanged; nothing else reads the extractor.

## Risk and reversibility

Risk: Low - over this repo the output changed only by five in-quote false edges, and the suite covers each quoting rule; other projects' scripts may hold quoting forms not seen here.
Reversibility: Easy - reverting the merge commit restores the previous extractor; caches regenerate from code.

## Areas, concepts and seams changed

- Graph extractor `extractors/bash.sh`: its reading of quoted text across lines (`walk_quotes`, `code_outside_spanning_quotes`); the CLI and the output JSON shape are unchanged.
- Fixture seam `tests/fixtures/architecture-oracle.sh`: four Unresolved edges removed.
- Concepts: Graph extractor, CAP-005.

## How to undo this PR

Revert the merge commit on main (`git revert -m 1 <merge commit>`), then regenerate the Tier B caches if they were rebuilt with the new extractor. No data or settings to restore.
