# Fix plan: human round trips, result filing and review churn

> Scaffold-only design doc (D30). Written 2026-10-22 from an audit of the 002-review-lessons run (session transcripts, spec artifacts, git log). It records where the time went, the decisions that fix it (D96–D101, copied into `assetlist.md`), the contracts the build units share, and the units themselves. The build runs outside `feature-workflow` at the stakeholder's request, as `PLAN/test-cost-fix.md` did. No Tier A file changes.

## What the audit found

Spec 002 (full path, 6 tasks, 2 waves) took about 263 minutes of session time once gaps where the stakeholder was away for over 30 minutes are removed. The test-cost fix (D91–D95) had landed before the build: nine full-harness runs on the main session cost about 15 minutes in all. The time sat elsewhere.

| Segment | Wall | Waiting on the stakeholder | Agent launches |
| --- | --- | --- | --- |
| Discovery | 69 min | 39 min | 7 |
| Phases 1–2 | 55 min | 30 min | 1 |
| Phase 3 | 50 min | 9 min | 17 |
| Phase 4 and rework | 44 min | 5 min | 12 |
| Phase 5 | 31 min | 16 min | 0 |

Causes, in order of minutes:

1. **Discovered work blocked the spec three times for items that could wait.** The untracked-lint item (1.2), the research model-map item (2.1) and the flaky timing test (3.9) were each assessed "can be solved later" by the orchestrator, yet 00.21 blocked the spec and every launch until the stakeholder ruled: 32 minutes of waiting. All three were dismissed or duplicated shelved items (retrospective 002, F9). Net effect on the build: none.
2. **Six mini-review launches on T1.** Each failing round named one new cosmetic item on lines an earlier round had passed; three rounds were noise, about 10 minutes at 3.3 minutes per round.
3. **The orchestrator retyped every agent result.** 23 result blocks (implementation, integration, mini-review) were re-typed by heredoc into `artifacts/`; two broke on YAML quoting and needed fix turns. About 10 minutes of orchestrator output.
4. **Sequential asks that could be one round.** 5.5, 5.9 and the retrospective's "anything to weigh" came as three rounds within seven minutes; 5.3's 13 proposals took two asks.
5. **The resume re-derived main drift.** The handoff carried no main sha; the session spent its first eleven minutes rereading the spec folder and finding the lens-contract change by hand.
6. **Small items.** The term-gate ask ran before retrieval instead of beside it; a gate re-ran after the wall-clock concurrency assertion failed under load; the 1.4 known-bad record was assembled by four awk attempts over a verbose log.

## Decisions (D96–D101, authoritative copy in `assetlist.md`)

- **D96. Can-wait discovered work never blocks; duplicates are filed without a ruling.** (Amends D56.) The orchestrator assesses every discovered-work entry first, with the 00.22 rule (blocker when a capability's success line or a journey cannot be met without it, or when continuing builds on something known to be wrong; an agent's `blocker_assessment` is the starting point). A **blocker** runs 00.21–00.24 as before: block, present every blocker that has arrived in one call, rule, record. A **can-wait** item never blocks and is never asked about one at a time: 00.26 first checks `.workflow/deferred/*.md` (not `archive/`) and every `open` item in `.workflow/specs/work-backlog/` by concept, as deferred-handoff does; a match appends one line to that file (a Later requests line on a shelf file; an "Also seen" line under Evidence on a backlog item) and logs one line in `design-log.md`; no match writes the work item with `status: open` and a full Discovered work entry whose ruling reads "can be solved later; filed without a ruling, offered at 5.9". Either way the current work continues at once: no `blocked`, no launch held, no 00.28. 5.9 presents every open item of the spec in one call and keeps its three routes; a stakeholder who thinks an item should have blocked answers 5.5 with a change request (5.6). Size-budget halts (00.29) and Phase 0 scope decisions (0.3.16–0.3.17) are unchanged. Decided 2026-10-22: three can-wait blocks on 002 cost 32 minutes and changed nothing.
- **D97. Implementation, integration and mini-review agents file their own result blocks.** (Extends D93 to Phase 3.) Each agent writes its full result block to its evidence file in the main checkout with one quoted heredoc, after its toolchain run and commit: `<spec_dir>/artifacts/<task_id>/implementation.yaml` (Phase 1: `artifacts/phase-1-<work_type>/implementation.yaml`), `<spec_dir>/artifacts/integration-<work_type>/integration.yaml`, `<spec_dir>/artifacts/<task_id>/mini-review.yaml`. Its final message is a summary block only (C2). The orchestrator never retypes a block: it runs `check-task-result.sh <file>` (C1), which validates the shape and prints a bounded table, and reads single fields with `yq`. A missing or invalid file is one resume of the same agent with the checker's lines; a second failure is a stop (`blocked`). Before a fix round, rework or re-check on a task that already has a result file, the orchestrator renames it `<name>-r<k>.yaml` (k = 1 + the count of existing `<name>-r*.yaml`), so the plain name is always the newest; 5.4 and the retrospective read the plain names. The worktree guard allows the write: an implementation agent's command starts with `cd <worktree> &&` and the heredoc targets an absolute path under `artifacts/`, which `check-write.sh` classes as unguarded. Decided 2026-10-22: 23 retyped blocks on 002, two of them broken by quoting.
- **D98. A mini-review after a wording-only fix round is a re-check, not a new review.** (Amends D95.) When a 3.8 failure's items were all wording or readable-code items and the same implementer was resumed, the next `profile-mini-review` launch carries the previous verdict file and the fix diff (C3). The reviewer judges the previously failed items against the full diff and every checklist item against the lines the fix changed; every other item keeps its previous verdict, copied through with `carried_from: r<k>`. A re-check never fails an item on a line the fix did not change unless that item failed in the previous round. After a behaviour fix (a fresh launch) the next review is full. Decided 2026-10-22: rounds 2–4 of T1's rework on 002 each failed a new cosmetic item on unchanged lines.
- **D99. Sign-off asks are batched.** 5.3 is one round: every proposal listed by id, target and a one-phrase gist, with the file linked, and one question: approve all as written, or name exceptions (`P<n>: modify <text>` or `P<n>: reject <reason>`); only modified rows get a second round. 5.5, 5.9 and the retrospective's going-in concerns are one call: the approval question, one question per open backlog item (a second call only when more than the host's per-call limit), and "anything you want weighed at 5.7" with a "none" option. Sign-off records the concerns under its 5.5 design-log entry; retrospective step 2 takes them from there and asks only when the entry has none. A 5.5 No still goes to 5.6; the 5.9 and concern answers stay logged for the spec's return. Decided 2026-10-22: three rounds in seven minutes on 002, and 5.3 split over two asks.
- **D100. The handoff records the main-branch tip; resume reports drift.** The handoff frontmatter gains `main_sha` (the project's main branch at handoff) and `affected_paths` (the spec's affected area from `codebase-map.md`, else the paths under Files touched). On resume, when the main branch has moved, the session runs `git log --oneline <main_sha>..<main> -- <paths>` and `git diff --stat` over them, tells the stakeholder what changed in the affected area before the first action, and appends a dated "Main moved since handoff" entry to the spec's `design-log.md`. Verification-setup 1.1 reads that entry before filling Targets. Decided 2026-10-22: on 002 the lens contract moved between 0.6 and 1.1 and was found by reading the module.
- **D101. Three small time sinks.** (a) Discovery launches `retrieval` and `library-evaluation` in the same message as the 0.2.2 term-gate ask when 0.2.7 found every cache fresh; the briefs carry the raised terms as proposed; 0.2.3 and 0.2.6 are written as each answer lands. When caches need 0.2.8, regeneration launches beside the ask and retrieval follows publishing. (b) The harness selection suite proves concurrency by interval overlap (each stub records its start and end; parallel stubs overlap, `-j 1` stubs never do), not by elapsed seconds, so load cannot fail a gate; `.workflow/deferred/concurrency-check-timing.md` is resolved by it. (c) `tests/run-all.sh -v` ends with a `== failures` block: every FAIL line with its detail, grouped by suite, so a verbose log serves the 1.4 record without parsing. Decided 2026-10-22.

## Contracts the units build to

### C1. `check-task-result.sh` (shell-scripts; model: `check-review-findings.sh`)

`.agents/skills/feature-workflow/scripts/check-task-result.sh <file> [--kind implementation|integration|mini-review]`. Kind from the basename when not given: `implementation*.yaml`, `integration*.yaml`, `mini-review*.yaml`; any other name needs `--kind`. Reads the file only. bash 3.2, jq, mikefarah yq v4 (`yq -o=json`, then jq over the slurped document; a multi-document file is a shape error).

Shape rules, one error line per breach (`<field>: <problem>`), exit 1 when any:

- **implementation**: `status` in `done | profile-wrong | scope-expansion | discovered-work | blocked`; `summary` non-empty string; `task_id` a string that equals the artifacts directory name when the file sits in `artifacts/<dir>/`; `worktree`, `base_commit` non-empty strings; `branch` string or null; `head_commit` a 7–40 hex string (null allowed only when status is `blocked` or `profile-wrong`); `files_changed` a list of strings; `tests_added` a list of `{file, test, kind}` with `kind` in `behaviour | negative | edge`; `evidence` an object with a non-empty `toolchain`; `considered_not_built` a list; `profile_wrong`, `scope_expansion`, `blocked` each null or an object; `discovered_work` a list whose entries each have `kind` in `bug | requirement | refactor | scope-expansion | decision`, `summary`, `evidence`, `blocker_assessment` in `blocks-this-task | can-wait`, `reason`. Status-specific: `profile-wrong` needs `profile_wrong.line`; `scope-expansion` needs a non-empty `scope_expansion.requested_paths`; `blocked` needs `blocked.reason`; `discovered-work` needs a non-empty `discovered_work`.
- **integration**: `status` in `done | partial | profile-wrong | discovered-work | blocked`; `summary`, `work_type`, `worktree`, `base_commit` non-empty; `branch` string or null; `head_commit` as above; `requests` a list of `{n (integer), verdict, reason}` with `verdict` in `applied | reject-not-shared-core | reject-other-work-type | conflict | blocked`; `files_changed` a list; `evidence.toolchain` non-empty; `discovered_work` as above; `profile_wrong`, `blocked` null or object; `partial` needs at least one non-`applied` verdict.
- **mini-review**: `verdict` in `pass | fail`; `task_id`, `work_type`, `diff`, `tool_output` non-empty; `mode` in `full | re-check`; `previous` a string when `mode` is `re-check`, else null; `items` a non-empty list of `{n, verdict, location}` where `n` is an integer or `R1`–`R5`, `verdict` in `pass | fail | tool-covered | not-applicable`, `location` a string, `note` required for `fail` and `tool-covered`, `carried_from` optional (`r<k>`) and allowed only when `mode` is `re-check`; `verdict` is `fail` iff any item is `fail`; `read_outside_diff` a list; `out_of_scope_noticed` a list with the discovered-work entry fields above.

stdout on exit 0: one header line, then bounded rows, tab-separated:

- implementation: `status: <s>  task: <id>  head: <sha7>  files: <n>  tests: <n> (behaviour <b>, negative <n>, edge <e>)  discovered_work: <k>`; then `summary: <text>`; then one row per discovered-work entry (`kind  blocker_assessment  evidence  summary`); for a stop status, one line naming the stop field's content (`profile_wrong.line`, `scope_expansion.requested_paths`, `blocked.reason`).
- integration: `status: <s>  work_type: <wt>  head: <sha7>  requests: <n> (applied <a>, rejected <r>, conflict <c>, blocked <b>)  discovered_work: <k>`; then one row per request (`n  verdict  reason`); then discovered-work rows as above.
- mini-review: `verdict: <v>  task: <id>  mode: <m>  items: <n> (pass <p>, fail <f>, tool-covered <t>, not-applicable <na>, carried <c>)  out_of_scope: <k>`; then one row per `fail` and `tool-covered` item (`n  verdict  location  note`); then one row per out-of-scope entry.

Exit 2: usage error, missing or unreadable file, YAML that does not parse, unknown kind, or missing jq/yq (message on stderr).

### C2. Agent summary blocks (the final message; the file holds the full block)

The full result block of each agent keeps its current fields (`.agents/agents/<name>.md` Return), plus `mode` and `previous` on mini-review (C3). The agent writes it with one quoted heredoc (`<<'EOF'`), creating the directory first, then returns only:

````yaml
# implementation
status: <status>
result_file: <spec_dir>/artifacts/<task_id>/implementation.yaml
head_commit: <sha>
summary: <one line>
discovered_work: <count>
````

````yaml
# integration
status: <status>
result_file: <spec_dir>/artifacts/integration-<work_type>/integration.yaml
head_commit: <sha>
applied: <n>
not_applied: <n>
discovered_work: <count>
````

````yaml
# profile-mini-review
verdict: pass | fail
result_file: <spec_dir>/artifacts/<task_id>/mini-review.yaml
mode: full | re-check
failed: [<n> <location>, ...]
out_of_scope_noticed: <count>
````

Implementation agents write from the worktree: `cd <worktree> && main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)") && mkdir -p "$main/<spec_dir>/artifacts/<task_id>" && cat > "$main/<spec_dir>/artifacts/<task_id>/implementation.yaml" <<'EOF' … EOF`. Mini-review and integration agents run in the main checkout (or a linked worktree) and use the same shape. The write happens after the toolchain run and the commit; `artifacts/` is outside the tree hash, so the stop audit still reuses the agent's own run.

### C3. Re-check launch (D98)

After a wording-only 3.8 failure, the orchestrator renames `mini-review.yaml` to `mini-review-r<k>.yaml`, resumes the implementer with the item list (D95), and, when it returns, launches `profile-mini-review` with the header followed by:

```text
re-check of: <spec_dir>/artifacts/<task_id>/mini-review-r<k>.yaml
fix diff: <worktree> <previous head_commit>..<new head_commit>
full diff: <worktree> <base_commit>..<new head_commit>
```

The reviewer sets `mode: re-check` and `previous: <that file>`; items not re-judged carry `carried_from: r<k>` with the previous verdict and location. A full review (no `re-check of:` line) sets `mode: full`, `previous: null`.

### C4. Discovered-work routing (D96)

The caller hands the module the entries as today (origin node, found by, problem, evidence, kind, the agent's assessment). The module's first step is the assessment; its routes are:

| Assessment | Route |
| --- | --- |
| blocker | 00.21 block → 00.22 present (all blockers in one call) → 00.23/00.24 → record → 00.28 |
| can wait, matches a shelf file or an open backlog item by concept | append one line to that file, one-line design-log record, return to the caller at once |
| can wait, no match | 00.26 write the item (`status: open`), full design-log entry ("filed without a ruling, offered at 5.9"), return to the caller at once |

The stakeholder may overrule a blocker to "not a blocker" at 00.22 (then 00.25–00.27 as today). The "Mid-wave rule" (no new launch) applies while the spec is `blocked` only.

### C5. Sign-off round (D99)

One AskUserQuestion call at 5.5 holds, in order: the 5.5 approval question; one 5.9 question per open backlog item (title, Problem, Suggested scope, origin step; options start / keep open / move to the shelf), continuing in a second call only past the per-call limit; and the 5.7 question "Anything you want weighed in the retrospective?" with the option "Nothing in particular". The design-log 5.5 entry records the approval, each 5.9 ruling and the concerns verbatim (`Going-in concerns: <text | none>`).

## Work units

Each unit is one opus builder in its own git worktree on its own branch, with the file set below and nothing outside it. Every unit runs `tests/run-all.sh` and shellcheck over the shell files it touched before it reports, and commits with a Conventional Commits subject (no AI mention, no trailer).

| Unit | Work type | Files | Done when |
| --- | --- | --- | --- |
| U1 Checker and harness | shell-scripts, test-harness | new `.agents/skills/feature-workflow/scripts/check-task-result.sh`, new `tests/scripts/check-task-result.sh`, `tests/run-all.sh`, `tests/scripts/run-all-selection.sh`, `tests/README.md` (two rows: the new suite, the `-v` failures block), `PROVENANCE.md` (the scripts row names the new script) | C1 holds with a suite: one valid file per kind (exit 0, header and rows match), one malformed file per shape rule (exit 1, the line names the field), kind from basename and from `--kind`, missing file, bad YAML and unknown kind (exit 2). D101(b): the selection suite's concurrency checks use interval overlap for the parallel case and no overlap for `-j 1`; the `-lt 4` wall-clock check is gone; the `-ge 4` serial check may stay. D101(c): `tests/run-all.sh -v` prints `== failures` after the summary with each FAIL line and its indented detail grouped under `-- <suite>` lines, nothing when no suite failed; asserted in the selection suite. |
| U2 Agent and orchestrator docs | agent-docs | `.agents/agents/implementation.md`, `.agents/agents/integration.md`, `.agents/agents/profile-mini-review.md`, `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`, `.agents/skills/feature-workflow/modules/verification-setup.md`, `.agents/skills/feature-workflow/SKILL.md` | D97, D98, C2, C3 are what the agent files and the orchestrator say (3.2, 3.4, 3.7, 3.8, fix rounds, rework entry, the `<name>-r<k>` renaming, the one-resume-then-stop rule, "never retype a block"); the orchestrator's Discovered work section and verification-setup's 1.2 return table follow C4 (the module assesses first; only a blocker blocks or holds launches); verification-setup 1.1 reads the "Main moved since handoff" entry (D100); SKILL.md's "Sub-agents never write" and "Never grow the spec mid-build" lines and the discovered-work module row match D96/D97. The four lint suites pass. |
| U3 Flow modules and skills | agent-docs | `.agents/skills/feature-workflow/modules/discovered-work.md`, `modules/review-triage.md` (6.0), `modules/task-breakdown.md` (the Discovered work paragraph), `modules/sign-off.md` (5.3, 5.5, 5.9), `modules/discovery.md` (0.2.2–0.2.6 ordering), `assets/design-log.md` (Discovered work entry; the 5.5 entry's concerns line), `assets/work-item.md` (the comment's "Written by" line), `.agents/skills/retrospective/SKILL.md` (step 2), `.agents/skills/handoff/SKILL.md` and `assets/handoff.md` (D100) | C4 and C5 are what the modules say; D100 fields and resume steps are in the handoff skill; D101(a) ordering is in discovery.md step 2 and 5. Node ids are unchanged (`references/steps.tsv` untouched); `--step` phrases use existing ids only. The four lint suites pass. |
| U4 Design docs | scaffold docs | `assetlist.md`, `PLAN/decision-flow-reference.md`, `PLAN/decision-flow.mermaid` | D96–D101 appended after D95 verbatim from this file; D56 marked amended by D96, D93 extended by D97, D95 amended by D98; the agent rows for `implementation`, `integration`, `profile-mini-review` and the module row for `discovered-work` say what changed; the scripts row names `check-task-result.sh`; reference entries for 00.21–00.28, 3.4, 3.7, 3.8, 5.3, 5.5, 5.9, 1.1 and the 0.2 paragraph updated; mermaid labels for 00.21, 00.22, 00.26, 00.28, 3.7, 5.3, 5.9 say what changed, ids unchanged. `tests/lint/step-list.sh` passes. |
| U5 Integration | none | none of its own | After U1–U4: branch `fix/workflow-speed` off `main`, the four branches merged, conflicts resolved in favour of this file's contracts, shellcheck over every tracked `.sh`, `tests/run-all.sh` green, a review of the whole diff against this file, and a Later requests line on `.workflow/deferred/concurrency-check-timing.md` naming D101(b). |

## Expected effect

On a run shaped like 002: no blocking wait for can-wait items (32 minutes), one review round instead of four on a wording-only rework (about 10 minutes), no retyped result blocks (about 10 minutes), two fewer sign-off rounds and one fewer 5.3 round (5–8 minutes), a resume that starts with the drift (about 5 minutes). Together above the 26-minute (10 percent) target without removing a gate, a lens, a test run or a human approval.

## Out of scope

- The P13 comment-id lint (`.workflow/deferred/comment-id-lint.md`): test-harness work for a next feature; D98 reduces its urgency.
- The discovered-work shelf check for Phase 0 (0.3.16–0.3.17 already match by concept through deferred-handoff).
- Any change to launch header fields or to `status-transition.sh` transitions: D96 removes blocks, it adds no status.
- Tier A edits (`.workflow/rules.md`, profiles, pitfalls): none needed; pitfall P10 stays as history.
