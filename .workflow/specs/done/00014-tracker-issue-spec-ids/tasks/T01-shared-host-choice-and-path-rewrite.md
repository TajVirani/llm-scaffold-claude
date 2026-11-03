# T01: Shared host choice and path rewrite

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `move-to-done.sh`, `open-task-pr.sh` and `rules-setting.sh` stop carrying their own copies of two pieces of logic. They call the two new shared lib functions instead: the host choice (the `origin` URL picks gh for GitHub, glab for GitLab, nothing otherwise) and the path rewrite with rollback and a scoped commit (today inside `move-to-done.sh`). Sign-off 5.8's host prose says the same choice applies. Behaviour does not change: every existing suite of the three scripts passes unchanged.

**Seam:** the existing CLIs of `move-to-done.sh`, `open-task-pr.sh` and `rules-setting.sh`, driven by their existing suites (`tests/scripts/move-to-done.sh`, `tests/scripts/sign-off-pr.sh`, `tests/scripts/budget-check.sh` and the other suites that call them). Catches caller regressions. It misses lib cases no caller reaches yet, which T08's adoption suite covers.

**Acceptance criteria:**

- [ ] The three scripts source the shared lib and call its host-choice function; none matches the `origin` URL against `github` or `gitlab` itself.
- [ ] `move-to-done.sh` calls the shared path-rewrite function for its spec-path rewrite, rollback and scoped commit; its own copies (`roll_back`, `replace_file`, the `SAVED_*` arrays, `commit_moves`) are gone.
- [ ] `tests/run-all.sh` passes every suite that passed at the task's base, unchanged.
- [ ] `sign-off.md` 5.8 names the shared host choice instead of restating the URL rule.

**Predicted files:** `.agents/skills/feature-workflow/scripts/move-to-done.sh`, `.agents/skills/feature-workflow/scripts/open-task-pr.sh`, `.agents/skills/feature-workflow/scripts/rules-setting.sh`, `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/lib/workflow-paths.sh` (written by integration).

**Phase 1 tests:** None. The JRN-013 lint `tests/lint/shared-tracker-logic.sh` also needs T08's adoption script and belongs to T08.

**Size:** M (5 files, about 250 changed lines).

**Mode:** afk.

**Notes:** touches_core. Shared-core requests for `.agents/lib/` (integration, before wave 1):

1. **Host choice.** A function whose name contains `host`, taking a checkout directory and printing `github`, `gitlab` or nothing from its `origin` URL, the rule `open-task-pr.sh:27-28,162-164` uses today. Exit 0 in every case; an absent remote prints nothing.
2. **Path rewrite with rollback and scoped commit.** Functions whose names contain `rewrite`, extracted from `move-to-done.sh:141-182,228-236,283-306,371-377,387-406`. They rewrite a path `OLD` to `NEW` in every tracked `.workflow/` file except `cache/`, `initiatives/`, `.worktrees/`, `.handoff/` and staging. They keep a saved copy of each file so a failure rolls every change back, and they commit exactly the touched paths with a given subject. They are general enough for three cases: `specs/NAME` to `specs/done/NAME` (today's move), `specs/NAME` to `specs/NEW`, and `specs/done/NAME` to `specs/done/old_NAME`. A backlog list name `NAME.md` and `origin: NAME.md#B<n>` references count as paths (T08 needs them).
