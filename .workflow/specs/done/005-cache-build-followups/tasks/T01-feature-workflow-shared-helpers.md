# T01: Feature-workflow scripts use the shared folder-path and test-path helpers

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately; needs the wave-1 integration batch merged first) · Parallel with: None

**What to build:** The six feature-workflow scripts that take a workflow folder path (status-transition, budget-check, task-waves, commit-workflow-data, initiative-transition, open-task-pr including `--record`) validate it through `wf_norm_folder spec|initiative` and find the main checkout through `wf_main_root`, both from `.agents/lib/workflow-paths.sh`, and keep no local copy. budget-check reads the test patterns and classifies test files through `.agents/lib/test-paths.sh` and keeps no copy of the defaults or the matcher. Every script gives the same accept or reject result, message and exit code as before, except that open-task-pr (spec dir and `--record`) now rejects an absolute path whose parent is not `.workflow/specs` or `.workflow/initiatives`.

**Seam:** Each script's CLI (exit code, stdout, stderr) driven from the existing per-script suites, plus the `wf_norm_folder` / `wf_main_root` functions sourced in `tests/scripts/lib-workflow-paths.sh`.

**Acceptance criteria:**

- [ ] No `main_root`, `norm_spec_dir` or `norm_initiative_dir` definition is left in the five scripts that define them today (TGT-005), and open-task-pr has no inline normaliser.
- [ ] Each script keeps its own `die` message and exit code around the helper's status and message (D4); commit-workflow-data stays exit 2; open-task-pr `--record` keeps its message and `generic_usage` exit 2 (D10).
- [ ] For every input form in `artifacts/phase-1-test-harness/normaliser-baseline.md`, each script matches the recorded behaviour, apart from the open-task-pr exception above.
- [ ] budget-check sources `.agents/lib/test-paths.sh`, keeps no default list or matcher (TGT-004 counts it out), keeps its yq v4 check, and an invalid `test_patterns` still exits 1 with its own message.
- [ ] `tests/scripts/lib-workflow-paths.sh` and `tests/scripts/task-breakdown.sh` pass; the existing suites for the six scripts still pass; shellcheck clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/status-transition.sh`, `.agents/skills/feature-workflow/scripts/budget-check.sh`, `.agents/skills/feature-workflow/scripts/task-waves.sh`, `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh`, `.agents/skills/feature-workflow/scripts/initiative-transition.sh`, `.agents/skills/feature-workflow/scripts/open-task-pr.sh`

**Phase 1 tests:** `tests/scripts/lib-workflow-paths.sh`, `tests/scripts/task-breakdown.sh`

**Size:** M (6 files, about 250 changed lines).

**Mode:** afk.

**Notes:** Shared-core requests (touches_core), for the integration batch before wave 1:

1. `.agents/lib/workflow-paths.sh`: implement `wf_main_root` (prints the main checkout root, falling back from a worktree to its main checkout as the current copies do) and `wf_norm_folder spec|initiative <arg>` (accepts a relative `.workflow/specs/NNN-slug` or `.workflow/initiatives/NNN-slug`, an absolute path under the main checkout, a worktree path, and the forms the current copies accept; prints the normalised repo-relative folder and returns 0; on reject returns 1 and prints the message, never exits). Contract fixed at 1.1 (design-log) and pinned by `tests/scripts/lib-workflow-paths.sh`.
2. `.agents/lib/test-paths.sh`: see T02 Notes (budget-check is a consumer too).
