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
