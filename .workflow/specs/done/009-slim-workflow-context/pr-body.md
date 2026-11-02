## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- Feature-workflow is split into a router (`SKILL.md`), two reference files (`references/conventions.md` for the rules every step follows, `references/launching.md` for sub-agent launches) and one step file per stage. A session loads the router, the conventions and the step file it needs.
- Discovery is split at the questioning loop (`discovery.md`, `discovery-impact.md`); the implementation orchestrator is replaced by `implementation-setup.md`, `implementation-shared-core.md`, `implementation-gates.md`, `implementation-waves.md` and `implementation-finish.md`; `small-path.md` is folded into the step files it changed.
- A new `domain-modeling/scripts/term-list.sh` prints one line per glossary term, and the output style reads that list in place of the whole glossary.
- A new lint, `lint/workflow-load-size`, fails when a new-feature start loads more than 45,000 bytes or an implementation resume more than 55,000. They now load 44,733 and 54,360 bytes, down from about 81,000 and 85,000.
- New suites for routing, links and anchors, the term list, one home per shared rule, small-path docs and the affected-area read; script and asset headers point at the new step files.

## Why the change

- Starting the feature workflow used about 10% of the context window before any work, much of it instructions for other steps. The same conventions were also written twice and could drift apart.
- CAP-012: a session running the feature workflow loads only what its current step needs, so its context goes to the work, while the workflow behaves exactly as before.

## Why this approach

- feature-workflow owns the change; the term-list script lives in domain-modeling so the output style and domain-modeling can use it without new dependencies, and the output style inlines the command because output styles may depend on nothing (D1).
- `modules/` keeps its name because other skills use the same folder name; the files are called step files.
- Splitting by step, with shared rules in `references/`, gives every rule one home; the alternative, one file with progressive-loading keys, did not work because no host reads those keys. The limits are enforced by a lint, in bytes, so the load cannot grow back unnoticed (ADR-0004).
- Impact: refactor of the router and the step files, two new reference files, one new script, new lint and script suites; behaviour unchanged.

## Special things to note

- Report: [report.md](report.md). Task PRs: none; every task merged locally into the spec branch, as agreed for this spec.
- No live session has run the new router yet: the first feature session on `main` after the merge is the real test.
- The new-feature start has 267 bytes to spare and counts the term list, so a few new glossary terms can fail `lint/workflow-load-size`; ADR-0004 says to trim, not raise the limit.
- The output style's `awk` command and `term-list.sh` are not on the shipped Claude allow list; a target project in default permission mode may see a prompt at session start (not tried).
- Not measured: line coverage of changed shell code (no bash coverage tool); links inside `assets/` files are not checked by `lint/md-links`.
- Deferred: [cache-scope-paths](../../../deferred/cache-scope-paths.md), [in-review-hand-off](../../../deferred/in-review-hand-off.md).

## How to test

1. Run `bash tests/lint/workflow-load-size.sh`. Expected: `new-feature start: 44733 bytes (limit 45000)` and `implementation resume: 54360 bytes (limit 55000)`, then a passing result.
2. Run `tests/run-all.sh`. Expected: it ends with `TOTAL passed=4458 failed=0`.
3. Start a new session and ask to resume or start a feature. Expected: it loads `SKILL.md`, `references/conventions.md` and one step file, not the whole skill.

## Blast radius

- Every feature-workflow session: the router, all step files under `.agents/skills/feature-workflow/modules/` and the two reference files.
- The output style (`.agents/output-styles/concise-technical.md`), read at every session start in every target project.
- Script header comments in `feature-workflow/scripts/` (no behaviour change) and the asset templates that name step files.
- Tier A in this repo: `capabilities.md` (CAP-012), ADR-0004, one pitfall, one shell-scripts profile line.
- Untouched: hooks, `.agents/lib/`, other skills, `install.sh` and the install manifest.

## Risk and reversibility

Risk: Medium - every feature-workflow session now follows the split files, and a missed rule or broken link would show up there; the suites check routing, links and one home per rule, but no live session has run it yet.
Reversibility: Easy - revert the merge commit; no data or settings change outside this repo's `.workflow/`.

## Areas, concepts and seams changed

- Step-file load (changed shape first): the router now loads one step file plus `references/conventions.md`; step files link to the reference files instead of `SKILL.md` sections.
- Launch rules: moved from the router to `references/launching.md`; step files point there at the step that launches.
- Glossary reading: the output style reads the term list (`term-list.sh` output shape) instead of the whole glossary; concepts Router, Step file, Workflow conventions and Term list.
- Modules: feature-workflow (owner), domain-modeling (new script), output-styles, tests.

## How to undo this PR

1. Revert the merge commit on `main` (`git revert -m 1 <merge sha>`).
2. Run `tests/run-all.sh` to confirm the old layout passes again.
