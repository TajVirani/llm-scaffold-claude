#!/usr/bin/env bash
# block-destructive-git.sh
# PreToolUse hook (Claude Code `Bash`, Codex `Bash`): denies destructive git commands before they run.
# Reads the hook JSON on stdin, takes tool_input.command (a string; an argv array is shell-quoted and joined), splits it
# into simple commands the way a shell would, and checks each `git` invocation's subcommand and options. Text that is only
# data is not a command, so a heredoc body, a quoted argument or a comment that mentions `git reset --hard` is allowed.
# Text that a shell will run is inspected too: `$(...)` and backquotes, `bash|sh|zsh|dash|ksh -c STRING`, `eval ARGS`,
# and a heredoc or here-string fed to one of those shells.
#
# Blocked (each also inside `&&`, `||`, `;`, `|`, `( )`, newlines, and after `sudo`/`env`/`command`/`exec`/`nohup`/
# `time`/`nice`/`timeout` and VAR=value prefixes, and with git global options such as `-C dir`, `-c k=v`, `--no-pager`):
#   git stash ...            every form except `git stash list` and `git stash show`
#   git reset --hard
#   git checkout             with `-f`/`--force`/`--discard-changes`, any pathspec after `--`, or a path argument starting
#                            with `.` (`.`, `./src`, `../x`; git forbids ref names starting with `.`)
#   git switch               with `-f`/`--force`/`--discard-changes`
#   git restore ...          every form
#   git clean ...            every form except a dry run (`-n`/`--dry-run`)
#   git push                 with `-f`/`--force`/`--force-with-lease`/`--force-if-includes`, `--mirror`, `-d`/`--delete`,
#                            `--prune`, or a `+refspec` (force) or `:refspec` (delete). Plain `git push` is allowed.
#   git branch               with `-D`, or delete plus force (`-d -f`, `--delete --force`, `-df`)
#   git rebase ...           every form (rewrites history)
#   git filter-branch, git filter-repo
#   git reflog expire|delete (destroys the recovery log)
# Not inspected: text piped into a shell (`... | bash`), script files a shell runs, git aliases, and commands built at
# run time from variables. This is a guard against mistakes, not a sandbox.
#
# Output: the PreToolUse deny shape {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",
# "permissionDecisionReason":...}} on stdout, exit 0; Codex's PreToolUse reads the same shape. Silent exit 0 otherwise.
# A command the tokenizer cannot read is denied when it mentions git (fail closed).
#
# Sources: first-party, adapted from mattpocock/skills `skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh`
# at 49dd158 (MIT, Copyright (c) 2026 Matt Pocock; blocked-command list, which this script extends, except that plain
# `git push` stays allowed), and the earlier first-party version of this script (stash rule, deny JSON, reason text).
# The upstream matches raw text with grep; the tokenizer and per-subcommand rules here are new. bash 3.2 compatible.

set -uo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '(.tool_input.command // "") | if type == "array" then map(@sh) | join(" ") else tostring end' 2>/dev/null) || COMMAND=""

[ -n "$COMMAND" ] || exit 0

deny() {
  jq -n --arg why "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
    permissionDecisionReason: ("BLOCKED: Destructive git command detected: " + $why + ". Destructive git commands are FORBIDDEN. You previously destroyed a week of uncommitted work with git stash pop. NEVER run git stash (other than list/show), git reset --hard, git checkout -- <paths> / git checkout ., git switch --discard-changes, git restore, git clean, git push --force / --force-with-lease / --delete / +refspec, git branch -D, git rebase, git filter-branch / filter-repo, or git reflog expire/delete. If you need to check something against a clean state, ask the USER to do it or use a worktree.")}}'
  exit 0
}

# ── Tokenizer ──────────────────────────────────────────────────────────
# Prints one simple command per line, words separated by \037, starting at the real command word (assignments and
# wrappers stripped). Shell code nested in the command ($(...), backquotes, sh -c, eval, heredocs fed to a shell) is
# queued and printed as further commands.
# shellcheck disable=SC2016  # awk program, not shell
TOKENIZER='
function flushword() {
  if (!inw) return
  if (redir) { redir = 0 }
  else if (herenext) { hstr = hstr cur "\n"; herenext = 0 }
  else { W[NW++] = cur }
  cur = ""; inw = 0
}
function push(s) { if (qn < 256) Q[qn++] = s }
function isshell(b) { return b == "bash" || b == "sh" || b == "zsh" || b == "dash" || b == "ksh" }
function base(p) { sub(/.*\//, "", p); return p }
function endcmd(   k, c, b, j, out, hasc, a, wrap) {
  flushword()
  k = 0
  # Skip keywords, assignments and wrapper commands (with their options).
  while (k < NW) {
    c = W[k]; b = base(c)
    if (c ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || c == "!" || c == "{" || c == "}" || c == "if" || c == "then" || c == "elif" || \
        c == "else" || c == "do" || c == "while" || c == "until" || c == "time" || c == "builtin") { k++; continue }
    if (b == "sudo" || b == "env" || b == "command" || b == "exec" || b == "nohup" || b == "nice" || b == "timeout" || \
        b == "xargs") {
      wrap = b; k++
      while (k < NW && (W[k] ~ /^-/ || W[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/)) {
        if ((wrap == "sudo" && W[k] ~ /^-[ugCDhpRT]$/) || (wrap == "env" && W[k] ~ /^-[uCS]$/) || (wrap == "nice" && W[k] == "-n") || \
            (wrap == "timeout" && W[k] ~ /^-[sk]$/) || (wrap == "xargs" && W[k] ~ /^-[IinPLsdEJR]$/)) k++
        k++
      }
      if (wrap == "timeout" && k < NW) k++
      continue
    }
    break
  }
  if (k < NW) {
    b = base(W[k])
    if (isshell(b)) {
      hasc = 0
      for (j = k + 1; j < NW; j++) {
        a = W[j]
        if (hasc) { push(a); break }
        if (a == "--") break
        if (a ~ /^-[A-Za-z]*c[A-Za-z]*$/) { hasc = 1; continue }
        if (a ~ /^[-+]/) { if (a == "-o" || a == "+o" || a == "-O" || a == "+O") j++; continue }
        break
      }
      if (!hasc && j >= NW) { ISSH[cmdno] = 1; if (hstr != "") push(hstr) }
    } else if (b == "eval") {
      out = ""
      for (j = k + 1; j < NW; j++) out = out (out == "" ? "" : " ") W[j]
      if (out != "") push(out)
    }
    out = ""
    for (j = k; j < NW; j++) { a = W[j]; gsub(/\n/, " ", a); out = out (j > k ? "\037" : "") a }
    print out
  }
  NW = 0; hstr = ""; herenext = 0; redir = 0; cmdno++
}
# capture(s, i, op, cl): index of the cl matching the op at s[i] (or length+1), skipping single quotes.
function capture(s, i, op, cl,   d, c, n) {
  n = length(s); d = 0
  for (; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") { i++; continue }
    if (c == "'\''") { i++; while (i <= n && substr(s, i, 1) != "'\''") i++; continue }
    if (c == op) { d++; continue }
    if (c == cl) { d--; if (d <= 0) return i; continue }
  }
  return n + 1
}
function dollar(s, i,   j, c2) {   # at s[i] == "$"; returns the last index consumed
  c2 = substr(s, i + 1, 1)
  if (c2 == "(") { j = capture(s, i + 1, "(", ")"); push(substr(s, i + 2, j - i - 2)); cur = cur "SUBST"; inw = 1; return j }
  if (c2 == "{") { j = capture(s, i + 1, "{", "}"); cur = cur substr(s, i, j - i + 1); inw = 1; return j }
  cur = cur "$"; inw = 1; return i
}
function backq(s, i,   j, n) {
  n = length(s)
  for (j = i + 1; j <= n && substr(s, j, 1) != "`"; j++) if (substr(s, j, 1) == "\\") j++
  push(substr(s, i + 1, j - i - 1)); cur = cur "SUBST"; inw = 1; return j
}
function heredocs(s, i,   n, k, line, j, body, d, strip, done) {   # s[i] is a newline; read pending bodies, return last index
  n = length(s)
  for (k = 0; k < HDN; k++) {
    d = HD[k]; strip = HDS[k]; body = ""; done = 0
    while (i < n && !done) {
      j = index(substr(s, i + 1), "\n")
      if (j == 0) { line = substr(s, i + 1); i = n } else { line = substr(s, i + 1, j - 1); i = i + j }
      if (strip) sub(/^\t+/, "", line)
      if (line == d) done = 1; else body = body line "\n"
    }
    if (ISSH[HDO[k]]) push(body)
  }
  HDN = 0
  return i
}
function parse(s,   n, i, c, c2, d, strip, q) {
  n = length(s); NW = 0; cur = ""; inw = 0; hstr = ""; herenext = 0; redir = 0; HDN = 0
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1); c2 = substr(s, i + 1, 1)
    if (c == "\\") { if (c2 == "\n") { i++; continue } cur = cur c2; inw = 1; i++; continue }
    if (c == "'\''") {
      inw = 1; i++
      while (i <= n && substr(s, i, 1) != "'\''") { cur = cur substr(s, i, 1); i++ }
      continue
    }
    if (c == "\"") {
      inw = 1; i++
      while (i <= n && substr(s, i, 1) != "\"") {
        c = substr(s, i, 1)
        if (c == "\\") { c2 = substr(s, i + 1, 1); if (c2 ~ /[$`"\\\n]/) { if (c2 != "\n") cur = cur c2; i += 2; continue } }
        if (c == "$") { i = dollar(s, i) + 1; continue }
        if (c == "`") { i = backq(s, i) + 1; continue }
        cur = cur c; i++
      }
      continue
    }
    if (c == "$") { i = dollar(s, i); continue }
    if (c == "`") { i = backq(s, i); continue }
    if (c == "#" && !inw) { while (i < n && substr(s, i + 1, 1) != "\n") i++; continue }
    if (c == " " || c == "\t") { flushword(); continue }
    if (c == "\n") { endcmd(); if (HDN > 0) i = heredocs(s, i); continue }
    if (c == "<" && c2 == "<") {
      if (inw && cur ~ /^[0-9]+$/) { cur = ""; inw = 0 } else flushword()
      if (substr(s, i + 2, 1) == "<") { i += 2; herenext = 1; continue }
      i += 2; strip = 0
      if (substr(s, i, 1) == "-") { strip = 1; i++ }
      while (substr(s, i, 1) == " " || substr(s, i, 1) == "\t") i++
      d = ""; q = ""
      while (i <= n) {
        c = substr(s, i, 1)
        if (q != "") { if (c == q) q = ""; else d = d c; i++; continue }
        if (c == "'\''" || c == "\"") { q = c; i++; continue }
        if (c == "\\") { d = d substr(s, i + 1, 1); i += 2; continue }
        if (c ~ /[ \t\n;&|<>()]/) break
        d = d c; i++
      }
      HD[HDN] = d; HDS[HDN] = strip; HDO[HDN] = cmdno; HDN++
      i--
      continue
    }
    if (c == "<" || c == ">" || (c == "&" && c2 == ">")) {
      if (inw && cur ~ /^[0-9]+$/) { cur = ""; inw = 0 } else flushword()
      while (substr(s, i + 1, 1) ~ /[<>&|]/) i++
      redir = 1
      continue
    }
    if (c == ";" || c == "&" || c == "|" || c == "(" || c == ")") { endcmd(); continue }
    cur = cur c; inw = 1
  }
  endcmd()
}
BEGIN {
  s = ""; first = 1
  while ((getline line) > 0) { s = s (first ? "" : "\n") line; first = 0 }
  qn = 0; cmdno = 0; push(s)
  for (qi = 0; qi < qn; qi++) parse(Q[qi])
}
'

if ! CMDS=$(printf '%s' "$COMMAND" | awk "$TOKENIZER" 2>/dev/null); then
  case "$COMMAND" in *git*) deny "could not parse the command; it mentions git" ;; esac
  exit 0
fi

# ── Rules ──────────────────────────────────────────────────────────────

# short_has LETTERS ARG : ARG is a short-option cluster (-xyz) containing one of LETTERS.
short_has() {
  case "$2" in --* | -) return 1 ;; -*) ;; *) return 1 ;; esac
  case "${2#-}" in *["$1"]*) return 0 ;; esac
  return 1
}

# check_git SUBCOMMAND ARGS... : prints the blocked form, or nothing.
check_git() {
  local sub=$1 a first="" dashdash=0 del=0 force=0 dry=0
  shift
  case "$sub" in
    rebase) echo "git rebase"; return ;;
    restore) echo "git restore (discard changes)"; return ;;
    filter-branch | filter-repo) echo "git $sub (rewrites history)"; return ;;
    stash)
      [ $# -gt 0 ] && first=$1
      case "$first" in list | show) return ;; esac
      echo "git stash${first:+ $first} (only 'git stash list' and 'git stash show' are allowed)"
      return ;;
    reflog)
      case "${1:-}" in expire | delete) echo "git reflog $1" ;; esac
      return ;;
  esac
  for a in "$@"; do
    if [ "$dashdash" = 1 ]; then
      [ "$sub" = checkout ] && { echo "git checkout -- <paths> (discard working tree)"; return; }
      continue
    fi
    case "$sub:$a" in
      *:--) dashdash=1 ;;
      reset:--hard) echo "git reset --hard"; return ;;
      checkout:-f | checkout:--force | checkout:--discard-changes) echo "git checkout $a (discard working tree)"; return ;;
      checkout:.*) echo "git checkout $a (discard working tree)"; return ;;
      switch:-f | switch:--force | switch:--discard-changes) echo "git switch $a (discard working tree)"; return ;;
      clean:-n | clean:--dry-run) dry=1 ;;
      clean:-*) short_has n "$a" && dry=1 ;;
      push:--force* | push:--mirror | push:--delete | push:--prune) echo "git push $a"; return ;;
      push:+*) echo "git push $a (force refspec)"; return ;;
      push::*) echo "git push $a (delete refspec)"; return ;;
      push:-*) if short_has fd "$a"; then echo "git push $a"; return; fi ;;
      branch:-D | branch:--delete) [ "$a" = -D ] && { echo "git branch -D (force delete)"; return; }; del=1 ;;
      branch:--force) force=1 ;;
      branch:-*)
        short_has D "$a" && { echo "git branch $a (force delete)"; return; }
        short_has d "$a" && del=1
        short_has f "$a" && force=1 ;;
    esac
  done
  case "$sub" in
    clean) [ "$dry" = 1 ] || echo "git clean (remove untracked files; only -n/--dry-run is allowed)" ;;
    branch) [ "$del" = 1 ] && [ "$force" = 1 ] && echo "git branch --delete --force (force delete)" ;;
  esac
  return 0
}

while IFS= read -r line; do
  [ -n "$line" ] || continue
  words=()
  IFS=$'\037' read -r -a words <<<"$line"
  [ "${#words[@]}" -gt 0 ] || continue
  [ "${words[0]##*/}" = git ] || continue
  i=1
  n=${#words[@]}
  while [ "$i" -lt "$n" ]; do
    case "${words[$i]}" in
      -C | -c | --git-dir | --work-tree | --namespace | --super-prefix | --config-env) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  [ "$i" -lt "$n" ] || continue
  why=$(check_git "${words[@]:$i}")
  [ -z "$why" ] || deny "$why"
done <<<"$CMDS"

exit 0
