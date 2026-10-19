#!/usr/bin/env bash
# File: Sourced helper (not a hook) shared by codex-write-guard.sh and codex-rules-sync.sh.
# Purpose: Parse the patch text Codex sends as `tool_input.command` for its `apply_patch` tool (verified 0.155.1,
#   PLAN/hook-verification-codex.md row 5a) into the list of file paths it touches.
# Usage: source it, then
#   codex_patch_paths <patch-file>          stdout: one `<index>\t<op>\t<path>` line per path, in patch order; exit 1 on a parse error
#                                           (reason on stderr). op = add | update | delete | move (the `*** Move to:` target of the
#                                           update with the same index).
#   codex_patch_body <patch-file> <index>   stdout: the hunk lines of file section <index> (the lines after its header and optional
#                                           `*** Move to:` line, up to the next file header or `*** End Patch`).
#   codex_patch_text                        reads the PreToolUse/PostToolUse payload on stdin and prints the patch text: tool_input.command
#                                           when it is a string, or the last element when it is an array (argv form). Exit 1 when neither.
# Grammar accepted (Codex apply_patch format), fail closed on anything else:
#   optional heredoc wrapper line (`apply_patch <<'EOF'`, `<<EOF`) and blank lines before `*** Begin Patch`;
#   file headers `*** Add File: p`, `*** Update File: p` (optionally followed directly by `*** Move to: p`), `*** Delete File: p`;
#   hunk lines are not validated except that a line starting with `*** ` must be a known header, `*** End of File` or `*** End Patch`;
#   `*** End Patch`, then only blank lines or a bare heredoc terminator word.
#   Errors: no Begin/End, unknown `*** ` line, empty path, a path with a tab, `*** Move to:` not right after an Update header, no file section.
#   Paths are trimmed of surrounding whitespace, as Codex does; a trailing CR is dropped from every line.
# Plan refs: assetlist D9, D40, D67; PLAN/hook-verification-codex.md rows 5a, 5b.
# Sources: first-party; patch format from the Codex apply_patch tool description (codex-cli 0.155.1) and row 5a's observed payload.
# Requires: bash 3.2+, awk, jq.

codex_patch_text() {
  jq -er '.tool_input.command | if type == "string" then . elif type == "array" and length > 0 and (.[-1] | type) == "string" then .[-1] else error("no patch") end' 2>/dev/null
}

codex_patch_paths() {
  awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function fail(msg) { print "apply_patch parse error: " msg " (line " NR ")" > "/dev/stderr"; bad = 1; exit 1 }
    function emit(op, p) {
      p = trim(p)
      if (p == "") fail("empty path after `*** " hdr ":`")
      if (index(p, "\t")) fail("tab in path")
      printf "%d\t%s\t%s\n", n, op, p
    }
    { sub(/\r$/, "") }
    state == 0 {
      if ($0 ~ /^[ \t]*\*\*\* Begin Patch[ \t]*$/) { state = 1; next }
      if ($0 ~ /^[ \t]*$/) next
      if (!wrapper && $0 ~ /^[ \t]*(apply_patch[ \t]+)?<<-?[ \t]*['"'"'"]?[A-Za-z_][A-Za-z0-9_]*['"'"'"]?[ \t]*$/) { wrapper = 1; next }
      fail("text before `*** Begin Patch`")
    }
    state == 2 {
      if ($0 ~ /^[ \t]*$/) next
      if (wrapper && !term && $0 ~ /^[A-Za-z_][A-Za-z0-9_]*[ \t]*$/) { term = 1; next }
      fail("text after `*** End Patch`")
    }
    /^\*\*\* End Patch[ \t]*$/ { state = 2; next }
    /^\*\*\* Add File:/    { n++; hdr = "Add File";    emit("add",    substr($0, 14)); last = "add"; next }
    /^\*\*\* Delete File:/ { n++; hdr = "Delete File"; emit("delete", substr($0, 17)); last = "delete"; next }
    /^\*\*\* Update File:/ { n++; hdr = "Update File"; emit("update", substr($0, 17)); last = "update-header"; next }
    /^\*\*\* Move to:/ {
      if (last != "update-header") fail("`*** Move to:` not directly after `*** Update File:`")
      hdr = "Move to"; emit("move", substr($0, 13)); last = "move"; next
    }
    /^\*\*\* End of File[ \t]*$/ { last = "body"; next }
    /^\*\*\* / { fail("unknown patch header: " $0) }
    {
      if (n == 0 && $0 !~ /^[ \t]*$/) fail("hunk line before any file header")
      last = "body"
    }
    END {
      if (bad) exit 1
      if (state == 0) { print "apply_patch parse error: no `*** Begin Patch` line" > "/dev/stderr"; exit 1 }
      if (state == 1) { print "apply_patch parse error: no `*** End Patch` line" > "/dev/stderr"; exit 1 }
      if (n == 0) { print "apply_patch parse error: the patch names no file" > "/dev/stderr"; exit 1 }
    }
  ' "$1"
}

codex_patch_body() {
  awk -v want="$2" '
    { sub(/\r$/, "") }
    !begun { if ($0 ~ /^[ \t]*\*\*\* Begin Patch[ \t]*$/) begun = 1; next }
    /^\*\*\* End Patch[ \t]*$/ { exit }
    /^\*\*\* (Add|Delete|Update) File:/ { n++; next }
    /^\*\*\* Move to:/ { next }
    n == want { print }
  ' "$1"
}
