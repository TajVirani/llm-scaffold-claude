# Verification plan: Tier B caches for bash projects

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-004: with profiles naming `bash`, `dependency-cruiser` or `none`, `build-architecture.sh` runs each named graph extractor and renders all three caches from the merged graph.
- [ ] CAP-004: on the existing JS/TS fixtures with a profile naming `dependency-cruiser`, the rendered architecture, modules and entries output is byte-identical to the output at `baseline_revision`, apart from architecture's new "Unresolved edges" section reading `None.`.
- [ ] CAP-004: a profile without `graph_extractor` makes `build-architecture.sh` exit 2 with a message that says it is a breaking change, names that profile and gives the line to add; `--extractor NAME` does not bypass this, `--from-json` does (D12).
- [ ] CAP-005: on bash fixtures, `extractors/bash.sh` prints dependency-cruiser-shaped JSON with an edge for every `source`/`.` line and script call whose path resolves, `couldNotResolve: true` with the source text for each that does not, and an `exports` map of top-level functions of sourced files.
- [ ] CAP-005: architecture.md lists unresolved edges under "Unresolved edges" (or `None.`) and passes `check-staged-cache.sh`; modules.md Public interface is the union of each module's functions; flows candidates exclude files matching any profile's `test_patterns`.
- [ ] CAP-004: with a committed boundary config and no profile naming `dependency-cruiser`, `build-architecture.sh --cache architecture` runs no depcruise and Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (bash).`; with a profile naming `dependency-cruiser`, the boundary check still runs.
- [ ] CAP-005: at 5.3, after this repo's profile keys are applied, its three caches are built, pass `check-staged-cache.sh`, publish through `publish-cache.sh` with `generator` naming the extractors, and `cache-stamp-check.sh` exits 0 (all fresh).

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain; `spec.md` Constraints (bash 3.2, portable tools) |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean | errors | exit 0; each lint suite reports 0 failed | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| Every script this spec adds or changes has a suite | coverage | `0` printed (no uncovered script) | the `script-coverage` command below: scripts under `.agents/` added or modified since `baseline_revision` whose file name no file under `tests/` mentions | `.workflow/profiles/test-harness.md` § Mini-review checklist ("A new or changed script has a suite ending in a `shellcheck_files` assertion") |
| Every new `.agents/` asset is in the manifest and `PROVENANCE.md` | coverage | `0` printed (no unlisted asset) | the `asset-coverage` command below: files added under `.agents/` since `baseline_revision` that are not a line of `.agents/install-manifest.txt` (or under a listed directory) or not named in `PROVENANCE.md` | `.workflow/rules.md` § Cross-cutting policy (manifest, PROVENANCE) |
| Bash graph extractor wall time on this repo | performance | under 30 s | the `extractor-time` command below: `/usr/bin/time -p` around `extractors/bash.sh --root . --scope .agents --scope tests --scope scripts --scope install.sh`, reading the `real` line | stakeholder decision, 1.1 (2026-10-23) |

Commands referenced above (pipes keep them out of the table cells); each runs from the project root:

```bash
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of uncovered scripts; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/003-bash-cache-extractor/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' '.agents/skills/*/scripts/*/*.sh' | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files missing from the manifest or PROVENANCE.md; the threshold is 0
git diff --name-only --diff-filter=A "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/003-bash-cache-extractor/spec.md)"..HEAD -- .agents | while read -r f; do r=${f#.agents/}; m=0; while IFS= read -r l; do case "$r" in "$l"|"${l%/}"/*) m=1;; esac; done < .agents/install-manifest.txt; [ "$m" = 1 ] || echo "manifest: $f"; grep -qF -- "$(basename "$f")" PROVENANCE.md || echo "provenance: $f"; done | wc -l | tr -d ' '
# extractor-time: the real line must be under 30
/usr/bin/time -p .agents/skills/regenerate-caches/scripts/extractors/bash.sh --root . --scope .agents --scope tests --scope scripts --scope install.sh >/dev/null
```

## Journeys

There is no browser UI; every journey runs in the bash harness (`tests/run-all.sh`).

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Bash project builds all three caches | CAP-005, CAP-004 | 1. Fixture repo with bash scripts, a sourced lib, a script call, a dynamic `source`, a test file and a profile with `graph_extractor: bash` and `test_patterns`. 2. Run `build-architecture.sh --cache architecture`, `modules`, `entries`. 3. Run `check-staged-cache.sh` on the rendered architecture and modules bodies. | Edges for the lib and the call; the dynamic `source` under Unresolved edges; lib functions as Public interface; the test file absent from entries; both bodies pass the check | `scripts/cache-bash-project` |
| JRN-002 | JS/TS project unchanged once keyed | CAP-004 | 1. Existing depcruise and tsc fixtures plus a profile with `graph_extractor: dependency-cruiser`. 2. Render all three outputs. 3. Compare with the outputs from `baseline_revision`. | Byte-identical, apart from architecture's new `Unresolved edges` section reading `None.` | `scripts/cache-js-unchanged` |
| JRN-003 | Missing key is a breaking-change error | CAP-004 | 1. Fixture with one profile lacking `graph_extractor`. 2. Run `build-architecture.sh`, then again with `--extractor bash`, then with `--from-json`. | Exit 2 naming the profile and the line to add for the first two runs; the `--from-json` run succeeds | `scripts/cache-missing-extractor-key` |
| JRN-004 | Mixed extractors merge | CAP-004 | 1. Fixture with a `bash` profile, a `dependency-cruiser` profile (`DEPCRUISE` pointed at a stub printing fixture JSON) and a `none` profile. 2. Render architecture. | One graph with both languages' files; `generator` names `bash,dependency-cruiser` | `scripts/cache-mixed-extractors` |
| JRN-006 | Bash project with a boundary config builds architecture without depcruise | CAP-004 | 1. Bash fixture repo with a profile `graph_extractor: bash`, a committed `.workflow/tools/boundaries/dependency-cruiser.cjs` and `DEPCRUISE` pointed at a stub that fails if run. 2. Run `build-architecture.sh --cache architecture`. 3. Repeat with a second profile naming `dependency-cruiser` and `DEPCRUISE` pointed at a stub printing violations JSON. | Run 1: exit 0, the stub never runs, Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (bash).` and the body passes `check-staged-cache.sh`. Run 2: the stub runs and its violations are listed | MISSING |
| JRN-005 | This repo's caches are fresh | CAP-005 | 1. At 5.3 apply the profile keys from proposals.md. 2. Run regenerate-caches (three cache-regeneration launches, check, publish). 3. Run `cache-stamp-check.sh`. | Exit 0; `.workflow/cache/{modules,flows,architecture}.md` exist with 40-hex stamps | Manual at 5.3, evidence in `artifacts/` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Bash fixture repo | Scripts covering each `source` form (dir-anchored, `$here` variable, one variable hop), a dir-anchored call, a runtime-root call with an existing tail and one without, a dynamic `source`, a test file, a sourced lib with functions | Built in the test under a temp dir, modelled on the forms the fact lookup found (design-log round 1 facts) | JRN-001, JRN-003, JRN-004 |
| depcruise and tsc fixture JSON | Today's JS/TS inputs | Existing `tests/scripts/build-architecture.sh` fixtures | JRN-002, JRN-004 |
| Baseline renders | Oracle for byte-identity | Rendered from the fixtures with `build-architecture.sh` at `baseline_revision` and stored as expected output | JRN-002 |
| Profile fixtures | `graph_extractor`, `test_patterns`, one profile without the key | Written in the test | JRN-001, JRN-003, JRN-004 |
| `check-staged-cache.sh`, `cache-stamp-check.sh` | Shape and freshness oracles | The module's own gates | JRN-001, JRN-005 |

## Suites

<!-- 1.2-1.4. Filled by modules/verification-setup.md. Commands come from the profile Toolchain keys, not from this file: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md), full log [harness.log](artifacts/phase-1-known-bad/harness.log): 52 failures across the 5 new suites and the 1 extended one, all assertions |
| Browser | `e2e`: not applicable (no e2e work type, no browser; JRN-001 to JRN-004 are harness suites, JRN-005 is manual at 5.3) | none | none | not applicable; see record.md Run 2 |
