#!/usr/bin/env bash
# File: Shared script (host-neutral, not a hook): decide whether a sub-agent's file write or shell command stays inside its agent worktree.
# Purpose: One home for the worktree-confinement rule behind hooks/worktree-write-guard.sh (Claude) and hooks/codex-write-guard.sh (Codex)
#   (shared so each host hook stays a thin adapter). The orchestrator creates each agent worktree itself and, on Claude, launches the implementation agent without
#   `isolation` (the Agent tool has no working-directory input), so only the brief keeps the agent in its worktree. This check backs the brief:
#   parallel agents must not write into the main checkout or into each other's worktrees.
# Usage:
#   check-worktree-scope.sh --cwd <payload cwd> [--worktree-name <name>] [--confined] (--path <target>... | --command <shell command>)
#     --cwd            payload cwd; relative --path values resolve against it; also locates the main checkout (git rev-parse --git-common-dir).
#     --worktree-name  the agent worktree under .workflow/.worktrees/: s<NNN>_t<N> for a Phase 3 task, s<NNN>_phase_1_<work type> for a
#                      Phase 1 build, s<NNN>_integration_<work type> for an integration batch; on Codex any spawn task_name.
#     --confined       the caller knows the agent must be confined: with no confinement root, deny every path and command.
#     --path           a file the tool would write (repeatable).
#     --command        a Bash command the agent would run.
# Confinement root, first match wins:
#   1. --worktree-name given and <main checkout>/.workflow/.worktrees/<name> exists: that directory.
#   2. --cwd is inside a linked worktree (git-dir differs from git-common-dir; e.g. a Claude `isolation: "worktree"` launch): its top level.
#   3. Neither, or --cwd is outside any git repository: with --confined, deny every path and command, temp-dir writes and read-only
#      commands included, naming the cause (the agent worktree is missing, no name was given, or the cwd is not in a git repository);
#      without --confined, allow (nothing recorded to confine to).
# Rules:
#   path     deny when it lies inside the main checkout (which holds .workflow/.worktrees/ and .claude/worktrees/) but outside the root.
#            Paths outside the main checkout (a temp dir) are allowed. `.` and `..` are resolved, and symlinks through the deepest existing parent.
#   command  allow when --cwd is inside the root or outside the main checkout; otherwise the command must start with `cd <dir> &&` where <dir>
#            is a literal absolute path (quotes allowed) inside the root, as the implementation brief asks. A cd target with `$`, `~` or a
#            backtick cannot be checked and is denied. Accident prevention only: a command can still cd elsewhere later.
#            Read-only commands need no `cd`: a command made only of allowlisted reads joined by `|` or `&&` is allowed from anywhere.
#              Allowlist: cat, head, tail, grep, rg, ls, wc, find, yq, jq, `git log|show|diff|status`, and sed that only prints:
#                its options are -n (required), -E and -r, alone or combined (-nE), and -e SCRIPT; each script, given with -e or
#                else as the first operand, is one optional address or `a,b` range (a number, `$`, or `/re/` with no `/`, `\` or `[`
#                inside), an optional `!`, then `p`. Every sed word is plain or wholly quoted, with no backslash and, unquoted, no
#                glob or brace character (*?[]{}~). A `$` address must be single-quoted (`sed -n '$p' f`), as the quote scan below asks.
#              Denylist, per tool (the segment needs the `cd`): sed with anything else (s, w, W, e, r, a custom delimiter, -i, -f,
#              --in-place, ...); find -delete, -exec, -execdir, -ok, -okdir, -fprint*, -fls; yq -i, --inplace, -s, --split-exp;
#              jq -i; git --output; rg --pre.
#              Denylist, whole command: `<`, `>`, `;`, a lone `&` (so `|&` too), `||`, a newline, a carriage return, `tee`, an
#              empty segment; then a left-to-right quote scan denies a `$`, a backtick or a backslash outside single quotes (inside
#              double quotes too) and an unterminated quote. Inside single quotes `$` and a backtick are literal and pass.
#              Not a shell parser: only the `$`, backtick and backslash scan knows quotes. A `|`, `&&` or `;` inside quotes still
#              splits or denies, which only costs a needless `cd`.
# Outputs/handoff: exit 0 allow (reason on stdout); exit 2 deny (reason on stderr); exit 1 usage or environment error (adapters deny).
# Called by: hooks/worktree-write-guard.sh (Claude, Write/Edit/NotebookEdit and Bash), hooks/codex-write-guard.sh (Codex apply_patch paths).
# Sources: first-party.
# Requires: bash 3.2+, git.

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=check-worktree-scope.sh
usage_err() { echo "$PROG: $*" >&2; exit 1; }

cwd="" name="" command="" have_cmd=0 confined=0
paths=()
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) [ $# -ge 2 ] || usage_err "--cwd needs a value"; cwd=$2; shift 2 ;;
    --worktree-name) [ $# -ge 2 ] || usage_err "--worktree-name needs a value"; name=$2; shift 2 ;;
    --confined) confined=1; shift ;;
    --path) [ $# -ge 2 ] || usage_err "--path needs a value"; paths+=("$2"); shift 2 ;;
    --command) [ $# -ge 2 ] || usage_err "--command needs a value"; command=$2; have_cmd=1; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) usage_err "unknown argument: $1" ;;
  esac
done
[ -n "$cwd" ] || usage_err "missing --cwd"
[ -d "$cwd" ] || usage_err "--cwd is not a directory: $cwd"
if [ "$have_cmd" -eq 1 ]; then
  [ "${#paths[@]}" -eq 0 ] || usage_err "--path and --command are exclusive"
else
  [ "${#paths[@]}" -gt 0 ] || usage_err "need --path or --command"
fi
case "$name" in */*|.*) usage_err "--worktree-name must be a plain directory name: $name" ;; esac

# canon PATH : absolute, with . and .. resolved and symlinks resolved through the deepest existing ancestor.
canon() {
  local p=$1 out="" seg rest head tail
  [[ "$p" == /* ]] || p="$cwd/$p"
  # lexical pass over . and ..
  p="$p/"
  while [ -n "$p" ]; do
    seg=${p%%/*}
    p=${p#*/}
    case "$seg" in
      ''|.) ;;
      ..) out=${out%/*} ;;
      *) out="$out/$seg" ;;
    esac
  done
  [ -n "$out" ] || out=/
  # physical pass on the deepest existing directory
  head=$out tail=""
  while [ ! -d "$head" ]; do
    rest=${head##*/}
    tail="/$rest$tail"
    head=${head%/*}
    [ -n "$head" ] || head=/
  done
  head=$(cd -P "$head" && pwd)
  [ "$head" = / ] && head=""
  printf '%s%s\n' "$head" "$tail"
}

# under PATH ROOT : PATH is ROOT or inside it.
under() { [ "$1" = "$2" ] || [[ "$1" == "$2"/* ]]; }

# no_root CAUSE : with --confined, deny every call because no confinement root was found (CAUSE says why); otherwise allow.
no_root() {
  if [ "$confined" -eq 1 ]; then
    echo "worktree guard: this agent must work in its agent worktree, but none can be found: $1. Every call is denied, reads and writes outside the repository included, until the orchestrator creates the agent worktree and relaunches the agent." >&2
    exit 2
  fi
  echo "allow: no confinement: $1"
  exit 0
}

common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || no_root "the cwd $cwd is not in a git repository"
main_root=$(cd -P "$(dirname "$common")" && pwd)

root=""
if [ -n "$name" ] && [ -d "$main_root/$WF_WORKTREES/$name" ]; then
  root=$(cd -P "$main_root/$WF_WORKTREES/$name" && pwd)
else
  gd=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)
  if [ -n "$gd" ] && [ "$(cd -P "$gd" && pwd)" != "$(cd -P "$common" && pwd)" ]; then
    root=$(cd -P "$(git -C "$cwd" rev-parse --show-toplevel)" && pwd)
  fi
fi
if [ -z "$root" ]; then
  if [ -n "$name" ]; then
    no_root "$main_root/$WF_WORKTREES/$name does not exist and the cwd $cwd is not in a linked worktree"
  fi
  no_root "no agent worktree name was given and the cwd $cwd is not in a linked worktree"
fi

if [ "$have_cmd" -eq 0 ]; then
  bad=()
  for p in "${paths[@]}"; do
    c=$(canon "$p")
    if under "$c" "$main_root" && ! under "$c" "$root"; then bad+=("$p"); fi
  done
  if [ "${#bad[@]}" -gt 0 ]; then
    echo "worktree guard: this agent works only in its agent worktree $root; denied write outside it: ${bad[*]}. Use an absolute path inside $root; the main checkout and other agents' worktrees belong to the orchestrator and other agents." >&2
    exit 2
  fi
  echo "allow: inside $root or outside the main checkout"
  exit 0
fi

c=$(canon "$cwd")
if under "$c" "$root" || ! under "$c" "$main_root"; then
  echo "allow: cwd inside $root or outside the main checkout"
  exit 0
fi

# sed_print_only ARGS : true when ARGS, the words after `sed`, hold -n, print-only scripts and file operands, as the header's sed
#   allowlist describes; any other option or script means the sed call may write or run something.
sed_print_only() {
  local rest=$1 word value have_n=0 have_e=0 script_next=0 first_operand="" have_operand=0
  local re_word="^('[^']*'|\"[^\"\\\\]*\"|[^[:space:]'\"\\\\]+)(.*)\$"
  # BSD sed does not end a regex at a `/` inside a bracket expression, and `\/` ends none anywhere, so either would let a script hide
  #   a `w` command from this address pattern.
  local re_addr='([0-9]+|\$|/[^/\[]*/)'
  local re_print="^[[:space:]]*(${re_addr}(,${re_addr})?)?[[:space:]]*!?[[:space:]]*p[[:space:]]*\$"
  local re_quiet_flags='^-[nEr]+$' re_regex_flags='^-[Er]+$'
  while :; do
    rest=${rest#"${rest%%[![:space:]]*}"}
    [ -n "$rest" ] || break
    [[ "$rest" =~ $re_word ]] || return 1
    word=${BASH_REMATCH[1]} rest=${BASH_REMATCH[2]}
    [[ -z "$rest" || "$rest" == [[:space:]]* ]] || return 1
    case "$word" in
      \'*|\"*) value=${word:1:${#word}-2} ;;
      # The shell would expand these into words this check never sees, such as a file named -i that GNU sed reads as an option.
      *[]*?[{}~]*) return 1 ;;
      *) value=$word ;;
    esac
    if [ "$script_next" -eq 1 ]; then
      [[ "$value" =~ $re_print ]] || return 1
      script_next=0
      continue
    fi
    case "$value" in
      -e) have_e=1 script_next=1 ;;
      -*n*) [[ "$value" =~ $re_quiet_flags ]] || return 1; have_n=1 ;;
      -*) [[ "$value" =~ $re_regex_flags ]] || return 1 ;;
      *) [ "$have_operand" -eq 1 ] || first_operand=$value; have_operand=1 ;;
    esac
  done
  [ "$have_n" -eq 1 ] || return 1
  [ "$script_next" -eq 0 ] || return 1
  # With an -e script every operand is a file; without one the first operand is the script.
  [ "$have_e" -eq 1 ] || { [ "$have_operand" -eq 1 ] && [[ "$first_operand" =~ $re_print ]]; }
}

# read_only_segment SEGMENT : true when SEGMENT is one allowlisted read with none of the denylisted write or exec flags for its tool.
read_only_segment() {
  local re_split='^[[:space:]]*([^[:space:]]+)(.*)$'
  local re_git_read='^[[:space:]]+(log|show|diff|status)([[:space:]]|$)'
  local re_git_write='[[:space:]]--output([=[:space:]]|$)'
  local re_find_write='[[:space:]]-(delete|exec|execdir|ok|okdir|fprint[[:alnum:]]*|fls)([[:space:]]|$)'
  local re_yq_write='[[:space:]]-[[:alpha:]]*[is]|[[:space:]]--(inplace|split-exp)'
  local re_jq_write='[[:space:]]-[[:alpha:]]*i'
  local re_rg_exec='[[:space:]]--pre([=[:space:]]|$)'
  local tool args
  [[ "$1" =~ $re_split ]] || return 1
  tool=${BASH_REMATCH[1]} args=${BASH_REMATCH[2]}
  case "$tool" in
    cat|head|tail|grep|ls|wc) return 0 ;;
    rg) ! [[ "$args" =~ $re_rg_exec ]] ;;
    find) ! [[ "$args" =~ $re_find_write ]] ;;
    yq) ! [[ "$args" =~ $re_yq_write ]] ;;
    jq) ! [[ "$args" =~ $re_jq_write ]] ;;
    sed) sed_print_only "$args" ;;
    git) [[ "$args" =~ $re_git_read ]] && ! [[ "$args" =~ $re_git_write ]] ;;
    *) return 1 ;;
  esac
}

# expansions_only_single_quoted COMMAND : true when every `$` and backtick in COMMAND sits inside single quotes, no backslash sits
#   outside them, and every quote is closed. Double quotes are tracked so that a `'` inside them does not hide a `$(...)` after it.
expansions_only_single_quoted() {
  local rest=$1 unquoted quote quoted
  while :; do
    unquoted=${rest%%[\"\']*}
    case "$unquoted" in *'$'*|*'`'*|*\\*) return 1 ;; esac
    [ "$unquoted" != "$rest" ] || return 0
    quote=${rest:${#unquoted}:1}
    rest=${rest:${#unquoted}+1}
    case "$rest" in *"$quote"*) ;; *) return 1 ;; esac
    quoted=${rest%%"$quote"*}
    rest=${rest#*"$quote"}
    if [ "$quote" = '"' ]; then
      case "$quoted" in *'$'*|*'`'*|*\\*) return 1 ;; esac
    fi
  done
}

# read_only_chain COMMAND : true when COMMAND is only read_only_segment reads joined by `|` or `&&`, with no shell form that could
#   write, redirect or run something else.
read_only_chain() {
  local chain=$1 rest seg
  local re_tee='(^|[[:space:]|&])tee([[:space:]]|$)'
  # `<` covers `<(cmd)`, a process substitution that runs cmd, as well as an input redirect.
  case "$chain" in *'<'*|*'>'*|*';'*|*'||'*|*$'\n'*|*$'\r'*) return 1 ;; esac
  expansions_only_single_quoted "$chain" || return 1
  [[ "$chain" =~ $re_tee ]] && return 1
  chain=${chain//&&/|}
  # Runs after the && rewrite above, so any & left is a lone & (background or |&); checked earlier it would deny every && chain.
  case "$chain" in *'&'*) return 1 ;; esac
  # The trailing | is what ends the loop below: without it the last segment never empties rest and the guard hangs.
  rest="$chain|"
  while [ -n "$rest" ]; do
    seg=${rest%%|*}
    rest=${rest#*|}
    read_only_segment "$seg" || return 1
  done
}

if read_only_chain "$command"; then
  echo "allow: read-only command"
  exit 0
fi
re_dq='^[[:space:]]*cd[[:space:]]+"([^"]+)"[[:space:]]*&&'
re_sq="^[[:space:]]*cd[[:space:]]+'([^']+)'[[:space:]]*&&"
re_bare='^[[:space:]]*cd[[:space:]]+([^[:space:]&;|"'"'"']+)[[:space:]]*&&'
target=""
if [[ "$command" =~ $re_dq ]] || [[ "$command" =~ $re_sq ]] || [[ "$command" =~ $re_bare ]]; then
  target=${BASH_REMATCH[1]}
fi
deny_cmd() {
  echo "worktree guard: this agent works only in its agent worktree $root, and this shell starts in $cwd. $1 Start the command with: cd $root && <command>" >&2
  exit 2
}
[ -n "$target" ] || deny_cmd "The command does not start with \`cd <worktree> &&\`."
case "$target" in *'$'*|*'`'*|'~'*) deny_cmd "The cd target '$target' is not a literal path." ;; esac
[[ "$target" == /* ]] || deny_cmd "The cd target '$target' is not an absolute path."
tc=$(canon "$target")
under "$tc" "$root" || deny_cmd "The cd target '$target' is outside the worktree."
echo "allow: command runs in $tc"
exit 0
