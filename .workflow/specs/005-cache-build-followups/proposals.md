# Proposals: Cache build follow-ups from spec 003

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Rules

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/rules.md` § Ownership | replace: `may_depend_on: [feature-workflow]` (module `agents`) -> `may_depend_on: [feature-workflow, regenerate-caches]` | Without it, review-standards (4.1) flags the cache-regeneration agent's one call to the regenerate-caches wrapper script as a forbidden dependency on every review. | 0.3.5 rule conflict; design-log 2026-10-26 Placement (0.3.4) | proposed | |
