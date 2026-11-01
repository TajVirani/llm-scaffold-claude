# Workflow review: specs 00010 to 00013

Date: 2026-10-31. Scope: the `feature-workflow` runs that finished specs 00010 (full path, clone `llm-scaffold-claude-00010`) and 00011, 00012, 00013 (light path, clone `llm-scaffold-claude-bugs`), plus one trivial edit, all on 2026-10-30. Sources: the two session transcripts and their sub-agent transcripts, the spec folders on `main` (`.workflow/specs/<spec>/`), the retrospectives, the backlog and shelf, and `git` in both clones. File:line references are to the workflow source as it ran (the copy in the bugs clone at `469ade4`); the primary checkout's `implementation-orchestrator.md` was being edited while this review ran, so its line numbers may differ.

All times are UTC on 2026-10-30. "Wait" is the gap between an `AskUserQuestion` call and its answer. "Active" is gross time minus waits.

## 1. Speed

### Evidence

**Headline numbers**

| Spec | Path | Code change | Gross | Human wait | Active | Agent launches | Full-harness runs |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 00010 worktree-guard-followups | full, 4 tasks, 2 waves | 13 files, +383/-68 | 272 min | 131 min (15 asks) | 142 min | 24 | 8 |
| 00011 interrupted-run-cleanup | light, 1 task | 2 files, +179/-4 | 159 min | 92 min (8 asks) | 67 min | 11 | 6 |
| 00012 extractor-multiline-quotes | light, 1 task | 4 files, +246/-41 | 114 min | 26 min (7 asks) | 88 min | 12 | 8 |
| 00013 validator-diagnostic | light, 1 task | 4 files, +86/-13 | 40 min | 7 min (7 asks) | 33 min | 7 | 4 |
| trivial edit (bugs session, item 1) | 0.0.2 | 1 backlog item closed | 11 min | 3 min (1 ask) | 8 min | 0 | 2 |

Baseline from the 2026-10-22 audit of spec 002: 263 min gross, about 100 min waits, 33 launches.

The user's impression is half right. After discovery, a light-path spec with one small task took 33 min (00013), 67 min (00011) or 88 min (00012) of active time; the full-path spec took 142 min active. Those are not "hours" of agent work for 00013, but 00011 and 00012 did take well over an hour of active time for 2 to 4 changed files, and gross time for every spec except 00013 ran to two or more hours. Two single waits explain most of the gross time: the user was away from 15:37 to 17:02 while both sessions sat on a question (85.6 min in 00010, 79.2 min in 00011). Those two questions did not need asking (see below), so the workflow caused the sessions to stop at exactly the wrong moment.

The D96-D101 levers from the last audit did work where they applied:

- D96 (can-wait never blocks): 00010 filed 6 backlog items without a single block. Spec 002 had three blocks costing 32 min.
- D97/D98 (agents file their own result files; re-check after a wording fix): 00010 had 7 mini-review launches, three of them re-checks of 1.3 to 1.4 min; no block was retyped. 00011 had three re-checks.
- D99 (batched sign-off asks): sign-off waits were 0.5 to 2.5 min per ask in 00010, 00012 and 00013. In 00011 and 00012 the 5.5 approval wait was 4.4 and 10.3 min because the user was reading the PR body, which is fine.
- D101(a) (retrieval launched beside the term gate): retrieval and library-evaluation ran in parallel, 2 to 3 min each.

Launches fell from 33 to 24 on a comparable full-path spec, and waits that the workflow itself caused fell from about 100 min to about 45 min on 00010 (131 minus the 86-min absence). The remaining time is spread over many small structural steps, not one big one.

**00010 timeline (full path)**

| Phase / step | Window | Elapsed | Waits | What ran |
| --- | --- | --- | --- | --- |
| 0.1-0.2 discovery setup | 14:53-15:05 | 12 min | 0 | 3 `cache-regeneration` agents (7.3 min, opus), `retrieval` + `library-evaluation` (3 min, parallel), one `claude-code-guide` fact lookup |
| 0.3.4 placement, 0.3.7, deeper prompt | 15:05-15:08 | 3 min | 2.9 | placement ask, `domain-modeling`, deeper-prompt ask |
| 0.3.8-0.3.19 rounds 1-2 | 15:08-15:18 | 10 min | 0.8 | 7 + 1 questions, answered in one message |
| 0.4 impact, module audit, 0.4.7 loop-back round 3 | 15:18-15:37 | 19 min | 14.3 | `module-audit` 2 min; conflict ask (3 questions); 0.5, 0.6 |
| "continue into verification setup?" | 15:37-17:02 | 86 min | 85.6 | nothing |
| 1.1-1.5 verification setup | 17:02-17:35 | 33 min | 0.7 | targets ask; Phase 1 harness agent 25.6 min; 1.4 known-bad run 3.5 min; backlog item disc-001 filed |
| 2.1-2.6 task breakdown | 17:35-17:38 | 3 min | 1.2 | breakdown ask |
| 3.x wave 1 (T1, T3, T4) | 17:38-17:58 | 20 min | 0 | three implementers in parallel (11.2, 5.7, 3.3 min); 3 mini-reviews (0.6-2.4 min); one resume for a bad YAML file; 3.9 gate 4.3 min |
| 3.x wave 2 (T2) | 17:58-18:19 | 21 min | 0 | T2 12.8 min; mini-review 3.2; wording fix round; re-check 1.3; 3 backlog items filed; 3.9 gate 6 min |
| 4.x review pass 1 | 18:19-18:48 | 30 min | 20.7 | 4 lenses in parallel (longest 6.1 min); triage probes 3 min; 4.8 "same shelf item?" ask; handoff files |
| 4.7 rework 1 (T2, two wording patches) | 18:48-19:02 | 13 min | 0 | implementer 6.5 min; mini-review 2.5 (failed R5, wording); fix; re-check 1.4; 3.9 gate 5 min |
| 5.x sign-off | 19:02-19:26 | 24 min | 4.4 | 5.4 harness run 9.5 min (not reused); report, PR body; 5.5 asks in two calls; 5.9 wrote 5 shelf files; retrospective 3 min; local merge; final harness run |

**Light-path timelines (bugs session)**

| Spec | Discovery | Phase 3 (build, gates) | Phase 4 | Rework | Sign-off + merge | Waits |
| --- | --- | --- | --- | --- | --- | --- |
| 00011 | 15 min (cache regen 5.8, retrieval 2.4; waits 5.6) | 24 min (impl 21.2 incl. two wording fix rounds; 3 mini-reviews) | 4 min (3 lenses) | 17 min (impl 15.4, mini 1.1) | 14 min + 5 min post-merge run | 92 (79 absent) |
| 00012 | 17 min (retrieval 2.8; waits 12.5) | 44 min (impl 25.1; mini 3.4; behaviour fix round 9.5 fresh agent; mini 2.5; wording resume 3; re-check 1.6; gate 2.8) | 6 min | 21 min (impl 8.6, mini 2.3, gate 9.3) | 17 min + 7 min post-merge | 26 |
| 00013 | 8 min (retrieval 3.0; waits 3.2) | 15 min (impl 8.6, mini 1.9, gate 4.0) | 3 min | none | 6 min + 5 min post-merge | 7 |

**Where the agent time goes (both sessions, 57 launches)**

| Agent type | Launches | Minutes | Note |
| --- | --- | --- | --- |
| implementation (opus) | 12 | 153 | 8 first launches, 4 fix/rework launches; longest 25.6 (Phase 1 harness) and 25.1 (00012 T1) |
| profile-mini-review (haiku) | 16 | 31 | 9 full, 7 re-checks |
| cache-regeneration (opus) | 6 | 14 | once per session at 0.2.8, before any question was asked |
| retrieval + library-evaluation (haiku) | 8 | 22 | parallel pairs; library-evaluation found nothing to adopt in all four specs (bash-only repo) |
| review lenses | 13 | 36 | 4 + 3 + 3 + 3; 9 findings in total |
| module-audit, fact lookup | 2 | 3 | |

Sub-agents were busy for 78 min of 00010's 142 active minutes and 126 of the bugs session's 197. The rest, about 60 to 70 min per session, is the main session reading modules, writing workflow files, running gates and filing items.

**Fix rounds.** 00010: T1 one resume (bad YAML), T2 one wording round, T2 rework plus one wording round (4 extra review launches). 00011: two wording rounds then a rework (5 extra launches). 00012: one behaviour round, one wording round, one rework (5 extra). 00013: none. Across the four specs, 11 of the 16 mini-review launches were second or later rounds, and 8 of those 11 were about comment wording.

**Full-harness runs.** The harness takes 3 to 4 min (9.5 min once under load). Per light-path spec it ran 4 to 8 times on trees that differed only in workflow data: the implementer's own 3.5 run (`test: tests/run-all.sh`, unscoped because the light path has no Phase 1 tests), once more per fix round, the 3.9 gate on the same tree (not reused: `run-toolchain.sh` line 46 requires "its profile is the same file", and the gate runs under `test-harness` while the task ran under `shell-scripts`), the 5.4 sign-off run (not reused in any spec: 5.3 edits `.workflow/capabilities.md` and `review-lessons.md`, which the tree hash includes, `run-toolchain.sh` lines 42-44), and a post-merge run on `main`. Evidence: `artifacts/*/toolchain.json` `reused_from` is `no` for every gate and sign-off run except 00011's two gates; 00012's T1 and gate-w2 share tree `89a7c6f2b5`, 00013's T1 and gate-w1 share `bbfe8ec6ae`.

**Top time sinks, ranked**

1. Two unneeded stop-and-ask questions at the moment the user stepped away: "continue into verification setup?" (`discovery.md:254-256`, 85.6 min) and "no browser suite: same shelved item?" (`implementation-orchestrator.md:286` via `deferred-handoff`, 79.2 min, then asked again at 2.2 and 2.9 min for 00012 and 00013). Structural: both asks are written into the modules. Cost when the user is present: 1 to 3 min each; cost when absent: the whole absence.
2. Review-driven rework for wording: 00010's rework (13 min, two comment edits), 00011's two wording rounds plus rework (about 28 min, of which the stdin fix was real), 00012's wording round (5 min). Structural: 3.8 sends any failed readable-code item back to the implementer, and 4.7 reopens a task for a low finding.
3. Repeated full-harness runs: about 15 to 25 min per spec. Incidental: the reuse rule is too narrow (profile file identity, tree includes Tier A files).
4. The 4.8 shelf-match ask in 00010 (20.7 min wait) for a target already ruled "not measured" at 1.1 (D14). Structural: `review-triage.md:186` turns every `not_measurable` target into a handoff, and `deferred-handoff` asks when it matches a shelf file.
5. Cache regeneration at session start: 7 min per session, 3 opus agents, before the first question. Structural (`discovery.md` 0.2.7-0.2.8); it also delayed retrieval, since retrieval launches "once step 4 has published".
6. Phase 1 on the full path: 33 min for a harness build whose suites were red by design, plus the 1.4 known-bad run. Structural and worth keeping for real features; disproportionate for a 13-file hook fix.
7. The 0.4.6 module audit loop-back in 00010: 19 min including a 14-min wait, three questions, one of them (D10) a real design point.
8. Discovered-work paperwork: 00010 wrote 6 backlog items (about 36 lines each), then 5.9 turned them into 5 shelf files (about 55 lines each) plus 2 review handoff files. Roughly 600 lines of process text for items whose combined code fix is under 30 lines. About 8 min of agent time plus two sign-off asks.

### Recommendations (speed)

1. **Drop the "continue or fresh session?" ask and the per-spec suite-gap ask.** `discovery.md` "Offer a fresh session" (lines 252-258): continue by default; offer a handoff only when context is actually large (for example after 2 or more loop-backs), and say so in the progress line instead of asking. `implementation-orchestrator.md` 3.13-3.14 (lines 282-287): when the shelf already holds a file whose Origin is "3.14 suite gap" for this repo, append the Later-requests line without asking; ask only the first time a gap is seen in a project. Saves 1 to 3 min per spec when the user is present and avoids the 80-min stall when they are not. Risk: none to quality; the gap is still recorded.
2. **Widen toolchain reuse.** `run-toolchain.sh` Reuse (lines 46-50): match on the `test` command string, not the profile file, so a `shell-scripts` run whose `test` is `tests/run-all.sh` satisfies the `test-harness` gate on the same tree; and add `.workflow/capabilities.md`, `review-lessons.md`, `profiles/`, `GLOSSARY.md` and `rules.md` to the tree-hash exclusions, or hash only files the profile's commands can read. Also drop the post-merge `tests/run-all.sh` on `main` when the merge was a fast-forward of a tree that already passed. Saves 10 to 20 min per spec. Risk: low; a Tier A edit that changes test behaviour (a profile toolchain line) is the one case to keep, so exclude profiles only when the `test` command is unchanged.
3. **Make wording findings a patch the orchestrator applies, not a fix round.** `implementation-orchestrator.md` Fix rounds (lines 178-190): for a `fail` whose items are all readable-code lines (R1-R5) with the fix text in the note, let the main session apply the one-line edit in the task worktree, commit it, and launch the re-check; do not resume the implementer. `review-triage.md` 6.3 (line 151): a pass whose patch entries are all `low` wording goes to the same direct patch instead of reopening the task at 4.7. Saves 5 to 15 min per spec (00010's rework, 00011's two rounds). Risk: the orchestrator edits code it did not write; keep the re-check and the 3.9 gate.
4. **Regenerate caches lazily.** `discovery.md` 0.2.7-0.2.8: when a cache is stale only because of commits outside the affected area, or when `retrieval` can read the code directly (it already does for stale caches: "read the code for these, stamp null"), launch retrieval at once and run regeneration in the background after discovery, or at sign-off. Saves 5 to 7 min of wall-clock at the start of every session. Risk: retrieval reads slightly older caches; it already reports stamps.
5. **Scale Phase 1 to the change.** `verification-setup.md` 1.2: when the full path is taken only because the change spans more than one module (00010's reason), and the harness already exists, let 1.2 be "the Phase 1 tests are written by the implementers in their tasks" and run 1.4 once on the merged wave. Saves 20 to 30 min on a small full-path spec. Risk: the red-by-design proof is weaker; keep the full Phase 1 when a new capability or a new test harness is involved.
6. **Pre-settle ordering questions in the loop.** `questioning-loop.md` 0.3.8: when a decision adds a mode to an ordered rule chain (the 00010 retrospective lesson), add "where in the order" as a frontier question in the same round. Saves the 0.4.7 loop-back (15 to 20 min in 00010). Risk: none.

## 2. Findings

### Evidence

I went through every mini-review verdict, every lens finding, every `not_checked` and `not_verifiable` line, and every backlog and shelf item the four specs produced. The classification is: **real and reproduced** (a run, probe or test showed it), **plausible but unproven** (reasoned from code, no run), or **speculative** (a hypothetical trigger). "In scope" means inside the spec's capabilities and the task's lines.

**Mini-review (3.7) verdicts and out-of-scope notes**

| Spec, round | Item | Class | In scope | Outcome | Cost |
| --- | --- | --- | --- | --- | --- |
| 00010 T1 r1 `out_of_scope_noticed` | orchestrator doc line "runs ahead of the hook until `--confined` is wired" | real, reproduced (grep) | yes, T2's work in the same spec | orchestrator correctly said "agreed scope, not discovered work" | 1 min |
| 00010 T1 | result file did not parse | process | | one resume | 1 min |
| 00010 T2 r1 fail R2 | missing reason comment on the hand-written deny | real (wording rule) | yes | wording round + re-check | 4 min |
| 00010 T2 r1 oos bug | errors before `CONFINED` are not denied, "reachable only with a partial install" | plausible, unproven; pre-existing | no | backlog disc-002, then shelf file `worktree-guard-early-errors.md` | 2 min + ask |
| 00010 T2 r1 oos bug | malformed transcript gets the wrong deny cause | plausible, unproven (read from code) | no (adjacent new code) | disc-003, shelf `worktree-guard-transcript-cause.md` | 2 min + ask |
| 00010 T2 r1 oos decision | jq missing denies the main session too | already decided (D9) | yes | dismissed | 0.5 min |
| 00010 T2 r1 oos refactor | `cd` vs `cd -P` for the hooks folder, "no failure found" | speculative | no | disc-004, shelf `worktree-guard-hooks-dir.md` | 2 min + ask |
| 00010 T2 r3 (rework) fail R5 | journey ids on two changed suite-header lines | real per R5, conflicts with 39 existing suites | yes | wording round + re-check | 4 min |
| 00010 T2 r3 oos | journey ids on untouched header lines, rule unsettled | real inconsistency; a rules decision | no | disc-006, appended to `comment-id-lint.md` after an ask | 2 min + ask |
| 00010 Phase 1 `discovered_work` | second stop-audit row in `assetlist.md:593` says implementation only | real (text) | no (D8 named three other lines) | disc-001, shelf `asset-list-stop-audit-row.md` | 2 min + ask |
| 00011 T1 r1 fail R2 | empty-array guard needs a reason comment; "Reasoned from bash 3.2 behaviour, not executed" | speculative, and the stated reason turned out wrong | yes | wording round 1 | 6 min |
| 00011 T1 r2 oos | the new comment's reason is wrong (indices form does not error) | real, reproduced by the orchestrator's bash probe | yes | wording round 2 | 5 min |
| 00011 T1 r3 oos | "none" overstates which expansions are guarded | pedantic, real | yes | triage F2 low, patched in rework | part of 17 min |
| 00012 T1 r1 fail item 3 | suite self-run never checks the extractor's exit status | real (test weakness) | yes | behaviour fix round (fresh agent) | 12 min |
| 00012 T1 r1 oos | no presence check beside the negative check | real | yes | folded into the same fix round (right call, against the 3.7 text) | 0 |
| 00012 T1 r2 fail R2 | here-string branch has no reason comment | real (wording rule) | yes | wording resume + re-check | 5 min |
| 00013 T1 oos | a yq warning on stderr with exit 0 would refuse a valid write; "the trigger is hypothetical" | speculative | yes | triage F1 maybe-false, dismissed after probes | 2 min |

**Phase 4 lens findings (score 80 and above)**

| Spec | Finding | Class | Caused by this change | Triage | Cost |
| --- | --- | --- | --- | --- | --- |
| 00010 | RS-1 journey id in a new body comment (medium, conf 100) | real per `rules.md` policy | yes | patch, rework 1 | 13 min rework (shared) |
| 00010 | RS-2 "named worktree" alias (low) | real per glossary | yes | patch, rework 1 | shared |
| 00010 | RL-1 (claimed high) deny rules miss `-Pi` spellings | verified true, but the spec's Assumptions and D6 accepted exactly this gap | no (accepted gap) | medium, deferred to a new HITL shelf file `frontmatter-extract-write-guard.md`, plus a Known gap line | 3 min + a standing HITL item |
| 00010 | RL-2 discovered work: quoted write flags pass the read check | real, reproduced by the orchestrator (18:25 probe), pre-existing | no | disc-005, shelf `read-only-allowlist-flags.md` | 3 min + ask |
| 00012 | RE-1 and RL-1: backtick substitution inside a multi-line double quote is dropped | real regression, reproduced by probe | yes | medium, patched in rework | 20 min, worth it |
| 00012 | RS-1 smell: four quote pairers with different rules; `$'...'` same-line drop | reproduced as pre-existing (base extractor drops it too) | no | medium, shelf `bash-extractor-quote-rules.md` | 3 min |
| 00012 | RS-2 header describes the change not the behaviour (low) | real | yes | patch in rework | shared |
| 00012 | RS-3 discovered work: jq guard now unreachable | false (still exercised by a fixture line) | | dismissed | 1 min |
| 00011, 00013 | no findings | | | | |

**Below the 80 cutoff (`not_checked`, `not_verifiable`)**

- 00011 review-end-state `not_checked`: "with `set -m` active, suites no longer get `/dev/null` as stdin" at "below 80, likely medium". The orchestrator probed it on bash 3.2 and it was a **real regression**, the best catch of all four specs. It was patched as F1. The 80 cutoff put it in the gaps list, not the findings list; only the triage rule "read `not_checked` too" (`review-triage.md:72`) saved it.
- 00010 review-end-state `not_verifiable`: (a) whether Claude Code applies the deny rule, settled by the orchestrator with a live call in 2 min; (b) the real payload shape when a sub-agent's transcript is missing, which became the HITL shelf file `subagent-missing-transcript-path.md` and a Known gap. (b) is speculative: no evidence the host ever omits `transcript_path`.
- 00010 review-targets `not_checked`: line coverage not measurable. Known since 1.1 (D14); still produced the 20.7-min 4.8 ask.
- 00010 review-standards and review-lessons each listed six `not_checked` lines, mostly "file not present" (CODING_STANDARDS.md, CONTRIBUTING.md, GLOSSARY-MAP.md), copied into report.md as known gaps.
- 00012 review-lessons: a suspicion at 60 about `x=${s%% #*}`, a stale comment, a stale cache; no cost beyond reading.
- 00011 review-end-state `not_verifiable`: Ctrl-C at a real terminal, HUP end to end, the `setsid` assumption. All accepted at the retrospective; a real-terminal check would have taken the orchestrator one minute.

**Totals.** 9 lens findings: 1 real regression caused by the change (00012 backtick), 3 real wording items, 1 accepted-by-spec gap reported as high, 2 pre-existing bugs, 1 false. 17 mini-review items: 5 fails (1 behaviour, 4 wording), 10 unique out-of-scope notes of which 3 were in-scope wording, 1 already decided, 4 pre-existing and unproven or speculative, 1 a rules decision, 1 another task's agreed work. Backlog items produced: 6, all from 00010, all moved to the shelf at 5.9; none was started as a next feature. Shelf files produced: 8 new, 5 Later-requests lines.

**The "mid-migration" example.** The phrase does not appear in either transcript, in the four spec folders or on the shelf. The closest matches are: disc-002 ("reachable only with a partial install where `.agents/lib/` is missing while `check-worktree-scope.sh` exists", a half-installed state nobody has seen); the review-end-state gap on a transcript-less sub-agent payload (sent to the human as a HITL item); and the 0.4.7 goal conflict, where the module audit found that the new deny mode landed in the middle of an ordered allow chain and the user was asked three questions (14 min wait). All three fit the pattern the user describes: a state the code could in theory reach, raised without a reproduction, and either shelved or sent back to the user. The evidence agrees with the user on the pattern, with one correction: the two findings that did matter (00011 stdin, 00012 backtick) were also raised by the reviewers, and both were proven by the orchestrator's own probes before they were graded. The problem is not that review finds things; it is that the agents are told to report rather than prove, and the workflow turns every report into a document.

**Did small findings become new specs that take hours?** Not in these four runs: every item went to the shelf, none was promoted. But 00010 itself was the promoted result of six 006 backlog items (spec.md "Origin"), and it took 142 active minutes to fix what those items describe as 1-to-3-file changes. So the pattern the user describes is real one level up: shelf and backlog items from one spec become the next full-path spec.

**Prompt text that drives the pattern**

- Confidence filters hide proven-by-nobody findings in a list that still costs time, and let unproven ones through at 80. `review-end-state.md:43` "Drop every finding under 80. A high-severity suspicion you cannot raise to 80 goes under `not_checked` with what would settle it." Same in `review-standards.md:50` and `review-lessons.md:39`. Nothing requires a run or a test: `review-end-state.md:16` even forbids it ("Run only read-only commands (`git diff`, `git log`, `git show`, `git rev-parse`, `yq` reads)"), so the stdin regression could only be "likely medium" and the `-Pi` finding could be "high, 85" without checking the spec's Assumptions (the lessons lens does not read spec.md: `review-lessons.md:20-27`).
- Discovered work is collected without an evidence bar beyond "concrete evidence", and the lenses are told to report things outside the change: `review-end-state.md:111`, `review-standards.md:140`, `review-lessons.md:107` "A problem you notice in passing that lies outside this change ... carries no severity or confidence and the 80 cutoff does not apply; report it only with concrete evidence." `profile-mini-review.md:57` "A problem you see in passing that no checklist item covers goes in `out_of_scope_noticed`". `implementation.md:64` "Report out-of-scope work; never do it. When you notice a bug, a missing requirement, a refactor you would want ...". The word "refactor you would want" invites disc-004.
- Every note becomes a file. `implementation-orchestrator.md:175` "A non-empty `out_of_scope_noticed` never changes the verdict: hand each entry to Discovered work with origin node `3.7`"; `implementation-orchestrator.md:297` "Never fold it into a task or brief. Assess each entry first"; `discovered-work.md:31,40` "Can wait otherwise ... A can-wait item never blocks the spec, holds no launch and is not asked about" followed by 00.26, which writes a 30-line work item for anything without a shelf match. Three retrospectives in a row (00011, 00012, 00013) carry the same unapplied action item: an out-of-scope note about the task's own lines should be a fix round, not discovered work.
- Triage routes verified-real-but-elsewhere findings into the same machine. `review-triage.md:83` "any finding you verified as real whose fix lies outside the spec's agreed scope ... is discovered work"; `review-triage.md:97` "an all-`maybe-false` entry that would be `medium` or `high` if true" is deferred as a handoff; `review-triage.md:186` "Add the remaining gaps from the lenses the same way: requirements under `not_verifiable` and targets that could not be measured" (this is what produced the transcript-payload HITL file and the line-coverage ask).
- Sign-off makes the stakeholder rule on each one. `sign-off.md:130` "One question per open backlog item", and `deferred-handoff` Write asks whenever a shelf file might match (the disc-006 and 4.8 asks). 5.9 then writes a shelf file per item that is not started.
- Wording rules run before behaviour. `profile-mini-review.md:22` adds the five readable-code lines to every review; `review-standards.md:47` grades a comment "citing a decision record or document" as a hard breach. Three of four specs spent fix rounds on comments.

### Recommendations (findings)

1. **Evidence or silence.** In `review-end-state.md`, `review-standards.md`, `review-lessons.md` (Method step "Try to disprove", and Scoring): allow and require a reproduction for any `medium` or `high` claim: a command run in a scratch worktree, a failing test, or a probe, with the command and output in `evidence`. Replace "Drop every finding under 80" with "report a finding only with a reproduction or a quotable rule; everything else goes under `not_checked` as one line". Lift the read-only restriction to "no writes to the checkout" (a scratch worktree or `/tmp` is fine). Expected effect: the 00011 stdin regression is a finding, the 00013 yq-warning and the transcript-payload items never leave `not_checked`. Time saved: 5 to 10 min of triage per spec. Risk: lenses run longer (a few minutes); the orchestrator already does these probes today.
2. **Give the lenses the spec's accepted gaps.** `review-lessons.md:20-27` inputs: add spec.md Assumptions and Non-goals; score "a gap the spec accepted" at 0. This removes findings like RL-1 in 00010. Risk: none.
3. **In-scope notes are fixes, not discovered work.** `implementation-orchestrator.md:175` and `discovered-work.md` "Assess each report first": an `out_of_scope_noticed` or `discovered_work` entry whose evidence is on lines this task changed, or whose fix is under about ten lines in the task's own files, is handed back to the implementer in the current fix round. This is the action item three retrospectives already carry. Saves one review round per occurrence (5 min). Risk: scope creep is bounded by the line and file limit.
4. **Stop writing a file for every can-wait item.** `discovered-work.md` 00.26: replace the per-item `work-backlog/<spec>-disc-NNN.md` file with one appended line in a single `.workflow/specs/work-backlog/<spec>.md` list (problem, evidence, kind, one line each). `sign-off.md:130` and 5.9: present the list as one question ("start any of these now? otherwise they stay on the list"), and stop converting items to shelf files; a list line is enough until someone picks it up. Removes about 600 lines of paperwork and two asks from a spec like 00010 (8 to 10 min). Risk: less context per item; the design-log entry keeps the evidence.
5. **No new feature from review, by rule.** Add to `review-triage.md` step 4 item 5 and `discovered-work.md` "Assess each report first": an entry of kind `requirement`, `refactor` or `decision` found at 3.7 or 4.4 is logged in one design-log line and goes nowhere else unless the stakeholder names it at 5.5. Only `bug` entries with a reproduction reach the backlog list. Matches the user's rule; removes disc-004 and disc-006 style items. Risk: a real refactor need is still visible in the design log.
6. **Turn the readable-code rules into a lint and take them out of the review.** The shelf already holds `comment-id-lint.md` with the design; build it (journey or decision ids and `.workflow/` paths in body comments). Mark R4 and R5 `tool-covered` in `.workflow/profiles/shell-scripts.md` and `test-harness.md`. Then wording fails happen in the implementer's own toolchain run, not in a review round. Saves 5 to 10 min per spec. Risk: none; it is a grep.
7. **Settle the suite-header journey-id rule once** (disc-006): decide in `rules.md` Cross-cutting policy whether `# Suite:` headers may name journey ids. Until then every changed suite header fails R5. Zero cost, removes a recurring fail.
8. **Treat `not_verifiable` host facts as orchestrator work, not HITL items.** `review-triage.md:186`: a `not_verifiable` line that the orchestrator can settle with one live command (the deny rule, a Ctrl-C at a terminal) is settled in triage; only facts that need another machine or person become a handoff. Risk: none.

## 3. Worktrees

### Evidence

**What the docs say**

- Spec branch: `verification-setup.md:11-26` (full path, 1.1) and `discovery.md:173-175` (light path, 0.3.20): `git switch -c spec/NNN-slug <main>` **in the main checkout**. There is no spec worktree anywhere in the modules. The spec branch is the checked-out branch for the rest of the run: `implementation-orchestrator.md:83` "Check you are on the spec branch", `commit-workflow-data.sh` exits 1 when "the main checkout is off the spec branch".
- Task branch and worktree (full path): `implementation-orchestrator.md:136-141`: `git worktree add .workflow/.worktrees/s<NNN>_t<N> -b task/NNN-slug/T<nn>-<slug> spec/NNN-slug`, off the spec-branch tip, removed after the merge (3.16 step 3). Light path, `:143`: "no task branch; create the worktree detached at the spec-branch tip ... and fast-forward the spec branch to its commits at 3.16". Integration and Phase 1 builds get `wf/NNN-slug/<name>` branches and worktrees the same way.
- Task merge: `implementation-orchestrator.md:196-205`: `rules-setting.sh task_review` is `pr` by default; `open-task-pr.sh` pushes and opens a PR/MR into the spec branch when `origin` is GitHub or GitLab, otherwise prints `skipped: <reason>` and the task merges locally with `git merge --no-ff`. The PR is "a non-blocking review record". `pr-blocking` waits for approval; `local` opens nothing.
- Spec merge: `sign-off.md:216-232`: PR via `gh` or `glab` when `origin` is on GitHub or GitLab, else a local `git merge --no-ff` into main, after a go-ahead ask. Leftover worktrees under `.workflow/.worktrees/` are removed. The spec branch is not deleted.

**What happened**

- 00010 (full path): `git switch -c spec/00010-...` in the clone's main checkout at 17:03; Phase 1 worktree `s00010_phase_1_test_harness` on `wf/...` merged and removed; four task worktrees `s00010_t1/t3/t4/t2` on `task/00010-.../T0x-...` branches, each merged `--no-ff` in id order and removed; task PRs skipped ("origin host is neither GitHub nor GitLab": `origin` is the local path of the primary repo); rework reused a fresh `s00010_t2` worktree; spec merged into the clone's `main` locally at 19:21 (`fa534ee`), then merged into the bugs clone's `main` through a `clone-00010` remote (`469ade4`), then fast-forwarded into the primary with `git fetch ../llm-scaffold-claude-bugs main:main` (primary reflog `main@{0}`). `git worktree list` in the clone now shows only the main checkout; `spec/00010-...` still exists locally.
- 00011-00013 (light path): `git switch -c spec/...` in the bugs clone; one detached worktree `s000NN_t1` per spec, `git merge --ff-only <head_commit>` onto the spec branch, worktree removed, recreated for the rework; no task branch, no PR; each spec merged `--no-ff` into the clone's `main` with the PR body as the message. Three `spec/*` branches remain locally.
- The graph (`git log --graph` in the bugs clone) shows exactly the documented shape: spec branch off main, task merges as bubbles on the spec branch (full path) or straight commits (light path), spec merge bubble into main.

**Gaps between the design, the docs and practice**

| # | Design (as the user states it) | Docs | Practice | Gap |
| --- | --- | --- | --- | --- |
| 1 | The spec gets its own worktree off main | The spec gets a branch, checked out in the main checkout; no worktree | Same as docs; two specs in parallel needed two full clones | Docs and practice both miss the spec worktree |
| 2 | Each task branches off the spec branch in its own worktree and merges back | Full path: yes. Light path: detached worktree, no branch, fast-forward | As docs | Light path has no task branch; fine for one task, but `git log` cannot name the task |
| 3 | The task merge is a PR on a hosted remote, else a local merge as the user decides | `task_review: pr` default; PR only when `origin` is GitHub or GitLab; a local path origin is "skipped" | Every task PR was skipped because `origin` is a local path | The decision is made by host detection, not by the user; with local clones the PR path is dead |
| 4 | The spec gets a PR back to main when complete | Same host detection; local merge otherwise, after a go-ahead ask | Local merges in each clone, then hand-run fetches between clones | Merging main back across clones is outside the workflow and done by hand |
| 5 | Task worktrees are removed once merged | Yes (3.16 step 3, Hand off) | Yes, all removed | None |
| 6 | | Spec branches are never deleted | `spec/00010...` and three others still exist locally; origin still carries `spec/001`-`007` | Branch litter; `discovery.md` 0.1.1 even counts these branches to pick the next number |
| 7 | Parallel specs | Not addressed; 00010's spec.md carries a constraint "Spec 007 is editing `install.sh` ... in parallel: this spec changes neither" | Clones, a `clone-00010` remote, manual fast-forwards | Parallel work is done by stepping around it in the spec text |

**Does `wf_main_root` conflict with a spec worktree?** Yes. `workflow-paths.sh:71-83` resolves the "main checkout" through `git rev-parse --git-common-dir`, which from any linked worktree returns the main checkout's `.git`. Twenty-five scripts, hooks and agent definitions use it (`status-transition.sh`, `commit-workflow-data.sh`, `run-toolchain.sh`, `check-merge-artifacts.sh`, `post-implementation-audit.sh`, `pre-launch.sh`, `session-start-resume.sh`, `implementation.md`, `profile-mini-review.md` and others). So if a spec were a linked worktree: the `.step` marker ("gitignored; main checkout only", `SKILL.md` Route by status) would be read from the main checkout's copy of the spec folder; the implementer's result file would be written to `<main checkout>/.workflow/specs/NNN-slug/artifacts/` (`implementation.md:92`), which on `main` may not even have the spec folder; agent worktrees would be created under the main checkout's `.workflow/.worktrees/`; and `commit-workflow-data.sh` would refuse because the main checkout is not on the spec branch. That is why separate clones were used: a clone has its own `.git`, so everything resolves inside it.

**How to fix it.** Two options, in order of preference:

1. **Resolve the workflow root from the checkout the session runs in, not from the common dir.** Add `wf_project_root <dir>` = `git -C <dir> rev-parse --show-toplevel` and use it for everything that is "workflow data for this spec": `.step`, `artifacts/`, `commit-workflow-data.sh`, the spec-branch check, `.workflow/.worktrees/`. Keep `wf_main_root` only where the main checkout is really meant: the session-start resume offer (list specs across worktrees) and the worktree guard's "is the agent outside its worktree" test, which should compare against the spec worktree, not the main checkout. Agent worktrees then nest under the spec worktree (`<spec worktree>/.workflow/.worktrees/s<NNN>_t<N>`), which git allows. Then 1.1 and 0.3.20 become `git worktree add .worktrees/spec-NNN-slug -b spec/NNN-slug <main>` from the main checkout, and the session `cd`s there (or the user opens the session in it). `install.sh`'s `.gitignore` block gains `.worktrees/`. This is a one-library change plus a sweep of callers; it is the only way to run two specs in one clone.
2. **Keep clones and make them first-class.** Document the clone-per-spec practice, add a `scripts/spec-clone.sh` that clones, sets `origin` to the hosted remote (not the primary's path, so `task_review: pr` works), and a sign-off step that pushes `main` back. Cheaper, but keeps the duplicated cache regeneration and the hand-run fetches.

In both cases, set `task_review` by a stakeholder decision rather than host detection: `local` when the user wants local merges, `pr` when `origin` is hosted; and have 5.8 delete the spec branch after a local merge (or after the PR merges), and 3.16 delete task branches as it does today.

### Recommendations (worktrees)

1. `.agents/lib/workflow-paths.sh`: add `wf_project_root` and switch the per-spec callers to it (list above). Then `verification-setup.md` 1.1 and `discovery.md` 0.3.20 create a spec worktree instead of `git switch -c`. Saves the clone setup, the duplicate 7-min cache regeneration per clone and the manual fetches (10 to 15 min per parallel spec). Risk: medium; every guard and script that assumes "main checkout" needs its tests updated (`tests/hooks/worktree-guard.sh`, `tests/scripts/*`).
2. `rules.md` Workflow settings and `implementation-orchestrator.md:196-205`: when `origin` is not hosted, read `task_review` as `local` and say so once in the design log instead of printing "skipped" per task. Zero time, less noise.
3. `sign-off.md` 5.8 and `discovery.md` 0.1.1: delete `spec/NNN-slug` after the merge lands on main and stop counting branches for the spec number (the Done folder and the top level already hold every number). Risk: a spec branch on `origin` that was not merged is lost; only delete merged branches (`git branch -d`).
4. Light path: give T1 a branch too (`task/NNN-slug/T01-<slug>`) and merge `--no-ff`. Zero time, keeps `git log` honest and lets 4.7 find the task by its merge subject, which the full path relies on (`review-triage.md:151`).

## 4. Other improvements

### What current practice says

- **Specs stay small.** Thoughtworks lists OpenSpec as a lightweight spec layer for agreeing what to build before code is generated ([Thoughtworks Radar](https://www.thoughtworks.com/radar/tools/openspec)). Practitioners describe a two-tier layout, a long-lived feature spec plus a per-change plan ([hamy.xyz](https://hamy.xyz/blog/2026-01_ai-engineering-best-practices)), and one to three pages per spec with explicit out-of-scope lines ([questera.ai](https://www.questera.ai/blogs/spec-driven-development-habits)). The four specs here are about 60 to 80 lines each, which is fine; the surrounding folder is 26 to 84 files and 580 to 2,000 lines of workflow text per spec (measured on `main`), which is not.
- **Test-first agents.** Superpowers enforces red-green-refactor, dispatches a fresh sub-agent per task and runs a two-stage review, spec compliance first then code quality ([emelia.io](https://emelia.io/hub/superpowers-claude-code-framework), [GitHub mirror](https://github.com/buildwithdesi/superpowers)); a Codex guide splits test-writer, implementer and refactorer ([codex.danielvaughan.com](https://codex.danielvaughan.com/2026/04/26/codex-cli-tdd-red-green-refactor-agent-driven-test-first-development/)). The `implementation.md` agent already does this inside one task. What it does not do is what these systems do: keep the review inside the implementer's loop so wording problems are fixed before the diff leaves the worktree.
- **Reviewer calibration.** OpenAI's code-review agent is tuned for precision over recall, accepts lower recall for signal developers trust, and gained both precision and recall by letting the reviewer run code and repo-wide tools instead of reading the diff alone; 46 to 53 percent of its comments lead to a code change ([OpenAI alignment blog](https://alignment.openai.com/scaling-code-verification/)). A secondary source cites Google's Tricorder keeping analyzers only while their effective false-positive rate stayed under 10 percent ([octopus-review.ai](https://octopus-review.ai/blog/your-team-is-ignoring-ai-review-comments)); CodeRabbit traced a tenth of false positives to missing cross-file context ([codeant.ai](https://www.codeant.ai/blogs/ai-code-review-false-positives)); CR-Bench (ICLR 2026) evaluates review agents where false positives are costly ([iclr.cc](https://www.iclr.cc/virtual/2026/10017268)). Measured here: 9 lens findings, 1 regression caught, 4 wording, 3 pre-existing or accepted, 1 false; the best catch sat below the cutoff. The lenses are read-only by instruction, the opposite of what OpenAI found works.
- **Parallel sub-agents and worktree-per-task.** Claude Code's docs describe `isolation: worktree` for sub-agents and session-level worktrees, with automatic cleanup of clean worktrees ([code.claude.com](https://code.claude.com/docs/en/worktrees)); guides warn that worktrees isolate files but not ports or runtime state and that sub-agents touching the same file still conflict at merge ([morphllm.com](https://www.morphllm.com/claude-subagents), [dev.to](https://dev.to/claude_code_security/using-git-worktrees-to-contain-the-blast-radius-of-agentic-coding-tasks-iog)). The scaffold's task-worktree design matches this; the spec-level worktree is the missing piece (section 3).
- **Batching approvals and escalation thresholds.** Approval fatigue is named as the main failure mode of human-in-the-loop designs; the advice is to batch and risk-tier approvals rather than gate every action ([Addy Osmani](https://addyosmani.com/blog/agentic-autonomy-levels/)); autonomy is set per stage, planning can be agent-led for well-scoped tasks, the merge decision still gets an approval ([Augment Code](https://www.augmentcode.com/guides/autonomous-engineering-loop)); the harness-engineering review calls the autonomy level a configurable parameter per task and per tool ([arxiv 2604.08224](https://arxiv.org/pdf/2604.08224)). The scaffold already batches sign-off (D99). It still asks 7 to 15 times per spec, and five of those asks per spec are confirmations ("is this summary right?", "is the deeper prompt ready?", "continue?", "same shelf item?", "retrospective candidates ok?").
- **Risk tiering and skipping ceremony.** Risk-proportional review routes a trivial low-risk change to a one-reviewer scan and everything else to a fuller quorum, with path rules setting the risk floor ([traderspost.io](https://blog.traderspost.io/article/risk-proportional-review-for-ai-agents)); a three-tier "ask before acting" framework ([codeongrass.com](https://codeongrass.com/blog/when-should-your-agent-ask-before-acting-3-tier-risk-framework/)); scoring by blast radius, longevity and ownership ([dev.to](https://dev.to/pyor/risk-based-code-review-tier-rigor-by-blast-radius-352j)). The counter-view, that small agent diffs hide problems and need proof rather than less review ([dev.to](https://dev.to/hedimanai/your-ai-agents-smallest-diffs-are-its-most-dangerous-jp5)), argues for keeping the tests and the reproduction, not the paperwork. The scaffold has two tiers (trivial, light, full) and the light path still runs every ceremony step except Phase 1 and 2: discovery with retrieval and library evaluation, deeper prompt, questioning round, summary confirmation, 3.14 handoff, three lenses, triage, proposals, report, PR body, five sign-off questions, retrospective.

### Recommendations (other)

1. **A real small-change tier.** `SKILL.md` "Size the request" and `discovery.md` 0.3.20: add a `small` path between trivial and light for a backlog item that already names the file, the mechanism and the test (all three of 00011-00013 did): skip `library-evaluation` (it found nothing in four runs), skip the deeper prompt ask, run one questioning round, skip the summary confirmation when every answer was "(Recommended)", run one combined review agent instead of three lenses, write report.md as five lines, and fold the retrospective into the 5.5 ask. Expected: 00013 from 40 to about 20 min, 00011 and 00012 to about 45 to 60 min. Risk: the one regression per spec that review caught must still be caught; keep the reproduction rule from section 2 and the 3.9 gate.
2. **Review inside the worktree, before hand-back.** `implementation.md` Before you stop: let the implementer run the readable-code grep lint and a self-review against the mini-review checklist with the result written into `implementation.yaml`; make the first 3.7 launch a re-check of that self-review rather than a full review. This is what the test-first frameworks do. Saves one mini-review launch per task (2 to 3 min) and most wording rounds.
3. **One combined review agent for light-path specs, with execution rights.** Replace the three light-path lenses with one `review` launch that reads spec.md, rules.md, lessons and the diff, may run commands in a scratch worktree, and reports only reproduced findings. Keeps the four-lens split for the full path where targets and journeys exist. Saves 3 to 5 min per spec and most false or accepted-gap findings. Risk: one agent holds more context; it is a haiku-sized job today (lenses used 14k to 219k output tokens).
4. **Collapse confirmations.** `deeper-prompt` "ready to pass on?" and `questioning-loop.md` 0.3.19 "summary matches?" can be one ask that also carries the first round's questions (the deeper prompt answers were "yes" in all four runs, 0.1 min each, but each is a full round trip). The retrospective's "approve candidates" ask can carry a "Nothing in particular" default when the stakeholder already answered "nothing" at 5.5. Saves 2 to 4 round trips per spec. Risk: none.
5. **Escalation thresholds in the discovered-work rules.** `discovered-work.md` "Assess each report first": ask the stakeholder only for a blocker with a reproduction; file everything else as one line; never write a shelf file from review. Already covered in section 2, listed here because it is the batching rule the sources recommend.
6. **Measure the workflow on itself.** Add the per-spec numbers from this review (gross, waits, launches, harness runs, findings by class) to the retrospective template so the next audit does not need a transcript parser. Zero cost per spec; the data is in `artifacts/`.

## Combined priority list

1. Remove the two asks that stalled both sessions: "continue or fresh session?" (`discovery.md:252-258`) and the repeat suite-gap ask (`implementation-orchestrator.md:282-287`). Biggest wall-clock win, no risk.
2. Evidence-required findings: lenses may run probes and must reproduce `medium` and `high` claims; sub-80 suspicions stay one line (`review-end-state.md:16,43`, `review-standards.md:50`, `review-lessons.md:39`); give the lessons lens the spec's Assumptions. Fixes the false-positive pattern and keeps the real catches.
3. In-scope notes are fixes; can-wait items are one line in one list; no shelf file or backlog file from review; new features never from review (`implementation-orchestrator.md:175,297`, `discovered-work.md` 00.26, `review-triage.md:83,186`, `sign-off.md:130`).
4. Wording findings are applied by the orchestrator, then re-checked; build the comment lint from `comment-id-lint.md` and mark R4/R5 tool-covered (`implementation-orchestrator.md:178-190`, `review-triage.md:151`, profiles).
5. Widen toolchain reuse to the `test` command and exclude Tier A files from the tree hash (`run-toolchain.sh:42-50`); skip the post-merge run after a fast-forward. 10 to 20 min per spec.
6. A `small` path for backlog items that name file, mechanism and test: one round, one review agent, five-line report, retrospective folded into 5.5.
7. Spec worktrees: `wf_project_root` in `workflow-paths.sh`, spec worktree at 1.1 and 0.3.20, `task_review` by decision not host detection, delete merged spec branches at 5.8.
8. Lazy cache regeneration at 0.2.8 and a lighter Phase 1 for multi-module fixes that add no capability.
