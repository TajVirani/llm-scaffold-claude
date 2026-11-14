## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- The session-start hook now offers a session in the main checkout or a session worktree (Claude Code desktop's `.claude/worktrees/<name>`) its own handoffs first, then every other worktree's: the main checkout's, each spec worktree's and other session worktrees'. Before, a session worktree saw only the main checkout's.
- A session in a spec worktree still sees only its own handoffs and the main checkout's.
- The handoff skill's Resume has a new first step: move the session into the checkout the handoff file sits in (EnterWorktree on Claude Code; reopen the session there on other hosts).
- The handoff skill's Write section, the hook wiring doc and the design-log asset now describe the new rule and step numbers.
- "Session worktree" is a new glossary term.

## Why the change

- Claude Code desktop opens every session in a new session worktree, so a new session was never offered the handoff for the spec it should resume. In Commonplace, the 00031 handoff was listed from the main checkout but missing from `.claude/worktrees/quirky-yonath-09ed4f`.
- A handoff written in a session worktree was lost to the next session, which opens in a different worktree.
- CAP-015 (per-run session handoffs) now holds wherever the host starts the session.

## Why this approach

- The rule lives in the session-start hook (`hooks`), the one place that decides which handoffs are offered; no shared-core helper was needed, since `git worktree list --porcelain` already names every worktree.
- The handoff skill keeps writing in its own checkout (spec 00016's self-contained Locate block), rather than writing to the main checkout from a session worktree, so a handoff stays beside that worktree's uncommitted work.
- Spec worktrees keep their narrow view, so parallel specs still never pick up each other's handoffs.

## Special things to note

- Report: [report.md](report.md). Task PR: none (`gh` is not installed; T1 merged locally).
- The browser-suite gate was skipped: this repo has no browser suite ([browser-suite.md](../../../deferred/browser-suite.md)).
- Not verified in a live Claude Code desktop session, and not confirmed that EnterWorktree switches from a session worktree into a spec worktree under `.workflow/.spec-worktrees/`.

## How to test

1. Run `tests/run-all.sh`: expect `TOTAL passed=4885 failed=0`.
2. Run `tests/run-all.sh --suite hooks/audit-sync-resume`: the session-worktree cases list a sibling session worktree's and a spec worktree's handoffs, and the spec-worktree case lists neither.
3. In a target project with a spec worktree holding a handoff, pipe `{"cwd":"<project>/.claude/worktrees/<name>"}` into `.agents/hooks/session-start-resume.sh`: the spec worktree's handoff appears by absolute path.

## Blast radius

- `.agents/hooks/session-start-resume.sh`: the handoff part of the SessionStart offer, on Claude Code and Codex. Specs, initiatives and the backlog listing are untouched.
- `.agents/skills/handoff/SKILL.md`: the Resume step order; every later step moves down by one.
- Docs only: `.agents/hooks/claude-settings.template.md`, `.agents/skills/feature-workflow/assets/design-log.md`.
- Target projects get the change on their next `install.sh` run.

## Risk and reversibility

Risk: Low - a session may now see more handoffs (capped at 3 listed); the live EnterWorktree switch from a session worktree is unconfirmed.
Reversibility: Easy - revert the merge commit and re-run `install.sh` in target projects.

## Areas, concepts and seams changed

- SessionStart output (`additionalContext`): the handoff list's other-checkouts group changed for every checkout that is not a spec worktree.
- Handoff skill Resume steps: new step 1, the rest renumbered.
- Concepts: Session worktree (new), Spec worktree, Session handoff (CAP-015).

## How to undo this PR

Revert the merge commit on `main` (`git revert -m 1 <merge sha>`), then re-run `install.sh` in each target project that was updated.
