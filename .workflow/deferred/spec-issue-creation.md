---
origin_spec: .workflow/specs/done/008-pr-description-template
created: 2026-10-29
---

# Spec issue creation

**Summary:** Create a tracker issue (GitHub or GitLab) when a spec starts, so its Sign-off PR can link a real issue.
**Mode:** HITL
**Origin:** [008-pr-description-template](../specs/done/008-pr-description-template/spec.md), 0.3.17 scope decision, design-log entry 2026-10-29 Deeper prompt

## Goal

Every spec has a tracker issue from the moment discovery starts. The PR template's "Link to issue" section points at it instead of a stub.

## Background

The PR template requires a "Link to issue" section, but the workflow creates no issue at any step. Spec 008 ships that section as a marked stub. Creating issues is a separate capability with its own host, permission and timing questions, so it was kept out of 008's scope.

**Current behaviour:** No issue is created. The Sign-off PR's "Link to issue" section holds a stub saying issue creation is not built yet.

**Desired behaviour:** When a spec starts, the workflow opens an issue on the project's host (GitHub through `gh`, GitLab through `glab`), records its URL in the spec, and the Sign-off PR links it, closing it on merge where the host supports that. With no remote or CLI, the spec records that no issue exists and the stub stays.

## Constraints

- The 008 PR template keeps "Link to issue" as a required section; this item fills it, it does not remove it.
- Pushing or creating anything on a remote needs the stakeholder's standing consent, as task PRs do through `task_review`.

## Decisions already made

- "Link to issue" is required and stays a marked stub until this exists (design-log Deeper prompt in [.workflow/specs/done/008-pr-description-template/design-log.md](../specs/done/008-pr-description-template/design-log.md)).

## Evidence

- No step creates an issue; the sign-off PR is opened with raw `gh pr create` / `glab mr create` and no issue link, at `.agents/skills/feature-workflow/modules/sign-off.md:161` as of commit `02bc218`.

## Acceptance criteria

- [ ] Starting a spec on a GitHub or GitLab project creates one issue and records its URL in the spec.
- [ ] The Sign-off PR's "Link to issue" section shows that URL and the check script accepts it.
- [ ] With no remote or CLI, no issue is created and the stub text is used.
- [ ] Work-backlog items and initiative slices that become specs get their issue the same way.

## Out of scope

- Syncing spec status to issue labels or boards.
- Creating issues for individual tasks.
