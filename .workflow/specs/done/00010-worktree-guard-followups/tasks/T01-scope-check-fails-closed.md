# T01: Scope check fails closed and passes quoted reads

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `check-worktree-scope.sh` gains a `--confined` flag: when it is set and no confinement root can be found (no worktree name given, the named agent worktree under `.workflow/.worktrees/` does not exist, and the cwd is not in a linked worktree, or the cwd is outside any git repo), every path and command is denied with exit 2, before any other allow (outside-checkout writes and read-only commands included), with a `worktree guard:` reason on stderr that names the cause. Without `--confined` the no-root behaviour stays an allow, so the Codex guard is unchanged. The read-only chain check becomes quote-aware: scanning left to right, a `$` or backtick inside single quotes passes, while a `$`, a backtick or a backslash outside single quotes (inside double quotes too) denies, and an unterminated quote denies; `|`, `&&` and `;` splitting stays quote-blind. Every message and the `# File:` header say "agent worktree" instead of "task worktree" (and "other agents' worktrees" for "other tasks' worktrees"), the `--worktree-name` usage text lists `s<NNN>_t<N>`, `s<NNN>_phase_1_<work type>`, `s<NNN>_integration_<work type>` and a Codex `task_name`, and the header's root rule 3, the sed `$`-address note and the "regex check" note describe the new behaviour. `modules/implementation-orchestrator.md` gains one sentence, where it describes the worktree guard, saying a confined agent whose agent worktree is missing is denied every call, so the orchestrator recreates the worktree before relaunching.

**Seam:** the `check-worktree-scope.sh` CLI: `--cwd D [--worktree-name N] [--confined] (--path P... | --command C)`, exit 0 allow (reason on stdout), 2 deny (reason on stderr), 1 usage or environment error. Tests drive it directly and through `worktree-write-guard.sh` payloads in a fixture repo with real agent worktrees and a linked worktree.

**Acceptance criteria:**

- [ ] `--confined` with a named worktree that does not exist, with no `--worktree-name`, and with a cwd outside any git repo each exit 2 with a reason naming the cause; a write to a temp dir and a read-only `cat f` are denied too.
- [ ] `--confined` with the cwd in a linked worktree confines to it (exit 0 inside); without `--confined` the no-root case still exits 0.
- [ ] From the main checkout with a root, `sed -n '$p' f`, `sed -n -e '1p' -e '$p' f`, `grep 'x$' f` and ``grep '`' f`` are allowed; `grep "x$" f`, `cat $HOME/f`, `grep \$ f`, ``grep `id` f``, `grep 'a'\''$' f` and `grep 'x$ f` are denied with the `cd` instruction.
- [ ] No message, `# File:` line or `--help` text contains "task worktree"; deny reasons say "agent worktree"; `--help` names the Phase 1 and integration shapes.
- [ ] `implementation-orchestrator.md` has one sentence that says a confined agent whose agent worktree is missing is denied (JRN-005 doc check).
- [ ] The guard-time target in `verification-plan.md` holds (≤ 0.5 s best of 3).
- [ ] The JRN-004, JRN-005 (scope-check and doc parts) and JRN-006 checks in `tests/hooks/worktree-guard.sh` pass; its remaining JRN-001 and JRN-003 checks belong to T2.

**Predicted files:** `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`, `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`

**Phase 1 tests:** None. `tests/hooks/worktree-guard.sh` also holds T2's checks, so T2 owns the suite; run it yourself and report which of its checks your change turns green.

**Size:** M (2 files, about 200 changed lines).

**Mode:** afk.

**Notes:** Keep the scanner bash 3.2 and make every loop consume input on each pass; run it after the cheap whole-command denials (newline, `<`, `>`). The `cd` target check keeps its own `$`, backtick and `~` denial. `modules/implementation-orchestrator.md` only: spec 007 is editing `SKILL.md`, `modules/discovery.md` and `modules/large-path.md` in parallel, so leave those alone.
