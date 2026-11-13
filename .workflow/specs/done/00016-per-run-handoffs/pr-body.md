## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- The `handoff` skill writes each session handoff as a new file, `<NNN-slug or topic>--<UTC time>-<4 chars>.md`, in `.workflow/.handoff/` of the checkout the session works in. It no longer writes into the main checkout from a worktree and never replaces another handoff.
- The skill writes a `.gitignore` holding `*` into that folder, so handoffs stay out of git even where the install.sh ignore block is missing.
- A handoff named by path in a session's first message is resumed without asking. The session that resumed it deletes it once it has written its own handoff or finished the work.
- The session-start offer lists the session's own checkout's handoffs first as `.workflow/.handoff/<name>`, then the other checkouts' by absolute path: every spec worktree's from the main checkout, the main checkout's from any other checkout.
- New suite `tests/scripts/handoff-skill.sh` runs the skill's Locate block as written; `tests/hooks/audit-sync-resume.sh` covers the per-checkout offer.

## Why the change

- A session in a spec worktree had to write its handoff into the main checkout, outside the checkout it works in. That breaks the rule against writing files to main and stops an unattended run.
- Handoff files were named by spec or topic, so two agents working at once overwrote each other's handoff.
- The offer did not say which checkout a handoff belonged to, so a fresh session could not tell its own from another run's.
- Capability CAP-015: a session writes its session handoff into its own checkout under a name no other run uses, and a fresh session resumes from the one handoff it is given.

## Why this approach

- Placement: each part stays in the module that owns it today. The handoff skill owns where and how a handoff is written and resumed, the hooks module owns the offer, and the path constant and the install.sh ignore block are unchanged. The skill keeps its commands inline because its module may depend on no other.
- Ruled out: keeping the main-checkout folder and exempting it from the rule (a write still leaves the session's checkout), and one replaced file per spec or topic (two agents on the same work collide).
- Impact: handoff location and file name are refactored; the folder's own ignore file is created; Resume and the offer's handoff list are extended; the handoff's frontmatter and body are unchanged, so old-name handoffs are still listed and resumed.

## Special things to note

- Report: [report.md](.workflow/specs/done/00016-per-run-handoffs/report.md). Task PRs: none; `gh` is not installed, so T1 and T2 were merged locally.
- The browser gate was skipped: this repo has no browser suite ([.workflow/deferred/browser-suite.md](.workflow/deferred/browser-suite.md)).
- Not checked in a live session: that a session started inside a spec worktree gets that worktree's path as its `cwd`, which the offer relies on. The suite proves the order only against a built fixture.
- None of the three targets could be measured by a command; the offer's size cap and exit code are asserted by the suite.
- The automatic hand off, reset and reload loop is not built; this change only makes it possible.

## How to test

1. Run `tests/run-all.sh --suite scripts/handoff-skill --suite hooks/audit-sync-resume`. Expected: both suites pass, 12 and 66 checks.
2. In a spec worktree, set `stem=demo`, run the bash block under "1. Locate" of `.agents/skills/handoff/SKILL.md`, then `echo "$file"`. Expected: a path under that worktree's `.workflow/.handoff/` named `demo--<UTC time>-<4 chars>.md`, a `.gitignore` holding `*` beside it, and nothing new in the main checkout.
3. Create that file with handoff frontmatter and start a fresh session in the same folder. Expected: the offer lists it first as `.workflow/.handoff/<name>`.
4. Run `tests/run-all.sh`. Expected: `TOTAL passed=4700 failed=0`.

## Blast radius

- Reviewed files: `.agents/skills/handoff/SKILL.md`, `.agents/skills/handoff/assets/handoff.md`, `.agents/hooks/session-start-resume.sh`, `.agents/hooks/claude-settings.template.md`, `upstream-lineage.json`, `.workflow/deferred/browser-suite.md`.
- Reaches: every session that writes or resumes a session handoff, and every session start on Claude Code and Codex, through the offer text.
- Untouched: `.agents/lib/`, the write guards, `install.sh` and its ignore block, the handoff's frontmatter and body, and the spec part of the offer.

## Risk and reversibility

Risk: Low - the offer could list a handoff under the wrong checkout in a layout the fixture does not build; the hook still exits 0 and the handoff can be named by path.
Reversibility: Easy - revert the merge; handoffs already written under the new names stay readable as plain files.

## Areas, concepts and seams changed

- Interfaces whose shape changed: the handoff file name and folder (now per run, per checkout); the offer's handoff entry line (own checkout by repo-relative path, other checkouts by absolute path) and its section header.
- Modules: `standalone-skills` (the handoff skill), `hooks` (the session-start offer), `tests`.
- Glossary: **Session handoff** added.
- Unchanged seams: `WF_HANDOFF`, `wf_main_root`, `wf_project_root`, the SessionStart hook's input and output shape.

## How to undo this PR

Revert the merge commit on the main branch. No data or settings need restoring: handoffs are local, uncommitted files, and the folder's `.gitignore` can stay or be deleted.
