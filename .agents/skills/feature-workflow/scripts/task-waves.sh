#!/usr/bin/env bash
# File: Helper script (not a hook): derive the implementation waves of one spec from tasks.md, with predicted-file overlaps (2.5, D85).
# Purpose: Read the tasks.md frontmatter `tasks:` array, find every pair of tasks whose `predicted_files` overlap, turn each overlap into an
#   implied depends_on edge (later id depends on earlier id) unless the pair is already ordered by depends_on or both tasks list each other
#   in `parallel_with`, reject cycles and unknown ids, and print the waves, the overlap table and the 2.1 quiz table. Read-only: it never
#   writes tasks.md; the caller copies the implied edges into depends_on (2.5 is the only step that may write tasks.md).
# Usage:
#   task-waves.sh --spec-dir .workflow/specs/NNN-slug [--cwd <dir>] [--json]
#   task-waves.sh --tasks-file <path to tasks.md> [--json]
#     --spec-dir    `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it); tasks.md is read from the
#                   MAIN checkout, found with `git rev-parse --git-common-dir` from --cwd (default $PWD) (D18).
#     --tasks-file  read this file instead (no git needed); for drafts and tests.
#     --json        print one JSON object instead of the text report (shape below).
# Overlap rule (patterns compared after dropping a leading "./"; a pattern ending in "/" means "<dir>/**"). Two patterns overlap when some
#   path could match both; the reported rule is
#   identical       the two patterns are the same string.
#   glob-match      one is a literal path, the other a glob that matches it.
#   glob-intersect  both are globs and they can match a common path.
#   Matching is segment by segment on "/": a `**` segment matches zero or more segments (`a/**/b` also matches `a/b`); inside a segment
#   `*` matches any run, `?` one character, `[...]` a class (a `**` inside a longer segment acts as `*`). Two wildcard segments are judged
#   by their literal head (text before the first wildcard) and tail (text after the last): they intersect when one head is a prefix of
#   the other and one tail is a suffix of the other, so `*.ts` / `*.css` do not intersect, `src-*` / `*-api` do. The check is exact for
#   literal-vs-glob; for glob-vs-glob it can over-report (e.g. `[ab].ts` / `[cd].ts`), never under-report.
#   So `src/lib/` and `src/lib/**/*.ts` overlap, `src/lib/**` and `src/*.css` do not.
#   Limits: two different literal paths never overlap (a literal is a file; write a directory as `dir/` or `dir/**`); paths are compared
#   case-sensitively and without touching the file system (no symlink or rename detection); brace expansion `{a,b}` and negation `!` are
#   not supported (written literally, they compare as plain characters).
# Graph:
#   - Records with status split-out are left out (their work left the spec, D68); a depends_on naming one is dropped with a warning.
#   - Overlapping pair (A, B), A before B in id order:
#       ordered        A and B are already ordered through depends_on (either direction, transitively): no new edge.
#       parallel_with  both list each other in parallel_with: no edge; they may share a wave and are merged in id order at 3.16.
#                      Listed by only one side: warning, and the edge is still added.
#       implied        otherwise B gets an implied depends_on A. Pairs are processed in id order, so later pairs see earlier implied edges.
#   - Waves: depends_on [] -> wave 1; otherwise 1 + the highest wave among its dependencies (declared plus implied edges).
# Text output: "Wave N: T1, T3" lines, a Mermaid graph (implied edges dashed), the overlap table and the 2.1 quiz table
#   (Wave | Task | Size | Mode | Overlaps), then warnings.
# JSON output: {waves: [{wave, tasks: [ids]}], tasks: [{id, wave, points, mode, depends_on, implied_depends_on, overlaps: [ids]}],
#   overlaps: [{a, b, matches: [{a_pattern, b_pattern, rule}], resolution: "implied"|"ordered"|"parallel_with"}],
#   implied_edges: [{task, depends_on}], warnings: [..]}
# Exit codes: 0 waves derived; 2 invalid graph (cycle, unknown id in depends_on or parallel_with, duplicate id; reason on stderr);
#   1 usage or environment error (missing jq/yq, not a git repo, missing or unreadable tasks.md).
# Called by: modules/task-breakdown.md (2.5: derive waves and implied edges; 2.1 quiz table) and implementation-orchestrator (wave start).
# Plan refs: 2.1, 2.5, 3.3, 3.16; assetlist D14, D18, D38, D68, D85.
# Notes: Requires jq and mikefarah yq v4 (D38). bash 3.2 compatible. Replaces the inline jq wave snippet formerly in task-breakdown.md.
# Sources: first-party; wave computation (longest path over depends_on) adapted from open-gsd/gsd-core agents/gsd-planner.md "assign_waves"
#   (MIT; idea only) as already used in task-breakdown.md; overlap-implies-ordering from mattpocock/skills implement-spec@49dd158 (MIT; idea only).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=task-waves.sh
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-1}"; }
usage() {
  echo "usage: task-waves.sh --spec-dir $WF_SPECS/NNN-slug [--cwd <dir>] [--json] | --tasks-file <tasks.md> [--json]" >&2
  exit 1
}

main_root() {
  local common
  common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "not inside a git repository: $1"
  if [[ "$(basename "$common")" == ".git" ]]; then dirname "$common"
  else git -C "$1" worktree list --porcelain | sed -n '1s/^worktree //p'; fi
}

norm_spec_dir() {
  local d=${1%/}
  d=${d#./}
  if [[ "$d" == /* ]]; then
    [[ "$(dirname "$d")" == */"$WF_SPECS" ]] || die "spec dir must be $WF_SPECS/NNN-slug: $1"
    d="$WF_SPECS/$(basename "$d")"
  fi
  [[ "$d" == "$WF_SPECS"/* && "${d#"$WF_SPECS"/}" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "spec dir must be $WF_SPECS/NNN-slug: $1"
  printf '%s\n' "$d"
}

SPEC_ARG="" TASKS_FILE="" OPT_CWD=$PWD JSON=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-dir)   [[ $# -ge 2 ]] || usage; SPEC_ARG=$2; shift 2 ;;
    --tasks-file) [[ $# -ge 2 ]] || usage; TASKS_FILE=$2; shift 2 ;;
    --cwd)        [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    --json)       JSON=1; shift ;;
    -h|--help)    usage ;;
    *)            die "unknown argument: $1" ;;
  esac
done
[[ -n "$SPEC_ARG" || -n "$TASKS_FILE" ]] || usage
[[ -z "$SPEC_ARG" || -z "$TASKS_FILE" ]] || die "pass --spec-dir or --tasks-file, not both"
command -v jq >/dev/null 2>&1 || die "jq not found on PATH"
command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (D38)"
yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (D38)"

if [[ -n "$SPEC_ARG" ]]; then
  [[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
  ROOT=$(main_root "$OPT_CWD")
  TASKS_FILE="$ROOT/$(norm_spec_dir "$SPEC_ARG")/tasks.md"
fi
[[ -f "$TASKS_FILE" ]] || die "tasks.md not found: $TASKS_FILE"
TASKS_JSON=$(yq --front-matter=extract -o=json -I0 '.tasks' "$TASKS_FILE" 2>/dev/null) || die "cannot read the frontmatter of $TASKS_FILE"
[[ "$(jq -r 'type' <<<"$TASKS_JSON")" == "array" ]] || die "tasks.md has no tasks: array in its frontmatter: $TASKS_FILE"

# shellcheck disable=SC2016 # jq program, not shell expansions
PROGRAM='
def isglob: test("[*?\\[]");
def norm: sub("^\\./"; "") | if endswith("/") then . + "**" else . end;
def g2re:
  gsub("(?<c>[.+^$(){}|\\\\])"; "\\\(.c)")
  | gsub("\\*+"; "[^/]*") | gsub("\\?"; "[^/]")
  | "^" + . + "$";
def head: (match("[*?\\[]") | .offset) as $o | .[:$o];
def tail: explode | reverse | implode | (match("[*?\\]]") | .offset) as $o | .[:$o] | explode | reverse | implode;
def segx($a; $b):
  if $a == $b then true
  elif ($a | isglob | not) then ($a | test($b | g2re))
  elif ($b | isglob | not) then ($b | test($a | g2re))
  else ($a | head) as $ha | ($b | head) as $hb | ($a | tail) as $ta | ($b | tail) as $tb
    | (($ha | startswith($hb)) or ($hb | startswith($ha))) and (($ta | endswith($tb)) or ($tb | endswith($ta)))
  end;
def inter($a; $b):
  if ($a | length) == 0 and ($b | length) == 0 then true
  elif ($a | length) > 0 and $a[0] == "**" then inter($a[1:]; $b) or (($b | length) > 0 and inter($a; $b[1:]))
  elif ($b | length) > 0 and $b[0] == "**" then inter($a; $b[1:]) or (($a | length) > 0 and inter($a[1:]; $b))
  elif ($a | length) == 0 or ($b | length) == 0 then false
  else segx($a[0]; $b[0]) and inter($a[1:]; $b[1:])
  end;
def rule($a; $b):
  if $a == $b then "identical"
  elif ($a | isglob | not) and ($b | isglob | not) then null
  elif inter($a | split("/"); $b | split("/")) | not then null
  elif ($a | isglob) and ($b | isglob) then "glob-intersect"
  else "glob-match" end;
def num: .[1:] | tonumber;
# closure: id -> all transitive dependencies
def closure($d):
  reduce range($d | length) as $_ ($d;
    . as $c | with_entries(.value = ((.value + [.value[] | $c[.] // [] | .[]]) | unique)));

. as $all
| ($all | map(select(.status == "split-out") | .id)) as $gone
| ($all | map(select(.status != "split-out")) | sort_by(.id | num)) as $ts
| [$ts[].id] as $ids
| (if ($all | map(.id) | unique | length) != ($all | length) then error("duplicate task id in tasks.md") else . end)
| [ $ts[] | .id as $me | (.depends_on // [])[] | select(. as $x | $ids | index($x) | not) | select(. as $x | $gone | index($x) | not)
    | "task \($me): depends_on names unknown id \(.)" ] as $unknown_dep
| [ $ts[] | .id as $me | (.parallel_with // [])[] | select(. as $x | ($ids + $gone) | index($x) | not)
    | "task \($me): parallel_with names unknown id \(.)" ] as $unknown_pw
| (if ($unknown_dep + $unknown_pw | length) > 0 then error(($unknown_dep + $unknown_pw) | join("; ")) else . end)
| [ $ts[] | .id as $me | (.depends_on // [])[] | select(. as $x | $gone | index($x)) | "task \($me): depends_on \(.) dropped (split-out)" ] as $w_gone
| [ $ts[] | select(.predicted_files == null) | "task \(.id): no predicted_files; its overlaps are unknown" ] as $w_pf
| ($ts | map({key: .id, value: [(.depends_on // [])[] | select(. as $x | $ids | index($x))]}) | from_entries) as $decl
| (closure($decl)) as $c0
| (if [$ids[] | . as $x | $c0[$x] | index($x)] | any then error("cycle among depends_on: " + ([$ids[] | . as $x | select($c0[$x] | index($x))] | join(", "))) else . end)
| ($ts | map({key: .id, value: [(.predicted_files // [])[] | select(type == "string" and . != "") | norm]}) | from_entries) as $pf
| ($ts | map({key: .id, value: (.parallel_with // [])}) | from_entries) as $pw
| [ range(0; $ids | length) as $i | range($i + 1; $ids | length) as $j | [$ids[$i], $ids[$j]] ] as $pairs
| [ $pairs[] | .[0] as $a | .[1] as $b
    | [ $pf[$a][] as $pa | $pf[$b][] as $pb | rule($pa; $pb) as $r | select($r != null) | {a_pattern: $pa, b_pattern: $pb, rule: $r} ] as $m
    | select($m | length > 0) | {a: $a, b: $b, matches: $m} ] as $ov
| (reduce $ov[] as $o ({deps: $decl, res: [], implied: [], warn: []};
    closure(.deps) as $c
    | (($pw[$o.a] | index($o.b)) != null) as $ab | (($pw[$o.b] | index($o.a)) != null) as $ba
    | if ($c[$o.b] | index($o.a)) != null or ($c[$o.a] | index($o.b)) != null then .res += [$o + {resolution: "ordered"}]
      elif $ab and $ba then .res += [$o + {resolution: "parallel_with"}]
      else
        (if $ab or $ba then .warn += ["\($o.a) and \($o.b) overlap but only \(if $ab then $o.a else $o.b end) lists the other in parallel_with; both must, so \($o.b) depends on \($o.a)"] else . end)
        | .deps[$o.b] += [$o.a] | .implied += [{task: $o.b, depends_on: $o.a}] | .res += [$o + {resolution: "implied"}]
      end)) as $st
| $st.deps as $deps
| (reduce range($ids | length) as $_ ({}; . as $w
    | reduce ($deps | to_entries[]) as $e ($w;
        if ([$e.value[] | $w[.]] | all(. != null)) then .[$e.key] = (([$e.value[] | $w[.]] | max // 0) + 1) else . end))) as $wave
| (if ($wave | length) < ($ids | length) then error("cycle or unknown id among: " + (($ids - ($wave | keys)) | join(", "))) else . end)
| {
    waves: ([$ids[] | {id: ., wave: $wave[.]}] | group_by(.wave) | map({wave: .[0].wave, tasks: map(.id)})),
    tasks: [ $ts[] | .id as $id | {
      id: $id, wave: $wave[$id], points: (.size.points // null), mode: (.mode // null),
      depends_on: $decl[$id],
      implied_depends_on: [$st.implied[] | select(.task == $id) | .depends_on],
      overlaps: ([$st.res[] | select(.a == $id or .b == $id) | if .a == $id then .b else .a end] | unique | sort_by(num)) } ],
    overlaps: $st.res,
    implied_edges: $st.implied,
    warnings: ($w_gone + $w_pf + $st.warn)
  }'

ERR=$(mktemp "${TMPDIR:-/tmp}/task-waves.XXXXXX")
trap 'rm -f "$ERR"' EXIT
if ! RESULT=$(jq -c "$PROGRAM" <<<"$TASKS_JSON" 2>"$ERR"); then
  msg=$(sed -e 's/^jq: error (at <stdin>:[0-9]*): //' -e 's/^jq: error: //' "$ERR" | head -3 | tr '\n' ' ')
  case "$msg" in
    *cycle*|*unknown\ id*|*duplicate*) die "invalid task graph in $TASKS_FILE: $msg" 2 ;;
    *) die "cannot evaluate $TASKS_FILE: $msg" ;;
  esac
fi

jq -r '.warnings[]' <<<"$RESULT" | while IFS= read -r w; do printf '%s: warning: %s\n' "$PROG" "$w" >&2; done

if [[ $JSON -eq 1 ]]; then
  printf '%s\n' "$RESULT"
  exit 0
fi

jq -r '
  "## Waves", "",
  (.waves[] | "- Wave \(.wave): \(.tasks | join(", "))"), "",
  "```mermaid", "graph LR",
  (.tasks[] | .id as $id | (.depends_on[] | "  \(.) --> \($id)"), (.implied_depends_on[] | "  \(.) -.->|overlap| \($id)")),
  ([.tasks[] | .depends_on[], .implied_depends_on[]] as $src | .tasks[] | .id as $id | select((.depends_on | length) == 0 and (.implied_depends_on | length) == 0 and (($src | index($id)) == null)) | "  \($id)"),
  "```", "",
  "## Overlaps", "",
  (if (.overlaps | length) == 0 then "None." else
    ("| Tasks | Shared predicted files | Rule | Resolution |", "| --- | --- | --- | --- |",
     (.overlaps[] | "| \(.a), \(.b) | \([.matches[] | if .a_pattern == .b_pattern then "`\(.a_pattern)`" else "`\(.a_pattern)` ~ `\(.b_pattern)`" end] | join(", ")) | \([.matches[].rule] | unique | join(", ")) | \(
        if .resolution == "implied" then "implied: \(.b) depends_on \(.a)"
        elif .resolution == "parallel_with" then "parallel_with (approved; same wave allowed, merged in id order)"
        else "already ordered by depends_on" end) |"))
   end), "",
  "## Tasks by wave", "",
  "| Wave | Task | Size | Mode | Overlaps |", "| --- | --- | --- | --- | --- |",
  (.tasks | sort_by(.wave, (.id[1:] | tonumber))[] | "| \(.wave) | \(.id) | \(.points // "?") | \(.mode // "?") | \(if (.overlaps | length) == 0 then "none" else (.overlaps | join(", ")) end) |"),
  (if (.warnings | length) > 0 then ("", "## Warnings", "", (.warnings[] | "- \(.)")) else empty end)
' <<<"$RESULT"
