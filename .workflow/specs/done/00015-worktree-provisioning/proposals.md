# Proposals: Worktree provisioning

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-016 \| Worktree setup: `worktree-setup.sh` creates every agent worktree and scratch worktree and sets up every spec worktree: it gives the spec a slot, copies the gitignored files the project's `.worktreeinclude` names from the main checkout as real files, runs the project's `worktree_setup` command with the isolation values (`WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET`, `WF_MAIN_ROOT`, `WF_SPEC_ROOT`) and refuses a symlink that reaches back into the main checkout or another worktree; `run-toolchain.sh` runs that link check first and the project's `services_up` before a `test` or `e2e` key that will run; `spec-worktree.sh remove` runs `services_down`; a project that declares nothing behaves as before \| [.workflow/specs/done/00015-worktree-provisioning](specs/done/00015-worktree-provisioning/spec.md) | Without it, 0.3.1 would not see that a later request to install dependencies in worktrees, copy `.env`, or start services for tests extends this capability, and would plan it as new work. | spec.md § Capabilities | approved | |
