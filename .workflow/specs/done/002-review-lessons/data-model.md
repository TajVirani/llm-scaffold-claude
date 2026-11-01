# Data model: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md) · Placement: retrospective

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Review lesson | entity | create | retrospective |
| Review lessons file (`.workflow/review-lessons.md`) | entity | create | retrospective (writer); feature-workflow (template, D9) |
| Lens finding (`review-findings` item) | entity | extend | agents |
| `review-lessons` agent definition | interface | create | agents |
| Task-type table row (`resolve-launch.sh`) | interface | extend | feature-workflow |
| Model-map entry | entity | create | project data (`.workflow/model-map/`) |
| Step list row `4.9` (+ lint counts, PLAN docs) | interface | extend | feature-workflow, tests, scaffold-only PLAN |
| Write-guard class `review-lessons` (`check-write.sh`) | interface | extend | feature-workflow |
| Path variable `WF_REVIEW_LESSONS` (`workflow-paths.sh`) | interface | extend | lib (shared core) |
| Retrospective routing table | interface | extend | retrospective |
| Project-setup file table | interface | extend | project-setup |
| Review triage launch and validation | interface | extend | feature-workflow |
| `pre-launch.sh`, `tier-a-write-guard.sh`, `generate-codex-agents.sh`, `install.sh` | interface | unchanged | hooks, installer |
| `review-standards`, `review-end-state`, `review-targets` inputs | interface | unchanged | agents |

## Entities

### Review lesson (create)

One lesson a retrospective recorded for the Phase 4 review: a symptom to look for in a set of paths, with the spec it came from and the date.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `id` | string | yes | matches `^RL-[0-9]{3,}$`; unique in the file; the next id is the highest present plus one, so an id is never reused (D3, D10) (CAP-NEW-review-lessons-record) | create |
| `symptom` | string | yes | non-empty; what a reader looks for in a diff, one or two sentences (CAP-NEW-review-lessons-lens) | create |
| `paths` | list of strings | yes | at least one repo-relative glob in the `.workflow/rules.md` Ownership-block syntax; no absolute path, no `..` (CAP-NEW-review-lessons-lens) | create |
| `origin_spec` | string | yes | matches `^\.workflow/specs/[0-9]{3}-[a-z0-9-]+$` (CAP-NEW-review-lessons-record) | create |
| `date` | string | yes | ISO date `YYYY-MM-DD`, the 5.7 date (CAP-NEW-review-lessons-record) | create |
| `retired` | string | no | ISO date; present only on a retired entry; the lens skips an entry that has it (D10) | create |
| `enforced_by` | string | no | required when `retired` is present: the rule, lint or profile line that now enforces the lesson (D10) | create |

**Relationships:** a Review lesson belongs to exactly one originating spec (`origin_spec`); a Lens finding references at most one Review lesson (`lesson`). Deleting a spec folder leaves the lesson in place: `origin_spec` is a pointer, not a foreign key.

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| candidate (in the retrospective's step 5 list) | stakeholder approves | recorded (an entry in the file) | step 5.7 set; per-entry approval |
| candidate | stakeholder rejects | none (nothing written) | - |
| recorded | a rule, lint or profile line now enforces it; stakeholder approves retirement | retired (entry kept, `retired` and `enforced_by` set; the lens skips it; the id stays taken) | step 5.7 set; per-entry approval |

**Invalid states ruled out:** an entry without a scope cannot be represented (`paths` must hold at least one glob, checked by the yq validation the retrospective and the tests run); two entries with one id cannot be represented (uniqueness check); a retired entry without `enforced_by` fails validation; a lesson written outside 5.7 cannot happen through Write or Edit (guard class). Still representable: a glob that matches nothing in the repo (accepted: the lesson simply never fires), and a lesson already enforced by a rule that nobody retired (accepted: the next retrospective offers its retirement).

### Review lessons file (create)

The project's one Tier A file of review lessons: a header comment with the entry rules, then one fenced YAML block.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `lessons` | list of Review lesson | yes | may be empty; the block validates with mikefarah yq v4 (`.lessons` is a sequence and every item passes the field rules above) | create |

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| absent | project-setup runs on a new project (copies the feature-workflow template, D9) | present, empty | outside any feature |
| absent | the retrospective has a first approved lesson at 5.7 (copies the same template, then appends) | present, one entry | step 5.7 set |
| present | the lens reads it at 4.9 | unchanged | the lens has no write tools |
| absent | the lens reads it at 4.9 | unchanged (read as an empty list, D7) | - |

**Invalid states ruled out:** a second lessons file per project (one fixed path from `workflow-paths.sh`). Still representable: a hand-edited file outside a feature with a malformed block; the lens then returns `status: blocked` naming the yq error, and the retrospective refuses to append until it validates.

### Lens finding (extend)

One item of the `findings` list in the lens's `review-findings` block, in the shape triage already validates.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `id` | string | yes | `^RL-[0-9]+$` (the triage check with `PFX=RL`) | extend |
| `category` | string | yes | `lesson` (never `discovered-work`) | extend |
| `lesson` | string | no | the Review lesson `id` the change repeats; absent for a pitfall or retrospective finding | extend |
| `severity` | string | yes | `high` for a repeated review lesson; `medium` for a repeated pitfall or retrospective lesson (D4) | unchanged |
| `confidence` | int | yes | at least 80, as for every lens | unchanged |
| location, summary, evidence | as the other lenses | yes | `path:line` in the diff, what repeats, the lesson or pitfall quoted | unchanged |

**Invalid states ruled out:** a finding without a lesson, pitfall or retrospective source (the `evidence` field must quote one). Still representable: two findings for one lesson at two locations (accepted: triage merges nothing silently and lists both).

## Interfaces

| Interface | Classification | Shape after the change |
| --- | --- | --- |
| `.agents/agents/review-lessons.md` | create | frontmatter `name: review-lessons`, `description` leading "Phase 4 review lens (workflow step 4.9)", `tools: Read, Grep, Glob, Bash`; body Input / Steps / Return per the agent template; Return is the `review-findings` block |
| `.agents/skills/feature-workflow/assets/review-lessons.md` | create | the empty lessons file: header comment with the entry rules and the yq validation, then a fenced block holding `lessons: []` (D9) |
| `resolve-launch.sh` D31_TABLE | extend | row `review-lessons`: `d31_fields [spec_dir]`, one shape "Phase 4 lens" requiring `spec_dir`, `header_optional false`, `profile none` |
| `.workflow/model-map/review-lessons.md` | create | `tier: cheap`, `claude: haiku`, `codex: gpt-6-luna`, the cheap-tier "Why this model" text |
| `steps.tsv` | extend | row `4.9  4  both  Review lessons lens` placed after the 4.3 row; `tests/lint/step-list.sh` pins `4:9` on both paths; `PLAN/decision-flow-reference.md` and `PLAN/decision-flow.mermaid` gain the node |
| `check-write.sh` | extend | classification branch for the lessons path before the `other` fallthrough, `KIND=review-lessons`; `REVIEW_LESSONS_STEPS="5.7"`; a `case` arm selecting it |
| `workflow-paths.sh` | extend | `WF_REVIEW_LESSONS` (shared core; integration agent) and its lower-cased `P_` line in `check-write.sh` |
| `modules/review-triage.md` | extend | launches four lenses, waits for four, `PFX` `RL` for `review-lessons`, "Failed lenses" admits the fourth |
| `retrospective/SKILL.md`, `modules/routing.md`, `assets/retrospective.md` | extend | third destination "Review lesson" with the distinction from a judgement lesson (design-log, Module audit follow-up); copy the feature-workflow template when the file is missing; append the approved entry with the next id; retire a superseded entry in place; "Recorded in" names the file and id; the Kind column, the routing table and step 6's list change together |
| `project-setup/modules/files.md` | extend | one table row: `.workflow/review-lessons.md` from `.agents/skills/feature-workflow/assets/review-lessons.md`, copy as is |
| `feature-workflow/SKILL.md` guarded-writes table | extend | row `.workflow/review-lessons.md` → 5.7 |
| `tier-a-write-guard.sh` header | extend | prose names the lessons file; logic unchanged |

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | `WF_REVIEW_LESSONS` in `workflow-paths.sh` (shared core, integration agent) | extend | yes | - | none |
| M2 | `check-write.sh` class and 5.7-only steps; `SKILL.md` guarded-writes row; `tier-a-write-guard.sh` header | extend | yes | M1 | none |
| M3 | feature-workflow template `assets/review-lessons.md` and the project-setup `files.md` row | create / extend | yes | - | new projects get an empty file; existing projects get it at their next 5.7 |
| M4 | `resolve-launch.sh` row and `.workflow/model-map/review-lessons.md` | extend / create | yes | - | none |
| M5 | `steps.tsv` row `4.9`, lint counts, both PLAN docs | extend | yes | - | none |
| M6 | `.agents/agents/review-lessons.md`, regenerated Codex toml, manifest, PROVENANCE, READMEs, assetlist | create / extend | yes | M4 | none |
| M7 | `modules/review-triage.md` four lenses, design-log asset lens list | extend | yes | M5, M6 | none |
| M8 | retrospective `SKILL.md`, `routing.md`, `assets/retrospective.md`, sign-off 5.7 prose | extend | yes | M2, M3 | none |
| M9 | harness suite for the lens contract and the guard case; existing suites extended | create / extend | yes | M1-M8 | fixture lesson text lives only in the suite and the live-run fixture |
