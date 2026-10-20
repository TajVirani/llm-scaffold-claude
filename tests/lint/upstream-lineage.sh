#!/usr/bin/env bash
# Suite: lint of upstream-lineage.json against the repo (reads the repo, writes nothing outside a temp dir).
# Covers: the file parses, `version` is 1, `upstreams` and `entries` have the right shape; every entry has the keys its
#   kind needs (copy: sha256_of_upstream_at_copy; derived and pinned-addon: none), `kind` and `commit_basis` are in their
#   enums, `upstream_commit` is a 40-hex sha or "unknown", `reviewed_at` is a date, `upstream_repo` is a declared upstream,
#   `path` (and a copy's license_path and consumers) exists under .agents/ outside the vendored reference copies, and no
#   (path, upstream_repo, upstream_path) pair repeats; every declared upstream is used.
#   Coverage: a first-party file under .agents/ whose Sources: / Adapted from / Copied from line (plus `#   ` comment
#   continuation lines) names an upstream, by one of its `aliases` or a `vendored_at` path, needs an entry for that
#   upstream whose `path` is the file or a directory containing it. LICENSE and NOTICE files are skipped.
#   No such line names a `.agents/skills/<name>/` directory that does not exist (deleted vendored skills are cited
#   upstream instead).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

L=$REPO_ROOT/upstream-lineage.json
new_workdir

check "upstream-lineage.json exists" '[ -f "$L" ]'
if ! jq -e . "$L" >/dev/null 2>&1; then
  ko "upstream-lineage.json parses as JSON"
  finish
fi
ok "upstream-lineage.json parses as JSON"
eq "version is 1" "$(jq -r '.version' "$L")" "1"
check "entries is a non-empty array" 'jq -e "(.entries | type) == \"array\" and (.entries | length) > 0" "$L" >/dev/null'
check "upstreams is an object" 'jq -e "(.upstreams | type) == \"object\"" "$L" >/dev/null'

# Shape problems, one per line ("<entry or upstream>: <problem>").
problems=$(jq -r '
  def str: type == "string" and length > 0;
  def strs: type == "array" and length > 0 and all(.[]; str);
  (.upstreams | to_entries[] | .key as $k | .value |
    (if (.url | str) then empty else "upstream \($k): url missing" end),
    (if (.license | str) then empty else "upstream \($k): license missing" end),
    (if (.aliases | strs) then empty else "upstream \($k): aliases must be a non-empty string array" end),
    (if has("vendored_at") and ((.vendored_at | strs) | not) then "upstream \($k): vendored_at must be a non-empty string array" else empty end)),
  (.upstreams as $up | .entries | to_entries[] | "entry \(.key) (\(.value.path // "?"))" as $id | .value |
    ((["path","kind","upstream_repo","upstream_path","upstream_commit","commit_basis","changes","why","reviewed_at"] - keys)[]
      | "\($id): missing \(.)"),
    (if has("kind") and ([.kind] | inside(["copy","derived","pinned-addon"]) | not) then "\($id): kind \(.kind) not in copy|derived|pinned-addon" else empty end),
    (if has("commit_basis") and ([.commit_basis] | inside(["pinned","blob-match","release-tag","survey-date"]) | not) then "\($id): commit_basis \(.commit_basis) not in pinned|blob-match|release-tag|survey-date" else empty end),
    (if .kind == "copy" and ((.sha256_of_upstream_at_copy // "") | test("^[0-9a-f]{64}$") | not) then "\($id): copy needs a 64-hex sha256_of_upstream_at_copy" else empty end),
    (if .kind != "copy" and has("sha256_of_upstream_at_copy") then "\($id): sha256_of_upstream_at_copy is for copy entries only" else empty end),
    (if has("upstream_commit") and ((.upstream_commit | type) != "string" or ((.upstream_commit | test("^[0-9a-f]{40}$")) or .upstream_commit == "unknown" | not)) then "\($id): upstream_commit must be a 40-hex sha or \"unknown\"" else empty end),
    (if has("reviewed_at") and ((.reviewed_at | type) != "string" or (.reviewed_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$") | not)) then "\($id): reviewed_at must be YYYY-MM-DD" else empty end),
    (if has("changes") and ((.changes | strs) | not) then "\($id): changes must be a non-empty string array" else empty end),
    (if has("why") and ((.why | str) | not) then "\($id): why must be a non-empty string" else empty end),
    (if has("upstream_path") and ((.upstream_path | str) | not) then "\($id): upstream_path must be a non-empty string" else empty end),
    (if has("upstream_repo") and (.upstream_repo as $r | $up | has($r) | not) then "\($id): upstream_repo \(.upstream_repo) is not in upstreams" else empty end),
    (if has("path") and (.path | startswith(".agents/") | not) then "\($id): path must be under .agents/" else empty end))
' "$L" 2>&1)
eq "every upstream and entry has a valid shape" "$problems" ""

dups=$(jq -r '.entries | group_by([.path, .upstream_repo, .upstream_path])[] | select(length > 1) | .[0] | "\(.path) <- \(.upstream_repo):\(.upstream_path)"' "$L")
eq "no duplicate (path, upstream_repo, upstream_path)" "$dups" ""

unused=$(jq -r '([.entries[].upstream_repo] | unique) as $used | .upstreams | keys[] | select(. as $k | $used | index($k) | not)' "$L")
eq "every declared upstream is used by an entry" "$unused" ""

# Vendored reference copies (excluded from first-party files).
jq -r '.upstreams[].vendored_at // [] | .[]' "$L" | sed 's|/*$||' >"$WORK/vendored"
under_vendored() {
  local v
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    case "$1" in "$v" | "$v"/*) return 0 ;; esac
  done <"$WORK/vendored"
  return 1
}

missing=""
while IFS= read -r p; do
  if [ ! -e "$REPO_ROOT/$p" ]; then
    missing="$missing $p"
  elif under_vendored "$p"; then
    missing="$missing $p(vendored)"
  fi
done < <(jq -r '.entries[] | .path, (.license_path // empty), (.consumers // [] | .[])' "$L" | sort -u)
eq "every entry path, license_path and consumer exists outside the vendored copies" "${missing# }" ""

# ---- coverage of Sources: lines
# First-party files: everything under .agents/ except the vendored reference copies and LICENSE / NOTICE files.
(cd "$REPO_ROOT" && find .agents -type f ! -name LICENSE ! -name 'LICENSE.*' ! -name NOTICE | sort) >"$WORK/all"
: >"$WORK/files"
while IFS= read -r f; do under_vendored "$f" || printf '%s\n' "$f" >>"$WORK/files"; done <"$WORK/all"

# Attribution lines as "<file>\t<text>": the matching line, plus `#   ` continuation lines after a `#` comment match.
: >"$WORK/lines"
while IFS= read -r f; do
  grep -qiE 'sources?:|adapted from|copied from' "$REPO_ROOT/$f" 2>/dev/null || continue
  awk -v f="$f" '
    tolower($0) ~ /sources?:|adapted from|copied from/ { print f "\t" $0; cont = ($0 ~ /^[[:space:]]*#/); next }
    cont && /^#[[:space:]][[:space:]]+[^[:space:]]/ { print f "\t" $0; next }
    { cont = 0 }' "$REPO_ROOT/$f" >>"$WORK/lines"
done <"$WORK/files"

# Needles per upstream: aliases and vendored_at paths (with a trailing slash), as "<repo>\t<needle>".
jq -r '.upstreams | to_entries[] | .key as $k | (.value.aliases[], ((.value.vendored_at // [])[] | sub("/*$"; "/"))) | "\($k)\t\(.)"' "$L" >"$WORK/needles"

: >"$WORK/named"
while IFS=$'\t' read -r repo needle; do
  [ -n "$needle" ] || continue
  grep -F -- "$needle" "$WORK/lines" | cut -f1 | sed "s|\$|	$repo|" >>"$WORK/named"
done <"$WORK/needles"
sort -u "$WORK/named" -o "$WORK/named"

jq -r '.entries[] | "\(.path)\t\(.upstream_repo)"' "$L" | sort -u >"$WORK/covered"
uncovered=""
while IFS=$'\t' read -r f repo; do
  hit=0
  while IFS=$'\t' read -r p r; do
    [ "$r" = "$repo" ] || continue
    case "$f" in "$p" | "${p%/}"/*) hit=1; break ;; esac
  done <"$WORK/covered"
  [ "$hit" -eq 1 ] || uncovered="$uncovered
$f <- $repo"
done <"$WORK/named"
eq "every upstream named in a first-party Sources line has a lineage entry" "${uncovered#
}" ""
check "the coverage scan found attribution lines (sanity)" '[ -s "$WORK/named" ]'

# Deleted vendored skills leave no needle behind, so a Sources line must cite upstream, not a local
# .agents/skills/<name>/ path that no longer exists.
dangling=""
while IFS=$'\t' read -r f d; do
  [ -d "$REPO_ROOT/$d" ] || dangling="$dangling
$f -> $d"
done < <(awk -F'\t' '{ s = $2; while (match(s, /\.agents\/skills\/[A-Za-z0-9_-]+/)) { print $1 "\t" substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } }' "$WORK/lines" | sort -u)
eq "no Sources line points at a missing .agents/skills/<name>/ directory" "${dangling#
}" ""

shellcheck_files "shellcheck tests/lint/upstream-lineage.sh" "$TESTS_DIR/lint/upstream-lineage.sh"
finish
