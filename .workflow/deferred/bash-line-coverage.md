---
origin_spec: .workflow/specs/005-cache-build-followups
created: 2026-10-28
---

# Bash line coverage

**Summary:** The scaffold can measure line coverage of its bash scripts, so a coverage target in a verification plan can be checked.
**Mode:** HITL
**Origin:** [005-cache-build-followups](../specs/005-cache-build-followups/spec.md), 4.8 review finding (remaining gap: target TGT-007 not measurable), design-log entry 2026-10-28 Triage, review pass 1

## Goal

A verification plan for a shell-scripts change can set a line-coverage threshold for the changed code, and the targets review lens reads a number for it instead of reporting it not measurable.

## Background

Spec 005 set a coverage target for its changed shell code at 1.1. No bash coverage tool is installed, and the spec's constraints ban new dependencies, so the stakeholder ruled the target not measured and recorded the reason. Coverage stays unmeasured for every shell-scripts change until a tool is adopted, which is a dependency decision a human must make.

**Current behaviour:** the shell-scripts profile has no coverage command; a coverage target is always `not_measurable`, and the per-script test-harness checklist at the mini-review stands in for it.

**Desired behaviour:** the shell-scripts profile names a coverage command whose machine output gives line coverage for a list of files, run by the homegrown harness under bash 3.2.

## Constraints

- Scripts and the harness stay bash 3.2 compatible.
- Adopting a coverage tool is a new dependency: it goes through the library-evaluation step and `.workflow/rules.md` required versions.

## Decisions already made

- TGT-007 recorded as not measurable by stakeholder decision at 1.1 ([.workflow/specs/005-cache-build-followups/verification-plan.md](../specs/005-cache-build-followups/verification-plan.md), Targets).

## Evidence

- TGT-007 row of the Targets table at `.workflow/specs/005-cache-build-followups/verification-plan.md:60` as of commit `b98e62b`; review-targets pass 1 measured it `not_measurable` (`.workflow/specs/005-cache-build-followups/artifacts/review/pass-1/review-targets.yaml`).

## Acceptance criteria

- [ ] A coverage tool is chosen and recorded with its required version.
- [ ] The shell-scripts profile Toolchain names a coverage command that prints line coverage for the given files.
- [ ] Running it on a script with a known test suite gives a number above 0.
- [ ] `tests/run-all.sh` passes.

## Out of scope

- Coverage for markdown skills and agent definitions.
- Raising existing suites to any coverage threshold.
