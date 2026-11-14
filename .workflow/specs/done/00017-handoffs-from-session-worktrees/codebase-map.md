# Codebase map: Handoffs found from session worktrees

Affected area: hooks (`.agents/hooks`, `session-start-resume.sh`); standalone-skills (`.agents/skills/handoff`); lib (`.agents/lib/workflow-paths.sh`, read only); feature-workflow (`.agents/skills/feature-workflow/SKILL.md`); tests (`tests/hooks/audit-sync-resume.sh`, `tests/scripts/handoff-skill.sh`).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| session-start hook: checkout roots | `root` = `wf_main_root(cwd)`; `here` = `wf_project_root(cwd)`, which maps a checkout under `.claude/worktrees/` or `.workflow/.worktrees/` to the checkout holding it | `.agents/hooks/session-start-resume.sh:67-72` |
| spec scan checkouts | scans `here`, every worktree on a `refs/heads/spec/*` branch, then `root`; a worktree on another branch (e.g. `claude/<name>`) is not listed | `.agents/hooks/session-start-resume.sh:75-83` |
| handoff: own checkout | `own_checkout` = `git -C "$cwd" rev-parse --show-toplevel`: the top of the session's cwd, whatever kind of checkout | `.agents/hooks/session-start-resume.sh:99-101` |
| handoff: other checkouts | own = main → other = spec worktrees only; otherwise other = main only, so a session worktree never sees spec worktrees' handoffs | `.agents/hooks/session-start-resume.sh:102-107` |
| handoff listing | own group first as `.workflow/.handoff/<name>`, others by absolute path; newest first by mtime; at most 3 listed | `.agents/hooks/session-start-resume.sh:131-171` |
| resume offer text | a spec in another checkout is resumed by moving in (EnterWorktree on Claude Code); handoffs go to the handoff skill's Resume | `.agents/hooks/session-start-resume.sh:346-353` |
| header comment of the rule | "any other checkout sees only the main checkout's, so a run never picks up a sibling worktree's handoff" | `.agents/hooks/session-start-resume.sh:96-98` |
| `wf_main_root` | common dir basename `.git` gives its dirname; else first line of `git worktree list` | `.agents/lib/workflow-paths.sh:128-140` |
| `wf_project_root` | top level; owner when `dirname(top)` ends in `/.workflow/.worktrees` or `/.claude/worktrees`; folder shape only, never branch | `.agents/lib/workflow-paths.sh:144-161` |
| path constants | `WF_HANDOFF`, `WF_SPEC_WORKTREES`, `WF_ISOLATION_WORKTREES=.claude/worktrees` | `.agents/lib/workflow-paths.sh:113-118` |
| handoff Locate (Write step 1) | writes to `$(git rev-parse --show-toplevel)/.workflow/.handoff`, so a session worktree's handoff lands in that worktree; self-contained, calls no script | `.agents/skills/handoff/SKILL.md:21-35` |
| handoff Resume drift step | `root` from `git rev-parse --show-toplevel` | `.agents/skills/handoff/SKILL.md:77-81` |
| feature-workflow "Work in the spec checkout" | when the session is elsewhere, move in with EnterWorktree; no mention of session worktrees | `.agents/skills/feature-workflow/SKILL.md:52` |
| confinement rule, same folder shape | a cwd under `.claude/worktrees/` is its own confinement root for sub-agents | `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:18-19` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `wf_main_root DIR` | prints main checkout root; status 1 outside git | session-start hook; feature-workflow scripts; `tracker-adoption.sh:83` | `.agents/lib/workflow-paths.sh:128` |
| `wf_project_root DIR` | prints the checkout holding workflow data; status 1 outside git | session-start hook; `issue-tracker.sh:373` | `.agents/lib/workflow-paths.sh:144` |
| SessionStart stdin payload | JSON with `cwd`; fallback `CLAUDE_PROJECT_DIR` or `$PWD` | Claude and Codex hook wiring; test helper `ss` | `.agents/hooks/session-start-resume.sh:66-68`, `tests/hooks/audit-sync-resume.sh:227` |
| SessionStart output | `{hookSpecificOutput:{hookEventName, additionalContext}}`, list text capped at 9000 chars | host | `.agents/hooks/session-start-resume.sh:62`, `:355` |
| handoff frontmatter | `goal`, `spec`, `created` read for the offer; `main_sha`, `affected_paths` used by Resume | hook; handoff Resume | `.agents/skills/handoff/assets/handoff.md:2` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| CAP-015 (spec 00016) | handoff written in the checkout the session works in; offer lists own checkout's first, then other checkouts' by absolute path | `.workflow/capabilities.md` § Capabilities, CAP-015 |
| 00016 retrospective | handoff skill stays self-contained; folder stays `.workflow/.handoff/`; live SessionStart in a worktree was never exercised | `.workflow/decisions/retrospectives/00016-per-run-handoffs.md` § Result against the spec, § Findings, § Action items |
| "other checkouts see main only" | reason stated only in code: a run never picks up a sibling worktree's handoff; no ADR | `.agents/hooks/session-start-resume.sh:96-98` |
| Pitfall: stray isolation worktree copies | `.claude/worktrees/` copies outlived Phase 4 | `.workflow/decisions/pitfalls.md` § Fork a Phase 1 build's worktree from the spec branch |
| Ownership | `hooks` may depend on `lib`, `feature-workflow`, `project-setup`; `standalone-skills` (owns `handoff`) depends on nothing | `.workflow/rules.md` § Ownership |
| Shelf: `main-checkout-resolver.md` | other places compute the main checkout themselves; shelved refactor onto `wf_main_root` | `.workflow/deferred/main-checkout-resolver.md` § Background |
| Shelf: `session-start-timing-target.md` | no wall-time target for the session-start hook | `.workflow/deferred/session-start-timing-target.md` § Goal |

No ADR mentions worktrees, handoffs or session start. No shelf item matches the session-worktree concept.

## Library options

Not evaluated: no new library named; the change is bash in an existing hook plus skill text.

## Not found

- "session worktree" or a `claude/<name>` branch test anywhere in `.agents/**`, `tests/**`, `.workflow/**`, `AGENTS.md`, `README.md`. Reported by retrieval.
- A test of a session in a `.claude/worktrees/` checkout that holds its own handoff, or that sees spec worktrees' handoffs: none; `tests/hooks/audit-sync-resume.sh:68-71`, `:315-317`, `:359-366` cover main and spec worktrees only. Reported by retrieval.
- A handoff Locate test outside a spec worktree: `tests/scripts/handoff-skill.sh:17-18`, `:53-64` run only in a spec worktree. Reported by retrieval.
- Doc mismatch: `.agents/skills/handoff/SKILL.md:21` lists "a spec worktree, an agent worktree or the main checkout" and omits isolation and session worktrees, though Locate writes into any of them. Reported by retrieval.
- Live behaviour of a session started in `.claude/worktrees/<name>`: never tested (`00016` retrospective). Reported by retrieval.
