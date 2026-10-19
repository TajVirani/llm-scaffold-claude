#!/usr/bin/env bash
# File: Helper script (not a hook): check a staged Tier B cache body against its fixed shape before it is published.
# Purpose: Catch drift in the agent-written parts (modules.md Purpose slots, flows.md sections and diagrams) and any
#   hand-built architecture.md, so only canonical bodies reach publish-cache.sh. Optionally wraps the body's ```mermaid
#   fences into an HTML file that .agents/skills/visual-change-report/scripts/validate_mermaid.mjs can parse, since that
#   validator reads only <pre class="mermaid"> blocks in HTML (PLAN/gap-research.md G6, "Mermaid validation").
# Called by: the cache-regeneration agent before it returns, and regenerate-caches / discovery 0.2.8 before publishing.
# Plan refs: 00.5-00.7, 0.2.8; PLAN/gap-research.md G6; assetlist D4, D17, D64.
# Sources: first-party. Shape rules: assets/cache-frontmatter.md "Body shape per cache type".
#
# Usage:
#   check-staged-cache.sh <modules|flows|architecture> <staged-file> [--html-out FILE]
#     --html-out FILE   also write every ```mermaid block as <pre class="mermaid"> (HTML-escaped) into FILE
# Output: "ok" on stdout, or one problem per line on stderr.
# Exit codes: 0 = body matches the shape; 1 = problems found (listed); 2 = usage error or file missing.
set -euo pipefail
export LC_ALL=C

die() { echo "check-staged-cache: $*" >&2; exit 2; }

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

title="$(printf '%s\n' "$body" | sed '/^[[:space:]]*$/d' | head -1)"
case "$type" in
  modules) want="# Modules" ;;
  flows) want="# Flows" ;;
  architecture) want="# Architecture" ;;
esac
[[ "$title" == "$want" ]] || add "first line must be '$want' (found '$title')"

if printf '%s\n' "$body" | grep -q '<!-- slot:'; then add "unfilled slot left: $(printf '%s\n' "$body" | grep -c '<!-- slot:') '<!-- slot: ... -->' marker(s)"; fi
if printf '%s\n' "$body" | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}'; then add "body holds a timestamp; the stamp belongs in the frontmatter only"; fi

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
    [[ "$headings" == "$(printf '%s\n' "Module graph" "Edges" "Boundary violations")" ]] \
      || add "sections must be exactly: Module graph, Edges, Boundary violations (in that order)"
    g="$(section "Module graph" | mermaid_blocks)"
    [[ "$(printf '%s\n' "$g" | grep -c '^%%END$' || true)" -eq 1 ]] || add "Module graph must hold exactly one mermaid block"
    [[ "$(printf '%s\n' "$g" | head -1)" == "flowchart LR" ]] || add "Module graph block must start with 'flowchart LR'"
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
    first="$(printf '%s\n' "$headings" | head -1)"
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
        [[ "$(printf '%s\n' "$after" | head -1)" == "Error branches:" ]] || add "$h: an 'Error branches:' list must follow the diagram"
        eb="$(printf '%s\n' "$after" | sed '1d')"
        if [[ "$eb" != "- none" ]]; then printf '%s\n' "$eb" | sorted_unique || add "$h: Error branches are not byte-sorted and unique"; fi
      done <<<"$rest"
    fi
    ;;
esac

if [[ -n "$html_out" ]]; then
  {
    echo '<!DOCTYPE html><html><body>'
    printf '%s\n' "$body" | mermaid_blocks | awk '
      BEGIN { open = 0 }
      /^%%END$/ { if (open) print "</pre>"; open = 0; next }
      { if (!open) { printf "<pre class=\"mermaid\">"; open = 1 }
        gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;"); print }'
    echo '</body></html>'
  } >"$html_out"
fi

if [[ ${#problems[@]} -gt 0 ]]; then
  for p in "${problems[@]}"; do echo "check-staged-cache: $p" >&2; done
  exit 1
fi
echo ok
