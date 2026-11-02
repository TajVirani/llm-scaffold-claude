#!/usr/bin/env bash
# Suite: the Sign-off PR steps of feature-workflow (modules/sign-off.md 5.2 to 5.8) and the project-setup pr_template question.
# Covers: JRN-005: the 5.8 publish block (the fenced bash block right after the line `<!-- 5.8 publish commands -->`)
#   exists; its gh and glab lines, run from the spec branch of a fixture repo with stand-in gh and glab on PATH, pass the
#   approved pr-body.md with --body-file / --description-file, the main and spec branches, and no --template; its other
#   lines make a --no-ff merge on main whose subject is a Conventional Commits subject and whose body is pr-body.md; the
#   block is shellcheck-clean. JRN-006: sign-off 5.2 names the pr_template proposal row, spells out none of the host
#   template paths and points at project-setup's modules/files.md for them; 5.4 fills pr-body.md from pr-template.md, runs
#   check-pr-body.sh, and on its exit 2 for the host template stops and offers the workflow template or a fixed path
#   through 5.2; 5.5 shows the full text of pr-body.md for approval; 5.8 reruns the check and publishes with --body-file
#   and --description-file; project-setup asks the pr_template question, names the host template, and its
#   modules/files.md names all four host template paths; the rules.md template documents pr_template under Workflow
#   settings; SKILL.md lists pr-template.md among the assets.
#   JRN-006 (spec 007): the 5.8 SPEC_DIR setting names .workflow/specs/done/NNN-slug; with that value and the spec folder
#   only in done/ (the state right after the move), gh gets --body-file on the moved pr-body.md and the local merge's message
#   holds the moved body.
#   JRN-009 (spec 00014): the shipped pr-template.md Link to issue guidance gives the tracker form (the spec's tracker_issue
#   URL and `Closes #<n>`) and keeps the no-tracker stub; a workflow body in that form passes check-pr-body.sh; sign-off 5.4
#   says a body filled from a project template ends with the issue URL and `Closes #<n>` as its last lines, and a project
#   body ending that way passes check-pr-body.sh --project-template. The no-tracker stub body already passes the
#   check-pr-body suite, so it is not repeated here.
# Contract read from sign-off.md: the publish block uses the variables SPEC_DIR, SPEC_BRANCH, MAIN and SUBJECT, puts each
#   command on one line, and runs from the project root with the spec branch checked out.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/pr-template.sh
source "$TESTS_DIR/fixtures/pr-template.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
FW="$WORK/scaffold/.agents/skills/feature-workflow"
SIGN_OFF="$FW/modules/sign-off.md"
SETUP="$WORK/scaffold/.agents/skills/project-setup"
HOST_TEMPLATE_PATHS='.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE/*.md
.gitlab/merge_request_templates/*.md'

# publish_block FILE : print the fenced bash block that follows the 5.8 publish marker line (blank lines between are allowed).
publish_block() {
  awk '
    /^[[:space:]]*<!-- 5\.8 publish commands -->[[:space:]]*$/ { armed = 1; next }
    armed && !infence && /^[[:space:]]*$/ { next }
    armed && !infence && /^[[:space:]]*```bash[[:space:]]*$/ { infence = 1; next }
    armed && !infence { exit }
    infence && /^[[:space:]]*```[[:space:]]*$/ { exit }
    infence { print }
  ' "$1"
}

# step_section FILE HEADING : print the text of the `## <HEADING>` section (the heading alone or followed by more words),
#   up to the next `## ` heading.
step_section() {
  awk -v start="## $2" '
    $0 == start || index($0, start " ") == 1 { insec = 1; next }
    /^## / { insec = 0 }
    insec
  ' "$1"
}

# flag_value ARGS_FILE FLAG : print the value a recorded argument list gave FLAG, as `FLAG value` or `FLAG=value`.
flag_value() {
  [[ -f $1 ]] || return 0
  awk -v flag="$2" '
    take { print; exit }
    $0 == flag { take = 1; next }
    index($0, flag "=") == 1 { print substr($0, length(flag) + 2); exit }
  ' "$1"
}

# is_approved_body PATH : true when PATH, read from the fixture repo root, is the approved pr-body.md.
is_approved_body() {
  local path=$1
  case "$path" in
    /*) ;;
    *) path="$REPO/$path" ;;
  esac
  [[ $(basename "$path") == pr-body.md ]] && cmp -s "$path" "$APPROVED_BODY"
}

# host_template_exit_2_paragraphs : print each paragraph of sign-off 5.4 that handles an exit 2 on the host template:
#   it names an exit 2 and `pr_template` or the host template, says to stop, and offers the workflow template or a
#   fixed path through 5.2.
host_template_exit_2_paragraphs() {
  step_section "$SIGN_OFF" 5.4 | awk '
    BEGIN { RS = "" }
    /[Ee]xit 2/ && /pr_template|host template/ && /[Ss]top/ && /workflow template/ && /5\.2/ { print; print "" }
  '
}

# missing_host_template_paths FILE : print each host PR/MR template path that FILE does not name.
missing_host_template_paths() {
  local path
  while IFS= read -r path; do
    grep -Fq -- "$path" "$1" || echo "$path"
  done <<<"$HOST_TEMPLATE_PATHS"
}

# has_template_flag ARGS_FILE : true when the recorded arguments hold --template or -T in any form.
has_template_flag() { grep -Eq -- '^(--template|-T)(=.*)?$' "$1"; }

# run_publish_lines LINES : run LINES as one bash script from the fixture repo root, with the stand-ins first on PATH.
run_publish_lines() {
  (cd "$REPO" && env PATH="$STUBS:$PATH" GIT_EDITOR=true SPEC_DIR="$SPEC_DIR" SPEC_BRANCH="$SPEC_BRANCH" MAIN=main \
    SUBJECT="$SUBJECT" bash -c "$1") >"$WORK/publish.out" 2>&1
}

echo "== JRN-005: the PR and the local merge carry the approved body"
BLOCK=$(publish_block "$SIGN_OFF")
check "JRN-005 sign-off 5.8 holds the publish block after its marker" '[[ -n $BLOCK ]]' \
  "no fenced bash block right after <!-- 5.8 publish commands --> in modules/sign-off.md"
check "JRN-005 the publish block has a gh pr create line" 'grep -q "gh pr create" <<<"$BLOCK"'
check "JRN-005 the publish block has a glab mr create line" 'grep -q "glab mr create" <<<"$BLOCK"'
check "JRN-005 the publish block has a git merge --no-ff -F line" 'grep -Eq "git (-C [^ ]+ )?merge --no-ff -F" <<<"$BLOCK"'

# The spec branch is checked out because sign-off publishes from it. A local bare origin lets any push line in the block
# succeed without a network.
REPO="$WORK/repo"
make_fixture_repo "$REPO"
git init -q --bare "$WORK/origin.git"
git -C "$REPO" remote add origin "$WORK/origin.git"
SPEC_DIR=.workflow/specs/008-demo
SPEC_BRANCH=spec/008-demo
SUBJECT="feat(sign-off): publish the approved PR template"
git -C "$REPO" switch -q -c "$SPEC_BRANCH"
mkdir -p "$REPO/$SPEC_DIR"
APPROVED_BODY="$WORK/approved-pr-body.md"
printf '%s\n' "$PR_TEMPLATE_SECTIONS" | pr_body_from_headings >"$APPROVED_BODY"
cp "$APPROVED_BODY" "$REPO/$SPEC_DIR/pr-body.md"
git_commit_all "$REPO" "docs(workflow): approved PR body for 008-demo"

STUBS="$WORK/stubs"
mkdir -p "$STUBS"
for cli in gh glab; do
  cat >"$STUBS/$cli" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >"$WORK/$cli.args"
echo "https://example.invalid/$cli/1"
EOF
  chmod +x "$STUBS/$cli"
done

run_publish_lines "$(grep "gh pr create" <<<"$BLOCK")"
GH_ARGS="$WORK/gh.args"
check "JRN-005 gh got --body-file pointing at the approved pr-body.md" \
  '[[ -f $GH_ARGS ]] && is_approved_body "$(flag_value "$GH_ARGS" --body-file)"' "$(cat "$WORK/publish.out")"
check "JRN-005 gh got no --template" '[[ -f $GH_ARGS ]] && ! has_template_flag "$GH_ARGS"'
eq "JRN-005 gh got the main branch as --base" "$(flag_value "$GH_ARGS" --base)" main
eq "JRN-005 gh got the spec branch as --head" "$(flag_value "$GH_ARGS" --head)" "$SPEC_BRANCH"

run_publish_lines "$(grep "glab mr create" <<<"$BLOCK")"
GLAB_ARGS="$WORK/glab.args"
check "JRN-005 glab got --description-file pointing at the approved pr-body.md" \
  '[[ -f $GLAB_ARGS ]] && is_approved_body "$(flag_value "$GLAB_ARGS" --description-file)"' "$(cat "$WORK/publish.out")"
check "JRN-005 glab got no --template" '[[ -f $GLAB_ARGS ]] && ! has_template_flag "$GLAB_ARGS"'
eq "JRN-005 glab got the main branch as --target-branch" "$(flag_value "$GLAB_ARGS" --target-branch)" main
eq "JRN-005 glab got the spec branch as --source-branch" "$(flag_value "$GLAB_ARGS" --source-branch)" "$SPEC_BRANCH"

SPEC_TIP=$(git -C "$REPO" rev-parse "$SPEC_BRANCH")
run_publish_lines "$(grep -v -e "gh pr create" -e "glab mr create" <<<"$BLOCK")"
check "JRN-005 the local merge is a --no-ff merge of the spec branch into main" \
  '[[ $(git -C "$REPO" rev-parse -q --verify "main^2" 2>/dev/null) == "$SPEC_TIP" ]]' "$(cat "$WORK/publish.out")"
check "JRN-005 the merge commit subject is a Conventional Commits subject" \
  'git -C "$REPO" log -1 --format=%s main | grep -Eq "^[a-z]+(\([^)]+\))?!?: .+"' \
  "subject: $(git -C "$REPO" log -1 --format=%s main)"
eq "JRN-005 the merge commit body is the approved pr-body.md" \
  "$(git -C "$REPO" log -1 --format=%b main)" "$(cat "$APPROVED_BODY")"

if [[ -n $BLOCK ]]; then
  printf '#!/usr/bin/env bash\n%s\n' "$BLOCK" >"$WORK/publish-block.sh"
  shellcheck_files "JRN-005 shellcheck: the 5.8 publish block" "$WORK/publish-block.sh"
else
  ko "JRN-005 shellcheck: the 5.8 publish block" "no publish block to check"
fi

echo "== JRN-006: sign-off and setup text say the new steps"
check "JRN-006 sign-off 5.2 adds the pr_template proposal row" 'step_section "$SIGN_OFF" 5.2 | grep -q "pr_template"'
SIGN_OFF_5_2=$(step_section "$SIGN_OFF" 5.2)
check "JRN-006 sign-off 5.2 names none of the host template paths" \
  '! grep -Eq "pull_request_template\.md|PULL_REQUEST_TEMPLATE|merge_request_templates" <<<"$SIGN_OFF_5_2"' \
  "$(grep -E "pull_request_template\.md|PULL_REQUEST_TEMPLATE|merge_request_templates" <<<"$SIGN_OFF_5_2")"
check "JRN-006 sign-off 5.2 points at project-setup modules/files.md for the host template paths" \
  'grep -q "project-setup" <<<"$SIGN_OFF_5_2" && grep -q "modules/files\.md" <<<"$SIGN_OFF_5_2"'
check "JRN-006 sign-off 5.4 fills pr-body.md from pr-template.md" \
  'step_section "$SIGN_OFF" 5.4 | grep -q "pr-template.md" && step_section "$SIGN_OFF" 5.4 | grep -q "pr-body.md"'
check "JRN-006 sign-off 5.4 runs check-pr-body.sh" 'step_section "$SIGN_OFF" 5.4 | grep -q "check-pr-body.sh"'
check "JRN-006 sign-off 5.4 stops and asks when check-pr-body.sh exits 2 on the host template" \
  '[[ -n $(host_template_exit_2_paragraphs) ]]' \
  "no 5.4 paragraph names an exit 2 on the host template with a stop, the workflow template and a fixed path via 5.2"
check "JRN-006 sign-off 5.5 shows the full text of pr-body.md for approval" \
  'step_section "$SIGN_OFF" 5.5 | grep -q "pr-body.md" && step_section "$SIGN_OFF" 5.5 | grep -iq "full text"'
check "JRN-006 sign-off 5.8 reruns check-pr-body.sh" 'step_section "$SIGN_OFF" 5.8 | grep -q "check-pr-body.sh"'
check "JRN-006 sign-off 5.8 publishes with --body-file and --description-file" \
  'step_section "$SIGN_OFF" 5.8 | grep -q -- "--body-file" && step_section "$SIGN_OFF" 5.8 | grep -q -- "--description-file"'

SETUP_TEXT=$(cat "$SETUP/SKILL.md" "$SETUP"/modules/*.md)
check "JRN-006 project-setup asks the pr_template question" 'grep -q "pr_template" <<<"$SETUP_TEXT"'
check "JRN-006 project-setup names the host PR template it looks for" 'grep -q "pull_request_template" <<<"$SETUP_TEXT"'
check "JRN-006 project-setup modules/files.md names all four host template paths" \
  '[[ -z $(missing_host_template_paths "$SETUP/modules/files.md") ]]' \
  "missing: $(missing_host_template_paths "$SETUP/modules/files.md")"
check "JRN-006 the rules.md template documents pr_template under Workflow settings" \
  'step_section "$SETUP/assets/docs/rules.md" "Workflow settings" | grep -q "pr_template"'
check "JRN-006 SKILL.md lists pr-template.md among the assets" \
  'grep "assets/" "$FW/SKILL.md" | grep -q "pr-template.md"'

echo "== JRN-006 (spec 007): 5.8 publishes the body the move rewrote, from the Done folder"
# The fixture is the state right after sign-off moves the spec: the spec folder sits only in done/, and its pr-body.md differs from the
# approved text only in the spec path.
SPEC_DIR_LINE=$(step_section "$SIGN_OFF" 5.8 | grep -oE '^- `SPEC_DIR=[^`]+`' | head -1)
SPEC_DIR=${SPEC_DIR_LINE#- \`SPEC_DIR=}
SPEC_DIR=${SPEC_DIR%\`}
check "JRN-006 the 5.8 SPEC_DIR setting names the Done folder path" '[[ $SPEC_DIR == .workflow/specs/done/NNN-slug ]]' \
  "SPEC_DIR line: ${SPEC_DIR_LINE:-<none>}"
SPEC_DIR=${SPEC_DIR//NNN-slug/008-demo}
REPO="$WORK/repo-moved"
make_fixture_repo "$REPO"
git init -q --bare "$WORK/origin-moved.git"
git -C "$REPO" remote add origin "$WORK/origin-moved.git"
SPEC_BRANCH=spec/008-demo
git -C "$REPO" switch -q -c "$SPEC_BRANCH"
APPROVED_BODY="$WORK/approved-moved-pr-body.md"
{ printf '%s\n' "$PR_TEMPLATE_SECTIONS" | pr_body_from_headings; printf 'Report: .workflow/specs/008-demo/report.md\n'; } \
  >"$WORK/approved-before-move.md"
sed 's#\.workflow/specs/008-demo#.workflow/specs/done/008-demo#' "$WORK/approved-before-move.md" >"$APPROVED_BODY"
mkdir -p "$REPO/.workflow/specs/done/008-demo"
cp "$APPROVED_BODY" "$REPO/.workflow/specs/done/008-demo/pr-body.md"
git_commit_all "$REPO" "chore(workflow): move 008-demo to the Done folder"
rm -f "$WORK/gh.args"
run_publish_lines "$(grep "gh pr create" <<<"$BLOCK")"
check "JRN-006 gh got --body-file pointing at the moved pr-body.md" \
  '[[ -f $GH_ARGS ]] && is_approved_body "$(flag_value "$GH_ARGS" --body-file)"' \
  "SPEC_DIR=$SPEC_DIR; --body-file $(flag_value "$GH_ARGS" --body-file); $(cat "$WORK/publish.out")"
SPEC_TIP=$(git -C "$REPO" rev-parse "$SPEC_BRANCH")
run_publish_lines "$(grep -v -e "gh pr create" -e "glab mr create" <<<"$BLOCK")"
check "JRN-006 the local merge from the Done folder lands on main" \
  '[[ $(git -C "$REPO" rev-parse -q --verify "main^2" 2>/dev/null) == "$SPEC_TIP" ]]' "$(cat "$WORK/publish.out")"
eq "JRN-006 the merge message holds the moved pr-body.md" "$(git -C "$REPO" log -1 --format=%b main)" "$(cat "$APPROVED_BODY")"

echo "== JRN-009 (spec 00014): the Sign-off PR links and closes the spec's tracker issue"
CHECK_PR_BODY="$FW/scripts/check-pr-body.sh"
LINK_GUIDANCE=$(step_section "$FW/assets/pr-template.md" "Link to issue")
SIGN_OFF_5_4=$(step_section "$SIGN_OFF" 5.4)
# template_gives_tracker_form : the Link to issue guidance names the spec's tracker_issue and the Closes line.
template_gives_tracker_form() { grep -q "tracker_issue" <<<"$LINK_GUIDANCE" && grep -q "Closes #" <<<"$LINK_GUIDANCE"; }
# sign_off_appends_to_project_body : a 5.4 paragraph says a project-template body ends with the issue URL and Closes line.
sign_off_appends_to_project_body() {
  awk 'BEGIN { RS = "" } /Closes #/ && /[Ll]ast/ && /project template|host template|a path/ { found = 1 } END { exit !found }' \
    <<<"$SIGN_OFF_5_4"
}
check "JRN-009 (spec 00014) the pr-template.md Link to issue guidance gives the tracker_issue URL and Closes #<n>, and keeps the no-tracker stub" \
  'template_gives_tracker_form && grep -q "No tracker issue" <<<"$LINK_GUIDANCE"' "$LINK_GUIDANCE"
PR_TRACKER_ISSUE=https://gitlab.com/acme/widget/-/issues/42
printf '%s\n' "$PR_TEMPLATE_SECTIONS" | pr_body_from_headings >"$WORK/tracker-body.md"
check_out=$(bash "$CHECK_PR_BODY" "$WORK/tracker-body.md" 2>&1); check_rc=$?
check "JRN-009 (spec 00014) a workflow body in the template's tracker form passes check-pr-body.sh" \
  'template_gives_tracker_form && [[ $check_rc == 0 && -z $check_out ]]' "rc=$check_rc: $check_out"
check "JRN-009 (spec 00014) sign-off 5.4 ends a project-template body with the issue URL and Closes #<n>" \
  'sign_off_appends_to_project_body' "no 5.4 paragraph names Closes #, the last lines and a project template"
printf '%s\n' "$PR_PROJECT_TEMPLATE" >"$WORK/project-template.md"
pr_project_body >"$WORK/project-body.md"
check_out=$(bash "$CHECK_PR_BODY" "$WORK/project-body.md" --project-template "$WORK/project-template.md" 2>&1); check_rc=$?
check "JRN-009 (spec 00014) a project-template body ending with the issue URL and Closes #<n> passes check-pr-body.sh --project-template" \
  'sign_off_appends_to_project_body && [[ $check_rc == 0 && -z $check_out && $(tail -1 "$WORK/project-body.md") == "Closes #42" ]]' \
  "rc=$check_rc: $check_out"
unset PR_TRACKER_ISSUE

finish
