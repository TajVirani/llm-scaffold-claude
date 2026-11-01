---
spec: .workflow/specs/done/00012-extractor-multiline-quotes
date: 2026-10-30
verdict: accepted-with-open-items
---

# Retrospective: The bash graph extractor never reads quoted text as commands

## Summary

- Spec: `.workflow/specs/done/00012-extractor-multiline-quotes/spec.md` (capabilities: CAP-005)
- Report: `.workflow/specs/done/00012-extractor-multiline-quotes/report.md`
- Tasks: 1 done, 0 deferred (one review finding deferred to `.workflow/deferred/bash-extractor-quote-rules.md`)
- Evidence available: spec.md, report.md, tasks.md, design-log.md (questioning round 1, triage pass 1, sign-off), proposals.md, `artifacts/T1/` (fix rounds and rework), `artifacts/gate-3.9-w1/`, `artifacts/gate-3.9-w2/`, `artifacts/sign-off-5.4/`, `artifacts/review/pass-1/`, `artifacts/oracle/oracle-diff.txt`, git `9347768..8c637b1`
- Evidence missing: verification-plan.md not produced (light path); no session logs beyond the design-log entries.

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-005 success: no call from text inside multi-line single quotes (jq incl. `(./x`, awk, plain block) | yes | report.md [E2]; `scripts/extractor-bash` passed=54 |
| CAP-005 success: no call from plain text in multi-line double quotes; `$(...)` and backtick substitutions still reported | yes | report.md [E2]; backticks restored in rework 1 (F1) |
| CAP-005 success: calls after a trailing-comment apostrophe, `'"'"'`, `$'...'` and a quoted `<<` are reported | yes | report.md [E2]; main-session probes |
| CAP-005 success: no `./x` from the suite's own jq program | yes | suite self-check with exit-status and claim checks (fix round 1) |
| CAP-005 success: repo-wide diff shows only removed in-quote edges or restored calls | yes | `artifacts/oracle/oracle-diff.txt`: 437 to 432, five in-quote removals |
| Constraints D1-D4, no new binary, JSON and CLI unchanged | yes | `extractors/bash.sh` diff `9347768..8c637b1`; modules and exports identical in the oracle |
| Constraint: a detected call is never filtered | yes, after rework | F1 found a dropped backtick call; fixed and covered by a suite case |
| Success signal: regenerated cache lists no quoted-text edge | partly | shown by the oracle; the published cache was not regenerated (report.md § Known gaps) |

Built but not asked for: the suite's self-check now asserts the extractor's exit status and that it claims the suite file (mini-review round 1).

## Behavior verification

The extractor ran over the whole repo with the pre-change and final versions on the same tree; only five in-quote records differ (`artifacts/oracle/oracle-diff.txt`). Main-session probes on a scratch repo exercised each quoting rule. The Tier B caches were not regenerated in this spec.

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1 medium: backtick substitution in a multi-line double quote dropped | review-end-state RE-1, review-lessons RL-1 | accept (patched in rework 1) | - |
| F2 medium, pre-existing: same-line call after an escaped quote in `$'...'` dropped; four quote pairers with different rules | review-standards RS-1 | defer | .workflow/deferred/bash-extractor-quote-rules.md |
| F3 low: header described the change | review-standards RS-2 | accept (patched in rework 1) | - |
| Browser gate skipped | 3.14 | defer | .workflow/deferred/browser-suite.md |
| Published architecture cache still lists the five removed edges | report.md § Known gaps | accept: the next regeneration removes them | - |

## Previous-retrospective follow-through

From `.workflow/decisions/retrospectives/00011-interrupted-run-cleanup.md`:

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 1. implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about the task's own lines is a fix round | no | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md` unchanged; applied by hand again in this spec (mini-review round 1's out-of-scope note folded into the behaviour fix round) |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| Putting a repo-wide before/after oracle of the extractor's output in the acceptance criteria made "never drop a call" checkable, and the main session could reproduce it exactly | process note | not recorded elsewhere: specific to output-comparison work |
| A change that hides quoted text can also hide command substitutions written as backticks | review lesson | `.workflow/review-lessons.md` RL-007 |

## Pitfalls

| Failure observed | Where | Prevented by | pitfalls.md entry |
| --- | --- | --- | --- |
| A detected call (backtick substitution) was dropped by the new quote walker | `extractors/bash.sh` | the backtick suite case in `tests/scripts/extractor-bash.sh`; RL-007 | already present ("Report a detected call as unresolved; never filter it out") |

## Feature notes

- The published architecture cache will lose five Unresolved edges (four in `tests/scripts/build-architecture.sh`, one in `tests/scripts/extractor-bash.sh`) at its next regeneration (design-log.md, 2026-10-30 Retrospective notes section)

## Model observations

None.

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| 1. (carried from 00011) implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about lines the task itself changed is handled as a fix round, not discovered work | scaffold maintainer, via a spec on feature-workflow | yes |

## Acceptance verdict

`accepted-with-open-items`: every spec item is met except the success signal's cache regeneration, which is shown by the oracle instead; T1 is `done`; F2 and the browser gate are deferred. The stakeholder approved the work at 5.5 and this verdict at 5.7.

## Open questions

None.
