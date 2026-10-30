<!--
File: Template for .workflow/decisions/pitfalls.md (Tier A). Copied by project-setup; written at 5.7 by the retrospective skill, with approval.
Rules:
  - Admit a pitfall only when something actually went wrong. A suspicion or a trap-looking fact is not an entry.
  - Remove an entry only when the thing it is about is gone, or a tool now enforces it. Never remove it because it has not recurred.
  - Each entry is a terse imperative that names the permitted alternative, plus the four fields below.
Entry shape (newest first):

## {Short imperative title}
- What happened: {the observed failure}
- Where: {file or area}
- Spec: {.workflow/specs/NNN-slug}
- Prevented by: {the rule or check that now prevents it, or "none yet"}
-->
# Pitfalls

## Quote every YAML string that contains `: ` in a result file
- What happened: a profile-mini-review result file held an unquoted string with `: ` inside, so `check-task-result.sh` could not parse it (go-yaml "mapping values are not allowed in this context") and the reviewer had to be resumed to rewrite it
- Where: `.workflow/specs/00010-worktree-guard-followups/artifacts/T1/mini-review.yaml` (3.7)
- Spec: .workflow/specs/00010-worktree-guard-followups
- Prevented by: `check-task-result.sh` refuses the file (exit 2) and the orchestrator resumes the agent once; the launch brief now asks to quote such strings

## Name no `.workflow/` path in an installed asset
- What happened: the shipped `assets/pr-template.md` issue stub named `.workflow/deferred/spec-issue-creation.md`, a file only this scaffold repo holds, so every target project's Sign-off PR would cite a dead path (F1, medium, a rework); the T6 fix round then failed mini-review R4 for naming `.workflow/deferred/` in the same template's guidance.
- Where: `.agents/skills/*/assets/` (installed into target projects)
- Spec: .workflow/specs/008-pr-description-template
- Prevented by: none yet (the shelved lint `.workflow/deferred/comment-id-lint.md`, widened at T6 to asset-template guidance comments)

## Grep the modules for the old behaviour when a loop-back decision changes a script
- What happened: D19 (from the 4.5 loop-back) made `check-pr-body.sh` project mode read every heading level, but `modules/sign-off.md` 5.4 still said a host template had only `##` headings and that exit 2 meant "no `##` headings"; both review lenses flagged it (F7, F8, medium), costing rework 1.
- Where: `modules/sign-off.md` 5.4; the 0.5 re-entry and 2.5 task briefs after a loop-back
- Spec: .workflow/specs/008-pr-description-template
- Prevented by: none yet

## Fill a brief's path placeholders with what the launch really gives the agent
- What happened: `tests/hooks/worktree-guard.sh` filled every `worktree`, `checkout` and `launched` placeholder in the result-file command it extracts from the agent docs with the agent worktree. So the integration and Phase 1 briefs passed while their "checkout you were launched in" meant the main checkout under the no-isolation launch; review pass 1 caught it (F1, high).
- Where: `tests/hooks/worktree-guard.sh` placeholder filler; command templates in `.agents/agents/*.md`
- Spec: .workflow/specs/006-result-file-guard
- Prevented by: the guard suite fills a `launched` placeholder with the main checkout and checks the filled command starts with `cd <agent worktree> &&`

## Flip a Phase 1 placeholder's PROVENANCE row when the task that implements it lands
- What happened: Phase 1 added `lib/test-paths.sh` as a stub with a `placeholder` PROVENANCE row; T1 and T2 made it real and sourced it, no task brief named the row, and both review-standards and review-end-state flagged it (F2, medium), costing a rework.
- Where: `PROVENANCE.md`; task briefs at 2.5 for tasks that replace a Phase 1 stub
- Spec: .workflow/specs/005-cache-build-followups
- Prevented by: none yet

## Write a mini-review re-check to the plain mini-review.yaml
- What happened: at 3.7 the T9 re-check reviewer wrote `artifacts/T9/mini-review-r2.yaml` instead of `mini-review.yaml`, so the newest round was not under the plain name sign-off and the retrospective read; the orchestrator renamed it. The same reviewer reported the `tree` in `toolchain.json` as stale by comparing it with the git tree id, though `tree` is run-toolchain's own content hash (a `--reuse` run matched it).
- Where: `.agents/agents/profile-mini-review.md` (Re-check rule); `.workflow/specs/003-bash-cache-extractor/artifacts/T9/`
- Spec: .workflow/specs/003-bash-cache-extractor
- Prevented by: none yet (action item in the 003 retrospective); the orchestrator names the plain file in the re-check brief

## Fork a Phase 1 build's worktree from the spec branch
- What happened: the 1.2 harness agent's `isolation: "worktree"` worktree started at `main`, without the spec folder; the agent fast-forwarded it to the spec branch, and the worktree guard then refused its result-file write to the main checkout, so the orchestrator copied the file in by hand.
- Where: verification-setup 1.2 launch (`modules/verification-setup.md`)
- Spec: .workflow/specs/003-bash-cache-extractor; recurred in .workflow/specs/008-pr-description-template (the 1.2 result files stayed in the `isolation: "worktree"` worktree twice, and a stray `.claude/worktrees/` copy outlived Phase 4; the third 1.2 run, in a worktree under `.workflow/.worktrees/`, wrote its result file in place)
- Prevented by: none yet (needs `worktree.baseRef: head` in `.claude/settings.json`, or a wave-start-style worktree for Phase 1 builds)

## Never pipe a gate checker into head inside a && chain
- What happened: at 3.16 `check-task-result.sh ... | head -1 && git merge ...` merged T3 although the checker exited 1, because the pipeline returned head's exit status; the reviewer then rewrote the file and it passed.
- Where: implementation-orchestrator 3.16 merge (`modules/implementation-orchestrator.md`)
- Spec: .workflow/specs/003-bash-cache-extractor
- Prevented by: none yet

## Report a detected call as unresolved; never filter it out
- What happened: the bash graph extractor dropped script calls it had already detected (extensionless targets, cwd-relative paths, `bash --norc x`, `$(...)` calls, `bash -o pipefail x`) through filters and option scans, found by one review finding and three fix rounds.
- Where: `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`
- Spec: .workflow/specs/003-bash-cache-extractor
- Prevented by: the call-form cases in `tests/scripts/extractor-bash.sh`

## Assign capability ids in the same step as re-reading capabilities.md
- What happened: at 5.3 the orchestrator assigned CAP-001 and CAP-002 to this spec's capabilities while CAP-001 already belonged to spec 004; the unguarded files were corrected by sed and `tasks.md` with `yq --front-matter=process -i`, because `set-task` rewrites only a provisional id.
- Where: sign-off 5.3, capability assignment (`modules/sign-off.md`)
- Spec: .workflow/specs/002-review-lessons
- Prevented by: none yet (the module says to re-read `capabilities.md` immediately before each assignment; the read and the assignment were batched)

## Keep a work type's lint key free of suites another task's Phase 1 pin can turn red
- What happened: an agent-docs task in the same wave as a step-list change could not pass its toolchain: the agent-docs `lint` key ran `lint/step-list` unscoped while that suite carried the sibling task's red Phase 1 pin, and the `&&` chain hid the later lint suites (T3, `profile-wrong` at 3.3).
- Where: `.workflow/profiles/agent-docs.md` § Toolchain, `lint`
- Spec: .workflow/specs/002-review-lessons
- Prevented by: the agent-docs `lint` key no longer runs `lint/step-list`; the scoped `test` key covers it (P3, 2026-10-22)

## Never overlap a 3.9 gate with an agent's full-harness run
- What happened: a 3.9 gate ran while an agent's toolchain was running the whole harness; the runner's wall-clock concurrency assertion failed on load and turned a green gate red (`gate-3.9-w1b`).
- Where: `tests/scripts/run-all-selection.sh` ("with no -j, suites run concurrently"); orchestrator gate timing
- Spec: .workflow/specs/002-review-lessons
- Prevented by: none yet for the assertion (shelved as `.workflow/deferred/concurrency-check-timing.md`); the orchestrator runs one harness at a time

## Match a review lesson on the mistake its symptom names, not its consequence clause
- What happened: the cheap-tier review-lessons lens read a lesson's "..., so <consequence>" clause as a matching condition and dropped a plain repeat of the mistake to confidence 60, reporting nothing (JRN-001 live run 2).
- Where: `.agents/agents/review-lessons.md` § Method and Scoring
- Spec: .workflow/specs/002-review-lessons
- Prevented by: the lens definition matches on the mistake and treats the consequence as context (T3 fix, 2026-10-22)

## Check the deferred shelf by concept before writing a backlog item
- What happened: two discovered-work backlog items were written at 00.26 without a shelf check and both duplicated shelved items (`002-review-lessons-disc-001` with `research-model-map.md`, `-002` with `concurrency-check-timing.md`); the review-lessons lens caught it from retrospective 004's lesson.
- Where: `.agents/skills/feature-workflow/modules/discovered-work.md` 00.26; `.workflow/specs/work-backlog/`
- Spec: .workflow/specs/002-review-lessons
- Prevented by: none yet; a shelf check at 00.26 is a candidate next feature

## Edit frontmatter with Edit or `yq --front-matter=process`, never `--front-matter=extract -i`
- What happened: `yq --front-matter=extract -i` rewrote two work-backlog items as their frontmatter alone, deleting the body; one was restored from git, the other from the session.
- Where: main-session status edits of `.workflow/specs/work-backlog/*.md` (00.26, 5.9)
- Spec: .workflow/specs/004-scoped-test-runs
- Prevented by: partly: four `permissions.deny` rules in the settings template and `.claude/settings.json` refuse `yq --front-matter=extract` with `-i` or `--inplace` (spec 00010, confirmed live); other spellings such as `-Pi` stay open (`.workflow/deferred/frontmatter-extract-write-guard.md`)

## Quote heredocs that write markdown (`<<'EOF'`), or use Write
- What happened: an unquoted `<<EOF` holding markdown ran its backticked code spans as shell commands and hung the shell, leaving an empty `.workflow/deferred/` file.
- Where: main-session Bash writes of `.workflow/` markdown (3.14)
- Spec: .workflow/specs/004-scoped-test-runs
- Prevented by: none yet

## Point at a folder instead of restating its tree in the README
- What happened: the README's hooks and helper-script lists drifted from the tree; `worktree-write-guard.sh` and five helper scripts are missing.
- Where: `README.md` (hooks and helper lists)
- Spec: none (found by project-standards discovery, 2026-10-21)
- Prevented by: `.workflow/rules.md` § Cross-cutting policy (the README never restates the tree)
