---
status: done
baseline_revision: "317fdd0f82a86dd95ef360fd59d5ea9dbc8f5575"
spec_branch: spec/00017-handoffs-from-session-worktrees
impl_base_revision: "317fdd0f82a86dd95ef360fd59d5ea9dbc8f5575"
light_path: true
followup_review_recommended: false
deferred: [.workflow/deferred/browser-suite.md]
tracker_issue: ""
budget: {max_tasks: 10, max_changed_files: 30}
---

# Handoffs found from session worktrees

## Why

Claude Code desktop starts every session in its own session worktree under `.claude/worktrees/<name>`, not in the main checkout. The session-start hook lists the session handoffs saved in spec worktrees only when the session runs in the main checkout, so a session started in a session worktree is never offered the handoff for the spec it should resume, and a handoff written in a session worktree is lost to the next session. Make a session handoff reachable from wherever the host starts the next session, so picking work back up never depends on which checkout the session opened in.

## Capabilities

- **CAP-015** Per-run session handoffs (changed)
  - **intent:** A session in any checkout that is not a spec worktree is offered its own handoffs and every other worktree's (main, spec worktrees, other session worktrees); a spec worktree is offered its own and the main checkout's; resuming a handoff first moves the session into the checkout the handoff sits in.
  - **success:** The session-start hook run from a session worktree lists a spec worktree's handoff and a sibling session worktree's handoff by absolute path; run from a spec worktree it still lists no sibling spec worktree's handoff; the handoff skill's Resume names the move as its first step.

## Constraints

- The handoff skill stays self-contained: its Locate block calls no script (spec 00016).
- At most 3 handoffs are listed in the offer, newest first within each group, under the existing character cap.

## Non-goals

- Cleaning up the existing worktrees in Commonplace or any other target project.
- Moving spec worktrees an older scaffold nested inside a session worktree.
- The shelved main-checkout-resolver refactor (`.workflow/deferred/main-checkout-resolver.md`).

## Success signal

Starting a session in a fresh Claude Code session worktree of a project with a spec in flight offers that spec's handoff, and choosing it moves the session into the spec worktree before any work runs.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
- Not verified live (review pass 1 gaps): a real Claude Code desktop session in a session worktree, and whether its EnterWorktree tool switches from a session worktree into a spec worktree under `.workflow/.spec-worktrees/`. Design-log entry "Triage, review pass 1".
