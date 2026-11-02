<!--
File: Template for the project's review-lessons file: mistakes a review caught that no rule or tool enforces yet, so the next review looks for them again.
Only the retrospective adds or retires an entry; every other step reads the file.

Entry rules, one item of the `lessons` list per lesson:
  - id: RL- and at least three digits (RL-001), unique in the file. A new entry takes the highest id present plus one. An id is never reused, so a retired entry stays in the list and keeps its id taken.
  - symptom: what went wrong, in one or two plain sentences a reviewer can match against a diff. Never empty.
  - paths: at least one glob, relative to the repo root, naming the files where the mistake can recur (src/**). No absolute path, no `..`.
  - origin_spec: the spec folder the lesson came from, written as `.workflow/specs/`, or `.workflow/specs/done/` once the spec has moved into the Done folder, then the spec number (in the Done folder optionally after `old_`, the prefix tracker adoption gives a finished spec), a dash and a slug that starts with a letter or digit and holds only letters, digits, `.`, `_` and `-`.
  - date: the day the lesson was recorded, YYYY-MM-DD.
  - retired: optional, the day a rule or a tool started to enforce the lesson, YYYY-MM-DD. A retired entry also needs enforced_by.
  - enforced_by: required once retired is set, never empty: the rule line or tool check that now catches the mistake.

Two commands check the file and give the next id. Each takes the file path as its one argument and runs the feature-workflow script review-lessons.sh, which holds these rules in executable form:
validate: "$(git rev-parse --show-toplevel)"/.agents/skills/feature-workflow/scripts/review-lessons.sh validate "$1"
next-id: "$(git rev-parse --show-toplevel)"/.agents/skills/feature-workflow/scripts/review-lessons.sh next-id "$1"
-->

# Review lessons

```yaml
lessons: []
```
