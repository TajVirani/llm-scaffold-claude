---
status: accepted
---

# Tracker issues: a new issue-tracking skill owns them

Specs and tasks are now filed as tracker issues on GitLab or GitHub, which touches discovery, task breakdown, sign-off, project setup and a migration of existing specs. We place the tracker work in a new `issue-tracking` skill: it owns the scripts that create, fill, link and move tracker issues for both hosts, the setup flow for a project already under way, and the spec migration; `feature-workflow` and `project-setup` call its scripts and carry only the step that calls them.

## Considered Options

- `feature-workflow` as owner: it runs every step that files or moves an issue, but its new-feature start already sits at 44,733 of the 45,000 bytes ADR-0004 allows, and a project without a tracker would carry the tracker detail anyway.
- Extend the `glab` skill: it already documents issue commands, but it covers GitLab only, and it is a standalone playbook that `feature-workflow` may not depend on.

## Consequences

- `.workflow/rules.md` Ownership gains the `issue-tracking` module, and `feature-workflow` and `project-setup` may depend on it; until 5.3 approves that, the change is a proposal.
- The new skill is a first-party asset, so it goes in `.agents/install-manifest.txt` and `PROVENANCE.md` in the same change.
