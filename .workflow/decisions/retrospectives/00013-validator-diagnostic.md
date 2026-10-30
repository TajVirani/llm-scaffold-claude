---
spec: .workflow/specs/00013-validator-diagnostic
date: 2026-10-30
verdict: accepted-with-open-items
---

# Retrospective: The single writers keep the validator's diagnostic

## Summary

- Spec: `.workflow/specs/00013-validator-diagnostic/spec.md` (capabilities: CAP-009)
- Report: `.workflow/specs/00013-validator-diagnostic/report.md`
- Tasks: 1 done, 0 deferred
- Evidence available: spec.md, report.md, tasks.md, design-log.md (questioning round 1, triage pass 1, sign-off), proposals.md, `artifacts/T1/`, `artifacts/gate-3.9-w1/`, `artifacts/sign-off-5.4/`, `artifacts/review/pass-1/`, git `7b0cceb..205595d`
- Evidence missing: verification-plan.md not produced (light path); no session logs beyond the design-log entries.

## Result against the spec

| Spec item (end state, acceptance, target) | Met | Evidence |
| --- | --- | --- |
| CAP-009 success: broken validator in each writer exits 1 with the diagnostic, file byte-identical, no copy left | yes | report.md [E2]; `scripts/status-transition-tasks` passed=153, `scripts/initiative-transition` passed=80 |
| CAP-009 success: ordinary rejection keeps today's message and code (1 and 2), no yq `Error:` text | yes | report.md [E2] |
| Constraint D1: validators run without `-e`, verdict read from output | yes | diff `7b0cceb..205595d` in both scripts |
| Constraint D2: validator error exits 1; `# Exit:` headers name it | yes | `status-transition.sh` and `initiative-transition.sh` headers |
| Constraint: validator expressions unchanged | yes | validator-text equality check in `tests/scripts/status-transition-tasks.sh` passes |
| Success signal | yes | report.md § Summary |

Built but not asked for: a case for a non-boolean validator result (reported as a validator error), from the implementer.

## Behavior verification

Both suites put a PATH yq shim in front of the real yq that fails only the validator call, and check exit code, diagnostic, file and step marker; ordinary rejections are checked for today's message. A yq release that warns on stderr while exiting 0 was not exercised (probes on v4.54.1 found none).

## Findings

| Finding | Source | Disposition | Link |
| --- | --- | --- | --- |
| F1 maybe-false: a yq warning on stderr with exit 0 would refuse a valid write | T1 mini-review out_of_scope_noticed | accept: no such output on yq v4.54.1; it would fail loudly with the text shown, as D1 chose | - |
| Browser gate skipped | 3.14 | defer | .workflow/deferred/browser-suite.md |

## Previous-retrospective follow-through

From `.workflow/decisions/retrospectives/00012-extractor-multiline-quotes.md`:

| Earlier action item | Landed | Evidence |
| --- | --- | --- |
| 1. (carried from 00011) implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about the task's own lines is a fix round | no | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md` unchanged; this spec's note went to triage as F1 instead |

## Process lessons

| Lesson | Kind | Recorded in |
| --- | --- | --- |
| Probing the tool before the questioning loop turned the backlog item's literal suggestion ("append the validator's stderr") into a better design, since with `-e` yq writes "Error: no matches found" for every ordinary rejection; check a backlog item's suggested mechanism against the real tool before adopting it | process note | not recorded elsewhere: no destination this skill writes fits a general discovery habit |

## Pitfalls

None.

## Feature notes

None.

## Model observations

None.

## Action items

| Item | Owner | Awaiting human application |
| --- | --- | --- |
| 1. (carried from 00011) implementation-orchestrator 3.7: an `out_of_scope_noticed` entry about lines the task itself changed is handled as a fix round, not discovered work | scaffold maintainer, via a spec on feature-workflow | yes |

## Acceptance verdict

`accepted-with-open-items`: every spec item is met and T1 is `done`; the browser gate is a known gap deferred to `.workflow/deferred/browser-suite.md`. The stakeholder approved the work at 5.5 and this verdict at 5.7.

## Open questions

None.
