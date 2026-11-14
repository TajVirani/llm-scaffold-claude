# T01: Offer every worktree's handoffs outside a spec worktree

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A session started in any checkout that is not a spec worktree (the main checkout, or a session worktree such as Claude Code desktop's `.claude/worktrees/<name>`) is offered its own handoffs first, then the handoffs of every other registered worktree by absolute path: main, every spec worktree, other session worktrees. A session in a spec worktree keeps today's view: its own, then the main checkout's. Resuming a handoff whose file sits in another checkout first moves the session into that checkout (EnterWorktree on Claude Code; elsewhere ask the user to reopen the session there), before reading the spec or running anything.

**Seam:** `.agents/hooks/session-start-resume.sh` driven through its stdin payload `{"cwd": ...}` (the `ss` helper in `tests/hooks/audit-sync-resume.sh`), asserting on `additionalContext`; the handoff skill's Resume text, asserted by `tests/scripts/handoff-skill.sh`.

**Acceptance criteria:**

- [ ] From a session worktree (`$P/.claude/worktrees/<name>`, on a non-spec branch), the offer lists a spec worktree's handoff and a sibling session worktree's handoff by absolute path, and the session worktree's own handoff first as `.workflow/.handoff/<name>`.
- [ ] From the main checkout the offer also lists a session worktree's handoff.
- [ ] From a spec worktree the offer still lists no sibling spec worktree's handoff and no session worktree's handoff.
- [ ] The listing keeps the cap of 3 and newest-first order within each group.
- [ ] The hook's header comment and the inline comment at the own/other rule state the new rule.
- [ ] `.agents/skills/handoff/SKILL.md` Resume has a first step that moves the session into the checkout the handoff file sits in when that is not the session's own; its Write section names session worktrees among the checkouts a handoff can be written in.
- [ ] `tests/run-all.sh` passes; `tests/README.md` rows for the touched suites name the new cases.

**Predicted files:** `.agents/hooks/session-start-resume.sh`, `.agents/skills/handoff/SKILL.md`, `tests/hooks/audit-sync-resume.sh`, `tests/scripts/handoff-skill.sh`, `tests/README.md`

**Phase 1 tests:** None.

**Size:** S (5 files, about 90 changed lines)

**Mode:** afk.

**Notes:** None. No shared core (`.agents/lib/**`) change: `git worktree list --porcelain` in the hook already gives every registered worktree.
