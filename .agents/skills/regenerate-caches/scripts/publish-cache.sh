#!/usr/bin/env bash
# File: Helper script (not a hook): stamp a regenerated Tier B cache and publish it into .workflow/cache/.
# Purpose: The cache-regeneration agent writes the body to the staging path; this script writes the stamp frontmatter (assets/cache-frontmatter.md), validates it, and atomically moves the file into .workflow/cache/<type>.md (D17).
# Plan refs: 0.2.8, `regen` node, Tier B; assetlist D17, D36, D38.
# Called by: regenerate-caches skill and feature-workflow modules/discovery.md after a 0.2.8 cache-regeneration launch returns.
# Sources: first-party.
#
# Staging path (fixed here): <main checkout root>/.workflow/.cache-staging/<type>.md, outside .workflow/cache/ and gitignored
# (install.sh adds `.workflow/.cache-staging/` to .gitignore). The agent writes there with Write/Edit.
#
# Usage:
#   .agents/skills/regenerate-caches/scripts/publish-cache.sh <staged-file> <modules|flows|architecture> <scope-path>... [--generator NAME] [--root DIR]
#     staged-file   must live under <root>/.workflow/.cache-staging/; any frontmatter it has is discarded
#     scope-path    repo-relative file or directory, no globs, at least one
#     --generator   default: cache-regeneration
#     --root        override. Default (D18): the MAIN checkout, found through
#                   `git rev-parse --git-common-dir`, even when run from a worktree. The stamp is
#                   that checkout's HEAD; .workflow/cache/ and .workflow/.cache-staging/ are that checkout's too.
#                   Pass the staged file as an absolute path when running from a worktree.
# Stamp written: generated_at_commit = full HEAD SHA, generated_at = quoted UTC ISO 8601,
#   scope, cache_type, generator. The result is validated with the yq expression from
#   assets/cache-frontmatter.md before the move; on any failure nothing in .workflow/cache/ changes.
# Output: prints the published path. Exit 0 = published; 1 = staged file missing, empty or outside
#   the staging dir, or the stamped result fails validation; 2 = usage or tooling error.
#
# SANDBOX (D36): the deny rule Edit(.workflow/cache/**) does not see this script's move. A project that
# enables the Claude Code sandbox merges that rule into OS-level write denies and would block the
# move. Such a project must add this exact command line to `sandbox.excludedCommands`, and the
# skills must always call the script with exactly this prefix:
#   .agents/skills/regenerate-caches/scripts/publish-cache.sh
# Runs through Bash, never Write/Edit, so tier-b-write-guard does not apply to it.
# Requires: git, jq, mikefarah yq v4 on PATH (D38).
set -euo pipefail

# Workflow paths (D81).
# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

resolve_root() { # main checkout (D18): the parent of the common git dir, so worktrees share one root
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  if [[ "$(basename "$common")" == ".git" ]]; then dirname "$common"; else git rev-parse --show-toplevel; fi
}

die() { echo "publish-cache: $1" >&2; exit "${2:-2}"; }

generator="cache-regeneration"
root=""
pos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --generator) [[ $# -ge 2 ]] || die "--generator needs a value"; generator="$2"; shift 2 ;;
    --root) [[ $# -ge 2 ]] || die "--root needs a value"; root="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) pos+=("$1"); shift ;;
  esac
done

[[ ${#pos[@]} -ge 3 ]] || die "usage: publish-cache.sh <staged-file> <modules|flows|architecture> <scope-path>... [--generator NAME]"
staged="${pos[0]}"
type="${pos[1]}"
scope=("${pos[@]:2}")

for tool in git jq yq; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found on PATH"
done
yq --version 2>&1 | grep -q 'mikefarah' || die "yq must be mikefarah yq v4 (D38)"

case "$type" in modules|flows|architecture) ;; *) die "cache type must be modules, flows or architecture" ;; esac
[[ -n "$generator" ]] || die "--generator must not be empty"
for p in "${scope[@]}"; do
  [[ -n "$p" && "$p" != /* && "$p" != *..* && "$p" != *[\*\?\[]* ]] \
    || die "scope path must be repo-relative with no '..' and no globs: $p"
done

[[ -n "$root" ]] || root="$(resolve_root)" || die "not in a git repository (use --root)"
root="$(cd "$root" && pwd -P)"

[[ -f "$staged" ]] || die "staged file missing: $staged" 1
staged_abs="$(cd "$(dirname "$staged")" && pwd -P)/$(basename "$staged")"
[[ "$staged_abs" == "$root/$WF_CACHE_STAGING/"* ]] || die "staged file must be under $root/$WF_CACHE_STAGING/" 1

head_sha="$(git -C "$root" rev-parse HEAD)"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

dest_dir="$root/$WF_CACHE"
mkdir -p "$dest_dir"
tmp="$(mktemp "$dest_dir/.$type.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

scope_yaml="$(printf '%s\n' "${scope[@]}" | jq -R '"  - " + tojson' -r)"
{
  printf -- '---\n'
  printf 'generated_at_commit: %s\n' "$head_sha"
  printf 'generated_at: "%s"\n' "$now"
  printf 'scope:\n%s\n' "$scope_yaml"
  printf 'cache_type: %s\n' "$type"
  printf 'generator: %s\n' "$(jq -n --arg g "$generator" '$g' )"
  printf -- '---\n'
  # body: staged file without any frontmatter it already carries
  awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm {print}' "$staged_abs"
} >"$tmp"

body_chars="$(awk 'NR>1 && /^---$/ && !done {done=1; next} done' "$tmp" | tr -d '[:space:]' | wc -c)"
[[ "$body_chars" -gt 0 ]] || die "staged file has an empty body" 1

if ! yq --front-matter=extract -e '
  (.generated_at_commit | test("^[0-9a-f]{40}$")) and
  (.generated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")) and
  ((.scope | tag) == "!!seq") and ((.scope | length) > 0) and
  (.cache_type | test("^(modules|flows|architecture)$")) and
  ((.generator | tag) == "!!str")' "$tmp" >/dev/null 2>&1; then
  die "stamped file fails the cache-frontmatter schema" 1
fi

chmod 644 "$tmp"
mv -f "$tmp" "$dest_dir/$type.md"
trap - EXIT
rm -f "$staged_abs"
echo "$WF_CACHE/$type.md"
