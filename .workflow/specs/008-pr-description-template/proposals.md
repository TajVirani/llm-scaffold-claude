# Proposals: PR template for the Sign-off PR

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P3 | `.workflow/capabilities.md` | CAP-### \| Sign-off PR description: sign-off fills `pr-body.md` at 5.4 from the spec's evidence, following the ten-section PR template or the project's host PR/MR template when `pr_template` names one; `check-pr-body.sh` checks its shape, the stakeholder approves the exact text at 5.5, and 5.8 publishes it unchanged as the PR/MR description or the local merge message \| [.workflow/specs/008-pr-description-template](specs/008-pr-description-template/spec.md) | Without it, 0.3.1 would not find this capability when a later request touches PR descriptions or the 5.8 publish, and would treat it as new work | spec.md § Capabilities (CAP-006) | approved | |

## Decisions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/GLOSSARY.md` § Sign-off PR | replace: Its description follows the **PR template**. -> Its description follows the **PR template**, or the project's own PR/MR template when the `pr_template` setting names one. | Without it, an agent reading the glossary would fill the ten workflow sections even when the project chose its own host template, contrary to sign-off 5.4 (D4, D12) | finding F3 (review-standards RS-3) | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P4 | `.workflow/decisions/pitfalls.md` | new entry, newest first: **Name no `.workflow/` path in an installed asset**. What happened: the shipped `assets/pr-template.md` issue stub named `.workflow/deferred/spec-issue-creation.md`, a file only this scaffold repo holds, so every target project's Sign-off PR would cite a dead path (F1, medium, a rework); the T6 fix round then failed mini-review R4 for naming `.workflow/deferred/` in the same template's guidance. Where: `.agents/skills/*/assets/` (installed into target projects). Spec: .workflow/specs/008-pr-description-template. Prevented by: none yet (the shelved lint `.workflow/deferred/comment-id-lint.md`, widened at T6 to asset-template guidance comments) | Without it, a task writing an installed asset would again cite a scaffold-only record, caught only by review | findings F1 (review-standards RS-1); T6 mini-review round 1 (R4) | approved | |
| P5 | `.workflow/decisions/pitfalls.md` | new entry, newest first: **Grep the modules for the old behaviour when a loop-back decision changes a script**. What happened: D19 (from the 4.5 loop-back) made `check-pr-body.sh` project mode read every heading level, but `modules/sign-off.md` 5.4 still said a host template had only `##` headings and that exit 2 meant "no `##` headings"; both review lenses flagged it (F7, F8, medium), costing rework 1. Where: `modules/sign-off.md` 5.4; the 0.5 re-entry and 2.5 task briefs after a loop-back. Spec: .workflow/specs/008-pr-description-template. Prevented by: none yet | Without it, the re-entry task brief names only the script, and prose stating the old contract survives into review | findings F7 (review-end-state RE-1), F8 (review-standards RS-1), review cycle 2 | approved | |
| P6 | `.workflow/decisions/pitfalls.md` § Fork a Phase 1 build's worktree from the spec branch | replace: - Spec: .workflow/specs/003-bash-cache-extractor -> - Spec: .workflow/specs/003-bash-cache-extractor; recurred in .workflow/specs/008-pr-description-template (the 1.2 result files stayed in the `isolation: "worktree"` worktree twice, and a stray `.claude/worktrees/` copy outlived Phase 4; the third 1.2 run, in a worktree under `.workflow/.worktrees/`, wrote its result file in place) | Without the recurrence, the entry reads as a one-off, and the next Phase 1 launch keeps `isolation: "worktree"` instead of the worktree shape that worked | design-log 1.1-1.2 and 4.5 loop-back 1.2 re-entry entries | approved | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/profiles/agent-docs.md` § Toolchain | replace: lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage" -> lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage" | Without it, the 3.5 stop audit of an agent-docs task never runs `lint/step-list` (which `rule_set` and `AGENTS.md` both name), so a broken step list surfaces only at the 3.9 full run | finding F6 (review-targets RT-1) | approved | |
