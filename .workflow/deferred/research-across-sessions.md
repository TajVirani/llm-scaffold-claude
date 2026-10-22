---
origin_spec: .workflow/specs/001-large-path
created: 2026-10-22
severity: medium
---

# Collect a research answer across a session end

**Summary:** A research question left `researching` when a session ends is settled on resume only if the agent's return is in hand; otherwise the large path resets it to `open` and launches it again.
**Mode:** HITL
**Origin:** [001-large-path](../specs/001-large-path/spec.md), 4.8 review finding (F11, unverified), design-log entry 2026-10-22 Triage, review pass 1

## Goal

The stakeholder knows, and accepts, what happens to a research launch that outlives its session: either its answer is collected on resume, or the question is relaunched and the first launch's cost is lost.

## Background

The capability's success line says a session can end with a question `researching` and the next session writes the answer back. The module keeps the `researching` state and the launch record across the session end, but a host that does not preserve a sub-agent's result between sessions leaves nothing to write back, so the module resets the question and relaunches at the next round. Whether the host preserves results is outside the repo, so the review could not verify the success line as written.

**Current behaviour:** on resume, 6.2 writes back a return that is in the session; with none, it clears `launched`, sets the question `open`, and 6.4 relaunches it.

**Desired behaviour:** either the stakeholder accepts relaunch-on-new-session as the meaning of the success line, or a host mechanism preserves the result so the next session writes it back.

## Constraints

- Initiative state changes only through the single writer; a write-back is `set-question --state settled --settled <text>`.

## Decisions already made

- A research question may be launched and left pending when a session ends; its answer is written back by the session that resumes it (design-log D9 in [design-log.md](../specs/001-large-path/design-log.md)).

## Evidence

- `.agents/skills/feature-workflow/modules/large-path.md` § 6.2, as of commit `291e55289f399f767e7403715e14b73ffa5a7ccd`. Unverified: settled by the stakeholder's acceptance at sign-off 5.5, or by a host mechanism for preserving sub-agent results.

## Acceptance criteria

- [ ] The stakeholder has recorded whether relaunch-on-new-session satisfies the success line, or
- [ ] a research result left pending across a session end is written back without a relaunch.

## Out of scope

- Any change to how a host stores sub-agent transcripts.
