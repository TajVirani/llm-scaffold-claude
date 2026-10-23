# 3.10 Live runs of the review-lessons lens (in place of the browser suite)

Spec: 002-review-lessons · Step 3.10 · 2026-10-22 · Merged spec branch at `be54c3e` (every task done, gate-3.9-w2 green: 44 suites, 2588 passed).

The project has no e2e work type, so the two journeys the harness cannot run (no LLM) were run by hand, as `verification-plan.md` § Journeys records. Each fixture repo was built with `review_lessons_repo DIR <mode>` from `tests/fixtures/review-lessons.sh` (one lesson `RL-001`, a spec `001-fixture` at `in-review` with `baseline_revision` set to the init commit, then one commit adding `src/report.sh`), placed under the gitignored `.workflow/.worktrees/` so the launch hook resolved the fixture's own `.workflow/` (its spec folder and its `model-map/review-lessons.md`, cheap tier). The lens was launched exactly as `modules/review-triage.md` step 2 launches it: `subagent_type: review-lessons`, the launch header with `spec_dir: .workflow/specs/001-fixture`, and the one-line task "Review pass 1 of .workflow/specs/001-fixture. Write the review-findings block to your pass file and return the summary block." Nothing else was passed. Each pass file was checked with `.agents/skills/feature-workflow/scripts/check-review-findings.sh` at its fixture path (the script derives the pass from the `pass-1` folder); the file and the check output are copied beside this record.

## JRN-001: lens finds a repeated lesson (fixture `repeat`: `cat "$1"` with no existence check)

- Summary block returned: `findings: {total: 1, high: 1, medium: 0, low: 0}`, `discovered_work: 0`, id line `RL-1 high: src/report.sh:4 opens its first argument with cat "$1" without checking the file exists, repeating RL-001`.
- Pass file [jrn-001.yaml](jrn-001.yaml): `status: done`; exactly one finding, `id: RL-1`, `category: lesson`, `severity: high`, `confidence: 85`, `lesson: RL-001`, `location: src/report.sh:4`; `checked` lists `.workflow/review-lessons.md` and `.workflow/decisions/pitfalls.md`; `not_checked` names the missing retrospectives folder and the empty pitfalls file.
- Check [jrn-001.check.txt](jrn-001.check.txt): exit 0, header `findings: 1 (high 1, medium 0, low 0)`, one row `RL-1  lesson  high  85  src/report.sh:4`.
- The fixture repo was unchanged apart from the pass file (`git status`: only `artifacts/` untracked).

Verdict: pass (expected outcome met exactly).

## JRN-002: lens stays silent without the repeat (fixture `clean`: `[[ -f "$1" ]]` guard before `cat`)

- Summary block returned: `findings: {total: 0, high: 0, medium: 0, low: 0}`, `discovered_work: 0`, `ids: []`.
- Pass file [jrn-002.yaml](jrn-002.yaml): `status: done`, `findings: []`; `checked` lists the lessons file and pitfalls (see the file for `not_checked`).
- Check [jrn-002.check.txt](jrn-002.check.txt): exit 0, header `findings: 0 (high 0, medium 0, low 0)`.

Verdict: pass.

Both journeys pass, so 3.11 sets the spec `in-review`.

## Runs after the review rework (2026-10-22, spec branch `7507db6`)

The module runs 3.10 again after a rework. Run 2 of JRN-001 (after rework 1, before the T3 fix) **failed**: `findings: []`, the lens scored the same hunk at about 60 and put RL-001 under `not_checked`, reasoning that the lesson's consequence clause ("a confusing error far from the call") was only partly repeated ([jrn-001-run2-after-rework.yaml](jrn-001-run2-after-rework.yaml)). 3.11 reopened T3: the lens now matches a lesson on the mistake its symptom names and treats the consequence clause as context (merged as `7507db6`). Runs 3 are against that lens, on rebuilt fixtures:

- **JRN-001 run 3** ([jrn-001.yaml](jrn-001.yaml), [jrn-001.check.txt](jrn-001.check.txt)): `RL-1`, `category: lesson`, `severity: high`, `confidence: 85`, `lesson: RL-001`, `location: src/report.sh:4`; check exit 0, header `findings: 1 (high 1, medium 0, low 0)`. Pass. The lens's summary block carried extra "Notes for triage" lines after the block and it left a scratch file in the temp dir (removed); both recorded for the retrospective as model observations.
- **JRN-002 run 3** ([jrn-002.yaml](jrn-002.yaml), [jrn-002.check.txt](jrn-002.check.txt)): `findings: []`, `status: done`, lessons file and pitfalls under `checked`; check exit 0. Pass.
- Run 1 evidence is kept as `jrn-001-run1.yaml` and `jrn-002-run1.yaml` with their checks.

Three live runs of JRN-001 in all: two passes (before the rework and after the T3 fix) and one failure in between on the unchanged lens, so the lens's judgement at the cheap tier is a sample, not a proof; the T3 fix removes the reasoning that produced the miss.
