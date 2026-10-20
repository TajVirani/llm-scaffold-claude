---
goal: ""                 # one line: what the work is for (shown in the session-start offer)
spec: ""                 # .workflow/specs/NNN-slug when the work belongs to a spec, else ""
step_at_handoff: ""      # the spec's .step at handoff time, e.g. "3.4"; "" outside a spec. The live .step wins on resume
created: YYYY-MM-DDTHH:MM:SSZ
---
<!--
File: Template for .workflow/.handoff/<NNN-slug | topic>.md, a session handoff (skills/handoff). Lives in .workflow/.handoff/ at the main checkout; install.sh's .gitignore block keeps it out of git.
Read by: hooks/session-start-resume.sh (frontmatter goal, spec, created; read with mikefarah yq v4 --front-matter=extract) and by the resuming session (everything).
Writing rules: one line per fact; point to an artifact (path, sha, URL) instead of copying it; in a spec, status, step, scope, decisions and tasks stay in spec.md, .step, design-log.md and tasks.md. `none` for an empty section. No secrets. Add no other frontmatter keys. Delete this comment in the finished file.
Sources: first-party; idea from mattpocock/skills@49dd158d1076134a641b33efb035946536778336 skills/productivity/handoff/SKILL.md (MIT).
-->

# Handoff: <goal in a few words>

## State

<!-- Where the work stands, in two to five lines: done, in progress, not started. In a spec: "see spec.md / tasks.md", plus only what they do not show yet. -->

## Decisions

<!-- One line each: decision and why, or a pointer (design-log.md entry, ADR, commit). Mark a decision agreed in the conversation but not yet written down `not logged`. -->

## Open questions

<!-- Who must answer each (user, a fact from the repo), and what it blocks. -->

## Next action

<!-- The single next step, concrete enough to start without asking: command, file, or feature-workflow step. -->

## Files touched

<!-- Paths changed this session and not yet committed, one line each with what changed; or the commit range. `git status --short` is the check. -->

## Verify

<!-- The command(s) that show the state is as described (test suite, script, git log range), and what passing looks like. -->

## Load first

<!-- Skills the next session should load before acting, with one line on why (e.g. feature-workflow for the spec, tdd for the task). -->
