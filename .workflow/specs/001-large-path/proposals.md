# Proposals: Large path: planning a large subject into several specs

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Glossary

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/GLOSSARY.md` § Language, **Task type** | add `research` to the task-type list in the definition, after `review-lessons` (as the list reads on main at 5.3): `..., review-lessons, standards-discovery.` -> `..., review-lessons, standards-discovery, research.` | Without it, review-standards (4.1) would flag `research` as a name outside the agreed task types, and 0.2.2 would raise it as an unknown term on every initiative. | design-log D20 | proposed | |
