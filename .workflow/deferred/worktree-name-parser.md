---
origin_spec: .workflow/specs/006-result-file-guard
created: 2026-10-29
---

# Worktree-name parser

**Summary:** Hooks that read an agent worktree name back into its spec number, task or work type use one shared parser instead of their own regexes.
**Mode:** AFK
**Origin:** [006-result-file-guard](../specs/006-result-file-guard/spec.md), 0.3.17 scope decision, design-log entry 2026-10-29 Scope decision: worktree-name parser

## Goal

Building and parsing an **Agent worktree** name (`s<NNN>_t<N>`, `s<NNN>_phase_1_<enc(work type)>`, `s<NNN>_integration_<enc(work type)>`, and the Codex review and initiative forms) agree everywhere because both sides come from the same shared code.

## Background

Spec 006 moves the name encoder and builder into `.agents/lib/workflow-paths.sh` (D15). Parsing names back was found by the hooks module audit and left out: the spec's goal is result files and confinement, and the builder can land without moving the parsers.

**Current behaviour:** three hooks parse names with their own regexes, and two of them map an encoded work type back to a profile by encoding every profile and requiring one match.

**Desired behaviour:** one lib function parses a name into its kind, spec number and task or encoded work type, and one resolves an encoded work type to its profile; every hook uses them, and the accepted forms are listed once.

## Constraints

- `.agents/lib/` is shared core: it changes only through the integration agent.
- Names stay byte-identical to what Codex orchestrators already create.
- bash 3.2; helpers return a status and never exit.

## Decisions already made

- Encoder and builder live in `workflow-paths.sh`, pinned to `LC_ALL=C` (design-log D15 in [.workflow/specs/006-result-file-guard/design-log.md](../specs/006-result-file-guard/design-log.md)).

## Evidence

- Parsers: `.agents/hooks/post-implementation-audit.sh:127-165`, `.agents/hooks/codex-pre-spawn.sh:124-158`, `.agents/hooks/codex-write-guard.sh:114-115`, as of commit `02bc218`.
- Reverse work-type lookup copies: `codex-pre-spawn.sh:115-122`, `post-implementation-audit.sh:141-151`, as of `02bc218`.

## Acceptance criteria

- [ ] No hook contains its own regex for agent worktree or Codex `task_name` forms.
- [ ] A suite case per name form shows the parser returns kind, spec number and task or work type, and rejects malformed names.

## Out of scope

- Building names (spec 006).
- The Codex profile-lookup mismatch (`.workflow/deferred/codex-spawn-profile-lookup.md`).

## Later requests

- .workflow/specs/006-result-file-guard, 3.7: the mapping from launch header to worktree kind (task, phase_1 or integration) is written twice, in `worktree-write-guard.sh` and `post-implementation-audit.sh` (T1 mini-review, `artifacts/T1/mini-review.yaml` out_of_scope_noticed).
