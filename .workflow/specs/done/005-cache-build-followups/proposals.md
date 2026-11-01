# Proposals: Cache build follow-ups from spec 003

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Rules

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/rules.md` § Ownership | replace: `may_depend_on: [feature-workflow]` (module `agents`) -> `may_depend_on: [feature-workflow, regenerate-caches]` | Without it, review-standards (4.1) flags the cache-regeneration agent's one call to the regenerate-caches wrapper script as a forbidden dependency on every review. | 0.3.5 rule conflict; design-log 2026-10-26 Placement (0.3.4) | approved | Approved at 5.3 (2026-10-28) |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/decisions/pitfalls.md` | New entry "Flip a Phase 1 placeholder's PROVENANCE row when the task that implements it lands": What happened: Phase 1 added `lib/test-paths.sh` as a stub with a `placeholder` PROVENANCE row; T1 and T2 made it real and sourced it, no task brief named the row, and both review-standards and review-end-state flagged it (F2, medium), costing a rework. Where: `PROVENANCE.md`; task briefs at 2.5 for tasks that replace a Phase 1 stub. Spec: .workflow/specs/done/005-cache-build-followups. Prevented by: none yet | Without it, a task breakdown that turns a Phase 1 stub into working code leaves the stub's `placeholder` PROVENANCE row out of every brief, and the miss surfaces only at Phase 4 as a rework. | F2 (RS-1, RE-1), review pass 1 | approved | Approved at 5.3 (2026-10-28) |
