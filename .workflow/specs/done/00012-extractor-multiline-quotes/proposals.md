# Proposals: The bash graph extractor never reads quoted text as commands

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` § CAP-005 row | replace: `CAP-005 \| Bash graph extractor: ... sourced files' functions as Public interface \| [003]` -> `CAP-005 \| Bash graph extractor: a file graph from `source`/`.` lines and script calls, with unresolved calls listed under Unresolved edges and sourced files' functions as Public interface; quoted text, including strings that span lines, is never read as a call, and a command substitution inside double quotes is \| [.workflow/specs/done/003-bash-cache-extractor](specs/done/003-bash-cache-extractor/spec.md), [.workflow/specs/done/00012-extractor-multiline-quotes](specs/done/00012-extractor-multiline-quotes/spec.md)` | Without it, 0.3.1 of a later request about false or missing edges from quoted text would not find that CAP-005 already promises quote-aware reading, and would mint a new capability or miss the spec that set the rules (D1-D4) | spec.md § Capabilities (CAP-005 changed) | approved | |
