---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "3.4"
discovered_at: 2026-10-29
status: open
kind: decision
---

# Quoted dollar signs in read-only commands

## Problem

The worktree scope check denies any read-only chain that contains `$`, so a quoted `$` in a read is refused without the leading `cd`. The sed print-only allowlist accepts a `$` (last-line) address, yet no command using one can pass. `sed -n '$p' f` and `grep 'x$' f` from the main checkout both need the `cd`.

## Evidence

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` `read_only_chain` (`case "$chain" in *'$'*...`) at T4 head `d612b9d`.
- Probe from T4's result (`.workflow/specs/006-result-file-guard/artifacts/T4/implementation.yaml` `discovered_work[0]`): `check-worktree-scope.sh --command "sed -n -e '1p' -e '\$p' f"` from the main checkout exits 2.

## Why not a blocker

CAP-NEW-worktree-read-commands lists `$` among the shell forms to deny, so the check meets its success line as written. Such reads still work with the leading `cd`.

## Suggested scope and size

- Scope: decide whether a `$` inside single quotes may pass. If yes, add a quote-aware check (a `$` only inside single quotes, and any backslash outside single quotes denied so a quote cannot be faked), with allow and deny cases in `tests/hooks/worktree-guard.sh`.
- Size: 1 task in feature-workflow, 2 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: quoted-dollar-reads)
