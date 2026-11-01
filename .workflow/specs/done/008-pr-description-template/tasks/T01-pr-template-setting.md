# T01: `pr_template` setting reads `workflow` or a host template path

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `rules-setting.sh pr_template` reads the new Workflow settings key. It prints `workflow` or the repo-relative path of the project's own PR/MR template, defaults to `workflow` with a stderr note when the key or block is absent, and exits 1, naming the value, for anything else: a path of the wrong shape, a path whose file is missing from the main checkout, `project`, or any other word (D12, D16).

**Seam:** The `rules-setting.sh pr_template [--cwd <dir>] [--rules <file>]` CLI (stdout, stderr, exit code), driven from the `== rules-setting.sh` block of `tests/scripts/task-breakdown.sh`.

**Acceptance criteria:**

- [ ] Absent block or key prints `workflow` with a stderr note containing "default"; `workflow` reads back.
- [ ] A path value prints back when it is relative, ends in `.md`, holds no `..`, starts with neither `/` nor `-`, and the file exists under the main checkout root found from `--cwd` (git common dir, the same root rules.md is found from), also when `--rules` is passed.
- [ ] A missing file, each bad shape, `project` and `other` exit 1 with a message naming the value; a path value with `--cwd` outside any git repo exits 1 with a message that says so.
- [ ] The key appears in all five places a key lives in the script (header table, `usage()`, `setting_spec`, unknown-key text, "Called by"); `task_review` and `main_branch` behave as before.
- [ ] `tests/scripts/task-breakdown.sh` passes, including the JRN-004 cases; shellcheck clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/rules-setting.sh`

**Phase 1 tests:** `tests/scripts/task-breakdown.sh`

**Size:** S (1 file, about 40 changed lines).

**Mode:** afk.

**Notes:** Reuse the `@`-pattern mechanism `main_branch` uses (`setting_spec` "<default> <allowed...>", `valid_branch_name`); the existence check is the one place that needs the repo root under `--rules`. Callers that will read it: sign-off 5.2 and 5.4 (T3).
