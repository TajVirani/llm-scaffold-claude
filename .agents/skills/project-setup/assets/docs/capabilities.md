<!--
File: Template for .workflow/capabilities.md (Tier A capabilities index). Copied by project-setup; read at 0.3.1; grows at 5.3 (approved proposals only).
Sources: first-party; CAP entry idea (id, intent) adapted from bmad-code-org/BMAD-METHOD skills/bmad-spec/assets/spec-template.md (MIT).
Rules:
  - One row per user-facing capability: stable ID `CAP-###` (zero-padded, never reused or renumbered), what the system does for users (WHAT, not HOW), and a link to the spec that introduced it.
  - Only real IDs appear here. A spec in flight uses a provisional `CAP-NEW-<slug>` ID; at sign-off 5.3 the approved proposal takes the next unused CAP-### (highest existing number + 1), adds the row, and rewrites the provisional ID in that spec's files (D44). This keeps parallel specs from claiming the same number.
  - A later spec that changes a capability adds its link to the row's last column; it keeps the ID.
  - A removed capability keeps its row, marked `(retired)` in the description.
-->
# Capabilities

| ID | Description | Introduced by |
| --- | --- | --- |
| CAP-001 | {User or system can do X to achieve Y.} | [.workflow/specs/NNN-slug](specs/NNN-slug/spec.md) |
