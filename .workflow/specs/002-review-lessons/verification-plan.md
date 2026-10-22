# Verification plan: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-review-lessons-lens: a `review-lessons` launch (header plus "Review pass 1 of <spec>") against a fixture repo whose `.workflow/review-lessons.md` holds one lesson and whose diff since `baseline_revision` repeats it returns a `review-findings` block with `lens: review-lessons`, `status: done` and exactly one finding, id `RL-1`, `severity: high`, `confidence` at least 80, `lesson: RL-001`; the same launch against a diff that does not repeat it returns `findings: []`.
- [ ] CAP-NEW-review-lessons-lens: both returned blocks pass the triage yq check from `review-triage.md` with `LENS=review-lessons PFX=RL`, unchanged except for the prefix mapping.
- [ ] CAP-NEW-review-lessons-lens: `pre-launch.sh` allows a `review-lessons` launch whose header holds `spec_dir` and resolves its model from `.workflow/model-map/review-lessons.md`; with that file removed and no override it denies the launch naming 00.14; a header without `spec_dir` is denied.
- [ ] CAP-NEW-review-lessons-lens: `steps.tsv` holds `4.9` directly after `4.3`; `step-progress.sh` prints "step 4 of 9" for 4.9 and "step 5 of 9" for 4.4 on both paths; the frontmatter, step-list, symlinks and upstream-lineage lint suites pass.
- [ ] CAP-NEW-review-lessons-record: in a fixture repo with a spec whose `.step` is 5.7, `check-write.sh --path .workflow/review-lessons.md` exits 0 and `tier-a-write-guard.sh` allows a Write payload for it; at 0.3.7, 5.3, 4.9 and 0.1.4 the script exits 2 and the hook prints the deny JSON.
- [ ] CAP-NEW-review-lessons-record: the retrospective's routing names the review lesson as a destination it writes; appending one entry by its documented procedure to a file created from the template yields a file that passes the yq validation, with the next id and no other change; a retired entry keeps its id and carries `retired` and `enforced_by`.
- [ ] CAP-NEW-review-lessons-record: the template `.agents/skills/feature-workflow/assets/review-lessons.md` validates with an empty list, and project-setup's `modules/files.md` lists it as the source of `.workflow/review-lessons.md`.
- [ ] CAP-NEW-review-lessons-lens: `.agents/install-manifest.txt` lists the agent, `PROVENANCE.md` and `assetlist.md` carry its entries, `README.md` names four lenses, and `generate-codex-agents.sh` emits a toml for it.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Lens finds a repeated lesson | CAP-NEW-review-lessons-lens | 1. Build the live-run fixture repo (one lesson `RL-001`, a spec with `baseline_revision`, a committed diff that repeats the lesson). 2. Launch `review-lessons` with the header and the one-line task. 3. Save the returned block under `artifacts/review-lessons/jrn-001.yaml`. 4. Run the triage yq check with `PFX=RL` on it. | Exactly one finding, `RL-1`, high, `lesson: RL-001`, located in the diff; the check prints true. | live run by hand (D8), evidence `artifacts/review-lessons/jrn-001.yaml`; MISSING in the harness (no LLM) |
| JRN-002 | Lens stays silent without the repeat | CAP-NEW-review-lessons-lens | 1. Same fixture, diff replaced by one that does not repeat the lesson. 2. Launch. 3. Save under `artifacts/review-lessons/jrn-002.yaml`. 4. Run the yq check. | `findings: []`, `status: done`, the lessons file and pitfalls listed under `checked`; the check prints true. | live run by hand (D8), evidence `artifacts/review-lessons/jrn-002.yaml`; MISSING in the harness |
| JRN-003 | Canned lens return passes triage validation | CAP-NEW-review-lessons-lens | 1. Write the expected JRN-001 block to a file. 2. Run the triage yq check with `PFX=RL`. 3. Run it on a block with an `RS-` id and on one with confidence 70. | First prints true; the other two fail. | `tests/scripts/review-lessons.sh` / MISSING |
| JRN-004 | Guard allows at 5.7 and denies elsewhere | CAP-NEW-review-lessons-record | 1. Fixture repo with a spec; set `.step` to 5.7. 2. `check-write.sh --path .workflow/review-lessons.md`. 3. Hook `tier-a-write-guard.sh` with a Write payload for the file. 4. Repeat at 0.3.7, 5.3, 4.9, 0.1.4. | Step 2 exits 0 and step 3 allows at 5.7; both deny at every other step, the hook with the deny JSON. | `tests/scripts/review-lessons.sh` / MISSING |
| JRN-005 | Launch accepted with the header, refused without a model | CAP-NEW-review-lessons-lens | 1. Fixture with `.workflow/model-map/review-lessons.md`. 2. Run `pre-launch.sh` with a `review-lessons` Agent payload whose prompt starts with the header. 3. Remove the model-map file and rerun. 4. Rerun with a header lacking `spec_dir`. | Step 2 allows with the resolved model; step 3 denies naming 00.14; step 4 denies. | `tests/scripts/review-lessons.sh` (or the existing `tests/hooks/pre-launch.sh` extended) / MISSING |
| JRN-006 | Retrospective procedure writes one entry and nothing else | CAP-NEW-review-lessons-record | 1. Fixture with the file copied from the template and a spec at 5.7. 2. Apply the documented append procedure for one approved candidate. 3. Validate with yq; diff the repo. 4. Apply the documented retirement to that entry. | One entry `RL-001`; only the lessons file changed; after retirement the entry stays with `retired` and `enforced_by` and the next id would be `RL-002`. The agent's own judgement runs for real at this spec's 5.7 and is recorded in its retrospective. | `tests/scripts/review-lessons.sh` / MISSING |
| JRN-007 | Progress line counts the new step fourth | CAP-NEW-review-lessons-lens | 1. Set a fixture spec's `.step` to 4.9, then 4.4. 2. Run `step-progress.sh` on the full and the light path. | "step 4 of 9" then "step 5 of 9" on both paths. | `tests/scripts/step-progress.sh` extended / MISSING |
| JRN-008 | Template and project-setup row | CAP-NEW-review-lessons-record | 1. Validate the template with yq. 2. Grep `project-setup/modules/files.md` for the target and source. | Empty list validates; the row names the feature-workflow template. | `tests/scripts/review-lessons.sh` / MISSING |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Fixture lesson `RL-001` (the only lesson text this feature writes, fixtures only) | `symptom`: "A script under `src/` opens a file path taken from its arguments without first checking the file exists, so a missing file surfaces as a confusing error far from the call." `paths: ["src/**"]`, `origin_spec: .workflow/specs/001-fixture`, `date: 2026-10-21` | the harness suite's fixture builder (`tests/lib/common.sh` `make_fixture_repo` plus the suite's own `.workflow/` files); the live run reuses the same builder with a kept scratch dir | JRN-001, JRN-002, JRN-003, JRN-006 |
| Repeating diff | adds `src/report.sh` that runs `cat "$1"` with no existence check | the suite's fixture builder, committed after `baseline_revision` | JRN-001 |
| Non-repeating diff | adds `src/report.sh` that checks `[[ -f "$1" ]]` and dies before reading | the suite's fixture builder | JRN-002 |
| Expected lens block | the JRN-001 block written by hand: one `RL-1` high finding with `lesson: RL-001` | the suite (heredoc) | JRN-003 |
| Guard oracle | exit 0 and allow at 5.7; exit 2 and the deny JSON at every other step | `check-write.sh` exit codes and `_guard-common.sh` deny shape | JRN-004 |
| Launch oracle | allow JSON with `updatedInput` carrying the model; deny JSON naming 00.14 | `pre-launch.sh` output shapes already pinned by `tests/hooks/pre-launch.sh` | JRN-005 |
| yq validation expression | `.lessons` is a sequence; every item has the five required fields with the rules in data-model.md; `retired` implies `enforced_by`; ids unique | the template's header comment (one home) | JRN-003, JRN-006, JRN-008 |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| <filled at 1.1> | | | | |

## Suites

<!-- 1.2-1.4. Filled by modules/verification-setup.md. Commands come from the profile Toolchain keys, not from this file: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` | <filled at 1.2> | none | |
| Browser | `e2e` | not applicable (no browser) | none | |
