#!/usr/bin/env bash
# File: Fixture builder and oracle for the workflow-folder path cases: the spec or initiative folder argument the
#   feature-workflow scripts normalise. Sourced after lib/common.sh by the per-script suites and the lib suite; defines
#   variables and functions only. bash 3.2 compatible.
# Provides:
#   folder_fixture_repo DIR  git repo on branch spec/001-alpha holding spec 001-alpha (spec.md, tasks.md with T1),
#                            initiative 001-ini (initiative.md, questions.md) and the local-state ignore block; an agent
#                            worktree at DIR/.workflow/.worktrees/wt-folders, which the scripts resolve to DIR, the checkout
#                            it sits in, and a folder DIR-elsewhere, outside any repository, holding 001-alpha and 001-ini.
#                            Sets FOLDER_REPO and FOLDER_WT.
#   folder_inputs KIND       one "<form>|<cwd>|<arg>" line per input form for KIND (spec or initiative): relative,
#                            dot-relative with a trailing slash, absolute under the main checkout, absolute under the
#                            worktree, relative run from the worktree, bare NNN-slug, absolute path elsewhere, and a
#                            relative path run from a folder outside any git repository
#   folder_outcome CMD...    prints "<exit code>|<first stderr line>" for CMD; its stdout is dropped
#   folder_expected FORM CWD ARG PROG EXIT REASON ACCEPTED
#                            the outcome the scripts gave before the shared normaliser (recorded at 1.2 of spec 005):
#                            "<EXIT>|<PROG>: <REASON>: <ARG>" for a bare name or an absolute path elsewhere, the
#                            not-a-repository line for a run outside git, and ACCEPTED for every form naming the folder
#   FOLDER_SPEC, FOLDER_INITIATIVE   the repo-relative folders the accepted forms normalise to
# shellcheck disable=SC2034  # the variables are read by the suites that source this file

FOLDER_SPEC=.workflow/specs/001-alpha
FOLDER_INITIATIVE=.workflow/initiatives/001-ini

folder_fixture_repo() {
  local p=$1 assets="$AGENTS_SRC/skills/feature-workflow/assets"
  git_init_repo "$p"
  mkdir -p "$p/$FOLDER_SPEC" "$p/$FOLDER_INITIATIVE"
  cp "$assets/spec.md" "$p/$FOLDER_SPEC/spec.md"
  sed -e 's/<slug>/demo/g' -e 's#task/NNN-slug/#task/001-alpha/#' "$assets/tasks.md" >"$p/$FOLDER_SPEC/tasks.md"
  cp "$assets/initiative.md" "$p/$FOLDER_INITIATIVE/initiative.md"
  cp "$assets/questions.md" "$p/$FOLDER_INITIATIVE/questions.md"
  printf '%s\n' '.workflow/specs/*/.step' '.workflow/initiatives/*/.step' '.workflow/.worktrees/' '.workflow/.handoff/' \
    '.workflow/.standards-staging/' >"$p/.gitignore"
  git_commit_all "$p" "fixture: workflow folders"
  git -C "$p" branch -q -m spec/001-alpha
  git -C "$p" worktree add -q "$p/.workflow/.worktrees/wt-folders" -b wt-folders
  mkdir -p "$p-elsewhere/001-alpha" "$p-elsewhere/001-ini"
  FOLDER_REPO=$p
  FOLDER_WT=$p/.workflow/.worktrees/wt-folders
}

folder_inputs() {
  local folder name
  case "$1" in
    spec) folder=$FOLDER_SPEC ;;
    initiative) folder=$FOLDER_INITIATIVE ;;
    *) return 1 ;;
  esac
  name=${folder##*/}
  printf '%s|%s|%s\n' \
    relative "$FOLDER_REPO" "$folder" \
    dot-relative "$FOLDER_REPO" "./$folder/" \
    absolute-main "$FOLDER_REPO" "$FOLDER_REPO/$folder" \
    absolute-worktree "$FOLDER_REPO" "$FOLDER_WT/$folder" \
    from-worktree "$FOLDER_WT" "$folder" \
    bare "$FOLDER_REPO" "$name" \
    absolute-elsewhere "$FOLDER_REPO" "$FOLDER_REPO-elsewhere/$name" \
    outside-repo "$FOLDER_REPO-elsewhere" "$folder"
}

folder_outcome() {
  local err rc
  err=$("$@" 2>&1 >/dev/null)
  rc=$?
  printf '%s|%s\n' "$rc" "${err%%$'\n'*}"
}

folder_expected() {
  case "$1" in
    bare | absolute-elsewhere) printf '%s|%s: %s: %s\n' "$5" "$4" "$6" "$3" ;;
    outside-repo) printf '%s|%s: not inside a git repository: %s\n' "$5" "$4" "$2" ;;
    *) printf '%s\n' "$7" ;;
  esac
}
