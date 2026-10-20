#!/usr/bin/env bash
# File: Shared script (host-neutral, not a hook): resolve the model and profile text for one sub-agent launch.
# Purpose: Parse and validate the D37 launch header (the fenced ```yaml launch-header block on the prompt's first line) against the per-task-type
#   requirements table (D31, owned here), resolve the model for the host by D35 precedence, resolve the work type and the profile text, and return
#   everything a launch needs: hooks/pre-launch.sh turns it into updatedInput (D33); on Codex the orchestrator places model and prompt itself (D9).
# Triggers/inputs: hooks/pre-launch.sh on every Claude launch (D33); hooks/post-implementation-audit.sh (--parse-header, D39); on Codex the
#   feature-workflow modules before every launch (advisory, D9).
# Plan refs: 00.11-00.14, 00.18-00.20; reference "Model selection", "Sub-agent task types", "Work profiles"; assetlist D9, D12, D13, D14, D18, D23, D31, D32, D33, D35, D37, D38, D80.
# Sources: first-party; PLAN/decision-flow-reference.md "Sub-agent task types" (D31 table), "Model selection", 00.11-00.20; assetlist D13, D14, D18, D31, D33, D35, D37, D38.
#
# CLI:
#   resolve-launch.sh --host claude|codex --task-type <type> [--project-dir <dir>] [--prompt-file <path>|-]
#       Resolve mode (default). Reads the launch prompt (stdin by default). Pre-launch passes tool_input.subagent_type as --task-type;
#       a header task_type that disagrees is denied (D37).
#   resolve-launch.sh --host claude|codex --task-type <type> [--spec-dir <d>] [--task-id <id>] [--work-type <wt>] [--no-header] [--project-dir <dir>]
#       Orchestrator mode (Codex, D9). Builds the header from the flags (task_type = --task-type) instead of reading it; stdin, when it is not a
#       terminal, is the task body (it must not carry its own header). --no-header (header-optional types only: cache-regeneration bulk runs, standards-discovery) builds no header.
#       Prints the same JSON; .prompt is the complete launch prompt to send.
#   resolve-launch.sh --parse-header [--task-type <type>] [--prompt-file <path>|-]
#       Extract and validate the header only (syntax, known task_type, D31 shape, field formats; no file lookups). With --task-type, also deny a
#       header whose task_type disagrees, and accept a header-less prompt when that type allows it (prints {}). stdout: the header as JSON.
#   resolve-launch.sh --requirements [--task-type <type>]
#       Print the D31 table (or one entry) as JSON.
# Project root (--project-dir, else $CLAUDE_PROJECT_DIR, else the current directory): always normalised to the main checkout via
#   `git rev-parse --git-common-dir`, so a worktree cwd works; .workflow/agent-overrides.yaml, .workflow/model-map/, .workflow/profiles/, .agents/agents/ and .workflow/specs/ are read there (D18).
# Model (D35): <root>/agent-overrides.yaml [type][host] > <root>/.agents/agents/<type>.md frontmatter models.<host> > <root>/model-map/<type>.md
#   frontmatter [host] > none: deny with 00.14. Empty values and unfilled template placeholders (`<...>`) count as unset. model-map `fallback` is not used.
# Work type: header work_type; for implementation and profile-mini-review with task_id, the task record in <spec_dir>/tasks.md is authoritative:
#   it fills a missing header work_type, and a header value that disagrees is denied. Phase 1 implementation (no task_id) carries it explicitly (D14).
# Profile (coding types only): implementation, integration = whole .workflow/profiles/<work_type>.md; profile-mini-review = its "## Mini-review checklist"
#   section (heading through the line before the next level-2 heading); other types = null. Missing profile or section: deny with 00.19.
# stdout (resolve and orchestrator modes): one JSON object
#   {task_type, host, model, model_source: "override"|"definition"|"map", header: {...}|null, header_block: "<fenced block>"|null,
#    work_type: <string>|null, profile: <string>|null, profile_path: <relative path>|null, prompt: <launch prompt>}
#   prompt = header block, blank line, profile, blank line, rest of the prompt (D37: the header stays first). Unchanged when there is no profile
#   (resolve mode). In orchestrator mode it is assembled from header block, profile and body.
# Exit: 0 resolved / valid; 2 deny, reason on stderr (malformed or missing header, D31 violation, task_type mismatch, unreadable project file,
#   00.14, 00.19); 1 usage or environment error (bad flags, jq or mikefarah yq v4 missing).
# Requires: bash, jq, mikefarah yq v4 (D38), git (optional; without a repo the root is used as given).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

usage_err() { echo "resolve-launch.sh: $*" >&2; exit 1; }
deny() { echo "resolve-launch.sh: $*" >&2; exit 2; }

# ── D31 requirements table (single source of truth; pre-launch.sh and post-implementation-audit.sh reuse it through this script) ──
# Per type: d31_fields = the D31 row; shapes = header key sets accepted (keys other than task_type; first match wins);
# header_optional = a header-less prompt is accepted; profile = whole | checklist | none.
D31_TABLE=$(cat <<'JSON'
{
  "implementation": {
    "d31_fields": ["spec_dir", "task_id", "work_type"],
    "shapes": [
      {"when": "task launch (3.3); work_type looked up from tasks.md by task_id", "required": ["spec_dir", "task_id"], "optional": ["work_type"]},
      {"when": "Phase 1 launch (1.2, 1.3): no task record yet, explicit work_type (D14)", "required": ["spec_dir", "work_type"], "optional": []}
    ],
    "header_optional": false, "profile": "whole"
  },
  "integration": {
    "d31_fields": ["spec_dir", "work_type"],
    "shapes": [{"when": "one batch of one work type (D28)", "required": ["spec_dir", "work_type"], "optional": []}],
    "header_optional": false, "profile": "whole"
  },
  "profile-mini-review": {
    "d31_fields": ["spec_dir", "task_id", "work_type"],
    "shapes": [{"when": "one task's diff; work_type looked up from tasks.md by task_id", "required": ["spec_dir", "task_id"], "optional": ["work_type"]}],
    "header_optional": false, "profile": "checklist"
  },
  "retrieval":          {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 0", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "library-evaluation": {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 0", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "fact-lookup":        {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 0", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "module-audit":       {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 0", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "review-standards":   {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 4 lens", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "review-end-state":   {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 4 lens", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "review-targets":     {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 4 lens", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"},
  "cache-regeneration": {
    "d31_fields": ["spec_dir"],
    "shapes": [
      {"when": "inside a feature (0.2.8)", "required": ["spec_dir"], "optional": []},
      {"when": "bulk regenerate-caches run: no header", "required": [], "optional": []}
    ],
    "header_optional": true, "profile": "none"
  },
  "standards-discovery": {
    "d31_fields": [],
    "shapes": [{"when": "project-standards run outside any feature (D80): task_type only, or no header", "required": [], "optional": []}],
    "header_optional": true, "profile": "none"
  }
}
JSON
)

# Field formats (D37 values; task ids per the tasks.md schema; work_type names a file under .workflow/profiles/).
SPECS_RE=$(printf '%s' "$WF_SPECS" | sed 's/\./[.]/g')   # literal dots, no JSON escaping needed
FORMATS='{"spec_dir": "^'"$SPECS_RE"'/[0-9]+-[A-Za-z0-9._-]+/?$", "task_id": "^T[0-9]+$", "work_type": "^[A-Za-z0-9][A-Za-z0-9._-]*$"}'
FENCE_OPEN='```yaml launch-header'

# ── Arguments ──
mode=resolve host="" task_type="" project_dir="" prompt_file="-"
f_spec="" f_task="" f_wt="" f_none=0 flag_mode=0
while [ $# -gt 0 ]; do
  case "$1" in
    --parse-header) mode=parse; shift ;;
    --requirements) mode=requirements; shift ;;
    --host) [ $# -ge 2 ] || usage_err "--host needs a value"; host=$2; shift 2 ;;
    --task-type) [ $# -ge 2 ] || usage_err "--task-type needs a value"; task_type=$2; shift 2 ;;
    --project-dir) [ $# -ge 2 ] || usage_err "--project-dir needs a value"; project_dir=$2; shift 2 ;;
    --prompt-file) [ $# -ge 2 ] || usage_err "--prompt-file needs a value"; prompt_file=$2; shift 2 ;;
    --spec-dir) [ $# -ge 2 ] || usage_err "--spec-dir needs a value"; f_spec=$2; flag_mode=1; shift 2 ;;
    --task-id) [ $# -ge 2 ] || usage_err "--task-id needs a value"; f_task=$2; flag_mode=1; shift 2 ;;
    --work-type) [ $# -ge 2 ] || usage_err "--work-type needs a value"; f_wt=$2; flag_mode=1; shift 2 ;;
    --no-header) f_none=1; flag_mode=1; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) usage_err "unknown argument: $1" ;;
  esac
done

command -v jq >/dev/null 2>&1 || usage_err "jq not found"

if [ -n "$task_type" ] && ! jq -e --arg t "$task_type" 'has($t)' <<<"$D31_TABLE" >/dev/null; then
  deny "unknown task type '$task_type' (known: $(jq -r 'keys | join(", ")' <<<"$D31_TABLE"))"
fi

if [ "$mode" = requirements ]; then
  if [ -n "$task_type" ]; then jq --arg t "$task_type" '{($t): .[$t]}' <<<"$D31_TABLE"; else jq . <<<"$D31_TABLE"; fi
  exit 0
fi

command -v yq >/dev/null 2>&1 || usage_err "yq not found (mikefarah yq v4 required; D38)"
yq --version 2>&1 | grep -q 'mikefarah' || usage_err "yq is not mikefarah yq v4 (D38)"

if [ "$mode" = resolve ]; then
  case "$host" in claude|codex) ;; '') usage_err "missing --host (claude|codex)" ;; *) usage_err "--host must be claude or codex, got '$host'" ;; esac
  [ -n "$task_type" ] || usage_err "missing --task-type"
else
  [ "$flag_mode" = 0 ] || usage_err "--spec-dir/--task-id/--work-type/--no-header apply to resolve mode only"
fi
if [ "$flag_mode" = 1 ] && [ "$f_none" = 1 ] && [ -n "$f_spec$f_task$f_wt" ]; then
  usage_err "--no-header cannot be combined with header fields"
fi

# ── Input ──
if [ "$prompt_file" = - ]; then
  if [ "$flag_mode" = 1 ] && [ -t 0 ]; then input=x; else input=$(cat; printf x); fi
else
  [ -f "$prompt_file" ] || usage_err "--prompt-file not found: $prompt_file"
  input=$(cat "$prompt_file"; printf x)
fi
input=${input%x} # trailing newlines preserved

# ── Header extraction (D37) ──
# Sets: header_json (JSON object, or "null" when the prompt has no header), header_block (the fenced text), rest (prompt after the block).
header_json=null header_block="" rest=$input
extract_header() {
  local text=$1 first line body="" closed=0 tail
  first=${text%%$'\n'*}
  first=${first%$'\r'}
  first=${first%"${first##*[![:space:]]}"}
  if [ "$first" != "$FENCE_OPEN" ]; then
    if grep -qF -- "$FENCE_OPEN" <<<"$text"; then
      deny "malformed launch header: the \`\`\`yaml launch-header block must open on the prompt's first line (D37)"
    fi
    return 0
  fi
  [[ $text == *$'\n'* ]] || deny "malformed launch header: no closing \`\`\` fence (D37)"
  tail=${text#*$'\n'}
  while :; do
    if [[ $tail == *$'\n'* ]]; then line=${tail%%$'\n'*}; tail=${tail#*$'\n'}; else line=$tail; tail=""; fi
    local trimmed=${line%$'\r'}; trimmed=${trimmed%"${trimmed##*[![:space:]]}"}
    if [ "$trimmed" = '```' ]; then closed=1; break; fi
    body+=$line$'\n'
    [ -n "$tail" ] || break
  done
  [ "$closed" = 1 ] || deny "malformed launch header: no closing \`\`\` fence (D37)"
  header_block=$FENCE_OPEN$'\n'$body'```'
  rest=$tail
  [ -n "${body//[[:space:]]/}" ] || deny "malformed launch header: the block is empty; it must hold at least task_type (D37)"
  local parsed
  parsed=$(printf '%s' "$body" | yq -o=json -I=0 '.' - 2>/dev/null) || deny "malformed launch header: not valid YAML (D37)"
  jq -e 'type == "object"' <<<"$parsed" >/dev/null 2>&1 || deny "malformed launch header: expected a YAML mapping of fields (D37)"
  header_json=$parsed
}

# Validate header_json against the D31 table. $1 = expected task type ("" = use the header's own).
# Prints the matched shape's "when" text.
validate_header() {
  local expected=$1 err
  if [ "$header_json" = null ]; then
    [ -n "$expected" ] || deny "no launch header: the prompt must start with a \`\`\`yaml launch-header block (D37)"
    if jq -e --arg t "$expected" '.[$t].header_optional' <<<"$D31_TABLE" >/dev/null; then
      jq -r --arg t "$expected" '.[$t].shapes[] | select(.required == []) | .when' <<<"$D31_TABLE" | head -n1
      return 0
    fi
    deny "no launch header: task type '$expected' requires a \`\`\`yaml launch-header block first in the prompt with $(jq -r --arg t "$expected" '.[$t].d31_fields | join(", ")' <<<"$D31_TABLE") (D31, D37)"
  fi
  err=$(jq -r --argjson tbl "$D31_TABLE" --argjson fmt "$FORMATS" --arg exp "$expected" '
    def shape_text: "{" + ((.required + (.optional | map(. + "?"))) | join(", ")) + "}";
    . as $h
    | if ($h.task_type | type) != "string" or $h.task_type == "" then "header has no task_type (D37)"
      elif ($tbl | has($h.task_type) | not) then "unknown task_type \u0027\($h.task_type)\u0027 in header"
      elif $exp != "" and $h.task_type != $exp then "header task_type \u0027\($h.task_type)\u0027 disagrees with the launched task type \u0027\($exp)\u0027 (D37)"
      else
        ($h | del(.task_type)) as $f
        | ($f | keys) as $k
        | ($tbl[$h.task_type]) as $e
        | ([$e.shapes[] | select(((.required - $k) | length) == 0 and (($k - (.required + .optional)) | length) == 0)] | first) as $m
        | ([$f | to_entries[] | select((.value | type) != "string" or .value == "") | .key]) as $bad
        | ([$f | to_entries[] | .key as $kk | select(($fmt | has($kk)) and (.value | type) == "string" and (.value | test($fmt[$kk]) | not))
            | "\(.key)=\(.value) (expected \($fmt[.key]))"]) as $badfmt
        | if $m == null then
            "header fields {\($k | join(", "))} do not match task type \u0027\($h.task_type)\u0027 (D31); accepted: \([$e.shapes[] | shape_text + " (" + .when + ")"] | join("; "))"
          elif ($bad | length) > 0 then "header field(s) \($bad | join(", ")) must be non-empty strings"
          elif ($badfmt | length) > 0 then "malformed header value(s): \($badfmt | join("; "))"
          else "" end
      end' <<<"$header_json")
  [ -z "$err" ] || deny "$err"
  jq -r --argjson tbl "$D31_TABLE" '
    (del(.task_type) | keys) as $k | $tbl[.task_type].shapes[]
    | select(((.required - $k) | length) == 0 and (($k - (.required + .optional)) | length) == 0) | .when' <<<"$header_json" | head -n1
}

# ── Parse-header mode ──
if [ "$mode" = parse ]; then
  extract_header "$input"
  validate_header "$task_type" >/dev/null
  if [ "$header_json" = null ]; then echo '{}'; else jq . <<<"$header_json"; fi
  exit 0
fi

# ── Resolve / orchestrator mode ──
if [ "$flag_mode" = 1 ]; then
  if grep -qF -- "$FENCE_OPEN" <<<"$input"; then
    deny "orchestrator mode builds the header from flags; the task body must not carry its own launch-header block"
  fi
  if [ "$f_none" = 1 ]; then
    header_json=null
  else
    header_json=$(jq -cn --arg t "$task_type" --arg s "$f_spec" --arg i "$f_task" --arg w "$f_wt" \
      '{task_type: $t} + (if $s != "" then {spec_dir: $s} else {} end) + (if $i != "" then {task_id: $i} else {} end) + (if $w != "" then {work_type: $w} else {} end)')
    header_block=$FENCE_OPEN$'\n'$(jq -r 'to_entries[] | "\(.key): \(.value)"' <<<"$header_json")$'\n''```'
  fi
  rest=$input
else
  extract_header "$input"
fi
validate_header "$task_type" >/dev/null

# Project root: main checkout (D18).
root=${project_dir:-${CLAUDE_PROJECT_DIR:-$PWD}}
[ -d "$root" ] || usage_err "project directory not found: $root"
root=$(cd "$root" && pwd)
if common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  root=$(dirname "$common")
fi

hfield() { jq -r --arg k "$1" '.[$k] // ""' <<<"$header_json"; }
spec_dir="" task_id="" work_type=""
if [ "$header_json" != null ]; then
  spec_dir=$(hfield spec_dir); spec_dir=${spec_dir%/}
  task_id=$(hfield task_id)
  work_type=$(hfield work_type)
fi
if [ -n "$spec_dir" ] && [ ! -d "$root/$spec_dir" ]; then
  deny "spec_dir '$spec_dir' does not exist under $root"
fi

# Load a YAML file (its frontmatter when $2 = fm) as JSON; comments are dropped. No frontmatter -> {}. Unreadable file -> deny.
yaml_json() {
  local file=$1 fm=${2:-} out
  if [ "$fm" = fm ]; then
    [ "$(head -n1 "$file" | tr -d '\r')" = --- ] || { echo '{}'; return 0; }
    out=$(yq --front-matter=extract -o=json -I=0 '.' "$file" 2>/dev/null) || deny "cannot parse frontmatter: ${file#"$root"/}"
  else
    out=$(yq -o=json -I=0 '.' "$file" 2>/dev/null) || deny "cannot parse YAML: ${file#"$root"/}"
  fi
  printf '%s' "${out:-null}"
}
# Pick a model string from JSON by path; unset, empty, non-string and unfilled `<...>` placeholders give "".
pick_model() { # $1 = json, then path keys
  local json=$1; shift
  jq -r '(getpath($ARGS.positional) // "") as $v
    | if ($v | type) == "string" and ($v | test("^\\s*(<.*>)?\\s*$") | not) then $v else "" end' \
    --args "$@" <<<"$json" 2>/dev/null || true
}

# ── Model (D35) ──
model="" model_source=""
if [ -f "$root/$WF_AGENT_OVERRIDES" ]; then
  doc=$(yaml_json "$root/$WF_AGENT_OVERRIDES")
  model=$(pick_model "$doc" "$task_type" "$host")
  [ -z "$model" ] || model_source=override
fi
if [ -z "$model" ] && [ -f "$root/.agents/agents/$task_type.md" ]; then
  doc=$(yaml_json "$root/.agents/agents/$task_type.md" fm)
  model=$(pick_model "$doc" models "$host")
  [ -z "$model" ] || model_source=definition
fi
if [ -z "$model" ] && [ -f "$root/$WF_MODEL_MAP/$task_type.md" ]; then
  doc=$(yaml_json "$root/$WF_MODEL_MAP/$task_type.md" fm)
  model=$(pick_model "$doc" "$host")
  [ -z "$model" ] || model_source=map
fi
if [ -z "$model" ]; then
  deny "00.14: no model for task type '$task_type' on host '$host'. Checked, in precedence order (D35): $WF_AGENT_OVERRIDES [$task_type][$host], .agents/agents/$task_type.md models.$host, $WF_MODEL_MAP/$task_type.md [$host]. Assign one in $WF_MODEL_MAP/$task_type.md (or in $WF_AGENT_OVERRIDES when the definition pins a model for this host) before launching."
fi

# ── Work type (D14, D31) ──
if [ -n "$task_id" ]; then
  tasks_file=$root/$spec_dir/tasks.md
  [ -f "$tasks_file" ] || deny "task_id $task_id given but $spec_dir/tasks.md not found (D14)"
  [ "$(head -n1 "$tasks_file" | tr -d '\r')" = --- ] || deny "$spec_dir/tasks.md has no YAML frontmatter"
  records=$(RL_TID=$task_id yq --front-matter=extract -o=json -I=0 '[(.tasks // [])[] | select(.id == strenv(RL_TID))]' "$tasks_file" 2>/dev/null) \
    || deny "cannot parse tasks.md frontmatter: $spec_dir/tasks.md"
  [ "$(jq 'length' <<<"$records")" -ge 1 ] || deny "task $task_id not found in $spec_dir/tasks.md"
  task_wt=$(jq -r '.[0].work_type // "" | if type == "string" then . else "" end' <<<"$records")
  [ -n "$task_wt" ] || deny "00.18: task $task_id has no work_type in $spec_dir/tasks.md; classify it (3.1) before launching"
  if [ -n "$work_type" ] && [ "$work_type" != "$task_wt" ]; then
    deny "header work_type '$work_type' disagrees with task $task_id's work_type '$task_wt' in $spec_dir/tasks.md"
  fi
  work_type=$task_wt
  jq -en --argjson fmt "$FORMATS" --arg w "$work_type" '$w | test($fmt.work_type)' >/dev/null \
    || deny "task $task_id has a malformed work_type '$work_type' in $spec_dir/tasks.md"
fi

# ── Profile (00.18-00.20) ──
profile_kind=$(jq -r --arg t "$task_type" '.[$t].profile' <<<"$D31_TABLE")
profile=null profile_path=null profile_text=""
if [ "$profile_kind" != none ]; then
  rel=$WF_PROFILES/$work_type.md
  [ -f "$root/$rel" ] || deny "00.19: no profile for work type '$work_type' ($rel not found). Define it from $WF_PROFILES/TEMPLATE.md before launching."
  if [ "$profile_kind" = whole ]; then
    profile_text=$(cat "$root/$rel"; printf x); profile_text=${profile_text%x}
  else
    profile_text=$(awk '
      /^(```|~~~)/ { fence = !fence }
      !fence && /^## / { if (insec) exit; if ($0 ~ /^## Mini-review checklist[[:space:]]*$/) insec = 1 }
      insec { print }' "$root/$rel")
    [ -n "$profile_text" ] || deny "00.19: profile $rel has no '## Mini-review checklist' section ($WF_PROFILES/TEMPLATE.md contract)"
  fi
  # Trim trailing blank lines so the assembled prompt is stable.
  while [[ $profile_text == *$'\n' ]]; do profile_text=${profile_text%$'\n'}; done
  profile=$profile_text profile_path=$rel
fi

# ── Prompt assembly (D37: header first, profile right after it) ──
strip_leading_newlines() { local s=$1; while [[ $s == $'\n'* || $s == $'\r\n'* ]]; do s=${s#$'\r'}; s=${s#$'\n'}; done; printf '%s' "$s"; }
if [ "$flag_mode" = 0 ] && [ "$profile" = null ]; then
  prompt=$input
else
  body=$(strip_leading_newlines "$rest"; printf x); body=${body%x}
  prompt=""
  [ -z "$header_block" ] || prompt=$header_block
  if [ "$profile" != null ]; then prompt=${prompt:+$prompt$'\n\n'}$profile_text; fi
  if [ -n "$body" ]; then prompt=${prompt:+$prompt$'\n\n'}$body; fi
fi

jq -n \
  --arg task_type "$task_type" --arg host "$host" --arg model "$model" --arg model_source "$model_source" \
  --argjson header "$header_json" --arg header_block "$header_block" \
  --arg work_type "$work_type" --arg profile "$profile_text" --arg profile_kind "$profile_kind" --arg profile_path "${profile_path}" \
  --arg prompt "$prompt" '
  {task_type: $task_type, host: $host, model: $model, model_source: $model_source,
   header: $header,
   header_block: (if $header_block == "" then null else $header_block end),
   work_type: (if $work_type == "" then null else $work_type end),
   profile: (if $profile_kind == "none" then null else $profile end),
   profile_path: (if $profile_kind == "none" then null else $profile_path end),
   prompt: $prompt}'
