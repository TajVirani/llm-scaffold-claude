#!/usr/bin/env bash
# File: Helper script (not a hook): detect stale Tier B caches before retrieval runs.
# Purpose: For each Tier B cache (docs/cache/modules.md, flows.md, architecture.md), read the frontmatter, validate it against assets/cache-frontmatter.md, and decide fresh or stale. A cache is stale when any commit in generated_at_commit..HEAD touched a path under `scope`.
# Triggers/inputs: Called by feature-workflow modules/discovery.md at 0.2.7 before launching `retrieval`, and by regenerate-caches for stale-only runs.
# Plan refs: 0.2.7; reference "Helper scripts" (Cache stamp check); assetlist D7, D38.
# Sources: first-party; changed-since-commit idea from skills/data-structure-audit/scripts/audit_scope.sh.
#
# Usage:
#   cache-stamp-check.sh [--area PATH]... [--cache-dir DIR] [--root DIR]
#     --area PATH      repo-relative path of the affected area (repeatable). Only caches whose
#                      scope intersects an area (one path is the other, or a parent of it) are
#                      checked for staleness. Without --area, every scope path counts.
#     --cache-dir DIR  default: <root>/docs/cache
#     --root DIR       repo root override. Default (D18): the MAIN checkout, found through
#                      `git rev-parse --git-common-dir`, even when run from a worktree. Caches
#                      are read from, and HEAD is taken from, that checkout.
#
# Output (stdout, one JSON object):
#   {"head":"<sha>","stale":<bool>,"stamps":{"modules":"<40-hex>|null","flows":...,"architecture":...},"caches":[{"cache_type":"modules","file":"docs/cache/modules.md",
#     "status":"fresh|stale|missing|invalid","generated_at_commit":"<sha>|null",
#     "stale_paths":["<files changed since the stamp under checked scope>"],"reason":"<text>"}]}
#   stamps is ready for codebase-map.md `cache_stamps`: the cache's generated_at_commit when its
#   frontmatter is valid (fresh or stale), else null (missing or invalid).
#   status: fresh   = valid frontmatter, no commit since the stamp touched the checked scope
#           stale   = at least one such commit (stale_paths lists the changed files)
#           missing = the cache file does not exist (needs regeneration)
#           invalid = frontmatter missing or fails the schema, or the stamp commit is unknown
#
# Exit codes: 0 = all caches fresh; 1 = at least one stale or missing (and none invalid);
#             2 = at least one invalid, or a usage or tooling error (message on stderr).
# Requires: git, jq, mikefarah yq v4 on PATH (D38).
set -euo pipefail

resolve_root() { # main checkout (D18): the parent of the common git dir, so worktrees share one root
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  if [[ "$(basename "$common")" == ".git" ]]; then dirname "$common"; else git rev-parse --show-toplevel; fi
}

die() { echo "cache-stamp-check: $*" >&2; exit 2; }

areas=()
cache_dir=""
root=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --area) [[ $# -ge 2 ]] || die "--area needs a value"; areas+=("${2%/}"); shift 2 ;;
    --cache-dir) [[ $# -ge 2 ]] || die "--cache-dir needs a value"; cache_dir="$2"; shift 2 ;;
    --root) [[ $# -ge 2 ]] || die "--root needs a value"; root="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

for tool in git jq yq; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found on PATH"
done
yq --version 2>&1 | grep -q 'mikefarah' || die "yq must be mikefarah yq v4 (D38)"

[[ -n "$root" ]] || root="$(resolve_root)" || die "not in a git repository (use --root)"
cd "$root"
[[ -n "$cache_dir" ]] || cache_dir="$root/docs/cache"
head_sha="$(git rev-parse HEAD)"

valid_expr='
  (.generated_at_commit | test("^[0-9a-f]{40}$")) and
  (.generated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")) and
  ((.scope | tag) == "!!seq") and ((.scope | length) > 0) and
  (.cache_type | test("^(modules|flows|architecture)$")) and
  ((.generator | tag) == "!!str")'

# intersects SCOPE_PATH: true when it overlaps any --area (or no --area given)
intersects() {
  local s="${1%/}" a
  [[ ${#areas[@]} -gt 0 ]] || return 0
  for a in "${areas[@]}"; do
    [[ "$a" == "." || "$a" == "$s" || "$a" == "$s"/* || "$s" == "$a"/* ]] && return 0
  done
  return 1
}

results=()
any_invalid=0
any_stale=0

emit() { # type status commit stale_paths_json reason
  results+=("$(jq -n --arg t "$1" --arg f "docs/cache/$1.md" --arg s "$2" --arg c "$3" \
    --argjson p "$4" --arg r "$5" \
    '{cache_type:$t,file:$f,status:$s,generated_at_commit:(if $c=="" then null else $c end),stale_paths:$p,reason:$r}')")
  case "$2" in
    invalid) any_invalid=1 ;;
    stale|missing) any_stale=1 ;;
  esac
}

for type in modules flows architecture; do
  file="$cache_dir/$type.md"
  if [[ ! -f "$file" ]]; then
    emit "$type" missing "" '[]' "cache file does not exist"
    continue
  fi
  if ! yq --front-matter=extract -e "$valid_expr" "$file" >/dev/null 2>&1; then
    emit "$type" invalid "" '[]' "frontmatter missing or fails the schema (assets/cache-frontmatter.md)"
    continue
  fi
  if [[ "$(yq --front-matter=extract '.cache_type' "$file")" != "$type" ]]; then
    emit "$type" invalid "" '[]' "cache_type does not match the file name"
    continue
  fi
  sha="$(yq --front-matter=extract '.generated_at_commit' "$file")"
  if ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
    emit "$type" invalid "$sha" '[]' "generated_at_commit is not a commit in this repository"
    continue
  fi
  checked=()
  while IFS= read -r p; do
    if intersects "$p"; then checked+=("$p"); fi
  done < <(yq --front-matter=extract '.scope[]' "$file")
  if [[ ${#checked[@]} -eq 0 ]]; then
    emit "$type" fresh "$sha" '[]' "scope does not intersect the affected area"
    continue
  fi
  changed="$(git log --format= --name-only "${sha}..HEAD" -- "${checked[@]}" | sort -u | sed '/^$/d')"
  if [[ -n "$changed" ]]; then
    emit "$type" stale "$sha" "$(printf '%s\n' "$changed" | jq -R . | jq -s .)" \
      "commits since generated_at_commit touched the scope"
  else
    emit "$type" fresh "$sha" '[]' "no commit since generated_at_commit touched the scope"
  fi
done

stale_bool=false
if [[ $any_stale -eq 1 || $any_invalid -eq 1 ]]; then stale_bool=true; fi
printf '%s\n' "${results[@]}" | jq -s --arg h "$head_sha" --argjson s "$stale_bool" \
  '{head:$h,stale:$s,
     stamps:(reduce .[] as $c ({}; .[$c.cache_type] = (if ($c.status=="fresh" or $c.status=="stale") then $c.generated_at_commit else null end))),
     caches:.}'

if [[ $any_invalid -eq 1 ]]; then exit 2; fi
if [[ $any_stale -eq 1 ]]; then exit 1; fi
exit 0
