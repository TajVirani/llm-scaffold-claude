---
origin_spec: .workflow/specs/done/00010-worktree-guard-followups
created: 2026-10-30
severity: medium
---

# Frontmatter extract write guard

**Summary:** Every spelling of an in-place `yq --front-matter=extract` call is refused, not only the ones the settings deny rules match by text.
**Mode:** HITL
**Origin:** [00010-worktree-guard-followups](../specs/done/00010-worktree-guard-followups/spec.md), 4.8 review finding F3, design-log entry 2026-10-30 Triage, review pass 1

## Goal

A Claude session in an installed project cannot rewrite a markdown file down to its frontmatter through `yq --front-matter=extract` with an in-place flag, whatever the flag spelling, while plain extract reads keep running without a prompt.

## Background

Spec 00010 added four `permissions.deny` rules that refuse `yq --front-matter=extract` with `-i` or `--inplace` before or after the extract option, beside the existing prefix allow for extract reads. Permission rules match command text and cannot express "this prefix, but no in-place flag", and an allowlist of exact read forms cannot be written with glob wildcards either, so other spellings stay open. The stakeholder accepted that gap as accident prevention (spec Assumptions, D6) and ruled a main-session hook out of scope for 00010. Closing it needs a PreToolUse check that parses the command, which is a design decision of its own.

**Current behaviour:** `yq --front-matter=extract -i ...`, `... -i` after the option, and the two `--inplace` forms are denied (confirmed live in a Claude Code session on 2026-10-30). A combined short flag such as `-Pi`, `--inplace=true`, or a call through a variable or a script passes the prefix allow with no prompt.

**Desired behaviour:** any `yq` call that combines front-matter extract mode with in-place writing is denied or prompted, in the main session and in sub-agents; extract reads without an in-place flag still run without a prompt.

## Constraints

- Bash 3.2 and the existing hook shape (thin adapter, shared logic in a skill script), per ADR-0001.
- A review lesson (RL-005) warns against regex denylists of a tool's write forms; prefer recognising the read forms.

## Decisions already made

- Deny rules in the settings template, not an installer change (design-log D6 in [.workflow/specs/done/00010-worktree-guard-followups/design-log.md](../specs/done/00010-worktree-guard-followups/design-log.md)).
- A main-session yq hook was not asked for in 00010 (Deeper prompt, Not asked for).

## Evidence

- Allow `Bash(yq --front-matter=extract:*)` and the four deny rules at the top of `permissions.deny` in `.agents/hooks/claude-settings.template.json` and `.claude/settings.json`, as of commit `6d40286`. Verdict medium, verified: the deny patterns need ` -i` or ` --inplace` as typed, so `-Pi` matches none of them (review-lessons RL-1, triage F3).
- Pitfall "Edit frontmatter with Edit or `yq --front-matter=process`, never `--front-matter=extract -i`" in `.workflow/decisions/pitfalls.md`.

## Acceptance criteria

- [ ] `yq --front-matter=extract -Pi '.a = 1' f.md` and `yq --front-matter=extract --inplace=true '.a = 1' f.md` are refused in a main session and in a sub-agent.
- [ ] `yq --front-matter=extract '.status' f.md` runs without a prompt.
- [ ] A test feeds each spelling to the check and asserts the verdict.

## Out of scope

- `yq --front-matter=process -i`, which keeps the body and stays allowed.
- Other tools' in-place flags.
