<!--
Template for the managed block project-standards writes into the target's AGENTS.md (step 7). Copy everything between the two marker lines, inclusive, fill it, and delete every {…} line that has nothing to say. Delete this comment; it is not part of the block.
Rules: pointers, not copies. Each standard lives in one home (.workflow/rules.md, .workflow/profiles/, .workflow/decisions/adr/, .workflow/pr-quality/, .workflow/GLOSSARY.md); the block points at it with a trigger the agent can observe (a path, a file type, a named task). Commands come from the profiles' Toolchain blocks verbatim; a command the obvious guess gets right, and that a manifest already states, earns no line. Codex caps AGENTS.md at 32 KiB, so keep the block short.
Sources: first-party. Section order (Orientation, Where things are, Running and verifying; policy stays in .workflow/rules.md), terse imperative lines, a pointer names an observable trigger, and a provenance line with the verified sha inside begin and end markers adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/references/{template,best-practices}.md@8f0d50e (MIT; pattern only).
-->
<!-- project-standards:begin -->
<!-- verified_at_commit: {40-hex sha} · {date} · Managed by project-standards: text between these markers is replaced on refresh; keep your own lines outside them. -->

## {Project name}

{Two to four sentences: what this is, the stack, where planning lives (.workflow/specs/ through the feature-workflow skill).}

## Where the standards are

- Writing or changing code anywhere: follow `.workflow/rules.md` (ownership, shared core, cross-cutting policy, external systems, required versions).
- Code under `{paths}`: follow `.workflow/profiles/{work-type}.md`.
- Naming a domain concept: use the term in `.workflow/GLOSSARY.md`.
- Changing {area an ADR settled}: read `.workflow/decisions/adr/{NNNN-slug}.md` first.
- Before merging: run the `pr-quality` skill; project checks are in `.workflow/pr-quality/`.
- Read workflow files under `.workflow/` by explicit path; when searching, include hidden dirs (e.g. `rg --hidden`), and read gitignored state like `.step` by path.

## Running and verifying

- {Work type}: lint `{lint}` · typecheck `{typecheck}` · test `{test}`.
- {A caveat the manifest does not state, e.g. a service that must be up first, or a filter flag the obvious command lacks.}
<!-- project-standards:end -->
