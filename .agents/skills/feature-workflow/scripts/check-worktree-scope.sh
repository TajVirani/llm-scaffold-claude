#!/usr/bin/env bash
# File: Shared script (host-neutral, not a hook): decide whether a sub-agent's file write or shell command stays inside its task worktree.
# Purpose: One home for the worktree-confinement rule behind hooks/worktree-write-guard.sh (Claude) and hooks/codex-write-guard.sh (Codex)
#   (shared so each host hook stays a thin adapter). The orchestrator creates each task worktree itself and, on Claude, launches the implementation agent without
#   `isolation` (the Agent tool has no working-directory input), so only the brief keeps the agent in its worktree. This check backs the brief:
#   parallel agents must not write into the main checkout or into each other's worktrees.
# Usage:
#   check-worktree-scope.sh --cwd <payload cwd> [--worktree-name <name>] (--path <target>... | --command <shell command>)
#     --cwd            payload cwd; relative --path values resolve against it; also locates the main checkout (git rev-parse --git-common-dir).
#     --worktree-name  the agent's worktree under .workflow/.worktrees/ (s<NNN>_t<N> for a Phase 3 task; on Codex any spawn task_name).
#     --path           a file the tool would write (repeatable).
#     --command        a Bash command the agent would run.
# Confinement root, first match wins:
#   1. --worktree-name given and <main checkout>/.workflow/.worktrees/<name> exists: that directory.
#   2. --cwd is inside a linked worktree (git-dir differs from git-common-dir; e.g. a Claude `isolation: "worktree"` launch): its top level.
#   3. Neither: no confinement, allow (nothing recorded to confine to).
# Rules:
#   path     deny when it lies inside the main checkout (which holds .workflow/.worktrees/ and .claude/worktrees/) but outside the root.
#            Paths outside the main checkout (a temp dir) are allowed. `.` and `..` are resolved, and symlinks through the deepest existing parent.
#   command  allow when --cwd is inside the root or outside the main checkout; otherwise the command must start with `cd <dir> &&` where <dir>
#            is a literal absolute path (quotes allowed) inside the root, as the implementation brief asks. A cd target with `$`, `~` or a
#            backtick cannot be checked and is denied. Accident prevention only: a command can still cd elsewhere later.
# Outputs/handoff: exit 0 allow (reason on stdout); exit 2 deny (reason on stderr); exit 1 usage or environment error (adapters deny).
# Called by: hooks/worktree-write-guard.sh (Claude, Write/Edit/NotebookEdit and Bash), hooks/codex-write-guard.sh (Codex apply_patch paths).
# Sources: first-party.
# Requires: bash 3.2+, git.

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=check-worktree-scope.sh
usage_err() { echo "$PROG: $*" >&2; exit 1; }

cwd="" name="" command="" have_cmd=0
paths=()
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) [ $# -ge 2 ] || usage_err "--cwd needs a value"; cwd=$2; shift 2 ;;
    --worktree-name) [ $# -ge 2 ] || usage_err "--worktree-name needs a value"; name=$2; shift 2 ;;
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

common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { echo "allow: --cwd is not in a git repository"; exit 0; }
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
  echo "allow: no task worktree recorded${name:+ ($WF_WORKTREES/$name does not exist)} and the agent is not in a linked worktree"
  exit 0
fi

if [ "$have_cmd" -eq 0 ]; then
  bad=()
  for p in "${paths[@]}"; do
    c=$(canon "$p")
    if under "$c" "$main_root" && ! under "$c" "$root"; then bad+=("$p"); fi
  done
  if [ "${#bad[@]}" -gt 0 ]; then
    echo "worktree guard: this agent works only in its task worktree $root; denied write outside it: ${bad[*]}. Use an absolute path inside $root; the main checkout and other tasks' worktrees belong to the orchestrator and other agents." >&2
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
re_dq='^[[:space:]]*cd[[:space:]]+"([^"]+)"[[:space:]]*&&'
re_sq="^[[:space:]]*cd[[:space:]]+'([^']+)'[[:space:]]*&&"
re_bare='^[[:space:]]*cd[[:space:]]+([^[:space:]&;|"'"'"']+)[[:space:]]*&&'
target=""
if [[ "$command" =~ $re_dq ]] || [[ "$command" =~ $re_sq ]] || [[ "$command" =~ $re_bare ]]; then
  target=${BASH_REMATCH[1]}
fi
deny_cmd() {
  echo "worktree guard: this agent works only in its task worktree $root, and this shell starts in $cwd. $1 Start the command with: cd $root && <command>" >&2
  exit 2
}
[ -n "$target" ] || deny_cmd "The command does not start with \`cd <worktree> &&\`."
case "$target" in *'$'*|*'`'*|'~'*) deny_cmd "The cd target '$target' is not a literal path." ;; esac
[[ "$target" == /* ]] || deny_cmd "The cd target '$target' is not an absolute path."
tc=$(canon "$target")
under "$tc" "$root" || deny_cmd "The cd target '$target' is outside the worktree."
echo "allow: command runs in $tc"
exit 0
