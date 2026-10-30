# Design log: Done folder for finished specs

Spec: [spec.md](spec.md)

## 2026-10-29 Term gate 0.2.2: Done folder

- Raised: the place a finished spec moves to after merge ("done folder" or "z_" prefix in the request).
- Agreed: [**Done folder**](../../GLOSSARY.md), `.workflow/specs/done/`. "Spec archive" rejected: "archive" already names the deferred-handoff Archive step and `.workflow/deferred/archive/`. The `z_` prefix rejected: the top-level folder count never drops and every `[0-9][0-9][0-9]-*` glob needs a second pattern.
- Spec folder renamed from `007-spec-archive` to `007-done-folder` so the slug does not use an avoided alias.

## 2026-10-29 Placement: feature-workflow

- Owning module: feature-workflow (a new final sign-off step and its script under `.agents/skills/feature-workflow/scripts/`).
- Alternatives considered: lib: holding the move logic in shared core would put every change through the integration agent for logic only sign-off calls. New standalone skill: a manual step outside sign-off is the one most likely to be skipped.
- Touched beyond the owner: the `done/` path constant in `.agents/lib/workflow-paths.sh` (shared core, through the integration agent); hooks, installer and tests only where they scan or match spec paths ([codebase-map.md](codebase-map.md) Relevant code).
- Conflict with an ADR or rule: none. hooks, installer and tests already may depend on feature-workflow and lib (`.workflow/rules.md` Ownership); ADR-0001 says nothing about spec folder layout.
- Decision: **D1** feature-workflow owns the done-folder step. No ADR: placement inside the workflow's own module is not surprising, so it fails the three-part test.

## 2026-10-29 Deeper prompt

**Ask:** Once a feature's Sign-off PR has merged, close the spec. Mark the spec and everything under it as finished, then move it into the Done folder (`.workflow/specs/done/`). The top level of `.workflow/specs/` then lists only work still in progress.

**Goals:**
- After the merge, `.workflow/specs/` lists only in-flight specs, the `work-backlog/` folder and `done/`.
- One look at a spec in `done/` confirms it is finished. The spec is `done` and every task record is `done`. Any work-backlog item it created is either still open on purpose or already closed.
- Nothing breaks once a spec moves:
  - spec numbering never reuses its number;
  - the session-start offer stops listing it;
  - links pointing at it from shelf items, retrospectives, capabilities and review lessons still resolve.
- The step runs as part of the workflow, not as a separate chore someone has to remember.

**Downstream:** None known.

**Tools and technologies:** Plain `mv` + `git add` for the move, because `git mv` leaves the ignored `.step` file behind. yq v4 for frontmatter reads. Bash 3.2.

**Gotchas:**
- `done` is set at 5.7, before the merge at 5.8. So "after merge" needs a new step after 5.8, or a separate commit on main after the merge.
- Every existing link uses `.workflow/specs/NNN-slug`: deferred `origin_spec`, retrospectives, `capabilities.md` and the review-lessons regex.
- `wf_norm_folder` in `.agents/lib/workflow-paths.sh` only accepts specs sitting directly under `.workflow/specs/`.
- The `.step` gitignore pattern (`specs/*/.step`) does not match `specs/done/*/.step`.

**Not asked for:** Initiative cleanup, pruning `done/` by age, and reports over finished specs.

**Original request:** "Need to have a step at the end once the code is done and merged to cleanup the spec. We need a way to designate an item is done, and all sub items are done. I think having a z_ in front of the name of the spec folder and making all statuses marked complete could do the job, or we could have a done folder in specs. In large projects the specs folder could get crowded."

Rounds: 1 draft (ask + goals proposed; stakeholder answered downstream "no", tools and gotchas "just what you suggested"); 2 full block restated, agreed ("ready").

## 2026-10-29 Questioning round 1

- **Q1 When the spec moves.** Options: in 5.8 on the spec branch before the Sign-off PR opens; after the merge, a new step committing to main. Recommended: in 5.8 (5.8 ends once the PR is open and nothing waits for the merge; `done` is already set at 5.7). Answer: "In 5.8, before the PR". **D2** the move is committed on the spec branch in 5.8, before push and PR, and reaches main with the merge.
- **Q2 Links to a moved spec.** Options: rewrite at move time; keep old paths as IDs plus a resolver. Recommended: rewrite. Answer: "Rewrite at move". **D3** the move rewrites `.workflow/specs/NNN-slug` to `.workflow/specs/done/NNN-slug` (and the relative forms) in `.workflow/` files outside the spec; the review-lessons regex and `wf_norm_folder` accept `done/`.
- **Q3 Sub-items.** Options: verify and refuse; force-mark complete. Recommended: verify. Answer: "Verify, refuse if not". **D4** the move runs only when the spec is `done`, every task record is `done` or `split-out`, and every work-backlog item with this origin is `open`, `promoted` or `moved-to-deferred`; otherwise it lists what is open and changes nothing.
- **Q4 Existing done specs.** Options: sweep mode run once here; new specs only. Recommended: sweep. Answer: "Yes, sweep mode". **D5** the script has a sweep mode that moves every top-level `done` spec; run once in this repo within this feature; target projects run it once to catch up.
- Facts looked up instead of asked ([fact-lookup](codebase-map.md)): 5.8 ends at PR open and nothing writes the spec folder after it except 6.13's read-only `git show` (sign-off.md 159-165, large-path.md 249-288); no script checks task records at 5.7, only the retrospective verdict (status-transition.sh 432; retrospective SKILL.md 82-86); task statuses `pending|in-progress|done|blocked|split-out` (status-transition.sh 90); backlog statuses `open|promoted|moved-to-deferred|dismissed` (assets/work-item.md 5); light path uses the same 5.7-5.8; no guard hook sees Bash writes (check-write.sh 53-55); specs 001-005 are `done`, each mentioned by 6-21 files under `.workflow/`.
- Required, not asked: the 0.1.1 numbering scan and 6.13 / `spec_done_on_main` look in `done/` too.

## 2026-10-29 Questioning round 2

- **Q5 Write rules for the rewrite.** Options: the move script owns path-only rewrites; skip guarded files. Recommended: script owns them. Answer: "Script owns path rewrites". **D6** the move script is the one writer of path-only rewrites in Tier A files and append-only design logs at 5.8: it changes only the moved spec's path string. The rule line goes to `proposals.md` for 5.3.
- **Q6 Relative links inside the moved spec.** Options: add one `../`; leave them. Recommended: add one. Answer: "Add one ../". **D7** the move adds one `../` to every relative link in the moved spec that leaves the spec folder; links inside the folder are unchanged.
- **Q7 When the sub-item check runs.** Options: before 5.7 sets `done`, and again before the move; only at the move. Recommended: before done. Answer: "Check before done". **D8** 5.7 runs the D4 check before `status ... done` and stops listing what is open; 5.8 runs it again before the move.
- Fact found instead of asked: outside `.workflow/` only test fixtures name spec paths (`rg` over the repo), so the D3 rewrite covers `.workflow/` only.

## 2026-10-29 Goal confirmed (0.3.19)

- Summary of D2-D8 plus sweep mode and `.step` removal on move, restated to the stakeholder. Answer: "matches". One feature (CAP-NEW-done-folder). Light-path facts: intent gaps clean, no irreversible action, footprint not small (lib, hooks, feature-workflow, retrospective, tests) → **D9** full path, `light_path: false`.

## 2026-10-29 Impact classification

- Term gate 0.4.2: no new concept; the Done folder entry covers the move, and the script is named for what it does (`move-to-done.sh`), avoiding "close"/"archive".
- create: `WF_SPECS_DONE` constant (`.agents/lib/workflow-paths.sh`, shared core); `move-to-done.sh` (`--check`, move, `--sweep`) under feature-workflow scripts; a test suite for it.
- extend: `wf_norm_folder spec` accepts a `done/` child; `sign-off.md` 5.7 (check before done) and 5.8 (move before push); `discovery.md` 0.1.1 scan counts `done/`; `large-path.md` 6.13 and `session-start-resume.sh` `spec_done_on_main` look in `done/`; `review-lessons.sh` `origin_spec` regex; feature-workflow `SKILL.md` (Route by status `done` row, write table entry for the script's path rewrite).
- unchanged: `check-write.sh` and the write-guard hooks (they do not see Bash writes; done specs are already skipped); `install.sh` `GI_ENTRIES` and the `.step` deny rule (`.step` is removed on move).
- Tier A: one rule line in `.workflow/rules.md` for D6, as a `proposals.md` entry for 5.3.
- Migration: sweep 001-005 in this repo (D5).

## 2026-10-29 Questioning round 3 (loop-back from 0.4.7)

Seeded by the module audit ([codebase-map.md](codebase-map.md) Module audit), which conflicted with D3 and D4.

- **Q8 Initiative links.** Options: skip `.workflow/initiatives/` at 5.8 and rewrite at 6.13 on the initiative branch; skip and leave links. Recommended: skip, fix at 6.13 (initiative files commit only on `initiative/NNN-slug`, `sign-off.md:157`). Answer: "Skip, fix at 6.13". **D10 (amends D3)** the 5.8 rewrite skips `.workflow/initiatives/`; `spec_done_on_main` accepts the top level and `done/`; 6.13 runs the same rewrite on the initiative branch when it closes the initiative.
- **Q9 Guard for done/.** Options: deny every Write/Edit under `specs/done/**`; leave unguarded. Recommended: deny (`check-write.sh:205-226` classes it `other`, allowed). Answer: "Deny all". **D11** `check-write.sh` denies every Write/Edit under `.workflow/specs/done/**`.
- **Q10 Amendments.** (a) `dismissed` backlog items pass the check; (b) the rewrite skips `.workflow/cache/`; (c) the rewrite also fixes `.workflow/specs/NNN-slug` strings inside the moved spec. Recommended: accept all. Answer: "Accept all three". **D12 (amends D3, D4)** as listed.
- **Q11 Scope gate.** (1) review-lessons `origin_spec` regex allows only lowercase slugs while `wf_norm_folder` allows `[A-Za-z0-9._-]`; (2) 5.8 sweeps an untracked seeded spec onto the branch. Recommended: shelve both. Answer: "Fix (1) here, shelve (2)". **D13** (1) is in scope: the regex extended for `done/` also takes the `wf_norm_folder` slug class, with the template header kept in step. (2) is the same item as `.workflow/deferred/sign-off-scoped-commit.md` (confirmed in the question): a Later requests line added there.

## 2026-10-29 Scope decision: untracked seeded spec swept at 5.8

- Item: 5.8 commits everything untracked, so a seeded draft spec gets swept onto this spec's branch and, with D3, its links rewritten there. Evidence: `modules/sign-off.md:132,161`, `modules/discovery.md:53`.
- Ruling: can wait; same concept as the shelved item. Later requests line in [sign-off-scoped-commit.md](../../deferred/sign-off-scoped-commit.md). Mode: AFK.

## 2026-10-29 Goal confirmed (0.3.19, after round 3)

- Revised summary (D10-D13) restated. Answer: "confirm". One feature, full path (D9 stands). `spec.md` Constraints and success line updated.

## 2026-10-29 Impact classification (amended after round 3)

- Supersedes the `unchanged` line of the first classification for `check-write.sh`: now **extend** (D11, a `done` class denying every write under `specs/done/**`).
- extend: `large-path.md` 6.13 runs the rewrite on the initiative branch (D10); `review-lessons.sh` and `assets/review-lessons.md` header take the `wf_norm_folder` slug class (D13).
- 0.4.7: no remaining conflict with the goal or placement; the audit already read every part named here, so no second audit.

## 2026-10-30 Main moved since handoff

- Main: 02bc218..581e785 (main). Specs 006-result-file-guard and 008-pr-description-template merged, plus quick fix f436aed; 43 files in the affected area (`git diff --stat 02bc218..581e785 -- <affected paths>`).
- Commit f436aed Accept any spec number length; number new specs with five digits
- Commit b20dabe feat(sign-off): fill, approve and publish the Sign-off PR description (with 46d8e9f, 2b05147, 163acd3)
- Commit fd4a1d7 feat(lib): implement wf_enc and wf_agent_worktree_name
- File .agents/skills/feature-workflow/modules/sign-off.md +56 -6
- File .agents/skills/feature-workflow/scripts/check-pr-body.sh +238 (new)
- File .agents/skills/feature-workflow/assets/pr-template.md +62 (new)
- File .agents/lib/workflow-paths.sh +65 -0
- File .agents/skills/feature-workflow/modules/discovery.md +3 -3
- File .agents/skills/feature-workflow/scripts/review-lessons.sh +2 -2
- File .agents/skills/feature-workflow/scripts/check-write.sh +1 -1
- File install.sh +250, .agents/hooks/* (worktree guard, stop audit, codex-pre-spawn), tests/* (new suites)

## 2026-10-30 Contracts changed under the spec (1.1)

- **Spec numbers have any digit count** (f436aed). `wf_norm_folder` takes `^[0-9]+-<slug>$`; 0.1.1 globs `.workflow/specs/[0-9]*-*/` and greps `^[0-9]+`; new specs get five digits (`00010-worktree-guard-followups` exists); `review-lessons.sh` takes `^\.workflow/specs/[0-9]+-[a-z0-9-]+$`. Effect: the move script, the `done/` scan in 0.1.1 and the D13 regex use `[0-9]+`, never `[0-9]{3}`. D13 still stands (the slug class is still lowercase only).
- **Sign-off PR description** (008). 5.4 fills `.workflow/specs/NNN-slug/pr-body.md`; 5.5 asks the stakeholder to approve its full text; 5.8 re-runs `check-pr-body.sh` and publishes it "unchanged" as the PR body or the local merge message, from `SPEC_DIR=.workflow/specs/NNN-slug`. The pr-body hash check was dropped (46d8e9f), and `check-pr-body.sh` checks sections, not link paths. Effect: the D2 move in 5.8 changes `SPEC_DIR` and, through D12, rewrites the spec path inside the approved `pr-body.md`. Not settled by D1-D13: a decision (discovered work, below).
- **More specs are done.** 006 and 008 are `done` on main, so the D5 sweep here moves 001-006 and 008, not 001-005.
- **Agent worktrees** (006). Phase 1 and integration builds now run in orchestrator-made worktrees under `.workflow/.worktrees/`; Bash reads pass the worktree scope check. No 007 contract changes.
- Unchanged: `commit-workflow-data.sh`, `session-start-resume.sh`, `status-transition.sh`, `large-path.md`.

## 2026-10-30 Discovered work: pr-body-move-order

- Found at: step 1.1 by the main session (main-drift read). Kind: decision
- Problem and evidence: spec 008's 5.4 fills `pr-body.md`, 5.5 has it approved and 5.8 publishes it "unchanged" from `SPEC_DIR=.workflow/specs/NNN-slug`; 007's D2 move in 5.8 changes that folder and D12 rewrites the spec path inside `pr-body.md` (`modules/sign-off.md` 5.4, 5.8 on main 581e785).
- Assessment and ruling: blocker; to discovery (spec back to draft). Answer: "Blocker, go to discovery".
Outcome: loop back (00.24 discovered work)

## 2026-10-30 Questioning round 4 (loop-back from 00.24)

Seeded by the discovered work pr-body-move-order above.

- **Q12 pr-body.md and the move.** Options: move after the 5.8 body check and before publishing, the rewrite treating `pr-body.md` like every other spec file, `check-pr-body.sh` run again on the moved file, publish from the `done/` path, the go-ahead showing the path-only diff; 5.4 fills the body with the `done/` path so the move skips it; move after publishing in a separate commit on main. Recommended: move first (one rule, no special case; the check reads sections, not paths). Answer: "Move first, rewrite body". **D14 (amends D2)** 5.8 order: commit what is left, check the body, run the move (check, `mv`, rewrite, commit on the spec branch), run `check-pr-body.sh` on `.workflow/specs/done/NNN-slug/pr-body.md`, show the stakeholder the path-only diff of `pr-body.md` with the publish go-ahead, then publish with `SPEC_DIR=.workflow/specs/done/NNN-slug`. The 5.4 line "5.8 publishes it unchanged" becomes "unchanged apart from the spec path the move rewrites".
- Facts found instead of asked: spec numbers now have any digit count (f436aed), so every pattern in the move script, the 0.1.1 `done/` scan and the D13 regex use `[0-9]+`; specs 006 and 008 are `done` on main, so the D5 sweep in this repo moves 001-006 and 008; `check-pr-body.sh` checks sections and scores, not paths (`scripts/check-pr-body.sh` header lines 3-23).

## 2026-10-30 Goal confirmed (0.3.19, after round 4)

- Revised summary (D14, any-length spec numbers, sweep 001-006 and 008) restated. Answer: "Matches". One feature, full path (D9 stands: footprint unchanged).

## 2026-10-30 Impact classification (amended after round 4)

- Term gate 0.4.2: no new concept (Sign-off PR and PR template are 008's terms).
- extend: `sign-off.md` 5.4 (the "publishes it unchanged" line names the path rewrite) and 5.8 (D14 order; publish with `SPEC_DIR` on the `done/` path; the merge-message build reads the moved `pr-body.md`).
- extend: every pattern this feature adds takes any-digit spec numbers (`[0-9]+`).
- unchanged: `check-pr-body.sh` and `assets/pr-template.md` (sections only, no paths).
- Migration M4 sweeps 001-006 and 008.

## 2026-10-30 Scope decision: launch against a finished spec

- Item: `resolve-launch.sh` refuses a `spec_dir` under `.workflow/specs/done/`, so no sub-agent can launch against a moved spec (module-audit refresh, Out of scope noticed; `scripts/resolve-launch.sh:103`). Can wait: every sign-off launch runs before the 5.8 move.
- Ruling: shelved to [launch-against-done-spec.md](../../deferred/launch-against-done-spec.md); no shelf match by concept (`main-checkout-resolver.md` is about finding the main checkout). Mode: HITL (which task types to allow is a decision).

## 2026-10-30 Questioning round 5 (loop-back from 0.4.7)

Seeded by the module-audit refresh: after the move the D11 deny blocks every Write/Edit under `done/`, while D14 re-checks `pr-body.md` there.

- **Q13 A fault after the move.** Options: fix every body fault before the move and stop on a post-move fault as a move bug; let the main session Edit `pr-body.md` and `design-log.md` under `done/` at step 5.8. Recommended: fix before, stop after (only the path rewrite touches the body between the checks; `check-pr-body.sh` reads no paths). Answer: "Fix before move, stop after". **D15 (refines D14)** every body fix happens before the move (5.4, 5.5, the 5.8 pre-move check); a `check-pr-body.sh` fault on the moved body stops sign-off unpublished and is reported as a move bug; 5.8 writes nothing into the moved folder. D11 stays absolute.
- Facts from the audit, applied without asking: the stale "published unchanged" lines in `check-pr-body.sh:3,28`, `assets/pr-template.md:3-4` and `sign-off.md:126,205` are reworded (extend, comment and prose only); the `<!-- 5.8 publish commands -->` marker stays directly above the publish block that `tests/scripts/sign-off-pr.sh` runs; nothing after the move calls a `wf_norm_folder` script; the 5.8 progress line passes the `done/` path and `5.8`.

## 2026-10-30 Goal confirmed (0.3.19, after round 5)

- Revised summary (D15, shelved launch-against-done-spec) restated. Answer: "Matches". One feature, full path (D9 stands).

## 2026-10-30 Exit gate 0.6 (after rounds 4-5)

- Scope: clear (Non-goals and `deferred` list sign-off-scoped-commit and launch-against-done-spec; no open questions). System impact: clear (module-audit refresh in codebase-map; the five `cache disagrees with code` lines resolved by republishing all three caches at 9e971ad and refreshing retrieval). Data changes: clear (data-model M1-M4, pr-body row). Testable objectives: clear (CAP-NEW-done-folder has 15 objectives and JRN-001-JRN-007).
