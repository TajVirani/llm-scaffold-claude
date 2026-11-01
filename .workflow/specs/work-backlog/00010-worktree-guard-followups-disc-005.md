---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
origin_step: "4.4"
discovered_at: 2026-10-30
status: moved-to-deferred
kind: bug
---

# Quoted write flags pass the read-only check

## Problem

The worktree scope check lets an allowlisted read run from the main checkout without the leading `cd`, and refuses a read whose write flag it spots. It spots `yq`, `find`, `jq`, `git` and `rg` write flags only when the flag follows an unquoted space, so a quoted flag such as `yq '-i' ...` or `find . '-delete'` passes as a read. This is the regex-denylist leak a recorded review lesson warns about; allowlisting each tool's read forms closes it.

## Evidence

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` `read_only_segment` (`re_find_write`, `re_yq_write`, `re_jq_write`, `re_git_write`, `re_rg_exec` and their case arms), at `6d40286`.
- Probe: `check-worktree-scope.sh --cwd <main> --worktree-name <existing> --command "yq '-i' '.a = 1' f.yaml"` and `--command "find . '-delete'"` exit 0 (allowed); `yq -i '.a = 1' f.yaml` exits 2. The same yq probe against the script at `581e785` also exits 0, so it predates spec 00010.
- Review pass 1, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/review/pass-1/review-lessons.yaml` RL-2 (triage F4); review lesson RL-005 in `.workflow/review-lessons.md`.

## Why not a blocker

Pre-existing and on lines spec 00010 did not change. CAP-008's success line (single-quoted `$` reads pass; `$`, backtick and backslash outside single quotes deny) holds, and the guard is accident prevention: an agent must choose the quoted-flag spelling to hit it.

## Suggested scope and size

- Scope: replace the per-tool write-flag denylists for yq, find, jq, git and rg with allowlists of their read forms (as sed's print-only check already does), with quoted-flag deny cases in `tests/hooks/worktree-guard.sh`. Leave the quote scan for `$` as it is.
- Size: 1 to 2 tasks in feature-workflow, 2 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../done/00010-worktree-guard-followups/spec.md)
- Design log entry: [design-log.md](../done/00010-worktree-guard-followups/design-log.md) (section 2026-10-30 Triage, review pass 1)
- Deferred file: [.workflow/deferred/read-only-allowlist-flags.md](../../deferred/read-only-allowlist-flags.md)
