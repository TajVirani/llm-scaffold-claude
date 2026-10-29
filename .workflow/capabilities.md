<!--
File: Template for .workflow/capabilities.md (Tier A capabilities index). Copied by project-setup; read at 0.3.1; grows at 5.3 (approved proposals only).
Rules:
  - One row per user-facing capability: stable ID `CAP-###` (zero-padded, never reused or renumbered), what the system does for users (WHAT, not HOW), and a link to the spec that introduced it.
  - Only real IDs appear here. A spec in flight uses a provisional `CAP-NEW-<slug>` ID; at sign-off 5.3 the approved proposal takes the next unused CAP-### (highest existing number + 1), adds the row, and rewrites the provisional ID in that spec's files. This keeps parallel specs from claiming the same number.
  - A later spec that changes a capability adds its link to the row's last column; it keeps the ID.
  - A removed capability keeps its row, marked `(retired)` in the description.
-->
# Capabilities

| ID | Description | Introduced by |
| --- | --- | --- |
| CAP-001 | Scoped and parallel harness runs: `tests/run-all.sh` runs the suites a selector file names, or every suite minus an exclude file, in parallel by default with the same report as a serial run | [.workflow/specs/004-scoped-test-runs](specs/004-scoped-test-runs/spec.md) |
| CAP-002 | Review lessons lens: the Phase 4 review checks every change since `baseline_revision` against the project's recorded review lessons, pitfalls and retrospectives (step 4.9, cheap tier, read-only) | [.workflow/specs/002-review-lessons](specs/002-review-lessons/spec.md) |
| CAP-003 | Review lessons written by the retrospective: an approved "watch for X in Y" lesson becomes one entry in `.workflow/review-lessons.md` at 5.7, retired in place once a rule, lint or profile line enforces it | [.workflow/specs/002-review-lessons](specs/002-review-lessons/spec.md) |
| CAP-004 | Graph extractor per work profile: the Tier B cache build runs the graph extractor each work profile names (`graph_extractor`: `bash`, `dependency-cruiser` or `none`) and merges their graphs; a profile without the key is a breaking-change error | [.workflow/specs/003-bash-cache-extractor](specs/003-bash-cache-extractor/spec.md) |
| CAP-005 | Bash graph extractor: a file graph from `source`/`.` lines and script calls, with unresolved calls listed under Unresolved edges and sourced files' functions as Public interface | [.workflow/specs/003-bash-cache-extractor](specs/003-bash-cache-extractor/spec.md) |
| CAP-006 | Sign-off PR description: sign-off fills `pr-body.md` at 5.4 from the spec's evidence, following the ten-section PR template or the project's host PR/MR template when `pr_template` names one; `check-pr-body.sh` checks its shape, the stakeholder approves the exact text at 5.5, and 5.8 publishes it unchanged as the PR/MR description or the local merge message | [.workflow/specs/008-pr-description-template](specs/008-pr-description-template/spec.md) |
