# Proposals: Scoped test runs for the harness profiles

Spec: [spec.md](spec.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/shell-scripts.md` § Toolchain | replace: `test_scoped: ""` -> `test_scoped: "tests/run-all.sh --only-file \"$WF_TASK_TESTS_FILE\" --exclude-file \"$WF_EXCLUDE_TESTS_FILE\""` | Without it the 3.5 toolchain and stop audit run the whole 6-minute harness per task and report `unscoped`. | design-log D3, D5 | proposed | |
| P2 | `.workflow/profiles/test-harness.md` § Toolchain | same replacement as P1 | as P1 | design-log D3, D5 | proposed | |
| P3 | `.workflow/profiles/agent-docs.md` § Toolchain | same replacement as P1 | as P1 | design-log D3, D5 | proposed | |
