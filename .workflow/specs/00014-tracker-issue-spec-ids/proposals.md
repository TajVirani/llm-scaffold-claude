# Proposals: Tracker issues as spec IDs

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Rules

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/rules.md` § Ownership | Add module `issue-tracking: { owns: [".agents/skills/issue-tracking/**"], may_depend_on: [lib, feature-workflow] }`; add `issue-tracking` to `may_depend_on` of `feature-workflow` and `project-setup` | Without it the new skill's paths have no owner, so 0.3.3 cannot place later changes to it, and review 4.1 flags feature-workflow and project-setup calling its scripts as forbidden dependencies | design-log D2, 0.3.5 conflict check | approved | "Approve all (Recommended)", 5.3 |
| P2 | `.workflow/rules.md` § Ownership | Add `issue-tracking` to `may_depend_on` of `tests` | Without it every suite that calls the issue-tracking scripts is a forbidden dependency, so 0.3.3 placement and review 4.1 flag each later change to them | design-log F7 (review pass 1, RS-3) | approved | "Approve all (Recommended)", 5.3 |

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P3 | `.workflow/capabilities.md` | CAP-013 \| Specs and tasks filed as tracker issues: with a tracker set up, a spec's number is its GitLab or GitHub issue number, tasks are child issues or sub-issues, issues move through the three-label issue flow, and the Sign-off PR closes the spec's issue; with none, numbering is unchanged \| [.workflow/specs/00014-tracker-issue-spec-ids](specs/00014-tracker-issue-spec-ids/spec.md) | Without it, 0.3.1 would not find that tracker numbering exists and could plan it again | spec.md § Capabilities | approved | "Approve all (Recommended)", 5.3 |
| P4 | `.workflow/capabilities.md` | CAP-014 \| Tracker setup and adoption: project-setup and the `issue-tracking` skill check the tracker, save the issue flow in `.workflow/issue-tracking.yaml`, and Tracker adoption files and renames active specs and prefixes Done specs `old_` \| [.workflow/specs/00014-tracker-issue-spec-ids](specs/00014-tracker-issue-spec-ids/spec.md) | Without it, 0.3.1 would not find that adoption and the `old_` Done names exist | spec.md § Capabilities | approved | "Approve all (Recommended)", 5.3 |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P5 | `.workflow/decisions/pitfalls.md` | **Give every new spec or task key a writer step.** Spec 00014 added `tracker_issue` to the spec template and read it at six steps, but no step wrote it: 0.1.4 still said "frontmatter unchanged", so every tracker call would have exited 2 (review pass 1, F1, high). When a change adds a frontmatter or record key, name the step that writes it and add a docs-lint check for that step. | Without it, a planner adds a key and its readers and leaves the writer to the template comment, as happened here | design-log F1 | approved | "Approve all (Recommended)", 5.3 |
| P6 | `.workflow/decisions/pitfalls.md` | **A rename or adoption script must carry every record the workflow later reads.** Spec 00014's Tracker adoption filed spec issues but no task issues, so an adopted spec past 2.5 stopped at 3.3 with no step to clear it (review pass 2, F12). When a script brings existing specs under a new rule, list each later step that reads the new data and make the script fill it for specs already past that step. | Without it, a migration covers new specs and strands the ones already in flight | design-log F12 | approved | "Approve all (Recommended)", 5.3 |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P7 | `.workflow/profiles/shell-scripts.md` § Language and style rules | Add: "A bash 3.2 workaround (`${a[@]+"${a[@]}"}` for an empty array under `set -u`, `10#` for a leading-zero number, `|| true` after a pipeline that may match nothing) carries a one-line reason comment, so no reader drops it as noise." | The mini-review failed R2 on exactly these workarounds in T5 and twice in T6; with the rule in the profile, implementers write the reason first and the fix rounds go away | T5 and T6 `mini-review-r*.yaml` (R2) | approved | "Approve all (Recommended)", 5.3 |
