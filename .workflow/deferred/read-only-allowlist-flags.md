---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
created: 2026-10-30
---

# Read-only allowlist for write flags

**Summary:** The worktree scope check recognises the read forms of yq, find, jq, git and rg, so a quoted write flag cannot pass as a read.
**Mode:** AFK
**Origin:** [00010-worktree-guard-followups](../specs/done/00010-worktree-guard-followups/spec.md), 5.9 work-backlog item `00010-worktree-guard-followups-disc-005.md` (found at 4.4), design-log entry 2026-10-30 Sign-off: stakeholder approval (5.5)

## Goal

The worktree scope check recognises the read forms of yq, find, jq, git and rg, so a quoted write flag cannot pass as a read.

## Background

The scope check lets allowlisted reads run from the main checkout without the leading `cd`. For yq, find, jq, git and rg it denies write flags by a regex that needs the flag after an unquoted space, so `yq '-i' ...` or `find . '-delete'` passes. This predates spec 00010 and is the regex-denylist leak review lesson RL-005 warns about; replacing the denylists with read-form allowlists is its own change.

Problem, from the work item: The worktree scope check lets an allowlisted read run from the main checkout without the leading `cd`, and refuses a read whose write flag it spots. It spots `yq`, `find`, `jq`, `git` and `rg` write flags only when the flag follows an unquoted space, so a quoted flag such as `yq '-i' ...` or `find . '-delete'` passes as a read. This is the regex-denylist leak a recorded review lesson warns about; allowlisting each tool's read forms closes it.

**Current behaviour:** a quoted write flag passes the read-only check (probe: `yq '-i' '.a = 1' f.yaml` and `find . '-delete'` allowed).

**Desired behaviour:** only recognised read forms of each tool pass without the `cd`; any other flag, quoted or not, needs it.

## Constraints

- Review lesson RL-005: allowlist read forms rather than denylisting write forms.
- The single-quote scan for `$` (CAP-008) stays as it is.

## Decisions already made

- Moved to the shelf at sign-off (design-log 2026-10-30 Sign-off entry in [.workflow/specs/done/00010-worktree-guard-followups/design-log.md](../specs/done/00010-worktree-guard-followups/design-log.md)).

## Evidence

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` `read_only_segment` (`re_find_write`, `re_yq_write`, `re_jq_write`, `re_git_write`, `re_rg_exec` and their case arms), at `6d40286`.
- Probe: `check-worktree-scope.sh --cwd <main> --worktree-name <existing> --command "yq '-i' '.a = 1' f.yaml"` and `--command "find . '-delete'"` exit 0 (allowed); `yq -i '.a = 1' f.yaml` exits 2. The same yq probe against the script at `581e785` also exits 0, so it predates spec 00010.
- Review pass 1, `.workflow/specs/done/00010-worktree-guard-followups/artifacts/review/pass-1/review-lessons.yaml` RL-2 (triage F4); review lesson RL-005 in `.workflow/review-lessons.md`.
- Commit at shelving: `f276ea1`.

## Acceptance criteria

- [ ] `yq '-i' ...`, `find . '-delete'`, `jq '-i' ...` and `git '--output=x' log` from the main checkout are denied without the `cd`.
- [ ] Today's allowlisted reads still pass.

## Out of scope

- sed, whose print-only check is already an allowlist.
