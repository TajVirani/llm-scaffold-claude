#!/usr/bin/env bash
# File: Scaffold install script (scaffold-only; not part of the .agents/ payload). Lives at the repo root, next to the payload it copies (D11).
# Usage:
#   ./install.sh <target-dir> [--host claude|codex|all] [--force] [--dry-run]
#     <target-dir>  top level of a git repository (the target project)
#     --host        which host shims to set up (default: all)
#     --force       replace conflicting shim entries instead of refusing (see "Conflicts" below)
#     --dry-run     print what would change and write nothing
# What it does:
#   1. Preflight: bash 3.2+, git, jq, mikefarah yq v4 (D15, D38); the target is the top level of a git work tree.
#   2. Payload (D11, D71, D72): copies every file named by .agents/install-manifest.txt (first-party only; vendored skills,
#      kept only while being rewritten, never ship) into <target>/.agents/. .agents/ is scaffold-owned: changed files are overwritten, and files the previous
#      install shipped (listed in <target>/.agents/VERSION) that are no longer in the manifest are removed. Files in
#      <target>/.agents/ that no install shipped (for example the data-structure-audit state file) are left alone.
#      Writes <target>/.agents/VERSION: scaffold version, commit, install date and the installed file list. The
#      VERSION file is rewritten only when the version or file list changes, so a re-run changes nothing.
#   3. Claude (D36), --host claude|all: <target>/.claude/{skills,agents,output-styles} symlinks to ../.agents/<dir>, and
#      .agents/hooks/claude-settings.template.json merged into <target>/.claude/settings.json (rules in
#      .agents/hooks/claude-settings.template.md): missing hook groups appended, permissions.deny unioned, user keys kept,
#      a different user outputStyle or statusLine kept with a warning.
#   4. Codex (D40, D66, D67), --host codex|all: runs generate-codex-agents.sh in the target (.codex/agents/*.toml),
#      merges codex-hooks.template.json into .codex/hooks.json (same hook rules) and codex-config.template.toml into
#      .codex/config.toml (rules in the scaffold's .codex/README.md). yq v4 reads TOML but cannot write tables, so the
#      config is edited through marker blocks that later runs refresh in place; user text outside them is never rewritten.
#   5. <target>/.gitignore: specs/*/.step, .cache-staging/ and .worktrees/ in a marker block (D16, D17).
#   Never touches project-owned files: agent-overrides.yaml, model-map/, profiles/, GLOSSARY.md, docs/, deferred/, specs/ (D11, D35).
#   Scaffold-only files (PLAN/, tests/, assetlist.md, organization.md, checklist.md, PROVENANCE.md, CHANGELOG.md, upstream-lineage.json, scripts/, this script)
#   are outside .agents/ and never copied (D30).
# Conflicts: every check runs before anything is written. Without --force, install.sh refuses (exit 1, nothing written) when
#   .claude/{skills,agents,output-styles} is a real directory or a symlink elsewhere, a settings/hooks key has the wrong type or
#   a different value, .codex/config.toml has a different [permissions.workflow], or a marker block is damaged. With --force
#   a real directory is moved aside to <name>.backup-<timestamp>, a wrong symlink is replaced, conflicting JSON keys take the
#   template value, outputStyle, statusLine and default_permissions are overwritten, and a hand-written [permissions.workflow] that
#   differs is left as is with a warning (it cannot be rewritten safely). Unparseable JSON or TOML always refuses.
# Exit: 0 installed (or dry-run clean); 1 refused because of a conflict; 2 usage or preflight error.
# Run it outside a Codex session (.codex/README.md). Plan refs: assetlist D9, D11, D15, D16, D17, D30, D35, D36, D38, D40,
#   D66, D67, D71, D72. Tests: tests/scripts/install.sh.

set -euo pipefail
export LC_ALL=C

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
SRC=$SELF_DIR/.agents
MANIFEST=$SRC/install-manifest.txt
CLAUDE_TPL=$SRC/hooks/claude-settings.template.json
CODEX_HOOKS_TPL=$SRC/hooks/codex-hooks.template.json
CODEX_CONFIG_TPL=$SRC/hooks/codex-config.template.toml
SHIM_DIRS="skills agents output-styles"

die() { echo "install.sh: error: $*" >&2; exit 2; }
usage() { sed -n '/^# Usage:/,/^# What it does:/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'; }

target=""
host=all
force=0
dry=0
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
    *) echo "install.sh: yq is not mikefarah yq v4 (got: $(yq --version 2>&1 | head -n 1)); the Python yq is not supported (D38)" >&2; missing=1 ;;
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
# The template's hooks.<event> groups are appended, minus hook commands already present under that event (idempotent).
# permissions.deny is a de-duplicated union. Other template keys are set when absent; equal values are no-ops;
# outputStyle or statusLine that differs is kept with a warning (overwritten with --force); any other difference is a conflict.
# shellcheck disable=SC2016  # jq program, not shell
JQ_MERGE='
def cmds: [ .[]? | objects | (.hooks? // [])[]? | objects | .command? | strings ];
def merge_groups($cur; $new):
  reduce $new[] as $g ($cur;
    cmds as $have
    | [ $g.hooks[] | select(.command as $c | any($have[]; . == $c) | not) ] as $miss
    | if ($miss | length) == 0 then . else . + [ $g | .hooks = $miss ] end);
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
  {out: $u, conflicts: [], warnings: []}
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
            else .out.hooks[$ev] = merge_groups(.out.hooks[$ev] // []; $t.hooks[$ev]) end)
        end
    end
  | if $t.permissions == null then . else
      if badtype(.out.permissions | type; "object") then
        if $force then .warnings += ["permissions: not an object; replaced (--force)"] | .out.permissions = $t.permissions
        else .conflicts += ["permissions: is a \(.out.permissions | type), expected an object"] end
      else
        reduce ($t.permissions | to_entries[]) as $e (.;
          if $e.key == "deny" then
            if badtype(.out.permissions.deny | type; "array") then
              if $force then .warnings += ["permissions.deny: not an array; replaced (--force)"] | .out.permissions.deny = $e.value
              else .conflicts += ["permissions.deny: is a \(.out.permissions.deny | type), expected an array"] end
            else .out.permissions.deny = (reduce $e.value[] as $d ((.out.permissions.deny // []); if any(.[]; . == $d) then . else . + [$d] end)) end
          else keyrule(["permissions", $e.key]; $e.value; "permissions.\($e.key)") end)
      end
    end
  | reduce ($t | to_entries[] | select(.key != "hooks" and .key != "permissions")) as $e (.; keyrule([$e.key]; $e.value; $e.key))
  end
'

# merge_json NAME TEMPLATE DEST OUT : plan the merge of TEMPLATE into DEST; the result goes to OUT. Records refusals and
# warnings. Leaves OUT absent when DEST would not change.
merge_json() {
  local name=$1 tpl=$2 dest=$3 out=$4 res
  rm -f "$out"
  if [ ! -e "$dest" ]; then
    jq . "$tpl" >"$out"
    return
  fi
  if ! jq empty "$dest" >/dev/null 2>&1; then
    refuse "$name: not valid JSON; fix it or move it aside (--force does not override this)"
    return
  fi
  res=$(jq --argjson t "$(cat "$tpl")" --argjson force "$([ "$force" -eq 1 ] && echo true || echo false)" "$JQ_MERGE" "$dest")
  if [ "$(jq -r '.fatal // empty' <<<"$res")" != "" ]; then
    refuse "$name: $(jq -r .fatal <<<"$res") (--force does not override this)"
    return
  fi
  while IFS= read -r m; do [ -z "$m" ] || refuse "$name: $m (re-run with --force to take the template value)"; done < <(jq -r '.conflicts[]' <<<"$res")
  while IFS= read -r m; do [ -z "$m" ] || warn "$name: $m"; done < <(jq -r '.warnings[]' <<<"$res")
  if [ "$(jq -S .out <<<"$res")" != "$(jq -S . "$dest")" ]; then
    jq .out <<<"$res" >"$out"
  fi
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

  # config.toml: two marker blocks. "default-permissions" holds the top-level key (inserted at the top, before any
  # table); "permissions-workflow" holds the template's tables (appended at the end).
  CFG=$T/.codex/config.toml
  rm -f "$tmp/config.toml"
  dp_want=$(yq -p toml -o json -I=0 '.default_permissions' "$CODEX_CONFIG_TPL")
  wf_want=$(yq -p toml -o json -I=0 '.permissions.workflow' "$CODEX_CONFIG_TPL")
  printf 'default_permissions = %s\n' "$dp_want" >"$tmp/cfg.top"
  awk 'f || /^[[:space:]]*\[/ { f = 1; print }' "$CODEX_CONFIG_TPL" >"$tmp/cfg.tables"
  if [ ! -e "$CFG" ]; then
    {
      echo "# Codex project config. install.sh manages the marked blocks (see the scaffold's .codex/README.md); add your own settings outside them."
      block_text default-permissions "$tmp/cfg.top"
      echo
      block_text permissions-workflow "$tmp/cfg.tables"
    } >"$tmp/config.toml"
  elif ! cur_json=$(yq -p toml -o json -I=0 '.' "$CFG" 2>/dev/null); then
    refuse ".codex/config.toml: not valid TOML; fix it first (--force does not override this)"
  else
    cp "$CFG" "$tmp/cfg.work"
    st_top=$(block_state "$CFG" default-permissions)
    st_tab=$(block_state "$CFG" permissions-workflow)
    cfg_ok=1
    for st in "$st_top" "$st_tab"; do
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
printf '%s\n' 'specs/*/.step' '.cache-staging/' '.worktrees/' >"$tmp/gi.block"
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
  write_file "$tmp/gitignore" "$GI" ".gitignore (specs/*/.step, .cache-staging/, .worktrees/)"
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
echo "  Run the project-setup skill in the target to create GLOSSARY.md, docs/, profiles/, model-map/ and agent-overrides.yaml."
exit 0
