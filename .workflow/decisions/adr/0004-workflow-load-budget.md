---
status: accepted
---

# Feature-workflow load budget, enforced by a lint

Starting the feature workflow used to load about 81 KB of instructions before any work, most of it for other steps. Feature-workflow is now a router (`SKILL.md`), shared files under `references/` and one step file per stage, and a session loads only the router, `references/conventions.md` and the step file it needs. `tests/lint/workflow-load-size.sh` holds this in place: a new-feature start may load at most 45,000 bytes and an implementation resume at most 55,000 (`wc -c`, session-start hook output and the glossary term list included), and the suite fails above either. When it fails, trim text or move it to the step that uses it; raise a limit only by a new decision.

## Considered Options

- One `SKILL.md` with `modules:` and `progressive_loading:` frontmatter keys: no host reads those keys, so the whole file loaded anyway. They were removed.
- Counting tokens instead of bytes: the offline tokenizers use OpenAI encodings and add a runtime, and Claude's token-count API needs a key and the network, so it cannot run in the tests. A byte count is a proxy, so the limits are stated in bytes.
- Measuring once and not enforcing it: the load would grow back unnoticed, one rule at a time.
- Leaving the term list out of the count: it loads at every session start, so a count without it would understate the real load.

## Consequences

- The new-feature start sits close to its limit (44,733 of 45,000 bytes at sign-off). Each new glossary term adds a line to the term list, so a few new terms can fail the lint in a change that never touched feature-workflow.
- A rule moved into `references/` must leave no copy behind in the step file it came from (see pitfalls); `lint/shared-rule-homes` checks only the marker lines it lists.
