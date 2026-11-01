#!/usr/bin/env bash
# Suite: lint over the affected-area command of feature-workflow discovery 0.2.1 (modules/discovery.md).
# Covers: JRN-009. The fenced bash block under the bold 0.2.1 label (before the next step) is found; run from a scratch
#   project holding a copy of this repo's rules.md, it exits 0 and prints one line per module of the Ownership block,
#   each naming the module and all its owns paths (as globs, or with the trailing /** or * dropped) and nothing else: no
#   may_depend_on, no Shared core path, no other module's path. The oracle reads the Ownership yaml block itself.
#   Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

DISCOVERY=$FW_SKILL/modules/discovery.md
RULES=$REPO_ROOT/.workflow/rules.md

# step_command FILE LABEL : the first fenced bash block after the bold LABEL, unless another numbered step or a heading
#   comes first; the block's own indent is removed.
step_command() {
  awk -v label="$2" '
    !armed && index($0, label) { armed = 1; next }
    armed && !infence && (/^#+ / || /^[[:space:]]*[0-9]+\. \*\*/) { exit }
    armed && !infence && /^[[:space:]]*```bash[[:space:]]*$/ { infence = 1; match($0, /^[[:space:]]*/); indent = RLENGTH; next }
    infence && /^[[:space:]]*```[[:space:]]*$/ { exit }
    infence { print substr($0, indent + 1) }
  ' "$1"
}

# ownership_oracle : "<module>\t<owns glob> ..." for each module of the Ownership yaml block in RULES.
ownership_oracle() {
  awk '/^## / { on = ($0 == "## Ownership") } on && /^```yaml/ { inblock = 1; next } inblock && /^```/ { exit } inblock' "$RULES" \
    | yq '.modules | to_entries | .[] | .key + "	" + (.value.owns | join(" "))'
}

# strip_glob PATH : PATH with a trailing /** or * dropped, as the affected area names it.
strip_glob() { local p=${1%/\*\*}; printf '%s' "${p%\*}"; }

echo "== the oracle"
ownership_oracle >"$WORK/oracle.tsv"
check "the Ownership block lists modules with owns paths" '[ "$(grep -c . "$WORK/oracle.tsv")" -gt 5 ]' "$(cat "$WORK/oracle.tsv")"

echo "== the 0.2.1 command"
COMMAND=$(step_command "$DISCOVERY" '**0.2.1')
check "discovery 0.2.1 holds a fenced bash command" '[ -n "$COMMAND" ]' "no bash block under the 0.2.1 label before the next step"
if [ -n "$COMMAND" ]; then
  # The owns globs are compared as text, so the shell must not expand them against the files of the current folder.
  set -f
  PROJECT=$WORK/project
  git_init_repo "$PROJECT"
  mkdir -p "$PROJECT/.workflow"
  cp "$RULES" "$PROJECT/.workflow/rules.md"
  area=$(cd "$PROJECT" && bash -c "$COMMAND" 2>"$WORK/stderr")
  rc=$?
  eq "the command exits 0 on this repo's rules.md" "$rc" 0
  eq "one line per module" "$(grep -c . <<<"$area")" "$(grep -c . "$WORK/oracle.tsv")"

  wrong=""
  seen=" "
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    words=$(printf "%s\n" "$line" | sed "s/[][\",:]/ /g" | tr -s " " "\n" | sed "/^-$/d; /^$/d")
    module=$(head -n 1 <<<"$words")
    owns=$(awk -F'\t' -v m="$module" '$1 == m { print $2 }' "$WORK/oracle.tsv")
    if [ -z "$owns" ]; then
      wrong="$wrong [not a module: $line]"
      continue
    fi
    case "$seen" in *" $module "*) wrong="$wrong [twice: $module]" ;; esac
    seen="$seen$module "
    for glob in $owns; do
      grep -qxF -- "$glob" <<<"$words" || grep -qxF -- "$(strip_glob "$glob")" <<<"$words" || wrong="$wrong [$module lacks $glob]"
    done
    while IFS= read -r word; do
      [ "$word" = owns ] && continue
      matched=""
      for glob in $owns; do
        [ "$word" = "$glob" ] || [ "$word" = "$(strip_glob "$glob")" ] && matched=1
      done
      [ -n "$matched" ] || wrong="$wrong [$module line also names $word]"
    done < <(tail -n +2 <<<"$words")
  done <<<"$area"
  eq "each line is one module with exactly its owns paths" "$wrong" ""
  set +f
fi

shellcheck_files "shellcheck: affected-area suite" "$TESTS_DIR/lint/affected-area.sh"
finish
