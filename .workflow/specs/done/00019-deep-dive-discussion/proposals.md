# Proposals: Hold the deep dive at once, as a discussion that reaches agreement

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-017 \| Deep dive held at once: picking "Talk it through (deep dive)" on a questioning round question starts the deep dive straight after the round is logged (inside 6.5 on the large path); the agent says back the question and its recommendation's reason and asks where that is wrong, the two go back and forth in chat until the stakeholder's explicit yes to a written agreed statement, which is the logged decision; every other answer in the round is then checked against it, only the contradicted ones re-asked; a deep dive cut off by a session end is resumed first; the retrospective counts each deep dive exchange as a wait \| [.workflow/specs/done/00019-deep-dive-discussion](specs/done/00019-deep-dive-discussion/spec.md) | Without it, 0.3.1 would not see that the deep dive is a held discussion with an agreed statement, and a later request about deep dives (for example offering them at other asks) would be framed as new instead of as a change to this capability | spec.md § Capabilities | approved | approved at 5.5 as written; assigned CAP-017 |
