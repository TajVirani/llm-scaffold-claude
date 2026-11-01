<!--
File: Template for the project's review-lessons file: mistakes a review caught that no rule or tool enforces yet, so the next review looks for them again.
Only the retrospective adds or retires an entry; every other step reads the file.

Entry rules, one item of the `lessons` list per lesson:
  - id: RL- and at least three digits (RL-001), unique in the file. A new entry takes the highest id present plus one. An id is never reused, so a retired entry stays in the list and keeps its id taken.
  - symptom: what went wrong, in one or two plain sentences a reviewer can match against a diff. Never empty.
  - paths: at least one glob, relative to the repo root, naming the files where the mistake can recur (src/**). No absolute path, no `..`.
  - origin_spec: the spec folder the lesson came from, written as `.workflow/specs/` then a three-digit number and a lowercase slug.
  - date: the day the lesson was recorded, YYYY-MM-DD.
  - retired: optional, the day a rule or a tool started to enforce the lesson, YYYY-MM-DD. A retired entry also needs enforced_by.
  - enforced_by: required once retired is set, never empty: the rule line or tool check that now catches the mistake.

Two commands check the file and give the next id. Each takes the file path as its one argument and runs the feature-workflow script review-lessons.sh, which holds these rules in executable form:
validate: "$(git rev-parse --show-toplevel)"/.agents/skills/feature-workflow/scripts/review-lessons.sh validate "$1"
next-id: "$(git rev-parse --show-toplevel)"/.agents/skills/feature-workflow/scripts/review-lessons.sh next-id "$1"
-->

# Review lessons

```yaml
lessons:
  - id: RL-001
    symptom: "A change adds a task type or an agent definition but leaves a hard-coded count or list stale: the Agents (N) header of install-manifest.txt, the agents row and the 'the N agents/*.md' line of PROVENANCE.md, project-setup's model-map tier table and its 'N task types' lines, or the type counts pinned in tests/scripts/resolve-launch.sh and tests/lint/step-list.sh."
    paths: [".agents/agents/**", ".agents/install-manifest.txt", "PROVENANCE.md", ".agents/skills/project-setup/**"]
    origin_spec: .workflow/specs/done/002-review-lessons
    date: 2026-10-22
  - id: RL-002
    symptom: "A change makes a Phase 1 stub or helper real, or starts sourcing it, but its PROVENANCE.md row still says placeholder or 'to be sourced by'."
    paths: ["PROVENANCE.md", ".agents/lib/**"]
    origin_spec: .workflow/specs/done/005-cache-build-followups
    date: 2026-10-29
  - id: RL-003
    symptom: "A change alters what a script accepts, prints or exits with, but the module or SKILL.md prose that tells agents how to call it or read its result still describes the old behaviour."
    paths: [".agents/skills/*/modules/**", ".agents/skills/*/SKILL.md", ".agents/skills/*/scripts/**"]
    origin_spec: .workflow/specs/done/008-pr-description-template
    date: 2026-10-30
  - id: RL-004
    symptom: "A file under an installed skill's assets/ or modules/ names a specific .workflow/deferred/, .workflow/specs/ or .workflow/decisions/ file that only this scaffold repo holds, so every target project gets a dead path."
    paths: [".agents/skills/*/assets/**", ".agents/skills/*/modules/**"]
    origin_spec: .workflow/specs/done/008-pr-description-template
    date: 2026-10-30
  - id: RL-005
    symptom: "A guard treats a tool as a read and denies its write forms with a regex denylist over flags or script text, so an unusual spelling (a custom delimiter, an attached file name, a script file) still passes as a read; allowlist the read forms instead."
    paths: [".agents/skills/feature-workflow/scripts/check-worktree-scope.sh", ".agents/hooks/**"]
    origin_spec: .workflow/specs/done/006-result-file-guard
    date: 2026-10-30
  - id: RL-006
    symptom: "A test extracts a command from an agent doc and fills different path placeholders (worktree, checkout, launched-in) with the same expected path, so a doc that names the wrong checkout still passes."
    paths: ["tests/**"]
    origin_spec: .workflow/specs/done/006-result-file-guard
    date: 2026-10-30
  - id: RL-007
    symptom: "A change that hides quoted text from the bash graph extractor also hides a command substitution in one of its forms ($(...) or backticks) inside double quotes, so a real call stops being reported."
    paths: [".agents/skills/regenerate-caches/scripts/extractors/**"]
    origin_spec: .workflow/specs/done/00012-extractor-multiline-quotes
    date: 2026-10-30
```
