# Proposals: Done folder for finished specs

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-011 \| Done folder: sign-off 5.7 runs `move-to-done.sh --check` and refuses `done` while a task record or backlog item from the spec is open; 5.8 moves the finished spec to `.workflow/specs/done/NNN-slug` on the spec branch, rewrites its path in `.workflow/` files outside the caches and initiatives (its own files and `pr-body.md` included) and adds one `../` to its outbound links, then publishes the Sign-off PR from there; every Write/Edit under the Done folder is denied; `--sweep` moves older finished specs once, leaving the spec being signed off for its own move; the 0.1.1 numbering scan, session start and large-path 6.13 find a finished spec in either place \| [.workflow/specs/done/007-done-folder](specs/done/007-done-folder/spec.md) | Without it, 0.3.1 would not see that closing finished specs exists and could plan a second archive mechanism. | spec.md § Capabilities | approved | |
| P2 | `.workflow/capabilities.md` CAP-006 row | replace: `and 5.8 publishes it unchanged as the PR/MR description or the local merge message` -> `and 5.8 publishes it, unchanged apart from the spec path the Done folder move rewrites (CAP-011), as the PR/MR description or the local merge message`; add the link [.workflow/specs/done/007-done-folder](specs/done/007-done-folder/spec.md) | Without it, an agent reading CAP-006 would treat the path rewrite of an approved body as a breach and stop 5.8, or drop the rewrite and publish links to a folder that no longer exists. | spec.md § Constraints (D14) | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P3 | `.workflow/decisions/pitfalls.md` (newest first) | `## Leave the spec being signed off out of a sign-off-wide pass` - What happened: the 5.8 one-time `--sweep` moved every top-level `done` spec, including the one being signed off (5.7 had already set it `done`), so its own move then exited 2 and sign-off would have stopped (review pass 1 F1, high, rework 1). - Where: `modules/sign-off.md` 5.8; `scripts/move-to-done.sh --sweep` - Spec: .workflow/specs/done/007-done-folder - Prevented by: `move-to-done.sh --sweep` leaves in place the spec whose `spec_branch` is checked out (`tests/scripts/move-to-done.sh`) | Without it, the next whole-repo pass added to sign-off (a rewrite, a lint, a cleanup) would again run over the spec that sign-off is still finishing. | triage F1 | rejected | one-off, not a recurring pitfall (stakeholder, 5.3) |
| P4 | `.workflow/decisions/pitfalls.md` (newest first) | `## Search every workflow file in one batch, never one process per file` - What happened: `move-to-done.sh --sweep` started a subshell and a `grep` per workflow file per spec (about 16,000 processes for 7 specs) and took 52.2 s against TGT-007's 30 s; one `xargs grep` per spec brought it to 12.9-15.8 s (review pass 2 F5, high, rework 2). - Where: `scripts/move-to-done.sh` - Spec: .workflow/specs/done/007-done-folder - Prevented by: none yet (TGT-007 measures this script only) | Without it, the next script that scans all of `.workflow/` would fork per file and fail its time target at review instead of at design. | triage F5 | rejected | one-off, not a recurring pitfall (stakeholder, 5.3) |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P5 | `.workflow/profiles/shell-scripts.md` § Mini-review checklist | `- [ ] A write or check inside a loop, function or command substitution whose caller adds \|\| die or \|\| exit carries its own \|\| die: bash suspends set -e on the left side of \|\|.` | Without it, the implementer relies on `set -e` where bash ignores it, and a failed write is dropped silently; T5's mini-review failed on this in three rounds (round 1 reads at `move-to-done.sh:222-231`, round 4 the scratch redirects, round 5 the `printf` at :300), each a fix round. The tool-rule alternative, shellcheck's optional `check-set-e-suppressed` (SC2310-SC2312), flags every existing `\|\|` call across the scaffold and is left for a later look. | T5 mini-review rounds 1, 4 and 5 (`artifacts/T5/mini-review-r1.yaml`, `-r4`, `-r5`) | approved | |
