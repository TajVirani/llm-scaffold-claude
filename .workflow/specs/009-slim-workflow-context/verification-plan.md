# Verification plan: Slim the workflow context

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-lean-workflow-load: a new-feature start (AGENTS.md, the session-start hook output from a fixture with one in-flight spec and no handoffs, SKILL.md, references/conventions.md, modules/discovery.md, the term-list output) totals at most 45,000 bytes by `wc -c`; a small-path start loads the same files (D15, D17, D21, D22).
- [ ] CAP-NEW-lean-workflow-load: an implementation resume (AGENTS.md, the same hook output, SKILL.md, references/conventions.md, modules/implementation-waves.md) totals at most 55,000 bytes by `wc -c` (D15, D16, D20, D25).
- [ ] CAP-NEW-lean-workflow-load: a size-check suite run by `tests/run-all.sh` measures both loads and fails when either is above its target (D19).
- [ ] CAP-NEW-lean-workflow-load: every step id in `references/steps.tsv` routes, through the router's Route table and the step files' own "load" links, to exactly one step file that holds it, 0.0.3 and 4.10 included (D4, D13, D16, D17, D25).
- [ ] CAP-NEW-lean-workflow-load: every relative markdown link and `#anchor` under `.agents/` resolves, checked by a lint suite that fails on a broken one (D8).
- [ ] CAP-NEW-lean-workflow-load: the term-list script prints one line per glossary entry with its `_Avoid_` aliases, reads every glossary a `GLOSSARY-MAP.md` names, and `--define <term>` prints exactly that entry (D5, D12); discovery 0.2.1 and the output style use it instead of reading the glossary whole (D11).
- [ ] CAP-NEW-lean-workflow-load: discovery 0.2.1 reads only module names and `owns` paths from `rules.md`; the full Ownership block is read at 0.3.3 and Shared core at 0.3.20 (D22).
- [ ] CAP-NEW-lean-workflow-load: each shared rule (one writer and exit codes, set the step then write, guarded-writes table, progress line, sub-agent writes, launch header, host launch rows, the escalation classes, "Leave the small path") appears in exactly one file, and `modules/small-path.md` no longer exists (D2, D10, D17, D23, D24).
- [ ] CAP-NEW-lean-workflow-load: SKILL.md frontmatter has no `modules:` or `progressive_loading:` key and passes the frontmatter lint, and the small-path docs lint checks the step-file notes instead of the removed file and frontmatter row (D14, D17).
- [ ] CAP-NEW-lean-workflow-load: `tests/run-all.sh` passes, with the existing suites unchanged in behaviour and re-pointed only where they name a moved file or section.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | New-feature start load | CAP-NEW-lean-workflow-load | 1. Build a fixture repo with one in-flight draft spec and no handoffs; run `session-start-resume.sh` on it. 2. Sum `wc -c` of AGENTS.md, that output, SKILL.md, references/conventions.md, modules/discovery.md and the term-list output for this repo's glossary. | Total ≤ 45,000 bytes | `tests/run-all.sh --suite lint/workflow-load-size` (new-feature start checks) |
| JRN-002 | Implementation resume load | CAP-NEW-lean-workflow-load | 1. Same fixture hook output as JRN-001. 2. Sum `wc -c` of AGENTS.md, that output, SKILL.md, references/conventions.md and modules/implementation-waves.md. | Total ≤ 55,000 bytes | `tests/run-all.sh --suite lint/workflow-load-size` (implementation resume checks) |
| JRN-003 | Every step routes to one step file | CAP-NEW-lean-workflow-load | 1. For each step id in steps.tsv, find the step files whose headings or step lines hold it. 2. Check the router or a step file links to that file for the id. | Each id held by exactly one step file and reachable; 0.0.3 (router), 0.x, 1.x–5.x, 4.10, 6.x and 00.x ids all covered | `tests/run-all.sh --suite lint/step-routing` |
| JRN-004 | Link lint catches a broken anchor | CAP-NEW-lean-workflow-load | 1. Run the link lint on `.agents/`. 2. Run it on a fixture with a link to a missing heading and one to a missing file. | Step 1 passes; step 2 fails naming both links | `tests/run-all.sh --suite lint/md-links` |
| JRN-005 | Term list and lookup | CAP-NEW-lean-workflow-load | 1. Run the script on a fixture glossary. 2. Run it on a fixture with a GLOSSARY-MAP.md and two context glossaries. 3. `--define` a known term, then an unknown one. | 1: one line per entry with aliases. 2: terms from both contexts, labelled. 3: the one whole entry; non-zero exit for the unknown term | `tests/run-all.sh --suite scripts/term-list` |
| JRN-006 | One home per shared rule | CAP-NEW-lean-workflow-load | 1. Grep SKILL.md, large-path.md, references/conventions.md, references/launching.md and every step file for each shared rule's marker line, including the escalation-class line (`**scope-expanding**`) and the `## Leave the small path` heading. 2. Check `modules/small-path.md` is absent. | Each marker in exactly one file (the escalation class line only in discovered-work.md, the Leave heading only in questioning-loop.md); no small-path.md | `tests/run-all.sh --suite lint/shared-rule-homes` |
| JRN-007 | Frontmatter and small-path docs | CAP-NEW-lean-workflow-load | 1. Read SKILL.md frontmatter. 2. Run `tests/run-all.sh --suite lint/frontmatter` and `--suite lint/small-path-docs`. | No `modules:` or `progressive_loading:`; both lints pass, the small-path lint finding the "On the small path:" notes in discovery.md, discovery-impact.md, questioning-loop.md and sign-off.md | `tests/run-all.sh --suite lint/small-path-docs --suite lint/frontmatter` |
| JRN-008 | Size check fails above a target | CAP-NEW-lean-workflow-load | 1. Run the size-check suite on the repo. 2. Run its measuring function on a fixture where one counted file is padded past the limit. | Step 1 passes printing both totals; step 2 fails naming the load point, its total and its limit | `tests/run-all.sh --suite lint/workflow-load-size` (padded-fixture checks) |
| JRN-009 | Affected area from `owns` paths | CAP-NEW-lean-workflow-load | 1. Run the 0.2.1 command from discovery.md on this repo's `rules.md`. | One line per module in the Ownership block with its `owns` paths, nothing else from `rules.md` | `tests/run-all.sh --suite lint/affected-area` |
| JRN-010 | Full suite green | CAP-NEW-lean-workflow-load | 1. Run `tests/run-all.sh`. | Every suite passes | `tests/run-all.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Today's load sizes | Baselines at 7a9b852 with this repo's hook output (1,833 B): new-feature start 81,253 B, small-path start 89,180 B, implementation resume 84,855 B | Measured with `wc -c` on 2026-11-01 (spec.md, Why) | JRN-001, JRN-002 |
| Session-start hook fixture | A repo with one in-flight draft spec and no handoffs, and the hook's `additionalContext` | `seed_draft_spec` and `resume_offer` in `tests/fixtures/initiative.sh` (codebase-map.md, Seams) | JRN-001, JRN-002, JRN-008 |
| `references/steps.tsv` | Every step id and its title | The repo; unchanged by this change | JRN-003 |
| Fixture glossaries | A single glossary, and a GLOSSARY-MAP.md with two contexts, in GLOSSARY-FORMAT.md form | Written under `tests/` for the suite | JRN-005 |
| Broken-link fixture | A markdown file linking a missing heading and a missing file | Written under `tests/` for the suite | JRN-004 |
| `scripts/check-write.sh:74-83` step constants | The guarded-writes steps the moved table must match | The repo | JRN-006 |
| Shared-rule marker lines | One distinctive line per shared rule (for example the exit-code sentence) | Chosen when the conventions file is written | JRN-006 |
| `.workflow/rules.md` Ownership block | The modules and `owns` globs the 0.2.1 command must print | The repo | JRN-009 |
| Padded-file fixture | A copy of a counted file grown past the limit | Written under `tests/` for the size-check suite | JRN-008 |

## Targets

Run every command in bash from the project root on a clean checkout of the feature's HEAD. The two load targets read the totals the size-check suite prints (`<load point>: <n> bytes (limit <m>)`), so they count the same files and fixture hook output as JRN-001 and JRN-002; JRN-008 proves that suite fails above a limit. Baselines at 7a9b852 are in Fixtures and oracles.

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| New-feature start load | performance | ≤ 45,000 bytes | the `load-new-start` command below | `spec.md` CAP-NEW-lean-workflow-load success line (D15, D21) |
| Implementation resume load | performance | ≤ 55,000 bytes | the `load-impl-resume` command below | `spec.md` CAP-NEW-lean-workflow-load success line (D15, D21) |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean | errors | exit 0; each lint suite reports 0 failed | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| Every script this spec adds or changes has a suite | coverage | `0` printed | the `script-coverage` command below | `.workflow/profiles/test-harness.md` § Mini-review checklist |
| Every new `.agents/` file is in `PROVENANCE.md` | coverage | `0` printed | the `asset-coverage` command below: files added under `.agents/` since `baseline_revision` whose path no line of `PROVENANCE.md` names | `.workflow/rules.md` § Cross-cutting policy (PROVENANCE) |
| Line coverage of changed shell code | coverage | not measured | Cannot be measured: no bash coverage tool is installed and the spec allows no new dependency. The script-coverage target and the test-harness checklist at 3.7 stand in. | `spec.md` Constraints ("No new dependencies") |

Commands referenced above; each runs from the project root:

```bash
# load-new-start: prints the byte total; the threshold is 45000
bash tests/lint/workflow-load-size.sh | sed -n 's/^new-feature start: \([0-9]*\) bytes.*/\1/p'
# load-impl-resume: prints the byte total; the threshold is 55000
bash tests/lint/workflow-load-size.sh | sed -n 's/^implementation resume: \([0-9]*\) bytes.*/\1/p'
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of changed scripts no file under tests/ names; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/009-slim-workflow-context/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files PROVENANCE.md does not name; the threshold is 0
git diff --name-only --diff-filter=A "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/009-slim-workflow-context/spec.md)"..HEAD -- .agents | while read -r f; do grep -qF -- "${f#.agents/}" PROVENANCE.md || echo "$f"; done | wc -l | tr -d ' '
```

## Suites

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` | `tests/run-all.sh` | none | `artifacts/phase-1-known-bad/record.md` (`harness.txt`, `md-links-fault.txt`) |
| Browser | `e2e` | none: no `e2e-browser` work type in this repo | none | not applicable |
