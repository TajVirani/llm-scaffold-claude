---
status: done # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "9e971ade158b5e92da93bf2b150fd68dd55d7e9e" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/007-done-folder # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "9bd7f698f78051ca6212463706bad4eccd714761" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/sign-off-scoped-commit.md, .workflow/deferred/launch-against-done-spec.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
budget: {max_tasks: 10, max_changed_files: 30} # written at 2.5 from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
---

# Done folder for finished specs

## Why

Finished specs stay in `.workflow/specs/` next to the ones still in flight, so on a large project the folder fills up and nothing on disk says at a glance that a spec and everything under it is finished. Once a feature's Sign-off PR merges, the spec should be closed: checked that it and all its sub-items are finished, then moved into the Done folder (`.workflow/specs/done/`), so the top level of `.workflow/specs/` lists only work still in progress. The step runs as part of sign-off, not as a chore someone has to remember, and nothing that points at the spec breaks when it moves.

## Capabilities

- **CAP-011** Close a finished spec into the Done folder
  - **intent:** At sign-off the workflow checks that a spec and all its sub-items are finished and moves it into `.workflow/specs/done/` with every link to it still resolving, so the specs folder shows only in-flight work.
  - **success:** After sign-off 5.8 on a fixture project, the spec sits at `.workflow/specs/done/NNN-slug/` on the spec branch with `status: done`, every task record `done` or `split-out`, no `.step`, every `.workflow/` file outside `cache/` and `initiatives/` that named `.workflow/specs/NNN-slug` now naming `.workflow/specs/done/NNN-slug`, the spec's outbound relative links resolving, the published PR description (`pr-body.md`) naming the `done/` path, the next 0.1.1 scan not reusing its number, and a Write/Edit under `done/` denied; a spec with an open task is refused at 5.7 with that task listed and nothing changed.

## Constraints

- The sub-item check runs before 5.7 sets `done` (records can still be fixed) and again before the move in 5.8 (D8). It passes when every task record is `done` or `split-out` and every work-backlog item from this spec is `open`, `promoted`, `moved-to-deferred` or `dismissed` (D4, D12).
- The move is committed on the spec branch before push and PR; nothing commits straight to main (D2).
- 5.8 order: commit what is left, check `pr-body.md`, move and rewrite (the rewrite covers `pr-body.md` like any spec file), commit, run `check-pr-body.sh` on the moved body, show the stakeholder the path-only diff with the publish go-ahead, publish from `.workflow/specs/done/NNN-slug` (D14). Every body fix happens before the move; a fault on the moved body stops sign-off unpublished as a move bug, and nothing writes into the moved folder (D15).
- Spec numbers have any digit count (`wf_norm_folder`, 0.1.1): every pattern this feature adds uses `[0-9]+`, never a fixed width.
- The rewrite changes only the moved spec's path string, in `.workflow/` files only, including the moved spec's own files; it skips `.workflow/cache/` and `.workflow/initiatives/` (D3, D10, D12). The move script is the one writer allowed to do it in Tier A files and append-only design logs (D6).
- Initiative files are rewritten only at 6.13, on the initiative branch (D10). As built, 6.13 runs its own rewrite loop in `modules/large-path.md` with the same path boundary as the script; one script form is backlog item `007-done-folder-disc-001`.
- The one-time `--sweep` of older finished specs runs at 5.8 as its own commit, before the signing-off spec's own move, and leaves in place the spec whose `spec_branch` is checked out, for that move (D16, review F1).
- Every Write/Edit under `.workflow/specs/done/**` is denied (D11).
- The review-lessons `origin_spec` rule accepts `done/` and the `wf_norm_folder` slug class, with the template header kept in step (D13).
- Plain `mv` plus `git add`, not `git mv`: the folder may be untracked and `.step` is gitignored. Bash 3.2, yq v4.
- The Done folder path is built from `WF_SPECS` in `.agents/lib/workflow-paths.sh`, never a literal.

## Non-goals

- Closing initiatives or moving initiative folders.
- Pruning or deleting specs in `done/` by age.
- Reports or listings over finished specs.
- Rewriting spec paths outside `.workflow/` (only test fixtures name them).
- Force-marking open task records or backlog items complete (D4: the check refuses instead).
- Scoping the 5.8 commit so an untracked seeded spec is not swept onto the branch: shelved as [sign-off-scoped-commit](../../deferred/sign-off-scoped-commit.md) (Later requests line, D13).
- Launching a sub-agent with a Done folder `spec_dir` (every sign-off launch runs before the move): shelved as [launch-against-done-spec](../../deferred/launch-against-done-spec.md).

## Success signal

On this repo, every spec done on main before this feature (001–006 and 008) sits under `.workflow/specs/done/` with every back-link resolving, and the next spec to finish sign-off lands there by itself in its Sign-off PR, leaving only in-flight specs, `work-backlog/` and `done/` at the top level. Objectives and journeys: [verification-plan.md](verification-plan.md).

## Assumptions

- Confirmed: the local `.step` marker is deleted on the move rather than carried into `done/` (set aside during the move so a failed run can restore it), so no gitignore or deny-rule pattern needs a `done/*/.step` form.
- Confirmed: the move belongs inside step 5.8; no new step id was added, and the progress-line step count is unchanged.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Shelf items: [.workflow/deferred/sign-off-scoped-commit.md](../../deferred/sign-off-scoped-commit.md), [.workflow/deferred/launch-against-done-spec.md](../../deferred/launch-against-done-spec.md)
- Report: [report.md](report.md)
