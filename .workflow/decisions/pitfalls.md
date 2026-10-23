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

## Fork a Phase 1 build's worktree from the spec branch
- What happened: the 1.2 harness agent's `isolation: "worktree"` worktree started at `main`, without the spec folder; the agent fast-forwarded it to the spec branch, and the worktree guard then refused its result-file write to the main checkout, so the orchestrator copied the file in by hand.
- Where: verification-setup 1.2 launch (`modules/verification-setup.md`)
- Spec: .workflow/specs/003-bash-cache-extractor
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
- Prevented by: none yet

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
