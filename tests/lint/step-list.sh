#!/usr/bin/env bash
# Suite: lint of feature-workflow/references/steps.tsv (the ordered step list behind the progress line) against the repo.
# Covers: the file's shape (4 tab-separated columns, unique ids, known tracks, seven phase rows, each id's phase matches its
#   prefix); the id set equals the numbered nodes of PLAN/decision-flow-reference.md and of PLAN/decision-flow.mermaid (removed
#   nodes such as ~~00.15~~ excluded); each "## Phase N" section of the reference lists exactly the ids the file puts in phase N;
#   step-progress.sh prints every counted step with the per-phase totals steps.tsv gives on the full and light paths, and the
#   large form with the large-track total; every file path named in the decision-flow records, assetlist.md and checklist.md
#   exists, except the allowed target-project and example paths and removals marked as such; every step id named by status-transition.sh, the
#   check-write.sh step lists and every `--step` / `step <spec-dir> <id>` call under .agents/ is in the file; and
#   step-progress.sh prints a line for every counted step on each of its paths. JRN-007: the large track (phase row P6, 6.x ids
#   on track large, the conversion node in phase 0 on both paths), its ids in the reference and the mermaid, the 6.x ids the
#   scripts and skills use, and the large form of the progress line for every large row. Read-only.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight
new_workdir

TSV=$FW_SKILL/references/steps.tsv
REF=$REPO_ROOT/PLAN/decision-flow-reference.md
MMD=$REPO_ROOT/PLAN/decision-flow.mermaid
SP=$FW_SKILL/scripts/step-progress.sh
ID_RE='(00|[0-6])(\.[0-9]+)+'

check "steps.tsv exists" '[ -f "$TSV" ]'
rows() { grep -v '^#' "$TSV" | sed 1d; }

eq "header row" "$(grep -v '^#' "$TSV" | head -1)" "$(printf 'id\tphase\ttrack\ttitle')"
eq "every row has 4 tab-separated columns" "$(rows | awk -F'\t' 'NF != 4 { print NR ": " $0 }')" ""
eq "ids are unique" "$(rows | cut -f1 | sort | uniq -d)" ""
eq "tracks are known" "$(rows | awk -F'\t' '$3 !~ /^(both|full|light|large|phase|cross|intake|side)$/ { print $1 ": " $3 }')" ""
eq "seven phase rows P0-P6" "$(rows | awk -F'\t' '$3 == "phase" { printf "%s=%s ", $1, $2 }')" "P0=0 P1=1 P2=2 P3=3 P4=4 P5=5 P6=6 "
bad_phase=$(rows | awk -F'\t' '
  $3 == "phase" { next }
  { split($1, p, ".") }
  $1 ~ /^00\./ || $1 ~ /^0\.0(\.|$)/ { if ($2 != "-") print $1; next }
  p[1] != $2 { print $1 }')
eq "each id's phase column matches its prefix (00.x and 0.0.x: -)" "$bad_phase" ""
eq "00.x rows are cross, 0.0.x rows are intake" "$(rows | awk -F'\t' '($1 ~ /^00\./ && $3 != "cross") || ($1 ~ /^0\.0(\.|$)/ && $3 != "intake") { print $1 }')" ""

rows | awk -F'\t' '$3 != "phase" { print $1 }' | sort -u >"$WORK/tsv"

# Reference: bold text starting with a node id ("**<id> — ", "**<id> Gate?**", "**<id>**"), skipping struck-out (removed) nodes.
grep -oE "(~~)?\*\*$ID_RE( |\*\*)" "$REF" | grep -v '^~~' | grep -oE "$ID_RE" | sort -u >"$WORK/ref"
eq "reference node ids == steps.tsv ids" "$(comm -3 "$WORK/ref" "$WORK/tsv" | tr -s '\t ' ' ')" ""

# Mermaid: node labels '"<id> - ', excluding subgraph titles (0.1-0.5 are substage groups).
grep -v '^\s*subgraph' "$MMD" | grep -oE "[\[{(/]\"$ID_RE - " | grep -oE "$ID_RE" | sort -u >"$WORK/mmd"
eq "mermaid node ids == steps.tsv ids" "$(comm -3 "$WORK/mmd" "$WORK/tsv" | tr -s '\t ' ' ')" ""

# Each "## Phase N" section of the reference names exactly the ids the file puts in phase N.
for n in 0 1 2 3 4 5 6; do
  awk -v n="$n" '/^## / { on = ($0 ~ ("^## Phase " n " ")) } on' "$REF" \
    | grep -v '^~~' | grep -oE "\*\*$ID_RE —" | grep -oE "$ID_RE" | sort -u >"$WORK/ref$n"
  rows | awk -F'\t' -v n="$n" '$2 == n && $3 != "phase" { print $1 }' | sort -u >"$WORK/tsv$n"
  eq "reference Phase $n ids == steps.tsv phase $n ids" "$(comm -3 "$WORK/ref$n" "$WORK/tsv$n" | tr -s '\t ' ' ')" ""
done

# counts PATH : "<phase>:<steps> " for each phase with a counted step on PATH, in phase order, from steps.tsv.
counts() { rows | awk -F'\t' -v p="$1" '($3 == "both" || $3 == p) { n[$2]++ } END { for (i = 0; i <= 6; i++) if (i in n) printf "%d:%d ", i, n[i] }'; }
check "full path counts steps in phases 0-5" '[[ "$(counts full)" =~ ^0:[0-9]+\ 1:[0-9]+\ 2:[0-9]+\ 3:[0-9]+\ 4:[0-9]+\ 5:[0-9]+\ $ ]]' "$(counts full)"
check "light path counts steps in phases 0, 3, 4 and 5" '[[ "$(counts light)" =~ ^0:[0-9]+\ 3:[0-9]+\ 4:[0-9]+\ 5:[0-9]+\ $ ]]' "$(counts light)"

# Every file path the design records name exists. The awk prints "<file>:<line>: <path>" for each path-like token, skipping
# placeholders (a token that runs into <, {, * or $, or names NNN), records (assetlist's Decisions and Open questions), a "### " section whose first bullet says Removed (D<n>),
# and lines that mark a removal. Paths under skills/, agents/, hooks/ and lib/ are relative to .agents/ (assetlist's form).
# Allowed below: target-project paths and examples, which do not exist in this repo; a folder allows what is under it.
NAMED_PATH_ALLOW='.agents/VERSION
.codex/config.toml
.codex/hooks.json
.workflow/GLOSSARY-MAP.md
.workflow/data-structure-audit-state.jsonl
.workflow/design-pattern-doc/
.workflow/tools/oxlint/
agents/openai.yaml
PLAN/archive/
scripts/generate-codex-agents'
# named_paths FILE... : print "<file>:<line>: <path>" for each repo path a design record names.
named_paths() {
  awk '
    FNR == 1 { skip = 0; sect = 0 }
    /^## / { skip = (FILENAME ~ /assetlist\.md$/ && ($0 ~ /^## Decisions/ || $0 ~ /^## Open questions/)); sect = 0; next }
    /^### / { sect = 0; head = 1; next }
    head && /^- \*\*Removed \(D[0-9]+\)\.\*\*/ { sect = 1 }
    head && /^- / { head = 0 }
    skip || sect { next }
    /[Rr]emoved (by D[0-9]+|\(D[0-9]+\))|content stays in git history/ { next }
    {
      line = " " $0
      while (match(line, /[^A-Za-z0-9_.\/-](\.agents|\.workflow|\.claude|\.codex|tests|scripts|PLAN|skills|agents|hooks|lib)\/[A-Za-z0-9._\/-]*|[^A-Za-z0-9_.\/-]install\.sh/)) {
        tok = substr(line, RSTART + 1, RLENGTH - 1)
        rest = substr(line, RSTART + RLENGTH, 1)
        line = substr(line, RSTART + RLENGTH)
        sub(/\.+$/, "", tok)
        if (rest ~ /[<{*$]/ || tok ~ /NNN/) continue
        # A bare skills/ or hooks/ word with no extension or trailing slash is prose ("skills/agents/hooks"), not a path.
        if (tok ~ /^(skills|agents|hooks|lib)\// && tok !~ /(\.[A-Za-z0-9]+|\/)$/) continue
        print FILENAME ":" FNR ": " tok
      }
    }' "$@"
}
missing_paths=""
while IFS= read -r hit; do
  path=${hit##*: }
  [ -e "$REPO_ROOT/$path" ] && continue
  case $path in skills/* | agents/* | hooks/* | lib/*) [ -e "$AGENTS_SRC/$path" ] && continue ;; esac
  allowed=0
  while IFS= read -r ok_path; do
    # An allowed folder (trailing slash) also allows the paths under it.
    case $path in "$ok_path" | "${ok_path%/}" | "${ok_path%/}"/*) [[ $ok_path == */ || $path == "$ok_path" ]] && allowed=1 ;; esac
  done <<<"$NAMED_PATH_ALLOW"
  [ "$allowed" = 1 ] && continue
  missing_paths="$missing_paths${hit#"$REPO_ROOT"/}"$'\n'
done < <(named_paths "$MMD" "$REF" "$REPO_ROOT/assetlist.md" "$REPO_ROOT/checklist.md")
eq "every file path the decision flow, assetlist.md and checklist.md name exists" "$missing_paths" ""

# Step ids the scripts and skills use must be in the file.
ST=$FW_SKILL/scripts/status-transition.sh
CW=$FW_SKILL/scripts/check-write.sh
{
  grep -E 'need_step "|Step-only mode' "$ST" | grep -oE "$ID_RE"
  grep -E '^[A-Z_]*STEPS?="' "$CW" | grep -oE "$ID_RE"
  grep -rhoE -- "--step +$ID_RE" "$AGENTS_SRC" | grep -oE "$ID_RE\$"
  grep -rhoE "step +[^ ]*specs/[^ ]+ +$ID_RE" "$AGENTS_SRC" | grep -oE "$ID_RE\$"
} | sort -u >"$WORK/used"
check "found step ids in the scripts and skills" '[ "$(wc -l <"$WORK/used")" -gt 20 ]'
eq "every step id used by status-transition.sh, check-write.sh and the skills is in steps.tsv" "$(comm -23 "$WORK/used" "$WORK/tsv" | tr '\n' ' ')" ""

# step-progress.sh prints a line for every counted step on each of its paths, with the phase and step totals steps.tsv gives.
COUNTS_full=$(counts full) COUNTS_light=$(counts light)
miss=""
while IFS=$'\t' read -r id phase track _; do
  for p in full light; do
    [ "$track" = both ] || [ "$track" = "$p" ] || continue
    if [ "$p" = full ]; then path_counts=$COUNTS_full; else path_counts=$COUNTS_light; fi
    phases=$(wc -w <<<"$path_counts" | tr -d ' ')
    steps=$(tr ' ' '\n' <<<"$path_counts" | sed -n "s/^$phase://p")
    out=$(bash "$SP" "$id" --path "$p" 2>&1) && [[ "$out" == "Phase "*" of $phases · step "*" of $steps — "*"($id)" ]] || miss="$miss $id/$p"
  done
done < <(rows | awk -F'\t' '$3 == "both" || $3 == "full" || $3 == "light"')
eq "step-progress.sh prints every counted step with the totals steps.tsv gives" "$miss" ""

# The large track. Its ids are 6.x, so they sit outside ID_RE and are checked here on their own.
LARGE_RE='6(\.[0-9]+)+'
eq "JRN-007 phase row P6 is phase 6" "$(rows | awk -F'\t' '$1 == "P6" { print $2 "/" $3 }')" "6/phase"
rows | awk -F'\t' '$3 == "large" { print $1 }' | sort -u >"$WORK/large"
check "JRN-007 steps.tsv has large-track rows" '[ -s "$WORK/large" ]'
eq "JRN-007 every large row is a 6.x id in phase 6" "$(rows | awk -F'\t' '$3 == "large" && ($2 != "6" || $1 !~ /^6(\.[0-9]+)+$/) { print $1 }')" ""
eq "JRN-007 every 6.x row is on the large track" "$(rows | awk -F'\t' '$1 ~ /^6\./ && $3 != "large" { print $1 }')" ""
eq "JRN-007 the conversion node is a phase 0 step on both paths" \
  "$(rows | awk -F'\t' -v id="$CONVERSION_STEP" '($1 "") == (id "") { print $2 "/" $3 }')" "0/both"
check "JRN-007 the reference names the conversion node" 'grep -qE "\*\*${CONVERSION_STEP//./\\.}( |\*\*)" "$REF"'

grep -oE "(~~)?\*\*$LARGE_RE( |\*\*)" "$REF" | grep -v '^~~' | grep -oE "$LARGE_RE" | sort -u >"$WORK/ref-large"
eq "JRN-007 reference 6.x node ids == steps.tsv large ids" "$(comm -3 "$WORK/ref-large" "$WORK/large" | tr -s '\t ' ' ')" ""
grep -v '^\s*subgraph' "$MMD" | grep -oE "[\[{(/]\"$LARGE_RE - " | grep -oE "$LARGE_RE" | sort -u >"$WORK/mmd-large"
eq "JRN-007 mermaid 6.x node ids == steps.tsv large ids" "$(comm -3 "$WORK/mmd-large" "$WORK/large" | tr -s '\t ' ' ')" ""
check "JRN-007 the reference has a Phase 6 section" 'grep -q "^## Phase 6 " "$REF"'
awk '/^## / { on = ($0 ~ /^## Phase 6 /) } on' "$REF" | grep -v '^~~' | grep -oE "\*\*$LARGE_RE —" | grep -oE "$LARGE_RE" | sort -u >"$WORK/ref6"
eq "JRN-007 reference Phase 6 ids == steps.tsv large ids" "$(comm -3 "$WORK/ref6" "$WORK/large" | tr -s '\t ' ' ')" ""

IT_SCRIPT=$FW_SKILL/scripts/initiative-transition.sh
{
  grep -E '^[A-Z_]*STEPS?="' "$CW" | grep -oE "\b$LARGE_RE"
  [ ! -f "$IT_SCRIPT" ] || grep -oE "\b$LARGE_RE" "$IT_SCRIPT"
  grep -rhoE -- "--step +$LARGE_RE" "$AGENTS_SRC" | grep -oE "$LARGE_RE\$"
  grep -rhoE "step +[^ ]*initiatives/[^ ]+ +$LARGE_RE" "$AGENTS_SRC" | grep -oE "$LARGE_RE\$"
} | sort -u >"$WORK/used-large"
check "JRN-007 check-write.sh step lists name 6.x steps" 'grep -E "^[A-Z_]*STEPS?=\"" "$CW" | grep -qE "\b$LARGE_RE"'
eq "JRN-007 every 6.x id used by the scripts and skills is in steps.tsv" "$(comm -23 "$WORK/used-large" "$WORK/large" | tr '\n' ' ')" ""

large_miss=""
large_pos=0
large_count=$(grep -c . "$WORK/large")
while IFS=$'\t' read -r id _ _ title; do
  large_pos=$((large_pos + 1))
  [ "$(bash "$SP" "$id" 2>&1)" = "Large path · step $large_pos of $large_count — $title ($id)" ] || large_miss="$large_miss $id"
done < <(rows | awk -F'\t' '$3 == "large"')
eq "JRN-007 step-progress.sh prints the large form for every large row" "$large_miss" ""

finish
