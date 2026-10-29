---
status: in-progress # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "a36d149d8cf9b181f1aaf5c3917fb75b7b536534" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/008-pr-description-template # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "103fe9d53a99442833b0e2dace9237e148c536f2" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/spec-issue-creation.md, .workflow/deferred/workflow-settings-home.md, .workflow/deferred/initiative-pr-template.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
# initiative: NNN-slug               # optional; the initiative this spec was emitted from, present only on an emitted spec
budget: {max_tasks: 10, max_changed_files: 30} # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# PR description template

## Why

Every Sign-off PR should tell a reviewer, human or AI, what the change is for, prove it works, and say what it could break and how to undo it, so nobody has to open the spec folder to judge it. Today sign-off 5.8 opens the PR with a title and links only, and a local merge carries no message at all. Reviewers judge a diff against its stated intent, the person directing the agent signs off on it, and a change whose undo steps cannot be written is a warning sign; a fixed PR template filled from the evidence the spec already holds gives every reviewer that intent, that evidence and that undo path in one place.

## Capabilities

- **CAP-NEW-pr-template** PR template for the Sign-off PR
  - **intent:** Sign-off fills a fixed PR template from the spec's evidence, the stakeholder approves the exact text, and 5.8 publishes it as the Sign-off PR description (or the local merge message), so reviewers see intent, evidence, blast radius, risk and undo steps without reading the spec folder.
  - **success:** For a spec reaching 5.8, `pr-body.md` holds the ten sections in order (link to issue; what changed; why the change; why this approach; special things to note; how to test, step by step; blast radius; risk and reversibility; areas, concepts and seams changed; how to undo), the check script passes it, and the PR is opened with that file as its body; a body with a missing or empty section, an off-scale score, or Reversibility: Irreversible without Risk: High fails the check.

## Constraints

- No new dependencies: bash, a Markdown template under `.agents/skills/feature-workflow/assets/`, and the `gh` / `glab` CLIs already used.
- The body reaches the host through a file (`gh pr create --body-file`, `glab mr create --description-file`); never `gh --template` together with a body flag, which errors.
- `pr_template` lives in the `## Workflow settings` block of `.workflow/rules.md` and changes only through Tier A steps (`project-setup`, or a proposal approved at 5.3).
- Each section is filled from evidence in the spec folder (commands run and their output, review findings, report.md), not claims.

## Non-goals

- Creating a tracker issue when a spec starts: shelved as [.workflow/deferred/spec-issue-creation.md](../../deferred/spec-issue-creation.md).
- One central home for workflow settings: shelved as [.workflow/deferred/workflow-settings-home.md](../../deferred/workflow-settings-home.md).
- A REVIEW.md for AI review.
- Changing task PR bodies (3.16).
- A filled description for the initiative PR (large path): shelved as [.workflow/deferred/initiative-pr-template.md](../../deferred/initiative-pr-template.md).
- Making the Phase 4 review read the template (later work may; sections stay separately readable).

## Success signal

The next spec to sign off shows the stakeholder a filled PR template at 5.5, and the Sign-off PR (or local merge commit) it opens at 5.8 carries exactly that approved text, passing the check script.

## Assumptions

- "Link to issue" holds a fixed stub line naming the shelved issue-creation item until that item ships.
- `pr_template` is `workflow` or a repo-relative path to the host PR/MR template (`.md`); `rules-setting.sh` rejects a path of the wrong shape or one whose file is missing from the main checkout. With a path, the check script only requires that each of that template's headings, at any level `#` to `######`, appears in the body at the same level with the same text and is non-empty, a section running to the next heading of the same or a higher level; the ten-section order and score checks apply to the workflow template.
- A `pr_template` path whose file is gone, or a host template the check cannot use (unreadable, or no headings), stops 5.4; the stakeholder chooses the workflow template for that PR or a fixed path through a 5.2/5.3 proposal. Never a silent fallback.
- Host templates are looked for only at `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md` and `.gitlab/merge_request_templates/*.md`; the choice offers each path found plus `workflow`.
- With `pr_template` unset and no host template in the repo, the workflow template is used and nothing is asked.
- The template lives at `.agents/skills/feature-workflow/assets/pr-template.md`; the filled copy is `pr-body.md` in the spec folder, committed with it.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
