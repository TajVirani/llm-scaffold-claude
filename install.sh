#!/usr/bin/env bash
# File: Scaffold install script (scaffold-only; not part of the .agents/ payload). Lives at the repo root, next to the payload it copies.
# Usage:
#   ./install.sh <target-dir> [--host claude|codex|all] [--force] [--dry-run] [--matchers=merge|replace|keep]
#     <target-dir>  top level of a git repository (the target project)
#     --host        which host shims to set up (default: all)
#     --force       replace conflicting shim entries instead of refusing (see "Conflicts" below); hook matchers are not changed by it
#     --dry-run     print what would change and write nothing; asks nothing
#     --matchers    how to resolve each hook group whose matcher differs from the template's (see "Hook matchers" below):
#                   merge, replace or keep, for every group without asking. Without it, install.sh asks per group when stdin
#                   and stdout are a terminal; without a terminal it merges and warns, but keeps a mixed group or a matcher
#                   that is not a plain | list, with a warning.
# What it does:
#   1. Preflight: bash 3.2+, git, jq, mikefarah yq v4; the target is the top level of a git work tree.
#   2. Payload: copies every file named by .agents/install-manifest.txt (first-party only; vendored skills,
#      kept only while being rewritten, never ship) into <target>/.agents/. .agents/ is scaffold-owned: changed files are overwritten, and files the previous
#      install shipped (listed in <target>/.agents/VERSION) that are no longer in the manifest are removed. Files in
#      <target>/.agents/ that no install shipped (for example the data-structure-audit state file) are left alone.
#      Writes <target>/.agents/VERSION: scaffold version, commit, install date and the installed file list. The
#      VERSION file is rewritten only when the version or file list changes, so a re-run changes nothing.
#   3. Claude, --host claude|all: <target>/.claude/{skills,agents,output-styles} symlinks to ../.agents/<dir>, and
#      .agents/hooks/claude-settings.template.json merged into <target>/.claude/settings.json:
#      hook commands missing under an event appended in the template's group, a differing matcher on an existing group
#      resolved as "Hook matchers" says, permissions.deny unioned, user keys kept,
#      a different user outputStyle or statusLine kept with a warning.
#   4. Codex, --host codex|all: runs generate-codex-agents.sh in the target (.codex/agents/*.toml),
#      merges codex-hooks.template.json into .codex/hooks.json (same hook and matcher rules) and codex-config.template.toml into
#      .codex/config.toml. yq v4 reads TOML but cannot write tables, so the
#      config is edited through marker blocks that later runs refresh in place; user text outside them is never rewritten.
#      The tui block sets the built-in Codex status line; a [tui] table the user already has is kept with a warning.
#   5. <target>/.gitignore: .workflow/specs/*/.step, .workflow/.cache-staging/, .workflow/.worktrees/, .workflow/.handoff/ and
#      .workflow/.standards-staging/ in a marker block, since they hold local, in-progress state. Paths come from .agents/lib/workflow-paths.sh.
#   Never creates or touches .workflow/: every project-owned file (GLOSSARY.md, rules.md, agent-overrides.yaml, model-map/,
#   profiles/, decisions/, deferred/, specs/, ...) lives there and is created by the project-setup skill; nor the project's own docs/ and e2e/.
#   Scaffold-only files (PLAN/, tests/, assetlist.md, checklist.md, PROVENANCE.md, CHANGELOG.md, upstream-lineage.json, scripts/,
#   wayfinder-comparison.html, testprompt.md, the scaffold repo's own .workflow/, this script) are outside .agents/ and never copied.
# Hook matchers: on every hook event, an existing group that runs a command of a template group under a matcher that does
#   not cover the template's (its | alternatives do not include all of the template's) is resolved on its own. A match-all
#   group (no matcher, "" or "*") is never touched, and a covering one is left as is, so a re-run asks nothing.
#   merge: the group's alternatives in order, then the template's missing ones (implementation|foo with
#     implementation|integration gives implementation|foo|integration); only when the group's matcher is a plain | list
#     ([A-Za-z0-9_|]) and the template's is one too or matches all. Any other group is kept with a warning, whatever the
#     template's matcher.
#   replace: the template's matcher. A match-all template matcher makes replace drop the matcher, and merge too for a
#     plain | list.
#   keep: the group stays as it is, with a warning.
#   A group that runs commands of two or more template groups of one event is never asked about, whatever the mode:
#   when all its hooks are template commands it is rewritten into the template's groups, each command under its template
#   group's matcher; when it also runs a hook of your own it is kept as it is. Either way a warning names it.
#   --matchers sets the mode for every group. Otherwise, at a terminal (stdin and stdout), install.sh asks per group once
#   it knows the run will not refuse, naming the event and the scaffold command and showing the current, replace and
#   merge matchers (and every hook of a mixed group); Enter merges, r replaces, k keeps. Without a terminal it never
#   reads input: it merges with a warning, but keeps with a warning a mixed group (one that also runs a hook not in the
#   template) and a matcher that is not a plain | list. --dry-run never asks and previews the no-terminal outcome, or the
#   --matchers mode when given.
# Conflicts: every check runs before anything is written. Without --force, install.sh refuses (exit 1, nothing written) when
#   .claude/{skills,agents,output-styles} is a real directory or a symlink elsewhere, a settings/hooks key has the wrong type or
#   a different value, .codex/config.toml has a different [permissions.workflow], or a marker block is damaged. With --force
#   a real directory is moved aside to <name>.backup-<timestamp>, a wrong symlink is replaced, conflicting JSON keys take the
#   template value, outputStyle, statusLine and default_permissions are overwritten, and a hand-written [permissions.workflow] that
#   differs is left as is with a warning (it cannot be rewritten safely). --force does not change hook matchers: they follow
#   "Hook matchers". Unparseable JSON or TOML always refuses.
# Exit: 0 installed (or dry-run clean); 1 refused because of a conflict; 2 usage or preflight error (including a --matchers
#   value other than merge, replace or keep).
# Run it outside a Codex session. Tests: tests/scripts/install-*.sh (payload, hosts, upgrade with hook matcher resolution,
#   claude-settings, codex-config, codex-tui) and tests/lint/install-matcher-docs.sh (these docs).

set -euo pipefail
export LC_ALL=C

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
SRC=$SELF_DIR/.agents
MANIFEST=$SRC/install-manifest.txt
CLAUDE_TPL=$SRC/hooks/claude-settings.template.json
CODEX_HOOKS_TPL=$SRC/hooks/codex-hooks.template.json
CODEX_CONFIG_TPL=$SRC/hooks/codex-config.template.toml
# shellcheck source=.agents/lib/workflow-paths.sh
. "$SRC/lib/workflow-paths.sh"
GI_ENTRIES=("$WF_SPECS/*/.step" "$WF_INITIATIVES/*/.step" "$WF_CACHE_STAGING/" "$WF_WORKTREES/" "$WF_HANDOFF/" "$WF_STANDARDS_STAGING/")
SHIM_DIRS="skills agents output-styles"

die() { echo "install.sh: error: $*" >&2; exit 2; }
usage() { sed -n '/^# Usage:/,/^# What it does:/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'; }

target=""
host=all
force=0
dry=0
matchers=""
matchers_given=0
while [ $# -gt 0 ]; do
  case "$1" in
    --host)
      [ $# -ge 2 ] || die "--host needs a value (claude, codex or all)"
      host=$2
      shift
      ;;
    --host=*) host=${1#--host=} ;;
    --force) force=1 ;;
    --dry-run) dry=1 ;;
    --matchers)
      [ $# -ge 2 ] || die "--matchers needs a value (merge, replace or keep)"
      matchers=$2
      matchers_given=1
      shift
      ;;
    --matchers=*) matchers=${1#--matchers=}; matchers_given=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *)
      [ -z "$target" ] || die "more than one target given: $target, $1"
      target=$1
      ;;
  esac
  shift
done
[ -n "$target" ] || { usage >&2; exit 2; }
case "$host" in claude | codex | all) ;; *) die "--host must be claude, codex or all (got: $host)" ;; esac
if [ "$matchers_given" -eq 1 ] && [ -z "$matchers" ]; then die "--matchers needs a value (merge, replace or keep), got an empty one"; fi
case "$matchers" in "" | merge | replace | keep) ;; *) die "--matchers must be merge, replace or keep (got: $matchers)" ;; esac
# How a hook group whose matcher differs from the template's is resolved: the --matchers mode, "ask" at a terminal, or
# "auto" (merge a plain, template-only group; keep any other, with a warning). A dry run never asks, so it previews "auto".
matcher_mode=$matchers
if [ -z "$matcher_mode" ]; then
  if [ "$dry" -eq 0 ] && [ -t 0 ] && [ -t 1 ]; then matcher_mode=ask; else matcher_mode=auto; fi
fi
want_claude=0
want_codex=0
case "$host" in claude) want_claude=1 ;; codex) want_codex=1 ;; all) want_claude=1; want_codex=1 ;; esac

# ---------------------------------------------------------------------------------------------------------------- preflight
missing=0
if [ "${BASH_VERSINFO[0]}" -lt 3 ] || { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
  echo "install.sh: bash 3.2 or newer required (found $BASH_VERSION)" >&2
  missing=1
fi
command -v git >/dev/null 2>&1 || { echo "install.sh: git not found on PATH (https://git-scm.com/downloads)" >&2; missing=1; }
command -v jq >/dev/null 2>&1 || { echo "install.sh: jq not found on PATH (brew install jq, apt install jq)" >&2; missing=1; }
if ! command -v yq >/dev/null 2>&1; then
  echo "install.sh: yq not found on PATH; install mikefarah yq v4 (brew install yq, or https://github.com/mikefarah/yq/releases)" >&2
  missing=1
else
  case "$(yq --version 2>&1)" in
    *mikefarah*version\ v4.* | *mikefarah*version\ 4.*) ;;
    *) echo "install.sh: yq is not mikefarah yq v4 (got: $(yq --version 2>&1 | head -n 1)); the Python yq is not supported" >&2; missing=1 ;;
  esac
fi
[ "$missing" -eq 0 ] || exit 2

[ -f "$MANIFEST" ] || die "manifest not found: $MANIFEST"
[ -d "$target" ] || die "target is not a directory: $target"
T=$(cd "$target" && pwd -P)
top=$(git -C "$T" rev-parse --show-toplevel 2>/dev/null) || die "target is not a git repository: $T (run git init first)"
top=$(cd "$top" && pwd -P)
[ "$top" = "$T" ] || die "target must be the top level of its git repository ($top), not a sub-directory: $T"
[ "$T" != "$SELF_DIR" ] || die "target is the scaffold repo itself"
[ ! -L "$T/.agents" ] || die "$T/.agents is a symlink; install copies the payload and will not write through a link"
[ ! -e "$T/.agents" ] || [ -d "$T/.agents" ] || die "$T/.agents exists and is not a directory"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/scaffold-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

REFUSALS=()
WARNINGS=()
refuse() { REFUSALS+=("$1"); }
warn() { WARNINGS+=("$1"); }

# ------------------------------------------------------------------------------------------------------------ the manifest
# expand_manifest: print every payload file (path relative to .agents/), one per line.
expand_manifest() {
  local line m
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$line" in '' | '#'*) continue ;; esac
    case "$line" in
      /* | ../* | */../* | */.. | ..) die "manifest: path must stay inside .agents/: $line" ;;
    esac
    local found=0
    case "$line" in
      *[\*\?\[]*)
        # Glob line: expand relative to .agents/.
        for m in $(cd "$SRC" && eval "printf '%s\n' $line"); do
          if [ -d "$SRC/$m" ]; then
            (cd "$SRC" && find "$m" -type f ! -name .DS_Store)
            found=1
          elif [ -f "$SRC/$m" ]; then
            printf '%s\n' "$m"
            found=1
          fi
        done
        ;;
      *)
        if [ -d "$SRC/$line" ]; then
          (cd "$SRC" && find "$line" -type f ! -name .DS_Store)
          found=1
        elif [ -f "$SRC/$line" ]; then
          printf '%s\n' "$line"
          found=1
        fi
        ;;
    esac
    [ "$found" -eq 1 ] || die "manifest: no file matches '$line' (update .agents/install-manifest.txt)"
  done <"$MANIFEST"
}
expand_manifest | sed 's|/\{2,\}|/|g; s|^\./||' | sort -u >"$tmp/new.files"
[ -s "$tmp/new.files" ] || die "manifest names no files"

# The previous install's file list (empty for a fresh install or a pre-manifest one).
STAMP=$T/.agents/VERSION
: >"$tmp/old.files"
if [ -f "$STAMP" ]; then
  awk 'f { print } /^files:[[:space:]]*$/ { f = 1 }' "$STAMP" | sed '/^[[:space:]]*$/d' | sort -u >"$tmp/old.files"
elif [ -d "$T/.agents" ] && [ -n "$(ls -A "$T/.agents" 2>/dev/null)" ]; then
  warn ".agents/ exists without a VERSION stamp: files this script did not ship are left in place; remove stale ones (for example vendored skills) by hand"
fi
comm -13 "$tmp/new.files" "$tmp/old.files" >"$tmp/stale.files"

# ---------------------------------------------------------------------------------------------------- payload change plan
: >"$tmp/payload.plan"
while IFS= read -r f; do
  if [ ! -e "$T/.agents/$f" ]; then
    printf 'create %s\n' "$f" >>"$tmp/payload.plan"
  elif ! cmp -s "$SRC/$f" "$T/.agents/$f"; then
    printf 'update %s\n' "$f" >>"$tmp/payload.plan"
  elif [ -x "$SRC/$f" ] && [ ! -x "$T/.agents/$f" ]; then
    printf 'mode   %s\n' "$f" >>"$tmp/payload.plan"
  fi
done <"$tmp/new.files"
while IFS= read -r f; do
  case "$f" in /* | ../* | */../* | */.. | ..) warn "VERSION lists a path outside .agents/, ignored: $f"; continue ;; esac
  [ -e "$T/.agents/$f" ] || [ -L "$T/.agents/$f" ] || continue
  printf 'remove %s\n' "$f" >>"$tmp/payload.plan"
done <"$tmp/stale.files"

scaffold_version=$(git -C "$SELF_DIR" describe --tags --always --dirty 2>/dev/null || echo unknown)
scaffold_commit=$(git -C "$SELF_DIR" rev-parse HEAD 2>/dev/null || echo unknown)
{
  echo "# Written by install.sh from the workflow 2.0 scaffold. Scaffold-owned; do not edit. Re-run install.sh to upgrade."
  echo "scaffold_version: $scaffold_version"
  echo "scaffold_commit: $scaffold_commit"
  echo "installed: @DATE@"
  echo "files:"
  cat "$tmp/new.files"
} >"$tmp/VERSION.body"
stamp_changed=1
if [ -f "$STAMP" ] && cmp -s <(grep -v '^installed: ' "$tmp/VERSION.body") <(grep -v '^installed: ' "$STAMP"); then
  stamp_changed=0
fi

# ------------------------------------------------------------------------------------------------------ JSON settings merge
# On every hook event, each existing group that runs a command of a template group under a matcher not covering the
# template's first has its matcher resolved by $matchers (merge, replace, keep, auto, or ask, which records a question
# and counts the group as kept until $answers holds the reply). A group running commands of two or more template groups
# gets no question, since one matcher cannot serve them all: when it runs only template commands it is removed, so the
# append below puts each command back under its own template group; otherwise it is kept. Then the template's groups
# are appended, minus hook commands already present under that event (idempotent).
# permissions.allow and permissions.deny are de-duplicated unions. Other template keys are set when absent; equal values are no-ops;
# outputStyle or statusLine that differs is kept with a warning (overwritten with --force); any other difference is a conflict.
# shellcheck disable=SC2016  # jq program, not shell
JQ_MERGE='
def cmds: [ .[]? | objects | (.hooks? // [])[]? | objects | .command? | strings ];
def merge_groups($cur; $new):
  reduce $new[] as $g ($cur;
    cmds as $have
    | [ $g.hooks[] | select(.command as $c | any($have[]; . == $c) | not) ] as $miss
    | if ($miss | length) == 0 then . else . + [ $g | .hooks = $miss ] end);
def group_cmds: [ (.hooks? // [])[]? | objects | .command? | strings ];
def is_match_all: . == null or . == "" or . == "*";
def is_plain: type == "string" and test("^[A-Za-z0-9_|]+$");
def alternatives: split("|");
def covers($tm): ($tm | is_match_all | not) and (alternatives as $have | all($tm | alternatives[]; . as $a | any($have[]; . == $a)));
def merged_with($tm): reduce ($tm | alternatives[]) as $a (alternatives; if any(.[]; . == $a) then . else . + [$a] end) | join("|");
def shown: if is_match_all then "(none: matches everything)" else tojson end;
def set_matcher($ev; $i; $m): if $m == null then del(.out.hooks[$ev][$i].matcher) else .out.hooks[$ev][$i].matcher = $m end;
def resolve_group($ev; $i; $j; $tg; $all_tcmds):
  .out.hooks[$ev][$i] as $g
  | ($g | group_cmds) as $gc
  | ($tg | group_cmds) as $tc
  | if ($g | type) != "object" or ($g.matcher | type) != "string" or ($g.matcher | is_match_all)
       or (any($gc[]; . as $c | any($tc[]; . == $c)) | not) or ($g.matcher | covers($tg.matcher)) then .
    else
      ($tg.matcher | if is_match_all then null else . end) as $replaced
      | (($g.matcher | is_plain) and (($tg.matcher | is_match_all) or ($tg.matcher | is_plain))) as $mergeable
      | (if $replaced == null then null else $g.matcher | merged_with($replaced) end) as $merged
      | [ $gc[] | select(. as $c | any($tc[]; . == $c)) ] as $scaffold
      | [ $gc[] | select(. as $c | any($all_tcmds[]; . == $c) | not) ] as $own
      | "\($ev)/\($i)/\($j)" as $key
      | "hooks.\($ev): the group running \($scaffold | join(", ")) has matcher \($g.matcher | tojson), which does not cover the template matcher \($tg.matcher | shown)" as $what
      | (if $matchers == "ask" then
           .questions += [{key: $key, event: $ev, scaffold: $scaffold, hooks: $gc, own: $own, current: $g.matcher,
                           replace: $replaced, merge: $merged, mergeable: $mergeable}]
         else . end)
      | (if $matchers == "ask" then $answers[$key] // "keep"
         elif $matchers == "auto" then (if ($own | length) > 0 then "keep" else "merge" end)
         else $matchers end) as $choice
      | (if $choice == "merge" and ($mergeable | not) then "unmergeable" else $choice end) as $outcome
      | if $outcome == "merge" then
          set_matcher($ev; $i; $merged)
          | if $matchers == "auto" then .matcher_warnings += ["\($what); merged to \($merged | shown) (no terminal to ask; --matchers=merge|replace|keep chooses for every group)"] else . end
        elif $outcome == "replace" then set_matcher($ev; $i; $replaced)
        elif $outcome == "unmergeable" then
          .matcher_warnings += ["\($what); kept, since it is not a plain | list of names and cannot be merged (--matchers=replace takes the template matcher)"]
        elif $outcome == "keep" and $matchers == "auto" then
          .matcher_warnings += ["\($what); kept, since it also runs your hooks (\($own | join(", "))) and there is no terminal to ask (--matchers=merge|replace|keep chooses for every group)"]
        else .matcher_warnings += ["\($what); kept as it is"] end
    end;
def runs_any_of($tg): group_cmds as $gc | any($tg | group_cmds[]; . as $c | any($gc[]; . == $c));
def unsettled($tg): type == "object" and (.matcher | type) == "string" and (.matcher | is_match_all | not)
  and (.matcher | covers($tg.matcher) | not);
def only_template_hooks($all_tcmds):
  (.hooks | type) == "array"
  and all(.hooks[]; type == "object" and (.command | type) == "string" and (.command as $c | any($all_tcmds[]; . == $c)));
def hook_names: [ (.hooks? // [])[]? | if type == "object" and (.command | type) == "string" then .command else tojson end ];
def split_or_keep($ev; $i; $g; $all_tcmds; $count):
  "hooks.\($ev): the group with matcher \($g.matcher | tojson) runs commands of \($count) template groups" as $what
  | if $g | only_template_hooks($all_tcmds) then
      .rewritten += [$i]
      | .matcher_warnings += ["\($what) (\($g | hook_names | join(", "))); rewritten into the template groups, each command under its template matcher"]
    else
      .matcher_warnings += ["\($what) and hooks of your own, so no one matcher fits them all; kept as it is. Its hooks: \($g | hook_names | join(", "))"]
    end;
def resolve_matchers($ev):
  $t.hooks[$ev] as $tgroups
  | ([ $tgroups[] | group_cmds[] ]) as $all_tcmds
  | .rewritten = []
  | reduce range(0; .out.hooks[$ev] // [] | length) as $i (.;
      .out.hooks[$ev][$i] as $g
      | [ range(0; $tgroups | length) as $j | select($g | runs_any_of($tgroups[$j])) | $j ] as $js
      | if ($js | length) > 1 and any($js[]; . as $j | $g | unsettled($tgroups[$j])) then
          split_or_keep($ev; $i; $g; $all_tcmds; $js | length)
        else reduce $js[] as $j (.; resolve_group($ev; $i; $j; $tgroups[$j]; $all_tcmds)) end)
  | .rewritten as $gone
  | (if ($gone | length) == 0 then . else
       .out.hooks[$ev] |= [ range(0; length) as $k | select(any($gone[]; . == $k) | not) | .[$k] ] end)
  | del(.rewritten);
def badtype($ty; $want): ($ty != $want and $ty != "null");
def keyrule($p; $v; $label):
  (.out | getpath($p)) as $cur
  | if $cur == null then .out |= setpath($p; $v)
    elif $cur == $v then .
    elif $label == "outputStyle" or $label == "statusLine" then
      if $force then .warnings += ["\($label): replaced \($cur | tojson) with \($v | tojson) (--force)"] | .out |= setpath($p; $v)
      else .warnings += ["\($label): keeping your \($cur | tojson); the workflow ships \($v | tojson) (re-run with --force to use it)"] end
    elif $force then .warnings += ["\($label): replaced your value with the template value (--force)"] | .out |= setpath($p; $v)
    else .conflicts += ["\($label): your value \($cur | tojson) differs from the template value \($v | tojson)"] end;
. as $u
| if ($u | type) != "object" then {fatal: "the top level is not a JSON object"} else
  {out: $u, conflicts: [], warnings: [], matcher_warnings: [], questions: []}
  | if $t.hooks == null then . else
      (if badtype(.out.hooks | type; "object") then
         if $force then .warnings += ["hooks: not an object; replaced (--force)"] | .out.hooks = {}
         else .conflicts += ["hooks: is a \(.out.hooks | type), expected an object"] end
       else . end)
      | if badtype(.out.hooks | type; "object") then . else
          reduce ($t.hooks | keys_unsorted[]) as $ev (.;
            if badtype(.out.hooks[$ev] | type; "array") then
              if $force then .warnings += ["hooks.\($ev): not an array; replaced (--force)"] | .out.hooks[$ev] = $t.hooks[$ev]
              else .conflicts += ["hooks.\($ev): is a \(.out.hooks[$ev] | type), expected an array"] end
            else resolve_matchers($ev) | .out.hooks[$ev] = merge_groups(.out.hooks[$ev] // []; $t.hooks[$ev]) end)
        end
    end
  | if $t.permissions == null then . else
      if badtype(.out.permissions | type; "object") then
        if $force then .warnings += ["permissions: not an object; replaced (--force)"] | .out.permissions = $t.permissions
        else .conflicts += ["permissions: is a \(.out.permissions | type), expected an object"] end
      else
        reduce ($t.permissions | to_entries[]) as $e (.;
          if $e.key == "deny" or $e.key == "allow" then
            if badtype(.out.permissions[$e.key] | type; "array") then
              if $force then .warnings += ["permissions.\($e.key): not an array; replaced (--force)"] | .out.permissions[$e.key] = $e.value
              else .conflicts += ["permissions.\($e.key): is a \(.out.permissions[$e.key] | type), expected an array"] end
            else .out.permissions[$e.key] = (reduce $e.value[] as $d ((.out.permissions[$e.key] // []); if any(.[]; . == $d) then . else . + [$d] end)) end
          else keyrule(["permissions", $e.key]; $e.value; "permissions.\($e.key)") end)
      end
    end
  | reduce ($t | to_entries[] | select(.key != "hooks" and .key != "permissions")) as $e (.; keyrule([$e.key]; $e.value; $e.key))
  end
'

# run_merge TEMPLATE DEST ANSWERS : print the JQ_MERGE result for TEMPLATE into DEST, with ANSWERS (a JSON object of
# question key to merge, replace or keep) as the replies to the matcher questions.
run_merge() {
  jq --argjson t "$(cat "$1")" --argjson force "$([ "$force" -eq 1 ] && echo true || echo false)" \
    --arg matchers "$matcher_mode" --argjson answers "$3" "$JQ_MERGE" "$2"
}

# write_if_changed RESULT DEST OUT : write RESULT's merged settings to OUT, or leave OUT absent when DEST would not change.
write_if_changed() {
  rm -f "$3"
  if [ "$(jq -S .out <<<"$1")" != "$(jq -S . "$2")" ]; then
    jq .out <<<"$1" >"$3"
  fi
}

# merge_json NAME TEMPLATE DEST OUT : plan the merge of TEMPLATE into DEST; the result goes to OUT. Records refusals and
# warnings. Leaves OUT absent when DEST would not change. In ask mode the matcher questions go to OUT.questions, one JSON
# object per line, and those groups stay as they are until ask_matchers has the answers.
merge_json() {
  local name=$1 tpl=$2 dest=$3 out=$4 res
  rm -f "$out" "$out.questions"
  if [ ! -e "$dest" ]; then
    jq . "$tpl" >"$out"
    return
  fi
  if ! jq empty "$dest" >/dev/null 2>&1; then
    refuse "$name: not valid JSON; fix it or move it aside (--force does not override this)"
    return
  fi
  res=$(run_merge "$tpl" "$dest" '{}')
  if [ "$(jq -r '.fatal // empty' <<<"$res")" != "" ]; then
    refuse "$name: $(jq -r .fatal <<<"$res") (--force does not override this)"
    return
  fi
  while IFS= read -r m; do [ -z "$m" ] || refuse "$name: $m (re-run with --force to take the template value)"; done < <(jq -r '.conflicts[]' <<<"$res")
  # With questions pending, this plan counts every asked group as kept; ask_matchers prints the matcher warnings of the
  # plan that has the answers.
  while IFS= read -r m; do [ -z "$m" ] || warn "$name: $m"; done < <(jq -r '.warnings[], if (.questions | length) == 0 then .matcher_warnings[] else empty end' <<<"$res")
  jq -c '.questions[]' <<<"$res" >"$out.questions"
  write_if_changed "$res" "$dest" "$out"
}

# The prompt for one matcher question (a merge_json question object); $name is the settings file.
# shellcheck disable=SC2016  # jq program, not shell
JQ_PROMPT='
def shown: . // "(no matcher: matches everything)";
"",
"\($name) hooks.\(.event): a group runs the scaffold command \(.scaffold | join(", ")) under a matcher that does not cover the template matcher.",
(if (.own | length) > 0 then "  It also runs your own hooks. Every hook in the group:", (.hooks[] | "    - \(.)") else empty end),
"  current: \(.current)",
"  replace: \(.replace | shown)",
(if .mergeable then "  merge:   \(.merge | shown)"
 else "  merge:   not offered, since \(.current | tojson) is not a plain | list of names" end)
'

# ask_choice MERGEABLE : ask on the terminal until the reply is valid; sets MATCHER_CHOICE to merge, replace or keep.
# Enter takes merge when MERGEABLE is true, else keep. The end of input counts as Enter, so the run never stalls.
ask_choice() {
  local reply
  while :; do
    if [ "$1" = true ]; then printf 'Merge, replace or keep? [Enter = merge, r = replace, k = keep] '
    else printf 'Replace or keep? [Enter = keep, r = replace] '; fi
    IFS= read -r reply || { reply=""; echo; }
    case "$reply" in
      "") if [ "$1" = true ]; then MATCHER_CHOICE=merge; else MATCHER_CHOICE=keep; fi; return ;;
      [mM] | merge) if [ "$1" = true ]; then MATCHER_CHOICE=merge; return; fi ;;
      [rR] | replace) MATCHER_CHOICE=replace; return ;;
      [kK] | keep) MATCHER_CHOICE=keep; return ;;
    esac
    echo "  Answer with Enter, r or k."
  done
}

# ask_matchers NAME TEMPLATE DEST OUT : at a terminal, ask about each group merge_json left in OUT.questions, then plan
# the merge of TEMPLATE into DEST again with the answers; the result goes to OUT as merge_json does.
ask_matchers() {
  local name=$1 tpl=$2 dest=$3 out=$4 answers='{}' count i question res
  [ -s "$out.questions" ] || return 0
  count=$(jq -s length "$out.questions")
  for ((i = 0; i < count; i++)); do
    question=$(jq -s -c ".[$i]" "$out.questions")
    jq -r --arg name "$name" "$JQ_PROMPT" <<<"$question"
    ask_choice "$(jq -r .mergeable <<<"$question")"
    answers=$(jq -c --arg key "$(jq -r .key <<<"$question")" --arg choice "$MATCHER_CHOICE" '.[$key] = $choice' <<<"$answers")
  done
  res=$(run_merge "$tpl" "$dest" "$answers")
  while IFS= read -r m; do [ -z "$m" ] || warn "$name: $m"; done < <(jq -r '.matcher_warnings[]' <<<"$res")
  write_if_changed "$res" "$dest" "$out"
}

# --------------------------------------------------------------------------------------------------------- marker blocks
MARK_PREFIX="workflow-2.0 scaffold"
mark_begin() { printf '# >>> %s: %s (managed by install.sh; edits inside are replaced) >>>' "$MARK_PREFIX" "$1"; }
mark_end() { printf '# <<< %s: %s <<<' "$MARK_PREFIX" "$1"; }
# block_text NAME CONTENT_FILE : the full block (begin marker, content, end marker).
block_text() { mark_begin "$1"; echo; cat "$2"; mark_end "$1"; echo; }
# block_state FILE NAME : prints absent, present or damaged.
block_state() {
  local b e nb ne
  b=$(mark_begin "$2")
  e=$(mark_end "$2")
  [ -f "$1" ] || { echo absent; return; }
  nb=$(grep -cxF -- "$b" "$1" || true)
  ne=$(grep -cxF -- "$e" "$1" || true)
  if [ "$nb" -eq 0 ] && [ "$ne" -eq 0 ]; then echo absent
  elif [ "$nb" -eq 1 ] && [ "$ne" -eq 1 ] && [ "$(grep -nxF -- "$b" "$1" | cut -d: -f1)" -lt "$(grep -nxF -- "$e" "$1" | cut -d: -f1)" ]; then echo present
  else echo damaged; fi
}
# block_replace FILE NAME CONTENT_FILE : print FILE with the block's content replaced.
block_replace() {
  awk -v b="$(mark_begin "$2")" -v e="$(mark_end "$2")" -v cf="$3" '
    $0 == b { print; while ((getline l < cf) > 0) print l; skip = 1; next }
    skip && $0 == e { skip = 0; print; next }
    skip { next }
    { print }' "$1"
}
# block_append FILE NAME CONTENT_FILE : print FILE (may be absent) with the block appended.
block_append() {
  if [ -s "$1" ]; then
    cat "$1"
    [ "$(tail -c 1 "$1" | od -An -c | tr -d ' ')" = '\n' ] || echo
    echo
  fi
  block_text "$2" "$3"
}

# ------------------------------------------------------------------------------------------------------------ Claude plan
SYMLINK_PLAN=()
if [ "$want_claude" -eq 1 ]; then
  if [ -e "$T/.claude" ] && [ ! -d "$T/.claude" ]; then
    refuse ".claude exists and is not a directory"
  fi
  for d in $SHIM_DIRS; do
    l=$T/.claude/$d
    want=../.agents/$d
    if [ -L "$l" ]; then
      cur=$(readlink "$l")
      if [ "$cur" = "$want" ]; then continue; fi
      if [ "$force" -eq 1 ]; then SYMLINK_PLAN+=("relink $d $cur")
      else refuse ".claude/$d is a symlink to $cur, not $want (re-run with --force to replace it)"; fi
    elif [ -e "$l" ]; then
      if [ "$force" -eq 1 ]; then SYMLINK_PLAN+=("backup $d")
      else refuse ".claude/$d is a real directory or file; move its contents into .agents/$d or re-run with --force (it is moved to .claude/$d.backup-<timestamp>)"; fi
    else
      SYMLINK_PLAN+=("create $d")
    fi
  done
  merge_json .claude/settings.json "$CLAUDE_TPL" "$T/.claude/settings.json" "$tmp/settings.json"
fi

# ------------------------------------------------------------------------------------------------------------- Codex plan
if [ "$want_codex" -eq 1 ]; then
  if [ -e "$T/.codex" ] && [ ! -d "$T/.codex" ]; then
    refuse ".codex exists and is not a directory"
  fi
  merge_json .codex/hooks.json "$CODEX_HOOKS_TPL" "$T/.codex/hooks.json" "$tmp/hooks.json"

  # config.toml: three marker blocks. "default-permissions" holds the top-level key (inserted at the top, before any
  # table); "permissions-workflow" holds the template's [permissions.*] tables and "tui" its [tui] table (both appended at the end).
  CFG=$T/.codex/config.toml
  rm -f "$tmp/config.toml"
  dp_want=$(yq -p toml -o json -I=0 '.default_permissions' "$CODEX_CONFIG_TPL")
  wf_want=$(yq -p toml -o json -I=0 '.permissions.workflow' "$CODEX_CONFIG_TPL")
  printf 'default_permissions = %s\n' "$dp_want" >"$tmp/cfg.top"
  tui_want=$(yq -p toml -o json -I=0 '.tui' "$CODEX_CONFIG_TPL")
  awk '/^[[:space:]]*\[tui\][[:space:]]*$/ { exit } f || /^[[:space:]]*\[/ { f = 1; print }' "$CODEX_CONFIG_TPL" | awk '/^[[:space:]]*$/ { n++; next } { while (n > 0) { print ""; n-- } print }' >"$tmp/cfg.tables"
  awk 'f || /^[[:space:]]*\[tui\][[:space:]]*$/ { f = 1; print }' "$CODEX_CONFIG_TPL" >"$tmp/cfg.tui"
  if [ ! -e "$CFG" ]; then
    {
      echo "# Codex project config. install.sh manages the marked blocks (see the scaffold's .codex/README.md); add your own settings outside them."
      block_text default-permissions "$tmp/cfg.top"
      echo
      block_text permissions-workflow "$tmp/cfg.tables"
      echo
      block_text tui "$tmp/cfg.tui"
    } >"$tmp/config.toml"
  elif ! cur_json=$(yq -p toml -o json -I=0 '.' "$CFG" 2>/dev/null); then
    refuse ".codex/config.toml: not valid TOML; fix it first (--force does not override this)"
  else
    cp "$CFG" "$tmp/cfg.work"
    st_top=$(block_state "$CFG" default-permissions)
    st_tab=$(block_state "$CFG" permissions-workflow)
    st_tui=$(block_state "$CFG" tui)
    cfg_ok=1
    for st in "$st_top" "$st_tab" "$st_tui"; do
      [ "$st" != damaged ] || { refuse ".codex/config.toml: a workflow-2.0 marker block is damaged (unmatched or repeated markers); repair it by hand"; cfg_ok=0; }
    done
    if [ "$cfg_ok" -eq 1 ]; then
      # default_permissions
      if [ "$st_top" = present ]; then
        block_replace "$tmp/cfg.work" default-permissions "$tmp/cfg.top" >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
      else
        dp_cur=$(jq -c '.default_permissions // null' <<<"$cur_json")
        if [ "$dp_cur" = null ]; then
          { block_text default-permissions "$tmp/cfg.top"; echo; cat "$tmp/cfg.work"; } >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
        elif [ "$dp_cur" != "$dp_want" ]; then
          if [ "$force" -eq 1 ]; then
            awk -v repl="$(cat "$tmp/cfg.top")" '
              !t && /^[[:space:]]*\[/ { t = 1 }
              !t && !done && /^[[:space:]]*default_permissions[[:space:]]*=/ { print repl; done = 1; next }
              { print }' "$tmp/cfg.work" >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
            warn ".codex/config.toml: default_permissions $dp_cur replaced with $dp_want (--force)"
          else
            warn ".codex/config.toml: keeping your default_permissions $dp_cur; the workflow's hard write limits need $dp_want (re-run with --force to set it)"
          fi
        fi
      fi
      # [permissions.workflow]
      if [ "$st_tab" = present ]; then
        block_replace "$tmp/cfg.work" permissions-workflow "$tmp/cfg.tables" >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
      else
        wf_cur=$(jq -c '.permissions.workflow // null' <<<"$cur_json")
        if [ "$wf_cur" = null ]; then
          block_append "$tmp/cfg.work" permissions-workflow "$tmp/cfg.tables" >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
        elif [ "$(jq -S . <<<"$wf_cur")" != "$(jq -S . <<<"$wf_want")" ]; then
          if [ "$force" -eq 1 ]; then
            warn ".codex/config.toml: your [permissions.workflow] differs from the template and was left as is; reconcile it by hand with .agents/hooks/codex-config.template.toml"
          else
            refuse ".codex/config.toml: [permissions.workflow] exists and differs from the template; reconcile it with .agents/hooks/codex-config.template.toml (--force leaves it as is and continues)"
          fi
        fi
      fi
      # [tui] status_line. A [tui] table or tui.* key the user wrote is never rewritten, even with --force.
      if [ "$st_tui" = present ]; then
        block_replace "$tmp/cfg.work" tui "$tmp/cfg.tui" >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
      else
        tui_cur=$(jq -c '.tui // null' <<<"$cur_json")
        if [ "$tui_cur" = null ]; then
          block_append "$tmp/cfg.work" tui "$tmp/cfg.tui" >"$tmp/cfg.next" && mv "$tmp/cfg.next" "$tmp/cfg.work"
        elif [ "$(jq -c '.status_line // null' <<<"$tui_cur")" != "$(jq -c '.status_line' <<<"$tui_want")" ]; then
          sl_want=$(jq -c '.status_line' <<<"$tui_want")
          if [ "$force" -eq 1 ]; then
            warn ".codex/config.toml: your [tui] table was left as is (--force does not rewrite it); add status_line = $sl_want to it yourself for the context bar"
          else
            warn ".codex/config.toml: keeping your [tui] table; add status_line = $sl_want to it for the workflow's context bar"
          fi
        fi
      fi
      if ! yq -p toml -o json '.' "$tmp/cfg.work" >/dev/null 2>&1; then
        refuse ".codex/config.toml: the merge would produce invalid TOML; merge .agents/hooks/codex-config.template.toml by hand"
      elif ! cmp -s "$tmp/cfg.work" "$CFG"; then
        cp "$tmp/cfg.work" "$tmp/config.toml"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------------------------------------------------- .gitignore plan
GI=$T/.gitignore
rm -f "$tmp/gitignore"
printf '%s\n' "${GI_ENTRIES[@]}" >"$tmp/gi.block"
case "$(block_state "$GI" gitignore)" in
  absent) block_append "$GI" gitignore "$tmp/gi.block" >"$tmp/gitignore" ;;
  present)
    block_replace "$GI" gitignore "$tmp/gi.block" >"$tmp/gi.next"
    cmp -s "$tmp/gi.next" "$GI" || mv "$tmp/gi.next" "$tmp/gitignore"
    ;;
  damaged) refuse ".gitignore: the workflow-2.0 marker block is damaged (unmatched or repeated markers); repair it by hand" ;;
esac

# ------------------------------------------------------------------------------------------------------------- report plan
mode="Installing"
[ "$dry" -eq 0 ] || mode="Dry run: would install"
echo "$mode workflow 2.0 scaffold $scaffold_version into $T (host: $host)"

if [ "${#REFUSALS[@]}" -gt 0 ]; then
  echo "install.sh: refusing; nothing was written:" >&2
  for r in "${REFUSALS[@]}"; do echo "  - $r" >&2; done
  exit 1
fi

# Asked only once the run is known not to refuse, so no answer is wasted on a run that writes nothing.
if [ "$matcher_mode" = ask ]; then
  [ "$want_claude" -eq 0 ] || ask_matchers .claude/settings.json "$CLAUDE_TPL" "$T/.claude/settings.json" "$tmp/settings.json"
  [ "$want_codex" -eq 0 ] || ask_matchers .codex/hooks.json "$CODEX_HOOKS_TPL" "$T/.codex/hooks.json" "$tmp/hooks.json"
fi

act() { if [ "$dry" -eq 1 ]; then echo "  would $1"; else echo "  $1"; fi; }
# write_file SRC DEST LABEL : replace DEST's content (keeps a symlinked DEST pointing where it does).
write_file() {
  act "write $3"
  if [ "$dry" -eq 1 ]; then
    if [ -e "$2" ]; then diff -u "$2" "$1" | sed '1,2d; s/^/      /' || true; fi
    return
  fi
  mkdir -p "$(dirname "$2")"
  cat "$1" >"$2"
}

# ---------------------------------------------------------------------------------------------------------------- payload
echo "Payload (.agents/, $(wc -l <"$tmp/new.files" | tr -d ' ') files from install-manifest.txt):"
if [ ! -s "$tmp/payload.plan" ]; then
  echo "  up to date"
else
  while IFS= read -r line; do
    op=${line%% *}
    f=$(printf '%s' "$line" | sed 's/^[a-z]* *//')
    act "$op .agents/$f"
    [ "$dry" -eq 0 ] || continue
    case "$op" in
      create | update | mode)
        mkdir -p "$(dirname "$T/.agents/$f")"
        rm -f "$T/.agents/$f"
        cp "$SRC/$f" "$T/.agents/$f"
        ;;
      remove)
        rm -f "$T/.agents/$f"
        d=$(dirname "$T/.agents/$f")
        while [ "$d" != "$T/.agents" ] && rmdir "$d" 2>/dev/null; do d=$(dirname "$d"); done
        ;;
    esac
  done <"$tmp/payload.plan"
fi
if [ "$stamp_changed" -eq 1 ]; then
  act "write .agents/VERSION ($scaffold_version)"
  if [ "$dry" -eq 0 ]; then
    sed "s/^installed: @DATE@\$/installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$tmp/VERSION.body" >"$STAMP"
  fi
fi

# ----------------------------------------------------------------------------------------------------------------- Claude
if [ "$want_claude" -eq 1 ]; then
  echo "Claude shim (.claude/):"
  [ "${#SYMLINK_PLAN[@]}" -gt 0 ] || [ -f "$tmp/settings.json" ] || echo "  up to date"
  for p in ${SYMLINK_PLAN[@]+"${SYMLINK_PLAN[@]}"}; do
    op=${p%% *}
    rest=${p#* }
    d=${rest%% *}
    l=$T/.claude/$d
    case "$op" in
      create) act "link .claude/$d -> ../.agents/$d" ;;
      relink) act "relink .claude/$d -> ../.agents/$d (was -> ${rest#* }; --force)" ;;
      backup)
        bak=$l.backup-$(date +%Y%m%d%H%M%S)
        act "move .claude/$d to .claude/$(basename "$bak") and link .claude/$d -> ../.agents/$d (--force)"
        [ "$dry" -eq 1 ] || mv "$l" "$bak"
        ;;
    esac
    if [ "$dry" -eq 0 ]; then
      mkdir -p "$T/.claude"
      rm -f "$l"
      ln -s "../.agents/$d" "$l"
    fi
  done
  [ ! -f "$tmp/settings.json" ] || write_file "$tmp/settings.json" "$T/.claude/settings.json" .claude/settings.json
fi

# ------------------------------------------------------------------------------------------------------------------ Codex
if [ "$want_codex" -eq 1 ]; then
  echo "Codex shim (.codex/):"
  gen_out=$tmp/gen.out
  if [ "$dry" -eq 1 ]; then
    gen=$SRC/hooks/generate-codex-agents.sh
    gen_args=(--agents-dir "$SRC/agents" --out-dir "$T/.codex/agents")
  else
    gen=$T/.agents/hooks/generate-codex-agents.sh
    gen_args=()
  fi
  if bash "$gen" ${gen_args[@]+"${gen_args[@]}"} --check >"$gen_out" 2>&1; then
    echo "  .codex/agents up to date"
  else
    rc=$?
    if [ "$rc" -ne 1 ]; then
      cat "$gen_out" >&2
      die "generate-codex-agents.sh failed (exit $rc)"
    fi
    sed -n 's/^  //p' "$gen_out" | grep -E '^(create|update|remove) ' | while IFS= read -r line; do
      act "${line%% *} .codex/agents/${line#* }"
    done
    if [ "$dry" -eq 0 ]; then
      bash "$gen" || die "generate-codex-agents.sh failed"
    fi
  fi
  [ ! -f "$tmp/hooks.json" ] || write_file "$tmp/hooks.json" "$T/.codex/hooks.json" .codex/hooks.json
  [ ! -f "$tmp/config.toml" ] || write_file "$tmp/config.toml" "$T/.codex/config.toml" .codex/config.toml
fi

# ------------------------------------------------------------------------------------------------------------- .gitignore
echo ".gitignore:"
if [ -f "$tmp/gitignore" ]; then
  write_file "$tmp/gitignore" "$GI" ".gitignore ($(printf '%s, ' "${GI_ENTRIES[@]}" | sed 's/, $//'))"
else
  echo "  up to date"
fi

# --------------------------------------------------------------------------------------------------------------- warnings
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  echo "Warnings:"
  for w in "${WARNINGS[@]}"; do echo "  - $w"; done
fi

if [ "$dry" -eq 1 ]; then
  echo "Dry run: nothing was written."
  exit 0
fi

echo
echo "Next steps:"
if [ "$want_codex" -eq 1 ]; then
  echo "  Codex: start codex in $T (not from inside a Codex session that ran this script), trust the project .codex/ layer"
  echo "    when asked, then run /hooks and review each hook. Codex pins trust to the hook hash, so repeat this after every"
  echo "    upgrade. (--dangerously-bypass-hook-trust is for automation only.)"
fi
changed=".agents/"
[ "$want_claude" -eq 0 ] || changed="$changed, .claude/"
[ "$want_codex" -eq 0 ] || changed="$changed, .codex/"
echo "  Review and commit the changes ($changed, .gitignore)."
echo "  Run the project-setup skill in the target to create $WF_DIR/ (GLOSSARY.md, rules.md, profiles/, model-map/, agent-overrides.yaml and the rest)."
exit 0
