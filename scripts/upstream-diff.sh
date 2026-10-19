#!/usr/bin/env bash
# File: Upstream diff for upstream-lineage.json (scaffold-only; never installed, D30).
# Purpose: for each lineage entry, show what changed upstream since the commit we based our file on, so each change can
#   be accepted or rejected by hand (procedure in upstream-lineage.json "_about").
# Usage:
#   scripts/upstream-diff.sh [--repo OWNER/REPO]... [--path PREFIX] [--ref REF] [--lineage FILE] [--cache DIR]
#                            [--summary-only] [--dry-run]
#   --repo OWNER/REPO  only entries for this upstream (repeatable; default: all)
#   --path PREFIX      only entries whose `path` starts with PREFIX (e.g. .agents/agents/)
#   --ref REF          upstream ref to compare against (default: the upstream default branch HEAD)
#   --lineage FILE     lineage file (default: upstream-lineage.json at the repo root)
#   --cache DIR        keep clones in DIR and fetch on later runs (default: a temp dir removed on exit)
#   --summary-only     print only the summary, not the diffs
#   --dry-run          print the selected entries and what would be compared; no network, no clones
# Output: per entry a "=== <path> <- <repo>:<upstream_path> (<commit>..<ref>)" header and its `git diff`, then a
#   summary with one line per entry: changed | unchanged | skipped (reason). Entries whose upstream_commit is
#   "unknown" are skipped with a warning on stderr.
# Exit: 0 done (changed entries are not an error); 2 usage or input error; 3 an upstream could not be cloned or fetched,
#   or a commit or ref is missing upstream (the summary still prints).
# Read-only to this repo: clones go to a temp dir or --cache. Clone URL comes from .upstreams[repo].url
#   (default https://github.com/<repo>).
# Requires: bash 3.2+, git, jq. Tests: tests/scripts/upstream-diff.sh (offline parts only).

set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lineage=$ROOT/upstream-lineage.json
repos_json='[]'
prefix=""
ref=""
cache=""
summary_only=0
dry_run=0

die() { echo "upstream-diff: $*" >&2; exit 2; }
usage() { sed -n '/^# Usage:/,/^# Output:/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      [ $# -ge 2 ] && [ -n "$2" ] || die "--repo needs OWNER/REPO"
      case "$2" in */*) ;; *) die "--repo must be OWNER/REPO, got '$2'" ;; esac
      repos_json=$(jq -c --arg r "$2" '. + [$r]' <<<"$repos_json")
      shift
      ;;
    --path) [ $# -ge 2 ] && [ -n "$2" ] || die "--path needs a prefix"; prefix=$2; shift ;;
    --ref) [ $# -ge 2 ] && [ -n "$2" ] || die "--ref needs a ref"; ref=$2; shift ;;
    --lineage) [ $# -ge 2 ] && [ -n "$2" ] || die "--lineage needs a file"; lineage=$2; shift ;;
    --cache) [ $# -ge 2 ] && [ -n "$2" ] || die "--cache needs a directory"; cache=$2; shift ;;
    --summary-only) summary_only=1 ;;
    --dry-run) dry_run=1 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || die "jq not found on PATH"
command -v git >/dev/null 2>&1 || die "git not found on PATH"
[ -f "$lineage" ] || die "lineage file not found: $lineage"
jq -e '.entries | type == "array"' "$lineage" >/dev/null 2>&1 || die "not a lineage file (no .entries array): $lineage"

# Selected entries as TSV: index, path, repo, upstream_path, upstream_commit, url.
selected=$(jq -r --argjson repos "$repos_json" --arg prefix "$prefix" '
  . as $doc
  | .entries | to_entries[]
  | select(($repos | length) == 0 or (.value.upstream_repo as $r | $repos | index($r)))
  | select(.value.path | startswith($prefix))
  | [.key, .value.path, .value.upstream_repo, .value.upstream_path, .value.upstream_commit,
     ($doc.upstreams[.value.upstream_repo].url // ("https://github.com/" + .value.upstream_repo))]
  | @tsv' "$lineage") || die "could not read entries from $lineage"

# Every --repo must name at least one entry, so a typo is not a silent no-op.
for r in $(jq -r '.[]' <<<"$repos_json"); do
  printf '%s\n' "$selected" | cut -f3 | grep -qxF "$r" || die "no entry for --repo $r"
done
[ -n "$selected" ] || die "no entries selected"

rows=()
status=0
row() { rows+=("$(printf '%-9s %s <- %s:%s%s' "$1" "$2" "$3" "$4" "${5:+ ($5)}")"); }

if [ "$dry_run" -eq 1 ]; then
  while IFS=$'\t' read -r _i path repo upath commit url; do
    if [ "$commit" = "unknown" ]; then
      echo "upstream-diff: warning: $path <- $repo:$upath has upstream_commit unknown; skipped" >&2
      row skipped "$path" "$repo" "$upath" "upstream_commit unknown"
    else
      row would "$path" "$repo" "$upath" "$commit..${ref:-<default branch>} from $url"
    fi
  done <<<"$selected"
  printf '== summary (dry run)\n'
  printf '%s\n' "${rows[@]}"
  exit 0
fi

if [ -n "$cache" ]; then
  mkdir -p "$cache" || die "cannot create cache dir: $cache"
  work=$(cd "$cache" && pwd)
else
  work=$(mktemp -d "${TMPDIR:-/tmp}/upstream-diff.XXXXXX") || die "mktemp failed"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" EXIT
fi

# clone_dir REPO URL : set CLONE to the local clone of REPO, cloning (blobless) or fetching it once per run.
fetched=" "
CLONE=""
clone_dir() {
  CLONE=$work/$(printf '%s' "$1" | tr '/' '_')
  case "$fetched" in *" $1 "*) return 0 ;; esac
  if [ -d "$CLONE/.git" ]; then
    git -C "$CLONE" fetch -q --tags origin >&2 || return 1
    git -C "$CLONE" remote set-head origin --auto >/dev/null 2>&1 || true
  else
    git clone -q --filter=blob:none --no-checkout "$2" "$CLONE" >&2 || return 1
  fi
  fetched="$fetched$1 "
}

while IFS=$'\t' read -r _i path repo upath commit url; do
  if [ "$commit" = "unknown" ]; then
    echo "upstream-diff: warning: $path <- $repo:$upath has upstream_commit unknown; skipped" >&2
    row skipped "$path" "$repo" "$upath" "upstream_commit unknown"
    continue
  fi
  if ! clone_dir "$repo" "$url"; then
    echo "upstream-diff: could not clone or fetch $url" >&2
    row skipped "$path" "$repo" "$upath" "clone failed"
    status=3
    continue
  fi
  d=$CLONE
  to=${ref:-origin/HEAD}
  if ! git -C "$d" rev-parse -q --verify "$commit^{commit}" >/dev/null; then
    row skipped "$path" "$repo" "$upath" "commit $commit not found upstream"
    status=3
    continue
  fi
  if ! to_sha=$(git -C "$d" rev-parse -q --verify "$to^{commit}" 2>/dev/null) &&
    ! to_sha=$(git -C "$d" rev-parse -q --verify "origin/$to^{commit}" 2>/dev/null); then
    row skipped "$path" "$repo" "$upath" "ref $to not found upstream"
    status=3
    continue
  fi
  if git -C "$d" diff --quiet "$commit" "$to_sha" -- "$upath"; then
    row unchanged "$path" "$repo" "$upath" "${commit:0:7}..${to_sha:0:7}"
  else
    row changed "$path" "$repo" "$upath" "${commit:0:7}..${to_sha:0:7}"
    if [ "$summary_only" -eq 0 ]; then
      printf '=== %s <- %s:%s (%s..%s)\n' "$path" "$repo" "$upath" "${commit:0:7}" "${to_sha:0:7}"
      git -C "$d" --no-pager diff "$commit" "$to_sha" -- "$upath"
      printf '\n'
    fi
  fi
done <<<"$selected"

printf '== summary\n'
printf '%s\n' "${rows[@]}"
n_changed=$(printf '%s\n' "${rows[@]}" | grep -c '^changed ' || true)
printf '%s of %s entries changed upstream\n' "$n_changed" "${#rows[@]}"
exit "$status"
