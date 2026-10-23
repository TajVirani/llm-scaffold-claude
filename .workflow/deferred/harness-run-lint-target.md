---
origin_spec: .workflow/specs/002-review-lessons
created: 2026-10-22
---

# Lint targets that run through the harness runner

**Summary:** A Targets row whose command runs a work type's lint suites through the test runner is reported "not measurable" by the targets lens, so that lint never appears as measured in the sign-off report even though the 3.9 gate ran it green.
**Mode:** AFK
**Origin:** [002-review-lessons](../specs/002-review-lessons/spec.md), 4.8 review finding (gap F4), design-log entry 2026-10-22 Triage, review pass 1

## Goal

A project whose lint for a work type is a set of suites run by its test runner can either state that lint as a target the targets lens measures from the runner's machine output, or the rule for filling the Targets table says such a lint is proven by the 3.9 gate and is never a row. Either way the sign-off report never shows a green lint as a gap.

## Background

In this repo the agent-docs profile's `lint` key is four lint suites run through `tests/run-all.sh --suite ...`. Verification setup put that command in the Targets table as an errors row, while the same step's rule says a target never names the test harness. The targets lens applied the rule and recorded the row as not measurable; the workflow treats every such row as a gap, never a pass. The four suites had already run green inside the last-wave 3.9 gate, so the gap is a reporting artefact of how the row was written, not a missing check.

**Current behaviour:** the row is measured by nobody at 4.3 and reported as a gap at 5.4, although the gate proved it.

**Desired behaviour:** the Targets rule, or the lens, handles a lint that lives behind the test runner: the row is either excluded at 1.1 with the pointer to the 3.9 evidence, or measured by reading the runner's `RESULT` or `PASS` lines for the named suites.

## Constraints

- `review-targets` reads numbers only from a tool's machine output and runs exact commands; it makes no judgement calls.
- The 1.1 rule that a target never names the test harness or its pass count stays unless the stakeholder changes it at 5.3.

## Decisions already made

- Targets filled at 1.1 of 002-review-lessons with the agent-docs lint row sourced from the profile's `lint` key (design-log 2026-10-22, Phase 1 note, in [design-log.md](../specs/002-review-lessons/design-log.md)).

## Evidence

- `verification-plan.md` § Targets row 3 and `artifacts/review/pass-1/review-targets.yaml` (`result: not_measurable`, reason "the harness is proven at 3.9, not a target; the command runs tests/run-all.sh"), in `.workflow/specs/002-review-lessons/`, as of commit `be7638e87ae5146fcf2d85f2d059d079d85ae628`.
- `artifacts/gate-3.9-w2/toolchain.txt` in the same folder: `PASS lint/frontmatter`, `PASS lint/step-list`, `PASS lint/symlinks`, `PASS lint/upstream-lineage` in the full run (44 suites, 2588 passed), same commit.

## Acceptance criteria

- [ ] `modules/verification-setup.md` 1.1 says what to do with a profile `lint` key that runs suites through the test runner (exclude it and point at the 3.9 gate, or name the measurable form), or `review-targets` measures such a row from the runner's output.
- [ ] A later spec with an agent-docs lint row shows it as measured or absent in "Targets vs measured", never as not measurable.

## Out of scope

- The harness runner itself and its parallel timing assertion (shelved separately).
- Performance targets (see `session-start-timing-target.md`).
