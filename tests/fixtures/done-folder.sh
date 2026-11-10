#!/usr/bin/env bash
# File: Fixture builders and oracles for the Done folder suites (move-to-done.sh and the readers of .workflow/specs/done/).
#   Sourced after lib/common.sh and fixtures/pr-template.sh; defines variables and functions only. bash 3.2 compatible.
# Provides:
#   DONE_SPEC, DONE_SIBLING, DONE_SECOND, DONE_DRAFT   the fixture spec folders: 012-alpha (done, linked from everywhere),
#                          013-beta (in progress, links to alpha), 014-gamma (done) and 015-delta (draft)
#   DONE_MTD_REL           move-to-done.sh relative to the project root
#   done_manifest          prints the fixture project as `=== <path>` records followed by each file's lines. Paths and text
#                          hold placeholders: @S@ and @G@ are where 012-alpha and 014-gamma sit under .workflow/specs/
#                          (`012-alpha` or `done/012-alpha`), @UP@ and @GUP@ are the extra `../` a link leaving that spec
#                          folder needs once it sits one level deeper. Every back-link form is planted once: the repo-relative
#                          path (shelf, backlog item, review lesson, retrospective, the spec's own files and pr-body.md),
#                          `../specs/` (shelf), `../../specs/` (retrospective), `specs/` (capabilities.md) and `../NNN-slug/`
#                          (backlog item, sibling spec). The initiative file, docs/notes.md and a shelf file
#                          naming the look-alike specs 012-alpha-two and 012-alphabet hold literal paths only.
#   done_render DEST KEY=VALUE...   renders a manifest read on stdin into DEST, replacing each @KEY@ with VALUE
#   done_folder_repo DIR   git repo with a committed copy of .agents/ and the manifest rendered at the top level, checked out
#                          on spec/012-alpha, with the gitignored step markers 5.8 (alpha, gamma), 3.4 (beta) and 0.1.6 (delta)
#   done_expected DEST moved   the tree the manifest describes after `move-to-done.sh .workflow/specs/012-alpha`
#   done_digits_manifest, done_digits_repo DIR, done_digits_expected DEST
#                          the any-digit project: 00010-wide and 009-narrow done, 005-current in progress and checked out on
#                          spec/005-current, a backlog item and a shelf file pointing at the two done specs (@W@ and @N@)
#   tree_differences EXPECTED ACTUAL   prints one line per file under .workflow/ or docs/ (step markers left out) that is
#                          missing from ACTUAL, extra in ACTUAL, or differs; nothing when the trees match
#   unresolved_links DIR   prints `<file>: <target>` for each relative Markdown link in DIR/**/*.md that does not resolve with
#                          test -e from its file's folder; links to a URL or an anchor only are skipped
#   old_spec_refs ROOT NAME   prints each line under ROOT/.workflow/, outside initiatives/, that still names spec NAME
#                          at the top level of the specs folder (`specs/NAME` or `../NAME`, NAME followed by a non-slug character)
#   tree_digest DIR        prints a checksum of every file under DIR outside .git, ignored files included, then the branch,
#                          every ref and `git status`, so two calls compare equal only when nothing changed
#   step_marker DIR STEP   writes the gitignored step marker of the spec folder DIR (absolute) at STEP
# shellcheck disable=SC2034  # the variables are read by the suites that source this file

DONE_SPEC=.workflow/specs/012-alpha
DONE_SIBLING=.workflow/specs/013-beta
DONE_SECOND=.workflow/specs/014-gamma
DONE_DRAFT=.workflow/specs/015-delta
DONE_MTD_REL=.agents/skills/feature-workflow/scripts/move-to-done.sh

DONE_GITIGNORE='.workflow/specs/*/.step
.workflow/initiatives/*/.step
.workflow/.worktrees/
.workflow/.handoff/
.workflow/.standards-staging/'

done_manifest() {
  printf '=== .gitignore\n%s\n' "$DONE_GITIGNORE"
  cat <<'EOF'
=== .workflow/GLOSSARY.md
# Glossary
=== .workflow/decisions/adr/0001-baseline.md
# ADR 0001: project baseline
=== .workflow/specs/@S@/spec.md
---
status: done
baseline_revision: ""
spec_branch: spec/012-alpha
impl_base_revision: ""
light_path: false
followup_review_recommended: false
deferred: [.workflow/deferred/alpha-shelf.md]
---

# Alpha feature

## Why

Alpha is the fixture spec that moves into the Done folder.

## Links

- Design log: [design-log.md](design-log.md)
- Report: [report.md](report.md#summary)
- Shelf item: [alpha-shelf.md](@UP@../../deferred/alpha-shelf.md)
- Baseline ADR: [0001-baseline.md](@UP@../../decisions/adr/0001-baseline.md)
- Backlog item: [012-alpha-disc-001.md](@UP@../work-backlog/012-alpha-disc-001.md)
- Sibling spec: [013-beta](@UP@../013-beta/spec.md)
- Glossary: [GLOSSARY.md](@UP@../../GLOSSARY.md "the shared vocabulary")
- Tracker: [issue 12](https://example.invalid/issues/12)
- Section: [Why](#why)
=== .workflow/specs/@S@/tasks.md
---
tasks:
  - id: T1
    title: "Move script"
    status: done
  - id: T2
    title: "Sign-off wiring"
    status: done
  - id: T3
    title: "Sweep, split out"
    status: split-out
---

# Tasks

The task index of [spec.md](spec.md).
=== .workflow/specs/@S@/tasks/T01-move.md
# T1: Move script

Spec: [spec.md](../spec.md)
Shelf item: [alpha-shelf.md](@UP@../../../deferred/alpha-shelf.md)
=== .workflow/specs/@S@/design-log.md
# Design log: Alpha feature

Spec: [spec.md](spec.md)

## 2026-10-30 Sign-off

- Report: .workflow/specs/@S@/report.md
- Task file: `.workflow/specs/@S@/tasks/T01-move.md`
- Deferred: [alpha-shelf.md](@UP@../../deferred/alpha-shelf.md)
=== .workflow/specs/@S@/report.md
# Report

## Summary

Evidence lives under .workflow/specs/@S@/artifacts/.
=== .workflow/specs/@S@/artifacts/T1/toolchain.txt
RESULT passed=3 failed=0 skipped=0 xfail=0
EOF
  printf '=== .workflow/specs/@S@/pr-body.md\n'
  printf '%s\n' "$PR_TEMPLATE_SECTIONS" | pr_body_from_headings
  # shellcheck disable=SC2016  # the backticks are Markdown code spans
  printf 'Report: `.workflow/specs/@S@/report.md`\n'
  cat <<'EOF'
=== .workflow/specs/013-beta/spec.md
---
status: in-progress
spec_branch: spec/013-beta
---

# Beta feature

## Why

Beta builds on [012-alpha](../@S@/spec.md), recorded as .workflow/specs/@S@ in its design log.
=== .workflow/specs/@G@/spec.md
---
status: done
spec_branch: spec/014-gamma
---

# Gamma feature

Design log: [design-log.md](design-log.md) · Glossary: [GLOSSARY.md](@GUP@../../GLOSSARY.md)
=== .workflow/specs/@G@/tasks.md
---
tasks:
  - id: T1
    title: "Gamma"
    status: done
---

# Tasks
=== .workflow/specs/@G@/design-log.md
# Design log: Gamma feature

- Folder: .workflow/specs/@G@
=== .workflow/specs/015-delta/spec.md
---
status: draft
spec_branch: ""
---

# Delta feature
=== .workflow/specs/work-backlog/012-alpha-disc-001.md
---
origin_spec: .workflow/specs/@S@
origin_step: "3.4"
discovered_at: 2026-10-28
status: open
kind: bug
---

# Retry the flaky fetch

Origin: [012-alpha](../@S@/spec.md)
=== .workflow/specs/work-backlog/012-alpha-disc-002.md
---
origin_spec: .workflow/specs/@S@
origin_step: "4.4"
discovered_at: 2026-10-29
status: dismissed
kind: refactor
---

# Rename the helper
=== .workflow/specs/work-backlog/012-alpha-disc-003.md
---
origin_spec: .workflow/specs/@S@
origin_step: "3.6"
discovered_at: 2026-10-29
status: promoted
promoted_to: .workflow/specs/015-delta
kind: requirement
---

# Delta follow-up
=== .workflow/specs/work-backlog/012-alpha-disc-004.md
---
origin_spec: .workflow/specs/@S@
origin_step: "4.4"
discovered_at: 2026-10-29
status: moved-to-deferred
kind: requirement
---

# Shelved follow-up

Deferred file: [alpha-shelf.md](../../deferred/alpha-shelf.md)
=== .workflow/specs/work-backlog/013-beta-disc-001.md
---
origin_spec: .workflow/specs/013-beta
origin_step: "3.4"
discovered_at: 2026-10-30
status: open
kind: bug
---

# Beta item
=== .workflow/deferred/alpha-shelf.md
---
origin_spec: .workflow/specs/@S@
created: 2026-10-29
---

# Alpha follow-up

Shelved from [012-alpha](../specs/@S@/spec.md) at 0.3.17.
=== .workflow/deferred/gamma-shelf.md
---
origin_spec: .workflow/specs/@G@
created: 2026-10-20
---

# Gamma follow-up

Shelved from [014-gamma](../specs/@G@/design-log.md).
=== .workflow/deferred/alpha-two-shelf.md
---
origin_spec: .workflow/specs/012-alpha-two
created: 2026-10-30
---

# Look-alike specs

From [012-alpha-two](../specs/012-alpha-two/spec.md); see also .workflow/specs/012-alphabet and specs/012-alpha.md.
=== .workflow/decisions/retrospectives/012-alpha.md
---
spec: .workflow/specs/@S@
verdict: accepted
---

# Retrospective: 012-alpha

Spec: [spec.md](../../specs/@S@/spec.md) · Design log: [design-log.md](../../specs/@S@/design-log.md)
=== .workflow/capabilities.md
# Capabilities

| Id | Capability | Spec |
| --- | --- | --- |
| CAP-001 | Alpha feature | [012-alpha](specs/@S@/spec.md) |
| CAP-002 | Gamma feature | [014-gamma](specs/@G@/spec.md) |
=== .workflow/review-lessons.md
# Review lessons

```yaml
lessons:
  - id: RL-001
    symptom: "A script opens a path from its arguments without checking it exists."
    paths: ["src/**"]
    origin_spec: .workflow/specs/@S@
    date: 2026-10-30
```
=== .workflow/initiatives/001-ini/initiative.md
---
status: planned
origin: 001-ini
slices:
  - {id: S1, title: Alpha, status: emitted, spec: 012-alpha}
---

# Initiative: ini

Emitted: [012-alpha](../../specs/012-alpha/spec.md), folder .workflow/specs/012-alpha.
=== docs/notes.md
Alpha shipped: .workflow/specs/012-alpha/spec.md
EOF
}

done_render() {
  local dest=$1 subs="" pair
  shift
  for pair in "$@"; do subs="$subs$pair;"; done
  awk -v dest="$dest" -v subs="$subs" '
    BEGIN {
      n = split(subs, pairs, ";")
      for (i = 1; i <= n; i++) {
        if (pairs[i] == "") continue
        eq = index(pairs[i], "=")
        key[i] = "@" substr(pairs[i], 1, eq - 1) "@"
        val[i] = substr(pairs[i], eq + 1)
      }
    }
    function fill(text,   i) { for (i = 1; i <= n; i++) if (i in key) gsub(key[i], val[i], text); return text }
    /^=== / {
      if (out != "") close(out)
      out = dest "/" fill(substr($0, 5))
      dir = out
      sub(/\/[^\/]*$/, "", dir)
      system("mkdir -p \"" dir "\"")
      printf "" > out
      next
    }
    out != "" { print fill($0) > out }
  '
}

step_marker() {
  printf 'step: "%s"\nupdated_at: "2026-10-30T10:00:00Z"\n' "$2" >"$1/.step"
}

done_folder_repo() {
  local p=$1
  git_init_repo "$p"
  copy_agents "$p"
  done_manifest | done_render "$p" S=012-alpha UP= G=014-gamma GUP=
  git_commit_all "$p" "fixture: done-folder project"
  git -C "$p" switch -q -c spec/012-alpha
  step_marker "$p/$DONE_SPEC" 5.8
  step_marker "$p/$DONE_SECOND" 5.8
  step_marker "$p/$DONE_SIBLING" 3.4
  step_marker "$p/$DONE_DRAFT" 0.1.6
}

done_expected() {
  case "$2" in
    moved) done_manifest | done_render "$1" S=done/012-alpha UP=../ G=014-gamma GUP= ;;
    *) return 1 ;;
  esac
}

done_digits_manifest() {
  printf '=== .gitignore\n%s\n' "$DONE_GITIGNORE"
  cat <<'EOF'
=== .workflow/GLOSSARY.md
# Glossary
=== .workflow/specs/@W@/spec.md
---
status: done
spec_branch: spec/00010-wide
---

# Wide number

Glossary: [GLOSSARY.md](@WUP@../../GLOSSARY.md)
=== .workflow/specs/@W@/tasks.md
---
tasks:
  - id: T1
    title: "Wide"
    status: done
---
=== .workflow/specs/@N@/spec.md
---
status: done
spec_branch: spec/009-narrow
---

# Narrow number

Design log: .workflow/specs/@N@/design-log.md
=== .workflow/specs/@N@/tasks.md
---
tasks:
  - id: T1
    title: "Narrow"
    status: split-out
---
=== .workflow/specs/005-current/spec.md
---
status: in-progress
spec_branch: spec/005-current
---

# Current work
=== .workflow/specs/work-backlog/00010-wide-disc-001.md
---
origin_spec: .workflow/specs/@W@
origin_step: "3.4"
discovered_at: 2026-10-30
status: open
kind: bug
---

# Wide item

Origin: [00010-wide](../@W@/spec.md)
=== .workflow/deferred/narrow-shelf.md
---
origin_spec: .workflow/specs/@N@
created: 2026-10-30
---

# Narrow follow-up

Shelved from [009-narrow](../specs/@N@/spec.md).
EOF
}

done_digits_repo() {
  local p=$1
  git_init_repo "$p"
  copy_agents "$p"
  done_digits_manifest | done_render "$p" W=00010-wide WUP= N=009-narrow
  git_commit_all "$p" "fixture: any-digit project"
  git -C "$p" switch -q -c spec/005-current
  step_marker "$p/.workflow/specs/00010-wide" 5.8
  step_marker "$p/.workflow/specs/009-narrow" 5.8
  step_marker "$p/.workflow/specs/005-current" 3.4
}

done_digits_expected() {
  done_digits_manifest | done_render "$1" W=done/00010-wide WUP=../ N=done/009-narrow
}

# tree_files DIR : the files under DIR/.workflow and DIR/docs that the expected tree describes, one per line, sorted.
tree_files() {
  (cd "$1" && find .workflow docs -type f ! -name .step 2>/dev/null | LC_ALL=C sort)
}

tree_differences() {
  local expected=$1 actual=$2 f
  LC_ALL=C comm -23 <(tree_files "$expected") <(tree_files "$actual") | sed 's/^/missing: /'
  LC_ALL=C comm -13 <(tree_files "$expected") <(tree_files "$actual") | sed 's/^/extra: /'
  while IFS= read -r f; do
    cmp -s "$expected/$f" "$actual/$f" || echo "differs: $f"
  done < <(LC_ALL=C comm -12 <(tree_files "$expected") <(tree_files "$actual"))
}

unresolved_links() {
  local file target
  while IFS= read -r file; do
    while IFS= read -r target; do
      target=${target#](}
      target=${target%)}
      target=${target%% *}
      case "$target" in
        "" | \#* | *://* | mailto:*) continue ;;
      esac
      target=${target%%#*}
      [[ -e "$(dirname "$file")/$target" ]] || echo "$file: $target"
    done < <(grep -oE '\]\([^)]+\)' "$file")
  done < <(find "$1" -name '*.md' -type f)
}

old_spec_refs() {
  grep -rnE --exclude-dir=initiatives "(specs|\.\.)/$2([^A-Za-z0-9._-]|$)" "$1/.workflow" 2>/dev/null
}

tree_digest() {
  (cd "$1" && find . -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort)
  git -C "$1" branch --show-current
  git -C "$1" for-each-ref --format='%(refname) %(objectname)'
  git -C "$1" status --porcelain --ignored
}
