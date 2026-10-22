#!/usr/bin/env bash
# File: Fixture builders and oracles for the large-path suites (initiatives, slices, initiative questions). Sourced after
#   lib/common.sh; defines variables and functions only. bash 3.2 compatible.
# Provides:
#   Node ids               CONVERSION_STEP, LARGE_ENTRY_STEP, INITIATIVE_WRITER_STEP, INITIATIVE_READONLY_STEP, LARGE_TERM_GATE_STEP
#   large_path_repo DIR    git repo on main: committed copy of .agents/, minimal workflow folder, origin remote (bare repo DIR.origin.git)
#   set_task_review DIR V  the task_review setting in the fixture rules.md
#   seed_draft_spec DIR NNN SLUG       uncommitted draft spec at the conversion node, plus a shelf item and a work item pointing at it
#   seed_initiative DIR NNN SLUG       initiative committed on initiative/NNN-SLUG with S1, S2 and IQ1-IQ3; checkout left on that branch
#   initiative_transition DIR ARGS...  run initiative-transition.sh from the project root DIR
#   spec_transition DIR ARGS...        run status-transition.sh from the project root DIR
#   fm FILE EXPR           one frontmatter value (yq --front-matter=extract)
#   marker_step FILE       the step named by a .step marker
#   frontier DIR           ids of the questions on the frontier of the initiative folder DIR
#   next_spec_number DIR   the number discovery 0.1.1 gives the next spec
#   resume_offer DIR       the session-start hook's additionalContext for a session opened in DIR
#   offer_lines CTX REL    lines of the offer that list the folder REL
#   offer_research_text N  how the offer states the pending research count
#   stub_pr_clis DIR LOG   gh and glab stubs in DIR/bin that log their arguments to LOG; no network
#   refused NAME CMD...    assertion: CMD exits 2 with a reason on stderr
# shellcheck disable=SC2034,SC2016  # the node ids are read by the suites that source this file; yq programs are single-quoted on purpose

# Node ids from the large-path step list. Each is defined once here so the suites follow a renumbering from one place.
CONVERSION_STEP="0.3.23"           # the phase 0 node the questioning loop converts a spec at
LARGE_ENTRY_STEP="6.1"             # the step a new initiative starts at
INITIATIVE_WRITER_STEP="6.1"       # initiative.md is written at conversion, so the entry step is a writer step
INITIATIVE_READONLY_STEP="6.2"     # a 6.x step that neither writes initiative.md nor is a term gate
LARGE_TERM_GATE_STEP="6.6"         # the 6.x term-gate step, where glossary writes are allowed

IT_REL=.agents/skills/feature-workflow/scripts/initiative-transition.sh
ST_REL=.agents/skills/feature-workflow/scripts/status-transition.sh
FW_ASSETS_REL=.agents/skills/feature-workflow/assets

large_path_repo() {
  local p=$1
  git_init_repo "$p"
  copy_agents "$p"
  mkdir -p "$p/.workflow/specs" "$p/.workflow/model-map" "$p/.workflow/deferred"
  cp "$p/.agents/skills/project-setup/assets/docs/rules.md" "$p/.workflow/rules.md"
  printf '# Glossary\n' >"$p/.workflow/GLOSSARY.md"
  local type
  for type in research fact-lookup; do
    printf -- '---\ntier: cheap\nclaude: haiku\ncodex: gpt-mini\n---\n# %s\n' "$type" >"$p/.workflow/model-map/$type.md"
  done
  printf '%s\n' '.workflow/specs/*/.step' '.workflow/initiatives/*/.step' >"$p/.gitignore"
  git_commit_all "$p" "fixture: project"
  git init -q --bare "$p.origin.git"
  git -C "$p" remote add origin "$p.origin.git"
  git -C "$p" push -q origin main 2>/dev/null
}

set_task_review() {
  sed -i.bak "s/^task_review: [a-z-]*/task_review: $2/" "$1/.workflow/rules.md" && rm -f "$1/.workflow/rules.md.bak"
}

initiative_transition() {
  local p=$1
  shift
  (cd "$p" && "$p/$IT_REL" "$@")
}

spec_transition() {
  local p=$1
  shift
  (cd "$p" && bash "$p/$ST_REL" "$@")
}

fm() { yq --front-matter=extract "$2" "$1" 2>/dev/null; }

marker_step() { [ -f "$1" ] && yq '.step // ""' "$1" 2>/dev/null; }

seed_draft_spec() {
  local p=$1 name=$2-$3
  local dir=.workflow/specs/$name
  mkdir -p "$p/$dir" "$p/.workflow/specs/work-backlog"
  spec_transition "$p" step "$dir" 0.1.4 >/dev/null 2>&1
  cp "$p/$FW_ASSETS_REL/spec.md" "$p/$dir/spec.md"
  spec_transition "$p" status "$dir" draft --step 0.1.4 >/dev/null 2>&1
  spec_transition "$p" step "$dir" "$CONVERSION_STEP" >/dev/null 2>&1
  cat >"$p/$dir/design-log.md" <<EOF
# Design log: $3

Spec: [spec.md](spec.md)

## 2026-10-21 Deeper prompt

**Ask:** Plan a subject that turned out to be several features.

**Goals:**
- Each feature becomes its own spec.
EOF
  printf '# Codebase map: %s\n\nModules touched: several.\n' "$3" >"$p/$dir/codebase-map.md"
  printf -- '---\norigin_spec: %s\ncreated: 2026-10-21\n---\n# Shelved idea\n' "$dir" >"$p/.workflow/deferred/shelved-idea.md"
  printf -- '---\norigin_spec: .workflow/specs/000-earlier\norigin_step: "3.4"\ndiscovered_at: 2026-10-20\nstatus: promoted\npromoted_to: %s\nkind: requirement\n---\n# Seeded the draft\n' \
    "$dir" >"$p/.workflow/specs/work-backlog/000-earlier-disc-001.md"
}

seed_initiative() {
  local p=$1 name=$2-$3
  local dir=.workflow/initiatives/$name
  git -C "$p" switch -q -c "initiative/$name" main
  mkdir -p "$p/$dir"
  cp "$p/$FW_ASSETS_REL/initiative.md" "$p/$FW_ASSETS_REL/questions.md" "$p/$dir/"
  SEED_ORIGIN=001-$3 SEED_BRANCH=initiative/$name yq --front-matter=process -i '
    .status = "exploring" | .origin = strenv(SEED_ORIGIN) | .created = "2026-10-21" | .branch = strenv(SEED_BRANCH) | .merge_pr = null |
    .slices = [
      {"id": "S1", "title": "Core flow", "status": "planned", "questions": ["IQ1", "IQ3"], "depends_on": [], "spec": null},
      {"id": "S2", "title": "Follow-up reports", "status": "planned", "questions": ["IQ2"], "depends_on": ["S1"], "spec": null}
    ]' "$p/$dir/initiative.md"
  yq --front-matter=process -i '
    .questions = [
      {"id": "IQ1", "kind": "research", "state": "open", "question": "Which storage formats do peers use?", "depends_on": [], "launched": null, "settled": null},
      {"id": "IQ2", "kind": "decision", "state": "open", "question": "Which format do we adopt?", "depends_on": ["IQ1"], "launched": null, "settled": null},
      {"id": "IQ3", "kind": "decision", "state": "open", "question": "Who owns the core flow?", "depends_on": [], "launched": null, "settled": null}
    ]' "$p/$dir/questions.md"
  # The marker is gitignored state that the real script writes; a seeded initiative needs one without depending on that script.
  printf 'step: "%s"\nupdated_at: "2026-10-21T10:00:00Z"\n' "$LARGE_ENTRY_STEP" >"$p/$dir/.step"
  git -C "$p" add "$dir" && git -C "$p" commit -q -m "initiative $name: seeded"
}

frontier() {
  yq --front-matter=extract '
    ([.questions[] | select(.state == "settled") | .id]) as $settled
    | .questions[] | select(.state != "settled") | select(((.depends_on // []) - $settled | length) == 0) | .id' \
    "$1/questions.md" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'
}

# A converted spec leaves no folder and no branch behind; its number survives only as an initiative's origin, so origins count
# beside spec folders, spec branches and emitted slices.
next_spec_number() {
  local p=$1 d ref name highest
  highest=$(
    {
      for d in "$p"/.workflow/specs/[0-9][0-9][0-9]-*/; do [ -d "$d" ] && basename "$d"; done
      git -C "$p" for-each-ref --format='%(refname:lstrip=3)' refs/heads/spec
      git -C "$p" for-each-ref --format='%(refname:lstrip=4)' refs/remotes/origin/spec
      for d in "$p"/.workflow/initiatives/*/initiative.md; do
        [ -f "$d" ] && fm "$d" '.origin, (.slices // [] | .[].spec)'
      done
      for ref in $(git -C "$p" for-each-ref --format='%(refname)' refs/heads/initiative); do
        name=${ref#refs/heads/initiative/}
        git -C "$p" show "$ref:.workflow/initiatives/$name/initiative.md" 2>/dev/null \
          | yq --front-matter=extract '.origin, (.slices // [] | .[].spec)' 2>/dev/null
      done
    } | grep -oE '^[0-9]{3}' | sort -n | tail -1
  )
  printf '%03d\n' $((10#${highest:-0} + 1))
}

resume_offer() {
  jq -cn --arg c "$1" '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"SessionStart",source:"startup"}' \
    | bash "$1/.agents/hooks/session-start-resume.sh" 2>/dev/null \
    | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null
}

offer_lines() { grep -E "^- ${2//./\\.}(:| )" <<<"$1"; }

offer_research_text() { printf 'research pending: %s' "$1"; }

stub_pr_clis() {
  local bin=$1/bin log=$2 cli
  mkdir -p "$bin"
  for cli in gh glab; do
    cat >"$bin/$cli" <<EOF
#!/usr/bin/env bash
echo "$cli \$*" >> "$log"
case "\$1 \$2" in
  "auth status") exit 0 ;;
  "pr list"|"mr list") ;;
  "pr create") echo "Creating pull request..."; echo "https://github.com/o/r/pull/21" ;;
  "mr create") echo "Creating merge request"; echo " https://gitlab.com/o/r/-/merge_requests/8" ;;
esac
EOF
    chmod +x "$bin/$cli"
  done
}

refused() {
  local name=$1 err rc
  shift
  err=$("$@" 2>&1 >/dev/null)
  rc=$?
  if [ "$rc" = 2 ] && [ -n "$err" ]; then ok "$name"; else ko "$name" "rc=$rc want=2 with a reason on stderr: $err"; fi
}
