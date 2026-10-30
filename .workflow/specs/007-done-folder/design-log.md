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

## 2026-10-30 Targets (1.1)

- Main-moved contracts read at 1.1 (see "Contracts changed under the spec" above); none further.
- Sweep time threshold: options ≤ 5 s, ≤ 10 s (recommended), ≤ 30 s. Answer: "≤ 30 s". Line coverage: "Not measured" (recommended). TGT-001-TGT-008 written; TGT-004 enforces the no-literal constraint.

## 2026-10-30 Task breakdown (2.1-2.4)

- Breakdown: T1 Done folder path and write deny (touches_core: `WF_SPECS_DONE`, `wf_norm_folder` accepts a `done/` child), T2 review lessons accept the Done folder, T3 session start sees done-on-main in `done/` (hooks), T4 sign-off, discovery and large-path docs (after T2), T5 `move-to-done.sh` (after T1, T4). Waves: T1-T3, T4, T5; no predicted-file overlaps. Answer: "Approve".
- **Q14 Where the sweep of this repo runs.** Options: at 5.8 in the main checkout as its own commit on the spec branch before 007's own move, then `tests/run-all.sh`; a sixth Phase 3 task with an approved budget overrun. Recommended: at 5.8 (about 840 renamed files would swamp the 30-file budget; a worktree run leaves the old `.step` markers in the main checkout). Answer: "At 5.8, own commit". **D16 (amends D5)** the one-time sweep of 001-006 and 008 runs at 5.8 for this spec only, before the move of 007 itself, committed alone and followed by a passing `tests/run-all.sh` (JRN-005); no task carries it.
- Budget: defaults kept, `max_tasks: 10`, `max_changed_files: 30`. Answer: "Keep 10 / 30".
- Seams (2.3): `check-write.sh --cwd --path` CLI and the lib functions (T1); `review-lessons.sh validate` (T2); the session-start hook's output (T3); doc text checks and the 5.8 publish block (T4); the `move-to-done.sh` CLI in a fixture repo (T5). Answer: "Agreed". 2.2: every slice is specifiable from D1-D16.

## 2026-10-30 T2 mini-review round 1

- Fail: item 1 (Done folder path spelled out in `review-lessons.sh` instead of built from `workflow-paths.sh`) and R4 (header names paths the script never reads). Behaviour fix round: fresh launch.
- Out of scope noticed (`assets/review-lessons.md:9` still states the old `origin_spec` rule): not discovered work; it is T4's acceptance criterion (the template header kept in step with the script).
- T1 re-check out-of-scope note (toolchain tree hash differs from the git tree): not discovered work; the tree hash excludes the workflow data folders, and `run-toolchain.sh --reuse` on head 7323ca9 matched the same tree (pass, reused_from T1).
- 3.16 task review: skipped the task PRs for every wave (pr: null). `origin` is about 150 commits behind and is not used for this work; nothing is pushed (local-merge route, as for specs 006 and 008).

## 2026-10-30 Discovered work: initiative-link-rewrite-form

- Found at: step 3.4 by implementation T4 (`artifacts/T4/implementation.yaml`). Kind: decision
- Problem and evidence: 6.13 rewrites an initiative's links to moved specs with a `sed` loop in the doc block (`modules/large-path.md` § 6.13, commit `c863498`); `move-to-done.sh` has no form for it, so the rewrite rules live in two places.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9. The doc loop meets D10; T5's header names only 5.7 and 5.8 as callers.
- Backlog item: [work-backlog/007-done-folder-disc-001.md](../work-backlog/007-done-folder-disc-001.md)

## 2026-10-30 T4 mini-review round 1

- Fail: R2 (`modules/large-path.md:289`, the skip of slices not in `done/` needs its reason). Out of scope noticed: the 6.13 `sed` rewrite misses the second of two adjacent occurrences separated by one character (`large-path.md:291`). Not discovered work: a defect in T4's own change, fixed in this round. Behaviour fix round: fresh launch.
- T4 round 2 pass. Out of scope noticed (`move-to-done.sh` is still the stub): not discovered work; it is T5.

## 2026-10-30 T5 mini-review round 1

- Fail: item 3 (four reads at `move-to-done.sh:222-231` treat a failure as a clean result), item 4 (`git branch --show-current` at :110 exits with git's status, not 2), item 8 (the awk helper `adjusted` at :156 has no contract line). Out of scope noticed (an environment error after the `mv` at :217 leaves the spec moved and uncommitted, unreported): not discovered work; a defect in T5's own change, fixed in this round. Behaviour fix round: fresh launch.
- T5 round 3 re-check pass. Out-of-scope note (toolchain tree hash differs from the git tree): not discovered work; `run-toolchain.sh --reuse` on head e9ed598 matched the recorded tree.
- 3.9 last wave: full harness 3789 passed, 0 failed (64 suites). 3.10-3.11: no browser suite (not applicable, verification-plan Suites); spec set in-review at 3.11.

## 2026-10-30 Discovered work: integration-commit-subjects

- Found at: step 4.4 by review-standards pass 1 (RS-2, F3). Kind: bug
- Problem and evidence: `.agents/agents/integration.md:71` never states the Conventional Commits subject rule that `.agents/agents/implementation.md:81` does; integration commits `efd0c38`, `131f786` lack a type prefix.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9.
- Backlog item: [work-backlog/007-done-folder-disc-002.md](../work-backlog/007-done-folder-disc-002.md)

## 2026-10-30 Triage, review pass 1

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | review-end-state (RE-1) | The 5.8 one-time sweep also moves the spec being signed off (5.7 already set it `done`), so its own move then exits 2 and sign-off stops; breaks the D16 and D14 order | `.agents/skills/feature-workflow/modules/sign-off.md:192`; `scripts/move-to-done.sh` `--sweep` | high | Read 5.7 (status `done` before 5.8) and 5.8 (sweep before the move); `--sweep` moves every top-level `done` spec with no exception (`move-to-done.sh:7,11,82`). On this repo's own sign-off 007 is `done` at the top level when the sweep runs. | patch (T5: `--sweep` leaves in place the spec whose `spec_branch` is the checked-out branch, reports it as moved by its own step, header and a suite case) |
| F2 | review-standards (RS-1) | Integration commits `efd0c38`, `131f786` have subjects that are not Conventional Commits | commits `efd0c38`, `131f786` | low | `git log` shows subjects without a type prefix; developer-only harm (log reading) | none (dismissed: rewording needs a history rewrite of commits already merged on the spec branch; the cause is filed as F3) |
| F3 | review-standards (RS-2) | The integration agent definition does not state the Conventional Commits subject rule | `.agents/agents/integration.md:71` | medium | Compared with `.agents/agents/implementation.md:81`; produced F2 | discovered work (filed: [work-backlog/007-done-folder-disc-002.md](../work-backlog/007-done-folder-disc-002.md)) |
| F4 | review-targets (RT-1) | The TGT-007 command cannot run: the scratch clone is detached at the baseline, `--sweep` refuses a detached checkout, and the pipeline hides the exit code | `verification-plan.md` § Targets `sweep-time`; `artifacts/review/pass-1/targets/sweep-sanity-check.txt:4` | medium | The command checks out `$BASE` detached; `move-to-done.sh` refuses a detached HEAD (exit 1); the printed 0.37 s timed a refused run | patch (main session: the plan's own command, checked out on a scratch branch; TGT-007 measured after the T5 rework) |

Gaps (not_verifiable, review-end-state): JRN-005 and the Success signal run at 5.8 (D16), checked there; "the next spec lands there by itself" is seen only on a later sign-off (noted for 5.4 Known gaps); no suite runs the 6.13 rewrite block (appended to [work-backlog/007-done-folder-disc-001.md](../work-backlog/007-done-folder-disc-001.md) as an Also seen line).

Failed lenses: none
Outcome: rework 1 of 5
- F4 patch: the TGT-007 `sweep-time` command now checks the baseline out on a scratch branch (`-b tgt-sweep`), since `move-to-done.sh` refuses a detached checkout, and prints FAIL when the sweep fails instead of hiding it; the threshold is unchanged. Measured after the T5 rework.
- T5 rework (F1) mini-review pass. Out-of-scope note (the skip keys on `spec_branch` matching the checked-out branch, not on a running sign-off): not discovered work; the intended, documented behaviour (header lines 5-8, 22-23).
- TGT-007 measured by the main session after rework 1 with the fixed command: best of 3 = 52.21 s (threshold 30 s), a miss; pass 2's targets lens measures it independently.

## 2026-10-30 Triage, review pass 2

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F5 | review-targets (RT-1) | TGT-007 missed: `move-to-done.sh --sweep` on a scratch clone at the baseline took 52.23 s best of 3, threshold ≤ 30 s | `.agents/skills/feature-workflow/scripts/move-to-done.sh`; `artifacts/review/pass-2/review-targets.yaml` | high | Measured by the lens (52.23 s) and independently by the main session after rework 1 (52.21 s) with the corrected command | patch (T5: cut the sweep's per-file process cost so TGT-007 is met, behaviour unchanged) |
| F6 | review-standards (RS-1) | The 6.13 rewrite in `large-path.md` duplicates the script's path rewrite and already differs: a path that ends a sentence (`.workflow/specs/NNN-slug.`) is left unrewritten in initiative files | `.agents/skills/feature-workflow/modules/large-path.md` § 6.13; `scripts/move-to-done.sh:268` | medium | Compared the two boundary rules: the script keeps a sentence-ending full stop and rewrites, the 6.13 `sed` treats `.` as a name character | patch (T4: align the 6.13 boundary with the script's; one script form stays in [work-backlog/007-done-folder-disc-001.md](../work-backlog/007-done-folder-disc-001.md)) |

Gaps (not_verifiable, review-end-state): as pass 1 (JRN-005 at 5.8, the next spec at a later sign-off, the 6.13 block in no suite).

Failed lenses: none
Outcome: rework 2 of 5
- Rework 2, T5 fix round 2: mini-review item 3 at `move-to-done.sh:300-301` (the `printf` into CANDIDATE_FILE runs inside a `|| die` loop where `set -e` is ignored, so a failed write goes unnoticed). Behaviour fix: fresh launch. T5 has used four fix rounds; the cap is five.
- Rework 2: T4 (F6) and T5 (F5) mini-reviews pass; TGT-007 measured by T5 at 14.49 s and 15.81 s best of 3 (threshold 30 s; load-sensitive, 33.86 s once at load average 23). T5 out-of-scope note (an empty die reason when `xargs` fails without stderr, `move-to-done.sh:314-322`): low, dismissed: the run still stops with exit 2 and rolls back; only the message is lost, on a path `xargs` is not seen to take.
