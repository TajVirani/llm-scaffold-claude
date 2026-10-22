#!/usr/bin/env bash
# Suite: initiative-transition.sh (feature-workflow/scripts), the single writer for initiatives; JRN-002 "Explore across sessions".
# Covers: the frontier before and after a research question settles; set-question launch, reset and settle (launched map, settled
#   line); a researching question surviving a session end and counted by the session-start offer; illegal question, slice and
#   status transitions exit 2 with a reason; step and set-pr writes; usage errors exit 1.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

new_workdir
P=$WORK/proj
large_path_repo "$P"
seed_initiative "$P" 001 storage-overhaul
INI=.workflow/initiatives/001-storage-overhaul
IT() { initiative_transition "$P" "$@"; }
question() { fm "$P/$INI/questions.md" ".questions[] | select(.id == \"$1\") | $2"; }

echo "== JRN-002 first round"
eq "JRN-002 frontier 1 is IQ1 and IQ3" "$(frontier "$P/$INI")" "IQ1 IQ3"
refused "JRN-002 a decision question cannot be researching" IT set-question "$INI" IQ3 --state researching --launched research
refused "JRN-002 a question cannot be settled without a settled line" IT set-question "$INI" IQ3 --state settled

echo "== JRN-002 launch research, end the session"
t "JRN-002 launching IQ1 is accepted" 0 IT set-question "$INI" IQ1 --state researching --launched research
eq "JRN-002 IQ1 is researching" "$(question IQ1 .state)" researching
eq "JRN-002 IQ1 launched names the research task type" "$(question IQ1 .launched.task_type)" research
check "JRN-002 IQ1 launched records when" '[[ "$(question IQ1 .launched.at)" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]' "$(question IQ1 .launched)"
ctx=$(resume_offer "$P")
line=$(offer_lines "$ctx" "$INI")
eq "JRN-002 the next session's offer lists the initiative once" "$(printf '%s' "$line" | grep -c .)" 1
check "JRN-002 the offer shows one pending research question" 'grep -qF "$(offer_research_text 1)" <<<"$line"' "$ctx"
refused "JRN-002 a researching question cannot be launched again" IT set-question "$INI" IQ1 --state researching --launched research

echo "== JRN-002 resume finds no result, relaunch"
t "JRN-002 a researching question returns to open with launched cleared" 0 IT set-question "$INI" IQ1 --state open --launched clear
eq "JRN-002 IQ1 is open again" "$(question IQ1 .state)" open
eq "JRN-002 IQ1 launched is cleared" "$(question IQ1 .launched)" null
IT set-question "$INI" IQ1 --state researching --launched research >/dev/null 2>&1

echo "== JRN-002 answer written back, second round"
SOURCE="https://example.org/storage-survey#formats"
t "JRN-002 settling IQ1 with its source is accepted" 0 IT set-question "$INI" IQ1 --state settled --settled "$SOURCE"
eq "JRN-002 IQ1 is settled" "$(question IQ1 .state)" settled
eq "JRN-002 IQ1 settled line is the source" "$(question IQ1 .settled)" "$SOURCE"
eq "JRN-002 frontier 2 is IQ2 and IQ3" "$(frontier "$P/$INI")" "IQ2 IQ3"
line=$(offer_lines "$(resume_offer "$P")" "$INI")
check "JRN-002 after the write-back no research is pending" '[ -n "$line" ] && ! grep -qF "$(offer_research_text 1)" <<<"$line"' "$line"
refused "JRN-002 a settled question cannot be launched" IT set-question "$INI" IQ1 --state researching --launched research

echo "== JRN-002 slice and status transitions"
refused "JRN-002 a slice cannot be emitted without its spec" IT set-slice "$INI" S1 --status emitted
refused "JRN-002 a slice cannot be emitted while its questions are open" IT set-slice "$INI" S2 --status emitted --spec 002-follow-up-reports
refused "JRN-002 a planned slice cannot carry a spec" IT set-slice "$INI" S1 --spec 002-core-flow
refused "JRN-002 a planned slice cannot jump to done" IT set-slice "$INI" S1 --status "done"
refused "JRN-002 planned is refused while questions are open" IT status "$INI" planned
refused "JRN-002 done is refused from exploring" IT status "$INI" "done"
eq "JRN-002 the initiative is still exploring" "$(fm "$P/$INI/initiative.md" .status)" exploring

echo "== JRN-002 step and set-pr"
t "JRN-002 step is accepted" 0 IT step "$INI" "$INITIATIVE_READONLY_STEP"
eq "JRN-002 step writes the initiative marker" "$(marker_step "$P/$INI/.step")" "$INITIATIVE_READONLY_STEP"
check "JRN-002 the marker records when" 'grep -qE "^updated_at: \"[0-9]{4}-[0-9]{2}-[0-9]{2}T" "$P/$INI/.step"' "$(cat "$P/$INI/.step" 2>/dev/null)"
t "JRN-002 set-pr with a URL is accepted" 0 IT set-pr "$INI" https://github.com/o/r/pull/7
eq "JRN-002 set-pr records merge_pr" "$(fm "$P/$INI/initiative.md" .merge_pr)" https://github.com/o/r/pull/7
t "JRN-002 set-pr null is accepted" 0 IT set-pr "$INI" null
eq "JRN-002 set-pr null clears merge_pr" "$(fm "$P/$INI/initiative.md" .merge_pr)" null

echo "== JRN-002 usage and environment errors"
t "JRN-002 an unknown subcommand is a usage error" 1 IT frobnicate "$INI"
t "JRN-002 a missing initiative folder is an environment error" 1 IT status .workflow/initiatives/404-none exploring
t "JRN-002 a folder outside .workflow/initiatives is a usage error" 1 IT status .workflow/specs/001-storage-overhaul exploring
t "JRN-002 an unknown question id is a usage error" 1 IT set-question "$INI" IQ9 --state open
t "JRN-002 set-pr with a value that is not a URL is a usage error" 1 IT set-pr "$INI" not-a-url

echo "== JRN-002 step markers and initiative dirs"
NEW_INI=.workflow/initiatives/002-new-subject
mkdir -p "$P/$NEW_INI"
t "JRN-002 step is accepted on a folder with no initiative.md yet" 0 IT step "$NEW_INI" "$LARGE_ENTRY_STEP"
eq "JRN-002 step before initiative.md writes the marker" "$(marker_step "$P/$NEW_INI/.step")" "$LARGE_ENTRY_STEP"
refused "JRN-002 step refuses an id that is not 6.x" IT step "$INI" 0.1.4
t "JRN-002 an absolute initiative dir is accepted" 0 IT step "$P/$INI" "$LARGE_TERM_GATE_STEP"
eq "JRN-002 an absolute dir writes the marker" "$(marker_step "$P/$INI/.step")" "$LARGE_TERM_GATE_STEP"
refused "JRN-002 status refuses a --step that is not 6.x" IT status "$INI" exploring --step 0.3.1

echo "== JRN-002 unknown ids and values"
t "JRN-002 an unknown slice id is a usage error" 1 IT set-slice "$INI" S9 --status emitted --spec 002-core-flow
t "JRN-002 a launch task type outside the allowed four is a usage error" 1 IT set-question "$INI" IQ3 --state researching --launched wizard
eq "JRN-002 a refused launch leaves the question open" "$(question IQ3 .state)" open

echo "== JRN-002 a write the validator refuses"
# A hand edit that breaks the template rules (S2 depends on a slice that does not exist) makes any later write fail validation.
yq --front-matter=process -i '.slices[1].depends_on = ["S7"]' "$P/$INI/initiative.md"
sum_before=$(cksum <"$P/$INI/initiative.md")
refused "JRN-002 a write the validator rejects is refused" IT set-pr "$INI" https://github.com/o/r/pull/8
eq "JRN-002 a refused write leaves initiative.md byte-identical" "$(cksum <"$P/$INI/initiative.md")" "$sum_before"
yq --front-matter=process -i '.slices[1].depends_on = ["S1"]' "$P/$INI/initiative.md"

echo "== JRN-002 emitted slices, planned and reopen"
IT set-question "$INI" IQ2 --state settled --settled "Adopt the surveyed format." >/dev/null 2>&1
IT set-question "$INI" IQ3 --state settled --settled "The platform team owns the core flow." >/dev/null 2>&1
t "JRN-002 S1 is emitted once its questions settle" 0 IT set-slice "$INI" S1 --status emitted --spec 002-core-flow
refused "JRN-002 an emitted slice keeps the spec it was emitted as" IT set-slice "$INI" S1 --spec 003-other
eq "JRN-002 S1 still names its first spec" "$(fm "$P/$INI/initiative.md" '.slices[] | select(.id == "S1") | .spec')" 002-core-flow
IT set-slice "$INI" S2 --status emitted --spec 003-follow-up-reports >/dev/null 2>&1
t "JRN-002 planned is accepted once every slice is emitted" 0 IT status "$INI" planned
eq "JRN-002 the initiative is planned" "$(fm "$P/$INI/initiative.md" .status)" planned
t "JRN-002 a planned initiative can be reopened" 0 IT status "$INI" exploring
eq "JRN-002 the reopened initiative is exploring" "$(fm "$P/$INI/initiative.md" .status)" exploring

echo "== JRN-002 replacing merge_pr"
IT set-pr "$INI" https://github.com/o/r/pull/7 >/dev/null 2>&1
err=$(IT set-pr "$INI" https://github.com/o/r/pull/9 2>&1 >/dev/null)
check "JRN-002 replacing merge_pr warns on stderr" 'grep -q "warning: .*pull/7 replaced by .*pull/9" <<<"$err"' "$err"
eq "JRN-002 the replacement is recorded" "$(fm "$P/$INI/initiative.md" .merge_pr)" https://github.com/o/r/pull/9

shellcheck_files "JRN-002 shellcheck initiative-transition.sh" "$P/$IT_REL"
finish
