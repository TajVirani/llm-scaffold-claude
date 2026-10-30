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

## 2026-10-30 Placement: feature-workflow (check-worktree-scope.sh) for the confinement rule

- Owning module: feature-workflow owns the fail-closed confinement decision, in `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`; the hooks (`worktree-write-guard.sh`, `codex-write-guard.sh`) stay thin adapters that pass what they know. The other fixes stay in the modules that own their files: hooks (`claude-settings.template.json`), tests (`tests/**`), and the unowned scaffold files `assetlist.md` and `.claude/settings.json`.
- Alternatives considered: each fix stays put, with the fail-closed branch in the Claude hook: not chosen, the stakeholder wants the rule in the one shared script ("Move rule into the scope check").
- Conflict with an ADR or rule: none. ADR-0001 (host-neutral core behind thin shims) is served by it; `.workflow/rules.md` Ownership lets hooks depend on feature-workflow.
- Decision: **D1** The confinement rule, including when to deny because no worktree can be established, lives in `check-worktree-scope.sh`. ADR: none; the placement fails the three-part test (a script-level move, easy to reverse).

## 2026-10-30 Deeper prompt

**What this changes:** The worktree scope check denies a confined agent's write when its worktree cannot be established (unparsable header, or a named worktree that is missing); single-quoted `$` in read-only commands passes without the `cd`; guard messages say "agent worktree"; the upgrade re-run checks assert exit 0; `assetlist.md` gets "Amended by spec 006" notes; the shipped Claude settings deny `yq --front-matter=extract` combined with `-i`/`--inplace`.

**Why:** Spec 006 left the guard, the installer tests, the asset record and the settings out of line with the fail-closed rule, the glossary and a recorded pitfall.

**Ask:** Make the worktree guard and its surroundings trustworthy: a confined agent never gets a silent pass, a harmless read is never needlessly blocked, and every message, test and record matches what 006 built.

**Goals:**
- An implementation or integration agent whose worktree cannot be established is denied, with a reason that says why.
- `sed -n '$p' f` and `grep 'x$' f` pass from the main checkout; `$` outside single quotes, or a backslash, is still denied.
- No guard message or `# File:` line calls a Phase 1 or integration worktree a "task worktree".
- A re-run that refuses with exit 1 fails the three upgrade checks.
- An installed project, and this repo, deny `yq --front-matter=extract -i` without prompting; the pitfall records its prevention.

**Downstream:** none known; the worktree-name-parser and main-checkout-resolver shelf items stay shelved.

**Tools and technologies:** bash 3.2 only; extend the in-house scanner (no new runtime); Claude Code `deny` rules, which `install.sh` already merges as a union.

**Gotchas:** Spec 007 edits `install.sh` and line 148 of the settings template in parallel: stay out of both. A deny rule is text matching, not a security boundary.

**Not asked for:** a full shell parser; a main-session yq hook; Codex fail-closed changes beyond what the scope check gives; splitting the upgrade suite (006-disc-001).

**Original request:** "Take spec `.workflow/specs/00010-worktree-guard-followups` from draft to done ... seeded at 006's sign-off from the promoted backlog items 006-disc-003, -005, -007, -008, -009 and -010."

Revisions: agreed as first restated.

## 2026-10-30 Questioning round 1

**Q1. One feature or several?**

- Why now: the tree holds three capability changes (CAP-007, CAP-008, a settings deny) plus test and record fixes.
- Options: A: keep one spec · B: convert to an initiative
- Recommended: A, because the stakeholder chose "One combined spec now" at 006 sign-off and each piece is 1-3 files (Origin entries).
- Answer: "Keep one"
- Decision: **D2** One spec covers all six promoted items.

**Q2. Which cases fail closed?**

- Why now: D1 put the rule in `check-worktree-scope.sh`.
- Options: A: deny when the header is unparsable, the named worktree is missing, or the sub-agent transcript is not found · B: only the first two · C: keep allow and amend the profile line
- Recommended: A, because transcript-missing is also "no header" (`worktree-write-guard.sh:80-83`, codebase-map Relevant code) and a host layout change should surface as a deny.
- Answer: "a"
- Decision: **D3** For an implementation or integration agent whose cwd is not a linked worktree, the scope check denies (exit 2, reason naming the cause) when no agent worktree can be established: unparsable or missing header, missing named worktree, or missing transcript. The hook passes a flag saying the agent must be confined. Linked-worktree (isolation) launches keep rule 2. Codex calls are unchanged.

**Q3. Unparsable hook payload.**

- Why now: `worktree-write-guard.sh:65` exits 0 silently; `shell-scripts.md:25` says guards deny (codebase-map Not found).
- Options: A: keep the silent allow and propose a profile wording change at 5.3 · B: deny it too
- Recommended: A, because the hook cannot tell a main-session call from a sub-agent on a payload it cannot parse.
- Answer: "deny it"
- Decision: **D4** `worktree-write-guard.sh` prints the deny JSON on an unparsable payload, as `shell-scripts.md:25` says. No profile change.

**Q4. Quoted `$` rule.**

- Why now: CAP-008's read-only allowlist denies any `$` (`check-worktree-scope.sh:208`).
- Options: A: a left-to-right quote scanner; `$` passes only inside single quotes; `$`, a backtick or `\` outside single quotes (double quotes included) denies; `|`, `&&`, `;` splitting stays quote-blind · B: also allow `$` inside double quotes when not followed by `(` or a name
- Recommended: A, because it matches the work item's scope and library-evaluation's "extend the in-house scanner" verdict.
- Answer: "yes"
- Decision: **D5** Option A.

**Q5. yq deny, and the settings template outside line 130.**

- Why now: an allow rule cannot exclude a flag; deny beats allow (code.claude.com/docs/en/permissions, codebase-map Library options).
- Options: A: deny entries `Bash(yq *--front-matter=extract* -i*)`, `Bash(yq *-i* --front-matter=extract*)` and the two `--inplace` forms at the top of the template `deny` array (line 148, spec 007's, untouched) and in `.claude/settings.json`, with an install test · B: remove the line-130 allow only · C: back to the backlog until 007 merges
- Recommended: A, because `install.sh` already unions `deny` (`install.sh:393-398`), so no installer change.
- Answer: "A"
- Decision: **D6** Option A. The stakeholder agreed the scope reaches the template `deny` array beyond line 130, keeping line 148 untouched.

**Q6. "Task worktree" wording reach.**

- Options: A: the scope check's messages and `# File:` line, the guard's `# File:` line, `assetlist.md:47`, `PROVENANCE.md:21`, plus the stale "under three digits" comment at `worktree-write-guard.sh:21-22`; genuine Phase 3 task uses stay · B: messages and `# File:` lines only
- Recommended: A, because those places describe the shared guard.
- Answer: "A"
- Decision: **D7** Option A.

**Q7. Asset list amendments.**

- Options: A: "Amended by spec 006" notes on `assetlist.md:40` and D85 item 6 (`:234`), plus line 47 · B: also a row for `check-worktree-scope.sh`
- Recommended: A.
- Answer: "yes, but don't add amended by spec, just change the rule to match what we want. I don't want references that go stale"
- Decision: **D8** Rewrite `assetlist.md:40`, `:47` and D85 item 6 in place to describe current behaviour (matcher `implementation|integration`; orchestrator-made Phase 1 and integration worktrees; no isolation fallback), with no "Amended by" note and no spec reference. No new row.

Facts looked up instead of asked (0.3.10): Claude Code permission precedence and wildcards: deny, then ask, then allow; `*` at any position (code.claude.com/docs/en/permissions). `install.sh` unions `permissions.allow` and `permissions.deny` only (`install.sh:393-399`).

## 2026-10-30 Questioning round 2

**Q1. jq missing in the worktree guard.**

- Why now: D4 made the guard deny on an unparsable payload; `worktree-write-guard.sh:60` still exits 0 when jq is missing, and the other guards match only Write|Edit, so Bash passes unguarded.
- Options: A: deny with a static, hand-written deny JSON, as `_guard-common.sh:56-58` does · B: keep the silent allow
- Recommended: A, because it is the same fail-closed rule as D4 and the three write guards.
- Answer: "Deny, static JSON (Recommended)"
- Decision: **D9** `worktree-write-guard.sh` prints a static deny JSON when jq is missing (only when the workflow is installed, as today's earlier `check-worktree-scope.sh` presence check gates).

Facts looked up instead of asked (0.3.10): None.

## 2026-10-30 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| `check-worktree-scope.sh` CLI: new `--confined` flag (no root found → deny, exit 2) | extend | see data-model.md § Scope check contract |
| `check-worktree-scope.sh` `read_only_chain`: quote scanner for `$`, backtick, `\` | extend | see data-model.md § Read-only chain |
| `check-worktree-scope.sh` messages and `# File:` line: "agent worktree" | refactor | wording only |
| `worktree-write-guard.sh`: deny on unparsable payload, jq missing (static), header/transcript not found; passes `--confined`; header text | extend | see data-model.md § Guard decisions |
| `claude-settings.template.json` and `.claude/settings.json` `permissions.deny`: four yq extract in-place rules | extend | see data-model.md § Permission deny rules |
| `tests/hooks/worktree-guard.sh` | extend | allow cases for missing worktree/transcript/unparsable payload flip to deny; quoted-`$` allow and deny cases |
| `tests/scripts/install-upgrade.sh` re-run checks | extend | assert exit 0 |
| `tests/scripts/install-claude-settings.sh` | extend | the four deny rules land in a target's settings |
| `assetlist.md` lines 40, 47, D85 item 6; `PROVENANCE.md:21` | refactor | rewritten in place to current behaviour |
| `codex-write-guard.sh`, `post-implementation-audit.sh`, `install.sh`, `.agents/lib/workflow-paths.sh` | unchanged | |

## 2026-10-30 Questioning round 3

Loop-back from 0.4.7: the module audit's `blocks-this-task` line and two can-wait lines.

**Q1. What a confined agent with no worktree may still do.**

- Why now: module audit: a `--confined` deny at the no-root branch precedes the outside-main-checkout and read-only allows, and the not-a-git-repo exit allows first (`check-worktree-scope.sh:101`, `:113-136`, `:222`; codebase-map Module audit).
- Options: A: deny every call (reads, temp-dir writes, a non-git cwd included) · B: keep reads and outside writes, deny only main-checkout writes; a non-git cwd still allows
- Recommended: A, because with no worktree the agent's job is broken anyway and one loud deny is simplest.
- Answer: "Deny every call (Recommended)"
- Decision: **D10** Under `--confined`, when no root is found (including a cwd outside any git repo) the scope check denies every path and command, exit 2, before any other allow.

**Q2. `--worktree-name` usage text.**

- Options: A: fold the Phase 1 and integration name shapes into the header rewrite · B: defer
- Recommended: A (same header block D7 rewrites).
- Answer: "Fold it in (Recommended)"
- Decision: **D11** The usage text lists `s<NNN>_t<N>`, `s<NNN>_phase_1_<work type>`, `s<NNN>_integration_<work type>` and a Codex `task_name`.

**Q3. Orchestrator doc line for a missing worktree.**

- Options: A: one line in `modules/implementation-orchestrator.md` (not on spec 007's file list) where it describes the guard · B: defer
- Recommended: A, so the orchestrator's denied-agent handling stays accurate.
- Answer: "Add the line (Recommended)"
- Decision: **D12** `implementation-orchestrator.md` says a confined agent whose agent worktree is missing is denied every call, so the orchestrator recreates the worktree before relaunching.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-30 Impact classification (after round 3)

| Part | Classification | Note |
| --- | --- | --- |
| `check-worktree-scope.sh` `--confined` no-root branch moved before every allow, non-git cwd included | extend | D10; see data-model.md § Scope check contract |
| `check-worktree-scope.sh` usage text for `--worktree-name` | refactor | D11 |
| `.agents/skills/feature-workflow/modules/implementation-orchestrator.md` guard description | extend | D12; one line |

0.4.7: no further conflict with the goal or the placement.

## 2026-10-30 Targets (1.1)

- Guard time: options ≤ 0.2 s (recommended, as 006 D16) · ≤ 0.5 s. Answer: "≤ 0.5 s". Decision: **D13** `check-worktree-scope.sh` on a long read-only chain with single-quoted `$` runs in ≤ 0.5 s real, best of 3.
- Line coverage: options not measured (recommended, as 006 D17) · a threshold. Answer: "Not measured (Recommended)". Decision: **D14** Line coverage is not measured; script-coverage and the 3.7 checklist stand in.

## 2026-10-30 Discovered work: assetlist-second-audit-row

- Found at: step 1.2 by the Phase 1 test-harness build. Kind: bug
- Problem and evidence: a second `post-implementation-audit` row in the asset list's hooks table still says the stop audit runs for implementation agents only (`assetlist.md:593`).
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/00010-worktree-guard-followups-disc-001.md](../work-backlog/00010-worktree-guard-followups-disc-001.md)

## 2026-10-30 Task breakdown (2.1-2.4)

- Breakdown approved as proposed ("Approve (Recommended)"): T1 scope check (feature-workflow), T2 worktree guard (hooks, after T1), T3 settings deny rules (hooks), T4 asset record (root-docs); waves 1: T1, T3, T4; 2: T2. No overlaps; no shared core; all afk.
- Seams agreed (2.3): T1 the `check-worktree-scope.sh` CLI; T2 the `worktree-write-guard.sh` payload-in, deny-JSON-out contract; T3 the settings JSON and `install.sh`'s merged output; T4 the record text through grep lint.
- **D15** Size budget: the project defaults, 10 tasks and 30 changed files.
- `tests/hooks/worktree-guard.sh` belongs to T2, which completes the suite after T1; the JRN-008 checks were finished in Phase 1, green at baseline, and belong to no task.

## 2026-10-30 Wave 1 merged (3.16)

- T1 `5e345a0`, T3 `65c126d`, T4 `aa6bc6d`, merged in id order (`6246123`, `aeff6f6`, `cd9fdff`); task PRs skipped (local `origin`: "origin host is neither GitHub nor GitLab"), `pr` stays null.
- T1 mini-review: the first result file did not parse (YAML at L32); one resume fixed it. Its `out_of_scope_noticed` entry (the orchestrator sentence runs ahead of the hook until `--confined` is wired) is agreed scope, T2's, not discovered work.
- Gate 3.9 w1: pass, `TOTAL passed=3451 failed=0 (61 suites)`, T2's suite excluded (`artifacts/gate-3.9-w1/`). Budget: 4 tasks, 7 of 30 changed files.

## 2026-10-30 Discovered work: T2 mini-review notes

- Found at: step 3.7 by profile-mini-review (T2, `artifacts/T2/mini-review-r1.yaml` `out_of_scope_noticed`). Four entries:
  - bug: errors before the guard knows the caller is confined exit non-zero instead of denying (`worktree-write-guard.sh:56`, `:72`, `:74`). Can be solved later; filed without a ruling, offered at 5.9. Backlog item: [work-backlog/00010-worktree-guard-followups-disc-002.md](../work-backlog/00010-worktree-guard-followups-disc-002.md)
  - bug: a malformed transcript is denied with the "no first user message" cause (`:108`, `:110`). Can be solved later; filed without a ruling, offered at 5.9. Backlog item: [work-backlog/00010-worktree-guard-followups-disc-003.md](../work-backlog/00010-worktree-guard-followups-disc-003.md)
  - decision: with jq missing the hook denies main-session calls too (`:22-23`, `:66-70`). Already decided: D9 (round 2), so no item.
  - refactor: the hooks folder resolved with plain `cd` and with `cd -P` (`:63-64`, `:72`). Can be solved later; filed without a ruling, offered at 5.9. Backlog item: [work-backlog/00010-worktree-guard-followups-disc-004.md](../work-backlog/00010-worktree-guard-followups-disc-004.md)
- T2 mini-review round 1: fail on R2 (`:68`, the hand-written no-jq deny needs a reason comment); wording-only fix round.

## 2026-10-30 Wave 2 merged (3.16)

- T2 `eab2056` merged (`Merge T2`); task PR skipped (local `origin`). Mini-review round 1 failed R2 (wording); the wording-only fix round passed the re-check. The re-check's four `out_of_scope_noticed` entries are the same four already filed or ruled above (duplicates, nothing new filed).
- 3.9 wave 2 (last): full harness `TOTAL passed=3678 failed=0 skipped=0 xfail=0 (62 suites)`, nothing excluded (`artifacts/gate-3.9-w2/`). Budget: 4 tasks, 8 of 30 changed files. 3.10-3.11: no browser suite (Suites, Browser row: not applicable), so no e2e run; in-review at 3.11.

## 2026-10-30 Triage, review pass 1

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | review-standards (RS-1) | A new body comment in the guard suite names a journey id (`JRN-001`) | `tests/hooks/worktree-guard.sh:92` | medium | Read the line: `# The cause each JRN-001 deny reason must name.`; `.workflow/rules.md` Cross-cutting policy bans journey ids in body comments, and 3.7 fails it as R4. Added by this spec's Phase 1 build | patch (T2, owner of the suite) |
| F2 | review-standards (RS-2) | The guard's Behaviour header and new suite labels say "named worktree", a glossary alias to avoid for Agent worktree | `.agents/hooks/worktree-write-guard.sh:29`; `tests/hooks/worktree-guard.sh:14`, `:17`, `:117-118`, `:335-346`, `:372` | low | Glossary Agent worktree _Avoid_ lists "named worktree"; the lines are new in this change. Fix is wording only | patch (T2) |
| F3 | review-lessons (RL-1) | Text deny rules for in-place `yq --front-matter=extract` miss other spellings (`-Pi`, `--inplace=true`) that the prefix allow still approves (review lesson RL-005) | `.agents/hooks/claude-settings.template.json:147-150`; `.claude/settings.json:157-160` | medium | Verified: the patterns need ` -i` or ` --inplace` as typed, so `-Pi` matches none. The gap is the one spec Assumptions and D6 accepted; before this change every spelling passed, so the change narrowed it. The lesson's fix (allowlist exact read forms) cannot be written with glob permission rules; closing it needs a command-parsing hook, which the Deeper prompt put under Not asked for. Live check 2026-10-30: `yq --front-matter=extract -i ...` on a scratch file was refused by the permission layer, and a plain extract read still ran | defer ([.workflow/deferred/frontmatter-extract-write-guard.md](../../deferred/frontmatter-extract-write-guard.md)) |
| F4 | review-lessons (RL-2) | The read-only check misses quoted write flags (`yq '-i'`, `find . '-delete'`) | `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh` `read_only_segment` | medium | Probe at `6d40286`: `yq '-i' '.a = 1' f.yaml` and `find . '-delete'` allowed, `yq -i ...` denied; the same yq probe on the script at `581e785` is allowed too, so pre-existing and outside this change | discovered work (filed: [work-backlog/00010-worktree-guard-followups-disc-005.md](../work-backlog/00010-worktree-guard-followups-disc-005.md)) |

Gaps (4.8): line coverage not measurable (review-targets; matched the shelf file `bash-line-coverage.md` by concept, stakeholder confirmed "Same item", one Later requests line appended); the real payload of a sub-agent with no transcript is not verifiable from the repo (review-end-state; [.workflow/deferred/subagent-missing-transcript-path.md](../../deferred/subagent-missing-transcript-path.md)); the review-end-state gap on whether Claude Code applies the deny rules was settled by the live check in F3. Targets: all 7 measurable targets pass (guard-time 0.19 s against 0.5 s).

Failed lenses: none
Outcome: rework 1 of 5

## 2026-10-30 Discovered work: suite-header journey ids

- Found at: step 3.7 by profile-mini-review (T2 rework, `artifacts/T2/mini-review-r3.yaml`). Kind: decision
- Problem and evidence: the guard suite's header names journey ids on lines the rework did not touch (`tests/hooks/worktree-guard.sh:8-21`); 39 suites do the same, while R5 fails them on changed lines.
- Assessment and ruling: can be solved later; filed without a ruling, offered at 5.9
- Backlog item: [work-backlog/00010-worktree-guard-followups-disc-006.md](../work-backlog/00010-worktree-guard-followups-disc-006.md)
- T2 rework mini-review: fail on R5 (lines 14 and 17); wording-only fix round.

## 2026-10-30 Rework 1 merged (3.16)

- T2 `6219d5c` merged: F1 (suite body comment without a journey id) and F2 ("agent worktree" in the hook header and suite labels) patched. Rework mini-review failed R5 (journey ids on suite-header lines 14 and 17); a wording-only fix round passed the re-check. Its remaining `out_of_scope_noticed` entry duplicates disc-006 (nothing new filed).
