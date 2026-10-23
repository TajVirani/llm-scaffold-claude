# Design log: Tier B caches for bash projects

Spec: [spec.md](spec.md)

## 2026-10-21 Term gate 0.2.2

- Term agreed and written to `.workflow/GLOSSARY.md` at 0.2.3: **Graph extractor**. Kept apart from the boundary-config adapter (D20, `generate-boundary-config.sh`), which writes lint config, not a graph.

## 2026-10-21 Cache regeneration skipped (0.2.7-0.2.8)

- `cache-stamp-check.sh` reported all three caches `missing`. 0.2.8 was not run: `build-architecture.sh` requires dependency-cruiser for every cache type, and dependency-cruiser cannot read bash, which is the defect this spec fixes. Retrieval read the code with null stamps (see [codebase-map.md](codebase-map.md)).

## 2026-10-21 Placement: regenerate-caches

- Owning module: regenerate-caches (`.agents/skills/regenerate-caches/**`). Graph extractors live at `.agents/skills/regenerate-caches/scripts/extractors/<name>.sh`, one per language, all printing the same graph JSON; `build-architecture.sh` takes the extractor named by the work profile.
- Alternatives considered: lib (shared core): any module could call it, but nothing outside the caches needs a file graph, and shared-core changes go through the integration agent. project-setup, next to the boundary-config adapters: both are per-language, but the adapters write lint config, and regenerate-caches would then depend on project-setup for its core job.
- Secondary touches outside the owning module: project-setup (a Toolchain key naming the graph extractor in `assets/profiles/TEMPLATE.md`, and the dependency-cruiser requirement in `modules/profiles.md`), agents (`cache-regeneration.md`), feature-workflow (`discovery.md` hardcodes `--generator dependency-cruiser`), tests, and this repo's `.workflow/profiles/*.md` (Tier A, 5.3 proposal). The exact set is settled in the questioning loop.
- Conflict with an ADR or rule: none. regenerate-caches may already depend on lib, project-setup and feature-workflow (`.workflow/rules.md` § Ownership); ADR-0001 is conformed to.
- ADR three-part test: hard to reverse (no: moving scripts is cheap), a real trade-off (yes), surprising without context (no). Fails the test; recorded here, no ADR.
- Decision: **D1** Graph extractors are owned by regenerate-caches under `scripts/extractors/`; other modules receive secondary edits only.

## 2026-10-21 Deeper prompt

**Ask:** Let the workflow build and keep Tier B caches for projects whose code is not JS/TS, starting with bash, so retrieval reads stamped caches instead of re-reading the code each feature.

**Goals:**
- Each work profile names its graph extractor, and `build-architecture.sh` uses it. A JS/TS project with dependency-cruiser builds exactly as today.
- A bash graph extractor outputs files, `source`/`.` edges and entry-point candidates in the shared graph shape. Dynamic `source` paths it cannot resolve are reported, never guessed.
- This repo has all three caches (modules, flows, architecture) published with real stamps that pass `check-staged-cache.sh`, and the next discovery stamp check reports them fresh.
- No new runtime dependency; bash 3.2.

**Downstream:** graph extractors for more languages later (e.g. Python, Go). One graph JSON contract that any extractor prints, so a new language is one new script.

**Tools and technologies:** no preference. Library evaluation recommends in-house awk/grep.

**Gotchas:** none known.

**Not asked for:** extractors for languages other than bash; a boundary tool for bash (enforcing `.workflow/rules.md` Ownership); a markdown extractor for skill-to-script path references.

**Original request:** "Have an issue with how the workflow was installed on this project. - Caches: all three Tier B caches are missing and cannot be regenerated here. The build script shells out to dependency-cruiser, which is not installed and cannot read bash. Retrieval is reading the code directly with null stamps, the same as spec 001 did. Can you fix this and also look at anything else that wasn't set up - and set it up."

Revisions: agreed as first restated.

## 2026-10-21 Questioning round 1

**Q1. Graph contract: what shape does every graph extractor print?**

- Why now: the deeper prompt asks for one contract any language can print.
- Options: A: the input half of build-architecture's internal graph, `{files, file_edges, unresolved}`, with dependency-cruiser converted into it · B: dependency-cruiser's own JSON, imitated by the bash extractor
- Recommended: A, because it is already the internal shape (`build-architecture.sh:166-191`, codebase-map.md § Relevant code)
- Answer: "B"
- Decision: **D2** The graph contract is dependency-cruiser's JSON (`.modules[].source`, `.modules[].dependencies[].resolved`); the bash extractor prints that shape and the canonicalisation stays as it is.

**Q2. Bash edges: what counts as an edge?**

- Why now: D2 fixes the shape; edges fill it.
- Options: A: `source`/`.` lines plus script-to-script calls · B: `source` lines only
- Recommended: A, because most wiring here is script calls and `.workflow/rules.md` § Ownership counts a call as a dependency
- Answer: "A"
- Decision: **D3** Bash edges are `source`/`.` lines and script calls. A call anchored to the script's own directory resolves directly; one anchored to a runtime root resolves only when its literal tail is an existing repo file, otherwise it is reported unresolved.

**Q3. Which extractor reads which file?**

- Why now: profiles carry no machine-readable file globs (fact Q3).
- Options: A: run every graph extractor any profile names; each claims files by its own rule; graphs merged · B: a file-glob key per profile
- Recommended: A, because no new glob can drift from File locations
- Answer: "A"
- Decision: **D4** Every graph extractor named by a profile runs over the scope and claims its own files (bash: `*.sh` or a bash shebang; dependency-cruiser: JS/TS); the outputs are merged. A profile with no code names `graph_extractor: none`.

**Q4. A profile has no `graph_extractor` key: what happens?**

- Why now: D4 reads the key from every profile.
- Options: A: fall back to dependency-cruiser · B: error
- Recommended: A, because installed JS/TS targets have no such key
- Answer: "B with a notice to the user of the breaking change and to update"
- Decision: **D5** A profile without `graph_extractor` is an error, and the user is told it is a breaking change and how to update. Revises the deeper-prompt goal "builds exactly as today" to "builds as today once the key is added".

**Q5. modules.md Public interface for bash?**

- Options: A: top-level functions of files other files `source` · B: "Not generated"
- Recommended: A, because those functions are the real interface (fact Q6)
- Answer: "A"
- Decision: **D6** The bash extractor reports the top-level functions of sourced files as their public interface; other bash files get "Not generated".

**Q6. Building this repo's caches while profiles are guarded until 5.3?**

- Options: A: `--extractor NAME` override for tests and Phase 4 proof; profile keys proposed in proposals.md; caches built and published at 5.3 after the profile edit · B: change the guard
- Recommended: A, because it works within the guard as designed
- Answer: "a"
- Decision: **D7** `build-architecture.sh` gains `--extractor NAME`; this repo's `graph_extractor` keys go to proposals.md for 5.3, and the three caches are built and published at 5.3 right after.

Facts looked up instead of asked (0.3.10): all 29 `source` lines resolve statically, 0 dynamic (`build-architecture.sh:40`, `tier-a-write-guard.sh:16`); ~18 script-call sites, 12 dir-anchored, 6 runtime-root-anchored with literal tails (`pre-launch.sh:69`); profiles' File locations are prose only (`.workflow/profiles/TEMPLATE.md:9-11`); existing profiles editable only at 5.3 (`check-write.sh:64-68`); canonicalisation reads raw depcruise JSON only at `build-architecture.sh:156-191`; lib functions `wf_path`, `run_guard` and others (`.agents/lib/workflow-paths.sh:43`, `.agents/hooks/_guard-common.sh:19-44`).

## 2026-10-21 Questioning round 2

**Q7. Where do users see the breaking-change notice for D5?**

- Why now: D5 makes a missing key an error with a notice.
- Options: A: build-architecture.sh and the regenerate-caches preflight error, plus an install.sh notice on update · B: the error message only
- Recommended: A, because users learn at update time rather than at first regeneration
- Answer: "Error message only"
- Decision: **D8** The notice is the error message from `build-architecture.sh` and the regenerate-caches preflight: it says this is a breaking change, names each profile without `graph_extractor`, and gives the line to add. install.sh is unchanged.

**Q8. How does the bash extractor report unresolved calls and functions inside the dependency-cruiser shape?**

- Why now: D2 fixes the shape; D3 and D6 need fields it has no plain slot for.
- Options: A: dependency-cruiser's own `couldNotResolve: true` with `module: "<text>"`, plus one extra top-level `exports: {file: [fn]}` read when present · B: a separate side file
- Recommended: A, because it reuses dependency-cruiser's own field and keeps one output
- Answer: "depcruise's own fields (Recommended)"
- Decision: **D9** Unresolved edges are dependencies with `couldNotResolve: true` and `module` set to the source text; functions go in an optional top-level `exports` map that build-architecture.sh reads for Public interface when present.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-21 Term gate 0.4.2

- No new concept: the profile key `graph_extractor` names a **Graph extractor** (agreed at 0.2.3).

## 2026-10-21 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Graph contract (dependency-cruiser JSON: `.modules[].source`, `.dependencies[].resolved`, `couldNotResolve`, `module`) | unchanged | Now also printed by the bash extractor (D2); see data-model.md § Graph JSON |
| Graph JSON `exports` key | create | Optional map, read for Public interface (D9) |
| Work profile Toolchain `graph_extractor` key | create | Required; missing is an error (D5); see data-model.md § Work profile Toolchain |
| `build-architecture.sh` extractor lookup and `--extractor NAME` | refactor | Replaces the hardwired depcruise lookup (`build-architecture.sh:141-160`) |
| `build-architecture.sh` canonicalisation and renderers | extend | Merges several extractors' `.modules`; modules renderer reads `exports` when tsc output is absent |
| `scripts/extractors/dependency-cruiser.sh` | create | Today's depcruise run moved behind the extractor interface; output identical |
| `scripts/extractors/bash.sh` | create | D3, D6, D9 |
| regenerate-caches preflight (`SKILL.md:31-38`) | refactor | Checks the tools the named extractors need; breaking-change error (D8) |
| Tier B frontmatter `generator` | extend | Extractor names, comma-joined (spec Assumptions); format unchanged |
| `cache-regeneration.md`, `discovery.md` 0.2.8 | extend | Stop hardcoding `--generator dependency-cruiser` |
| project-setup profile TEMPLATE, examples, `modules/profiles.md` | extend | Key added; dependency-cruiser requirement tied to `graph_extractor: dependency-cruiser` |
| This repo's `.workflow/profiles/*.md` | extend | Via proposals.md at 5.3 (D7) |
| `check-staged-cache.sh`, `publish-cache.sh`, `cache-stamp-check.sh` | unchanged | Body shapes and stamp format do not change |
| Boundary violations section, `generate-boundary-config.sh` | unchanged | Non-goal |

## 2026-10-21 Questioning round 3

Loop-back from 0.4.7: the module audit (codebase-map.md § Module audit) found two blocks-this-task gaps and two missing rules.

**Q9. Where are unresolved edges reported?**

- Why now: the canonicaliser drops them (`build-architecture.sh:184`) and the architecture sections are pinned (`check-staged-cache.sh:76-77`).
- Options: A: a new "Unresolved edges" section in architecture.md, with `check-staged-cache.sh` and its tests extended · B: stderr plus the cache-regeneration agent's return
- Recommended: A, because it lasts in the cache where retrieval reads it
- Answer: "New cache section (Recommended)"
- Decision: **D10** architecture.md gains an "Unresolved edges" section (sorted `` `file:line` `` and source text, or `None.`); `check-staged-cache.sh` and its tests accept it. Supersedes the "check-staged-cache.sh unchanged" row of the impact classification.

**Q10. How is a directory module's Public interface built from per-file exports?**

- Options: A: the union of its sourced files' functions · B: an index-like file only
- Recommended: A, because bash has no index file
- Answer: "Union of its files (Recommended)"
- Decision: **D11** A module's Public interface from `exports` is the sorted union of the functions of its files, rendered `` - `name` (function) ``.

**Q11. How do `--from-json` and `--extractor` interact with profile resolution?**

- Options: A: both skip profiles · B: only `--from-json` skips
- Recommended: A, so fixture runs need no profiles
- Answer: "Only --from-json skips"
- Decision: **D12** `--from-json` bypasses profile resolution; `--extractor NAME` still requires every profile to carry `graph_extractor` and only overrides which extractor runs. Tests that use `--extractor` provide profile fixtures.

**Q12. How are bash tests excluded from entry-point candidates?**

- Options: A: also exclude files matching any profile's Toolchain `test_patterns` · B: hardcode `tests/`
- Recommended: A, because `test_patterns` exists and budget-check.sh uses it the same way (`budget-check.sh:34-37`)
- Answer: "Profiles' test_patterns (Recommended)"
- Decision: **D13** Entry candidates also exclude files matching any profile's `test_patterns`; the JS/TS rule stays.

Facts looked up instead of asked (0.3.10): None.

## 2026-10-21 Scope decision: boundary-check-wording

- Item: module audit noticed the Boundary violations "Not checked" line names a dependency-cruiser config even in a bash-only project (`build-architecture.sh:226-228`).
- Ruling: deferred, because a bash boundary checker is a non-goal and the output is valid; only wording is affected.
- Handoff: [.workflow/deferred/boundary-check-wording.md](../../deferred/boundary-check-wording.md) (AFK), also listed in spec.md `deferred`

## 2026-10-21 Goal confirmed (0.3.19, after round 3)

- Stakeholder confirmed D10-D13 and the boundary-check-wording deferral. spec.md Capabilities and Constraints and data-model.md updated; the impact classification's "check-staged-cache.sh unchanged" row is superseded by D10 (now extend).
- Light-path facts: intent gaps clean; irreversible actions not clean (removes a public contract: a profile without `graph_extractor` now errors, D5); footprint not small (five modules). `light_path: false`.

## 2026-10-23 Main moved since discovery (1.1)

- Changes on main in the affected area since 2026-10-21: discovery 0.2.7/0.2.8 now launch beside the term gate (`discovery.md:44-59`); its architecture publish line still passes `--generator dependency-cruiser` (`discovery.md:98`), as does `regenerate-caches/SKILL.md:123-126`. Profiles gained a filled `test_scoped` key and `-co --exclude-standard` in their lint commands; `workflow-paths.sh` gained `WF_INITIATIVES` and `WF_REVIEW_LESSONS`.
- Effect on this spec: none to a contract it relies on. `test_patterns` is unchanged, and the two `--generator dependency-cruiser` lines are still the ones the generator assumption replaces.

## 2026-10-23 Phase 1 harness reports (1.2)

Found at 1.2 by the `implementation` agent (phase-1-test-harness, [result](artifacts/phase-1-test-harness/implementation.yaml)). All four are inside the agreed capabilities, so none grows `spec.md` or goes to the work backlog.

- **D14** (decision, stakeholder 2026-10-23) `build-architecture.sh --print-generator` prints the sorted, comma-joined names of the extractors the profiles select (`none` left out) and exits 0; discovery and regenerate-caches pass that output to `publish-cache.sh --generator`. Evidence: `tests/scripts/cache-mixed-extractors.sh` (JRN-004).
- **D15** (decision, stakeholder 2026-10-23) Graph JSON gains an optional integer `modules[].dependencies[].line`; the bash extractor sets it. An unresolved-edge bullet is `` - `<file>:<line>` `<source text>` ``, or `` - `<file>` `<source text>` `` when `line` is absent. Evidence: `tests/scripts/cache-bash-project.sh` (JRN-001).
- Profile conflict: `.workflow/profiles/shell-scripts.md` § File locations stops skill-script depth at `scripts/<file>`, which conflicts with `scripts/extractors/` (D1). Filed as P1 in [proposals.md](proposals.md) for 5.3.
- Task-breakdown note: profile resolution must skip `.workflow/profiles/TEMPLATE.md` (it has no `graph_extractor` key), or the 5.3 build on this repo fails.
- Task-breakdown note: `arch-golden` and `viol-sorted-unique` in `tests/scripts/build-architecture.sh` expect today's three-section architecture body; the task that adds Unresolved edges updates them.
- "Source text" in an unresolved bullet or `module` may be the whole line or the path; the tests require only that it contains the path text.
