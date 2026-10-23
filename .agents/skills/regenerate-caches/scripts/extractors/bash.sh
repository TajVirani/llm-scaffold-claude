#!/usr/bin/env bash
# File: Helper script (not a hook): the bash graph extractor, a file graph from `source`/`.` lines and script calls, with the top-level functions of sourced files.
# Purpose: Interface stub. Prints an empty graph in dependency-cruiser's JSON shape until the extractor is built.
# Usage:
#   extractors/bash.sh --root DIR --scope PATH [--scope PATH]...
# Output: dependency-cruiser-shaped JSON on stdout.
# Exit: 0 = printed (an empty modules list is valid); 2 = usage or tool error.
# Sources: first-party.
set -euo pipefail

echo '{"modules":[]}'
