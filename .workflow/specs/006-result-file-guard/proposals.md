# Proposals: Sub-agents can write their own result file

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/shell-scripts.md` § Mini-review checklist | replace: Every error path reaches `die()` or the guard's deny output; nothing is silently swallowed. -> Every error path reaches `die()` or the guard's deny output; nothing is silently swallowed, except a silent exit the hook's header documents as intended (for example a stop the audit does not cover). | Without the exception a reviewer fails a documented silent exit (the integration stop with no transcript, ruled in design-log "Discovered work: codex-integration-missing-transcript") on every review. | T1 mini-review r2 out_of_scope_noticed (`artifacts/T1/mini-review-r2.yaml`), step 3.7 | proposed | |
