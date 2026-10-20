---
name: pr-quality
description: |
  PR code quality review dispatching parallel sub-agents for duplicate detection,
  orphan detection, complexity analysis, seam conformance and documentation conformance
  against the branch diff, plus one agent per project check in .workflow/pr-quality/*.md.

  Triggers: pr quality, code review, duplicate code, orphaned code, complexity review, pr cleanup

  Use when: before merging a PR, after completing feature work, code cleanup passes
  DO NOT use when: mid-feature development, single-file changes, non-code PRs
category: code-quality
tags: [pr-review, duplicates, orphans, complexity, refactoring, documentation]
tools: [Agent, Bash, Grep, Glob, Read]
modules:
  - duplicate-detection
  - orphan-detection
  - complexity-analysis
  - seam-conformance
  - doc-conformance
progressive_loading: true
estimated_tokens: 700
version: 1.3.0
---

# PR Quality Review

Parallel code quality analysis for PR branches. Dispatches five built-in sub-agents, plus one per project check (see [Project checks](#project-checks)), to analyze the diff against `origin/main`. All of them run every time; agents whose scope doesn't apply self-skip cheaply and say so (a silent skip reads as "checked and clean").

## Workflow

```
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
- **Context reads beyond the diff**: doc-conformance reads the branch's `.workflow/specs/` folder, cited ADRs, and sweeps `docs/`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/GLOSSARY.md` and `README.md`; seam-conformance reads the module index in `.workflow/rules.md` and `.workflow/cache/modules.md`; a project check reads what its file's Scope names — but findings always anchor to the diff
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
- **Start one** by copying [assets/project-check.template.md](assets/project-check.template.md) to `.workflow/pr-quality/<check-name>.md` and filling it in.
- **No folder or no files** → no project checks run; the report says "No project checks (.workflow/pr-quality/ has none)".
- This skill never ships project checks, and the scaffold installer never writes, overwrites or removes anything under `.workflow/pr-quality/`.

## Report Format

Each agent returns structured findings. The orchestrator consolidates them into a single report with one section per agent, counts, and actionable suggestions.

Findings without file paths and line numbers are not actionable — always include them.

## Instructions

Slash invocation: `/pr-quality`. Follow these steps exactly.
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

Dispatch agents 1–5 plus one agent per project check simultaneously using the Agent tool. Each agent must receive the full list of changed files from Step 1; agent 5 and the project-check agents also receive the branch name and commit subjects. Agents self-skip when their scope doesn't apply — a skip is reported, never silent.

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
- Prompt: Use the seam-conformance methodology from `Skill(pr-quality)` module `seam-conformance`. First read `.workflow/rules.md` § Ownership and `.workflow/cache/modules.md` (the module index and each module's public interface) and `.agents/skills/pr-quality/references/codebase-design.md` (vocabulary). Provide the agent with the list of changed files. The agent should:
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
  4. Keyword-sweep `docs/`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/GLOSSARY.md` and `README.md` (never the generated `.workflow/cache/`) for statements the diff makes false
  5. Report Tier 1 (spec/tasks/ADR mismatches) and Tier 2 (doc drift) separately, plus a one-line open-task inventory

**Project-check agents (one per `.workflow/pr-quality/*.md` file)**
- subagent_type: `Explore`
- Prompt: Read `.workflow/pr-quality/<check-name>.md` and apply it as your complete methodology. Provide the agent with the changed-file list, branch name, and commit subjects. The agent should:
  1. Exit immediately with "not applicable — <reason>" if the file's Scope trigger matches nothing in the diff
  2. Run each applicable check group against the diff; list skipped groups explicitly
  3. Report findings in the file's "What to report" format, anchored to diffed files and lines

### Step 3: Consolidate Results

After all agents complete, present a unified report:

```
## PR Quality Review

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

### Summary
- X duplicate patterns found
- Y orphaned exports found
- Z complexity issues found
- W seam violations found
- V doc mismatches (+ D drift notes)
- one line per project check: N findings in <check name>
```

Only report actual findings. If a category has no issues, say "No issues found" for that section.
