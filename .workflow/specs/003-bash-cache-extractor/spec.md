---
status: in-progress # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "86609a64711682747a07bea99a7ed442cf5a827c" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/003-bash-cache-extractor # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "8649720c48726c937fac91bc3597d91b680ad6fd" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
# origin: NNN-slug-disc-001.md       # optional; filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
budget: {max_tasks: 10, max_changed_files: 30} # absent until written; written at 2.5 (0.3.20 on the light path) from .workflow/rules.md "Size budget"; raised only by an approved overrun (00.29)
# blocked_condition: "<what a human must decide or do before work can continue>"   # present only while status is blocked; forms: "discovered work: <slug>", "size budget: <what>", or free text
---

# Tier B caches for bash projects

## Why

The Tier B caches (module map, flows, architecture) can only be built for JS/TS code: `regenerate-caches/scripts/build-architecture.sh` uses dependency-cruiser as the only parser for all three, and dependency-cruiser cannot read bash. A bash project, including this scaffold repo, never gets caches, so every feature's retrieval re-reads the code and records null stamps, as spec 001 did. Let the workflow build and keep Tier B caches for projects whose code is not JS/TS, starting with bash: each work profile names its **graph extractor**, every extractor prints dependency-cruiser's JSON shape, and a bash extractor joins dependency-cruiser. More languages will follow, so a new one must be one new script. Design decisions are D1-D9 in [design-log.md](design-log.md).

## Capabilities

- **CAP-004** Graph extractor per work profile
  - **intent:** The cache build runs the graph extractor each work profile names, so caches can be built for any language that has an extractor.
  - **success:** With profiles naming `dependency-cruiser`, `bash` or `none`, `build-architecture.sh` runs each named extractor, merges their graphs and renders all three caches; a JS/TS fixture renders output identical to today's, apart from architecture's new "Unresolved edges" section reading `None.`, once its profile names `dependency-cruiser`; a profile without the key fails with a message that says it is a breaking change, names the profile and gives the line to add; the depcruise boundary check runs only when a profile names `dependency-cruiser` (D16), and otherwise Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (<names>).` (D17), so a project with a committed boundary config but no `dependency-cruiser` profile builds architecture without depcruise.
- **CAP-005** Bash graph extractor
  - **intent:** A bash project gets a file graph from its `source`/`.` lines and script-to-script calls, with entry-point candidates and the functions of sourced files.
  - **success:** On fixtures, the bash extractor prints dependency-cruiser-shaped JSON with every statically resolvable edge, `couldNotResolve: true` for each path it cannot resolve, and an `exports` map of top-level functions for sourced files; architecture.md lists each unresolved edge under "Unresolved edges", modules.md shows each module's functions as Public interface, and flows.md lists no file matching a profile's `test_patterns` as an entry point; run on this repo at 5.3, the three caches pass `check-staged-cache.sh`, publish, and `cache-stamp-check.sh` reports them fresh.

## Constraints

- bash 3.2 and BSD/GNU-portable awk, grep and jq only; no new runtime dependency (`.workflow/rules.md` § Required versions).
- Every extractor prints dependency-cruiser's JSON shape (D2); `build-architecture.sh`'s canonicalisation stays the one reader of it.
- An unresolvable path is reported as unresolved, never guessed (D3), in architecture.md's "Unresolved edges" section (D10); `check-staged-cache.sh` changes only to accept that section.
- Only `--from-json` bypasses profile resolution; `--extractor NAME` overrides which extractor runs but still requires the key in every profile (D12).
- Existing profiles in this repo change only at 5.3 (`check-write.sh:64-68`): their keys go through `proposals.md` (D7).

## Non-goals

- Graph extractors for languages other than bash.
- A boundary checker for bash (enforcing `.workflow/rules.md` Ownership); Boundary violations stays "Not checked" for bash, with the D17 wording.
- A markdown extractor for skill-to-script path references.
- Changes to `install.sh`, including an update-time notice (D8).
- Editing target projects' profiles; the error tells the user what to add (D5).
- Leaving the boundary config out of the architecture stamp scope when the check does not run (D18).

## Success signal

A bash project whose profiles name `graph_extractor: bash` gets all three Tier B caches from `regenerate-caches`, a JS/TS project keyed to `dependency-cruiser` renders exactly as before, and this repo's discovery stamp check reports modules, flows and architecture fresh instead of missing, without depcruise although the repo commits a boundary config (objectives and journeys JRN-001 to JRN-006 in [verification-plan.md](verification-plan.md)).

## Assumptions

- Confirmed: the `generator` frontmatter field records the names of the extractors that ran, comma-joined and sorted (e.g. `bash`, `bash,dependency-cruiser`). Callers read it from `build-architecture.sh --print-generator` (D14); discovery, the cache-regeneration agent and regenerate-caches no longer hardcode `--generator dependency-cruiser`.
- Confirmed: the shipped profile template and example profiles (`project-setup/assets/profiles/`) carry the `graph_extractor` key, and project-setup asks for it when it writes a profile. dependency-cruiser stays required where a profile names it or a boundary config exists.
- Confirmed: the bash extractor claims `*.sh` files and files with a bash or sh shebang; dependency-cruiser claims what it does today. Unresolved edges carry an optional `line` (D15), and every script call the bash extractor detects is either an edge or an unresolved entry.

## Known gaps

- With every profile naming `none`, no architecture cache can be published: [work-backlog/003-bash-cache-extractor-disc-001.md](../work-backlog/003-bash-cache-extractor-disc-001.md).
- `case` pattern alternatives such as `../*` are listed as unresolved calls (two entries from `install.sh`): [work-backlog/003-bash-cache-extractor-disc-003.md](../work-backlog/003-bash-cache-extractor-disc-003.md).

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)
