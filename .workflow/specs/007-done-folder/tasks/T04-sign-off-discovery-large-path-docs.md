# T04: Sign-off, discovery and large-path docs for the Done folder

Index: [../tasks.md](../tasks.md) · Blocked by: T2 (Review lessons accept the Done folder) · Parallel with: None

**What to build:** The workflow docs run the Done folder end to end. Sign-off 5.7 runs the sub-item check before `done`. Sign-off 5.8 runs the move and publishes from the Done folder, in the D14 order with the D15 stop. In this spec only, the one-time sweep runs first (D16). Discovery 0.1.1 never reuses a finished spec's number. Large-path `spec_done_on_main` and 6.13 find finished specs in either place. The router knows the Done folder. The templates state the new rules.

**Seam:** Text checks over the docs in `tests/lint/done-folder-docs.sh`, and the 5.8 publish block run by `tests/scripts/sign-off-pr.sh` with `SPEC_DIR` on the Done folder path.

**Acceptance criteria:**

- [ ] `modules/sign-off.md` 5.7: runs `.agents/skills/feature-workflow/scripts/move-to-done.sh --check .workflow/specs/NNN-slug` before `status ... done --step 5.7`; on a non-zero exit it stops, lists what is open, and leaves the spec `in-review` (D8).
- [ ] `sign-off.md` 5.8, in order: commit what is left; the existing pre-move `check-pr-body.sh` with its fix loop; the move (`move-to-done.sh .workflow/specs/NNN-slug`, which checks, moves, rewrites and commits); `check-pr-body.sh` on `.workflow/specs/done/NNN-slug/pr-body.md`; the path-only diff of `pr-body.md` shown with the publish go-ahead; publish. A fault on the moved body stops sign-off unpublished as a move bug, and nothing writes into the moved folder (D15). `SPEC_DIR=.workflow/specs/done/NNN-slug` in the variables list. The `<!-- 5.8 publish commands -->` marker stays directly above the publish block, and the block's lines are otherwise unchanged. The 5.8 progress line passes the `done/` path and `5.8`. A line says that the first sign-off after this feature in a repo with older `done` specs may run `move-to-done.sh --sweep` first, as its own commit (D5, D16).
- [ ] `sign-off.md` 5.4 and 5.5 stop promising the exact text: the body is published unchanged apart from the spec path the move rewrites (the "5.8 publishes it unchanged", "as 5.8 will publish it" and "keep the approved text exactly" lines).
- [ ] `modules/discovery.md` 0.1.1: the scan also lists the children of `.workflow/specs/done/` (`[0-9]*-*/`), and the prose says the Done folder's children count while `done/` itself does not.
- [ ] `modules/large-path.md`: `spec_done_on_main` is true for a `done` spec on main at the top level or in `done/` (D10); 6.13 runs the same path rewrite on the initiative branch for each emitted spec in `done/` when it closes the initiative, and names `specs/done`.
- [ ] `SKILL.md`: the Route by status `done` row says a finished spec is read from `.workflow/specs/done/` once moved; Find the state names the Done folder; the guarded-write table gains the row that `move-to-done.sh` at 5.8 is the one writer of path-only rewrites in Tier A files and design logs (D6), and that `.workflow/specs/done/**` is never written by Write/Edit (D11); `move-to-done.sh` is named.
- [ ] `assets/pr-template.md` header (lines 3-4) and `assets/review-lessons.md` header (the `origin_spec` rule, kept in step with `review-lessons.sh` from T2) state the new rules.
- [ ] `tests/lint/done-folder-docs.sh` and `tests/scripts/sign-off-pr.sh` pass; `agent-docs` lint suites pass.

**Predicted files:** `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/modules/discovery.md`, `.agents/skills/feature-workflow/modules/large-path.md`, `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/assets/pr-template.md`, `.agents/skills/feature-workflow/assets/review-lessons.md`

**Phase 1 tests:** `tests/lint/done-folder-docs.sh`, `tests/scripts/sign-off-pr.sh`

**Size:** M (6 files, about 120 changed lines).

**Mode:** afk.

**Notes:** Data model migrations M2-M3, the doc half. The move script itself is T5; these docs name its interface (`--check <spec-dir>`, `<spec-dir>`, `--sweep`; exit 0 done, 1 refused with the open items listed, 2 usage or not a spec folder). Keep the `tests/scripts/sign-off-pr.sh` contract (SPEC_DIR, SPEC_BRANCH, MAIN, SUBJECT; one command per line; run from the project root on the spec branch). The 5.8 publish block does not change, apart from what `SPEC_DIR` holds.
