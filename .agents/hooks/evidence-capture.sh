#!/usr/bin/env bash
# File: Hook (Claude and Codex adapter): file browser-suite evidence after a browser-suite run (3.12).
# Goals:
#   - After a Bash call that ran the browser suite, copy screenshots, traces, videos and the console / network attachments of every
#     failing test and every journey-tagged (JRN-###) test into .workflow/specs/NNN-slug/artifacts/, filed by run and journey id, plus an index.
# Triggers/inputs: PostToolUse and PostToolUseFailure JSON for Bash (tool_input.command, cwd). tool_input.command is a string, or an argv
#   array (Codex): a [bash|sh|zsh, -c|-lc|..., script] array is read as its script; any other array is joined with spaces, each element
#   shell-quoted only when it holds characters outside [A-Za-z0-9_@%+=:,./-], so a plain argv still matches the prefixes below. A Bash call that exits non-zero fires only
#   PostToolUseFailure on Claude Code 2.1.303 (payload: error, is_interrupt, duration_ms, no tool_response); a failing suite is the run whose
#   evidence matters most (F-1), so both events are wired. The hook never reads tool_response or error: the JSON report is the source. Paths from the payload `cwd` (D18); .workflow/specs/ and the gitignored .step
#   markers are read in the main checkout (git rev-parse --git-common-dir), since a 1.4 run happens in a throwaway worktree.
# Match (leading NAME=value env assignments are skipped first; E2E_INJECT_FAULT=1 among them marks the run fault-injected, 1.4):
#   - the command starts with the `e2e` value of the e2e-browser profile's Toolchain block (.workflow/profiles/e2e-browser.md in cwd, then the main
#     checkout), or with `npx playwright test`; followed by end of command or whitespace (agents append --grep @JRN-001, --project, -x); or
#   - the command runs run-toolchain.sh with --e2e (3.10); its --spec-dir, --task-id, --cwd and --work-type / --profile are used when they
#     are literal (a value holding `$` or a backtick is unexpanded text and is ignored).
#   - A command carrying --list (collect only, the e2e-browser `test` key) never matches.
# Report: the profile's descriptive Toolchain key `e2e_report` (default test-results/e2e-results.json), relative to the run directory.
#   A report older than 15 minutes is stale (the run crashed before writing one): nothing is filed.
# Spec: --spec-dir from a run-toolchain.sh command; otherwise the in-flight spec in .workflow/specs/*/ (status ready-for-dev, in-progress, in-review
#   or blocked; .workflow/specs/work-backlog/ skipped) whose .step has the latest updated_at; a single in-flight spec without .step also counts.
# Destination (main checkout): .workflow/specs/NNN-slug/artifacts/<task-id>/ for a run-toolchain.sh run (earlier evidence of this hook in that
#   directory is replaced, as toolchain.txt is), else .workflow/specs/NNN-slug/artifacts/e2e-<run-id>/, run-id = UTC timestamp + short HEAD sha.
#   Inside: <JRN-###>/ (or untagged/ for a failing test without a journey tag) holding <name>[-retry<r>][-<k>].<ext> (k on a name clash),
#   e2e-results.json (the report) and evidence-index.json (run, command, stats, and per test: title, file:line, project, tags,
#   journeys, outcome, final status, files).
#   Attachments with a `path` are copied; those with only a `body` (base64 in the JSON report; the console / network logs) are decoded.
# Outputs/handoff: Evidence for 3.11, 4.2 and 5.4. stdout: nothing when the command is not a browser-suite run (or no workflow is
#   installed); after filing, {"hookSpecificOutput":{"hookEventName":"PostToolUse" (or "PostToolUseFailure", echoing the payload),"additionalContext":"..."}} naming the directory;
#   a {"systemMessage":...} when a matching run could not be filed (no report, stale report, no in-flight spec, yq missing).
#   Exit code always 0: neither event can undo the run, so this hook never blocks; any internal failure exits 0 silently (fail-safe).
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh, D36): PostToolUse and PostToolUseFailure,
#   matcher "Bash" each. codex-hooks.template.json (<target>/.codex/hooks.json): PostToolUse, matcher "Bash"; Codex fires it after non-zero
#   exits too, with tool_response a plain string (PLAN/hook-verification-codex.md row 6), which this hook never reads.
# Plan refs: 1.4, 3.10, 3.11, 3.12; assetlist D9, D15, D18, D38, D62, D63.
# Notes: The hook never runs the suite. Where it is not installed, the orchestrator copies the evidence itself (D9).
# Sources: first-party, from PLAN/gap-research.md G1 (match rule, JSON report parse, artifact layout; written from the Playwright docs,
#   Apache-2.0, no text copied: https://playwright.dev/docs/test-reporters, https://playwright.dev/docs/api/class-testinfo, JSON shape from
#   microsoft/playwright packages/playwright/src/reporters/json.ts); PLAN/hook-verification.md (PostToolUse payload, worktree cwd);
#   hooks reference https://code.claude.com/docs/en/hooks (PostToolUse additionalContext, systemMessage); profile Toolchain extraction as in
#   skills/feature-workflow/scripts/run-toolchain.sh; .step format in skills/feature-workflow/scripts/status-transition.sh.
# Requires: bash 3.2+, jq, mikefarah yq v4 (D38), git (optional), base64 (optional; jq @base64d is the fallback for text bodies).

set -euo pipefail

# Workflow paths (D81).
# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"

STALE_MINUTES=15
DEFAULT_PREFIX="npx playwright test"
DEFAULT_REPORT="test-results/e2e-results.json"

# Fail-safe: whatever happens, exit 0 (an error mid-way leaves partial evidence and no output).
trap 'exit 0' EXIT

command -v jq >/dev/null 2>&1 || exit 0
payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 || exit 0
[ "$(jq -r '.tool_name // "" | strings' <<<"$payload")" = Bash ] || exit 0
cmd=$(jq -r '.tool_input.command // ""
  | if type == "array" then
      (if length == 3 and (.[0] | strings | test("(^|/)(ba|z)?sh$")) and (.[1] | strings | test("^-[a-z]*c$")) then .[2] | strings
       else map(tostring | if test("^[A-Za-z0-9_@%+=:,./-]+$") then . else @sh end) | join(" ") end)
    else strings end' <<<"$payload" 2>/dev/null || true)
[ -n "$cmd" ] || exit 0

event=$(jq -r '.hook_event_name // "" | strings' <<<"$payload")
case "$event" in PostToolUse | PostToolUseFailure) ;; *) event=PostToolUse ;; esac

note() { jq -cn --arg m "evidence-capture: $1" '{systemMessage: $m}'; exit 0; }

cwd=$(jq -r '.cwd // "" | strings' <<<"$payload")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
cwd=$(cd "$cwd" && pwd -P)
main_root=$cwd
if common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  main_root=$(cd "$(dirname "$common")" && pwd -P)
fi

# Trim, then skip leading NAME=value assignments.
rest=$cmd
rest="${rest#"${rest%%[![:space:]]*}"}"
fault=false
env_re='^([A-Za-z_][A-Za-z0-9_]*)=([^[:space:]]*)[[:space:]]+(.*)$'
while [[ $rest =~ $env_re ]]; do
  [ "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}" != "E2E_INJECT_FAULT=1" ] || fault=true
  rest=${BASH_REMATCH[3]}
done

# Literal value of a run-toolchain.sh option, or "" (absent, or unexpanded shell text).
opt() {
  local want=$1 prev="" tok toks=()
  read -r -a toks <<<"$cmd" || true
  for tok in ${toks[@]+"${toks[@]}"}; do
    if [ "$prev" = "$want" ]; then
      tok=${tok#[\"\']}; tok=${tok%[\"\']}
      case "$tok" in *'$'* | *'`'*) return 0 ;; esac
      printf '%s' "$tok"
      return 0
    fi
    prev=$tok
  done
}
# True when the command text holds TOKEN as a whole whitespace-separated word.
has_token() {
  case " $cmd " in *[[:space:]]"$1"[[:space:]]*) return 0 ;; esac
  return 1
}

has_token --list && exit 0

via_toolchain=0 task_id="" spec_opt="" run_dir=$cwd profile=""
case "$rest" in
  *run-toolchain.sh*)
    has_token --e2e || exit 0
    via_toolchain=1
    task_id=$(opt --task-id)
    spec_opt=$(opt --spec-dir)
    d=$(opt --cwd)
    if [ -n "$d" ]; then
      case "$d" in /*) ;; *) d=$cwd/$d ;; esac
      [ -d "$d" ] && run_dir=$(cd "$d" && pwd -P)
    fi
    p=$(opt --profile)
    if [ -n "$p" ]; then
      case "$p" in /*) ;; *) p=$cwd/$p ;; esac
      [ -f "$p" ] && profile=$p
    fi
    ;;
esac

# Profile: --profile, else .workflow/profiles/<work-type or e2e-browser>.md in the run directory, cwd, then the main checkout.
if [ -z "$profile" ]; then
  wt=e2e-browser
  if [ "$via_toolchain" -eq 1 ]; then w=$(opt --work-type); [ -z "$w" ] || wt=$w; fi
  for d in "$run_dir" "$cwd" "$main_root"; do
    if [ -f "$d/$WF_PROFILES/$wt.md" ]; then profile=$d/$WF_PROFILES/$wt.md; break; fi
  done
fi

have_yq=0
if command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -q mikefarah; then have_yq=1; fi

block=""
if [ -n "$profile" ]; then
  block=$(awk '
    /^## /{ if (intool) exit; intool = ($0 ~ /^## Toolchain[[:space:]]*$/); next }
    intool && !infence && /^```ya?ml[[:space:]]*$/ { infence=1; next }
    intool && infence && /^```[[:space:]]*$/ { exit }
    intool && infence { print }
  ' "$profile" 2>/dev/null || true)
fi
key() {
  [ "$have_yq" -eq 1 ] && [ -n "$block" ] || return 0
  printf '%s\n' "$block" | K=$1 yq '.[strenv(K)] // "" | select(tag == "!!str")' 2>/dev/null || true
}
e2e_cmd=$(key e2e)
report_rel=$(key e2e_report)
[ -n "$report_rel" ] || report_rel=$DEFAULT_REPORT

starts_with() {
  local p=$1
  [ -n "$p" ] || return 1
  [ "$rest" = "$p" ] && return 0
  case "$rest" in "$p"[[:space:]]*) return 0 ;; esac
  return 1
}
if [ "$via_toolchain" -eq 0 ]; then
  starts_with "$e2e_cmd" || starts_with "$DEFAULT_PREFIX" || exit 0
fi

# From here the command was a browser-suite run: failures to file are reported, not silent.
[ -d "$main_root/$WF_SPECS" ] || exit 0   # no workflow in this project
[ "$have_yq" -eq 1 ] || note "mikefarah yq v4 not found; browser-suite evidence was not filed (D38)."

case "$report_rel" in /*) report=$report_rel ;; *) report=$run_dir/$report_rel ;; esac
[ -f "$report" ] || note "no JSON report at $report; check the json reporter outputFile in playwright.config.ts matches the profile's e2e_report. Evidence was not filed."
[ -n "$(find "$report" -mmin "-$STALE_MINUTES" 2>/dev/null)" ] || note "the JSON report $report is older than $STALE_MINUTES minutes (the run wrote no new report); evidence was not filed."
jq -e 'type == "object" and has("suites")' "$report" >/dev/null 2>&1 || note "$report is not a Playwright JSON report; evidence was not filed."

# Spec directory.
spec_abs=""
if [ -n "$spec_opt" ]; then
  case "$spec_opt" in /*) spec_abs=$spec_opt ;; *) spec_abs=$main_root/$spec_opt ;; esac
  [ -f "$spec_abs/spec.md" ] || spec_abs=""
fi
if [ -z "$spec_abs" ]; then
  best="" best_at="" nostep="" n_nostep=0
  for s in "$main_root/$WF_SPECS"/*/spec.md; do
    [ -f "$s" ] || continue
    d=$(dirname "$s")
    [ "$(basename "$d")" != work-backlog ] || continue
    st=$(yq --front-matter=extract '.status // ""' "$s" 2>/dev/null || true)
    case "$st" in ready-for-dev | in-progress | in-review | blocked) ;; *) continue ;; esac
    at=""
    [ ! -f "$d/.step" ] || at=$(yq '.updated_at // ""' "$d/.step" 2>/dev/null || true)
    if [ -z "$at" ]; then nostep=$d; n_nostep=$((n_nostep + 1)); continue; fi
    if [ -z "$best_at" ] || [[ "$at" > "$best_at" ]]; then best=$d best_at=$at; fi
  done
  spec_abs=$best
  [ -n "$spec_abs" ] || { [ "$n_nostep" -ne 1 ] || spec_abs=$nostep; }
fi
[ -n "$spec_abs" ] || note "no in-flight spec found under $WF_SPECS/ (status ready-for-dev, in-progress, in-review or blocked); evidence from $report was not filed."
spec_rel=${spec_abs#"$main_root"/}

sha=$(git -C "$run_dir" rev-parse --short HEAD 2>/dev/null || echo nogit)
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$sha"
case "$task_id" in
  '' | */* | .*) dest_name="e2e-$run_id" ;;
  *) dest_name=$task_id ;;
esac
dest=$spec_abs/artifacts/$dest_name
mkdir -p "$dest"
if [ -f "$dest/evidence-index.json" ]; then
  # Replace this hook's earlier output in a reused task directory; leave everything else (toolchain.*) alone.
  rm -rf "$dest"/JRN-* "$dest/untagged" "$dest/evidence-index.json" "$dest/e2e-results.json"
fi
cp "$report" "$dest/e2e-results.json"

# Selected tests (failing, or journey-tagged) with their attachments flattened. Suites nest; tags carry no "@" in the report.
tests_json=$(jq -c '
  [ .. | objects | select(has("specs") and (.specs | type == "array")) | .specs[] | . as $s
    | ($s.tests // [])[] as $t
    | (($s.tags // []) | map(select(type == "string" and test("^JRN-[0-9]{3,}$")))) as $j
    | ($t.results // []) as $rs
    | select(($j | length) > 0 or ($rs | any(.status != "passed" and .status != "skipped")))
    | { title: $s.title, file: $s.file, line: $s.line, project: ($t.projectName // ""), tags: ($s.tags // []), journeys: $j,
        outcome: ($t.status // ""), status: (($rs | last | .status) // "unknown"), results: $rs } ]
  | to_entries | map(.value + {id: .key})' "$report")

items=$(jq -r '
  .[] | . as $t | (if ($t.journeys | length) > 0 then $t.journeys[] else "untagged" end) as $g
  | $t.results[] | (.retry // 0) as $r | (.attachments // [])[]
  | [ ($t.id | tostring), $g, ($r | tostring), (if (.name | type) == "string" and .name != "" then .name else "attachment" end),
      (if (.contentType | type) == "string" and .contentType != "" then .contentType else "-" end),
      (if (.path | type) == "string" and .path != "" then .path else "-" end),
      (if (.body | type) == "string" then "B:" + .body else "-" end) ] | @tsv' <<<"$tests_json")

ext_for() {
  local ct=$1 src=$2 e
  if [ "$src" != "-" ]; then
    e=${src##*/}
    case "$e" in *.*) printf '%s' ".${e##*.}"; return ;; esac
  fi
  case "$ct" in
    text/plain) printf '.txt' ;;
    application/json) printf '.json' ;;
    text/html) printf '.html' ;;
    image/png) printf '.png' ;;
    image/jpeg) printf '.jpg' ;;
    video/webm) printf '.webm' ;;
    application/zip) printf '.zip' ;;
    *) printf '.bin' ;;
  esac
}
decode() { # base64 text on stdin -> bytes on stdout
  if command -v base64 >/dev/null 2>&1; then
    base64 -d 2>/dev/null || base64 -D
  else
    jq -Rrj '@base64d'
  fi
}

filed=$(mktemp "${TMPDIR:-/tmp}/evidence-capture.XXXXXX")
trap 'rm -f "$filed"; exit 0' EXIT
count=0
if [ -n "$items" ]; then
  while IFS=$'\t' read -r tid group retry name ct src body; do
    [ -n "$tid" ] || continue
    group=$(printf '%s' "$group" | tr -c 'A-Za-z0-9._-' '_')
    base=$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_')
    [ "$retry" = 0 ] || base="$base-retry$retry"
    ext=$(ext_for "$ct" "$src")
    mkdir -p "$dest/$group"
    out=$dest/$group/$base$ext k=2
    while [ -e "$out" ]; do out=$dest/$group/$base-$k$ext; k=$((k + 1)); done
    if [ "$src" != "-" ]; then
      case "$src" in /*) ;; *) src=$run_dir/$src ;; esac
      [ -f "$src" ] || continue
      cp "$src" "$out" || continue
    elif [ "$body" != "-" ]; then
      printf '%s' "${body#B:}" | decode >"$out" 2>/dev/null || { rm -f "$out"; continue; }
    else
      continue
    fi
    count=$((count + 1))
    jq -cn --argjson id "$tid" --arg f "${out#"$dest"/}" '{id: $id, file: $f}' >>"$filed"
  done <<<"$items"
fi

jq -n --arg run_id "$run_id" --arg cmd "$cmd" --arg cwd "$run_dir" --arg spec "$spec_rel" --arg sha "$sha" \
  --arg captured "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg report_src "$report" --argjson fault "$fault" \
  --argjson tests "$tests_json" --slurpfile files "$filed" --slurpfile rep "$dest/e2e-results.json" '
  ($files | group_by(.id) | map({key: (.[0].id | tostring), value: map(.file)}) | from_entries) as $byid
  | { run_id: $run_id, captured_at: $captured, command: $cmd, cwd: $cwd, head: $sha, spec_dir: $spec,
      fault_injected: $fault, report: "e2e-results.json", report_source: $report_src,
      stats: ($rep[0].stats // {}),
      tests: [ $tests[] | { title, file, line, project, tags, journeys, outcome, status,
                            retries: (.results | length), files: ($byid[(.id | tostring)] // []) } ] }' \
  >"$dest/evidence-index.json"

n_tests=$(jq 'length' <<<"$tests_json")
n_fail=$(jq '[.[] | select(.status != "passed" and .status != "skipped")] | length' <<<"$tests_json")
n_jrn=$(jq '[.[] | .journeys[]] | unique | length' <<<"$tests_json")
msg="evidence-capture: filed $count files for $n_tests tests ($n_fail failing, $n_jrn journeys) under $spec_rel/artifacts/$dest_name/ (index: evidence-index.json)."
[ "$fault" = false ] || msg="$msg Run was fault-injected (E2E_INJECT_FAULT=1)."
jq -cn --arg m "$msg" --arg e "$event" '{hookSpecificOutput: {hookEventName: $e, additionalContext: $m}}'
exit 0
