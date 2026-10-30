---
status: in-review # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "1c5e46d8c4974a68905cdce522183c067c3e9e41" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "spec/00010-worktree-guard-followups" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "375cb5be0671605c57fb97d9aae271e36a97eaba" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
budget: {max_tasks: 10, max_changed_files: 30} # written at 2.5 from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 006-result-file-guard-disc-003.md # filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
---
# Worktree guard and upgrade follow-ups

## Why

Origin: work items 006-result-file-guard-disc-003, -005, -007, -008, -009 and -010, combined at 006 sign-off (D2: one spec).

Make the worktree guard and its surroundings trustworthy: a confined agent never gets a silent pass, a harmless read is never needlessly blocked, and every message, test and record matches what spec 006 built. Today the guard allows a write when it cannot confine the agent, against the shell-scripts profile's fail-closed rule; any `$` blocks a read chain, even a quoted one; the guard's messages still say "task worktree"; three upgrade re-run checks ignore the exit code; `assetlist.md` still describes the removed isolation launch; and the shipped settings let `yq --front-matter=extract -i`, a recorded pitfall, through without a prompt.

## Capabilities

- **CAP-007** Sub-agents file their own result file (changed: fail closed)
  - **intent:** An implementation or integration agent is confined to its agent worktree, or denied when its worktree cannot be established, so it never writes into the main checkout unconfined.
  - **success:** For an implementation or integration agent whose cwd is not a linked worktree, `worktree-write-guard.sh` denies every call (writes, reads and Bash alike), with a reason naming the cause, when the launch header is unparsable or missing, the sub-agent transcript is missing, the named agent worktree does not exist, or the cwd is outside any git repo; it also denies on an unparsable payload and, with a static deny JSON, when jq is missing. No guard message or `# File:` line calls the agent's worktree a "task worktree", and `implementation-orchestrator.md` says a missing agent worktree is denied.
- **CAP-008** Read-only commands pass the worktree guard (changed: quoted `$`)
  - **intent:** A confined agent can run an allowlisted read whose `$` sits inside single quotes from the main checkout without the leading `cd`.
  - **success:** `check-worktree-scope.sh` allows `sed -n '$p' f`, `sed -n -e '1p' -e '$p' f` and `grep 'x$' f` from the main checkout for a confined agent, and still denies a read chain with `$`, a backtick or `\` outside single quotes (including inside double quotes).
- **CAP-NEW-extract-write-deny** In-place frontmatter extract denied
  - **intent:** A Claude session in an installed project, or in this repo, cannot run `yq --front-matter=extract` with an in-place flag, which truncates a file to its frontmatter.
  - **success:** The settings template's and this repo's `permissions.deny` hold `Bash(yq *--front-matter=extract* -i*)`, `Bash(yq *-i* --front-matter=extract*)`, `Bash(yq *--front-matter=extract* --inplace*)` and `Bash(yq *--inplace* --front-matter=extract*)`, and `install.sh` writes all four into a target's `.claude/settings.json`.

## Constraints

- The confinement rule, including when no worktree can be established, lives in `check-worktree-scope.sh`; the hooks stay thin adapters (D1).
- Under `--confined` with no confinement root, the scope check denies before any other allow, reads and outside-checkout writes included (D10).
- The `--worktree-name` usage text names every shape the hooks pass (D11).
- Codex calls behave as today: `codex-write-guard.sh` is not changed.
- Linked-worktree (Claude `isolation: "worktree"`) launches keep their confinement by cwd.
- Spec 007 is editing `install.sh` and line 148 of `claude-settings.template.json` in parallel: this spec changes neither; the deny entries go at the top of the template's `deny` array (D6).
- Bash 3.2, no new runtime; the quote check extends the in-house scanner (D5).
- `assetlist.md` is rewritten in place to describe current behaviour, with no "Amended by" note or spec reference (D8).
- The three "re-run writes nothing" checks in `tests/scripts/install-upgrade.sh` (JRN-011 third run, the two-template-groups re-run) also assert the re-run exits 0.

## Non-goals

- Quote-aware splitting of `|`, `&&` and `;`; a full shell parser.
- A main-session PreToolUse hook for `yq -i`.
- Codex fail-closed changes.
- Splitting the upgrade suite (006-result-file-guard-disc-001).
- An `assetlist.md` row for `check-worktree-scope.sh`; "task worktree" wording where it means a Phase 3 task's worktree.

## Success signal

A confined implementation or integration agent whose agent worktree cannot be established is denied on its first call with a reason naming why, while a single-quoted `sed -n '$p' f` from the main checkout passes; a fresh `install.sh` target denies `yq --front-matter=extract -i`; and the upgrade suite fails if a re-run refuses. The objectives and journeys are in [verification-plan.md](verification-plan.md).

## Assumptions

- Claude Code matches `*` at any position in a Bash permission rule and applies deny before allow (code.claude.com/docs/en/permissions); not checked against the installed Claude Code version.
- Deny rules are text matching: combined short flags (`-Pi`) or `-f extract` spellings are not covered, which is accepted as accident prevention.

## Open Questions

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)

## Known gaps

- None.
