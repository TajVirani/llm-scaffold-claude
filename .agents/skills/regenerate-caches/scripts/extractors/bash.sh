#!/usr/bin/env bash
# File: Helper script (not a hook): the bash graph extractor, a file graph from `source`/`.` lines and script calls, with the top-level functions of sourced files.
# Purpose: Prints the graph of the bash files under the scopes in dependency-cruiser's JSON shape, for build-architecture.sh.
#   Claims every `*.sh` file and every file whose first line is a bash or sh shebang (git-listed, symlinks skipped).
#   Edges: each `source`/`.` line, each `$var/...sh` or `$(dirname ...)/...sh` path on a code line, and each other anchored
#   path on a code line that resolves to a file claimed by its shebang. A script run by a path relative to the working
#   directory (`./x`, `dir/x`, `bash x`, `sh x`) is always `couldNotResolve`. A path resolves
#   statically when it is anchored to the script's own directory (`$(dirname "$0")`, `$(dirname "${BASH_SOURCE[0]}")`,
#   `${BASH_SOURCE%/*}`, `$(cd [-P] X && pwd)`, or a variable assigned one of those, through any number of plain
#   variable hops and `$(dirname "$var")`), or to a variable it cannot follow (a runtime root) whose literal tail is an
#   existing repo file. A variable set to a runtime root plus a tail is followed one hop when exactly one of its two
#   readings (as a subfolder of that root, or as a root itself) names an existing file. Anything else, and any target that is not an existing file, is `couldNotResolve: true` with the
#   path text in `module`. Every dependency carries its 1-based `line`. Heredoc bodies are data and are not read.
#   `exports` maps each claimed file that another claimed file sources to its sorted unique column-0 function names.
# Usage:
#   extractors/bash.sh --root DIR --scope PATH [--scope PATH]...
#     --root DIR    repo root; every path in the output is relative to it
#     --scope PATH  root-relative file or directory, no '..' ('.' = the whole repo); repeatable, at least one
# Output: {"modules":[{"source","dependencies":[{"module","resolved"|"couldNotResolve","line"}]}],"exports":{}} on stdout,
#   every list byte-sorted.
# Exit: 0 = printed (an empty modules list is valid); 2 = usage error, missing root or scope, root not a git work tree,
#   missing tool, or a git ls-files, awk or jq failure.
# Requires: git, awk, jq.
# Sources: first-party. Output shape after dependency-cruiser's doc/output-format.md (MIT; shape only).
set -euo pipefail
export LC_ALL=C

# die MESSAGE... : prints "extractors/bash: MESSAGE" to stderr and exits 2.
die() { echo "extractors/bash: $*" >&2; exit 2; }

usage_line="usage: extractors/bash.sh --root DIR --scope PATH [--scope PATH]..."
root=""
scopes=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) [[ $# -ge 2 ]] || die "--root needs a value"; root="$2"; shift 2 ;;
    --scope) [[ $# -ge 2 ]] || die "--scope needs a value"; scopes+=("$2"); shift 2 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$root" ]] || die "--root is required; $usage_line"
[[ ${#scopes[@]} -gt 0 ]] || die "at least one --scope is required; $usage_line"
for tool in git awk jq; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found on PATH"
done
[[ -d "$root" ]] || die "root not found: $root"
cd "$root"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "root is not a git work tree: $root"

for s in "${scopes[@]}"; do
  [[ "$s" != /* && "/$s/" != */../* ]] || die "scope must be root-relative with no '..': $s"
  [[ -e "$s" ]] || die "scope path does not exist: $s"
done

listing=$(mktemp)
existing_files=$(mktemp)
trap 'rm -f "$listing" "$existing_files"' EXIT

# The whole repo's files, not only the scope's, because a script may call a file outside the scope.
git ls-files -z -co --exclude-standard >"$listing" || die "git ls-files failed under $root"
while IFS= read -r -d '' f; do
  if [[ -f "$f" ]]; then printf '%s\n' "$f"; fi
done <"$listing" >"$existing_files"

# The ./ prefix stops awk reading a file name that starts with '-' or holds '=' as an option or an assignment.
git --literal-pathspecs ls-files -z -co --exclude-standard -- "${scopes[@]}" >"$listing" \
  || die "git ls-files failed for the scopes under $root"
candidates=()
while IFS= read -r -d '' f; do
  if [[ -f "$f" && ! -L "$f" ]]; then candidates+=("./$f"); fi
done <"$listing"

# Prints tab-separated records: M <file> for each claimed file; E <file> <line> <resolved or empty> <path text> for each
# dependency; F <file> <function> for each top-level function of a claimed file that a claimed file sources.
# shellcheck disable=SC2016 # the awk program is single-quoted so the shell leaves its $ fields alone
extract_awk='
BEGIN {
  while ((getline f < existing) > 0) exists[f] = 1
  close(existing)
  for (i = 1; i < ARGC; i++) if (ARGV[i] ~ /\.sh$/) print "M\t" substr(ARGV[i], 3)
  shebang = "^#![ \t]*(/usr)?/bin/(env[ \t]+(-S[ \t]+)?)?(ba)?sh([ \t]|$)"
  var_name = "[A-Za-z_][A-Za-z0-9_]*"
  self_dir_forms = "\\$\\(dirname \\$(0|BASH_SOURCE|\\{BASH_SOURCE\\[0\\]\\})\\)|\\$\\{(0|BASH_SOURCE|BASH_SOURCE\\[0\\])%/\\*\\}"
  OPEN = "\034"; CLOSE = "\035"
}

FNR == 1 {
  file = substr(FILENAME, 3)
  if (file !~ /\.sh$/ && $0 !~ shebang) nextfile
  if (file !~ /\.sh$/) print "M\t" file
  file_dir = file
  if (!sub(/\/[^\/]*$/, "", file_dir)) file_dir = ""
  split("", dir_vars); split("", root_vars)
  heredoc_end = ""; line_continues = 0; open_quote = ""
}

{ sub(/\r$/, "") }

heredoc_end != "" {
  closing = $0
  if (heredoc_strips_tabs) sub(/^\t+/, "", closing)
  if (closing == heredoc_end) heredoc_end = ""
  next
}

/^[ \t]*#/ { next }

{
  raw = $0
  continued = line_continues
  line_continues = (raw ~ /\\$/)
  if (match(raw, "^(function[ \t]+" var_name "|" var_name "[ \t]*\\(\\))")) {
    fn = substr(raw, 1, RLENGTH)
    sub(/^function[ \t]+/, "", fn)
    sub(/[ \t]*\(\)$/, "", fn)
    functions[file, fn] = 1
  }

  line = fold_dir_expressions(strip_redirections(unbrace(remove_double_quotes(raw))))
  if (match(line, "^[ \t]*(local|export|readonly|declare|typeset)?([ \t]+-[A-Za-z]+)*[ \t]*" var_name "=")) {
    assignment = substr(line, RSTART, RLENGTH)
    sub(/^[ \t]*(local|export|readonly|declare|typeset)?([ \t]+-[A-Za-z]+)*[ \t]*/, "", assignment)
    name = substr(assignment, 1, length(assignment) - 1)
    value = substr(line, RSTART + RLENGTH)
    sub(/[ \t;].*$/, "", value)
    delete dir_vars[name]
    delete root_vars[name]
    if (eval_path(value)) {
      if (ev_runtime_root) root_vars[name] = ev_path
      else dir_vars[name] = ev_path
    }
  }

  if (match(line, /^[ \t]*(source|\.)[ \t]+/)) {
    target = substr(line, RSTART + RLENGTH)
    sub(/[ \t;].*$/, "", target)
    if (target ~ /^[$\034]/) add_edge(target, 1)
    else if (target ~ /\// || target ~ /\.sh$/) add_edge(target, 0)
    # A bare name is looked up on PATH at run time. A jq `. as $name` binding in a multi-line jq program reads the same way.
    else if (target ~ /^[A-Za-z0-9_.+-]+$/ && line !~ /^[ \t]*\.[ \t]+as[ \t]+\$/) add_edge(target, 0)
  } else {
    token_count = split(line, tokens, /[ \t;|&<>=`]+/)
    for (t = 1; t <= token_count; t++) {
      token = tokens[t]
      while (sub(/^(\$\(|[(!])/, "", token)) {}
      sub(/[);]+$/, "", token)
      if (token ~ /\{/ && token !~ /\}/) continue
      if (token !~ /^[$\034]/) continue
      if (token ~ /\.sh$/) add_edge(token, 1)
      else if (token ~ /\//) {
        anchored_target = resolve_anchored(token)
        if (is_claimed_script(anchored_target)) add_edge(token, 1)
        else if (anchored_target in unreadable) add_edge(token, 0)
      }
    }
    report_cwd_relative_calls(line)
    report_bare_relative_calls(raw, continued)
  }

  # Without the (( guard an arithmetic shift such as (( n = 1 << k )) reads as a heredoc and skips the rest of the file.
  if (raw !~ /\(\(/ && match(raw, /(^|[^<])<<-?[ \t]*[\047"\\]?[A-Za-z_][A-Za-z0-9_]*/)) {
    marker = substr(raw, RSTART, RLENGTH)
    heredoc_strips_tabs = (marker ~ /<<-/)
    sub(/^.*<<-?[ \t]*[\047"\\]?/, "", marker)
    heredoc_end = marker
  }
}

END {
  for (key in functions) {
    split(key, parts, SUBSEP)
    if (parts[1] in sourced) print "F\t" parts[1] "\t" parts[2]
  }
}

# remove_double_quotes TEXT : TEXT without double quotes, so quoted and unquoted paths read the same.
function remove_double_quotes(text) {
  gsub(/"/, "", text)
  return text
}

# unbrace TEXT : TEXT with each plain ${name} written as $name; ${name:-x} and other expansions stay as they are.
function unbrace(text,   out, name) {
  out = ""
  while (match(text, "\\$\\{" var_name "\\}")) {
    name = substr(text, RSTART + 2, RLENGTH - 3)
    out = out substr(text, 1, RSTART - 1) "$" name
    text = substr(text, RSTART + RLENGTH)
  }
  return out text
}

# strip_redirections TEXT : TEXT without redirection targets, because a file written or read is not a file called.
function strip_redirections(text) {
  gsub(/[0-9]*(<<<|>>|>|<)&?[ \t]*[^ \t;|&()]*/, " ", text)
  return text
}

# fold_dir_expressions TEXT : TEXT with each directory expression replaced by a placeholder that records the directory.
function fold_dir_expressions(text,   inner) {
  while (1) {
    if (match(text, self_dir_forms)) {
      text = placeholder(text, 1, file_dir)
    } else if (match(text, "\\$\\(dirname \\$" var_name "\\)")) {
      inner = substr(text, RSTART + 10, RLENGTH - 11)
      if (match(text, "\\$\\(dirname \\$" var_name "\\)") && (inner in dir_vars) && dir_vars[inner] != "")
        text = placeholder(text, parent_dir(dir_vars[inner]) != "\001", parent_dir(dir_vars[inner]))
      else text = placeholder(text, 0, "")
    } else if (match(text, /\$\(cd( -P)? [^ )]+ && pwd( -P)?\)/)) {
      inner = substr(text, RSTART, RLENGTH)
      sub(/^\$\(cd( -P)? /, "", inner)
      sub(/ && pwd( -P)?\)$/, "", inner)
      eval_path(inner)
      match(text, /\$\(cd( -P)? [^ )]+ && pwd( -P)?\)/)
      text = placeholder(text, ev_ok && !ev_runtime_root, ev_path)
    } else return text
  }
}

# placeholder TEXT OK DIR : TEXT with the match at RSTART/RLENGTH replaced by a new placeholder for DIR (unresolvable when OK is 0).
function placeholder(text, ok, dir) {
  holders++
  holder_ok[holders] = ok
  holder_dir[holders] = dir
  holder_text[holders] = substr(text, RSTART, RLENGTH)
  return substr(text, 1, RSTART - 1) OPEN holders CLOSE substr(text, RSTART + RLENGTH)
}

# restore_text TOKEN : TOKEN with each placeholder put back as the text it replaced.
function restore_text(token,   id) {
  while (match(token, OPEN "[0-9]+" CLOSE)) {
    id = substr(token, RSTART + 1, RLENGTH - 2)
    token = substr(token, 1, RSTART - 1) holder_text[id] substr(token, RSTART + RLENGTH)
  }
  return token
}

# parent_dir DIR : the parent of root-relative DIR, or \001 when DIR is the root itself.
function parent_dir(dir) {
  if (dir == "") return "\001"
  if (!sub(/\/[^\/]*$/, "", dir)) dir = ""
  return dir
}

# eval_path TEXT : 1 when TEXT is an anchor (placeholder or $name) plus a literal tail, setting ev_path to the
# root-relative path it names. ev_runtime_root is 1 when the anchor is a variable this file never sets to its own
# directory: its value is only known at run time, so the path counts only when its literal tail names an existing file.
# A variable set to another run-time variable plus a tail may name a subfolder or a new root, so for it
# ev_root_tail_path also holds the path read with the variable as the root, and add_edge accepts whichever one exists.
function eval_path(text,   id, name, base, rest) {
  ev_ok = 0; ev_path = ""; ev_root_tail_path = ""; ev_runtime_root = 0
  if (match(text, "^" OPEN "[0-9]+" CLOSE)) {
    id = substr(text, 2, RLENGTH - 2)
    if (!holder_ok[id]) return 0
    base = holder_dir[id]
  } else if (match(text, "^\\$" var_name)) {
    name = substr(text, 2, RLENGTH - 1)
    ev_runtime_root = !(name in dir_vars)
    if (name in dir_vars) base = dir_vars[name]
    else if (name in root_vars) base = root_vars[name]
    else base = ""
  } else return 0
  rest = substr(text, RLENGTH + 1)
  if (rest != "" && rest !~ /^\//) return 0
  if (rest ~ /[$*?`~\[\034(){}]/) return 0
  ev_path = normalize(base rest)
  if (ev_path == "\001") return 0
  if (name in root_vars) ev_root_tail_path = normalize(rest)
  ev_ok = 1
  return 1
}

# normalize PATH : PATH with empty, . and .. segments folded, or \001 when it climbs above the root.
function normalize(path,   segments, count, i, kept, depth, out) {
  count = split(path, segments, "/")
  depth = 0
  for (i = 1; i <= count; i++) {
    if (segments[i] == "" || segments[i] == ".") continue
    if (segments[i] == "..") { if (depth == 0) return "\001"; depth--; continue }
    kept[++depth] = segments[i]
  }
  out = ""
  for (i = 1; i <= depth; i++) out = out (i > 1 ? "/" : "") kept[i]
  return out
}

# resolve_anchored TOKEN : the existing repo file anchored TOKEN names, or "" when it names none or, through a run-time
# variable set from another one, both of its two readings name existing files.
function resolve_anchored(token) {
  if (!eval_path(token)) return ""
  if (ev_root_tail_path == "") return (ev_path in exists) ? ev_path : ""
  if ((ev_path in exists) == (ev_root_tail_path in exists)) return ""
  return (ev_path in exists) ? ev_path : ev_root_tail_path
}

# is_claimed_script PATH : 1 when existing repo file PATH is one this extractor claims, by its .sh name or its shebang.
# An anchored path without .sh is only a call when it names such a script; any other file it names is data.
# A file that cannot be read goes in unreadable, since it may be a script and its call must not be dropped.
function is_claimed_script(path,   first_line, read_status) {
  if (path == "") return 0
  if (path ~ /\.sh$/) return 1
  if (!(path in shebang_checked)) {
    shebang_checked[path] = 1
    first_line = ""
    read_status = (getline first_line < path)
    if (read_status < 0) unreadable[path] = 1
    else if (read_status > 0 && first_line ~ shebang) has_shebang[path] = 1
    close(path)
  }
  return (path in has_shebang)
}

# split_commands TEXT COMMANDS OPENED : the count of commands TEXT holds, each put in COMMANDS without its leading
# keywords and variable assignments; OPENED[c] is 1 when command c starts inside `(` or `$(`.
# Quoted text is not a command, so single-quoted strings are dropped, and a quote left open starts a string that runs
# on past this line. An array assignment `=(` and an arithmetic `((...))` do not start a command.
function split_commands(text, commands, opened,   command_count, c) {
  gsub(/\047[^\047]*\047/, "", text)
  sub(/\047.*$/, "", text)
  gsub(/=\(/, "= ", text)
  gsub(/\(\([^()]*\)\)/, " ", text)
  gsub(/\$?\(/, ";\036", text)
  command_count = split(text, commands, /;|&&|\|\||\||&|`/)
  for (c = 1; c <= command_count; c++) {
    opened[c] = sub(/^\036/, "", commands[c])
    sub(/^[ \t{}]+/, "", commands[c])
    while (sub(/^(then|do|else|elif|if|while|until|exec|time|command|!)[ \t]+/, "", commands[c]) \
      || sub("^" var_name "=[^ \t]*[ \t]+", "", commands[c])) {}
  }
  return command_count
}

# report_cwd_relative_calls TEXT : prints an unresolved E record for each script TEXT runs by a path relative to the
# working directory (`./x`, `../x`, `bash x`, `sh x`), since that directory is only known at run time.
# A closing `)` does not start a command. Only a short-option cluster holding `c` (`-c`, `-ec`) makes bash read a
# command string; other options are skipped, with the value of those that take one.
# Every call found is reported, whatever its path holds, so a glob or an odd character is never dropped silently.
function report_cwd_relative_calls(text,   command_count, commands, opened, c, word_count, words, w, script) {
  command_count = split_commands(text, commands, opened)
  for (c = 1; c <= command_count; c++) {
    word_count = split(commands[c], words, /[ \t]+/)
    for (w = 1; w <= word_count; w++) {
      sub(/^\$?\(/, "", words[w])
      sub(/\)+$/, "", words[w])
    }
    script = ""
    if (words[1] ~ /^\.\.?\/[^\/]/) script = words[1]
    else if (words[1] == "bash" || words[1] == "sh") {
      for (w = 2; w <= word_count && words[w] ~ /^[-+]/; w++) {
        if (words[w] ~ /^-[^-]*c/) break
        if (words[w] ~ /^([-+][oO]|--rcfile|--init-file)$/) w++
      }
      if (w <= word_count && words[w] !~ /^[-$\/~]/ && (words[w] ~ /\// || words[w] ~ /\.sh$/)) script = words[w]
    }
    if (script != "") add_edge(script, 0)
  }
}

# unquoted_code TEXT : raw line TEXT with single-quoted strings and double-quoted strings holding a space or tab dropped,
# and the quotes of the other double-quoted strings removed. Quotes are paired left to right, and a string left open runs
# on into the next lines, kept in open_quote; quote_opened_before is 1 when TEXT starts inside such a string.
function unquoted_code(text,   out, span, span_carried, i, ch) {
  out = ""; span = ""
  quote_opened_before = (open_quote != "")
  span_carried = quote_opened_before
  for (i = 1; i <= length(text); i++) {
    ch = substr(text, i, 1)
    if (open_quote == "\047") {
      if (ch == "\047") open_quote = ""
    } else if (ch == "\\" && i < length(text)) {
      i++
      if (open_quote == "\"") span = span ch substr(text, i, 1)
      else out = out ch substr(text, i, 1)
    } else if (open_quote == "\"") {
      if (ch != "\"") span = span ch
      else {
        out = out ((span ~ /[ \t]/ || span_carried) ? " " : span)
        open_quote = ""; span = ""; span_carried = 0
      }
    } else if (ch == "\047" || ch == "\"") open_quote = ch
    else out = out ch
  }
  return out
}

# report_bare_relative_calls TEXT CONTINUED : prints an unresolved E record for each command of raw line TEXT that is a
# plain relative path with a folder and no leading `./` (`scripts/x.sh`), which also resolves against the working directory.
# Such words are common in prose and data, so only a plain path counts (no glob, trailing `/`, `:` or `,`); quoted text
# goes as unquoted_code says; a line CONTINUED from the one before, or one that starts inside a quoted string, does not
# start a command; and a word closed by `)` is a case pattern unless the command opened with `(`.
function report_bare_relative_calls(text, continued,   command_count, commands, opened, c, first_word) {
  text = strip_redirections(unquoted_code(text))
  command_count = split_commands(text, commands, opened)
  for (c = 1; c <= command_count; c++) {
    if (c == 1 && (continued || quote_opened_before)) continue
    first_word = commands[c]
    sub(/[ \t].*$/, "", first_word)
    if (first_word ~ /\)$/ && !opened[c]) continue
    sub(/\)+$/, "", first_word)
    if (first_word ~ /^[A-Za-z0-9_][A-Za-z0-9_.+-]*(\/[A-Za-z0-9_.+-]+)+$/) add_edge(first_word, 0)
  }
}

# add_edge TOKEN ANCHORED : prints the E record for TOKEN; a token without an anchor, or one whose two readings both
# name existing files, is unresolved.
function add_edge(token, anchored,   resolved) {
  resolved = anchored ? resolve_anchored(token) : ""
  if (resolved != "" && line ~ /^[ \t]*(source|\.)[ \t]/) sourced[resolved] = 1
  print "E\t" file "\t" FNR "\t" resolved "\t" restore_text(token)
}
'

# Each resolved target keeps its first line only; unresolved paths keep every line, since each is its own finding.
# shellcheck disable=SC2016 # $rows and friends are jq variables
graph_jq='
  split("\n") | map(select(length > 0) | split("\t")) as $rows
  | ([$rows[] | select(.[0] == "M") | .[1]] | unique) as $claimed
  | ($claimed | map({key: ., value: true}) | from_entries) as $is_claimed
  | ($rows | map(select(.[0] == "E") | {file: .[1], line: (.[2] | tonumber), resolved: .[3], module: .[4]})
      | group_by(.file) | map({key: .[0].file, value: .}) | from_entries) as $edges_by_file
  | {
      modules: [$claimed[] as $f | {
        source: $f,
        dependencies: (($edges_by_file[$f] // []) as $edges
          | ([$edges[] | select(.resolved != "")] | group_by(.resolved)
              | map(min_by(.line) | {module, resolved, line}))
            + ([$edges[] | select(.resolved == "")] | unique_by([.line, .module])
              | map({module, couldNotResolve: true, line}))
          | sort_by(.line, .module, .resolved // ""))
      }],
      exports: ([$rows[] | select(.[0] == "F" and $is_claimed[.[1]])] | group_by(.[1])
        | map({key: .[0][1], value: (map(.[2]) | unique)}) | from_entries)
    }'

{
  if [[ ${#candidates[@]} -gt 0 ]]; then
    awk -v existing="$existing_files" "$extract_awk" "${candidates[@]}" || die "awk failed reading the scope files"
  fi
} | jq -R -s "$graph_jq" || die "could not build the graph JSON"
