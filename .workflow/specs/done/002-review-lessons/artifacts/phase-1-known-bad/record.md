# 1.4 Known-bad build: Phase 1 suites against the merged HEAD

Spec: 002-review-lessons · Step 1.4 · 2026-10-22

## Run 1: the baseline is the first known-bad build

- Fault: none injected. The feature does not exist yet: HEAD `47713f3` is the baseline `7289fbf`, the 1.1 commit `0654169` and the merge of `phase-1-test-harness` (`176bb08`: one new suite, one fixture file, seven extended suites, the step-list pins). No `review-lessons` agent definition, template, model-map entry, guard class, launch row or `4.9` step row exists.
- Where: a detached throwaway worktree at HEAD, removed afterwards.
- Command: `tests/run-all.sh -v` (the `test` key of `.workflow/profiles/test-harness.md`, verbose); full output in `harness.log` beside this file.
- Exit code: 1. `TOTAL passed=2516 failed=66 skipped=0 xfail=0 (44 suites)`.
- Reference run on main `4724073` before Phase 1 (43 suites): `TOTAL passed=2507 failed=0`. Those 43 suites still pass here, except the seven that 1.2 extended, which fail only on their new assertions and on the count pins updated for the new step: `resolve-launch` "all 14 types", `step-progress` 4.7 "step 8 of 9", light-path 4.1 "step 1 of 9", `--spec-dir` 4.2 "step 2 of 9", and the two `lint/step-list` Phase 4 pins at 9.
- Every suite reached its `RESULT` line (44 of 44). Every failure is a `FAIL` line from `t`, `eq` or `check`, so an assertion failure: the detail names the missing lens row, the unguarded path, the unknown task type, the old step count, the missing template line or the missing file. No bash-level error (`<script>: line N:`), no sourcing error, no `preflight` exit, no crash.
- Assertions that pass on this build in the new suite (3 of 33) are the `shellcheck_files` assertion and two regression guards; every journey with a harness check (JRN-003 to JRN-008) has failing assertions on the behaviour the feature must add.

Verdict: pass. Both conditions of 1.4 hold for the harness: red on a known-bad build, red on assertions.

## Run 2: injected fault for the browser suite

Not applicable. The project has no e2e work type and no browser suite (`.workflow/profiles/` holds no `e2e-browser`); `verification-plan.md` § Suites recorded the Browser row as not applicable at 0.6, and JRN-001 and JRN-002 are live runs by hand (D8) in place of a browser suite.

## Run 3: StrykerJS on the harness

Skipped, and said so here: the stack is bash, StrykerJS is a JavaScript mutation tool and is not installed. The feature changes no existing JavaScript behaviour.

## Failing assertions per suite (each with its detail line)

### scripts/check-review-findings
RESULT passed=111 failed=8 skipped=0 xfail=0

- FAIL JRN-003 lessons: exit 0  ->  got=1 want=0
- FAIL JRN-003 lessons: header counts one high finding  ->  lens: 'review-lessons' is not review-standards, review-end-state or review-targets
- FAIL JRN-003 lessons: one RL-1 lesson row, high, confidence 90, in the diff  ->  lens: 'review-lessons' is not review-standards, review-end-state or review-targets
- FAIL JRN-003 lessons: no other finding rows  ->  got=1 want=3
- FAIL JRN-003 lessons: an RS- id: one line naming findings[0].id  ->  got=1:lens want=1:findings[0].id
- FAIL JRN-003 lessons: confidence 70: one line naming findings[0].confidence  ->  got=1:lens want=1:findings[0].confidence
- FAIL JRN-003 lessons, no findings: exit 0  ->  got=1 want=0
- FAIL JRN-003 lessons, no findings: header counts none  ->  lens: 'review-lessons' is not review-standards, review-end-state or review-targets

### scripts/check-write-tier-a
RESULT passed=103 failed=9 skipped=0 xfail=0

- FAIL JRN-004 review-lessons.md at 5.7 sub-agent deny  ->  rc=0 want=2: allow: .workflow/review-lessons.md is not a guarded path
- FAIL JRN-004 review-lessons.md at 0.3.7 deny  ->  rc=0 want=2: allow: .workflow/review-lessons.md is not a guarded path
- FAIL JRN-004 review-lessons.md at 0.3.7: a deny naming 5.7 on stderr
- FAIL JRN-004 review-lessons.md at 5.3 deny  ->  rc=0 want=2: allow: .workflow/review-lessons.md is not a guarded path
- FAIL JRN-004 review-lessons.md at 5.3: a deny naming 5.7 on stderr
- FAIL JRN-004 review-lessons.md at 4.9 deny  ->  rc=0 want=2: allow: .workflow/review-lessons.md is not a guarded path
- FAIL JRN-004 review-lessons.md at 4.9: a deny naming 5.7 on stderr
- FAIL JRN-004 review-lessons.md at 0.1.4 deny  ->  rc=0 want=2: allow: .workflow/review-lessons.md is not a guarded path
- FAIL JRN-004 review-lessons.md at 0.1.4: a deny naming 5.7 on stderr

### scripts/resolve-launch
RESULT passed=92 failed=3 skipped=0 xfail=0

- FAIL requirements: all 14 types  ->  assert failed: keys|length==14; out: {
- FAIL requirements: review-lessons is listed  ->  assert failed: has("review-lessons"); out: {
- FAIL requirements: review-lessons is a Phase 4 lens row  ->  exit 2 (want 0) stderr: resolve-launch.sh: unknown task type 'review-lessons' (known: cache-regeneration, fact-lookup, implementation, integration, library-evaluation, mo

### scripts/step-progress
RESULT passed=57 failed=9 skipped=0 xfail=0

- FAIL full: 4.7 runs eighth, after 4.9  ->  got=Phase 5 of 6 · step 7 of 8 — Review and triage: Rework attempts remaining? (4.7) want=Phase 5 of 6 · step 8 of 9 — Review and triage: Rework attempts remaining?
- FAIL light: 4.1  ->  got=Phase 3 of 4 · step 1 of 8 — Review and triage: Standards review (4.1) want=Phase 3 of 4 · step 1 of 9 — Review and triage: Standards review (4.1)
- FAIL --spec-dir: an explicit id wins over .step  ->  got=Phase 3 of 4 · step 2 of 8 — Review and triage: End-state review (4.2) want=Phase 3 of 4 · step 2 of 9 — Review and triage: End-state review (4.2)
- FAIL JRN-007 full: 4.9 is step 4 of 9  ->  got= want=Phase 5 of 6 · step 4 of 9 — Review and triage: Review lessons lens (4.9)
- FAIL JRN-007 light: 4.9 is step 4 of 9  ->  got= want=Phase 3 of 4 · step 4 of 9 — Review and triage: Review lessons lens (4.9)
- FAIL JRN-007 full: 4.4 is step 5 of 9  ->  got=Phase 5 of 6 · step 4 of 8 — Review and triage: Triage findings (4.4) want=Phase 5 of 6 · step 5 of 9 — Review and triage: Triage findings (4.4)
- FAIL JRN-007 light: 4.4 is step 5 of 9  ->  got=Phase 3 of 4 · step 4 of 8 — Review and triage: Triage findings (4.4) want=Phase 3 of 4 · step 5 of 9 — Review and triage: Triage findings (4.4)
- FAIL JRN-007 full: 4.8 is step 9 of 9  ->  got=Phase 5 of 6 · step 8 of 8 — Review and triage: Deferred handoffs (4.8) want=Phase 5 of 6 · step 9 of 9 — Review and triage: Deferred handoffs (4.8)
- FAIL JRN-007 light: 4.8 is step 9 of 9  ->  got=Phase 3 of 4 · step 8 of 8 — Review and triage: Deferred handoffs (4.8) want=Phase 3 of 4 · step 9 of 9 — Review and triage: Deferred handoffs (4.8)

### hooks/pre-launch
RESULT passed=17 failed=3 skipped=0 xfail=0

- FAIL JRN-005 review-lessons allow  ->  rc=0 out=
- FAIL JRN-005 review-lessons 00.14  ->  rc=0 out=
- FAIL JRN-005 review-lessons no spec_dir  ->  rc=0 out=

### hooks/write-guards
RESULT passed=98 failed=2 skipped=0 xfail=0

- FAIL JRN-004 review-lessons.md at 0.3.7 denied  ->  rc=0 out=
- FAIL JRN-004 review-lessons.md at 5.3 denied  ->  rc=0 out=

### lint/review-lessons
RESULT passed=3 failed=30 skipped=0 xfail=0

- FAIL JRN-008 the template exists  ->  <worktree>/.agents/skills/feature-workflow/a
- FAIL JRN-008 the template header has a validate: command
- FAIL JRN-008 the template header has a next-id: command
- FAIL JRN-008 the template validates with its own command  ->  no 'validate:' line in the template header
- FAIL JRN-008 the template's next id is RL-001  ->  got= want=RL-001
- FAIL JRN-008 files.md has a row for .workflow/review-lessons.md
- FAIL JRN-008 that row's source is the feature-workflow template
- FAIL JRN-006 a file with RL-001 validates  ->  no 'validate:' line in the template header
- FAIL JRN-006 the next id after RL-001 is RL-002  ->  got= want=RL-002
- FAIL JRN-006 the retired entry still validates  ->  no 'validate:' line in the template header
- FAIL JRN-006 a retired id stays taken: the next id is still RL-002  ->  got= want=RL-002
- FAIL JRN-006 validate: refuses retired-no-enforced-by  ->  no 'validate:' line in the template header
- FAIL JRN-006 validate: refuses duplicate-id  ->  no 'validate:' line in the template header
- FAIL JRN-006 validate: refuses empty-paths  ->  no 'validate:' line in the template header
- FAIL JRN-006 validate: refuses absolute-path  ->  no 'validate:' line in the template header
- FAIL JRN-006 validate: refuses bad-origin-spec  ->  no 'validate:' line in the template header
- FAIL JRN-006 validate: refuses bad-date  ->  no 'validate:' line in the template header
- FAIL JRN-006 validate: refuses lessons-not-a-list  ->  no 'validate:' line in the template header
- FAIL agents/review-lessons.md exists  ->  <worktree>/.agents/agents/review-lessons.md
- FAIL frontmatter keys are exactly name, description, tools  ->  got= want=name,description,tools
- FAIL name is review-lessons  ->  got= want=review-lessons
- FAIL tools are Read, Grep, Glob, Bash  ->  got= want=Read, Grep, Glob, Bash
- FAIL description starts with the step it runs at
- FAIL install-manifest.txt lists agents/review-lessons.md
- FAIL PROVENANCE.md has a line for agents/review-lessons.md
- FAIL README.md names review-lessons beside the other three lenses
- FAIL it emits review_lessons.toml
- FAIL the toml is named review_lessons
- FAIL 4.9 is phase 4 on both paths  ->  got= want=4	both
- FAIL 4.9 comes right after 4.3  ->  got=4.4 want=4.9

### lint/step-list
RESULT passed=34 failed=2 skipped=0 xfail=0

- FAIL full path step counts per phase  ->  got=0:48 1:5 2:6 3:14 4:8 5:9  want=0:48 1:5 2:6 3:14 4:9 5:9 
- FAIL light path step counts per phase  ->  got=0:36 3:15 4:8 5:9  want=0:36 3:15 4:9 5:9 

