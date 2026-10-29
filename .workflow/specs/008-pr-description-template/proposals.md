# Proposals: PR template for the Sign-off PR

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Decisions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/GLOSSARY.md` § Sign-off PR | replace: Its description follows the **PR template**. -> Its description follows the **PR template**, or the project's own PR/MR template when the `pr_template` setting names one. | Without it, an agent reading the glossary would fill the ten workflow sections even when the project chose its own host template, contrary to sign-off 5.4 (D4, D12) | finding F3 (review-standards RS-3) | proposed | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/profiles/agent-docs.md` § Toolchain | replace: lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage" -> lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage" | Without it, the 3.5 stop audit of an agent-docs task never runs `lint/step-list` (which `rule_set` and `AGENTS.md` both name), so a broken step list surfaces only at the 3.9 full run | finding F6 (review-targets RT-1) | proposed | |
