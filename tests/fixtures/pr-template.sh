#!/usr/bin/env bash
# File: Fixture builders and oracles for the PR template suites (check-pr-body, sign-off-pr).
#   Sourced after lib/common.sh; defines variables and functions only. bash 3.2 compatible.
# Provides:
#   PR_TEMPLATE_SECTIONS        the ten PR template headings in their agreed order, one per line (the oracle for the asset)
#   pr_section_fill HEADING     prints a filled section body for one PR template heading, the way sign-off fills it from
#                               the spec's evidence; the Risk and reversibility body reads `Risk: Medium - <reason>` and
#                               `Reversibility: Easy - <reason>`; Link to issue holds a no-tracker stub, or, when
#                               PR_TRACKER_ISSUE names an issue URL, the tracker lines; an unknown heading prints nothing
#   pr_tracker_lines URL        prints the two lines that link a Sign-off PR to its tracker issue: the URL, then
#                               `Closes #<n>` with the number the URL ends in
#   PR_PROJECT_TEMPLATE         a project's own PR template: two `##` headings, each holding only a guidance comment
#   pr_project_body             prints a body filled from PR_PROJECT_TEMPLATE, ending with the tracker lines when
#                               PR_TRACKER_ISSUE names an issue URL
#   pr_body_from_headings       reads headings on stdin, one per line, and prints a body with those sections in that order;
#                               the section named by $PR_EMPTY_SECTION keeps its heading but gets no text
# shellcheck disable=SC2034  # the variables are read by the suites that source this file

PR_TEMPLATE_SECTIONS='Link to issue
What changed
Why the change
Why this approach
Special things to note
How to test
Blast radius
Risk and reversibility
Areas, concepts and seams changed
How to undo this PR'

pr_section_fill() {
  case "$1" in
    "Link to issue")
      if [[ -n ${PR_TRACKER_ISSUE:-} ]]; then
        pr_tracker_lines "$PR_TRACKER_ISSUE"
      else
        echo "No tracker issue: the workflow does not create one when a spec starts yet."
      fi
      ;;
    "What changed")
      echo "- Sign-off fills the PR template at 5.4 and publishes it at 5.8."
      echo "- A read-only check validates the filled description."
      ;;
    "Why the change") echo "- Reviewers had to open the spec folder to judge a Sign-off PR." ;;
    "Why this approach") echo "A fixed template filled from evidence the spec folder already holds needs no new dependency." ;;
    "Special things to note") echo "None." ;;
    "How to test")
      echo "1. Run tests/run-all.sh --suite scripts/check-pr-body."
      echo "2. Confirm every case passes."
      ;;
    "Blast radius") echo "Sign-off steps 5.4 to 5.8 only; task PRs are unchanged." ;;
    "Risk and reversibility")
      echo "Risk: Medium - sign-off now stops on a description that fails the check."
      echo "Reversibility: Easy - revert the merge commit; no stored data changes."
      ;;
    "Areas, concepts and seams changed") echo "The sign-off module, the PR template asset and the new check script." ;;
    "How to undo this PR") echo "Revert the merge commit on the main branch." ;;
  esac
}

pr_body_from_headings() {
  local heading
  while IFS= read -r heading; do
    [[ -n $heading ]] || continue
    printf '## %s\n\n' "$heading"
    if [[ $heading != "${PR_EMPTY_SECTION:-}" ]]; then
      pr_section_fill "$heading"
      printf '\n'
    fi
  done
}

pr_tracker_lines() {
  printf '%s\nCloses #%s\n' "$1" "${1##*/}"
}

PR_PROJECT_TEMPLATE='## Summary

<!-- What this change does. -->

## Testing

<!-- How it was tested. -->'

pr_project_body() {
  printf '## Summary\n\nSign-off links the PR to its tracker issue.\n\n## Testing\n\nRan tests/run-all.sh.\n'
  if [[ -n ${PR_TRACKER_ISSUE:-} ]]; then
    printf '\n'
    pr_tracker_lines "$PR_TRACKER_ISSUE"
  fi
}
