# Data model: Tracker issues as spec IDs

Spec: [spec.md](spec.md) · Placement: issue-tracking

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Tracker settings (`.workflow/issue-tracking.yaml`) | entity | create | issue-tracking |
| Tracker issue | entity (on the remote) | create | issue-tracking |
| Spec `tracker_issue` | field | extend | feature-workflow |
| Task record `issue` | field | extend | feature-workflow |
| Spec folder name `NNN-slug` | field | extend (number source) | feature-workflow |
| Done folder name `old_NNN-slug` | field | extend | lib, feature-workflow |
| Tracker script CLI | interface | create | issue-tracking |
| `status-transition.sh` spec and task writers | interface | extend | feature-workflow |
| `wf_norm_folder` | interface | extend | lib |
| PR template "Link to issue" | interface | extend | feature-workflow |
| Initiative numbering and slices | entity | unchanged | feature-workflow |
| `next-spec-number.sh` | interface | create | feature-workflow |
| Shared path rewrite and host choice functions | interface | create | lib |
| Done backlog list name `old_NNN-slug.md` | field | extend | feature-workflow |

## Entities

### Tracker settings (create)

The project's choice of tracker host and its **Issue flow**, saved once by setup or **Tracker adoption**. Absent means no tracker.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `issue_tracker` | `gitlab \| github \| none` | yes | one of the three; must match the `origin` host when not `none` (CAP-NEW-issue-tracking-setup) | create |
| `issue_flow.backlog` | string | when not `none` | non-empty label name that exists on the tracker (CAP-NEW-issue-tracking-setup) | create |
| `issue_flow.in_progress` | string | when not `none` | as above, distinct from the other two | create |
| `issue_flow.done` | string | when not `none` | as above, distinct from the other two | create |

**Invalid states ruled out:** a tracker without a flow: the three labels are required whenever `issue_tracker` is not `none`, and the reader refuses the file otherwise. Still representable: a label deleted on the tracker after setup; the move call fails with the label's name and the spec stops (D9).

### Tracker issue (create, on the remote)

A **Tracker issue** for a spec or a task. The workflow stores only its URL; the number is the last path segment.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| number | int | yes | assigned by the tracker; names the spec folder, zero-padded to at least five digits (CAP-NEW-tracker-issues) | create |
| title, body | text | yes | placeholder and empty at creation; spec title and `spec.md` body from 0.3.19 on; a task issue's from its task file (CAP-NEW-tracker-issues) | create |
| stage label | one of the three flow labels | yes | exactly one flow label at a time; done also closes (D5) | create |
| parent | spec's issue | task issues only | GitLab child task, or a `relates_to` link on fallback; GitHub sub-issue (D10) | create |

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| (none) | spec starts (0.1.1) or task breakdown (2.5, 0.3.20) | backlog | tracker reachable, else stop (D9) |
| backlog | spec 3.1, or task launch 3.3 | in progress | |
| in progress | task merged at 3.16 | done, closed | |
| in progress | Sign-off PR merged (`Closes #<n>`) or local merge at 5.8 | done, closed | |
| done | task reopened at 3.9, 3.11 or 4.7 | in progress, reopened | |

**Invalid states ruled out:** two stage labels at once: every move removes the old label and adds the new one in one call. Still representable: a manual edit on the tracker; the workflow never reads the label back, so it does not detect one.

### Spec (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `tracker_issue` | string | no (absent on older specs, `""` with no tracker) | `""` or an `https://` URL of the spec's issue; written with `spec.md` at 0.1.4 from the number `next-spec-number.sh` returned (CAP-NEW-tracker-issues) | extend |
| folder number | digits | yes | the issue number when `tracker_issue` is set, else the 0.1.1 scan (CAP-NEW-tracker-issues) | extend |

### Task (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `issue` | string or null | no | null or an `https://` URL; written once at 2.5 / 0.3.20 through `set-task` (CAP-NEW-tracker-issues) | extend |

### Done folder entry (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| folder name | string | yes | `NNN-slug`, or `old_NNN-slug` after **Tracker adoption**; `old_` is accepted in the Done folder only (CAP-NEW-issue-tracking-setup) | extend |
| backlog list name | string | no | `NNN-slug.md`, or `old_NNN-slug.md` paired with an `old_` Done folder (D21) | extend |

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | `tracker_issue` and `issue` keys in templates, validators and `status-transition.sh` | extend | yes | - | none: absent reads as no tracker |
| M2 | `wf_norm_folder` and `review-lessons.sh` accept `old_` in the Done folder | extend | yes | - | none |
| M3 | **Tracker adoption**, per target project, run by the stakeholder: finished specs renamed `done/old_NNN-slug` and their backlog lists `old_NNN-slug.md`, with `.workflow/` references rewritten | extend | yes (git history; a rename back restores it) | M2 | path rewrite as the Done move does |
| M4 | **Tracker adoption**: each active spec filed as a tracker issue, then folder, backlog list, spec branch and spec worktree renamed and references rewritten; renamed branch pushed when the old one was | extend | partly: local renames are reversible; a created issue can be closed but not deleted, and the pushed branch stays | M1, M3 | refused for a spec with a live task worktree; old remote branch and task PRs reported, never deleted (D16) |
