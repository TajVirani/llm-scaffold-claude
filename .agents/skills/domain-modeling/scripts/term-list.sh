#!/usr/bin/env bash
# File: Helper script (not a hook): the term list, the canonical term names of the project glossary with their avoided
#   aliases, printed in place of the whole glossary; and one whole entry looked up by name.
# Purpose: A session loads the term list and reads a definition only when a term in play matches one on it. An entry is a
#   `**<term>**:` line at the start of a line, followed by its definition and an optional `_Avoid_:` line; it ends at a
#   blank line, a heading or the next entry (the glossary format in ../assets/GLOSSARY-FORMAT.md).
# Usage:
#   term-list.sh                  one line per glossary entry, in file order: `<term> (avoid: <aliases>)`, or `<term>` for
#                                 an entry with no _Avoid_ line. Reads .workflow/GLOSSARY.md under the current directory,
#                                 or, when .workflow/GLOSSARY-MAP.md exists, every context glossary its `## Contexts`
#                                 section links (`- [<context>](<path>)`, the path relative to the current directory), each
#                                 line then prefixed `[<context>] `; a map that links none, or a link with no path, is an error.
#                                 With neither file there is no glossary yet: it prints nothing.
#   term-list.sh --define <term>  the whole entry for <term>, matched exactly: its **<term>**: line, its definition and its
#                                 _Avoid_ line. When several mapped glossaries define <term>, each entry is printed, a blank
#                                 line between them.
# Exit: 0 printed; 1 the term is not in any glossary; 2 usage error, a glossary or map that cannot be read, or a map that
#   links no context glossary.
# Notes: bash 3.2 compatible.
# Sources: first-party. Glossary and map paths: .agents/lib/workflow-paths.sh.

set -euo pipefail

PROG="term-list.sh"
USAGE="usage: term-list.sh [--define <term>]"

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh" || die "cannot load workflow-paths.sh"

# list_terms CONTEXT GLOSSARY : prints one line per entry of GLOSSARY with its aliases, prefixed [CONTEXT] when CONTEXT is set.
list_terms() {
  awk -v context="$1" '
    function print_entry(  line) {
      if (term == "") return
      line = term
      if (aliases != "") line = line " (avoid: " aliases ")"
      if (context != "") line = "[" context "] " line
      print line
      term = ""
      aliases = ""
    }
    { sub(/\r$/, "") }
    /^\*\*[^*]+\*\*:/ {
      print_entry()
      term = $0
      sub(/^\*\*/, "", term)
      sub(/\*\*:.*$/, "", term)
      next
    }
    term != "" && /^_Avoid_:/ {
      aliases = $0
      sub(/^_Avoid_:[[:space:]]*/, "", aliases)
      next
    }
    /^[[:space:]]*$/ || /^#/ { print_entry() }
    END { print_entry() }
  ' "$2"
}

# define_entry TERM GLOSSARY... : prints every whole entry named exactly TERM, a blank line between two; status 1 when none.
define_entry() {
  local term=$1
  shift
  awk -v wanted="$term" '
    FNR == 1 { printing = 0 }
    { sub(/\r$/, "") }
    /^\*\*[^*]+\*\*:/ {
      name = $0
      sub(/^\*\*/, "", name)
      sub(/\*\*:.*$/, "", name)
      printing = (name == wanted)
      if (printing && found) print ""
      if (printing) found = 1
    }
    /^[[:space:]]*$/ || /^#/ { printing = 0 }
    printing { print }
    END { exit found ? 0 : 1 }
  ' "$@"
}

# map_contexts MAP : prints one "<context><TAB><glossary path>" line per link in the map's Contexts section.
map_contexts() {
  awk '
    { sub(/\r$/, "") }
    /^## / { in_contexts = ($0 ~ /^## Contexts[[:space:]]*$/); next }
    in_contexts && /^[-*][[:space:]]+\[[^]]+\]\([^)]+\)/ {
      link = $0
      sub(/^[-*][[:space:]]+\[/, "", link)
      context = link
      sub(/\]\(.*$/, "", context)
      path = link
      sub(/^[^]]*\]\(/, "", path)
      sub(/\).*$/, "", path)
      sub(/^\.\//, "", path)
      print context "\t" path
    }
  ' "$1"
}

define_term=
case "${1:-}" in
  '') ;;
  --define)
    [ "$#" -eq 2 ] && [ -n "$2" ] || die "$USAGE"
    define_term=$2
    ;;
  *) die "$USAGE" ;;
esac

# Parallel lists: the glossaries to read and the context each belongs to ("" for the root glossary).
contexts=()
glossaries=()
if [ -e "$WF_GLOSSARY_MAP" ]; then
  links=$(map_contexts "$WF_GLOSSARY_MAP") || die "cannot read $WF_GLOSSARY_MAP"
  # A map replaces the root glossary, so a map that names nothing would leave every term off the list unnoticed.
  [ -n "$links" ] || die "$WF_GLOSSARY_MAP links no context glossary under its ## Contexts heading"
  while IFS=$'\t' read -r context glossary; do
    [ -n "$glossary" ] || die "the $context context in $WF_GLOSSARY_MAP links no glossary path"
    [ -r "$glossary" ] || die "cannot read $glossary, the $context glossary $WF_GLOSSARY_MAP links"
    contexts+=("$context")
    glossaries+=("$glossary")
  done <<<"$links"
elif [ -e "$WF_GLOSSARY" ]; then
  [ -r "$WF_GLOSSARY" ] || die "cannot read $WF_GLOSSARY"
  contexts=("")
  glossaries=("$WF_GLOSSARY")
fi

if [ -n "$define_term" ]; then
  define_status=1
  if [ "${#glossaries[@]}" -gt 0 ]; then
    define_status=0
    define_entry "$define_term" "${glossaries[@]}" || define_status=$?
  fi
  case "$define_status" in
    0) exit 0 ;;
    1) printf '%s: no glossary entry for "%s"\n' "$PROG" "$define_term" >&2; exit 1 ;;
    *) die "cannot read the glossaries" ;;
  esac
fi

i=0
while [ "$i" -lt "${#glossaries[@]}" ]; do
  list_terms "${contexts[$i]}" "${glossaries[$i]}" || die "cannot read ${glossaries[$i]}"
  i=$((i + 1))
done
