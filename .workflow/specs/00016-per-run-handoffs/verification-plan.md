# Verification plan: Per-run session handoffs

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-per-run-handoffs: the handoff skill's Locate commands, run from a spec worktree, create the handoff folder and file under that worktree and add or change nothing under the main checkout.
- [ ] CAP-NEW-per-run-handoffs: in a repository whose `.gitignore` has no workflow block, `git status --porcelain` lists nothing under `.workflow/.handoff/` after the Locate commands and a handoff file exist.
- [ ] CAP-NEW-per-run-handoffs: two runs of the name command for the same spec in the same second give two different file names, each matching `<NNN-slug>--<YYYYMMDDTHHMMSSZ>-<4 chars>.md`.
- [ ] CAP-NEW-per-run-handoffs: the session-start offer of a session in a spec worktree lists that worktree's handoffs before the main checkout's, and each entry's path leads to the file from where the session is.
- [ ] CAP-NEW-per-run-handoffs: the session-start offer of a session in the main checkout lists the handoffs in each spec worktree with their paths, never lists `.gitignore`, and still lists a handoff under an old name.
- [ ] CAP-NEW-per-run-handoffs: the handoff skill says that a handoff named by path in the first message is resumed without asking, and that the resuming session deletes it once it has written its successor or finished the work.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Hand off from a spec worktree | CAP-NEW-per-run-handoffs | 1. Build a repo with a main checkout and a spec worktree. 2. Extract the Locate commands from the handoff skill and run them in the worktree. 3. List both checkouts. | The folder, its `.gitignore` and the named path are under the worktree; the main checkout is unchanged | `JRN-001` checks in `tests/scripts/handoff-skill.sh` |
| JRN-002 | Handoff stays out of git with no ignore block | CAP-NEW-per-run-handoffs | 1. Build a repo with no workflow `.gitignore` block. 2. Run the Locate commands and create a handoff file. 3. Run `git status --porcelain --untracked-files=all`. | No line names `.workflow/.handoff/` | `JRN-002` check in `tests/scripts/handoff-skill.sh` |
| JRN-003 | Two runs, one spec, same second | CAP-NEW-per-run-handoffs | 1. Run the name command twice for `007-alpha` with the clock fixed. | Two different names, both of the documented shape | `JRN-003` checks in `tests/scripts/handoff-skill.sh` |
| JRN-004 | Offer from a spec worktree | CAP-NEW-per-run-handoffs | 1. Put one handoff in the spec worktree and one in the main checkout. 2. Run the session-start hook with the worktree as cwd. | The worktree's handoff is listed first; both entries carry a path that exists from the worktree | `JRN-004` checks in `tests/hooks/audit-sync-resume.sh` |
| JRN-005 | Offer from the main checkout | CAP-NEW-per-run-handoffs | 1. Put a new-name handoff in a spec worktree, an old-name handoff and a `.gitignore` in the main checkout's folder. 2. Run the session-start hook with the main checkout as cwd. | Both handoffs are listed with their paths; `.gitignore` is not; the 3-listed cap and the count hold across checkouts | `JRN-005` checks in `tests/hooks/audit-sync-resume.sh` |
| JRN-006 | Resume rules are written down | CAP-NEW-per-run-handoffs | 1. Read the handoff skill's Resume section. | It states resume-by-path without asking and delete-after-successor | `JRN-006` checks in `tests/scripts/handoff-skill.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Temp repo with a spec worktree | A main checkout and `.workflow/.spec-worktrees/<NNN-slug>` | Built at run time under `new_workdir` (`tests/lib/common.sh`); the existing `$P` and `$WT` fixture of `tests/hooks/audit-sync-resume.sh` | JRN-001, JRN-004, JRN-005 |
| Skill command extract | The fenced bash block of the handoff skill's Locate step, run as written | `.agents/skills/handoff/SKILL.md`, read by the test | JRN-001, JRN-002, JRN-003 |
| Expected paths and names | Literal paths under the fixture and the name pattern `^[0-9a-z-]+--[0-9]{8}T[0-9]{6}Z-[a-z0-9]{4}\.md$` | data-model.md § Session handoff | JRN-001 to JRN-005 |
| Expected skill wording | Literal phrases the Resume section must hold | The settled decisions D6 and D8 in design-log.md | JRN-006 |

## Targets

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Session-start offer size with handoffs in several checkouts | performance | under 10,000 characters of `additionalContext` | Not measurable outside a fixture: it needs a repo with spec worktrees and handoffs, which only the suite builds; the cap check in `tests/hooks/audit-sync-resume.sh` is extended to cover it | spec.md Constraints (the offer stays inside its size cap) |
| Errors | error | the hook exits 0 for every input | Not measurable as a number: asserted per case by the suite | `.agents/hooks/session-start-resume.sh` header (exit 0 always) |
| Coverage | coverage | none set | Not measurable: no bash line-coverage tool is installed ([.workflow/deferred/bash-line-coverage.md](../../deferred/bash-line-coverage.md)) | assumed (design-log.md) |

## Suites

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` | `tests/run-all.sh` | none | `artifacts/phase-1-known-bad/record.md` |
| Browser | `e2e` | none: the project has no e2e profile | none | not applicable |
