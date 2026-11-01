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
| `.workflow/review-lessons.md`, when present | Recorded review lessons: a new candidate that repeats one is "already present", and one this feature's approved 5.3 proposals now enforce is a retirement candidate |
| The previous retrospective | The highest-numbered other file in `.workflow/decisions/retrospectives/` |
| Session logs, when they exist | Why a session took an unexpected turn. They are the evidence most likely to expire, so capture references now. |

On the light path (`light_path: true`), the feature went from 0.3.20 straight to implementation, so `verification-plan.md` is absent by design. Record it as "not produced (light path)", not as missing, and judge against `spec.md` alone.

If later work has landed on top of the feature, end the git range at the feature's last commit, judged from the commit subjects and `tasks.md`, and record that cut. With no `baseline_revision`, record that commit and diff evidence are unavailable.

## Missing evidence

Never hide a gap. Each later step that needs an absent source records a narrowed scope, so a reader can tell "checked and clean" from "never checked":

- No `report.md`: the result judgement relies on tests you run now, and says so.
- No session logs: process lessons come only from `design-log.md` and the stakeholder, and the document says so.
- No triage entries: findings come from `report.md` and step 3 only.

## Measurements

Fill the document's **Measurements** table from the spec folder and git. Each number comes from a file; write `not recorded` for one the files do not hold, never an estimate. Run from the project root, `<range>` being the git range above:

```bash
S=.workflow/specs/NNN-slug
git log --reverse --format=%cI <range> | sed -n '1p;$p'          # Elapsed: first and last commit time
grep -cE 'Answer:|^- (Approval|PR description|Backlog [^:]*|Going-in concerns):' "$S/design-log.md"   # Waits: answers recorded
for k in implementation mini-review integration; do printf '%s %s\n' "$k" "$(ls "$S"/artifacts/*/"$k"*.yaml 2>/dev/null | wc -l)"; done
printf 'review lenses %s\n' "$(ls "$S"/artifacts/review/pass-*/*.yaml 2>/dev/null | wc -l)"
jq -r 'select((.reused_from // .task_id) == .task_id) | .results[] | select(.key == "test" and .reused_from == null and .status != "skipped") | .status' "$S"/artifacts/*/toolchain.json | sort | uniq -c   # Harness runs
grep -l '^verdict: "fail"' "$S"/artifacts/*/mini-review*.yaml | wc -l    # mini-review fails
```

- **Elapsed:** the first design-log entry's date, then the first and last commit times and the span between them in hours and minutes.
- **Waits:** the count of answers the log records. The minutes spent waiting are not in the files: `not recorded`.
- **Agent launches:** one result file per launch or fix round, by type. Discovery launches leave no file: `not recorded`.
- **Harness runs:** the records whose `test` ran, by status; the other records with a `test` result reused it. Each evidence dir keeps only its newest run, so the count is a floor.
- **Findings by class:** the triage entries' rows in `design-log.md` by verdict (`high`, `medium`, `low`, `maybe-false`, `false`) and by route (patch, defer, dismissed, discovered work), and the mini-review fails.

Done when every row of the inventory is recorded in Summary as a path, `missing`, or "not produced", with the git range stated, and every Measurements row holds a number or `not recorded`.
