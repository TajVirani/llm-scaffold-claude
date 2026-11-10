#!/usr/bin/env bash
# Suite: lint that every step id of feature-workflow's references/steps.tsv is held by exactly one step file, and that the
#   router's Route by status section, or a load line in another step file, reaches that file.
# Covers: JRN-003. Intake ids 0.0.1-0.0.2 are held by the router (SKILL.md) and by no step file; every 0.x, 1.x-5.x
#   (4.10 included), 6.x and 00.x id is held by exactly one step file under modules/ and that file is reached; the ids
#   no step text labels (artifacts, hook and script actions) are held by at most one step file. Reads the repo only.
#
#   Step file: each modules/*.md. The router holds intake ids only; any other id it names is a route, not a step.
#   A step file holds an id when, outside fenced code blocks:
#     1. a heading starts with the id or an id range: "## 0.3.20 Light-path test", "## 3.10-3.11 Browser suite ...".
#        A "### 6.1" heading under a "## 6. Exit" heading in the same file is a section number, not a step id;
#     2. a heading names it in parentheses: "### Per-task gates (3.4-3.8)", "## 4. Triage each finding (4.4)". An id
#        after an arrow is where the section goes, not a step it holds: "(4.4 → 00.21)" holds 4.4 only; a 00.x id in
#        parentheses below the title names the cross-cutting protocol the section hands to ("## Discovered work (00.21)"):
#        only the protocol's own file holds it, by its title or its step headings;
#     3. a bold label that opens a line or list item starts with it: "1. **0.1.1 Scan.**", "**0.2.4 / 0.2.5 Launch**",
#        "**00.24 No.**", "No → **0.3.4 Resolve placement**". A label that only mentions an id later ("**Rework entry (4.7).**")
#        holds nothing.
#   A range "a-b" or "a–b" expands over its last number and keeps the ids steps.tsv lists.
#   A file is reached when the router's Route by status section, or any router line that says "load", names
#   modules/<file>.md, or when another step file names it (a link or a modules/<file>.md code span) on a line that says
#   load, run, return or go to.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

ROUTER=$FW_SKILL/SKILL.md
MODULES_DIR=$FW_SKILL/modules
TSV=$FW_SKILL/references/steps.tsv

# Ids the workflow names only as an artifact, a hook or script action or a call target, with no step text of their own:
# the request itself (0.0); the glossary writes the domain-modeling skill makes under the 0.2.2 and 0.4.2 term gates
# (0.2.3, 0.4.3); the verification-plan.md write that closes 0.5 (0.5.4); the side artifacts (0.3.21 design-log.md,
# 3.12 run artifacts); the Tier A files (00.1-00.4); the shelf files (00.8-00.10); and the model and profile
# lookups the launch hooks run (00.11-00.17, 00.19, 00.20). 00.18 keeps its own label in 3.1 and is checked like a step.
UNLABELLED_IDS=" 0.0 0.2.3 0.4.3 0.5.4 0.3.21 3.12 00.1 00.2 00.3 00.4 00.8 00.9 00.10 00.11 00.12 00.13 00.14 00.16 00.17 00.19 00.20 "

# held_ids FILE : the step ids FILE holds, one per line, ranges expanded, by the three rules in the header.
held_ids() {
  LC_ALL=C awk '
    function emit(s,    n, i, items, ends, a, b, pa, pb, da, db, prefix, j) {
      gsub(/–/, "-", s)
      n = split(s, items, /[ ]*[,\/;][ ]*/)
      for (i = 1; i <= n; i++) {
        if (match(items[i], /^[0-9]+(\.[0-9]+)+-[0-9]+(\.[0-9]+)+/)) {
          split(substr(items[i], 1, RLENGTH), ends, "-")
          a = ends[1]; b = ends[2]
          da = split(a, pa, "."); db = split(b, pb, ".")
          prefix = substr(a, 1, length(a) - length(pa[da]))
          if (da == db && substr(b, 1, length(b) - length(pb[db])) == prefix) {
            for (j = pa[da] + 0; j <= pb[db] + 0; j++) print prefix j
          } else { print a; print b }
        } else if (match(items[i], /^[0-9]+(\.[0-9]+)+/)) {
          print substr(items[i], 1, RLENGTH)
        }
      }
    }
    /^[[:space:]]*```/ { fenced = !fenced; next }
    fenced { next }
    /^#+ / {
      match($0, /^#+/); level = RLENGTH
      text = substr($0, RLENGTH + 2)
      if (level == 2 && match(text, /^[0-9]+\. /)) numbered_section[substr(text, 1, RLENGTH - 2)] = 1
      if (match(text, /^[0-9]+(\.[0-9]+)+((-|–)[0-9]+(\.[0-9]+)+)?/)) {
        lead = substr(text, 1, RLENGTH)
        is_section_number = level >= 3 && lead ~ /^[0-9]+\.[0-9]+$/ && (substr(lead, 1, index(lead, ".") - 1) in numbered_section)
        if (!is_section_number) emit(lead)
      }
      rest = text
      while (match(rest, /\([^)]*\)/)) {
        inside = substr(rest, RSTART + 1, RLENGTH - 2)
        rest = substr(rest, RSTART + RLENGTH)
        if (index(inside, "→")) inside = substr(inside, 1, index(inside, "→") - 1)
        gsub(/[A-Za-z][A-Za-z ]*/, "", inside)
        if (level >= 2) gsub(/00\.[0-9]+((-|–)00\.[0-9]+)?/, "", inside)
        emit(inside)
      }
      next
    }
    match($0, /^[[:space:]]*([-*+]|[0-9]+\.)?[[:space:]]*([A-Za-z]+[[:space:]]*→[[:space:]]*)?\*\*[^*]+\*\*/) {
      label = substr($0, 1, RLENGTH)
      sub(/^[^*]*\*\*/, "", label); sub(/\*\*$/, "", label)
      if (match(label, /^[0-9]+(\.[0-9]+)+([ ]*(-|–|\/|,)[ ]*[0-9]+(\.[0-9]+)+)*/)) emit(substr(label, 1, RLENGTH))
    }
  ' "$1" | sort -u
}

# router_intake_ids : the 0.0.x ids the router names in a heading or a bold span.
router_intake_ids() {
  awk '/^[[:space:]]*```/ { fenced = !fenced; next } !fenced' "$ROUTER" \
    | grep -oE '^#+ .*|\*\*[^*]+\*\*' | grep -oE '\b0\.0\.[0-9]+\b' | sort -u
}

# route_section : the router's Route by status section (its heading may carry a number).
route_section() {
  awk '/^## / { if (on) exit; t = $0; sub(/^## ([0-9]+\. )?/, "", t); if (index(t, "Route by status") == 1) { on = 1; next } } on' "$ROUTER"
}

# names_step_file TEXT NAME : true when TEXT names modules/NAME.md, or links NAME.md the way a sibling step file does.
names_step_file() {
  grep -qE "modules/$2\.md|\]\((\./)?$2\.md[#)]" <<<"$1"
}

# reached NAME : true when the router or a load line in another step file reaches modules/NAME.md.
reached() {
  local name=$1 other lines
  names_step_file "$(route_section)" "$name" && return 0
  names_step_file "$(grep -i 'load' "$ROUTER")" "$name" && return 0
  for other in "$MODULES_DIR"/*.md; do
    [ "$(basename "$other" .md)" = "$name" ] && continue
    lines=$(grep -iE '\b(load|loads|loaded|run|return|returns|go to)\b' "$other")
    names_step_file "$lines" "$name" && return 0
  done
  return 1
}

echo "== the step list and the holders"
grep -v '^#' "$TSV" | awk -F'\t' 'NR > 1 && $3 != "phase" { print $1 "\t" $3 }' >"$WORK/steps.tsv"
check "steps.tsv lists the step ids" '[ "$(wc -l <"$WORK/steps.tsv")" -gt 100 ]'
: >"$WORK/held.tsv"
for step_file in "$MODULES_DIR"/*.md; do
  held_ids "$step_file" | sed "s|\$|	$(basename "$step_file" .md)|" >>"$WORK/held.tsv"
done
router_intake_ids | sed 's|$|	SKILL|' >"$WORK/router.tsv"

# holders ID : the step files that hold ID, space-separated, sorted. Ids are compared as strings: awk would compare 3.1 and
#   3.10 as numbers and find them equal.
holders() { awk -F'\t' -v id="$1" '$1 "" == id "" { print $2 }' "$WORK/held.tsv" | sort -u | tr '\n' ' ' | sed 's/ $//'; }
holder_count() { awk -F'\t' -v id="$1" '$1 "" == id ""' "$WORK/held.tsv" | cut -f2 | sort -u | grep -c .; }
# Reach is worked out once per step file: every id a file holds shares it, and the greps are slow per id.
for step_file in "$MODULES_DIR"/*.md; do
  name=$(basename "$step_file" .md)
  reached "$name" && printf '%s\n' "$name"
done >"$WORK/reached.txt"

echo "== intake: the router holds 0.0.1-0.0.2"
for id in 0.0.1 0.0.2; do
  check "the router holds $id" 'grep -q "^$id	" "$WORK/router.tsv"'
  eq "no step file holds $id" "$(holders "$id")" ""
done

# check_group NAME PATTERN : every labelled id matching PATTERN is held by exactly one step file, which is reached.
check_group() {
  local name=$1 pattern=$2 id track count wrong_count="" unreached="" file
  while IFS=$'\t' read -r id track; do
    case "$UNLABELLED_IDS" in *" $id "*) continue ;; esac
    [ "$track" = intake ] && continue
    count=$(holder_count "$id")
    if [ "$count" -ne 1 ]; then
      wrong_count="$wrong_count $id(${count}: $(holders "$id"))"
      continue
    fi
    file=$(holders "$id")
    grep -qxF -- "$file" "$WORK/reached.txt" || unreached="$unreached $id($file)"
  done < <(grep -E "^$pattern	" "$WORK/steps.tsv")
  eq "every $name id is held by exactly one step file" "$wrong_count" ""
  eq "every $name id's step file is reached from the router or a load line" "$unreached" ""
}

check_group "0.x" '0\.[1-9][0-9.]*'
check_group "1.x" '1\.[0-9.]+'
check_group "2.x" '2\.[0-9.]+'
check_group "3.x" '3\.[0-9.]+'
check_group "4.x" '4\.[0-9.]+'
check_group "5.x" '5\.[0-9.]+'
check_group "6.x" '6\.[0-9.]+'
check_group "00.x" '00\.[0-9]+'

echo "== named ids"
eq "4.10 (the combined review) is held by exactly one step file" "$(holder_count 4.10)" 1
eq "0.3.20 (the light-path test) is held by exactly one step file" "$(holder_count 0.3.20)" 1
eq "3.1 (implementation setup) is held by exactly one step file" "$(holder_count 3.1)" 1

echo "== ids no step text labels"
crowded=""
for id in $UNLABELLED_IDS; do
  [ "$(holder_count "$id")" -le 1 ] || crowded="$crowded $id($(holders "$id"))"
done
eq "an unlabelled id is held by at most one step file" "$crowded" ""

shellcheck_files "shellcheck: step-routing suite" "$TESTS_DIR/lint/step-routing.sh"
finish
