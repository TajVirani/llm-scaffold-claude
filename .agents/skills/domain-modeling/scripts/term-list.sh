#!/usr/bin/env bash
# File: Helper script (not a hook): the term list, the canonical term names of the project glossary with their avoided
#   aliases, printed in place of the whole glossary; and one whole entry looked up by name.
# Purpose: A session loads the term list and reads a definition only when a term in play matches one on it. This file is
#   the interface stub: it accepts the arguments below, prints nothing and exits 0 until the lister is built.
# Usage:
#   term-list.sh                  one line per glossary entry: the term and its _Avoid_ aliases. Reads .workflow/GLOSSARY.md
#                                 under the current directory, or, when .workflow/GLOSSARY-MAP.md exists, every context
#                                 glossary the map links, each line labelled with its context name.
#   term-list.sh --define <term>  the whole entry for <term>: its **<term>**: line, its definition and its _Avoid_ line.
# Exit: 0 printed; 1 the term is not in any glossary; 2 usage error or a glossary that cannot be read.
# Notes: bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

PROG=term-list.sh

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

case "${1:-}" in
  '') ;;
  --define) [ "$#" -eq 2 ] && [ -n "$2" ] || die "usage: term-list.sh [--define <term>]" ;;
  *) die "usage: term-list.sh [--define <term>]" ;;
esac
exit 0
