# Payload bookkeeping
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 -->

## Objective

Every change to the distribution unit keeps its inventory in step, so `install.sh` ships the right files and every upstream-derived asset can be traced and updated. Report-only.

## Scope

- **Trigger:** the diff adds, renames, vendors or removes a file under `.agents/`. If it only edits existing files' contents, run check C only; if nothing under `.agents/` changed, report "not applicable — no .agents/ changes" and stop.
- **Read:** `PROVENANCE.md`, `.agents/install-manifest.txt`, `upstream-lineage.json`.
- **Report:** findings anchor to the added or removed path.

## Checks

### A. PROVENANCE — when a file under `.agents/` is added, vendored or removed

- Flag an added or removed asset with no matching change in `PROVENANCE.md` in the same PR. Suggest the PROVENANCE line.

### B. Manifest — when a first-party asset target projects need is added or removed

- Flag a new first-party skill, agent, hook, output style or lib file missing from `.agents/install-manifest.txt`, or a removed one still listed. Flag a vendored or scaffold-only path added to the manifest.

### C. Lineage — when a file carries or gains a `Sources:` or `Copied from` line naming an upstream

- Flag an upstream-derived asset with no `upstream-lineage.json` entry, or an entry whose commit does not match the `@<sha>` in the file. Flag a `Sources:` citation not in `<repo>/<path>@<sha>` form (at least 7 hex) or one naming a vendored path.

## What to report

```
- **[SEVERITY]** `path/to/file.ext:LINE` — [what is wrong]
  Rule: [one-line statement of the convention]
  Suggestion: [the sanctioned alternative]
```

| Severity | Description |
|----------|-------------|
| **HIGH** | manifest missing a shipped asset, or listing a vendored one |
| **MEDIUM** | PROVENANCE or lineage entry missing or out of date |
| **LOW** | citation format only |

## What NOT to flag

- What `tests/lint/upstream-lineage.sh` already fails (coverage of `Sources:`/`Copied from` lines): cite its result instead.
- Pre-existing citation breaks in unchanged lines (`task-waves.sh:45`, `block-destructive-git.sh:32-33`), noted at most once as pre-existing.
- Files under `PLAN/`, `tests/` and the scaffold-only root docs.
