# Verification plan: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-002: a `review-lessons` launch (header plus the one-line task "Review pass 1 of <spec>. Write the review-findings block to your pass file and return the summary block.") against a fixture repo whose `.workflow/review-lessons.md` holds one lesson and whose diff since `baseline_revision` repeats it writes a `review-findings` block to `<spec_dir>/artifacts/review/pass-1/review-lessons.yaml` with `lens: review-lessons`, `status: done` and exactly one finding, id `RL-1`, `category: lesson`, `severity: high`, `confidence` at least 80, `lesson: RL-001`, and returns the summary block; the same launch against a diff that does not repeat it writes `findings: []`.
- [ ] CAP-002: both pass files exit 0 from `.agents/skills/feature-workflow/scripts/check-review-findings.sh`, whose lens table gains one row (`review-lessons`: prefix `RL`, category `lesson`) and nothing else; a `lesson` finding under any other lens, an `RS-` id under this lens, and a confidence below 80 each exit 1 naming the field.
- [ ] CAP-002: `pre-launch.sh` allows a `review-lessons` launch whose header holds `spec_dir` and resolves its model from `.workflow/model-map/review-lessons.md`; with that file removed and no override it denies the launch naming 00.14; a header without `spec_dir` is denied.
- [ ] CAP-002: `steps.tsv` holds `4.9` directly after `4.3`; `step-progress.sh` prints "step 4 of 9" for 4.9 and "step 5 of 9" for 4.4 on both paths; the frontmatter, step-list, symlinks and upstream-lineage lint suites pass.
- [ ] CAP-003: in a fixture repo with a spec whose `.step` is 5.7, `check-write.sh --path .workflow/review-lessons.md` exits 0 and `tier-a-write-guard.sh` allows a Write payload for it; at 0.3.7, 5.3, 4.9 and 0.1.4 the script exits 2 and the hook prints the deny JSON.
- [ ] CAP-003: the retrospective's routing names the review lesson as a destination it writes; appending one entry by its documented procedure to a file created from the template yields a file that passes the yq validation, with the next id and no other change; a retired entry keeps its id and carries `retired` and `enforced_by`.
- [ ] CAP-003: the template `.agents/skills/feature-workflow/assets/review-lessons.md` validates with an empty list, and project-setup's `modules/files.md` lists it as the source of `.workflow/review-lessons.md`.
- [ ] CAP-002: `.agents/install-manifest.txt` lists the agent, `PROVENANCE.md` and `assetlist.md` carry its entries, `README.md` names four lenses, and `generate-codex-agents.sh` emits a toml for it.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Lens finds a repeated lesson | CAP-002 | 1. Build the live-run fixture repo (one lesson `RL-001`, a spec with `baseline_revision`, a committed diff that repeats the lesson). 2. Launch `review-lessons` with the header and the one-line task. 3. Copy the pass file it wrote (`artifacts/review/pass-1/review-lessons.yaml` in the fixture spec) to this spec's `artifacts/review-lessons/jrn-001.yaml`. 4. Run `check-review-findings.sh` on it. | Exactly one finding, `RL-1`, high, `category: lesson`, `lesson: RL-001`, located in the diff; the check exits 0 and its header line counts one high finding. | live run by hand at the 3.10 gate in place of the browser suite (D8), fixture from `tests/fixtures/review-lessons.sh` (`review_lessons_repo DIR repeat`), evidence `artifacts/review-lessons/jrn-001.yaml`; no harness check (no LLM) |
| JRN-002 | Lens stays silent without the repeat | CAP-002 | 1. Same fixture, diff replaced by one that does not repeat the lesson. 2. Launch. 3. Copy the pass file to `artifacts/review-lessons/jrn-002.yaml`. 4. Run `check-review-findings.sh` on it. | `findings: []`, `status: done`, the lessons file and pitfalls listed under `checked`; the check exits 0 with zero findings. | live run by hand at the 3.10 gate in place of the browser suite (D8), fixture `review_lessons_repo DIR clean`, evidence `artifacts/review-lessons/jrn-002.yaml`; no harness check (no LLM) |
| JRN-003 | Canned lens pass file passes the triage check | CAP-002 | 1. Write the expected JRN-001 block to `artifacts/review/pass-1/review-lessons.yaml` in a fixture spec. 2. Run `check-review-findings.sh` on it. 3. Run it on a copy with an `RS-` id, on one with confidence 70, and on one with `category: lesson` under `lens: review-standards`. | First exits 0, header line `findings: 1 (high 1, ...)` and one `RL-1  lesson  high` row; the other three exit 1 naming the field. | `tests/scripts/check-review-findings.sh`, the JRN-003 assertions (8) |
| JRN-004 | Guard allows at 5.7 and denies elsewhere | CAP-003 | 1. Fixture repo with a spec; set `.step` to 5.7. 2. `check-write.sh --path .workflow/review-lessons.md`. 3. Hook `tier-a-write-guard.sh` with a Write payload for the file. 4. Repeat at 0.3.7, 5.3, 4.9, 0.1.4. | Step 2 exits 0 and step 3 allows at 5.7; both deny at every other step, the hook with the deny JSON. | `tests/scripts/check-write-tier-a.sh` (9) and `tests/hooks/write-guards.sh` (2), the JRN-004 assertions |
| JRN-005 | Launch accepted with the header, refused without a model | CAP-002 | 1. Fixture with `.workflow/model-map/review-lessons.md`. 2. Run `pre-launch.sh` with a `review-lessons` Agent payload whose prompt starts with the header. 3. Remove the model-map file and rerun. 4. Rerun with a header lacking `spec_dir`. | Step 2 allows with the resolved model; step 3 denies naming 00.14; step 4 denies. | `tests/hooks/pre-launch.sh`, the JRN-005 assertions (3) |
| JRN-006 | Retrospective procedure writes one entry and nothing else | CAP-003 | 1. Fixture with the file copied from the template and a spec at 5.7. 2. Apply the documented append procedure for one approved candidate. 3. Validate with yq; diff the repo. 4. Apply the documented retirement to that entry. | One entry `RL-001`; only the lessons file changed; after retirement the entry stays with `retired` and `enforced_by` and the next id would be `RL-002`. The agent's own judgement runs for real at this spec's 5.7 and is recorded in its retrospective. | `tests/lint/review-lessons.sh`, the JRN-006 assertions (11), through the template's own `validate:` and `next-id:` commands |
| JRN-007 | Progress line counts the new step fourth | CAP-002 | 1. Set a fixture spec's `.step` to 4.9, then 4.4. 2. Run `step-progress.sh` on the full and the light path. | "step 4 of 9" then "step 5 of 9" on both paths. | `tests/scripts/step-progress.sh`, the JRN-007 assertions (6) plus three count pins moved from 8 to 9 |
| JRN-008 | Template and project-setup row | CAP-003 | 1. Validate the template with yq. 2. Grep `project-setup/modules/files.md` for the target and source. | Empty list validates; the row names the feature-workflow template. | `tests/lint/review-lessons.sh`, the JRN-008 assertions (7); the same suite also pins the asset set (agent frontmatter, manifest, PROVENANCE, README, Codex toml, `4.9` row) |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Fixture lesson `RL-001` (the only lesson text this feature writes, fixtures only) | `symptom`: "A script under `src/` opens a file path taken from its arguments without first checking the file exists, so a missing file surfaces as a confusing error far from the call." `paths: ["src/**"]`, `origin_spec: .workflow/specs/001-fixture`, `date: 2026-10-21` | the harness suite's fixture builder (`tests/lib/common.sh` `make_fixture_repo` plus the suite's own `.workflow/` files); the live run reuses the same builder with a kept scratch dir | JRN-001, JRN-002, JRN-003, JRN-006 |
| Repeating diff | adds `src/report.sh` that runs `cat "$1"` with no existence check | the suite's fixture builder, committed after `baseline_revision` | JRN-001 |
| Non-repeating diff | adds `src/report.sh` that checks `[[ -f "$1" ]]` and dies before reading | the suite's fixture builder | JRN-002 |
| Expected lens block | the JRN-001 block written by hand in the pass-file shape of `.agents/agents/review-standards.md` § Return: one `RL-1` high finding, `category: lesson`, `lesson: RL-001` | the suite (heredoc) | JRN-003 |
| Guard oracle | exit 0 and allow at 5.7; exit 2 and the deny JSON at every other step | `check-write.sh` exit codes and `_guard-common.sh` deny shape | JRN-004 |
| Launch oracle | allow JSON with `updatedInput` carrying the model; deny JSON naming 00.14 | `pre-launch.sh` output shapes already pinned by `tests/hooks/pre-launch.sh` | JRN-005 |
| yq validation expression | `.lessons` is a sequence; every item has the five required fields with the rules in data-model.md; `retired` implies `enforced_by`; ids unique | the template's header comment (one home) | JRN-003, JRN-006, JRN-008 |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean, Phase 4 counted as 9 | errors | exit 0; each of the four lint suites reports 0 failed, the step-list suite with its Phase 4 pin at 9 on both paths | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain; `spec.md` Constraints ("the Phase 4 count becomes 9 on both paths") |
| Every script this spec adds or changes has a suite | coverage | `0` printed (no uncovered script) | the `script-coverage` command below: scripts under `.agents/` and `install.sh` added or modified since `baseline_revision` whose file name no file under `tests/` mentions | `.workflow/profiles/test-harness.md` § Mini-review checklist ("A new or changed script has a suite ending in a `shellcheck_files` assertion") |
| Every new `.agents/` asset is in the manifest (agents) and `PROVENANCE.md` (all) | coverage | `0` printed (no unlisted asset) | the `asset-coverage` command below: files added under `.agents/` since `baseline_revision`; an agent definition must be a line of `.agents/install-manifest.txt`, and every file's name must appear in `PROVENANCE.md` | `spec.md` Constraints ("Every new first-party asset is listed in `.agents/install-manifest.txt` and `PROVENANCE.md`"); `.workflow/rules.md` § Cross-cutting policy |
| Guard and launch hook wall time | performance | none | not measured: stakeholder decision at 1.1 (no performance target), as for spec 001-large-path. The required stack has no bash profiler, and the hook timeouts in `.claude/settings.json` (10 s for the write guards, 30 s for `pre-launch.sh`) are the only ceiling | stakeholder decision, 1.1 (2026-10-22) |

Commands referenced above (pipes keep them out of the table cells); each runs from the project root:

```bash
# script-lint
git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of uncovered scripts; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/002-review-lessons/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files missing from the manifest (agent definitions) or from PROVENANCE.md (every file); the threshold is 0
git diff --name-only --diff-filter=A "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/002-review-lessons/spec.md)"..HEAD -- .agents | while read -r f; do case "$f" in .agents/agents/*.md) grep -qxF -- "${f#.agents/}" .agents/install-manifest.txt || echo "manifest: $f";; esac; grep -qF -- "$(basename "$f")" PROVENANCE.md || echo "provenance: $f"; done | wc -l | tr -d ' '
```

## Suites

<!-- 1.2-1.4. Filled by modules/verification-setup.md. Commands come from the profile Toolchain keys, not from this file: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md), full log [harness.log](artifacts/phase-1-known-bad/harness.log): 66 failures across the 1 new suite (`tests/lint/review-lessons.sh`) and the 7 extended ones, all assertions |
| Browser | `e2e`: not applicable (no e2e work type, no browser; JRN-001 and JRN-002 are live runs by hand, D8) | none | none | not applicable; see record.md Run 2 |
