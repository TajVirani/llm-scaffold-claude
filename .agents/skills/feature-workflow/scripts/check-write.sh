#!/usr/bin/env bash
# File: Shared script (host-neutral, not a hook): decide whether a file write is allowed at the current workflow step.
# Purpose: One home for the write rules behind spec-single-writer-guard, tier-a-write-guard and tier-b-write-guard (D9).
# Usage:
#   check-write.sh --cwd <payload cwd> --path <target> [--agent <agent_id or agent_type>] [--only spec|tier-a|tier-b] [--proposed <file>]
#     --cwd       payload cwd (D18); relative --path values resolve against it.
#     --path      the file the tool would write (absolute or relative).
#     --agent     pass it when the payload carries agent_id (only sub-agent calls do; verified 2.1.300, D16). Its value is used in the message only.
#     --only      evaluate only that path class and allow everything else, so each guard hook handles only its own paths.
#                 `spec` covers .workflow/specs/*/spec.md, .workflow/specs/*/tasks.md, .workflow/specs/*/tasks/**, .workflow/specs/*/.step and .workflow/specs/work-backlog/** (all handled by spec-single-writer-guard).
#     --proposed  file holding the full content the write would produce (spec.md only): denied if it changes `status`
#                 or `blocked_condition`, which only status-transition.sh may change.
# Rules, in order (path classes compared case-insensitively, repo-relative to the worktree that holds the path):
#   tier-b   .workflow/cache/**                          deny always, any writer. Caches arrive only via regenerate-caches/scripts/publish-cache.sh (D17).
#   spec     .workflow/specs/work-backlog/**                  deny sub-agents. Main session: allow only when the origin spec's .step names 00.26
#                                                   (write the item) or 5.9 (status / promoted link) (D57), or when the newest .step of
#                                                   any spec names 0.1.4 (a new spec seeded from the item marks it promoted; D69). The origin
#                                                   spec comes from the file name <NNN-slug>-disc-<###>.md; any other name is denied.
#                                                   Deleting a promoted item (Bash rm at the new spec's 0.6 / 0.3.20, D69) is not a file-tool
#                                                   write and is not checked here.
#                                                   .workflow/specs/work-backlog/ is not a spec folder: the spec.md/tasks.md/.step rules and the
#                                                   in-flight scan below ignore it.
#   spec     .workflow/specs/*/.step                          deny always. Only status-transition.sh writes the marker (D16, D36).
#   spec     .workflow/specs/*/spec.md                        deny sub-agents. Main session: allow only when that spec's .step names
#                                                   0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9 or 00.29,
#                                                   and (with --proposed) status/blocked_condition are unchanged (a new file must say status: draft).
#   spec     .workflow/specs/*/tasks.md,                      deny sub-agents. Main session: allow only when that spec's .step names 2.5 or 0.3.20
#            .workflow/specs/*/tasks/** (per-task bodies,    (creating or replacing the file); otherwise point at status-transition.sh set-task (D45).
#            tasks/Tnn-<slug>.md, D85)                       Bodies follow the same rule as the index (D85).
#   tier-a   .workflow/GLOSSARY.md, .workflow/GLOSSARY-MAP.md at any   deny sub-agents. Main session: allow when no feature is in flight (no .workflow/specs/*/spec.md
#            depth (D46),                          with a status other than done: project-setup and standalone domain-modeling);
#            .workflow/capabilities.md, .workflow/rules.md,   otherwise allow only when the newest .step among in-flight specs names an allowed step:
#            .workflow/decisions/**, .workflow/profiles/**           glossary files: 0.2.3, 0.3.15, 0.4.3, 5.3 (D51)
#                                                     .workflow/profiles/**: editing an existing file 5.3 only; creating a new file 00.19 or 5.3 (D50)
#                                                     other Tier A (rules.md, capabilities.md, decisions/**): 0.3.7, 5.3, 5.7 (D51)
#                                                   else redirect to a 5.2 proposal (D21).
#   other    everything else                        allow.
#   (The in-flight scan skips .workflow/specs/work-backlog/.)
# Triggers/inputs: Reads the gitignored step marker .workflow/specs/NNN-slug/.step (format owned by status-transition.sh: `step: "<node>"`, `updated_at: "<UTC>"`,
#   optional `blocked_from`) and the spec.md frontmatter `status`, both from the MAIN checkout found with `git rev-parse --git-common-dir`,
#   because gitignored state exists only there (D18). Needs mikefarah yq v4 only for Tier A checks and --proposed (D38).
# Outputs/handoff: exit 0 allow (reason on stdout); exit 2 deny (reason on stderr); exit 1 usage or environment error (adapters should treat it as deny).
#   Host adapters translate this to their decision format.
# Called by: hooks/spec-single-writer-guard.sh (--only spec), tier-a-write-guard.sh (--only tier-a), tier-b-write-guard.sh (--only tier-b);
#   phase modules call it directly before writing on hosts without write hooks (advisory, D9).
# Plan refs: 0.1.4, 00.26, 5.9, Tier A, Tier B; reference "Hooks" (allowed steps per path); assetlist D9, D16, D17, D18, D21, D36, D45, D46, D50-D54, D57, D58, D69, D85.
# Notes: Accident prevention only. Bash writes bypass Write/Edit hooks; hard limits come from the permission deny rules Edit(.workflow/cache/**) and Edit(.workflow/specs/*/.step) (D16, D36).
# Sources: first-party; PLAN/decision-flow-reference.md "Hooks", "Per-feature files", "Persistent files", "Project context: Tier A and Tier B", "Discovered work"; PLAN/hook-verification.md (agent_id only on sub-agent calls; worktree cwd); assetlist D9, D16, D17, D18, D21, D36, D38, D45, D46, D50-D54, D57, D58; skills/domain-modeling/SKILL.md (Tier A step values).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=check-write.sh
# spec.md: 0.1.6/0.3.19/0.5.1/5.1 from the plan; added by user decision: 0.1.4 (creation), 0.3.17 and 4.8 (deferred[]),
# 1.1 and 3.1 (baseline_revision: full path at 1.1, light path at 3.1; D53), 3.14 (Known gaps, deferred[]),
# 4.6 (followup_review_recommended; D54), 5.3 (provisional capability ids rewritten; D52),
# 0.3.20 and 2.5 (budget written with tasks.md; D58), 00.29 (budget raised after an approved overrun; D58),
# 5.9 (a backlog item moved to .workflow/deferred/ adds to deferred[]; D69).
SPEC_STEPS="0.1.4 0.1.6 0.3.17 0.3.19 0.3.20 0.5.1 1.1 2.5 3.1 3.14 4.6 4.8 5.1 5.3 5.9 00.29"
TASKS_STEPS="2.5 0.3.20"
BACKLOG_STEPS="00.26 5.9"                         # D57: .workflow/specs/work-backlog/** items (origin spec's .step)
BACKLOG_SEED_STEP="0.1.4"                         # D69: newest .step of any spec (new spec seeded from an item)
GLOSSARY_STEPS="0.2.3 0.3.15 0.4.3 5.3"           # D51
TIER_A_STEPS="0.3.7 5.3 5.7"                     # D51: every other Tier A path (rules.md, capabilities.md, decisions/**)
PROFILE_EDIT_STEPS="5.3"                          # D50: an existing .workflow/profiles/** file
PROFILE_CREATE_STEPS="00.19 5.3"                  # D50: a new .workflow/profiles/** file (00.19 in-flow, 5.3 approved proposal)

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 1; }
allow() { printf 'allow: %s\n' "$1"; exit 0; }
deny() { printf 'deny: %s\n' "$1" >&2; exit 2; }

usage() {
  echo "usage: check-write.sh --cwd <dir> --path <target> [--agent <id>] [--only spec|tier-a|tier-b] [--proposed <file>]" >&2
  exit 1
}

# in_list <word> "<space-separated list>"
in_list() {
  local w
  # shellcheck disable=SC2086 # split the list on purpose
  for w in $2; do [[ "$w" == "$1" ]] && return 0; done
  return 1
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

require_yq() {
  command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (D38)"
  yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (D38)"
}

# Lexically normalise an absolute path: drop empty and '.' segments, resolve '..'.
lex_norm() {
  local IFS=/ seg out=()
  set -f
  # shellcheck disable=SC2086 # split on '/' on purpose
  set -- $1
  set +f
  for seg in "$@"; do
    case "$seg" in
      ''|.) ;;
      ..) [[ ${#out[@]} -gt 0 ]] && unset 'out[${#out[@]}-1]' ;;
      *) out+=("$seg") ;;
    esac
  done
  if [[ ${#out[@]} -eq 0 ]]; then printf '/\n'; else printf '/%s\n' "${out[*]}"; fi
}

# Canonical absolute path: symlinks resolved in the longest existing ancestor (e.g. /tmp -> /private/tmp).
canon() {
  local p=$1 rest="" base
  while [[ ! -d "$p" ]]; do
    base=$(basename "$p")
    rest="/$base$rest"
    p=$(dirname "$p")
  done
  p=$(cd -P "$p" && pwd)
  [[ "$p" == "/" ]] && p=""
  printf '%s%s\n' "$p" "$rest"
}

# Nearest existing directory at or above a path.
existing_dir() {
  local p=$1
  while [[ ! -d "$p" ]]; do p=$(dirname "$p"); done
  printf '%s\n' "$p"
}

main_root() {
  local common
  common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  if [[ "$(basename "$common")" == ".git" ]]; then
    (cd -P "$(dirname "$common")" && pwd)
  else
    git -C "$1" worktree list --porcelain | sed -n '1s/^worktree //p'
  fi
}

marker_get() {
  local file=$1 key=$2
  [[ -f "$file" ]] || return 0
  sed -n "s/^${key}:[[:space:]]*\"\{0,1\}\([^\"]*\)\"\{0,1\}[[:space:]]*$/\1/p" "$file" | head -1
}

# ---------------------------------------------------------------- arguments
CWD="" TARGET="" AGENT="" HAVE_AGENT=0 ONLY="" PROPOSED=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)      [[ $# -ge 2 ]] || usage; CWD=$2; shift 2 ;;
    --path)     [[ $# -ge 2 ]] || usage; TARGET=$2; shift 2 ;;
    --agent)    [[ $# -ge 2 ]] || usage; AGENT=$2; HAVE_AGENT=1; shift 2 ;;
    --only)     [[ $# -ge 2 ]] || usage; ONLY=$2; shift 2 ;;
    --proposed) [[ $# -ge 2 ]] || usage; PROPOSED=$2; shift 2 ;;
    -h|--help)  usage ;;
    *)          die "unknown argument: $1" ;;
  esac
done
[[ -n "$CWD" && -n "$TARGET" ]] || usage
[[ -d "$CWD" ]] || die "--cwd is not a directory: $CWD"
case "$ONLY" in ''|spec|tier-a|tier-b) ;; *) die "--only must be spec, tier-a or tier-b" ;; esac
if [[ $HAVE_AGENT -eq 1 && -z "$AGENT" ]]; then AGENT="unknown"; fi
if [[ -n "$PROPOSED" && ! -f "$PROPOSED" ]]; then die "--proposed file not found: $PROPOSED"; fi

# ---------------------------------------------------------------- resolve the repo-relative path
CWD=$(cd -P "$CWD" && pwd)
[[ "$TARGET" == /* ]] || TARGET="$CWD/$TARGET"
ABS=$(canon "$(lex_norm "$TARGET")")

TOP=$(git -C "$(existing_dir "$ABS")" rev-parse --show-toplevel 2>/dev/null) \
  || TOP=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null) || TOP=""
[[ -n "$TOP" ]] || allow "not inside a git repository: $ABS"
TOP=$(cd -P "$TOP" && pwd)
case "$ABS" in
  "$TOP"/*) REL=${ABS#"$TOP"/} ;;
  *) allow "outside the project: $ABS" ;;
esac
LC=$(lower "$REL")

# ---------------------------------------------------------------- classify
CLASS=other KIND=""
# Lower-cased guarded roots from lib/workflow-paths.sh (D81). Prefix tests compare whole segments ("$P"/*), so a
# look-alike such as .workflow/specs-x/ or .workflow/cache2/ is not matched.
P_CACHE=$(lower "$WF_CACHE") P_SPECS=$(lower "$WF_SPECS") P_BACKLOG=$(lower "$WF_WORK_BACKLOG")
P_PROFILES=$(lower "$WF_PROFILES") P_DECISIONS=$(lower "$WF_DECISIONS")
P_RULES=$(lower "$WF_RULES") P_CAPABILITIES=$(lower "$WF_CAPABILITIES")
SPEC_REST=""
[[ "$LC" != "$P_SPECS"/* ]] || SPEC_REST=${LC#"$P_SPECS"/}
if [[ "$LC" == "$P_CACHE" || "$LC" == "$P_CACHE"/* ]]; then
  CLASS=tier-b
elif [[ "$LC" == "$P_BACKLOG" || "$LC" == "$P_BACKLOG"/* ]]; then
  CLASS=spec KIND=backlog                    # checked first: not a spec folder (D57)
elif [[ "$SPEC_REST" =~ ^[^/]+/\.step$ ]]; then
  CLASS=spec KIND=marker
elif [[ "$SPEC_REST" =~ ^[^/]+/spec\.md$ ]]; then
  CLASS=spec KIND=spec
elif [[ "$SPEC_REST" =~ ^[^/]+/tasks\.md$ ]]; then
  CLASS=spec KIND=tasks
elif [[ "$SPEC_REST" =~ ^[^/]+/tasks/.+ ]]; then
  CLASS=spec KIND=tasks                      # per-task bodies tasks/Tnn-<slug>.md, same writer rule as tasks.md (D85)
elif [[ "$LC" == "glossary.md" || "$LC" == */glossary.md || "$LC" == "glossary-map.md" || "$LC" == */glossary-map.md ]]; then
  CLASS=tier-a KIND=glossary                 # any depth (D46), so .workflow/GLOSSARY.md and per-context glossaries
elif [[ "$LC" == "$P_PROFILES" || "$LC" == "$P_PROFILES"/* ]]; then
  CLASS=tier-a KIND=profile
elif [[ "$LC" == "$P_CAPABILITIES" || "$LC" == "$P_RULES" || "$LC" == "$P_DECISIONS" || "$LC" == "$P_DECISIONS"/* ]]; then
  CLASS=tier-a KIND=tier-a
fi

[[ "$CLASS" != "other" ]] || allow "$REL is not a guarded path"
[[ -z "$ONLY" || "$ONLY" == "$CLASS" ]] || allow "$REL is not a $ONLY path"

WHO="main session"
[[ $HAVE_AGENT -eq 1 ]] && WHO="sub-agent ($AGENT)"

# ---------------------------------------------------------------- Tier B
if [[ "$CLASS" == "tier-b" ]]; then
  deny "$REL is a Tier B cache under $WF_CACHE/; no file-tool write lands there, from any writer. Regenerate it with the regenerate-caches skill: cache-regeneration writes to the staging path and skills/regenerate-caches/scripts/publish-cache.sh stamps it and moves it in (D17)."
fi

# ---------------------------------------------------------------- step marker
if [[ "$KIND" == "marker" ]]; then
  deny "$REL is the step marker; only skills/feature-workflow/scripts/status-transition.sh writes it (run: status-transition.sh step $WF_SPECS/<NNN-slug> <node-id>) (D16, D36)."
fi

# ---------------------------------------------------------------- sub-agents
if [[ $HAVE_AGENT -eq 1 ]]; then
  deny "$REL is protected ($CLASS) and the write comes from a $WHO. Only the main session writes spec.md, tasks.md, $WF_WORK_BACKLOG/ and Tier A, at approved steps (D16, D57). Return the proposed change (or the discovered-work report) in your output instead."
fi

ROOT=$(main_root "$TOP") || die "cannot locate the main checkout from $TOP"

# ---------------------------------------------------------------- .workflow/specs/work-backlog/ (D57)
if [[ "$KIND" == "backlog" ]]; then
  ITEM=${REL:${#WF_WORK_BACKLOG}+1}
  if [[ ! "$ITEM" =~ ^([0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*)-disc-[0-9]{3,}\.md$ ]]; then
    deny "$REL: backlog items are named $WF_WORK_BACKLOG/<origin NNN-slug>-disc-<###>.md (D57), written by the main session at 00.26 or 5.9."
  fi
  ORIGIN=${BASH_REMATCH[1]}
  STEP=$(marker_get "$ROOT/$WF_SPECS/$ORIGIN/.step" step)
  if [[ -n "$STEP" ]] && in_list "$STEP" "$BACKLOG_STEPS"; then
    allow "$REL: work-backlog item, main session at step $STEP ($WF_SPECS/$ORIGIN)"
  fi
  NEW_AT="" NEW_STEP="" NEW_SPEC=""
  for mk in "$ROOT/$WF_SPECS"/*/.step; do
    [[ -f "$mk" ]] || continue
    [[ "$(lower "$(basename "$(dirname "$mk")")")" != "work-backlog" ]] || continue
    at=$(marker_get "$mk" updated_at)
    if [[ -z "$NEW_STEP" || "$at" > "$NEW_AT" ]]; then
      NEW_AT=$at NEW_STEP=$(marker_get "$mk" step) NEW_SPEC="$WF_SPECS/$(basename "$(dirname "$mk")")"
    fi
  done
  if [[ "$NEW_STEP" == "$BACKLOG_SEED_STEP" ]]; then
    allow "$REL: work-backlog item, main session seeding $NEW_SPEC at step 0.1.4 (D69)"
  fi
  deny "$REL: origin spec $WF_SPECS/$ORIGIN is at step ${STEP:-<none>}; work-backlog items are written only at 00.26 (new item) or 5.9 (status at sign-off) of the origin spec, or at 0.1.4 of a new spec seeded from the item. Set the step with status-transition.sh step $WF_SPECS/$ORIGIN 00.26 | 5.9 (D57, D69)."
fi

# ---------------------------------------------------------------- tasks.md
if [[ "$KIND" == "tasks" ]]; then
  SPEC_NAME=${SPEC_REST%%/*}
  STEP=$(marker_get "$ROOT/$WF_SPECS/$SPEC_NAME/.step" step)
  if [[ -n "$STEP" ]] && in_list "$STEP" "$TASKS_STEPS"; then
    allow "$REL: main session at step $STEP"
  fi
  deny "$REL: current step is ${STEP:-<none>}; tasks.md and the task bodies under tasks/ are created or replaced only at 2.5 or 0.3.20. Change a task record with status-transition.sh set-task $WF_SPECS/$SPEC_NAME <task-id> --status <status> | --work-type <work-type> (D45)."
fi

# ---------------------------------------------------------------- spec.md
if [[ "$KIND" == "spec" ]]; then
  SPEC_NAME=${SPEC_REST%%/*}
  MARKER="$ROOT/$WF_SPECS/$SPEC_NAME/.step"
  STEP=$(marker_get "$MARKER" step)
  if [[ -z "$STEP" ]]; then
    deny "$REL: no step marker at $WF_SPECS/$SPEC_NAME/.step. spec.md is written only at $SPEC_STEPS; set the step first with status-transition.sh step $WF_SPECS/$SPEC_NAME <node-id> (D16)."
  fi
  if ! in_list "$STEP" "$SPEC_STEPS"; then
    deny "$REL: current step is $STEP; spec.md is written only at $SPEC_STEPS (single writer, 0.1.4). Status changes go through status-transition.sh, never Write/Edit."
  fi
  if [[ -n "$PROPOSED" ]]; then
    require_yq
    NEW_STATUS=$(yq --front-matter=extract '.status // ""' "$PROPOSED" 2>/dev/null) \
      || deny "$REL: cannot read the frontmatter of the proposed content; spec.md must keep valid frontmatter."
    NEW_COND=$(yq --front-matter=extract '.blocked_condition // ""' "$PROPOSED")
    if [[ -f "$ABS" ]]; then
      OLD_STATUS=$(yq --front-matter=extract '.status // ""' "$ABS" 2>/dev/null) || OLD_STATUS=""
      OLD_COND=$(yq --front-matter=extract '.blocked_condition // ""' "$ABS" 2>/dev/null) || OLD_COND=""
    else
      OLD_STATUS=draft OLD_COND=""
    fi
    if [[ "$NEW_STATUS" != "$OLD_STATUS" || "$NEW_COND" != "$OLD_COND" ]]; then
      deny "$REL: this write changes status or blocked_condition ('$OLD_STATUS' -> '$NEW_STATUS'). Status changes go only through status-transition.sh status $WF_SPECS/$SPEC_NAME <status> (D16)."
    fi
  fi
  allow "$REL: main session at step $STEP"
fi

# ---------------------------------------------------------------- Tier A
require_yq
IN_FLIGHT=0 BEST_AT="" BEST_STEP="" BEST_SPEC=""
for spec in "$ROOT/$WF_SPECS"/*/spec.md; do
  [[ -f "$spec" ]] || continue
  [[ "$(lower "$(basename "$(dirname "$spec")")")" != "work-backlog" ]] || continue   # not a spec folder (D57)
  status=$(yq --front-matter=extract '.status // ""' "$spec" 2>/dev/null) || status="unreadable"
  [[ "$status" == "done" ]] && continue
  IN_FLIGHT=1
  dir=$(dirname "$spec")
  at=$(marker_get "$dir/.step" updated_at)
  st=$(marker_get "$dir/.step" step)
  [[ -n "$st" ]] || continue
  if [[ -z "$BEST_STEP" || "$at" > "$BEST_AT" ]]; then
    BEST_AT=$at BEST_STEP=$st BEST_SPEC="$WF_SPECS/$(basename "$dir")"
  fi
done

[[ $IN_FLIGHT -eq 1 ]] || allow "$REL: Tier A, main session, no feature in flight"

case "$KIND" in
  glossary) STEPS=$GLOSSARY_STEPS WHAT="Glossary files are" ;;
  profile)
    if [[ -e "$ABS" ]]; then STEPS=$PROFILE_EDIT_STEPS WHAT="An existing profile is"
    else STEPS=$PROFILE_CREATE_STEPS WHAT="A new profile is"; fi ;;
  *)        STEPS=$TIER_A_STEPS WHAT="Tier A is" ;;
esac
if [[ -z "$BEST_STEP" ]]; then
  deny "$REL is Tier A and a feature is in flight, but no in-flight spec has a step marker. $WHAT written only at $STEPS: set the step with status-transition.sh step $WF_SPECS/<NNN-slug> <node-id>, or propose the change in $WF_SPECS/<NNN-slug>/proposals.md for approval at 5.3 (D21)."
fi
if in_list "$BEST_STEP" "$STEPS"; then
  allow "$REL: Tier A ($KIND), main session at step $BEST_STEP ($BEST_SPEC)"
fi
deny "$REL is Tier A; current step is $BEST_STEP ($BEST_SPEC). $WHAT written only at $STEPS. Record the change as a 5.2 proposal in $BEST_SPEC/proposals.md for approval at 5.3 instead (D21)."
