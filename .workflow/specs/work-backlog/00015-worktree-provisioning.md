# Work backlog: 00015-worktree-provisioning

- [open] B1 refactor (3.4): the text an implementation resume loads is a few bytes under the 55,000-byte limit `lint/workflow-load-size` enforces, so the next change to `AGENTS.md` or `modules/implementation-waves.md` will fail that lint. Evidence: T5's first wording measured 55,187 bytes and T9's 55,043 ("implementation resume 55043 bytes > limit 55000"), and both trimmed wording to fit (`.workflow/specs/00015-worktree-provisioning/artifacts/T5/implementation.yaml`, `artifacts/T9/implementation.yaml`).
