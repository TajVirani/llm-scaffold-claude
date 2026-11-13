# Proposals: Per-run session handoffs

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-015 \| Per-run session handoffs: the `handoff` skill writes each session handoff as a new file `<NNN-slug or topic>--<UTC time>-<4 chars>.md` in `.workflow/.handoff/` of the checkout the session works in, a folder whose own `.gitignore` keeps it out of git; a handoff named by path is resumed without asking and deleted by the session that resumed it; the session-start offer lists the session's own checkout's handoffs first, then the other checkouts' by absolute path \| [.workflow/specs/done/00016-per-run-handoffs](specs/done/00016-per-run-handoffs/spec.md) | Without it, 0.3.1 would not see that per-run handoffs exist, and a later request (the automatic hand off and reload loop) would be framed as new instead of as a change to this capability | spec.md § Capabilities | approved | |
