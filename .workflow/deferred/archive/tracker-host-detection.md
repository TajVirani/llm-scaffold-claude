---
superseded_by: .workflow/specs/00014-tracker-issue-spec-ids
origin_spec: .workflow/specs/00014-tracker-issue-spec-ids
created: 2026-11-02
---

# Tracker host detection

**Summary:** Pick the tracker host (GitHub through gh, GitLab through glab) in one shared place instead of one copy per script.
**Mode:** AFK
**Origin:** [00014-tracker-issue-spec-ids](../specs/00014-tracker-issue-spec-ids/spec.md), 0.3.17 scope decision, design-log entry 2026-11-02 Scope decision: tracker-host-detection

## Goal

Every workflow script and step that talks to the remote host chooses gh or glab the same way, from one definition.

## Background

The module audit for spec 00014 found the host choice written out separately in the task-PR script, the settings reader and the sign-off prose; the new issue-tracking skill adds a fourth. Each copy works, so unifying them is a refactor outside 00014's scope.

**Current behaviour:** Each caller reads the `origin` URL itself and maps `github` to gh and `gitlab` to glab.

**Desired behaviour:** One shared reader returns the host (or a reason it has none); every caller uses it, and their outputs stay as they are.

## Constraints

- Shared code under `.agents/lib/` changes only through the integration agent (`.workflow/rules.md` § Shared core).

## Evidence

- Host choice at `.agents/skills/feature-workflow/scripts/open-task-pr.sh:161-165`, `.agents/skills/feature-workflow/scripts/rules-setting.sh:107-113`, `.agents/skills/feature-workflow/modules/sign-off.md:239`, as of commit `7b50de2`.

## Acceptance criteria

- [ ] One definition of the host choice; no caller repeats the URL match.
- [ ] Every existing test of task PRs, settings and sign-off passes unchanged.

## Out of scope

- Supporting other hosts.
