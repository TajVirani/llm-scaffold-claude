---
status: in-review # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "1f59f20ee80efb50bfac85ba56afa22301eced56" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "spec/005-cache-build-followups" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "914df9ab8bc693423afef8f2e36eb4dfc11e9ef5" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/main-checkout-resolver.md, .workflow/deferred/bash-case-fallthrough.md, .workflow/deferred/bash-line-coverage.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 003-bash-cache-extractor-disc-002.md # filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
budget: {max_tasks: 10, max_changed_files: 30} # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Cache build follow-ups from spec 003

## Why

Origin: work items 003-bash-cache-extractor-disc-002.md, -disc-003.md, -disc-004.md and -disc-005.md, combined at the stakeholder's request. Spec 003 shipped Tier B caches for bash, but left four problems that make the caches, and the rules around them, less trustworthy:

- Two copies of the test-path rules: `budget-check.sh` and `build-architecture.sh` each keep the default test patterns and the matcher, so the size budget and the flow entry candidates can disagree about which files are tests (disc-002).
- False unresolved calls: the bash graph extractor reads `case` pattern alternatives such as `../*` as script calls, so this repo's published architecture cache lists two calls that do not exist (`install.sh:133,187`) (disc-003).
- A boundary check that failed but reads as clean: when depcruise does not run, Boundary violations reads `None.` for a JS/TS project, claiming a check that was never made (disc-004).
- An ownership map the code breaks: the `cache-regeneration` agent reaches regenerate-caches and visual-change-report by path, though `.workflow/rules.md` lets the agents module depend only on feature-workflow (disc-005).

A fifth item came off the shelf at 0.2.6: the shared path normaliser ([.workflow/deferred/archive/shared-path-normaliser.md](../../deferred/archive/shared-path-normaliser.md)), the same copied-helper problem in the feature-workflow scripts.

Make the Tier B caches, and the rules around how they're built, tell the truth. A published cache lists only real calls and reports only checks that actually ran. Each shared rule lives in one place, and the ownership map matches the code. Goals:

- A rebuilt architecture cache for this repo no longer lists the `install.sh:133,187` `case` patterns under Unresolved edges, and every real call the extractor finds is still listed.
- When depcruise doesn't run, Boundary violations says the check wasn't made. It never says `None.`
- The size budget and the flow entry candidates read test files through one shared test-pattern helper in `.agents/lib/`; flows keeps its JS regex as an extra entry-candidate filter (D8).
- The six feature-workflow scripts that take a workflow folder path (including open-task-pr `--record`) validate it through one helper in `.agents/lib/` (D5, D10).
- The cache-regeneration agent calls only regenerate-caches scripts, so after P1 no reference in it breaks `.workflow/rules.md` Ownership.

## Capabilities

- **CAP-005** Bash graph extractor
  - **intent:** The bash graph extractor tells a `case` arm's pattern list apart from a command, so patterns are never reported as script calls.
  - **success:** Fixture tests for one-line, multi-line, `(pattern)`, `./x)` and `|`-alternation arms report no pattern as an unresolved call while a command after the `)` is still reported; this repo's rebuilt architecture cache has no `install.sh:133` or `install.sh:187` entry under Unresolved edges.
- **CAP-004** Graph extractor per work profile
  - **intent:** The architecture cache build reports a boundary check as made only when depcruise actually ran.
  - **success:** When depcruise is not found, exits without a JSON report, or prints output without a `.summary.violations` array, Boundary violations reads `Not checked: depcruise did not run (<reason>).` with the fixed reason `not found`, `exited <n> without a JSON report` or `no .summary.violations in its output`, and `build-architecture.sh` exits 0; with violations it lists them as today; a `--violations-json` file that does not parse still exits 2 (D9).

## Constraints

- bash 3.2, no bash 4 constructs (no `**` globstar); shellcheck clean; no new dependencies (deeper prompt).
- `.agents/lib/` is shared core: the two helpers change only through the integration agent, between batches.
- A detected call is reported as unresolved, never filtered out (`.workflow/decisions/pitfalls.md`): the `case` fix skips only arm pattern lists (D3).
- Helpers return a status and a message; each calling script keeps its own `die` message and exit code (D4).
- The entry-candidate JS regex at build-architecture.sh stays unchanged (D8).
- The Boundary violations reason is one of three fixed strings, never depcruise's stderr, so the cache body is the same on every machine (D9).

## Non-goals

- A boundary checker for bash, other graph extractors, or a full bash grammar parser (mvdan/sh, tree-sitter).
- Moving the other ~15 main-checkout resolvers in hooks, regenerate-caches and agent docs to `.agents/lib/` (D5): shelved as [.workflow/deferred/main-checkout-resolver.md](../../deferred/main-checkout-resolver.md).
- Bash 4 `case` fall-through terminators `;&` and `;;&`: shelved as [.workflow/deferred/bash-case-fallthrough.md](../../deferred/bash-case-fallthrough.md).
- Node-version rules for depcruise.
- Editing `.workflow/rules.md` mid-feature: the `agents.may_depend_on` change is proposal P1 for 5.3.

## Success signal

A rebuilt architecture cache for this repo lists only real calls and says `Not checked` whenever depcruise did not run; budget-check and build-architecture read test files through one `.agents/lib/` helper; six scripts validate folder paths through one helper; and the cache-regeneration agent references only regenerate-caches.

## Assumptions

- The test-path helper is a new `.agents/lib/test-paths.sh` with the same status-and-message shape as the D4 normaliser (confirmed in the 0.3.19 summary, not asked as a question).
- The shared test-path loader keeps budget-check's empty-Toolchain-block guard and its yq v4 check stays in each caller.

## Open Questions

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
- Placement: no ADR (fails the three-part test); see design-log 2026-10-26 Placement check (0.3.5-0.3.7)
- Deferred: [main-checkout-resolver](../../deferred/main-checkout-resolver.md), [bash-case-fallthrough](../../deferred/bash-case-fallthrough.md); off the shelf: [shared-path-normaliser](../../deferred/archive/shared-path-normaliser.md)

## Known gaps

- None.
