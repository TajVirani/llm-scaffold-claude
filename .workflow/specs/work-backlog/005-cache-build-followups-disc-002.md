---
origin_spec: .workflow/specs/005-cache-build-followups
origin_step: "3.4"
discovered_at: 2026-10-28
status: dismissed
kind: decision
---

# Architecture build timing target sits inside run-to-run noise

## Problem

TGT-001 caps the architecture cache build for this repo's published scope at 1.2 s, best of 3. The baseline already measures 1.15-1.26 s, and a run on a busy machine reaches 1.34-1.67 s, so the target can pass or fail on noise alone, whatever the change does. The threshold needs either headroom or a measurement that compares against the baseline on the same machine and run.

## Evidence

- T4 implementation return (`artifacts/T4/implementation-r1.yaml`, discovered_work), quoted: "build-architecture.sh --cache architecture over architecture_oracle_scopes: HEAD~1 copy 1.59/1.15/1.22 s, HEAD copy 1.67/1.20/1.17 s; extractor alone old .90/.83/.84 s vs new .87/.86/.85 s".
- 1.1 baseline measurement: 1.16-1.26 s (verification-plan.md Targets, TGT-001).

## Why not a blocker

The extractor change costs nothing measurable (0.85 s before and after), so CAP-005 and JRN-001, JRN-002 are met either way. Only the 4.3 measurement of TGT-001 can flip on noise; the review lens reports the number and the stakeholder judges it at sign-off.

## Suggested scope and size

- Scope: a timing-target convention for this repo (relative to a baseline run in the same session, or a headroom rule), and TGT-001 restated with it; or speed up the build so 1.2 s has margin. Leaves out other targets.
- Size: 1 task or a decision only; far within 10 tasks and 30 files.

## Links

- Origin spec: [spec.md](../005-cache-build-followups/spec.md)
- Design log entry: [design-log.md](../005-cache-build-followups/design-log.md) (section 2026-10-28 Discovered work: TGT-001 noise)
