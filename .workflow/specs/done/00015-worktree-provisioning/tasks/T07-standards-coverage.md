# T07: Standards coverage

Index: [../tasks.md](../tasks.md) · Blocked by: T3 Worktree setup script · Parallel with: None

**What to build:** The standards interview of `project-standards` cannot finish without covering how a worktree is made ready and how tests stay apart from the dev environment, so an existing project that adopts or refreshes its standards is asked the same things a new project is.

**Seam:** the coverage list `assets/coverage.md` as loaded text, checked by a lint case over its rows.

**Acceptance criteria:**

- [ ] The "Every work type" coverage in `assets/coverage.md` includes: the worktree setup command; the gitignored files a worktree needs copied; the commands that start and stop the services tests need; how ports, container names and database names derive from the isolation values; and that tests use a throwaway database, never the dev one.
- [ ] Each item names its destination: the `## Workflow settings` block of `.workflow/rules.md`, `.worktreeinclude`, or the work profile.
- [ ] A lint case, written first, fails when the coverage list drops any of those items. Put it in the suite that already reads `coverage.md`.
- [ ] The existing lint suites over the file pass.

**Predicted files:** `.agents/skills/project-standards/assets/coverage.md`, `tests/lint/size-budget-docs.sh`

**Phase 1 tests:** None.

**Size:** S (2 files, about 30 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** `tests/lint/size-budget-docs.sh` is the one suite that reads `coverage.md` today. If a case about worktree setup does not belong in it, add a small suite `tests/lint/standards-coverage-docs.sh` with its row in `tests/README.md` instead, and say so in the result. Use the glossary term "Worktree setup".
