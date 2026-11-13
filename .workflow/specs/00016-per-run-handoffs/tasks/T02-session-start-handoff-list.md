# T02: Session-start offer lists session handoffs per checkout

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A fresh session sees the session handoffs of the checkout it started in first, each with a path it can open from where it is, then those of the other checkouts it may continue, so it can tell its own handoff from another run's.

**Seam:** The SessionStart hook's input and output: `.agents/hooks/session-start-resume.sh` given a payload `cwd`, returning `hookSpecificOutput.additionalContext`; driven by `tests/hooks/audit-sync-resume.sh`.

**Acceptance criteria:**

- [ ] The session's own checkout is the top level of the checkout its `cwd` is in (a spec worktree, an isolation worktree, or the main checkout). Its handoffs are listed first, as `- .workflow/.handoff/<name>`.
- [ ] A session in the main checkout then lists the handoffs of each spec worktree (found through `git worktree list` on `spec/*` branches). A session in any other checkout then lists the main checkout's, and no other worktree's. Each of these entries is `- <absolute path of the file>`.
- [ ] A handoff is the session's own when its path is under `<own checkout>/.workflow/.handoff/`, not merely under the own checkout's path (spec worktrees sit inside the main checkout). No checkout is scanned twice.
- [ ] Within each group, newest first by mtime. At most 3 entries in total, then `- ... and N older not listed.`; each entry is cut at 300 characters; `additionalContext` stays under 10,000 characters.
- [ ] Old-name files (`<NNN-slug | topic>.md`) and new-name files are both listed; `.gitignore` never is. Unreadable frontmatter is still flagged.
- [ ] Handoffs in any scanned checkout are enough to produce the offer; with none, and no specs, the hook prints nothing. The hook exits 0 for every input. "Do not resume unasked." stays in both endings.
- [ ] The section header and the hook's header comment describe the per-checkout scan; the SessionStart row of `.agents/hooks/claude-settings.template.md` mentions session handoffs.
- [ ] `tests/run-all.sh --suite hooks/audit-sync-resume` passes (JRN-004, JRN-005 and the updated isolation-worktree check).

**Predicted files:** `.agents/hooks/session-start-resume.sh`, `.agents/hooks/claude-settings.template.md`

**Phase 1 tests:** `tests/hooks/audit-sync-resume.sh`

**Size:** S (2 files, about 50 changed lines).

**Mode:** afk.

**Notes:** No shared-core change: `WF_HANDOFF`, `wf_main_root` and `wf_project_root` are used as they are. Under `set -euo pipefail` guard new globs and command substitutions as the hook already does. Decisions: design-log D5, D8 and the Assumed entry on which checkouts an offer covers. Module findings: codebase-map.md § Module audit (hooks).
