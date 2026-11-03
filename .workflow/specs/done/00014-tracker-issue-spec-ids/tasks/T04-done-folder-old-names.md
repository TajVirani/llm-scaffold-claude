# T04: Done folder accepts old_ names

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Shared host choice and path rewrite; both change `move-to-done.sh`) · Parallel with: None

**What to build:** After **Tracker adoption**, a finished spec can be named `.workflow/specs/done/old_NNN-slug`, with its backlog list named `.workflow/specs/work-backlog/old_NNN-slug.md`. Every workflow script accepts both names: `wf_norm_folder`, the `review-lessons.sh` `origin_spec` check, the check-write backlog-list name rule and the `move-to-done.sh` `open_sub_items` lookup. `old_` is accepted only in the Done folder; malformed names (`done/x01-short`, `done/done`, `done/work-backlog`, nested paths, `old_` at the top level) are still refused.

**Seam:** `wf_norm_folder`, `review-lessons.sh validate`, the `check-write.sh` CLI and `move-to-done.sh --check`, driven by their suites.

**Acceptance criteria:**

- [ ] `wf_norm_folder spec .workflow/specs/done/old_012-alpha` prints the folder; `specs/old_012-alpha` and the existing malformed names are refused.
- [ ] `review-lessons.sh validate` accepts an `origin_spec` of `.workflow/specs/done/old_NNN-slug`.
- [ ] `check-write.sh` admits a write to `.workflow/specs/work-backlog/old_NNN-slug.md` at 00.26 and 5.9, and still refuses malformed list names.
- [ ] `move-to-done.sh --check` on an `old_` Done spec finds its `old_` backlog list.

**Predicted files:** `.agents/skills/feature-workflow/scripts/review-lessons.sh`, `.agents/skills/feature-workflow/scripts/check-write.sh`, `.agents/skills/feature-workflow/scripts/move-to-done.sh`.

**Phase 1 tests:** `tests/scripts/lib-workflow-paths.sh`, `tests/scripts/review-lessons.sh`, `tests/scripts/check-write-paths.sh` (their JRN-012 tests). The two JRN-012 `move-to-done.sh --check` tests sit in `tests/scripts/tracker-adoption.sh`, which T08 owns; this task's lookup change makes them pass.

**Size:** S (3 files, about 60 changed lines).

**Mode:** afk.

**Notes:** touches_core. Shared-core request for `.agents/lib/workflow-paths.sh` (integration, before wave 2): `wf_norm_folder spec` accepts `specs/done/old_<digits>-<slug>`, and only in the Done folder. Migration M2 from data-model.md.
