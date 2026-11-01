# Proposals: Large path: planning a large subject into several specs

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Glossary

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/GLOSSARY.md` § Language, **Task type** | add `research` to the task-type list in the definition, after `review-lessons` (as the list reads on main at 5.3): `..., review-lessons, standards-discovery.` -> `..., review-lessons, standards-discovery, research.` | Without it, review-standards (4.1) would flag `research` as a name outside the agreed task types, and 0.2.2 would raise it as an unknown term on every initiative. | design-log D20 | proposed | |

## Rules

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/rules.md` § Ownership | add a module `scaffold-docs` with `owns: ["PLAN/**", "PROVENANCE.md", ".gitignore", "assetlist.md", "checklist.md"]`, `may_depend_on: []`, and the line "A task may edit a `scaffold-docs` file its change requires in the same commit: the PROVENANCE row, the PLAN flow docs beside `references/steps.tsv`, the `.gitignore` workflow block beside `GI_ENTRIES`, the manifest line beside a new agent." | Without it those files have no owner, so an implementation agent returns `scope-expansion` for a PROVENANCE row or a PLAN doc the cross-cutting policy requires in the same change; task-breakdown 2.1 had to grant them by hand in T1, T2 and T8. | task-breakdown 2.1 grant, 2026-10-22 | proposed | |
| P3 | `.workflow/profiles/agent-docs.md` § Toolchain, `lint` key | run the four lint suites so every one reports: `tests/run-all.sh --suite lint/frontmatter; tests/run-all.sh --suite lint/step-list; tests/run-all.sh --suite lint/symlinks; tests/run-all.sh --suite lint/upstream-lineage` combined so the key fails when any suite fails but every suite runs (for example a small `for` loop over the four names that records the worst exit), or a single `tests/run-all.sh --suite lint/...` form if the runner gains a multi-suite option | With `&&`, the first red suite hides the others' results from the toolchain artifact; during a feature that makes `lint/step-list` red by design (new step ids), no agent-docs task gets symlinks or upstream-lineage evidence. | T8 and T3 implementation returns, wave 1, 2026-10-22; discovered work agent-docs-lint-chain | proposed | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P4 | `.workflow/profiles/shell-scripts.md` § Language and style rules and § Mini-review checklist, the `# Exit:` label | either rename the label in the existing helper scripts that use `# Exit codes:` (`status-transition.sh`, `open-task-pr.sh`) to `# Exit:` so every helper header matches the profile and the two tools that anchor help extraction on `# Exit:` (`tests/run-all.sh:30`, `.agents/hooks/generate-codex-agents.sh:50`), or widen the profile's rule to accept `# Exit codes:` | Today a new script written to the profile (`initiative-transition.sh`) and its sibling differ in a header label the mini-review checks, so every new helper either fails the checklist or diverges from its sibling. | T4 mini-review round 2, wave 2, 2026-10-22 | proposed | |
| P5 | `.workflow/profiles/shell-scripts.md` § Language and style rules, the Exit codes line | add: "The workflow single writers (`status-transition.sh`, `initiative-transition.sh`) keep their own contract, 0 done, 1 usage or environment error, 2 illegal transition or validator refusal, because the spec of the large path requires the initiative writer to share the spec writer's codes; every other new script follows the 0/1/2 rule above." | Without it the mini-review and the standards lens flag the initiative writer's codes on every pass (F3), while changing them would break the contract the spec constraint and the modules rely on. | review pass 1, F3 (RS-3) | proposed | |
| P6 | `.workflow/profiles/test-harness.md` § File locations and § Approved libraries | add: "A Phase 1 journey suite may be named for its journey (`tests/<kind>/<journey-slug>.sh`, with the component in `# Covers:`), and fixture builders shared by several suites live in `tests/fixtures/<name>.sh`, sourced after `lib/common.sh`." | Without it every journey suite and the shared fixture file conflict with the one-suite-per-component rule and the lib/common.sh-only rule (F6), although the verification plan agreed this layout at Phase 0. | review pass 1, F6 (RS-6) | proposed | |
