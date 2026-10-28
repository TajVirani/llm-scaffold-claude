#!/usr/bin/env bash
# File: Helper script (not a hook): check a staged Tier B cache body against its fixed shape before it is published.
# Purpose: Catch drift in the agent-written parts (modules.md Purpose slots, flows.md sections and diagrams) and any
#   hand-built architecture.md, so only canonical bodies reach publish-cache.sh. When the body holds ```mermaid fences
#   and node can load the mermaid and jsdom packages, it also runs
#   .agents/skills/visual-change-report/scripts/validate_mermaid.mjs on them (wrapped as <pre class="mermaid"> blocks in
#   a temporary HTML file, the only form that validator reads). When node or a package is missing it still prints "ok"
#   but warns on stderr that the diagrams are not machine-validated and names the hand checklist,
#   .agents/skills/visual-change-report/references/visual-library.md "Mermaid syntax rules".
# Called by: the cache-regeneration agent before it returns, and regenerate-caches / discovery 0.2.8 before publishing.
# Steps: 00.5-00.7, 0.2.8.
# Sources: first-party. Shape rules: assets/cache-frontmatter.md "Body shape per cache type".
#
# Usage:
#   check-staged-cache.sh <modules|flows|architecture> <staged-file> [--html-out FILE]
#     --html-out FILE   also write every ```mermaid block as <pre class="mermaid"> (HTML-escaped) into FILE
# Output: "ok" on stdout, or one problem per line on stderr (a validator rejection adds its own output there).
# Exit codes: 0 = body matches the shape; 1 = problems found (listed) or the Mermaid validator rejected a diagram;
#   2 = usage error or file missing.
set -euo pipefail
export LC_ALL=C

die() { echo "check-staged-cache: $*" >&2; exit 2; }

skills_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mermaid_validator="$skills_dir/visual-change-report/scripts/validate_mermaid.mjs"
mermaid_checklist="$skills_dir/visual-change-report/references/visual-library.md"

html_out=""
pos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --html-out) [[ $# -ge 2 ]] || die "--html-out needs a value"; html_out="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) pos+=("$1"); shift ;;
  esac
done
[[ ${#pos[@]} -eq 2 ]] || die "usage: check-staged-cache.sh <modules|flows|architecture> <staged-file> [--html-out FILE]"
type="${pos[0]}"
file="${pos[1]}"
case "$type" in modules|flows|architecture) ;; *) die "cache type must be modules, flows or architecture" ;; esac
[[ -f "$file" ]] || die "staged file missing: $file"

body="$(awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm {print}' "$file")"
problems=()
add() { problems+=("$1"); }

[[ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ]] || { echo "check-staged-cache: empty body" >&2; exit 1; }

title="$(sed -n '/[^[:space:]]/{p;q;}' <<<"$body")"
case "$type" in
  modules) want="# Modules" ;;
  flows) want="# Flows" ;;
  architecture) want="# Architecture" ;;
esac
[[ "$title" == "$want" ]] || add "first line must be '$want' (found '$title')"

if grep -q '<!-- slot:' <<<"$body"; then add "unfilled slot left: $(grep -c '<!-- slot:' <<<"$body") '<!-- slot: ... -->' marker(s)"; fi
if grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' <<<"$body"; then add "body holds a timestamp; the stamp belongs in the frontmatter only"; fi

headings="$(printf '%s\n' "$body" | awk '/^```/ {f = !f; next} !f && /^## / {sub(/^## /, ""); print}')"
fences_open="$(printf '%s\n' "$body" | grep -c '^```' || true)"
[[ $((fences_open % 2)) -eq 0 ]] || add "unbalanced code fences"

sorted_unique() { # stdin lines -> 0 when byte-sorted and unique
  local in
  in="$(cat)"
  [[ "$in" == "$(printf '%s\n' "$in" | sort -u)" ]]
}

# section NAME -> lines of the body between "## NAME" and the next "## " outside fences
section() {
  printf '%s\n' "$body" | awk -v h="## $1" '
    /^```/ { f = !f }
    !f && /^## / { on = ($0 == h); next }
    on { print }'
}

# mermaid blocks of a text on stdin, separated by a line "%%END"
mermaid_blocks() { awk '/^```mermaid[[:space:]]*$/ {m=1; next} m && /^```/ {m=0; print "%%END"; next} m {print}'; }

case "$type" in
  architecture)
    # A body published before Unresolved edges existed stays valid until its next regeneration.
    if [[ "$headings" != "$(printf '%s\n' "Module graph" "Edges" "Boundary violations" "Unresolved edges")" \
       && "$headings" != "$(printf '%s\n' "Module graph" "Edges" "Boundary violations")" ]]; then
      add "sections must be exactly: Module graph, Edges, Boundary violations, Unresolved edges (in that order; Unresolved edges may be absent)"
    fi
    u="$(section "Unresolved edges" | sed '/^[[:space:]]*$/d')"
    if [[ -n "$u" && "$u" != "None." ]]; then printf '%s\n' "$u" | sorted_unique || add "Unresolved edges list is not byte-sorted and unique"; fi
    g="$(section "Module graph" | mermaid_blocks)"
    [[ "$(printf '%s\n' "$g" | grep -c '^%%END$' || true)" -eq 1 ]] || add "Module graph must hold exactly one mermaid block"
    [[ "$(head -1 <<<"$g")" == "flowchart LR" ]] || add "Module graph block must start with 'flowchart LR'"
    e="$(section "Edges" | sed '/^[[:space:]]*$/d')"
    if [[ "$e" != "None." ]]; then printf '%s\n' "$e" | sorted_unique || add "Edges list is not byte-sorted and unique"; fi
    ;;
  modules)
    [[ -n "$headings" ]] || add "no module sections"
    printf '%s\n' "$headings" | sorted_unique || add "module sections are not byte-sorted and unique"
    while IFS= read -r h; do
      [[ -n "$h" ]] || continue
      s="$(section "$h")"
      keys="$(printf '%s\n' "$s" | awk '/^- (Purpose|Files|Depends on|Used by|Public interface):/ {sub(/^- /, ""); sub(/:.*/, ""); print}')"
      [[ "$keys" == "$(printf '%s\n' "Purpose" "Files" "Depends on" "Used by" "Public interface")" ]] \
        || add "$h: fields must be Purpose, Files, Depends on, Used by, Public interface (in that order)"
      p="$(printf '%s\n' "$s" | sed -n 's/^- Purpose: //p')"
      if [[ -z "$p" ]]; then add "$h: Purpose is empty"
      elif [[ "$p" != *. ]]; then add "$h: Purpose must be one sentence ending in '.'"
      elif [[ "$(printf '%s' "${p%.}" | grep -o '[.!?] ' | wc -l | tr -d ' ')" -gt 0 ]]; then add "$h: Purpose must be one sentence"
      fi
    done <<<"$headings"
    ;;
  flows)
    first="$(head -1 <<<"$headings")"
    [[ "$first" == "Entry points" ]] || add "first section must be 'Entry points'"
    rest="$(printf '%s\n' "$headings" | sed '1d')"
    entries="$(section "Entry points" | sed '/^[[:space:]]*$/d')"
    if [[ "$entries" == "None." ]]; then
      [[ -z "$rest" ]] || add "Entry points says None. but entry sections exist"
    else
      # shellcheck disable=SC2016 # backticks are literal Markdown
      list="$(printf '%s\n' "$entries" | sed -n 's/^- `\(.*\)`$/\1/p')"
      [[ "$(printf '%s\n' "$entries" | wc -l)" -eq "$(printf '%s\n' "$list" | wc -l)" ]] \
        || add "Entry points lines must each be '- \`<path>\`'"
      printf '%s\n' "$list" | sorted_unique || add "Entry points list is not byte-sorted and unique"
      [[ "$list" == "$rest" ]] || add "entry sections must match the Entry points list one to one, in the same order"
      while IFS= read -r h; do
        [[ -n "$h" ]] || continue
        blk="$(section "$h" | mermaid_blocks)"
        [[ "$(printf '%s\n' "$blk" | grep -c '^%%END$' || true)" -eq 1 ]] || { add "$h: needs exactly one mermaid block"; continue; }
        bad="$(printf '%s\n' "$blk" | awk -v h="$h" '
          /^%%END$/ { next }
          NR == 1 { if ($0 != "sequenceDiagram") print h ": block must start with sequenceDiagram"; next }
          /^  participant [A-Za-z0-9_]+ as [^ ]+$/ { if (arrows) print h ": participant declared after a call: " $0; next }
          /^ +[A-Za-z0-9_]+->>[A-Za-z0-9_]+: [A-Za-z_$][A-Za-z0-9_$.]*\(\)$/ { arrows = 1; next }
          /^ +(alt|else|opt|loop)( |$)/ || /^ +end$/ { next }
          { print h ": not canonical (participant, A->>B: name(), or alt/else/opt/loop/end only): " $0 }')"
        if [[ -n "$bad" ]]; then while IFS= read -r b; do add "$b"; done <<<"$bad"; fi
        after="$(section "$h" | awk '/^```/ {f = !f; seen = 1; next} seen && !f {print}' | sed '/^[[:space:]]*$/d')"
        [[ "$(head -1 <<<"$after")" == "Error branches:" ]] || add "$h: an 'Error branches:' list must follow the diagram"
        eb="$(printf '%s\n' "$after" | sed '1d')"
        if [[ "$eb" != "- none" ]]; then printf '%s\n' "$eb" | sorted_unique || add "$h: Error branches are not byte-sorted and unique"; fi
      done <<<"$rest"
    fi
    ;;
esac

# write_mermaid_html FILE : write every ```mermaid block of the body into FILE as an HTML-escaped <pre class="mermaid">
write_mermaid_html() {
  {
    echo '<!DOCTYPE html><html><body>'
    printf '%s\n' "$body" | mermaid_blocks | awk '
      BEGIN { open = 0 }
      /^%%END$/ { if (open) print "</pre>"; open = 0; next }
      { if (!open) { printf "<pre class=\"mermaid\">"; open = 1 }
        gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;"); print }'
    echo '</body></html>'
  } >"$1"
}

# package_reachable NAME : 0 when node_modules/NAME sits beside the validator or in a folder above it, where node's
#   import lookup from the validator would find it
package_reachable() {
  local dir
  dir="$(dirname "$mermaid_validator")"
  while :; do
    [[ -f "$dir/node_modules/$1/package.json" ]] && return 0
    [[ "$dir" == / ]] && return 1
    dir="$(dirname "$dir")"
  done
}

# validate_mermaid : run the validator on the body's diagrams; on rejection print its output to stderr and exit 1
validate_mermaid() {
  local html report
  html="$(mktemp "${TMPDIR:-/tmp}/check-staged-cache.XXXXXX")" || die "cannot create a temporary file"
  write_mermaid_html "$html"
  if report="$(node "$mermaid_validator" "$html" 2>&1)"; then
    rm -f "$html"
    return 0
  fi
  rm -f "$html"
  echo "check-staged-cache: the Mermaid validator rejected a diagram; fix it and re-run:" >&2
  printf '%s\n' "$report" >&2
  exit 1
}

if [[ -n "$html_out" ]]; then write_mermaid_html "$html_out"; fi

if [[ ${#problems[@]} -gt 0 ]]; then
  for p in "${problems[@]}"; do echo "check-staged-cache: $p" >&2; done
  exit 1
fi

if grep -q '^```mermaid[[:space:]]*$' <<<"$body"; then
  if [[ -f "$mermaid_validator" ]] && command -v node >/dev/null 2>&1 \
     && package_reachable mermaid && package_reachable jsdom; then
    validate_mermaid
  else
    echo "check-staged-cache: Mermaid diagrams not machine-validated (needs node with the mermaid and jsdom packages);" \
      "check them by hand against \"Mermaid syntax rules\" in $mermaid_checklist" >&2
  fi
fi
echo ok
