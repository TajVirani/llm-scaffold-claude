# Proposals: The single writers keep the validator's diagnostic

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-009 \| Single writers report a broken validator: `status-transition.sh set-task` and `initiative-transition.sh` refuse a write the template validator rejects as before (exit 1 and 2), and report a validator yq cannot run with exit 1 and yq's own error text \| [.workflow/specs/00013-validator-diagnostic](specs/00013-validator-diagnostic/spec.md) | Without it, 0.3.1 of a later request about the writers' refusals or exit codes would not find that this behaviour is a recorded capability, and could undo the false/error split | spec.md § Capabilities | approved | |
