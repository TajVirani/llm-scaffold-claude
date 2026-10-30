# Verification plan: Done folder for finished specs

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-done-folder: `move-to-done.sh --check` on a fixture spec with every task `done`/`split-out` and every backlog item from it `open`/`promoted`/`moved-to-deferred`/`dismissed` exits 0; with one task `pending` it exits non-zero, names that task, and changes no file.
- [ ] CAP-NEW-done-folder: sign-off 5.7 runs the check before `status ... done`; a failing check leaves the spec `in-review`.
- [ ] CAP-NEW-done-folder: moving a `done` fixture spec puts it at `.workflow/specs/done/NNN-slug/` with no `.step`, `spec_branch` unchanged, and the old folder gone.
- [ ] CAP-NEW-done-folder: after the move, every `.workflow/` file outside `cache/` and `initiatives/` that named the spec (repo-relative, `../specs/`, `../../specs/`, `specs/`, and `../NNN-slug/` from `work-backlog/` or a sibling spec) names the `done/` path; files under `cache/` and `initiatives/` are byte-identical; no other text in any file changed.
- [ ] CAP-NEW-done-folder: inside the moved spec, every relative link that leaves the folder still resolves to an existing path, and its own `.workflow/specs/NNN-slug` strings name the `done/` path.
- [ ] CAP-NEW-done-folder: moving a spec whose status is not `done`, or whose `done/NNN-slug` already exists, is refused with nothing changed.
- [ ] CAP-NEW-done-folder: `--sweep` moves every top-level `done` spec and leaves `draft`/`in-progress` specs and `work-backlog/` in place.
- [ ] CAP-NEW-done-folder: the 0.1.1 scan counts a spec in `done/`, so the next number is above it.
- [ ] CAP-NEW-done-folder: `spec_done_on_main` is true for a `done` spec on main at the top level and in `done/`; the 6.13 rewrite fixes the initiative's links on the initiative branch.
- [ ] CAP-NEW-done-folder: `check-write.sh` denies a Write/Edit under `.workflow/specs/done/**` (main session and sub-agent).
- [ ] CAP-NEW-done-folder: `review-lessons.sh validate` accepts `origin_spec: .workflow/specs/done/NNN-slug` and a slug with uppercase, `.` or `_`; rejects a path outside `.workflow/specs/`.
- [ ] CAP-NEW-done-folder: in this repo, specs 001-005 sit under `.workflow/specs/done/` after the sweep and `tests/run-all.sh` passes.

## Journeys

No running application: each journey is a harness suite run against a fixture project.

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Check refuses an open task | CAP-NEW-done-folder | 1. Fixture spec `in-review`, one task `pending`. 2. Run `move-to-done.sh --check`. 3. Run the 5.7 sequence. | Non-zero exit naming T<n>; spec stays `in-review`; tree unchanged | `tests/scripts/move-to-done.sh` / MISSING |
| JRN-002 | Sign-off move with links | CAP-NEW-done-folder | 1. Fixture `done` spec referenced from a shelf file, retrospective, capabilities row, review lesson, backlog item (`../NNN-slug/`), sibling spec, cache and initiative file. 2. Run the move. | Spec in `done/`, no `.step`; every reference outside `cache/`/`initiatives/` rewritten; cache and initiative untouched; outbound links inside resolve | `tests/scripts/move-to-done.sh` / MISSING |
| JRN-003 | Sweep | CAP-NEW-done-folder | 1. Fixture with two `done` specs, one `draft`, `work-backlog/`. 2. Run `--sweep`. | Both `done` specs in `done/`; `draft` and backlog untouched | `tests/scripts/move-to-done.sh` / MISSING |
| JRN-004 | Readers after the move | CAP-NEW-done-folder | 1. Spec in `done/`. 2. Run the 0.1.1 scan, `spec_done_on_main`, `check-write.sh` on a file in it, `review-lessons.sh validate`. | Number counted; done-on-main true; write denied; lesson valid | `tests/scripts/move-to-done.sh`, `tests/scripts/check-write-paths.sh`, review-lessons suite / MISSING |
| JRN-005 | This repo swept | CAP-NEW-done-folder | 1. Run `--sweep` here. 2. `tests/run-all.sh`. | 001-005 under `done/`; all suites pass | `tests/run-all.sh` / MISSING |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Fixture project with a spec, tasks, backlog items and back-links | A `.workflow/` tree in a temp git repo | `tests/fixtures/workflow-folders.sh`, extended | JRN-001 to JRN-004 |
| Expected-tree oracle | `git diff --stat` and a grep for the old path after the move: only path strings change, no old-path reference remains outside `cache/`/`initiatives/` | the test itself | JRN-002, JRN-003 |
| Link-resolution oracle | Every relative Markdown link in the moved spec resolves with `test -e` from its file's directory | the test itself | JRN-002 |

## Targets

<Filled at 1.1.>

## Suites

<Filled at 1.2-1.4.>
