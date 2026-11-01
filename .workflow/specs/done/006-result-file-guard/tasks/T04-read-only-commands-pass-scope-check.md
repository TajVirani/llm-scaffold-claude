# T04: Read-only commands pass the worktree scope check

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Hooks build agent worktree names from the shared lib; T04 owns `tests/hooks/worktree-guard.sh`, which also holds T1's cases) · Parallel with: None

**What to build:** A confined agent can run a read-only command from the main checkout without the leading `cd <worktree> &&`. The command rule of `check-worktree-scope.sh` gains an allowlist.
- **Allowed:** a command made only of the allowlisted reads, joined by `|` or `&&`. The reads are `cat`, `head`, `tail`, `grep`, `rg`, `ls`, `wc`, `sed -n`, `find`, `git log`/`show`/`diff`/`status`, `yq` and `jq`.
- **Denied without the leading `cd`:** any segment that uses a writing or exec flag:
  - `sed` `w`/`W`/`-i`;
  - `find` `-delete`/`-exec`/`-execdir`/`-ok`/`-okdir`/`-fprint*`/`-fls`;
  - `yq`/`jq` `-i`;
  - `git --output`;
  - `rg --pre`.
- **Also denied without the leading `cd`:** a command containing `$`, a backtick, `<`, `>`, `;`, a lone `&`, `||`, a newline or `tee`.
- Every other command still needs the leading `cd`, and deny messages keep the hint.

**Seam:** `check-worktree-scope.sh --command`, driven through a confined PreToolUse Bash payload with the cwd in the main checkout (`tests/hooks/worktree-guard.sh` JRN-009). The rest of that suite is a regression check.

**Acceptance criteria:**

- [ ] Each allowlisted read is allowed, and so are `|` and `&&` chains of them, e.g. `cat f | head`, `grep x f && wc -l f`.
- [ ] Each per-tool writing or exec flag and each shell form listed above is denied with the `cd <worktree> &&` hint.
- [ ] Every existing allow and deny case in `tests/hooks/worktree-guard.sh` keeps its verdict. The path rule, exit codes 0/2/1 and the CLI are unchanged.
- [ ] The check stays bash 3.2-safe: regex in a variable with `BASH_REMATCH`, no `declare -A`, no `mapfile`. The `# File:` header documents the allowlist and the denylists.
- [ ] Target guard-time: real time ≤ 0.2 s, best of 3, on the long read chain in `verification-plan.md`.
- [ ] `tests/hooks/worktree-guard.sh` passes in full (with T1 merged) and shellcheck is clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`

**Phase 1 tests:** `tests/hooks/worktree-guard.sh`

**Size:** S (1 file, about 120 changed lines).

**Mode:** afk.

**Notes:** This is accident prevention, not a shell parser. Put the allowlist between the cwd check and `deny_cmd` (codebase-map, feature-workflow audit). The T1 → T04 edge exists for test ownership: run-all selects whole suite files.
