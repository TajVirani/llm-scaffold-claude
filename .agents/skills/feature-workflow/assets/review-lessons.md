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

Two commands check the file and give the next id. Each takes the file path as its one argument (bash, then mikefarah yq v4 and jq):
validate: set -o pipefail; awk '/^```yaml$/{f=1;next} /^```$/{if(f)exit} f' "$1" | yq -o=json '.' - | jq -e 'def iso_date: type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"); type == "object" and (.lessons | type == "array") and ([.lessons[].id] | length == (unique | length)) and all(.lessons[]; type == "object" and (.id | type == "string" and test("^RL-[0-9]{3,}$")) and (.symptom | type == "string" and length > 0) and (.paths | type == "array" and length > 0 and all(.[]; type == "string" and length > 0 and (startswith("/") | not) and (split("/") | any(. == "..") | not))) and (.origin_spec | type == "string" and test("^\\.workflow/specs/[0-9]{3}-[a-z0-9-]+$")) and (.date | iso_date) and (if has("retired") then (.retired | iso_date) and (.enforced_by | type == "string" and length > 0) else true end))' >/dev/null || { echo "review lessons: $1 breaks the entry rules in its header" >&2; exit 1; }
next-id: set -o pipefail; awk '/^```yaml$/{f=1;next} /^```$/{if(f)exit} f' "$1" | yq -o=json '.' - | jq -r '([.lessons[]?.id | ltrimstr("RL-") | tonumber] | max // 0) + 1 | tostring | if length < 3 then ("00" + .)[-3:] else . end | "RL-" + .'
-->

# Review lessons

```yaml
lessons: []
```
