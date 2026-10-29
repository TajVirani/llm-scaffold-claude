# Verification plan: PR template

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-pr-template: `assets/pr-template.md` holds the ten sections in the agreed order (link to issue; what changed; why the change; why this approach; special things to note; how to test; blast radius; risk and reversibility; areas, concepts and seams changed; how to undo), each a `##` heading with guidance naming its evidence source.
- [ ] CAP-NEW-pr-template: `check-pr-body.sh` exits 0 on a correctly filled body and exits 1 with one `<field>: <problem>` line for each of: a missing section, sections out of order, an empty section, Risk off the Low/Medium/High scale, Reversibility off the Easy/Moderate/Hard/Irreversible scale, and Reversibility: Irreversible without Risk: High.
- [ ] CAP-NEW-pr-template: in project mode, `check-pr-body.sh` exits 0 when every heading of the project's template is present and non-empty, and exits 1 when one is missing or empty.
- [ ] CAP-NEW-pr-template: `rules-setting.sh pr_template` prints `workflow` when the key is absent, prints the set value for `workflow` or `project`, and exits 1 on any other value.
- [ ] CAP-NEW-pr-template: the 5.8 PR is opened with the approved `pr-body.md` as a file (`gh pr create --body-file`, `glab mr create --description-file`), and a local merge commit's message is a Conventional Commits subject followed by that body.
- [ ] CAP-NEW-pr-template: `sign-off.md` fills and checks `pr-body.md` at 5.4, shows its full text for approval at 5.5, adds a `pr_template` proposal row at 5.2 when the key is unset and a host template exists, and reruns the check at 5.8; `project-setup` asks the same question when it writes rules.md and a host template exists.
- [ ] CAP-NEW-pr-template: this spec's own sign-off produces a `pr-body.md` that passes the check and is the description of its Sign-off PR.

## Journeys

The scaffold has no running application or browser suite. Each journey is an end-to-end run of the real scripts against a fixture, checked by a harness suite under `tests/`, except where marked manual.

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | A well-filled body passes | CAP-NEW-pr-template | 1. Copy `assets/pr-template.md` and fill every section (issue stub line, bullets, numbered test steps, `Risk: Medium`, `Reversibility: Easy` with reasons). 2. Run `check-pr-body.sh <file>`. | Exit 0, no problem lines. | `scripts/check-pr-body` (cases `JRN-001 ...`) |
| JRN-002 | Each bad shape is caught | CAP-NEW-pr-template | 1. From the JRN-001 body, make one variant per fault: a section removed, two sections swapped, a section emptied, `Risk: Severe`, `Reversibility: Never`, `Reversibility: Irreversible` with `Risk: Low`. 2. Run the check on each. | Exit 1 each time with one `<field>: <problem>` line naming the fault; a missing file or no argument exits 2. | `scripts/check-pr-body` (cases `JRN-002 ...`) |
| JRN-003 | Project mode checks the project's headings | CAP-NEW-pr-template | 1. Fixture repo with `.github/pull_request_template.md` (three headings) and `pr_template: project`. 2. Check a body that fills all three. 3. Check one with a heading empty, and one missing a heading. | Step 2 exits 0; step 3 exits 1 naming the heading each time. | `scripts/check-pr-body` (cases `JRN-003 ...`) |
| JRN-004 | The setting reads with its default | CAP-NEW-pr-template | 1. Run `rules-setting.sh pr_template --rules <file>` with no Workflow settings block, with the key absent, with `workflow`, with `project`, and with `other`. | Prints `workflow`, `workflow`, `workflow`, `project` (the first two with a default note on stderr); `other` exits 1. | `scripts/task-breakdown` (cases `JRN-004 ...`, beside the `task_review` ones) |
| JRN-005 | The PR and the local merge carry the approved body | CAP-NEW-pr-template | 1. Fixture repo with a spec branch and an approved `pr-body.md`. 2. Run the 5.8 PR call with stand-in `gh` and `glab` that record their arguments. 3. Run the 5.8 local merge. | The stand-ins received `--body-file` / `--description-file` pointing at `pr-body.md` and no `--template`; the merge commit's subject is a Conventional Commits subject and its body equals `pr-body.md`. | `scripts/sign-off-pr` (cases `JRN-005 ...`) |
| JRN-006 | Sign-off and setup text say the new steps | CAP-NEW-pr-template | 1. Grep `modules/sign-off.md` for the 5.2 row, the 5.4 fill and check, the 5.5 full-text approval and the 5.8 body-file calls. 2. Grep `project-setup` for the setup question. 3. Run the agent-docs lint suites. | Every step is present; lint passes. | `scripts/sign-off-pr` (cases `JRN-006 ...`); lint via TGT-003 |
| JRN-007 | This spec signs off with its own template | CAP-NEW-pr-template | 1. Run 5.4 for spec 008. 2. Approve at 5.5. 3. Open the Sign-off PR at 5.8. | `check-pr-body.sh` passed on `pr-body.md` at 5.4 and 5.8; the PR description equals the approved file. | Manual at 5.x (evidence under `artifacts/sign-off-5.4/`) |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Filled template body | A correct body; the oracle is exit 0 | Built in the test from `assets/pr-template.md` | JRN-001, JRN-002 |
| Fault variants | One fault each; the oracle is exit 1 plus the named field | Generated in the test from the JRN-001 body | JRN-002 |
| Host template fixture repo | `.github/pull_request_template.md` with known headings, rules.md with `pr_template: project` | Built by a `tests/fixtures/` helper | JRN-003 |
| rules.md variants | No block, no key, each valid value, a bad value | Built in the test, as the existing `task_review` cases do | JRN-004 |
| Stand-in `gh` / `glab` | Records the arguments it was called with | `PATH` stubs in the test | JRN-005 |
| Spec-branch fixture repo | A spec branch, main, and an approved `pr-body.md` | `tests/fixtures/` helper | JRN-005 |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

Run every command in bash from the repo root on a clean checkout of the feature's HEAD. `BASE` is the baseline:

```bash
BASE=$(yq --front-matter=extract '.baseline_revision' .workflow/specs/008-pr-description-template/spec.md)
```

| Id | Kind | Target | Threshold | Command | Source |
| --- | --- | --- | --- | --- | --- |
| TGT-001 | errors | Script lint clean | exit 0; 0 shellcheck findings | `script-lint` below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| TGT-002 | errors | Harness lint clean | exit 0; 0 shellcheck findings | `harness-lint` below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| TGT-003 | errors | Agent-docs lint clean | exit 0; each lint suite reports 0 failed | `agent-docs-lint` below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| TGT-004 | errors | `gh` `--template` passed beside a body flag anywhere under `.agents/` | `0` printed | `template-flag` below | `spec.md` Constraints ("never `gh --template` together with a body flag") |
| TGT-005 | coverage | Scripts added or changed since the baseline that no suite names | `0` printed | `script-coverage` below | `.workflow/profiles/test-harness.md` § Mini-review checklist ("A new or changed script has a suite") |
| TGT-006 | coverage | Files added under `.agents/` since the baseline missing from the manifest (or a listed directory) or from `PROVENANCE.md` | `0` printed | `asset-coverage` below | `.workflow/rules.md` § Cross-cutting policy (manifest, PROVENANCE) |
| TGT-007 | performance | Wall time of `check-pr-body.sh` on one body | real ≤ 1 s, best of 3 | `check-time` below: times the check on the shipped template, which has every heading, so the check walks all ten sections; its exit code is ignored | Stakeholder decision 2026-10-29 (1.1) |
| TGT-008 | coverage | Line coverage of changed shell code | not measured | Cannot be measured: no bash coverage tool is installed and `spec.md` Constraints ban new dependencies. TGT-005 and the 3.7 profile checklist stand in for it. | Stakeholder decision 2026-10-29 (1.1) |

Commands referenced above (pipes keep them out of the table cells):

```bash
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# template-flag: lines that pass gh --template together with --body or --body-file; the threshold is 0
git grep -h -E 'gh pr create' -- .agents | grep -E -- '--template|-T ' | grep -c -E -- '--body|-b |-F '
# script-coverage: prints the count of uncovered scripts; the threshold is 0
git diff --name-only --diff-filter=AM "$BASE"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files missing from the manifest or PROVENANCE.md; the threshold is 0
git diff --name-only --diff-filter=A "$BASE"..HEAD -- .agents | while read -r f; do r=${f#.agents/}; m=0; while IFS= read -r l; do case "$r" in "$l"|"${l%/}"/*) m=1;; esac; done < .agents/install-manifest.txt; [ "$m" = 1 ] || echo "manifest: $f"; grep -qF -- "$(basename "$f")" PROVENANCE.md || echo "provenance: $f"; done | wc -l | tr -d ' '
# check-time: the smallest real value must be at most 1
{ for i in 1 2 3; do /usr/bin/time -p .agents/skills/feature-workflow/scripts/check-pr-body.sh .agents/skills/feature-workflow/assets/pr-template.md >/dev/null; done; } 2>&1 | awk '/^real/{print $2}' | sort -n | head -1
```

## Suites

<!-- 1.2-1.4. Commands come from the profile Toolchain keys: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md) Run 1, log [harness.log](artifacts/phase-1-known-bad/harness.log): 60 failures across 3 suites, all assertions |
| Browser | `e2e`: not applicable (no e2e work type, no browser; JRN-001 to JRN-006 are harness suites, JRN-007 is manual at 5.x) | none | none | not applicable; see record.md Run 2 |
