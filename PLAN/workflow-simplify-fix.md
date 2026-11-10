# Fix plan: less machinery, fewer waits on the stakeholder

> Scaffold-only design doc (D30). Written 2026-11-10 from five audits: the step files against the flow diagram, the hooks and scripts, the review layers, the 14 finished specs in this repo, and the specs and session transcripts of the Athena and Commonplace projects. It records what the audits found, the decisions that fix it (D113–D127, to be copied into `assetlist.md`), the rules the build units share, and the units. The build runs outside `feature-workflow` at the stakeholder's request, as `PLAN/workflow-speed-fix.md` did, on branch `fix/workflow-simplify`.

## What the audits found

The core design holds: findings need proof, state lives on disk, and the end-state and standards lenses catch real defects after every task has passed its mini-review. The cost sits in four places.

1. **Waiting on the stakeholder.** Athena: 215 of 893 active minutes over 51 questions. Commonplace: 159 of 535 over 44. Ten more waits ran past 30 minutes because a question stopped all work while the stakeholder was away.
2. **Machinery nobody uses.**
   - Tier B caches: about 3,900 lines with tests. This repo's caches are 297 commits behind HEAD and spec 00014 recorded them as wrong. Commonplace has none.
   - The small path: 10 notes across the step files, never taken in Athena or Commonplace.
   - Model precedence: two of three levels are empty in all three projects.
   - Old-format branches: per-item backlog files, specs from before the Done folder, `branch: null` tasks, specs with no `blocked_from`, cache bodies from before "Unresolved edges", the old `Task` tool name.
3. **Checks that rarely find anything.**
   - Review-lessons lens: no unique defect in 8 specs here; 0 findings in Athena and in every Commonplace cycle.
   - Library evaluation: ran in 13 of 14 specs, adopted nothing.
   - Readable-code wording lines R1–R5 in the mini-review: 13 of 27 failed items; most repeat launches were comment wording.
   - `pr-quality` repeats four dimensions the review phase already ran (doc conformance, seam conformance, duplicates, commit hygiene).
4. **Friction and gaps in the guards.**
   - Implementation agents hit `worktree-write-guard.sh` 56 times in the two projects, mostly writing their own result file under the spec's `artifacts/`, where the workflow told them to write it.
   - `block-destructive-git.sh` lets a command through when `jq` is missing or the payload is malformed (lines 40–42).
   - A `research` launch is refused: `.workflow/model-map/` has no `research.md`.
   - A profile whose toolchain keys still read `TODO:` fails at 3.5, but profiles are editable only at 5.3. `run-toolchain.sh` runs the `TODO:` text as a command.
   - Three write hooks each start bash, `jq` and `check-write.sh` on every Write or Edit.
   - "Newest `.step`" is judged by file time, so tests need `sleep 1`.
5. **Design records have drifted.** `PLAN/decision-flow.mermaid` and `PLAN/decision-flow-reference.md` are about 30 step-file commits behind: they name a deleted small-path module, the old backlog format, a 4.8 that writes deferred handoffs (it writes nothing), a 5.8 with no Done folder, tracker or PR body, and a spec branch created only at 1.1. `assetlist.md` and `checklist.md` still name `implementation-orchestrator.md`. Only step ids are linted.

## Decisions

Waiting on the stakeholder:

- **D113. One sign-off ask.** 5.3 (proposals), 5.5 (approve the work), 5.9 (backlog rulings) and the retrospective's lesson agreement (5.7) are asked in one call. The retrospective drafts its lessons before the call; the stakeholder approves or names exceptions there. This is what the small path already does.
- **D114. No publish go-ahead at 5.8.** 5.5 approved the PR body. 5.8 publishes without a second ask.
- **D115. Only blocking questions block.** A question blocks when its answer changes scope or intent, or the action is hard to reverse. Any other question (a term gate with a clear recommended term, a shelf match, a "continue into the next phase?" check, a suite-gap note) takes the recommended answer at once, is logged in `design-log.md` as `assumed`, and is listed for veto in the next blocking ask. The rule lives in `references/conventions.md`; step files point to it.
- **D116. Launch before asking.** Before any blocking ask, the orchestrator launches every sub-agent whose input does not depend on the answer, so the wait is never idle.

Removals:

- **D117. Tier B caches are removed.** The `regenerate-caches` skill, the `cache-regeneration` agent, the graph extractors, `tier-b-write-guard.sh`, the cache deny rule, steps 0.2.7 and 0.2.8, `.workflow/cache/` and their tests go. The retrieval agent reads code and Tier A directly. `pr-quality`'s seam check reads `rules.md` ownership and the code.
- **D118. The lessons lens folds into the standards lens.** `review-standards` also checks `.workflow/review-lessons.md`, pitfalls and retrospective process lessons. `review-lessons` and step 4.9 go. The full path launches three lenses.
- **D119. Library evaluation is conditional.** 0.2.5 launches only when the request names a new library, SDK or external API, or the affected concern has no approved library in the work profile.
- **D120. The mini-review keeps the readable-code lines, and a breach never costs a launch.** (Revised 2026-11-10: the first version took R1–R5 out of the mini-review. That left names and restating comments to the implementer's own self-review until Phase 4, and the stakeholder's standing problem is exactly those two.) The mini-review judges R1–R5 on every task, as the one independent reader before the merge. What changes is the cost of a breach:
  - The reviewer lists every readable-code breach in the diff in one pass, each with its fix in the note: delete the comment, the replacement comment text, or the new name.
  - The orchestrator applies those fixes itself and reruns the toolchain when a name changed. No implementation relaunch and no re-check launch follow a round whose only failures are readable-code lines.
  - At 4.1 and 4.10 an R1 or R3 breach is always patched, never deferred or dismissed as low.
- **D121. `pr-quality` skips what the review phase settled.** On a spec branch whose spec reached `in-review` or `done`, it skips doc conformance, seam conformance, duplicate detection and commit hygiene, and says so in its report.
- **D122. The small path folds into the light path.** The light path takes the small path's trims as defaults: one questioning round unless a question stays open, a five-line report for a one-task spec, the retrospective inside the sign-off ask (D113). `small_path` and the "On the small path:" notes go. An old spec with `small_path: true` is read as light path.
- **D123. One model table.** `.workflow/model-map.yaml` holds one row per task type (tier, model per host, why). The `models:` key in agent definitions and `.workflow/agent-overrides.yaml` go. A `research` row is added. `install.sh` and `project-setup` seed the one file.
- **D124. Old-format branches are deleted.** The 10 remaining per-item backlog files in this repo are migrated to the per-spec list first. Then the branches listed in finding 2 are removed.

Guards:

- **D125. Guards fail closed, and the result file is writable.** `block-destructive-git.sh` blocks when it cannot read the command. `worktree-write-guard.sh` allows an agent to write its own result file under the spec's `artifacts/` (the path its launch header names) and nothing else outside its worktree. The three write hooks become one hook call. `.step` carries a sequence number; "newest" no longer reads file time and the test sleeps go.
- **D126. A `TODO:` toolchain value stops with a clear message, and the profile can be fixed on the spot.** `run-toolchain.sh` refuses to run a value that starts with `TODO:` and names the profile key. The Tier A guard allows a profile's toolchain keys to be edited at 3.5 when that refusal is the cause.

Records:

- **D127. The flow diagram is regenerated and its labels are linted.** `decision-flow.mermaid` and `decision-flow-reference.md` are brought in step with the step files. The step-list lint derives its per-phase counts from `steps.tsv` instead of hard-coding them, and fails when a file named in the mermaid, the reference, `assetlist.md` or `checklist.md` does not exist.

Not in this fix: the Codex adapters stay (agent-agnostic is the premise; they need a live run, not removal). Step ids keep their numbers even where run order differs; renumbering would break every record that cites them. The shelf (`.workflow/deferred/`) and the work backlog stay two stores.

## Shared rules for every unit

- Work in `/Users/tvirani/Desktop/Projects/llm-scaffold-claude` on branch `fix/workflow-simplify`. Do not switch branches, commit, stash or push. The orchestrating session commits after each wave.
- Other units run at the same time in the same checkout. Each unit owns the files its section lists. Edit a file another unit owns only for the lines its own decision needs, re-read it straight before the edit, and name the edit in the report.
- Follow `.workflow/rules.md` and the profiles: `.workflow/profiles/shell-scripts.md` for shell, `agent-docs.md` for markdown under `.agents/`, `test-harness.md` for `tests/`. Bash 3.2. Use the terms in `.workflow/GLOSSARY.md`; remove a glossary entry when its concept is removed.
- When a concept is removed, remove every mention: step files, agent definitions, `steps.tsv`, `check-write.sh`, hooks, the settings templates, `.agents/install-manifest.txt`, `install.sh`, `README.md`, `AGENTS.md`, `.agents/README.md`, tests. Search with `rg --hidden`. Do not edit `.workflow/specs/done/**`, `.workflow/decisions/**`, `CHANGELOG.md` history or other `PLAN/*.md` files: they are records.
- Update or delete the tests of what you change, and add a test for each new behaviour. Run the suites for your area with `tests/run-all.sh --suite <name>`. A failure in a suite outside your area, caused by another unit's half-done work, is reported, not fixed.
- Write plain sentences in docs. No comments that only narrate the change.
- Report: files changed, files deleted, suites run with results, anything left undone and why, and any edit to a file you do not own.

## Units

Wave 1, in parallel:

- **U1. Remove the Tier B caches (D117).** Owns `.agents/skills/regenerate-caches/`, `.agents/agents/cache-regeneration.md`, `.agents/agents/retrieval.md`, `.agents/hooks/tier-b-write-guard.sh`, `.workflow/cache/`, the cache suites under `tests/`, steps 0.2.4–0.2.8 in `modules/discovery.md`, `pr-quality`'s seam-conformance module, and the cache lines in `check-write.sh`, `run-toolchain.sh`, `commit-workflow-data.sh`, `workflow-paths.sh`, the settings templates, `.claude/settings.json` and `install.sh`.
- **U2. Trim the review layers (D118, D120, D121).** Owns `.agents/agents/review-*.md`, `.agents/agents/profile-mini-review.md`, `references/readable-code.md`, `modules/review-triage.md`, `modules/implementation-gates.md`, `scripts/check-review-findings.sh`, `.agents/skills/pr-quality/` except the seam-conformance module, the review-lessons model-map file, and their tests. While merging the lenses, move the text the lens definitions share word for word into one reference file they each point to, if the agent-docs profile allows a pointer there; otherwise leave it.
- **U3. Guards (D125, D126).** Owns `.agents/hooks/` except `tier-b-write-guard.sh` and the settings templates' cache lines, `scripts/run-toolchain.sh` (the `TODO:` refusal only), `scripts/status-transition.sh` and `scripts/step-progress.sh` (the `.step` sequence number only), `.agents/agents/implementation.md` and `integration.md` (result-file path wording only), and their tests. Merging the three write hooks waits for U1 to delete the Tier B hook: do it last, and re-read the templates first.

Wave 2, in parallel, after wave 1 is committed:

- **U4. Fold the small path, one model table, old formats (D119, D122, D123, D124).** Owns `modules/discovery.md`, `discovery-impact.md`, `questioning-loop.md`, `task-breakdown.md`, `implementation-waves.md`, the router `SKILL.md`, `scripts/resolve-launch.sh`, `.workflow/model-map/`, `.workflow/agent-overrides.yaml`, `project-setup`'s model-map seeding, `session-start-resume.sh`, the old-format lines in `check-write.sh` and `status-transition.sh`, `.workflow/specs/work-backlog/` (migration), and their tests.
- **U5. Waiting on the stakeholder (D113–D116).** Owns `modules/sign-off.md`, `.agents/skills/retrospective/`, `references/conventions.md`, `modules/verification-setup.md`, `modules/discovered-work.md`, `modules/implementation-finish.md`, the ask wording in the step files U4 owns (coordinate by re-reading before each edit), `assets/design-log.md`, and their tests. Also removes the small-path notes in `sign-off.md` and the retrospective for U4.

Wave 3, alone, after wave 2 is committed:

- **U6. Records and the full gate (D127).** Owns `PLAN/decision-flow.mermaid`, `PLAN/decision-flow-reference.md`, `assetlist.md` (add D113–D127, fix stale names), `checklist.md`, `references/steps.tsv` consistency, `tests/lint/step-list.sh`, `.workflow/GLOSSARY.md`, `README.md`, `AGENTS.md`, `CHANGELOG.md` (one new entry). Removes rule text that step files repeat from `conventions.md`. Removes the write permission step 4.8 no longer uses. Then runs the shell and agent-docs lint commands from `AGENTS.md` and the whole `tests/run-all.sh`, and fixes what fails.

After wave 3: one independent review of the whole branch diff against this plan, with fixes, then a last full `tests/run-all.sh`.
