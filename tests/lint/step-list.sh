#!/usr/bin/env bash
# Suite: lint of feature-workflow/references/steps.tsv (the ordered step list behind the progress line) against the repo.
# Covers: the file's shape (4 tab-separated columns, unique ids, known tracks, six phase rows, each id's phase matches its
#   prefix); the id set equals the numbered nodes of PLAN/decision-flow-reference.md and of PLAN/decision-flow.mermaid (removed
#   nodes such as ~~00.15~~ excluded); each "## Phase N" section of the reference lists exactly the ids the file puts in phase N;
#   per-phase step counts on the full and light paths are the agreed ones; every step id named by status-transition.sh, the
#   check-write.sh step lists and every `--step` / `step <spec-dir> <id>` call under .agents/ is in the file; and
#   step-progress.sh prints a line for every counted step on each of its paths. Read-only.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

TSV=$FW_SKILL/references/steps.tsv
REF=$REPO_ROOT/PLAN/decision-flow-reference.md
MMD=$REPO_ROOT/PLAN/decision-flow.mermaid
SP=$FW_SKILL/scripts/step-progress.sh
ID_RE='(00|[0-5])(\.[0-9]+)+'

check "steps.tsv exists" '[ -f "$TSV" ]'
rows() { grep -v '^#' "$TSV" | sed 1d; }

eq "header row" "$(grep -v '^#' "$TSV" | head -1)" "$(printf 'id\tphase\ttrack\ttitle')"
eq "every row has 4 tab-separated columns" "$(rows | awk -F'\t' 'NF != 4 { print NR ": " $0 }')" ""
eq "ids are unique" "$(rows | cut -f1 | sort | uniq -d)" ""
eq "tracks are known" "$(rows | awk -F'\t' '$3 !~ /^(both|full|light|phase|cross|intake|side)$/ { print $1 ": " $3 }')" ""
eq "six phase rows P0-P5" "$(rows | awk -F'\t' '$3 == "phase" { printf "%s=%s ", $1, $2 }')" "P0=0 P1=1 P2=2 P3=3 P4=4 P5=5 "
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
for n in 0 1 2 3 4 5; do
  awk -v n="$n" '/^## / { on = ($0 ~ ("^## Phase " n " ")) } on' "$REF" \
    | grep -v '^~~' | grep -oE "\*\*$ID_RE —" | grep -oE "$ID_RE" | sort -u >"$WORK/ref$n"
  rows | awk -F'\t' -v n="$n" '$2 == n && $3 != "phase" { print $1 }' | sort -u >"$WORK/tsv$n"
  eq "reference Phase $n ids == steps.tsv phase $n ids" "$(comm -3 "$WORK/ref$n" "$WORK/tsv$n" | tr -s '\t ' ' ')" ""
done

counts() { rows | awk -F'\t' -v p="$1" '($3 == "both" || $3 == p) { n[$2]++ } END { for (i = 0; i <= 5; i++) if (i in n) printf "%d:%d ", i, n[i] }'; }
eq "full path step counts per phase" "$(counts full)" "0:47 1:5 2:6 3:14 4:8 5:9 "
eq "light path step counts per phase" "$(counts light)" "0:35 3:15 4:8 5:9 "

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

# step-progress.sh prints a line for every counted step on each of its paths.
miss=""
while IFS=$'\t' read -r id _ track _; do
  for p in full light; do
    [ "$track" = both ] || [ "$track" = "$p" ] || continue
    out=$(bash "$SP" "$id" --path "$p" 2>&1) && [[ "$out" == Phase*"($id)" ]] || miss="$miss $id/$p"
  done
done < <(rows | awk -F'\t' '$3 == "both" || $3 == "full" || $3 == "light"')
eq "step-progress.sh prints every counted step" "$miss" ""

finish
