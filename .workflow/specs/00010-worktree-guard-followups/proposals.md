# Proposals: Worktree guard and upgrade follow-ups

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-### \| In-place frontmatter extract denied: the shipped Claude settings deny `yq --front-matter=extract` combined with `-i` or `--inplace` (before or after the option) while extract reads stay allowed; `install.sh` merges the rules into a target's `.claude/settings.json` \| [.workflow/specs/00010-worktree-guard-followups](specs/00010-worktree-guard-followups/spec.md) | Without it, 0.3.1 would not find this capability when a later request (such as the deferred frontmatter-extract-write-guard) changes how in-place extracts are refused, and would mint a duplicate | spec.md § Capabilities (CAP-010) | approved | approved as written (5.3) |
| P2 | `.workflow/capabilities.md` (CAP-007 row) | Append to the description: "; a confined implementation or integration agent whose agent worktree cannot be established (bad or missing header, missing transcript or worktree, cwd outside the repo) is denied every call, and the guard fails closed on an unparsable payload or a missing jq"; add [.workflow/specs/00010-worktree-guard-followups](specs/00010-worktree-guard-followups/spec.md) to Introduced by | Without it, 0.3.1 would read CAP-007 as allowing an unconfinable agent and could reframe a later request against the old behaviour | spec.md § Capabilities (CAP-007), D3, D4, D9, D10 | approved | approved as written (5.3) |
| P3 | `.workflow/capabilities.md` (CAP-008 row) | Append to the description: "; a `$` or backtick inside single quotes passes (`sed -n '$p' f`), while `$`, a backtick or a backslash outside single quotes still needs the `cd`"; add the spec link to Introduced by | Without it, 0.3.1 would still read CAP-008 as denying every `$`, and a later request to allow quoted reads would be framed as new work | spec.md § Capabilities (CAP-008), D5 | approved | approved as written (5.3) |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P4 | `.workflow/decisions/pitfalls.md` § "Edit frontmatter with Edit or `yq --front-matter=process`, never `--front-matter=extract -i`" | Replace "Prevented by: none yet" with "Prevented by: partly: four `permissions.deny` rules in the settings template and `.claude/settings.json` refuse `yq --front-matter=extract` with `-i` or `--inplace` (spec 00010, confirmed live); other spellings such as `-Pi` stay open (`.workflow/deferred/frontmatter-extract-write-guard.md`)" | Without it, the retrospective and review-lessons lens would keep treating this pitfall as unguarded and raise it again, as review pass 1 of spec 006 did | finding F3, design-log D6 | approved | approved as written (5.3) |
