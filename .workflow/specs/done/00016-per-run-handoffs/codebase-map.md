# Codebase map: Per-run session handoffs

Affected area: standalone-skills (`.agents/skills/handoff`), hooks (`.agents/hooks`), lib (`.agents/lib`), feature-workflow (`.agents/skills/feature-workflow`), project-setup (`.agents/skills/project-setup`), installer (`install.sh`), tests (`tests`), root-docs (`AGENTS.md`, `README.md`)

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Handoff skill, Write | Locates the main checkout with an inline `git rev-parse --git-common-dir` (not `wf_main_root`), makes `.workflow/.handoff/`, names the file `NNN-slug.md` for spec work or `<topic>.md` otherwise, and overwrites an existing file of the same name ("it is the previous handoff for this work"). | `.agents/skills/handoff/SKILL.md` § 1. Locate (lines 13-30) |
| Handoff skill, gather | Points to artifacts instead of copying them; fills `main_sha` from the main branch named in the `## Workflow settings` yaml of rules.md (default `main`) and `affected_paths` from the codebase-map `Affected area:` line or the `Files touched` list. | `.agents/skills/handoff/SKILL.md` § 2. Gather (lines 32-52) |
| Handoff template | Frontmatter keys: `goal`, `spec`, `step_at_handoff`, `main_sha`, `affected_paths`, `created`. Body sections: State, Decisions, Open questions, Next action, Files touched, Verify, Load first. | `.agents/skills/handoff/assets/handoff.md:1-8`, body headings `:17-43` |
| Handoff skill, Resume | Reads the file, loads Load-first skills, routes a `spec` to feature-workflow (live spec.md and .step win), then compares `main_sha` with the main branch tip and runs `git log`/`git diff --stat` on `affected_paths`, appending a dated entry to the spec design-log. It starts from "When the user picks a handoff"; the "Do not resume unasked" text is in the hook. | `.agents/skills/handoff/SKILL.md` § Resume (lines 64-91) |
| Session-start offer | Lists up to 3 files in `.workflow/.handoff/*.md` at the main checkout, newest first by mtime, with `created`, `spec` and `goal` read via yq; unreadable ones are flagged; the rest are counted. Handoffs alone are enough to produce the offer. Text says "Do not resume unasked." | `.agents/hooks/session-start-resume.sh:89`, `:114-137`, `:302-308`, `:319` |
| Session-start root | Uses `wf_main_root` for the main checkout (handoffs and backlog) and `wf_project_root` for the session's own checkout (specs). | `.agents/hooks/session-start-resume.sh:63-66` |
| Path constant | `WF_HANDOFF="$WF_DIR/.handoff"` (= `.workflow/.handoff`). Also excluded from the path rewrite. | `.agents/lib/workflow-paths.sh:109`, `:637` |
| Write guard | `check-write.sh` has no rule for `.workflow/.handoff/`; it falls under "other, allow". | `.agents/skills/feature-workflow/scripts/check-write.sh:48` |
| Toolchain scope | `run-toolchain.sh` leaves the handoff folder out of the scanned tree. | `.agents/skills/feature-workflow/scripts/run-toolchain.sh:54`, `:99` |
| Workflow data commit | `commit-workflow-data.sh` fails a commit that would include `.handoff/` when it is untracked and not ignored. | `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh:8`, `:70` |
| feature-workflow entry | On a handoff pick from the session-start offer, feature-workflow loads the handoff skill's Resume section. | `.agents/skills/feature-workflow/SKILL.md:16` |
| SessionStart wiring | Claude settings template runs `session-start-resume.sh` on SessionStart. | `.agents/hooks/claude-settings.template.json:8-13` |
| Installer gitignore | `GI_ENTRIES` includes `$WF_HANDOFF/`. The block is refreshed on each run (`block_replace`), so an existing install gets changes on upgrade. | `install.sh:35`, `:137`, `:700-709`, `:1055` |
| Repo gitignore | `.workflow/.handoff/` is present, hand-kept in step with `GI_ENTRIES`. | `.gitignore:13`, `AGENTS.md:27` |
| Ownership | `.agents/skills/handoff/**` is owned by `standalone-skills`, with `may_depend_on: []`. | `.workflow/rules.md` § Ownership |
| Tests | `audit-sync-resume.sh` covers the offer: handoff-only output, cap with long goals, newest first, unreadable flagged, 3 listed and 2 counted. `check-write-paths.sh` lists `.workflow/.handoff/001-alpha.md` as a path case. `commit-workflow-data.sh` test checks `.handoff/` stays out of the commit. `install-payload.sh` checks the GI block and that `handoff` is a first-party skill. | `tests/hooks/audit-sync-resume.sh:254-332`; `tests/scripts/check-write-paths.sh:83`; `tests/scripts/commit-workflow-data.sh:30-70`; `tests/scripts/install-payload.sh:76`, `:88-90` |
| Docs | README lists `handoff` as a first-party skill and the GI entries for every `--host`. | `README.md:50`, `:88` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `WF_HANDOFF` | Shell variable, `.workflow/.handoff` (repo-relative, no trailing slash) | session-start-resume.sh; install.sh `GI_ENTRIES`; commit-workflow-data.sh; run-toolchain.sh; workflow-paths.sh rewrite exclude | `.agents/lib/workflow-paths.sh:109` |
| `wf_main_root <dir>` | Prints the main checkout root for a dir in the repo or a worktree; status 1 outside git | session-start-resume.sh only. The handoff skill reimplements the lookup inline | `.agents/lib/workflow-paths.sh:122-134`; `.agents/skills/handoff/SKILL.md:18` |
| Handoff file frontmatter | YAML: `goal`, `spec`, `step_at_handoff`, `main_sha`, `affected_paths`, `created`. Read by yq `--front-matter=extract` | session-start-resume.sh (goal, spec, created); the Resume steps (all keys) | `.agents/skills/handoff/assets/handoff.md:1-8`; `session-start-resume.sh:123` |
| Handoff file name | `.workflow/.handoff/NNN-slug.md` (spec work) or `<topic>.md` (kebab, 2-4 words); same name = replace | Written by the handoff skill; listed by session-start (`*.md` glob) | `.agents/skills/handoff/SKILL.md:28`; `session-start-resume.sh:89` |
| Offer text | Hook emits `hookSpecificOutput.additionalContext`; the handoff line names the handoff skill's Resume | Claude, and Codex via `codex-hooks.template.json` | `session-start-resume.sh:302-321`; `.agents/hooks/codex-hooks.template.json:3-8` |
| Handoff skill, Write | Prose procedure. Inputs: the conversation and an optional argument (the next session's focus). Output: one file under `.workflow/.handoff/` plus a path and one resume line to the user. Done-when: every section filled or `none`, every path exists, no secrets. Outside git, `root=$PWD` and `main_sha` is `""`. | The user, via skill trigger | `.agents/skills/handoff/SKILL.md:11-62` |
| Handoff skill, Resume | Prose procedure. Input: one handoff file (picked from the offer or by name). Order: load Load-first skills; route the spec to feature-workflow (live state wins); drift check against `main_sha` with an optional design-log append; Verify; Next action. No deletion step tied to a successor. | The user; feature-workflow on a handoff pick | `.agents/skills/handoff/SKILL.md:64-91` |
| `root` (skill-local variable) | Absolute path. Today: the parent of `--git-common-dir`, else `$PWD`. Used for the folder location and for the path to `.workflow/rules.md`. | Write step 1, Write step 2 (`main`), Resume step 3 | `.agents/skills/handoff/SKILL.md:18`, `:42-45`, `:70` |
| `agents/openai.yaml` | `display_name: "Handoff"`, `short_description: "Write or resume a session handoff"`. No location or file-name wording. | Codex skill listing | `.agents/skills/handoff/agents/openai.yaml:1-3` |
| SessionStart hook I/O | stdin: SessionStart JSON; only `.cwd` is read, with fallback `$CLAUDE_PROJECT_DIR` then `$PWD`. stdout: nothing or one `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<text>"}}`. Exit 0 always; skips quietly when jq or yq is missing. | Claude (SessionStart, timeout 10) and Codex | `.agents/hooks/session-start-resume.sh:59-62`, `:101`, `:309`, `:321` |
| `checkouts` list (hook-internal) | Newline-separated absolute paths: `$here`, spec-branch worktrees from `git worktree list`, `$root`, de-duplicated by exact string. | The spec scan only | `.agents/hooks/session-start-resume.sh:71-87` |
| Handoff entry line | `- <path>[ (created <c>)][; spec <s>][: <goal>]` or `- <path>: frontmatter unreadable; open it to read the handoff.`, cut to 300 chars; then `- ... and N older not listed.` | The agent in the session; `tests/hooks/audit-sync-resume.sh` | `.agents/hooks/session-start-resume.sh:122-135` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Provenance D77/D78 | `handoff` is first-party, derived from mattpocock/skills (ideas only). The `.workflow/.handoff/` location, spec pointer rule and Resume are ours. | `PROVENANCE.md` § Workflow 2.0 table (row `handoff`) |
| Retrospective 002, actions | A handoff carried an old main sha and drift was found only at 1.1. The Resume drift check (step 3) came from it. | `.workflow/decisions/retrospectives/002-review-lessons.md` § action table |
| ADRs, pitfalls | No ADR or pitfall mentions handoffs or session resume. | `.workflow/decisions/adr/`, `.workflow/decisions/pitfalls.md` |
| Shelf, concept match | None. | `.workflow/deferred/*.md` |
| Shelf, related | `main-checkout-resolver.md` names `.agents/skills/handoff/SKILL.md:18` as a site that computes the main checkout itself. | `.workflow/deferred/main-checkout-resolver.md:42` |
| Shelf, related | `session-start-timing-target.md`: the session-start hook has no measured time target; its fixture includes handoffs. | `.workflow/deferred/session-start-timing-target.md` § Summary |

## Library options

Not evaluated: no new library named; shell-scripts approves jq and yq for JSON and YAML.

## Module audit

Owning module: standalone-skills (handoff skill only: `.agents/skills/handoff/**`)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Write step 1 already has a git-or-`$PWD` fallback followed by `mkdir -p "$root/.workflow/.handoff"`. The new root (`git rev-parse --show-toplevel`, else `$PWD`) fits the same pattern, and the `.gitignore` write can follow the `mkdir`. | `.agents/skills/handoff/SKILL.md:17-20` |
| reuse | The `NNN-slug` / `<topic>` stem rule can stay as the first part of the new name. | `.agents/skills/handoff/SKILL.md:28` |
| reuse | `created` already uses the UTC timestamp `YYYY-MM-DDTHH:MM:SSZ`; the file-name stamp is the same instant in compact form, so both can come from one clock read. | `.agents/skills/handoff/assets/handoff.md:7` |
| reuse | Resume already handles a handoff picked "by name", so a first-message path fits this entry point. | `.agents/skills/handoff/SKILL.md:66` |
| reuse | There is already a delete rule ("Delete it when its work is done or the user drops it"); the delete-after-successor rule replaces this line. | `.agents/skills/handoff/SKILL.md:91` |
| gap | Write step 1 resolves the main checkout through `--git-common-dir`, and its prose says handoffs live "at the main checkout, where the session-start hook looks". Both change. | `.agents/skills/handoff/SKILL.md:15`, `:18` |
| gap | The naming rule says an existing file of the same name "is the previous handoff for this work: read it and replace it". | `.agents/skills/handoff/SKILL.md:28` |
| gap | Nothing in the skill generates the 4 random characters. | `.agents/skills/handoff/SKILL.md:13-30` |
| gap | The skill never writes a `.gitignore`; step 1 relies on `install.sh`. | `.agents/skills/handoff/SKILL.md:15` |
| gap | Resume never says "without asking"; it starts from "When the user picks a handoff". | `.agents/skills/handoff/SKILL.md:66` |
| gap | Resume does not say how to find a handoff under the old names in the main checkout. | `.agents/skills/handoff/SKILL.md:28`, `:66` |
| gap | "the next handoff for the same work replaces it" contradicts the feature; no rule says the resuming session deletes the handoff it resumed from. | `.agents/skills/handoff/SKILL.md:91` |
| gap | "Tell the user" gives `.workflow/.handoff/<name>.md` as the path to name and says the hook offers it; wrong once the file sits in a worktree and the name carries a stamp. | `.agents/skills/handoff/SKILL.md:62` |
| gap | The frontmatter `description` names no per-checkout location and no path-in-first-message trigger. | `.agents/skills/handoff/SKILL.md:3` |
| gap | The template comment gives the name as `<NNN-slug \| topic>.md` and says it lives at the main checkout, kept out of git by install.sh. | `.agents/skills/handoff/assets/handoff.md:10` |
| constraint | Resume's drift step reuses Write's `root` ("set `root` as Write step 1 does"), and `main_sha` reads `main_branch` from `$root/.workflow/rules.md`. Changing `root` in Write changes Resume unless its wording is adjusted. | `.agents/skills/handoff/SKILL.md:42`, `:45`, `:70` |
| constraint | Frontmatter keys are fixed; the hook reads `goal`, `spec` and `created`, so `goal` stays one line. | `.agents/skills/handoff/assets/handoff.md:11-12`; `.agents/skills/handoff/SKILL.md:56` |
| constraint | Point, don't copy; `none` for an empty section; no secrets; every path in the file exists. | `.agents/skills/handoff/SKILL.md:34-38`, `:58` |
| constraint | Resume order stays: read, spec (live `.step` wins), drift, Verify, Next action. | `.agents/skills/handoff/SKILL.md:68-89` |
| constraint | SKILL.md frontmatter keeps the shape `name`, `description`, `argument-hint` (`lint/frontmatter`). | `.agents/skills/handoff/SKILL.md:1-5` |

### hooks (`.agents/hooks/session-start-resume.sh`)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | The hook already builds the ordered, de-duplicated checkout list: the session's own (`here`), each `git worktree list` entry on a `refs/heads/spec/*` branch, then the main checkout (`root`). The handoff scan can walk it. Spec worktrees come from git, not from a folder glob. | `.agents/hooks/session-start-resume.sh:63-66`, `:71-76` |
| reuse | Spec entries already name another checkout: `" (runs in $checkout; continue the session there)"` when the checkout is not `$here`. | `.agents/hooks/session-start-resume.sh:233-237` |
| reuse | The `seen_specs` string with `case ... *" $name "*` is the module's de-duplication idiom. | `.agents/hooks/session-start-resume.sh:78-86` |
| reuse | The handoff entry builder already reads `[.goal, .spec, .created]`, flags unreadable frontmatter, cuts to 300 chars, lists 3 and counts the rest. | `.agents/hooks/session-start-resume.sh:116-137` |
| reuse | The `*.md` glob under `nullglob` already leaves out a `.gitignore` and matches both old and new names. | `.agents/hooks/session-start-resume.sh:68`, `:89` |
| gap | Handoffs are gathered from one folder: `handoffs=("$root/$WF_HANDOFF"/*.md)`. | `.agents/hooks/session-start-resume.sh:89` |
| gap | The listed path is always `"- $WF_HANDOFF/$(basename "$h")"`, so it drops which checkout the file is in. | `.agents/hooks/session-start-resume.sh:122` |
| gap | The section header names one folder. | `.agents/hooks/session-start-resume.sh:303-304` |
| gap | `checkouts` includes every spec worktree even when the session is itself in one; a spec-worktree session should see its own handoffs and then main's. | `.agents/hooks/session-start-resume.sh:71-76` |
| gap | The order is mtime over everything (`ls -1t`), not grouped by checkout. | `.agents/hooks/session-start-resume.sh:133` |
| gap | The header comments describe a main-checkout-only scan, and the shellcheck-disable reason says names are kebab-case, while paths from other checkouts are absolute and may hold spaces. | `.agents/hooks/session-start-resume.sh:8`, `:12`, `:38-39`, `:118` |
| gap | `claude-settings.template.md` describes the SessionStart hook only as "Offers to resume an in-flight spec". | `.agents/hooks/claude-settings.template.md:9` |
| constraint | The early exit counts handoffs, so every handoff found in any checkout must be in `handoffs` before it. | `.agents/hooks/session-start-resume.sh:100` |
| constraint | The handoff text is taken off `LIMIT` (9000) before the spec list; longer paths take room from the goal text and the spec list. | `.agents/hooks/session-start-resume.sh:56`, `:132`, `:136` |
| constraint | Hook timeout 10 s, `TIME_BUDGET=6`; yq runs only for the 3 listed entries. | `.agents/hooks/session-start-resume.sh:57`, `:119-133` |
| constraint | "Do not resume unasked." stays in both endings. | `.agents/hooks/session-start-resume.sh:308`, `:318-319` |
| constraint | Exit 0 always; under `set -euo pipefail` a new glob or command substitution is guarded with `\|\| true`. | `.agents/hooks/session-start-resume.sh:41`, `:51`, `:73` |
| constraint | `root` and `here` come from logical `pwd` and are compared with `git worktree list` paths as plain strings; if the forms differ, one checkout could be scanned twice. | `.agents/hooks/session-start-resume.sh:63`, `:76`, `:237` |
| constraint | Under Codex the hook that runs in a spec worktree is that worktree's own `.agents/` copy. | `.agents/hooks/codex-hooks.template.json:8` |

## Not found

- A per-run or multi-file handoff layout, in code, tests or docs: `.agents/**`, `tests/**`, `install.sh`, `README.md`, `AGENTS.md`, `.workflow/rules.md`, `.workflow/decisions/**`. Reported by retrieval.
- A write-guard rule for handoff paths: `check-write.sh` has no `.handoff` case; `workflow-write-guard.sh`, `worktree-write-guard.sh`, `codex-write-guard.sh` and `pre-launch.sh` do not name the folder. Reported by retrieval.
- An installer upgrade step for handoffs: the folder is not in `RETIRED_PATHS` (`install.sh:123-132`); its only upgrade path is the `.gitignore` block refresh (`install.sh:705-709`). Reported by retrieval.
- Handoff references in `.agents/skills/project-setup/**`. Reported by retrieval.
- A doc that disagrees with the code on the folder: README.md:88, AGENTS.md:27, `.gitignore:13`, install.sh:137 and the handoff skill agree. Reported by retrieval.
- Location or file-name wording in `.agents/skills/handoff/agents/openai.yaml`: it holds only a display name and a short description. Reported by module-audit.
- A random-suffix or timestamp-name helper, or any use of `date -u`: `.agents/skills/handoff/**`. Reported by module-audit.
- Tests or fixtures inside the handoff skill: it holds only SKILL.md, assets/handoff.md and agents/openai.yaml. Reported by module-audit.
- A hook-side constant or glob for `.workflow/.spec-worktrees/`: the hook finds spec worktrees only through `git worktree list`. `.agents/hooks/**`. Reported by module-audit.
- Another hook that reads, writes or guards `.workflow/.handoff/`: `.agents/hooks/**`. Reported by module-audit.
