<!--
File: Template for .workflow/specs/NNN-slug/report.md: the 5.4 results report. No frontmatter.
Written by modules/sign-off.md at 5.4; read by the stakeholder at 5.5 and by the `retrospective` skill at 5.7.

Rules:
  - Nothing is claimed that has not been verified (design rule 12). Every PASS links evidence: a file under artifacts/, a CI run, or command output pasted from the run.
  - Report real numbers. A target that was not measured says "not measured" and why, never an estimate.
  - A skipped gate is a gap, never a pass. Light-path suite gaps (3.14) are listed under Known gaps even when everything else passed.
  - Evidence references: [E1], [E2], ... numbered in order of first use, each resolving to a path, URL or pasted output in the Evidence section.
  - Delete this comment in the finished file. Write "None." in a section with nothing to report rather than deleting it.
-->

# Report: <feature title>

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `<baseline_revision>` · Head: `<sha>`

## Summary

<Two or three sentences: what shipped, the overall result, and the most important gap. No claim here that the sections below do not back.>

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-### <name> | PASS / FAIL / BLOCKED / not verified | [E<n>] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `<command>` | <passed / failed / total; exit code> | [E<n>] |
| CI | <pipeline name> | <green / red> | [E<n>] <run URL> |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T<n> | clean | [artifacts/T<n>/](artifacts/T<n>/) |

## Targets vs measured

<!-- One row per target in verification-plan.md "Targets"; values from review-targets (4.3). -->

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| <target> | <threshold> | <number with unit, or "not measured: <reason>"> | PASS / FAIL / not measured | `<command>` | [E<n>] |

## Journeys

<!-- One row per JRN-### in verification-plan.md. Evidence is filed by run and journey id under artifacts/ (3.12). -->

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 <name> | PASS / FAIL / not exercised | [screenshots, trace, console and network logs](artifacts/<run>/JRN-001/) |

Behaviour verification: <what was exercised end to end against the running build and what was observed, or "Runtime behaviour was not exercised: <reason>.">

## Review outcome

- Review passes: <n> (rework ceiling 5) · Findings: <n> patched, <n> deferred, <n> dismissed with reason (see design-log.md triage entries)
- Follow-up review recommended: <yes / no, with the reason>

## Known gaps

- <Gate skipped or check not run>: <reason>. Handoff: [.workflow/deferred/<slug>.md](../../deferred/<slug>.md)

## Deferred

- [.workflow/deferred/<slug>.md](../../deferred/<slug>.md): <one line> (<severity if a review finding>)

## How to verify

1. <command or action the stakeholder can run>
2. <expected result>

## Evidence

- [E1] <path under artifacts/, CI run URL, or command with its pasted output>
