#!/usr/bin/env bash
# File: Hook (Claude and Codex adapter): offer to resume in-flight work.
# Goals:
#   - Scan .workflow/specs/*/spec.md frontmatter for features that are not done (spec.md frontmatter is the only status record), in every
#     checkout a spec can run in: the session's own, each worktree on a spec/* branch (the spec worktrees) and the main checkout
#   - List the initiatives still to resume (large-path subjects that plan several specs), from the working tree or their initiative/* branch
#   - Offer to resume at the recorded step via feature-workflow
#   - List session handoffs in .workflow/.handoff/*.md (written by the handoff skill in each run's own checkout) so a fresh session
#     can pick one up and tell its own from another run's
# Triggers/inputs: SessionStart JSON on stdin (any `source`: startup, resume, clear, compact; all get the offer, since a cleared or compacted
#   context has lost it). Paths from the payload `cwd`. Specs and their gitignored .step markers are read in
#   each checkout above (lib/workflow-paths.sh wf_project_root for the session's own; `git worktree list` for the rest); the backlog
#   and initiatives in the main checkout (wf_main_root). Handoffs are read in the session's own checkout (the top level of `cwd`:
#   the main checkout, a spec worktree, or an isolation or agent worktree), then, from the main checkout, in each spec worktree,
#   and from any other checkout, in the main checkout only.
# Behaviour:
#   - No spec.md with a status other than `done`, no initiative to resume, no open backlog item and no session handoff: exit 0, no output.
#   - Each non-done spec (draft, ready-for-dev, in-progress, in-review, blocked; sorted by folder name within each checkout, the session's
#     checkout first, then the spec worktrees, then the main checkout; a folder name already listed from an earlier checkout is skipped)
#     is listed with its status, "runs in <checkout>" when that is not the session's checkout,
#     blocked_condition (while blocked), and the current step from .workflow/specs/NNN-slug/.step (step, updated_at, blocked_from), "no .step marker"
#     when the file is absent, or "step marker unreadable" when it exists and cannot be parsed.
#     A spec.md whose frontmatter cannot be read is listed as unreadable rather than skipped.
#   - Initiatives (.workflow/initiatives/NNN-slug, sorted by name), each listed once as
#     `- .workflow/initiatives/NNN-slug: status <s>; current step <id> (since <t>); research pending: <n>`, where <n> counts the questions in
#     questions.md with state `researching` and the step comes from the gitignored .step in the main checkout. Listed: `exploring`, and
#     `planned` while a spec made from one of its slices is not `done` on origin/<main_branch> in the Done folder
#     .workflow/specs/done/ (else <main_branch>; rules-setting.sh
#     main_branch; when that setting cannot be read, main is used and the offer says so).
#     Omitted: `done`, and `planned` with every emitted spec done. Read from the local initiative/NNN-slug branch with `git show` when it
#     exists and is not checked out, else from the working tree, else from origin/initiative/NNN-slug; never by switching branches.
#     An initiative.md that cannot be read is listed as unreadable, and one found in none of those places as missing; neither is skipped.
#   - The text ends with the next action: load the feature-workflow skill for the chosen spec, which routes by spec.md status; a blocked spec
#     needs its blocked_condition resolved by a human first (except a size budget one); an initiative resumes through feature-workflow's large path.
#   - A blocked spec whose blocked_condition starts with `discovered work:` is flagged "discovered-work prompt pending"; one starting
#     `size budget:` (an older version) is flagged as resuming without a ruling.
#   - .workflow/specs/work-backlog/ is not a spec folder and is skipped by the scan. Its open items are summarised as a count plus up to 5 names,
#     and alone are enough to produce output: each `- [open] B<n> ...` line of a spec's backlog list <NNN-slug>.md (named <NNN-slug>.md#B<n>).
#     A list may be named old_<NNN-slug>.md, the name adopting an issue tracker gives a Done spec's list, matching the names the write guard
#     accepts in work-backlog/. Other files there are ignored.
#   - Session handoffs (.workflow/.handoff/*.md in each checkout above, any file name, never the folder's .gitignore): the own checkout's
#     first as `- .workflow/.handoff/<name>`, then the other checkouts' as `- <absolute path>`, each group newest first by mtime. A file
#     is the own checkout's only when it is in <own checkout>/.workflow/.handoff/, since spec worktrees sit inside the main checkout.
#     Up to 3 listed in total with frontmatter created, spec and goal (or "frontmatter unreadable"), each cut at 300 characters, the rest
#     counted; alone they are enough to produce output, and the text names the handoff skill's Resume.
#   - The text is capped below the 10,000-character additionalContext limit: specs past the cap are counted, not listed.
# Outputs/handoff: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<resume offer>"}} or nothing; exit 0 always.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh): SessionStart.
#   codex-hooks.template.json (<target>/.codex/hooks.json): SessionStart, no matcher; Codex also reads additionalContext.
# Notes: feature-workflow also performs the same scan on entry, for hosts where this hook is not installed. The list includes draft and ready-for-dev specs as well as the
#   in-progress, in-review and blocked ones, so a feature paused in discovery is also offered.
# Sources: first-party; hooks reference https://code.claude.com/docs/en/hooks
#   (SessionStart additionalContext); spec.md frontmatter contract in skills/feature-workflow/assets/spec.md; .step format in
#   skills/feature-workflow/scripts/status-transition.sh; initiative.md and questions.md frontmatter in skills/feature-workflow/assets/; handoff frontmatter in skills/handoff/assets/handoff.md.
# Requires: bash, jq, mikefarah yq v4, git (optional; initiatives on a branch and the done-on-main check need it).

set -euo pipefail

# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"

LIMIT=9000      # characters of list text; leaves room for the header and footer under the 10,000 cap
TIME_BUDGET=6   # seconds spent reading specs before the rest are only counted (hook timeout 10 s)

command -v jq >/dev/null 2>&1 || exit 0
payload=$(cat)
cwd=$(jq -r 'if type == "object" then .cwd // "" | strings else "" end' <<<"$payload" 2>/dev/null || true)
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
root=$(cd "$cwd" && pwd)
here=$root
if main=$(wf_main_root "$root" 2>/dev/null); then root=$main; fi
if spec_root=$(wf_project_root "$here" 2>/dev/null); then here=$spec_root; fi

shopt -s nullglob
spec_worktrees=$({ git -C "$root" worktree list --porcelain 2>/dev/null || true; } |
  awk '/^worktree /{ wt = substr($0, 10) } /^branch refs\/heads\/spec\//{ print wt }')
# Specs run in their own worktrees, so each checkout that can hold one is scanned: this session's, then every worktree on a spec
#   branch, then the main checkout. A spec folder seen in an earlier checkout is not listed again.
checkouts=$( {
  printf '%s\n' "$here"
  [ -z "$spec_worktrees" ] || printf '%s\n' "$spec_worktrees"
  printf '%s\n' "$root"
} | awk '!seen[$0]++')
specs=()
seen_specs=" "
while IFS= read -r checkout; do
  [ -n "$checkout" ] || continue
  for spec in "$checkout/$WF_SPECS"/*/spec.md; do
    name=$(basename "$(dirname "$spec")")
    case "$seen_specs" in *" $name "*) continue ;; esac
    seen_specs+="$name "
    specs+=("$spec")
  done
done <<<"$checkouts"
backlog=("$root/$WF_WORK_BACKLOG"/*.md)
# Each run writes its handoff in the checkout it ran in, so this session's own checkout (the top level of its cwd, even an
#   isolation or agent worktree) comes first. The main checkout also sees every spec worktree's handoffs; any other checkout
#   sees only the main checkout's, so a run never picks up a sibling worktree's handoff.
own_checkout=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || own_checkout=""
[ -n "$own_checkout" ] || own_checkout=$(cd "$cwd" && pwd)
own_handoffs=("$own_checkout/$WF_HANDOFF"/*.md)
if [ "$own_checkout" = "$root" ]; then other_checkouts=$spec_worktrees; else other_checkouts=$root; fi
other_handoffs=()
while IFS= read -r checkout; do
  [ -n "$checkout" ] && [ "$checkout" != "$own_checkout" ] || continue
  other_handoffs+=("$checkout/$WF_HANDOFF"/*.md)
done <<<"$other_checkouts"
h_total=$(( ${#own_handoffs[@]} + ${#other_handoffs[@]} ))

# An initiative in exploration is committed only on its own branch, so a checkout on main finds it through the branch names.
initiative_names=$(
  {
    for d in "$root/$WF_INITIATIVES"/*/initiative.md; do basename "$(dirname "$d")"; done
    # git is optional: outside a repository there are no branch names, and the folder scan above still counts.
    { git -C "$root" for-each-ref --format='%(refname:lstrip=2)' refs/heads/initiative refs/remotes/origin/initiative 2>/dev/null || true; } \
      | sed -n 's|^initiative/\([^/]*\)$|\1|p; s|^origin/initiative/\([^/]*\)$|\1|p'
  } | sort -u
)
[ "${#specs[@]}" -gt 0 ] || [ "${#backlog[@]}" -gt 0 ] || [ "$h_total" -gt 0 ] || [ -n "$initiative_names" ] || exit 0
command -v yq >/dev/null 2>&1 || exit 0

# Fast prefilter (no yq): the raw `status:` value of the frontmatter, quotes and comment stripped. Used to skip `done` specs cheaply and
# to count specs past the cap; every listed spec is read with yq.
raw_status() {
  awk 'NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit; next }
       /^---[[:space:]]*$/ { exit }
       /^status:/ { v = $0; sub(/^status:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*$/, "", v); gsub(/["\047]/, "", v); sub(/[[:space:]]+$/, "", v); print v; exit }' "$1"
}

# JSON array on stdin (from yq) -> one value per line; null -> "", whitespace runs folded so each value stays on one line.
lines() { jq -r 'if type == "array" then .[] else error("not an array") end | if . == null then "" else tostring | gsub("\\s+"; " ") end'; }

# newest_first FILE... : FILE paths one per line, newest first by mtime; nothing for no FILE.
newest_first() {
  [ "$#" -gt 0 ] || return 0
  # shellcheck disable=SC2012  # names come from the handoff skill (kebab-case); ls -t is the portable mtime sort
  ls -1t "$@"
}

# Read the handoffs before the spec list, so the spec list's cap leaves room for them.
htext="" h_n=0
HANDOFF_HEADER="Session handoffs (written by the handoff skill in the checkout each run worked in): this checkout's first as $WF_HANDOFF/<name>, then the other checkouts' by absolute path; newest first within each:"
if [ "$h_total" -gt 0 ]; then
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    h_n=$((h_n + 1))
    [ "$h_n" -le 3 ] || continue
    # A spec worktree sits inside the main checkout, so only a file in the own checkout's handoff folder is the session's own,
    #   and gets the short path it can open from where it is.
    case "$h" in
      "$own_checkout/$WF_HANDOFF/"*) entry="- $WF_HANDOFF/$(basename "$h")" ;;
      *) entry="- $h" ;;
    esac
    if hf=$(yq --front-matter=extract -o=json -I=0 '[.goal, .spec, .created]' "$h" 2>/dev/null | lines); then
      goal="" hspec="" created=""
      { IFS= read -r goal; IFS= read -r hspec; IFS= read -r created; } <<<"$hf" || true
      [ -z "$created" ] || entry+=" (created $created)"
      [ -z "$hspec" ] || entry+="; spec $hspec"
      [ -z "$goal" ] || entry+=": $goal"
    else
      entry+=": frontmatter unreadable; open it to read the handoff."
    fi
    htext+=${entry:0:300}$'\n'
  done < <(
    newest_first ${own_handoffs[@]+"${own_handoffs[@]}"}  # bash 3.2 treats an empty array as unset under set -u
    newest_first ${other_handoffs[@]+"${other_handoffs[@]}"}
  )
  [ "$h_n" -le 3 ] || htext+="- ... and $((h_n - 3)) older not listed.
"
  LIMIT=$((LIMIT - ${#HANDOFF_HEADER} - ${#htext}))
fi

# step_text MARKER : "current step <id> (since <time>)" from a .step marker, "no .step marker", or "step marker unreadable".
step_text() {
  local st step="" at="" from=""
  if [ ! -f "$1" ]; then
    printf 'no .step marker'
  elif st=$(yq -o=json -I=0 '[.step, .updated_at, .blocked_from]' "$1" 2>/dev/null | lines); then
    { IFS= read -r step; IFS= read -r at; IFS= read -r from; } <<<"$st" || true
    printf 'current step %s' "${step:-unknown}"
    [ -z "$at" ] || printf ' (since %s)' "$at"
    [ -z "$from" ] || printf '; blocked from %s' "$from"
  else
    printf 'step marker unreadable'
  fi
}

# initiative_ref NAME : the git ref to read initiative NAME from, empty for the working tree; fails when it is nowhere.
# The local branch wins unless it is checked out, because after a reopen it is newer than the copy merged into main.
initiative_ref() {
  local branch=initiative/$1
  if git -C "$root" rev-parse -q --verify "refs/heads/$branch" >/dev/null 2>&1 \
    && [ "$(git -C "$root" symbolic-ref -q --short HEAD 2>/dev/null)" != "$branch" ]; then
    printf '%s' "$branch"
  elif [ -f "$root/$WF_INITIATIVES/$1/initiative.md" ]; then
    printf ''
  elif git -C "$root" rev-parse -q --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
    printf 'origin/%s' "$branch"
  else
    return 1
  fi
}

# initiative_file NAME FILE REF : FILE of initiative NAME, from REF or, when REF is empty, from the working tree.
initiative_file() {
  if [ -z "$3" ]; then cat "$root/$WF_INITIATIVES/$1/$2"; else git -C "$root" show "$3:$WF_INITIATIVES/$1/$2"; fi
}

# A spec is done once it is done on the main branch; on its own branch it reads done before the merge lands.
main_ref="" main_warning=""
# spec_done_on_main SPEC : succeeds when SPEC's spec.md has status done on origin/<main> (or <main> without a remote copy),
#   in the Done folder.
spec_done_on_main() {
  if [ -z "$main_ref" ]; then
    local main err_file
    err_file=$(mktemp 2>/dev/null) || err_file=""
    # Fall back to main rather than exit: a failed SessionStart hook would lose the whole offer, so the problem is reported in it instead.
    if ! main=$(bash "$root/.agents/skills/feature-workflow/scripts/rules-setting.sh" main_branch --cwd "$root" 2>"${err_file:-/dev/null}"); then
      main=main
      main_warning="Warning: main branch setting unreadable ($([ -z "$err_file" ] || tr '\n' ' ' <"$err_file" | sed 's/ *$//')); done-on-main checks used main."
    fi
    [ -z "$err_file" ] || rm -f "$err_file"
    main_ref=$main
    git -C "$root" rev-parse -q --verify "refs/remotes/origin/$main" >/dev/null 2>&1 && main_ref=origin/$main
  fi
  [ "$(git -C "$root" show "$main_ref:$WF_SPECS_DONE/$1/spec.md" 2>/dev/null | raw_status /dev/stdin)" = "done" ]
}

# Initiatives to resume: every one exploring, or planned with an emitted spec not yet done on main. Each is listed once.
itext="" i_n=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  entry="- $WF_INITIATIVES/$name:"
  if ! ref=$(initiative_ref "$name"); then
    itext+="$entry no initiative.md on disk or on its branch; open the branch to check."$'\n'
    i_n=$((i_n + 1))
    continue
  fi
  # Only a failed read is unreadable: a frontmatter with no status also leaves fm empty, and is listed as status (none).
  if ! fm=$(initiative_file "$name" initiative.md "$ref" 2>/dev/null \
    | yq --front-matter=extract -o=json -I=0 '[.status, ([.slices // [] | .[] | select(.spec != null) | .spec] | join(" "))]' 2>/dev/null | lines); then
    entry+=" initiative.md frontmatter unreadable; open it to check its status."
  else
    { IFS= read -r status; IFS= read -r emitted; } <<<"$fm" || true
    case "$status" in
      done) continue ;;
      planned)
        open_spec=""
        for s in $emitted; do spec_done_on_main "$s" || { open_spec=$s; break; }; done
        [ -n "$open_spec" ] || continue
        ;;
    esac
    researching=$(initiative_file "$name" questions.md "$ref" 2>/dev/null \
      | yq --front-matter=extract '[.questions // [] | .[] | select(.state == "researching")] | length' 2>/dev/null) || researching="unknown"
    entry+=" status ${status:-(none)}; $(step_text "$root/$WF_INITIATIVES/$name/.step"); research pending: ${researching:-0}"
    [ -z "$ref" ] || entry+="; read from branch $ref (not checked out)"
  fi
  itext+=${entry:0:600}$'\n'
  i_n=$((i_n + 1))
done <<<"$initiative_names"
LIMIT=$((LIMIT - ${#itext}))

list="" listed=0 omitted=0
for spec in ${specs[@]+"${specs[@]}"}; do
  [ "$(basename "$(dirname "$spec")")" != "work-backlog" ] || continue # the discovered-work backlog is not a spec
  [ "$(raw_status "$spec")" != "done" ] || continue
  dir=$(dirname "$spec")
  slug=$WF_SPECS/$(basename "$dir")
  checkout=${dir%/"$slug"}
  where=""
  [ "$checkout" = "$here" ] || where=" (runs in $checkout; continue the session there)"
  # Past the character cap or the time budget (the hook timeout is 10 s): count, do not list.
  if [ "${#list}" -ge "$LIMIT" ] || [ "$SECONDS" -ge "$TIME_BUDGET" ]; then
    omitted=$((omitted + 1))
    continue
  fi
  if ! fm=$(yq --front-matter=extract -o=json -I=0 '[.status, .blocked_condition]' "$spec" 2>/dev/null | lines) \
    || [ -z "$fm" ]; then
    entry="- $slug$where: spec.md frontmatter unreadable; open it to check its status."
  else
    { IFS= read -r status; IFS= read -r bc; } <<<"$fm" || true
    if [ "$status" = "done" ]; then continue; fi
    [ -n "$status" ] || status="(none)"
    entry="- $slug$where: status $status; $(step_text "$dir/.step")"
    case "$bc" in
      "discovered work:"*) entry+="; discovered-work prompt pending (the user has not yet answered it)" ;;
      "size budget:"*) entry+="; size-budget block from an older version: resumes without a ruling" ;;
    esac
    [ -z "$bc" ] || entry+="; blocked_condition: $bc"
  fi
  entry=${entry:0:600}
  if [ $(( ${#list} + ${#entry} + 1 )) -gt "$LIMIT" ]; then
    omitted=$((omitted + 1))
    LIMIT=${#list} # list is full: later specs are only counted
    continue
  fi
  list+=$entry$'\n'
  listed=$((listed + 1))
done

# Open work-backlog items: the open lines of each spec's list; a count and up to 5 names.
open_n=0 open_names=""
# add_open NAME : count one open item and keep its name while fewer than 6 are named.
add_open() {
  open_n=$((open_n + 1))
  [ "$open_n" -gt 5 ] || open_names+="${open_names:+, }$1"
}
for item in ${backlog[@]+"${backlog[@]}"}; do
  [ "$SECONDS" -lt 8 ] || break
  name=$(basename "$item")
  case "$name" in
    [0-9]*-*.md | old_[0-9]*-*.md)
      while IFS= read -r id; do add_open "$name#$id"; done < <(sed -n 's/^- \[open\] \(B[0-9][0-9]*\) .*/\1/p' "$item" 2>/dev/null) ;;
  esac
done

[ $((listed + omitted + i_n + open_n + h_n)) -gt 0 ] || exit 0

text=""
if [ $((listed + omitted)) -gt 0 ]; then
  text="In-flight features in this project (from $WF_SPECS/*/spec.md frontmatter; status and .step are written only by status-transition.sh):
$list"
fi
[ "$omitted" -eq 0 ] || text+="- ... and $omitted more not listed (character or time limit); scan $WF_SPECS/*/spec.md for the rest.
"
if [ "$i_n" -gt 0 ]; then
  text+="Initiatives in this project (large-path subjects that plan several specs; from $WF_INITIATIVES/*/initiative.md, or from the initiative/* branch tip when this checkout does not hold the folder; status and .step are written only by initiative-transition.sh):
$itext"
fi
[ -z "$main_warning" ] || text+="$main_warning
"
if [ "$open_n" -gt 0 ]; then
  text+="Open discovered-work backlog items in $WF_WORK_BACKLOG/: $open_n (${open_names}$([ "$open_n" -le 5 ] || echo ", ...")); each was kept for later by the stakeholder and can be started as a new feature through discovery.
"
fi
if [ "$h_n" -gt 0 ]; then
  text+="$HANDOFF_HEADER
$htext"
fi
INITIATIVE_RESUME="To resume an initiative, load the feature-workflow skill and name the initiative: it routes to the large path (modules/large-path.md), which reads the initiative where it lives (its branch or main) and continues from its current step."
if [ $((listed + omitted + i_n)) -eq 0 ]; then
  [ "$h_n" -eq 0 ] || text+="Offer the user to resume a handoff: load the handoff skill and follow its Resume steps. Do not resume unasked."
  jq -cn --arg c "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
  exit 0
fi
if [ $((listed + omitted)) -gt 0 ]; then
  text+="Offer the user to resume one of these. To resume, load the feature-workflow skill for that spec: it reads the spec.md status and loads the module for that phase, continuing from the current step. A spec that runs in another checkout is resumed there: move the session into that checkout first (on Claude Code, the EnterWorktree tool with its path; elsewhere, reopen the session in it). A blocked spec needs a human to resolve its blocked_condition first, unless it is a size budget one; a discovered work prompt is answered in the feature-workflow discovered-work module."
  [ "$i_n" -eq 0 ] || text+=" $INITIATIVE_RESUME"
else
  text+="Offer the user to resume one of these. $INITIATIVE_RESUME"
fi
text+=" Do not resume unasked."
[ "$h_n" -eq 0 ] || text+=" To resume a session handoff instead, load the handoff skill and follow its Resume steps; a handoff that names a spec continues through feature-workflow."

jq -cn --arg c "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
exit 0
