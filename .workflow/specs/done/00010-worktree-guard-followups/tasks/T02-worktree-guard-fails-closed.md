# T02: Worktree guard fails closed

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Scope check fails closed and passes quoted reads) · Parallel with: None

**What to build:** `worktree-write-guard.sh` denies instead of allowing when it cannot confine an implementation or integration sub-agent. With the workflow installed, a missing jq gives a static, hand-written deny JSON naming jq, and a payload that is not a JSON object gives a deny JSON (main-session calls included, since the hook cannot tell them apart). For an implementation or integration sub-agent it always calls `check-worktree-scope.sh` with `--confined`, so a missing transcript, an empty first message, an unparsable or missing launch header, or a missing named worktree ends in the scope check's deny with its cause; the hook adds the cause it knows (transcript not found, header not parsed) to the reason. The header comment's Behaviour section describes the new rules, the `# File:` line says "agent worktree", and the stale "a spec folder number under three digits" example goes (any digit count is valid).

**Seam:** the `worktree-write-guard.sh` PreToolUse contract: payload JSON on stdin, nothing or one deny JSON on stdout, exit 0. Tests feed payloads built with `pl`/`mk_sub` in the suite's fixture repo, and run the hook with a PATH without jq.

**Acceptance criteria:**

- [ ] Implementation payloads from the main checkout whose worktree `s007_t9` is missing, whose transcript is missing, whose first message has no launch header or an unparsable one, and an integration payload whose worktree is missing are denied for a Write to the main checkout, a Write to a temp dir, `cat f` and `ls -la > x`, each reason naming its cause (JRN-001).
- [ ] An implementation payload whose cwd is outside any git repo is denied.
- [ ] An isolation agent (no named worktree, cwd in a linked worktree) may write inside its worktree and is denied outside it (JRN-002).
- [ ] `not json` and `[1,2]` payloads get a deny JSON with exit 0; with no jq on PATH the hook prints a static deny JSON naming jq (JRN-003).
- [ ] Main-session calls and other agent types are still allowed silently; the Codex cases still pass.
- [ ] `tests/hooks/worktree-guard.sh` passes in full.

**Predicted files:** `.agents/hooks/worktree-write-guard.sh`

**Phase 1 tests:** `tests/hooks/worktree-guard.sh`

**Size:** S (1 file, about 60 changed lines).

**Mode:** afk.

**Notes:** The no-jq deny must not need jq (a fixed `printf` line, as `_guard-common.sh` does). Keep the silent allow when `check-worktree-scope.sh` is not next to the hooks (workflow not installed).
