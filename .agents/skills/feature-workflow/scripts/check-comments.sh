#!/usr/bin/env bash
# File: Helper script (not a hook): the comment lint. Fails when a body comment in a shell file points at a workflow record
#   instead of giving its reason.
# Purpose: readable-code.md R4 says a comment keeps its reason in the comment and never points at a decision record or a
#   workflow file. The breaches that keep recurring are exact strings, so this script finds them and the 3.7 mini-review does
#   not have to: a decision id (D, G or ADR- followed by digits), a journey id (JRN- and digits), a task id written as T,
#   digits and a colon, or a path under .workflow/. Profile lint commands run it at 3.5, and the implementation agent runs it over its own diff before it stops.
#   - Only shell files are read: a name ending .sh or .bash, or a first line that is a sh, bash, dash, ksh or zsh shebang.
#     Other files are skipped without a word, so a caller may pass every changed file.
#   - A comment is a line whose first non-blank character is #, or the text from a # that starts a word outside quotes to the
#     end of the line. Quotes are tracked across lines, so a line inside a multi-line string is not a comment; neither
#     is a heredoc body, a here-string, $# or ${#x}.
#   - The header block is the run of comment lines at the top of the file, after the shebang, up to the first line that is
#     not a comment (a blank line ends it). It is the script's interface doc, so it may name the .workflow/ paths the script
#     reads or writes. A header that starts with `# Suite:` (a test suite) may also name the journey ids it covers. No
#     header may name a decision or task id.
# Usage:
#   check-comments.sh [--] [FILE...]
# stdout: one line per breaching comment, in argument order then line order:
#   <file>:<line>: <kinds>: <comment text>
#   kinds is one or more of "decision id", "journey id", "task id", "workflow path", joined with ", ".
# stderr on exit 1: one line with the count and the fix.
# Exit: 0 no breach (no files, or no shell files, is clean); 1 one or more breaches; 2 usage error, or a missing or
#   unreadable file.
# Called by: the lint key of a work profile (this repo's shell-scripts and test-harness profiles) and the implementation
#   agent's self-review.
# Notes: bash 3.2 compatible; needs awk.
# Sources: first-party.

set -euo pipefail

PROG=check-comments.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# is_shell_file FILE : true when FILE has a shell name or starts with a shell shebang.
is_shell_file() {
  local first=""
  case "$1" in
    *.sh | *.bash) return 0 ;;
  esac
  local shebang='^#!.*[/[:space:]](ba|da|k|z)?sh([[:space:]]|$)'
  IFS= read -r first <"$1" || true
  [[ $first =~ $shebang ]]
}

# Reads every file given and prints one line per breaching comment. The quote state carries from line to line, because a
# string may span lines; a heredoc opened on a line is skipped from the next line up to its delimiter.
read -r -d '' AWK_LINT <<'AWK' || true
function kinds(text, in_header, suite,    out) {
  out = ""
  if (text ~ /(^|[^A-Za-z0-9_])[DG][0-9]+([^A-Za-z0-9_]|$)/ || text ~ /ADR-[0-9]/) out = out ", decision id"
  if (text ~ /JRN-[0-9]/ && !(in_header && suite)) out = out ", journey id"
  if (text ~ /(^|[^A-Za-z0-9_])T[0-9]+:/) out = out ", task id"
  if (text ~ /[.]workflow\// && !in_header) out = out ", workflow path"
  return substr(out, 3)
}

# Sets comment to the comment text on the line ("" when none) and heredoc_delim / heredoc_dash to a heredoc it opens.
# in_s and in_d say whether the line ends inside a single- or double-quoted string.
function scan(line,    i, n, ch, prev, rest, word) {
  comment = ""; heredoc_delim = ""; heredoc_dash = 0
  prev = ""
  n = length(line)
  for (i = 1; i <= n; i++) {
    ch = substr(line, i, 1)
    if (in_s) { if (ch == "'") in_s = 0; prev = ch; continue }
    if (ch == "\\") { i++; prev = ""; continue }
    if (in_d) { if (ch == "\"") in_d = 0; prev = ch; continue }
    if (ch == "'") { in_s = 1 }
    else if (ch == "\"") { in_d = 1 }
    else if (ch == "#" && (prev == "" || prev ~ /[[:space:];&|()]/)) { comment = substr(line, i); return }
    # An arithmetic shift such as (( n = 1 << k )) would otherwise read as a heredoc and hide the rest of the file.
    else if (ch == "<" && substr(line, i, 2) == "<<" && prev != "<" && substr(line, i + 2, 1) != "<" && heredoc_delim == "" \
      && index(substr(line, 1, i), "((") == 0) {
      rest = substr(line, i + 2)
      if (substr(rest, 1, 1) == "-") { heredoc_dash = 1; rest = substr(rest, 2) }
      if (match(rest, /^[ \t]*['"\\]?[A-Za-z_][A-Za-z0-9_]*/)) {
        word = substr(rest, 1, RLENGTH)
        sub(/^[ \t]*['"\\]?/, "", word)
        heredoc_delim = word
      } else heredoc_dash = 0
      i++
      ch = "<"
    }
    prev = ch
  }
}

FNR == 1 { in_header = 1; suite = 0; header_seen = 0; open_delim = ""; in_s = 0; in_d = 0 }

{
  line = $0
  if (open_delim != "") {
    probe = line
    if (open_dash) sub(/^\t+/, "", probe)
    if (probe == open_delim) open_delim = ""
    next
  }
  if (FNR == 1 && line ~ /^#!/) next
  if (in_header) {
    if (line ~ /^[ \t]*#/) {
      if (!header_seen) { header_seen = 1; suite = (line ~ /^# Suite:/) }
    } else in_header = 0
  }
  scan(line)
  if (heredoc_delim != "") { open_delim = heredoc_delim; open_dash = heredoc_dash }
  if (comment == "") next
  k = kinds(comment, in_header, suite)
  if (k == "") next
  sub(/[ \t]+$/, "", comment)
  printf "%s:%d: %s: %s\n", FILENAME, FNR, k, comment
}
AWK

while [[ $# -gt 0 ]]; do
  case "$1" in
    --) shift; break ;;
    -*) die "unknown option '$1' (usage: $PROG [--] [FILE...])" ;;
    *) break ;;
  esac
done

shell_files=()
for f in "$@"; do
  [[ -f $f ]] || die "no such file: $f"
  [[ -r $f ]] || die "cannot read: $f"
  if is_shell_file "$f"; then
    shell_files+=("$f")
  fi
done
[[ ${#shell_files[@]} -gt 0 ]] || exit 0

breaches=$(awk "$AWK_LINT" "${shell_files[@]}") || die "awk failed"
[[ -n $breaches ]] || exit 0
printf '%s\n' "$breaches"
count=$(printf '%s\n' "$breaches" | wc -l | tr -d ' ')
printf '%s: %s comments name a decision, journey or task id or a workflow path; write the reason itself in plain words instead (readable-code R4)\n' \
  "$PROG" "$count" >&2
exit 1
