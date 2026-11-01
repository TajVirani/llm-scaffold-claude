## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- Sign-off 5.7 runs `move-to-done.sh --check` and refuses `done` while a task record or a backlog item from the spec is open.
- Sign-off 5.8 moves the finished spec into the Done folder, `.workflow/specs/done/NNN-slug`, on the spec branch. It rewrites every link to the spec in `.workflow/`, `pr-body.md` included, and publishes the Sign-off PR from there.
- New script `move-to-done.sh`: `--check`, the move, and `--sweep`. The sweep moves older finished specs once and leaves the spec being signed off for its own move. A run that fails partway puts everything back.
- `check-write.sh` denies every Write/Edit under the Done folder, for the main session and sub-agents.
- The 0.1.1 numbering scan, session start (`spec_done_on_main`), large-path 6.13 and `review-lessons.sh` find a finished spec in either place, with spec numbers of any length.
- This repo's finished specs (001-006, 008, 00010-00013) move into `done/` in this PR, in their own sweep commit.

## Why the change

- Finished specs stayed in `.workflow/specs/` beside the ones in flight, so on a large project the folder filled up, and nothing on disk said a spec and everything under it was finished.
- After this change the top level lists only work in progress. The move runs as part of sign-off, so nobody has to remember it, and no link to a moved spec breaks.

## Why this approach

- The feature-workflow module owns the step (D1). Putting the logic in the shared library would route every change through integration for code only sign-off calls. A separate skill would be the step most likely to be skipped.
- The move runs in 5.8 on the spec branch, before the PR, so it reaches main with the merge and nothing commits straight to main (D2). Links are rewritten at move time rather than resolved later (D3). Open sub-items make the check refuse rather than being marked complete (D4).
- Created: `move-to-done.sh` and `WF_SPECS_DONE`. Extended: `wf_norm_folder`, `check-write.sh`, `review-lessons.sh`, the session-start hook, and sign-off, discovery, large-path and `SKILL.md`.

## Special things to note

- Report: [report.md](.workflow/specs/007-done-folder/report.md). No task PRs: this work runs on local branches only (`pr: null`).
- Known gaps: no harness suite runs the large-path 6.13 rewrite loop; it is backlog item `007-done-folder-disc-001`, which also proposes one script form for it. TGT-007 (sweep ≤ 30 s, measured 12.86 s) is sensitive to machine load. Line coverage is not measured.
- Deferred: `.workflow/deferred/sign-off-scoped-commit.md` (5.8 stages every untracked folder) and `.workflow/deferred/launch-against-done-spec.md` (a sub-agent launch with a Done folder `spec_dir` is refused).

## How to test

1. Run `tests/run-all.sh`. Expected: `TOTAL ... failed=0` across 64 suites.
2. Run `tests/run-all.sh --suite scripts/move-to-done`. Expected: every case passes (check, move, rewrite, sweep, rollback).
3. Run `ls .workflow/specs/done/`. Expected: 001-008 and 00010-00013. Then run `ls .workflow/specs/`. Expected: only 009, `work-backlog/` and `done/`.

## Blast radius

- Scripts: `move-to-done.sh` (new), `check-write.sh`, `review-lessons.sh`, `check-pr-body.sh` (header only), `.agents/lib/workflow-paths.sh` (shared core: a new variable and a wider `wf_norm_folder`), `.agents/hooks/session-start-resume.sh`.
- Docs: `SKILL.md`, `modules/sign-off.md`, `discovery.md`, `large-path.md`, `assets/pr-template.md`, `assets/review-lessons.md`.
- Workflow data: `.workflow/capabilities.md` (CAP-011, CAP-006 wording), `.workflow/profiles/shell-scripts.md` (one checklist line), `PROVENANCE.md`, and the swept spec folders with every `.workflow/` link to them.
- Untouched: `install.sh`, the installed `.gitignore` block, `commit-workflow-data.sh`, `status-transition.sh`, and any top-level spec that is not `done`.

## Risk and reversibility

Risk: Medium - the sweep and the move rename hundreds of tracked files and rewrite links in about 50 others; the harness covers the rewrite rules on fixtures, and a failed run rolls itself back.
Reversibility: Easy - revert the merge commit; the sweep and the move are plain renames plus path rewrites in their own commits.

## Areas, concepts and seams changed

- Changed shape: `wf_norm_folder spec` also accepts `.workflow/specs/done/NNN-slug`. `check-write.sh` has a new deny class for the Done folder. `review-lessons.sh validate` takes a Done folder `origin_spec` and the wider slug class.
- New: the `move-to-done.sh --check <spec-dir> | <spec-dir> | --sweep` CLI and the `WF_SPECS_DONE` variable.
- Concepts: **Done folder**, **Sign-off PR**, spec branch, work-backlog item.

## How to undo this PR

Revert the merge commit on main (`git revert -m 1 <merge sha>`). That moves the specs back to the top level and restores the old links. No settings or data outside the repo change.
