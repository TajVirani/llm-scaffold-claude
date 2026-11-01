---
cache_stamps:
  modules: null
  flows: null
  architecture: null
---

# Codebase map: Review lessons: a Phase 4 lens for retrospective lessons

Affected area: feature-workflow (`.agents/skills/feature-workflow`), agents (`.agents/agents`), retrospective (`.agents/skills/retrospective`), hooks (`.agents/hooks`), project-setup (`.agents/skills/project-setup`), lib (`.agents/lib`, shared core), installer (`install.sh`, `.agents/install-manifest.txt`), root-docs (`README.md`, `.agents/README.md`, `AGENTS.md`), tests (`tests`); plus the scaffold-only root files `PROVENANCE.md`, `assetlist.md` and `upstream-lineage.json`.

All three Tier B caches were missing and could not be regenerated (`build-architecture.sh` needs dependency-cruiser, which is not installed and cannot read bash), so `retrieval` read the code and the stamps are null.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Task-type table `D31_TABLE` | One JSON row per task type: `d31_fields`, `shapes`, `header_optional`, `profile`. The three lens types take `spec_dir` only, `profile: none`. No `review-lessons` row. | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:51-93` (lens rows 75-77) |
| Unlisted subagent_type | pre-launch exits 0 with no header check for any type not in the table. | `.agents/hooks/pre-launch.sh:73-76` |
| Model resolution | override, then definition `models.<host>`, then `.workflow/model-map/<type>.md`; none means deny 00.14. | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:289-307` |
| Lens result check | Triage validates each block with yq; `PFX` is hard-coded per lens (RS, RE, RT). Targets also check `measurements:`. | `.agents/skills/feature-workflow/modules/review-triage.md:43-69` |
| Lens launch | Three lenses launched together; "Pass nothing else" to them. | `.agents/skills/feature-workflow/modules/review-triage.md:17-19` |
| Failed lens | Missing or unparseable block: relaunch once, then "failed lens", named in the triage entry and 5.4 report. | `.agents/skills/feature-workflow/modules/review-triage.md:75-77` |
| Tier A classification | Guarded classes are glossary, profiles, `capabilities.md`, `rules.md`, `decisions/**`. `.workflow/review-lessons.md` matches none, so it falls to class `other` and is allowed. | `.agents/skills/feature-workflow/scripts/check-write.sh:182, 202-210` |
| Tier A step gate | "other Tier A" (rules, capabilities, decisions) allowed at 0.3.7, 5.3, 5.7 only. | `.agents/skills/feature-workflow/scripts/check-write.sh:66, 318-331` |
| Path helper | One `WF_*` variable per workflow path. None for `review-lessons.md`. | `.agents/lib/workflow-paths.sh:18-41` |
| Retrospective writes | Document, `pitfalls.md`, a design-log section, model-map or overrides. No lessons destination. | `.agents/skills/retrospective/SKILL.md:19-24` |
| Retrospective routing | Destinations: pitfalls (written), process lessons (in document), mechanical lesson to tool rule and judgement lesson to checklist line (action items only, not written). | `.agents/skills/retrospective/modules/routing.md:5-12` |
| 5.7 step | Retrospective runs after 5.9, stakeholder present; verdict read from frontmatter. | `.agents/skills/feature-workflow/modules/sign-off.md:110-125`; `.agents/skills/feature-workflow/references/steps.tsv:112` |
| 5.2 candidate groups | Capabilities, rules, decisions, pitfalls, profiles, tool rules. No lessons group. | `.agents/skills/feature-workflow/modules/sign-off.md:19-29` |
| Step list | Per-phase counts asserted by lint: full path `4:8`, `5:9`; light path `4:8`, `5:9`. Adding a counted step breaks this. | `.agents/skills/feature-workflow/references/steps.tsv:97-112`; `tests/lint/step-list.sh:56-57` |
| Codex spawn check | Types come from `resolve-launch.sh --requirements`. For a type outside the three coding types, `task_name` is optional. | `.agents/hooks/codex-pre-spawn.sh:10-19, 70-77, 134-136` |
| Codex agent generation | One `<name>.toml` per `.agents/agents/*.md`; `model` is never written. | `.agents/hooks/generate-codex-agents.sh:9-18, 71` |
| Lens definitions | Frontmatter has `name`, `description`, `tools`; no `models:` key, so model comes from model-map. | `.agents/agents/review-standards.md:1-5`, `.agents/agents/review-end-state.md:1-5`, `.agents/agents/review-targets.md:1-5` |
| Lens inputs | review-standards reads rules, profiles, glossary, placement ADR, toolchain output. No lessons file. | `.agents/agents/review-standards.md:22-33` |
| Lens return block | `review-findings` YAML: `findings` (category, severity, confidence >= 80), `checked`, `not_checked`. | `.agents/agents/review-standards.md:103-129`; `.agents/agents/review-end-state.md:76-100` |
| Retrieval reading list | Reads ADRs, pitfalls, retrospectives, rules, capabilities. Not `review-lessons.md`. | `.agents/agents/retrieval.md:30` |
| Project setup copies | Creates capabilities, rules, pitfalls, GLOSSARY, profiles, agent-overrides. No lessons template. | `.agents/skills/project-setup/modules/files.md:5-15`; `.agents/skills/project-setup/assets/docs/` (three files) |
| Install manifest | Agents listed one per line under the header "Agents (12)". | `.agents/install-manifest.txt:20-32` |
| Counts in docs | PROVENANCE says "the 12 `agents/*.md`"; README names the three lenses. | `PROVENANCE.md:87`; `README.md:41` |
| Frontmatter lint | Agents may not have `model:`; `models:` keys limited to `claude`, `codex`. | `tests/lint/frontmatter.sh:3-4, 59-66` |
| Tests on Tier A | Tier A guard tests cover rules, glossary, cache, decisions. None cover `review-lessons.md`. | `tests/hooks/write-guards.sh:108-142`; `tests/scripts/status-transition-check-write.sh:305-307` |
| Tests on launch | The pre-launch fixture covers implementation, retrieval and fact-lookup. Lens types appear only in loops. | `tests/hooks/pre-launch.sh:17, 26, 91`; `tests/scripts/resolve-launch.sh:20, 154` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `resolve-launch.sh` task-type table | JSON keyed by type. `--requirements` prints it. Modes: resolve, `--parse-header`, orchestrator. | `.agents/hooks/pre-launch.sh:73`; `.agents/hooks/codex-pre-spawn.sh:70`; `.agents/hooks/worktree-write-guard.sh:84` | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:51-93, 36-37` |
| `check-write.sh` | `--cwd <dir> --path <target> [--agent <id>] [--only spec\|tier-a\|tier-b] [--proposed <file>]`. Exit 0 allow, 2 deny, 1 usage or environment error. | `.agents/hooks/_guard-common.sh:94`; phase modules on hosts without hooks | `.agents/skills/feature-workflow/scripts/check-write.sh:5, 74-77` |
| Lens `review-findings` block | YAML, `lens`, `status: done\|blocked`, `findings[]`, `checked[]`, `not_checked[]`. Discovered-work findings have their own shape. | `.agents/skills/feature-workflow/modules/review-triage.md:43-57` | `.agents/agents/review-standards.md:107-131` |
| Retrospective verdict | Frontmatter `verdict`: `accepted`, `accepted-with-open-items`, `rejected`. | `.agents/skills/feature-workflow/modules/sign-off.md:118-125` | `.agents/skills/retrospective/assets/retrospective.md:4, 10` |
| `steps.tsv` | Tab-separated `id, phase, track, title`. | `.agents/skills/feature-workflow/scripts/step-progress.sh`; `tests/lint/step-list.sh:15-18` | `.agents/skills/feature-workflow/references/steps.tsv:12` |
| `workflow-paths.sh` | Sourced `WF_*` variables and `wf_path <root> <rel>`. | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:43`; `.agents/skills/feature-workflow/scripts/check-write.sh:53`; `.agents/hooks/_guard-common.sh:53` | `.agents/lib/workflow-paths.sh:18-46` |

| Retrospective skill entry | Input: spec folder (`in-review` at 5.7; standalone offers `status: done` specs). Output: `.workflow/decisions/retrospectives/NNN-slug.md` plus returning path and verdict to the caller. Writes only with stakeholder agreement. Never changes `status`. | `sign-off` at 5.7 (`.agents/skills/feature-workflow/modules/sign-off.md:110-125`); stakeholder standalone | `.agents/skills/retrospective/SKILL.md:10-34, 85` |
| Routing table (candidate to destination, written-by-skill flag) | Markdown table, one row per candidate kind. The "Written by this skill?" column decides between a write at step 5 and an action item at step 6. | `SKILL.md` step 5 | `.agents/skills/retrospective/modules/routing.md:5-12` |
| Process lessons table | `Lesson \| Kind \| Recorded in`. Kind values are fixed text. | Human readers; next feature's retrospective (follow-through, `SKILL.md:59`) | `.agents/skills/retrospective/assets/retrospective.md:61-63` |
| Action items table | `Item \| Owner \| Awaiting human application`. The previous-retrospective check reads each item and records whether it landed. | `SKILL.md:59` (next retrospective) | `.agents/skills/retrospective/assets/retrospective.md:98-100` |
| Tier A write gate (dependency) | `status-transition.sh step <spec> 5.7` before the first Tier A write; `tier-a-write-guard` enforces it. Dependency: feature-workflow scripts and hooks, in-process (local scripts, same repo). | `SKILL.md` step 1 | `.agents/skills/retrospective/SKILL.md:26-30` |
| yq (dependency) | `yq --front-matter=extract`, `yq -i`, `--front-matter=process`. Dependency category: true external (third-party binary required by the installer). | routing model observations, evidence tasks read | `.agents/skills/retrospective/modules/routing.md:45, 52, 58`; `.agents/skills/retrospective/modules/evidence.md:12` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0001 (status: accepted; not superseded) | Host-neutral core in `.agents/` behind thin shims. `install.sh` ships exactly what the manifest lists. Deferred: CI, so `tests/run-all.sh` by hand is the gate. | `.workflow/decisions/adr/0001-project-baseline.md` § Project baseline (line 8); § Deferred (line 12) |
| Pitfall: README restates a tree | README hooks and helper lists drifted from the tree. Prevented by the rule that the README never restates the tree. | `.workflow/decisions/pitfalls.md` § Point at a folder instead of restating its tree (lines 17-21) |
| Closest precedent: pitfalls file | Tier A file written at 5.7 by the retrospective skill, with approval. Entry shape in its comment. | `.workflow/decisions/pitfalls.md:1-14` |
| Rule: Ownership, agents | `agents` owns `.agents/agents/**` and may depend on feature-workflow. | `.workflow/rules.md` § Ownership (lines 79-81) |
| Rule: Ownership, others | `hooks` may depend on lib, feature-workflow, project-setup (38). `feature-workflow` may depend on lib, regenerate-caches, domain-modeling, project-setup (39-41). `retrospective` may depend on feature-workflow only (54-56). `installer` owns `install.sh` and the manifest (85-87). `root-docs` owns AGENTS.md, README.md, `.agents/README.md` (94-96). `tests` owns `tests/**` (91-93). No path owns `.workflow/review-lessons.md`. | `.workflow/rules.md` § Ownership |
| Rule: Shared core | `.agents/lib/**` is shared core. Changes only through the integration agent, between batches. | `.workflow/rules.md` § Shared core (lines 101, 109) |
| Rule: policy | Comments give reasons, with no decision IDs or doc paths (137). Nothing in `.agents/` depends on `tests/` (138). Vendored skills frozen (139). Adding anything under `.agents/` updates `PROVENANCE.md` and, if installed, the manifest (142). Derived assets get an `upstream-lineage.json` entry (143). `.gitignore` block kept in step with `GI_ENTRIES` (147). | `.workflow/rules.md` § Cross-cutting policy |
| Rule: versions | bash 3.2 or newer; no bash 4 constructs. | `.workflow/rules.md` § Required versions (line 153) |
| Rule: size budget | `max_tasks: 10`, `max_changed_files: 30`, changed only at 5.3. | `.workflow/rules.md` § Size budget (lines 117-119) |
| Rule: External systems | Heading present, body empty. | `.workflow/rules.md` § External systems (lines 149-150) |
| Capabilities index | Table has a header and no rows. No existing capability covers this area. | `.workflow/capabilities.md` (lines 11-12) |
| Retrospectives | `.workflow/decisions/retrospectives/` does not exist. No earlier retrospective. | Glob of `.workflow/**` |
| Deferred shelf | `.workflow/deferred/` holds only `.gitkeep`. No shelved item matches by concept. | Glob of `.workflow/deferred/**` |

## Library options

## Library options: review-lessons feature (agents, feature-workflow, retrospective, hooks, project-setup, lib, installer, root-docs, tests)
Concerns: (1) parsing structured entries from the Tier A file `.workflow/review-lessons.md` in bash; (2) YAML or JSON handling for any structured output the installer or hooks write; settled by rules: (1) and (2) are settled by the "Required versions" section, which names bash 3.2+, git, jq, mikefarah yq v4 and shellcheck. The "External systems" section of `.workflow/rules.md` (line 149) is empty, so no external API or service is named. No new concern needs an outside library.

### Already in the project
- bash 3.2+ (no bash 4 constructs): `.workflow/rules.md:153`, `install.sh:89`; covers shell logic, string and line handling. Does not cover structured-data parsing beyond what awk/grep/sed give.
- jq (any version): `.workflow/rules.md:154`, `install.sh:94`, `install.sh:269-283` (JSON merge in use); covers JSON only.
- yq mikefarah v4: `.workflow/rules.md:155`, `install.sh:95-101`; covers YAML and TOML reads. Not used by `.agents/lib` today.
- No package manifest or lockfile exists (glob for package.json, bun.lock, pnpm-lock.yaml, pyproject.toml, Cargo.toml, go.mod, requirements*.txt returned nothing). `.agents/lib` has no imports of external tools (grep for yq/jq/python/node/awk/sed returned 0 matches), so the scaffold has no external library dependency today.
- shellcheck: `.workflow/rules.md:156`, `tests/.shellcheckrc`; lint and tests only.

### Structured-entry parsing (Tier A markdown file)
Verdict: Use existing (bash plus awk/grep, with the already-required jq or yq only if the entry format is machine-written as YAML or JSON). Adopting a markdown parser library would add a runtime dependency the required-versions list does not allow, so reject that.
Deprecation check: not applicable. No external API, SDK or service is involved. The step 5 searches were not run for jq or yq, since they are CLI tools named in rules.md, not APIs or SDKs.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| bash + awk/grep (in-house, incumbent tooling) | pass: already the scaffold's language; bash 3.2 compatible if no bash 4 constructs | pass: not applicable (in-house) | pass: in-repo | unknown: no advisory feed applies; shell code is reviewed by shellcheck | pass: no new deps; ~1-2 days to write the parser and its tests |
| jq (incumbent, required) | pass: JSON only; use if entries are stored as JSON | pass: MIT | unknown: no release date fetched (GitHub release section empty in fetch) | unknown: advisories not checked | pass: already installed by the installer; 0 added deps |
| yq mikefarah v4 (incumbent, required) | pass: YAML front-matter or YAML entries; not used in `.agents/lib` yet | pass: MIT | unknown: no release date fetched (only v4.2.0 seen in an install example) | unknown: advisories not checked | caution: adds a new call site, so the installer preflight already guards it; ~0.5 day |

Evidence:
- official docs / repository: https://github.com/jqlang/jq (MIT licence, per fetched page)
- official docs / repository: https://github.com/mikefarah/yq (MIT licence, not archived, per fetched page)
- project: `.workflow/rules.md` lines 149-156; `install.sh:89-101`; `tests/.shellcheckrc`

Risks: If review-lessons entries need nesting or free text with markup, awk parsing gets brittle; that would move the verdict to "Use existing: yq" for entries written as YAML blocks. If the team wants YAML front-matter parsing in hooks, yq becomes a runtime call, not just an installer check; confirm the hooks can assume yq is on PATH for target projects (install.sh already requires it, so likely yes).
Unverified: latest release dates and advisory status for jq and yq (fetched GitHub pages did not show release data; deps.dev and OSV were not queried because neither tool is a package-registry dependency here); OpenSSF Scorecard for both; the entry format of `.workflow/review-lessons.md` (it does not exist yet, so the parser choice depends on the spec's format decision).

Gates: no hold is needed. The project grounding (manifests, rules.md, source touchpoints) was read. External evidence was reachable for the two incumbent tools. No recommendation depends on missing information beyond the format decision noted above.

## Module audit

Owning module: retrospective (`.agents/skills/retrospective/**`: `SKILL.md`, `modules/routing.md`, `modules/evidence.md`, `assets/retrospective.md`; 298 lines in total, no scripts and no tests inside the module)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Writes table: each written file is one row with its file, tier and contents. A `.workflow/review-lessons.md` (Tier A) row fits this existing shape. | `.agents/skills/retrospective/SKILL.md:19-24` |
| reuse | Step 5 already covers per-entry approval: present each candidate with its source and proposed destination, the stakeholder approves, changes or rejects it, write only the approved ones, and record where each went. Its Done line (written, action item, or rejected) already covers a written review lesson. | `.agents/skills/retrospective/SKILL.md:65, 67` |
| reuse | The 5.7 step-set before the first Tier A write, and the standalone/in-flight-spec guard behaviour, already cover a new Tier A destination. | `.agents/skills/retrospective/SKILL.md:26-32` |
| reuse | Admission bar for any record: it must hold something the code, tests and docs do not already tell a reader. This applies to review lessons as written. | `.agents/skills/retrospective/modules/routing.md:3` |
| reuse | Pitfalls pattern, the closest precedent: entry shape lives in the target file's comment, entries are ordered, and a duplicate is skipped with "already present" in the document row. | `.agents/skills/retrospective/modules/routing.md:18-26`; `.agents/skills/retrospective/assets/retrospective.md:73` |
| reuse | "Prevented by" field on pitfalls: the module already records whether a rule or check now covers a failure. This is the nearest existing logic to "removes an entry a rule, lint or profile line now enforces". | `.agents/skills/retrospective/modules/routing.md:25` |
| reuse | Step 6 action-item list is defined by destination ("whose destination this skill cannot write"), so a written review lesson drops out with a small wording change. | `.agents/skills/retrospective/SKILL.md:71` |
| reuse | yq usage pattern for structured writes (`yq -i`, `--front-matter=process`), but only on non-Tier A files. | `.agents/skills/retrospective/modules/routing.md:45, 52, 58` |
| gap | The routing table has no review-lesson row. Its "Judgement lesson: needs a reader" row (to a profile checklist line or a rules.md line, as an action item) overlaps the new "symptom a reader can see in a diff" definition, and nothing tells the two apart. | `.agents/skills/retrospective/modules/routing.md:5-12` (row 10) |
| gap | No entry template for a YAML list item (`id`, `symptom`, `paths`, `origin_spec`, `date`). All existing templates are markdown blocks (pitfall, design-log section). | `.agents/skills/retrospective/modules/routing.md:20-35` |
| gap | No ID allocation anywhere in the module. Nothing assigns a next sequential id like RL-nnn. | Searched all four files; nearest is `.agents/skills/retrospective/modules/routing.md:18` |
| gap | No create-if-missing path for any destination. Pitfalls assumes `pitfalls.md` exists and reads its comment for the shape. The only template the module copies is its own `assets/retrospective.md`. | `.agents/skills/retrospective/SKILL.md:13, 40`; `.agents/skills/retrospective/modules/routing.md:18` |
| gap | No removal or edit of an existing Tier A entry anywhere. Pitfalls only adds; design-log says "never edit an earlier entry". | `.agents/skills/retrospective/modules/routing.md:18, 30` |
| gap | The evidence inventory does not list `.workflow/review-lessons.md`, `rules.md`, profiles or lint config. So the module reads nothing that would show "a rule, lint or profile line now enforces" an entry, or detect a duplicate lesson. | `.agents/skills/retrospective/modules/evidence.md:7-19` |
| gap | Template "Kind" column has no review-lesson value, and its "Recorded in" examples do not include a file plus id. The note under the table names only two outcomes (tool rule, checklist line). | `.agents/skills/retrospective/assets/retrospective.md:61-65` |
| gap | Done list names pitfalls, feature notes and model observations, but has no line for review lessons. | `.agents/skills/retrospective/SKILL.md:90` |
| gap | Step 5's candidate list ("process lessons, pitfalls, feature notes and model observations") does not name review lessons. | `.agents/skills/retrospective/SKILL.md:65` |
| constraint | "Write Tier A files with Write or Edit, never through Bash." The yq `-i` pattern in routing is used only on non-Tier A files. Writing the YAML `lessons:` list in a Tier A file must keep to Write or Edit. | `.agents/skills/retrospective/SKILL.md:34`; `.agents/skills/retrospective/modules/routing.md:52, 58` |
| constraint | The skill never edits `rules.md`, profiles, skills or `.agents/agents/*.md`. Those changes stay action items. Mechanical and judgement lessons keep that path. | `.agents/skills/retrospective/SKILL.md:34`; `.agents/skills/retrospective/modules/routing.md:9-10` |
| constraint | The step must be set to 5.7 before the first Tier A write. If another spec is in flight, a standalone run is denied: stop and report the agreed text. | `.agents/skills/retrospective/SKILL.md:26-32` |
| constraint | Every lesson carries a source reference; a claim with no source is dropped. | `.agents/skills/retrospective/SKILL.md:8` |
| constraint | Every lesson names its destination in the document ("Recorded in"). The routing Done line requires the document to name the destination of each approved candidate. | `.agents/skills/retrospective/assets/retrospective.md:13`; `.agents/skills/retrospective/modules/routing.md:66` |
| constraint | The retrospective does not change spec `status`; `sign-off` sets `done` after it returns. | `.agents/skills/retrospective/SKILL.md:34` |
| constraint | The document is the working state, and resume works from the first incomplete step. A partly written review-lesson set must be recoverable from the document on resume. | `.agents/skills/retrospective/SKILL.md:40` |
| constraint | Ownership dependency: `retrospective` may depend on feature-workflow only. "Creates the file from the project-setup template" would be a retrospective-to-project-setup dependency. The module has no reference to project-setup today. | `.workflow/rules.md` § Ownership (lines 54-56); `rg project-setup .agents/skills/retrospective` gives 0 hits |
| constraint | Template frontmatter: "Add no other machine-read fields". The verdict frontmatter is the only machine-read part of the document. | `.agents/skills/retrospective/assets/retrospective.md:10` |

Friction where the change touches: the lesson kinds are defined in three places that must stay in step: the routing table (`routing.md:5-12`), the template's Kind column plus the note under it (`assets/retrospective.md:63, 65`), and step 6's action-item list (`SKILL.md:71`). Adding a kind means editing all three.

Recent history: `git log` shows 3 commits touching the module (`aa05f00`, `4640be9`, `f60c679`), all repo-wide. No part of the module churns on its own.
## Not found

- `.workflow/cache/` (modules, flows, architecture): no files in `.workflow/cache/**`. Reported by retrieval.
- `.workflow/review-lessons.md`: absent in `.workflow/**`. Reported by retrieval.
- Existing `review-lessons` task type: no `.agents/agents/review-lessons.md`, no `review-lessons` row in `resolve-launch.sh`, no `review-lessons` template in project-setup assets, no `.workflow/model-map/review-lessons.md` (the model-map directory has entries for the other lenses only). Searched `.agents/**`, `tests/**`, `.workflow/**` by glob and rg. Reported by retrieval.
- `review-lessons` in the repo outside the spec folder: one hit only, `.workflow/GLOSSARY.md:48`, in a list of task types. Reported by retrieval.
- Model for `review-lessons`: no `models:` key in any agent definition, no model-map file. A launch would be denied at 00.14 (`.agents/skills/feature-workflow/scripts/resolve-launch.sh:305-306`). Reported by retrieval.
- Guard coverage for `.workflow/review-lessons.md`: class `other` in `check-write.sh`, no test. Reported by retrieval.
- Cache versus code disagreement: not assessable, since no cache exists. Reported by retrieval.
- Superseded ADRs: none. `.workflow/decisions/adr/` holds only 0001. Reported by retrieval.
- Package manifests or lockfiles (`package.json`, `bun.lock`, `pnpm-lock.yaml`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements*.txt`): none. Reported by library-evaluation.
- Tests owned by the retrospective module, or fixtures for retrospective output: none under `.agents/skills/retrospective/**`. Reported by module-audit.
- Any reference to `review-lessons`, `RL-` ids or a `lessons:` list: `.agents/skills/retrospective/**`. Reported by module-audit.
- Any existing mechanism to allocate sequential ids, create a missing destination file, or delete or edit a prior entry in a Tier A file: `.agents/skills/retrospective/**`. Reported by module-audit.
- Any reference to `project-setup` or its templates: `.agents/skills/retrospective/**`. Reported by module-audit.
- cache disagrees with code: none found; the codebase-map extracts for the retrospective module match the code. Reported by module-audit.
