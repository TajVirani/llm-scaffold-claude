---
spec: .workflow/specs/done/003-bash-cache-extractor
date: 2026-10-26
verdict: accepted-with-open-items
---

# Retrospective: Tier B caches for bash projects

## Summary

- Spec: `.workflow/specs/done/003-bash-cache-extractor/spec.md` (capabilities: CAP-004, CAP-005)
- Report: `.workflow/specs/done/003-bash-cache-extractor/report.md`
- Tasks: 10 done (T1-T10), 0 deferred; `.workflow/deferred/` holds nothing from this spec (spec.md `deferred: []`)
- Evidence available: spec.md, verification-plan.md, report.md, tasks.md, design-log.md (two triage passes, two reworks, the 5.6 change request), proposals.md (P1-P15, all approved), `artifacts/` (per-task toolchain and mini-review rounds, `phase-1-known-bad/`, `gate-3.9-*`, `review/pass-1`, `review/pass-2`, `jrn-005/`, `sign-off-5.4/`), `.workflow/review-lessons.md`, retrospective 004, git `86609a6..e530f63` (68 commits; 24 files outside `.workflow/`, +1948 -61)
- Evidence missing: session logs (process lessons come from design-log.md and this session's record only). Going-in concerns: none ("nothing in particular", design-log 2026-10-26 Sign-off).

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-004 Graph extractor per work profile | yes | report.md Capabilities; JRN-002, JRN-003, JRN-004, JRN-006 suites in `artifacts/sign-off-5.4/toolchain.txt` |
| CAP-005 Bash graph extractor | yes | JRN-001 suite; JRN-005 `artifacts/jrn-005/cache-stamp-check.json` |
| Constraint: bash 3.2 and portable tools, no new runtime dependency | yes | review-end-state pass 2 (no findings); script-lint target |
| Constraint: every extractor prints dependency-cruiser's JSON shape | yes | JRN-004 merge suite; data-model.md Graph JSON |
| Constraint: unresolvable path reported, never guessed; `check-staged-cache.sh` changes only to accept the section | yes | F5, F9, F10 patched (design-log triage passes 1-2); review-end-state pass 2 |
| Constraint: only `--from-json` bypasses profile resolution | yes | JRN-003 suite; T9 edge test `from-json-config-runs-depcruise` |
| Constraint: this repo's profiles change only at 5.3 | yes | P3-P5, P13, P15 applied at 5.3 (proposals.md) |
| Non-goals (no other extractors, no bash boundary checker, no markdown extractor, no install.sh change, no target-profile edits, stamp scope unchanged) | yes | review-end-state pass 2 "Non-goals: none were crossed" |
| Success signal: bash caches built, JS/TS unchanged, this repo's caches fresh without depcruise | yes | JRN-002 byte-identity suite; `artifacts/jrn-005/` (architecture generator `bash`, Boundary violations "Not checked") |
| JRN-001 to JRN-006 | yes | report.md Journeys |
| Six targets (three lints, script and asset coverage, extractor time 0.47 s < 30 s) | yes | `artifacts/review/pass-2/review-targets.yaml` |

Built but not asked for: None. (The bash extractor's quote scanner and continued-line handling in rework 2 serve the F10 patch, CAP-005's "every detected call is an edge or unresolved".)

## Behavior verification

On this repo at `e530f63`, regenerate-caches built modules, flows and architecture through three cache-regeneration launches; each passed `check-staged-cache.sh` and was published, and `cache-stamp-check.sh` exited 0 with all three `fresh` (`artifacts/jrn-005/`). Architecture's Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (bash).` with a committed boundary config and no depcruise. The full harness passed at Head: 2891 passed, 0 failed, 53 suites (`artifacts/sign-off-5.4/toolchain.txt`). Mermaid blocks were checked by hand, not rendered.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| No architecture cache when every profile names `none` | disc-001, T-time 3.4 | accept: tracked as an open backlog item by the stakeholder's 5.5 ruling | `.workflow/specs/work-backlog/003-bash-cache-extractor-disc-001.md` |
| Duplicate test-pattern definitions (F1) | review pass 1 RS-1 | accept: started as spec 005 at 5.9 | `.workflow/specs/005-shared-test-patterns` |
| `case` patterns read as calls (`install.sh:133,187`) | disc-003; still present in the published architecture cache | accept: started as spec 006 at 5.9 | `.workflow/specs/006-bash-case-patterns` |
| Failed depcruise run renders `None.` | disc-004; `build-architecture.sh:248-254,375,381-384` | accept: started as spec 007 at 5.9 | `.workflow/specs/007-boundary-check-failure` |
| Agents module depends on skills its ownership entry forbids (F8) | review pass 2 RS-3; `cache-regeneration.md:36,85,88` | accept: started as spec 008 at 5.9 | `.workflow/specs/008-agents-skill-dependencies` |
| Bare relative glob calls and calls after a lone `&`/`|&` continuation are not detected | rework 2 T3 result, `artifacts/T3/implementation.yaml` | accept: not in the agreed patches; no such line in this repo | - |
| Mermaid not machine-validated | cache-regeneration returns (no `node_modules/mermaid`, `jsdom`) | accept: hand-checked; the repo carries no node toolchain | - |
| flows.md labelling chosen by the agent (`main()` arrows, top-level `main()`) | flows cache-regeneration return | fix now: action item L6 | - |
| Targets measured before rework 2 | report.md Known gaps | accept: rework 2 changed only `extractors/bash.sh` and its suite; lint ran clean in its toolchain and in the 5.4 run | - |
| Commit subjects `T<n>:` instead of Conventional Commits (F11) | review pass 2 RL-3; `.workflow/rules.md:145` | fix now: P14 applied; 5.8 merge subject (L7) | - |

## Previous-retrospective follow-through

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| discovered-work 00.26: match open backlog items by concept before writing one | yes | `8582c50`; `.agents/skills/feature-workflow/modules/discovered-work.md` 00.26 step 2 |
| review-triage step 2: skip `review-targets` on the light path | yes | `.agents/skills/feature-workflow/modules/review-triage.md` step 2 "Light path: no targets lens" |
| Conventional Commits subject for the 5.8 merge of spec/004 | no | main `55413d0` "Merge pull request #1 from TajVirani/spec/004-scoped-test-runs" |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| The Phase 1 `isolation: "worktree"` launch forked from main again and the worktree guard again refused the agent's result file, although a pitfall named exactly this; a warning did not prevent it, the launch itself must change (L2, L3) | skill change | action item L3; `.workflow/decisions/pitfalls.md` "Fork a Phase 1 build's worktree from the spec branch" (already present) |
| After a 5.6 loop back the pass counter restarts at 1, so the lenses' pass folder would overwrite `review/pass-1/`; this run continued the folder numbering by hand (spec 001 precedent) (L4) | skill change | action item L4; design-log "Triage, review pass 2" |
| A re-check reviewer wrote the wrong file name and misread `tree` (L1, L5) | skill change | action item L5; `.workflow/decisions/pitfalls.md` "Write a mini-review re-check to the plain mini-review.yaml" |
| cache-regeneration filled gaps in its flows rules with its own labelling choices, so a rerun can differ (L6) | skill change | action item L6 |
| The repo-on-itself journey (JRN-005) ran only at 5.3 and found the boundary-config gap after review; it needed the 5.3 profile keys, so it could not run earlier (L8) | process note | not recorded as a change: the ordering was forced by D7 |
| The review-lessons lens caught F9/F10 repeating the recorded pitfall "Report a detected call as unresolved", which the first review pass missed | worked well | not recorded: no change needed |
| The 2.1 open question (fold the false `None.` into T9 or file it) kept the change request to two tasks within the 10-task budget | worked well | not recorded: no change needed |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| Re-check reviewer wrote `mini-review-r2.yaml` and reported a false stale `tree` | T9 re-check, `artifacts/T9/` | none yet (action item L5) | added |
| Phase 1 worktree forked from main; result-file write refused by the worktree guard | 1.2 JRN-006 build | none yet (action item L3) | already present |

## Feature notes

- This repo's three Tier B caches were published for the first time at `e530f63` (architecture generator `bash`); stamps and checks in `artifacts/jrn-005/` (design-log.md, 2026-10-26 Retrospective notes section)
- Four backlog items became specs 005-008 at 5.9; disc-001 stays open (design-log.md, 2026-10-26 Retrospective notes section)

## Model observations

| Task type | Host | Observation | Proposal | Goes to |
| --- | --- | --- | --- | --- |
| implementation | claude | T9, T10 passed first launch; T3 rework 2 took three rounds (one behaviour, two reason comments) and the agent caught its own over-broad first fix | none | .workflow/model-map/implementation.md |
| profile-mini-review | claude | caught a real dropped-call bug and two needed comments; one re-check wrote the wrong file name and a false `tree` finding | none | .workflow/model-map/profile-mini-review.md |

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| L3 verification-setup 1.2-1.3: create the Phase 1 worktree off the spec branch as Phase 3's wave start does (no `isolation: "worktree"`), so the result-file write passes the worktree guard | scaffold maintainer | yes |
| L4 review-triage step 1: pass folders keep a sequence that never restarts after a loop back, while the 4.6 pass count stays per cycle | scaffold maintainer | yes |
| L5 profile-mini-review Re-check rule: write the plain `mini-review.yaml`; `toolchain.json` `tree` is run-toolchain's content hash, never compared with a git tree id | scaffold maintainer | yes |
| L6 cache-regeneration: pin the flows labelling rules (arrow label for a script run as a command, name for top-level code) so reruns match | scaffold maintainer | yes |
| L7 Use a Conventional Commits subject for the 5.8 merge of spec/003 (F11) | orchestrator at 5.8 | no |

## Acceptance verdict

`accepted-with-open-items`. Every capability, constraint, non-goal, journey and target is met, with evidence above, and all 10 tasks are `done`. Known gaps remain and are tracked: disc-001 open, four items started as specs 005-008, two undetected call forms and hand-checked Mermaid accepted. The stakeholder approved the work at 5.5 ("Yes, approve").

## Open questions

None.
