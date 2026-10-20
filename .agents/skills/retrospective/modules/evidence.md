# Evidence

List what the feature produced so every later step works from artifacts rather than memory. Record each source's path, or `missing`, in the document's **Summary**.

## Inventory

| Source | Read for |
| --- | --- |
| `.workflow/specs/NNN-slug/spec.md` | Capabilities (`CAP-###`), constraints, non-goals, success signal; frontmatter `baseline_revision`, `deferred[]`, `followup_review_recommended`, `light_path` |
| `.workflow/specs/NNN-slug/verification-plan.md` | Journeys (`JRN-###`) and targets |
| `.workflow/specs/NNN-slug/report.md` | Test output, targets against measured values, known gaps, evidence links |
| `.workflow/specs/NNN-slug/tasks.md` | Each task's `status` (read with `yq --front-matter=extract '.tasks[] \| [.id, .status] \| @tsv'`) |
| `.workflow/specs/NNN-slug/design-log.md` | Triage entries from each review pass (finding ids, verdicts, routes), decisions and their reversals, deep dives |
| `.workflow/specs/NNN-slug/proposals.md` | What 5.3 approved, modified or rejected |
| `.workflow/specs/NNN-slug/artifacts/` | Toolchain output per task, browser evidence per journey |
| `.workflow/deferred/*.md` whose `origin_spec` is this spec | What was shelved, and why |
| Git, from `baseline_revision` to `HEAD` | `git log --oneline <baseline>..HEAD` and `git diff --stat <baseline>..HEAD`: commits and change volume |
| The previous retrospective | The highest-numbered other file in `.workflow/decisions/retrospectives/` |
| Session logs, when they exist | Why a session took an unexpected turn. They are the evidence most likely to expire, so capture references now. |

On the light path (`light_path: true`), the feature went from 0.3.20 straight to implementation, so `verification-plan.md` is absent by design. Record it as "not produced (light path)", not as missing, and judge against `spec.md` alone.

If later work has landed on top of the feature, end the git range at the feature's last commit, judged from the commit subjects and `tasks.md`, and record that cut. With no `baseline_revision`, record that commit and diff evidence are unavailable.

## Missing evidence

Never hide a gap. Each later step that needs an absent source records a narrowed scope, so a reader can tell "checked and clean" from "never checked":

- No `report.md`: the result judgement relies on tests you run now, and says so.
- No session logs: process lessons come only from `design-log.md` and the stakeholder, and the document says so.
- No triage entries: findings come from `report.md` and step 3 only.

Done when every row of the inventory is recorded in Summary as a path, `missing`, or "not produced", with the git range stated.
