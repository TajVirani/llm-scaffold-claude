# Design log: Worktree guard and upgrade follow-ups

Spec: [spec.md](spec.md)

## 2026-10-30 Origin: 006-result-file-guard-disc-003.md

- Work item: 006-result-file-guard-disc-003.md (Worktree guard allows when it cannot confine)
- Origin spec and step: .workflow/specs/006-result-file-guard, step 3.7
- Problem:

The worktree guard lets a non-isolated implementation or integration agent write into the main checkout in two cases where it cannot establish confinement:
- The launch header cannot be parsed.
- The worktree named for the launch does not exist.
Both are documented as "allow" in the guard's Behaviour text. The shell-scripts profile says guard hooks fail closed on a helper error. Which rule wins is undecided.

- Evidence:

- `.agents/hooks/worktree-write-guard.sh:92-93`: the header parse runs with `2>/dev/null` and an `if` fallback, so a parse error leaves no worktree name. Behaviour, `:23-24`: no header or no worktree, allow. Line numbers are at T1 head `9e706b7`.
- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:101-104`: rule 3 allows every write when the named worktree is missing and the cwd is the main checkout.
- `.workflow/profiles/shell-scripts.md:25`: "Guard hooks fail closed: on an unparsable payload or a helper error they print the host's deny JSON and exit 0."
- T1 mini-review round 3, `.workflow/specs/006-result-file-guard/artifacts/T1/mini-review.yaml` `out_of_scope_noticed` (two decision entries).

## 2026-10-30 Origin: 006-result-file-guard-disc-005.md

- Work item: 006-result-file-guard-disc-005.md (Quoted dollar signs in read-only commands)
- Origin spec and step: .workflow/specs/006-result-file-guard, step 3.4
- Problem:

The worktree scope check denies any read-only chain that contains `$`, so a quoted `$` in a read is refused without the leading `cd`. The sed print-only allowlist accepts a `$` (last-line) address, yet no command using one can pass. `sed -n '$p' f` and `grep 'x$' f` from the main checkout both need the `cd`.

- Evidence:

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` `read_only_chain` (`case "$chain" in *'$'*...`) at T4 head `d612b9d`.
- Probe from T4's result (`.workflow/specs/006-result-file-guard/artifacts/T4/implementation.yaml` `discovered_work[0]`): `check-worktree-scope.sh --command "sed -n -e '1p' -e '\$p' f"` from the main checkout exits 2.

## 2026-10-30 Origin: 006-result-file-guard-disc-007.md

- Work item: 006-result-file-guard-disc-007.md (Re-run checks in the upgrade suite ignore the exit code)
- Origin spec and step: .workflow/specs/006-result-file-guard, step 3.7
- Problem:

Three checks in the `install.sh` upgrade suite assert that a re-run writes nothing, but not that the re-run succeeded. A re-run that refused with exit 1 also writes nothing, so a regression that makes re-runs refuse would pass them.

- Evidence:

- `tests/scripts/install-upgrade.sh:280-281` (JRN-011 third run) and `:408-409` (two-template-groups re-run), at T6 head `b78d868`.
- T6 mini-review round 5, `.workflow/specs/006-result-file-guard/artifacts/T6/mini-review.yaml` `out_of_scope_noticed`.

## 2026-10-30 Origin: 006-result-file-guard-disc-008.md

- Work item: 006-result-file-guard-disc-008.md (Worktree guard messages say task worktree)
- Origin spec and step: .workflow/specs/006-result-file-guard, step 4.4
- Problem:

The worktree scope check's deny and allow messages, and the `# File:` lines of the scope check and the worktree guard, call the agent's worktree a "task worktree". Phase 1 builds and integration batches now pass through the same guard, and the glossary lists "Task worktree" as an _Avoid_ alias for **Agent worktree** ("Phase 1 and integration are not tasks"). So a denied Phase 1 or integration agent is told it works in a task worktree.

- Evidence:

- `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:2`, `:114`, `:125`, `:234` ("this agent works only in its task worktree $root"); `.agents/hooks/worktree-write-guard.sh:2`, at spec-branch commit `5fdfb89`.
- `.workflow/GLOSSARY.md`, Agent worktree, _Avoid_: "Task worktree (Phase 1 and integration are not tasks)".
- Review pass 1, `.workflow/specs/006-result-file-guard/artifacts/review/pass-1/review-standards.yaml` RS-1 (triage F3).

## 2026-10-30 Origin: 006-result-file-guard-disc-009.md

- Work item: 006-result-file-guard-disc-009.md (Asset list still describes the isolation launch)
- Origin spec and step: .workflow/specs/006-result-file-guard, step 4.4
- Problem:

`assetlist.md`, the scaffold's decision record for its assets, still describes behaviour spec 006 removed. It gives the stop-audit matcher as `implementation`. It also says Phase 1 builds and integration batches keep their existing worktree handling, with the isolation-relaunch fallback. Neither has the "Amended by" note the file uses elsewhere.

- Evidence:

- `assetlist.md:40` ("`SubagentStop`, matcher `implementation` (script also filters)") and `assetlist.md:234` (D85 item 6, the isolation fallback), at spec-branch commit `5fdfb89`.
- `.agents/hooks/claude-settings.template.json` SubagentStop matcher is now `implementation|integration`. `.workflow/specs/006-result-file-guard/design-log.md` D5: "Remove the fallback".
- Review pass 1, `.workflow/specs/006-result-file-guard/artifacts/review/pass-1/review-standards.yaml` RS-2 (triage F4).

## 2026-10-30 Origin: 006-result-file-guard-disc-010.md

- Work item: 006-result-file-guard-disc-010.md (Read-only yq allow entry also permits in-place edits)
- Origin spec and step: .workflow/specs/006-result-file-guard, step 4.4
- Problem:

The shipped Claude settings allow `Bash(yq --front-matter=extract:*)` without a prompt. That prefix also matches `yq --front-matter=extract -i ...`, an in-place frontmatter rewrite. A recorded pitfall says this exact call once dropped a backlog item's body, and its "Prevented by" is still "none yet".

- Evidence:

- `.agents/hooks/claude-settings.template.json:130` and `.claude/settings.json:141`, unchanged since baseline `e049f4d`.
- Review pass 1, `.workflow/specs/006-result-file-guard/artifacts/review/pass-1/review-lessons.yaml` RL-1 (triage F5).

- Seeded as one combined spec at 006 sign-off (5.9): "One combined spec now". `origin` names disc-003; disc-005, 007, 008, 009 and 010 are promoted to this spec too. Numbered `00010` under the 5-digit rule the stakeholder chose for disc-002 ("Any count + 5-digit new specs"), since 007-009 are taken in the primary repo and sibling clones.
