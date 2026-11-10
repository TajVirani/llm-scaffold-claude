#!/usr/bin/env bash
# Suite: check-comments.sh (feature-workflow/scripts), the comment lint.
# Covers: a body comment naming a decision id (D, G or ADR- and digits), a journey id, a task id (T, digits, colon) or a
#   workflow path fails with one line per comment naming the file, line and kind; full-line and trailing comments; a # inside
#   quotes, inside a string that spans lines, $#, ${#x}, heredoc bodies and here-strings are not comments; the top header block may name workflow paths, a # Suite: header
#   may also name journey ids, and neither may name a decision or task id; the header ends at the first line that is not a
#   comment; only shell files are read (a .sh or .bash name, or a shell shebang); several files in argument order; no files
#   is clean; exit 2 on a missing file or an unknown option.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
LINT="$WORK/scaffold/.agents/skills/feature-workflow/scripts/check-comments.sh"
F="$WORK/files"
mkdir -p "$F"

# run_lint ARGS... : run the lint from inside the fixture folder, capturing stdout in OUT, stderr in ERR and the exit code in RC.
run_lint() {
  OUT=$(cd "$F" && "$LINT" "$@" 2>"$WORK/stderr")
  RC=$?
  ERR=$(cat "$WORK/stderr")
}

# --- a clean file: a File header naming workflow paths, body comments that give reasons
cat >"$F/clean.sh" <<'SH'
#!/usr/bin/env bash
# File: Helper script: reads .workflow/rules.md and .workflow/profiles/<work-type>.md.
# Exit: 0 ok.
set -euo pipefail

# Count the arguments first, because an empty call is a usage error.
count=$#
arr=(a b)
echo "${#arr[@]} $count"
echo "a # D12 inside double quotes" 'and # JRN-001 inside single ones'
printf '%s\n' "it's # T3: still a string"
grep -c '^#' /dev/null || true # a reason, with no id in it
MD5=1; ID12=2; D12x=3 # names that only contain the letters are fine
cat <<'EOF'
# D12 in a heredoc body is data, not a comment
# .workflow/specs/ too
EOF
	cat <<-EOT
	# JRN-001 in an indented heredoc body
	EOT
tr a b <<<"# D12 in a here-string"
echo "a string over two lines,
# D12 on its second line, is still a string"
# A comment after the string closes gives its reason.
SH
run_lint clean.sh
eq "a clean file exits 0" "$RC" 0
eq "a clean file prints nothing" "$OUT" ""

# --- each breach in a body comment
cat >"$F/bad.sh" <<'SH'
#!/usr/bin/env bash
# File: Helper script: a fixture with one breach per line below.
set -euo pipefail

# Keep the cache, as D12 decided.
# The layout follows ADR-0007.
# Gap G8 asked for this.
# JRN-003 drives this branch.
# T3: added the guard.
# Read .workflow/specs/<NNN>-slug/tasks.md for the list.
x=1  # see D12
echo "$x" # the path is .workflow/specs/
# Both D4 and .workflow/rules.md in one comment.
cat <<EOF
# D12 inside a heredoc is skipped
EOF
# After the heredoc, comments are checked again: D9.
(( n = 1 << k ))
# An arithmetic shift opens no heredoc: D10.
SH
run_lint bad.sh
eq "a file with breaches exits 1" "$RC" 1
eq "a decision id" "$(sed -n 1p <<<"$OUT")" "bad.sh:5: decision id: # Keep the cache, as D12 decided."
eq "an ADR id is a decision id" "$(sed -n 2p <<<"$OUT")" "bad.sh:6: decision id: # The layout follows ADR-0007."
eq "a gap id is a decision id" "$(sed -n 3p <<<"$OUT")" "bad.sh:7: decision id: # Gap G8 asked for this."
eq "a journey id" "$(sed -n 4p <<<"$OUT")" "bad.sh:8: journey id: # JRN-003 drives this branch."
eq "a task id" "$(sed -n 5p <<<"$OUT")" "bad.sh:9: task id: # T3: added the guard."
eq "a workflow path" "$(sed -n 6p <<<"$OUT")" "bad.sh:10: workflow path: # Read .workflow/specs/<NNN>-slug/tasks.md for the list."
eq "a trailing comment with a decision id" "$(sed -n 7p <<<"$OUT")" "bad.sh:11: decision id: # see D12"
eq "a trailing comment with a workflow path" "$(sed -n 8p <<<"$OUT")" "bad.sh:12: workflow path: # the path is .workflow/specs/"
eq "two kinds in one comment give one line naming both" "$(sed -n 9p <<<"$OUT")" \
  "bad.sh:13: decision id, workflow path: # Both D4 and .workflow/rules.md in one comment."
eq "a comment after a heredoc is checked" "$(sed -n 10p <<<"$OUT")" "bad.sh:17: decision id: # After the heredoc, comments are checked again: D9."
eq "an arithmetic shift opens no heredoc" "$(sed -n 11p <<<"$OUT")" "bad.sh:19: decision id: # An arithmetic shift opens no heredoc: D10."
eq "one line per breaching comment, nothing from the heredoc" "$(wc -l <<<"$OUT" | tr -d ' ')" 11
check "stderr gives the count and the fix" '[[ $ERR == *"11 comments"* && $ERR == *"reason"* ]]' "$ERR"

# --- header blocks
cat >"$F/suite.sh" <<'SH'
#!/usr/bin/env bash
# Suite: a fixture suite.
# Covers: JRN-001: the build in .workflow/specs/ passes; JRN-002 too.
# shellcheck disable=SC2016  # check expressions are single-quoted on purpose
source /dev/null
# JRN-001 again, but in the body.
SH
run_lint suite.sh
eq "journey ids in a Suite header pass, and the body one fails" "$OUT" "suite.sh:6: journey id: # JRN-001 again, but in the body."

cat >"$F/suite-decision.sh" <<'SH'
#!/usr/bin/env bash
# Suite: a fixture suite.
# Covers: what D85 item 6 says.
source /dev/null
SH
run_lint suite-decision.sh
eq "a decision id in a Suite header fails" "$OUT" "suite-decision.sh:3: decision id: # Covers: what D85 item 6 says."

cat >"$F/file-journey.sh" <<'SH'
#!/usr/bin/env bash
# File: Helper script for JRN-004, reading .workflow/rules.md.
# Called by: T2: the merge step.
set -euo pipefail
SH
run_lint file-journey.sh
eq "a File header may name a workflow path but not a journey or task id" "$OUT" \
  "file-journey.sh:2: journey id: # File: Helper script for JRN-004, reading .workflow/rules.md.
file-journey.sh:3: task id: # Called by: T2: the merge step."

cat >"$F/blank-ends-header.sh" <<'SH'
#!/usr/bin/env bash
# File: Helper script: reads .workflow/rules.md.

# Body: .workflow/rules.md is read here too.
SH
run_lint blank-ends-header.sh
eq "a blank line ends the header" "$OUT" "blank-ends-header.sh:4: workflow path: # Body: .workflow/rules.md is read here too."

cat >"$F/no-shebang.sh" <<'SH'
# helper.sh: sourced, reads .workflow/state.json.
helper() { :; }
SH
run_lint no-shebang.sh
eq "a top comment block without a shebang is the header" "$RC" 0

# --- which files are read
printf '# D12 in a markdown heading\n' >"$F/notes.md"
printf '#!/bin/bash\n# File: a script without an extension.\ntrue\n# D12 in the body.\n' >"$F/tool"
printf '#!/usr/bin/env python3\n# D12 in python\n' >"$F/script.py"
printf '#!/usr/bin/env bash\n# File: x.\ntrue\n# ADR-1 here.\n' >"$F/lib.bash"
run_lint notes.md tool script.py lib.bash
eq "only shell files are read: by shebang or by a .bash name" "$OUT" "tool:4: decision id: # D12 in the body.
lib.bash:4: decision id: # ADR-1 here."

run_lint bad.sh clean.sh suite.sh
check "several files report in argument order" '[[ $RC == 1 && $(sed -n 1p <<<"$OUT") == bad.sh:5:* && $(tail -n 1 <<<"$OUT") == suite.sh:6:* ]]' "$OUT"

run_lint -- clean.sh
eq "-- ends the options" "$RC" 0
run_lint
eq "no files is clean" "$RC" 0
eq "no files prints nothing" "$OUT" ""

# --- exit 2
run_lint missing.sh
eq "a missing file exits 2" "$RC" 2
check "the missing file is named on stderr" '[[ $ERR == *"missing.sh"* ]]' "$ERR"
run_lint --strict clean.sh
eq "an unknown option exits 2" "$RC" 2

shellcheck_files "check-comments.sh is shellcheck clean" "$AGENTS_SRC/skills/feature-workflow/scripts/check-comments.sh" "${BASH_SOURCE[0]}"

finish
