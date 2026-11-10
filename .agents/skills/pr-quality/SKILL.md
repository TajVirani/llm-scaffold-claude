---
name: pr-quality
description: |
  PR code quality review dispatching parallel sub-agents for duplicate detection,
  orphan detection, complexity analysis, seam conformance and documentation conformance
  against the branch diff, plus one agent per project check in .workflow/pr-quality/*.md and,
  when .workflow/pr-quality/expert-panel/ exists, a per-concept expert panel that debates
  cross-concept impact. On a workflow spec branch whose spec is in-review or done, skips the
  checks the Phase 4 review already settled and says so.

  Triggers: pr quality, code review, duplicate code, orphaned code, complexity review, pr cleanup

  Use when: before merging a PR, after completing feature work, code cleanup passes
  DO NOT use when: mid-feature development, single-file changes, non-code PRs
category: code-quality
tags: [pr-review, duplicates, orphans, complexity, refactoring, documentation]
tools: [Agent, Bash, Grep, Glob, Read, SendMessage]
modules:
  - duplicate-detection
  - orphan-detection
  - complexity-analysis
  - seam-conformance
  - doc-conformance
progressive_loading: true
estimated_tokens: 700
version: 1.4.0
---

# PR Quality Review

Parallel code quality analysis for PR branches. Dispatches five built-in sub-agents, plus one per project check (see [Project checks](#project-checks)), to analyze the diff against `origin/main`. When the branch's workflow spec has already passed its Phase 4 review, Step 0 skips the checks that review settled. Every other agent runs; one whose scope doesn't apply self-skips cheaply and says so. Every skip is reported: a silent skip reads as "checked and clean".

## Workflow

```
spec for the branch, status in-review or done? → skip Dupe, Seam, Docs and covered project checks
git diff origin/main → changed files + branch name + commit subjects
ls .workflow/pr-quality/*.md → project checks (0..N)
         ↓
 ┌────┬────┬────┬────┬────┐
 ↓    ↓    ↓    ↓    ↓    ↓
Dupe Orph Cmplx Seam Docs Project check × N
 ↓    ↓    ↓    ↓    ↓    ↓
 └────┴────┴────┴────┴────┘
         ↓
  Consolidated Report
```

## Scope Rules

- **Only analyze source files**: the languages the project is written in
- **Skip**: dependency and build output (`node_modules`, `vendor`, `dist`, `build`), generated files, `*.test.*`, `*.spec.*`, config files
- **New code focus**: Duplicate detection compares new functions against the existing codebase and against each other
- **Whole-file scope**: Orphan and complexity checks examine the full file, not just the diff hunks; a project check sets its own scope
- **Context reads beyond the diff**: doc-conformance reads the branch's `.workflow/specs/` folder, cited ADRs, and sweeps `docs/`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/GLOSSARY.md` and `README.md`; seam-conformance reads the module index in `.workflow/rules.md` and finds each module's seam in the code; a project check reads what its file's Scope names — but findings always anchor to the diff
- **Self-skips**: no spec folder → doc agent reports it and stops; no modules in `.workflow/rules.md` → seam agent reports "not applicable"; a project check whose trigger matches nothing in the diff reports "not applicable" and lists any skipped sections

## Analysis Modules

See `modules/duplicate-detection.md` for duplicate code methodology.
See `modules/orphan-detection.md` for orphaned code methodology.
See `modules/complexity-analysis.md` for complexity analysis methodology.
See `modules/seam-conformance.md` for deep-module / seam conformance against the modules in `.workflow/rules.md` § Ownership.
See `modules/doc-conformance.md` for spec/PRD ↔ code conformance and doc-drift detection (two-tier severity).

## Project checks

Project-specific checks (a library's correct use, recurring fix patterns from the project's history, house rules no linter enforces) are **project-owned**: they live in the target project, never in this skill.

- **Contract:** every `.workflow/pr-quality/*.md` file in the project root except `README.md` is one project check. Each file is the complete methodology for one sub-agent: Objective, Scope (trigger and self-skip), Checks, What to report, What NOT to flag. Its H1 names its report section.
- **Covered by the review phase:** a check whose file starts with the frontmatter `covered_by_review: true` repeats what the workflow's Phase 4 review already judges (commit subjects against `.workflow/rules.md`, say). Step 0 skips it on a branch whose spec is `in-review` or `done`; everywhere else it runs. Leave the key out for a check the review does not cover.
- **Start one** by copying [assets/project-check.template.md](assets/project-check.template.md) to `.workflow/pr-quality/<check-name>.md` and filling it in.
- **Expert panel:** `.workflow/pr-quality/expert-panel/` is not a project check (the `*.md` listing never descends into it). When its `PANEL.md` exists, the orchestrator runs it as Step 2b, because the panel fans out per expert and debates over `SendMessage`, which a single check agent cannot do.
- **No folder or no files** → no project checks run; the report says "No project checks (.workflow/pr-quality/ has none)".
- This skill never ships project checks, and the scaffold installer never writes, overwrites or removes anything under `.workflow/pr-quality/`.

## Report Format

Each agent returns structured findings. The orchestrator consolidates them into a single report with one section per agent, counts, and actionable suggestions.

Findings without file paths and line numbers are not actionable — always include them.

## Instructions

Slash invocation: `/pr-quality`. Follow these steps exactly.

### Step 0: Skip what the review phase settled

A workflow spec that reached `in-review` or `done` has been through the Phase 4 review: its standards and end-state lenses already judged duplication, module seams, the spec and docs, and the project's written rules. Find the branch's spec:

```bash
branch=$(git rev-parse --abbrev-ref HEAD)
case "$branch" in spec/*) slug=${branch#spec/} ;; *) slug="" ;; esac
[ -n "$slug" ] || slug=$(git diff origin/main --name-only | sed -nE 's#^\.workflow/specs/(done/)?([0-9]+-[^/]+)/.*#\2#p' | sort -u)
for d in ".workflow/specs/$slug" ".workflow/specs/done/$slug"; do [ -f "$d/spec.md" ] && yq --front-matter=extract '.status' "$d/spec.md" && break; done
```

- **One spec found, status `in-review` or `done`:** skip Agent 1 (duplicate detection), Agent 4 (seam conformance) and Agent 5 (documentation conformance), and every project check this loop prints (a file with no frontmatter has no key, so it runs):

  ```bash
  for f in .workflow/pr-quality/*.md; do [ "$(head -n 1 "$f")" = "---" ] && [ "$(yq --front-matter=extract '.covered_by_review // false' "$f")" = true ] && echo "$f"; done; true
  ```

  Orphan detection, complexity, the other project checks and the expert panel still run.
- **Anything else** (no `spec/` branch and no spec folder in the diff, more than one slug, no `spec.md`, any other status): skip nothing.

Done when you know the spec and its status, or that there is none, and which agents Step 2 leaves out.

### Step 1: Gather Context

Run these commands to understand what changed:
```bash
git diff origin/main --name-only --diff-filter=ACMR
```
This gives you the list of new/modified files in this PR. Focus on source files — ignore config, generated files and dependency or build output (see Scope Rules).

Also run:
```bash
git diff origin/main --stat
git rev-parse --abbrev-ref HEAD
git log origin/main..HEAD --pretty="%s"
```
The branch name and commit subjects feed the doc-conformance agent (spec folder lookup + cited-ADR detection).

Then list the project checks:
```bash
ls .workflow/pr-quality/*.md 2>/dev/null | grep -v '/README\.md$'
```

### Step 2: Launch the Parallel Sub-Agents

Dispatch agents 1–5 plus one agent per project check simultaneously using the Agent tool, leaving out the ones Step 0 skipped. Each agent must receive the full list of changed files from Step 1; agent 5 and the project-check agents also receive the branch name and commit subjects. Agents self-skip when their scope doesn't apply — a skip is reported, never silent.

**Agent 1: Duplicate Code Detection**
- subagent_type: `Explore`
- Prompt: Use the duplicate detection methodology from `Skill(pr-quality)` module `duplicate-detection`. Provide the agent with the list of changed files. The agent should:
  1. Read each new/modified file to extract new functions and components
  2. Search the broader codebase for similar logic patterns
  3. Compare new functions against each other for internal duplication
  4. Report findings as a structured list

**Agent 2: Orphaned Code Detection**
- subagent_type: `Explore`
- Prompt: Use the orphan detection methodology from `Skill(pr-quality)` module `orphan-detection`. Provide the agent with the list of changed files. The agent should:
  1. Identify all exported functions, components, types, and constants in changed files
  2. Search the codebase for imports/references to each export
  3. Check for dead code left behind by refactors (renamed files show up in git status as R)
  4. Report unreferenced exports

**Agent 3: Complexity Analysis**
- subagent_type: `Explore`
- Prompt: Use the complexity analysis methodology from `Skill(pr-quality)` module `complexity-analysis`. Provide the agent with the list of changed files. The agent should:
  1. Check file line counts (flag >300 lines)
  2. Detect files with multiple component/function exports that should be split
  3. Identify components with co-located helper files that should be in a subfolder
  4. Flag shared logic buried in component directories that should be elevated to `lib/` or `utils/`
  5. Report findings with specific refactoring suggestions

**Agent 4: Seam Conformance**
- subagent_type: `Explore`
- Prompt: Use the seam-conformance methodology from `Skill(pr-quality)` module `seam-conformance`. First read `.workflow/rules.md` § Ownership (the module index) and `.agents/skills/pr-quality/references/codebase-design.md` (vocabulary). Provide the agent with the list of changed files. The agent should:
  1. For each module, check whether changed code from outside it reaches *past* its seam into internals instead of through the sanctioned entry point
  2. Flag new public exports that widen a module's seam without earning their place (deletion test)
  3. Flag new shallow modules (interface nearly as complex as implementation) and new behaviour that duplicates what an existing module's interface already provides
  4. Flag substantial new subsystems that no module in `.workflow/rules.md` owns
  5. Report findings with file:line, the module/seam involved, and a concrete suggestion (route through the seam / keep private / merge / add Ownership entry)

**Agent 5: Documentation Conformance**
- subagent_type: `Explore`
- Prompt: Use the doc-conformance methodology from `Skill(pr-quality)` module `doc-conformance`. Provide the agent with the changed-file list, branch name, and commit subjects. The agent should:
  1. Locate the originating spec folder from the branch name (`.workflow/specs/<branch>/`); no match → report that as a finding and stop
  2. Check spec.md/plan.md/tasks.md against the diff in both directions: doc claims without code, code without doc record, task checkbox state
  3. Check ADRs cited in commits/diff for contradiction
  4. Keyword-sweep `docs/`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/GLOSSARY.md` and `README.md` for statements the diff makes false
  5. Report Tier 1 (spec/tasks/ADR mismatches) and Tier 2 (doc drift) separately, plus a one-line open-task inventory

**Project-check agents (one per `.workflow/pr-quality/*.md` file)**
- subagent_type: `Explore`
- Prompt: Read `.workflow/pr-quality/<check-name>.md` and apply it as your complete methodology. Provide the agent with the changed-file list, branch name, and commit subjects. The agent should:
  1. Exit immediately with "not applicable — <reason>" if the file's Scope trigger matches nothing in the diff
  2. Run each applicable check group against the diff; list skipped groups explicitly
  3. Report findings in the file's "What to report" format, anchored to diffed files and lines

### Step 2b: Expert Panel (only when `.workflow/pr-quality/expert-panel/PANEL.md` exists)

Read `PANEL.md` and run it from this session, alongside the Step 2 agents:

1. Map the changed files onto the code roots of the roster `PANEL.md` names to find residents; dispatch one `Explore` triage agent to nominate neighbors.
2. Dispatch one `Explore` agent per resident and nominated neighbor. Each reads its persona file (matched on its `concept:` frontmatter), its roster entry and its listed docs, and returns claims in the PANEL.md claim format.
3. Run the debate rounds by continuing the same expert agents with `SendMessage`, then adjudicate per PANEL.md.
4. When the user rules on a Decision Point, append the ruling to the named personas' **Settled precedents**.

### Step 3: Consolidate Results

After all agents complete, present a unified report. A section Step 0 skipped holds one line instead of findings: `Skipped: spec <slug> is <status>; the Phase 4 review settled this.`

```
## PR Quality Review

[When Step 0 skipped anything, one line first: "Review phase settled: spec <slug> is <status>; skipped <the skipped sections>."]

### Duplicate Code
[Agent 1 findings — list each instance with file paths and line numbers]

### Orphaned Code
[Agent 2 findings — list each unreferenced export with file path]

### Complexity Issues
[Agent 3 findings — list each file with specific issue and suggestion]

### Seam Conformance
[Agent 4 findings — list each violation with file:line, module/seam, and suggestion]

### Documentation Conformance
[Agent 5 Tier 1 findings, then a "Doc Drift" subsection for Tier 2, then the open-task inventory line]

### <H1 of each project check>
[That agent's findings plus its skipped-sections line, or its "not applicable" line. With no project checks, one line: "No project checks (.workflow/pr-quality/ has none)"]

### Expert Panel
[Only when Step 2b ran: per-expert stance line, agreed findings with anchors, non-impact assertions — per PANEL.md Reporting]

### Decision Points
[Only when Step 2b ran: numbered unresolved disagreements, per PANEL.md]

### Summary
- X duplicate patterns found
- Y orphaned exports found
- Z complexity issues found
- W seam violations found
- V doc mismatches (+ D drift notes)
- one line per project check: N findings in <check name>
- expert panel: A agreed findings, P decision points (when Step 2b ran)
```

Only report actual findings. If a category has no issues, say "No issues found" for that section.
