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
#                                 line then prefixed `[<context>] `. A map that links none, a top-level list item in that
#                                 section that is not such a link, or a link with no path, is an error. With neither file
#                                 there is no glossary yet: it prints nothing.
#   term-list.sh --define <term>  the whole entry for <term>, matched exactly: its **<term>**: line, its definition and its
#                                 _Avoid_ line. When several mapped glossaries define <term>, each entry is printed, a blank
#                                 line between them.
# Exit: 0 printed; 1 the term is not in any glossary; 2 usage error, a glossary, map or .workflow folder that cannot be
#   read (a broken link included), or a map that links no context glossary or holds a Contexts item that is not a link.
# Notes: bash 3.2 compatible.
# Sources: first-party. Glossary and map paths: .agents/lib/workflow-paths.sh.

set -euo pipefail

PROG="term-list.sh"
USAGE="usage: term-list.sh [--define <term>]"

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh" || die "cannot load workflow-paths.sh"

# The context and the term reach awk through the environment, because awk -v would turn a backslash in them into an escape.

# list_terms CONTEXT GLOSSARY : prints one line per entry of GLOSSARY with its aliases, prefixed [CONTEXT] when CONTEXT is set.
list_terms() {
  GLOSSARY_CONTEXT=$1 awk '
    BEGIN { context = ENVIRON["GLOSSARY_CONTEXT"] }
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
  WANTED_TERM=$term awk '
    BEGIN { wanted = ENVIRON["WANTED_TERM"] }
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

# map_contexts MAP : prints "link<TAB><context><TAB><glossary path>" per context link in the map's Contexts section, and
#   "item<TAB><text>" per other top-level list item there. Indented lines and prose are not items.
map_contexts() {
  awk '
    { sub(/\r$/, "") }
    /^## / { in_contexts = ($0 ~ /^## Contexts[[:space:]]*$/); next }
    !in_contexts { next }
    /^[-*][[:space:]]+\[[^]]+\]\([^)]*\)/ {
      link = $0
      sub(/^[-*][[:space:]]+\[/, "", link)
      context = link
      sub(/\]\(.*$/, "", context)
      path = link
      sub(/^[^]]*\]\(/, "", path)
      sub(/\).*$/, "", path)
      sub(/^\.\//, "", path)
      print "link\t" context "\t" path
      next
    }
    /^([-*+]|[0-9]+[.)])([[:space:]]|$)/ {
      item = $0
      gsub(/\t/, " ", item)
      print "item\t" item
    }
  ' "$1"
}

# path_present PATH : status 0 when PATH exists or is a link, a broken one included, so a broken link is reported rather
#   than taken for a missing file.
path_present() { [ -e "$1" ] || [ -L "$1" ]; }

define_term=
if [ "$#" -gt 0 ]; then
  [ "$#" -eq 2 ] && [ "$1" = --define ] && [ -n "$2" ] || die "$USAGE"
  define_term=$2
fi

# A folder that cannot be searched hides both files below, which would read as a project with no glossary yet.
if path_present "$WF_DIR"; then
  [ -d "$WF_DIR" ] && [ -x "$WF_DIR" ] || die "$WF_DIR is not a folder this script can search"
fi

# Parallel lists: the glossaries to read and the context each belongs to ("" for the root glossary).
contexts=()
glossaries=()
if path_present "$WF_GLOSSARY_MAP"; then
  [ -f "$WF_GLOSSARY_MAP" ] && [ -r "$WF_GLOSSARY_MAP" ] || die "$WF_GLOSSARY_MAP is not a readable file"
  links=$(map_contexts "$WF_GLOSSARY_MAP") || die "cannot read $WF_GLOSSARY_MAP"
  # A map replaces the root glossary, so a map that names nothing would leave every term off the list unnoticed.
  [ -n "$links" ] || die "$WF_GLOSSARY_MAP links no context glossary under its ## Contexts heading"
  while IFS=$'\t' read -r kind context glossary; do
    # For an item that is not a link, the context field holds the item's text.
    [ "$kind" = link ] || die "the item \"$context\" under ## Contexts in $WF_GLOSSARY_MAP is not a link of the form - [<context>](<path>)"
    [ -n "$glossary" ] || die "the $context context in $WF_GLOSSARY_MAP links no glossary path"
    [ -f "$glossary" ] && [ -r "$glossary" ] || die "the $context context in $WF_GLOSSARY_MAP links $glossary, which is not a readable file"
    contexts+=("$context")
    glossaries+=("$glossary")
  done <<<"$links"
elif path_present "$WF_GLOSSARY"; then
  [ -f "$WF_GLOSSARY" ] && [ -r "$WF_GLOSSARY" ] || die "$WF_GLOSSARY is not a readable file"
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
