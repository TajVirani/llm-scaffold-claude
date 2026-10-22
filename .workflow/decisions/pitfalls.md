<!--
File: Template for .workflow/decisions/pitfalls.md (Tier A). Copied by project-setup; written at 5.7 by the retrospective skill, with approval.
Rules:
  - Admit a pitfall only when something actually went wrong. A suspicion or a trap-looking fact is not an entry.
  - Remove an entry only when the thing it is about is gone, or a tool now enforces it. Never remove it because it has not recurred.
  - Each entry is a terse imperative that names the permitted alternative, plus the four fields below.
Entry shape (newest first):

## {Short imperative title}
- What happened: {the observed failure}
- Where: {file or area}
- Spec: {.workflow/specs/NNN-slug}
- Prevented by: {the rule or check that now prevents it, or "none yet"}
-->
# Pitfalls

## Edit frontmatter with Edit or `yq --front-matter=process`, never `--front-matter=extract -i`
- What happened: `yq --front-matter=extract -i` rewrote two work-backlog items as their frontmatter alone, deleting the body; one was restored from git, the other from the session.
- Where: main-session status edits of `.workflow/specs/work-backlog/*.md` (00.26, 5.9)
- Spec: .workflow/specs/004-scoped-test-runs
- Prevented by: none yet

## Quote heredocs that write markdown (`<<'EOF'`), or use Write
- What happened: an unquoted `<<EOF` holding markdown ran its backticked code spans as shell commands and hung the shell, leaving an empty `.workflow/deferred/` file.
- Where: main-session Bash writes of `.workflow/` markdown (3.14)
- Spec: .workflow/specs/004-scoped-test-runs
- Prevented by: none yet

## Point at a folder instead of restating its tree in the README
- What happened: the README's hooks and helper-script lists drifted from the tree; `worktree-write-guard.sh` and five helper scripts are missing.
- Where: `README.md` (hooks and helper lists)
- Spec: none (found by project-standards discovery, 2026-10-21)
- Prevented by: `.workflow/rules.md` § Cross-cutting policy (the README never restates the tree)
