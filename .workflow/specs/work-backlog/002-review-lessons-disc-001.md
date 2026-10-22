---
origin_spec: .workflow/specs/002-review-lessons
origin_step: "2.1"
discovered_at: 2026-10-22
status: open
kind: bug
---

# The research task type is missing from the project-setup model map

## Problem

Spec 001-large-path added the `research` sub-agent, the thirteenth task type, but project-setup's model-map module still lists twelve task types in its tier table and tells the human to write "each of the 12" files. A project set up since then gets no `.workflow/model-map/research.md`, so its first research launch from an initiative is denied at 00.14 until someone writes the entry by hand. This repo's own model map has the same gap.

## Evidence

- `.agents/skills/project-setup/modules/model-map.md:10` (strong tier row) and the cheap tier row above it: neither names `research`; `grep -c research` on the file prints 0.
- `.agents/skills/project-setup/modules/model-map.md:18` and `:50`, `.agents/skills/project-setup/SKILL.md:49`: "each of the 12 task types" while `.agents/agents/` holds 13 definitions (`.agents/install-manifest.txt`, header `# --- Agents (13)`).
- `.workflow/model-map/` in this repo holds 12 files and none for `research`.

## Why not a blocker

No capability or journey of 002-review-lessons needs a research launch. T6 of that spec adds `review-lessons` to the tier table and writes a count that matches the types the table lists, so the lens ships correctly whether or not `research` is added.

## Suggested scope and size

- Scope: add `research` to the cheap or strong tier row of `modules/model-map.md` (the stakeholder picks the tier; it reads the repo, docs, git history and the web, so cheap is the likely default), update the two counts there and the one in `SKILL.md`, and write this repo's `.workflow/model-map/research.md` with the same tier. Leave the model-map template and `resolve-launch.sh` alone: they already handle any type.
- Size: one task in `project-setup` plus one repo data file; two or three files, far below the defaults of 10 tasks and 30 changed files in `.workflow/rules.md`.

## Links

- Origin spec: [spec.md](../002-review-lessons/spec.md)
- Design log entry: [design-log.md](../002-review-lessons/design-log.md) (section 2026-10-22 Discovered work: research-missing-from-model-map)
