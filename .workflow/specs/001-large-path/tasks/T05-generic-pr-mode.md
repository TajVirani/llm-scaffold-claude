# T05: Generic PR mode

Index: [../tasks.md](../tasks.md) · Blocked by: T4 The initiative single writer · Parallel with: None

**What to build:** `open-task-pr.sh` gains a generic mode the large path uses to open the `planned` and `done` PR/MR of an initiative branch into the main branch: `--head <branch> --base <branch> --title <text> [--body <text>] [--cwd <dir>] [--record <initiative-dir>] [--dry-run]`. It shares the task mode's host switch (gh for GitHub, glab for GitLab, `skipped: <reason>` otherwise), auth precheck, push, open-PR reuse, dry-run printing and exit contract; `--record` writes the URL into the initiative through `initiative-transition.sh set-pr`. The task mode is unchanged.

**Seam:** `open-task-pr.sh --head initiative/001-<slug> --base main --title <t> --dry-run` stdout with `gh` and `glab` stubs on PATH (no network), `--record` observed through `merge_pr` in `initiative.md`, and the unchanged task-mode cases in `tests/scripts/task-breakdown.sh`.

**Acceptance criteria:**

- [ ] With a GitHub origin the dry run prints the `gh pr create` command naming `--head initiative/001-<slug>` and `--base main` with the title; with a GitLab origin the `glab mr create` command with `--source-branch` and `--target-branch`; with no remote it prints `skipped: no remote` and exits 0.
- [ ] Without `--dry-run` it pushes the head branch, reuses an open PR/MR for that head and base when one exists, and prints the URL; `--record <initiative-dir>` then calls `initiative-transition.sh set-pr <dir> <url>` and `merge_pr` holds the URL.
- [ ] Generic and task modes are mutually exclusive: mixing `--head` with `<spec-dir> T<n>` exits 2 with usage; the task mode's behaviour and output are byte-for-byte unchanged (`tests/scripts/task-breakdown.sh` passes).
- [ ] The `# Usage:` header documents both modes and the `Called by:` lines of `open-task-pr.sh` and `rules-setting.sh` name the large path beside 3.16.
- [ ] `tests/scripts/initiative-merge.sh` passes.

**Predicted files:** `.agents/skills/feature-workflow/scripts/open-task-pr.sh`, `.agents/skills/feature-workflow/scripts/rules-setting.sh`.

**Phase 1 tests:** `tests/scripts/initiative-merge.sh`.

**Size:** S (2 files, about 120 changed lines).

**Mode:** afk.

**Notes:** Carries the PR half of migration M4 (D22, D24, D25, D32). `task_review` from `rules-setting.sh` is read by the caller (the large-path module), not by this script, as for task PRs: under `local` the module never calls it. Keep the host switch coded once; do not add a second copy. The suite's merge replay (local `--no-ff` merge, branch deletion, the `done` flip) exercises T4's `status` and this script's dry run together; this task owns the suite because it completes it.
