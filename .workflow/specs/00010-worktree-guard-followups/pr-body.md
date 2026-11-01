## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- The worktree guard fails closed: an implementation or integration agent whose agent worktree cannot be established (missing or unparsable launch header, missing transcript, missing named worktree, cwd outside the repo) is denied every call, with a reason naming the cause. The guard also denies on an unparsable payload, and with a fixed deny when jq is missing.
- `check-worktree-scope.sh` gains `--confined`. Its read-only check passes a `$` or backtick inside single quotes (`sed -n '$p' f`, `grep 'x$' f`) and still needs the `cd` for `$`, a backtick or a backslash outside single quotes.
- Guard messages, `# File:` lines and `--help` say "agent worktree" and name the Phase 1 and integration worktree shapes. `implementation-orchestrator.md` says a missing agent worktree is denied.
- The shipped Claude settings and this repo's `.claude/settings.json` deny `yq --front-matter=extract` with `-i` or `--inplace`. Extract reads stay allowed.
- The upgrade suite's three "re-run writes nothing" checks also assert the re-run exits 0.
- `assetlist.md` and `PROVENANCE.md` describe the agent worktree build as spec 006 left it.

## Why the change

- Spec 006 left the guard allowing a write when it could not confine the agent, against the shell-scripts profile's fail-closed rule.
- Any `$` blocked a read chain, even a quoted one, so harmless reads such as `sed -n '$p' f` needed a `cd`.
- The guard's messages and the asset record still described a "task worktree" and the removed isolation fallback.
- A recorded pitfall (`yq --front-matter=extract -i` truncating backlog items) had no prevention.
- Three upgrade checks would pass a re-run that refused with exit 1.

## Why this approach

- Placement: the confinement rule, including when no worktree can be found, lives in the shared `check-worktree-scope.sh` (feature-workflow). The hooks stay thin adapters (design-log D1). Keeping the fail-closed branch in the Claude hook alone was ruled out.
- Under `--confined`, no root means every call is denied before any other allow (D10). This is the loudest signal, and an agent with no worktree cannot do its job anyway.
- The quote scan extends the in-house bash scanner. library-evaluation rejected a full shell parser (mvdan/sh needs Go).
- The yq gap is closed with `permissions.deny` rules, which `install.sh` already merges as a union, so the installer needs no change (D6).
- Impact: two scripts and two settings files extended; the asset record and provenance text rewritten in place; `codex-write-guard.sh`, `install.sh` and `.agents/lib/` unchanged.

## Special things to note

- Report: [.workflow/specs/00010-worktree-guard-followups/report.md](.workflow/specs/00010-worktree-guard-followups/report.md)
- Task PRs: none. `origin` is a local path, so task review records were skipped and every task merged locally.
- F3 (medium): in-place extract spellings the text rules miss (`-Pi`, `--inplace=true`, a call through a variable) still pass the extract allow. Deferred: [.workflow/deferred/frontmatter-extract-write-guard.md](.workflow/deferred/frontmatter-extract-write-guard.md).
- The missing-transcript deny is proven on fixture payloads only. Deferred: [.workflow/deferred/subagent-missing-transcript-path.md](.workflow/deferred/subagent-missing-transcript-path.md).
- Line coverage of the changed shell code is not measured (no bash coverage tool): [.workflow/deferred/bash-line-coverage.md](.workflow/deferred/bash-line-coverage.md).
- With jq missing in an installed workflow, the guard now denies every Bash, Write, Edit and NotebookEdit call, the main session included (stakeholder decision D9).

## How to test

1. Run `tests/run-all.sh`. Expected: `TOTAL passed=3678 failed=0 skipped=0 xfail=0 (62 suites)`.
2. Run `tests/run-all.sh --suite hooks/worktree-guard`. Expected: `failed=0`, covering the fail-closed, quoted-`$`, CLI and wording checks.
3. In a Claude Code session in this repo, run `yq --front-matter=extract '.status' .workflow/specs/00010-worktree-guard-followups/spec.md`. Expected: it runs and prints the status.
4. In the same session, run `yq --front-matter=extract -i '.a = 1' <scratch>.md`. Expected: refused by the permission rules.

## Blast radius

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`: called by `worktree-write-guard.sh` (Claude, every Write/Edit/NotebookEdit/Bash call of an implementation or integration sub-agent) and by `codex-write-guard.sh` (Codex `apply_patch`, unchanged because it never passes `--confined`).
- `.agents/hooks/worktree-write-guard.sh`: PreToolUse in every target project's Claude settings. A confined agent launched without its agent worktree is now stopped on its first call. A missing jq now blocks main-session tool calls.
- `.agents/hooks/claude-settings.template.json` and `.claude/settings.json`: four deny rules merged into every target on install or upgrade. Any in-place `yq --front-matter=extract` call is refused there.
- `.agents/hooks/claude-settings.template.md`, `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`, `assetlist.md`, `PROVENANCE.md`: documentation only.
- Untouched: `install.sh`, `.agents/lib/`, `codex-write-guard.sh`, the stop audit.

## Risk and reversibility

Risk: Medium - the guard now denies where it used to allow, so a host change to the sub-agent transcript layout would stop every confined agent until fixed, and a missing jq blocks the main session's Bash and file tools; the suite and a live permission check pass.
Reversibility: Easy - revert the merge commit; deny entries already merged into a target's settings stay until removed by hand, since the installer's union merge never deletes.

## Areas, concepts and seams changed

- Seam changed first: `check-worktree-scope.sh --cwd D [--worktree-name N] [--confined] (--path P... | --command C)`. `--confined` is new; with no confinement root it exits 2 for every call. The read-only allow now scans quotes.
- `worktree-write-guard.sh` PreToolUse contract: same payload-in, deny-JSON-out shape, with new denies for an unparsable payload, a missing jq and an unconfinable agent.
- `permissions.deny` in the Claude settings template: four new entries.
- Modules: feature-workflow, hooks, tests; scaffold records (`assetlist.md`, `PROVENANCE.md`). Concepts: **Agent worktree**, **Launch header**.

## How to undo this PR

1. `git revert -m 1 <merge commit>` on the main branch.
2. In a target project that already installed this version, delete the four `Bash(yq ... --front-matter=extract ...)` entries from `.claude/settings.json` `permissions.deny` by hand if they are unwanted; re-running the older installer does not remove them.
