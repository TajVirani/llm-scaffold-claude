# <Check name>

<!-- Template for a project check. Copy to docs/pr-quality/<check-name>.md in your project and fill it in.
     pr-quality runs one sub-agent per docs/pr-quality/*.md file (README.md excluded), handing it this file as
     its whole methodology. The file is project-owned: the scaffold never ships, overwrites or removes it.
     The H1 above becomes the section heading in the pr-quality report. Delete this comment. -->

## Objective

<One or two sentences: what this check protects, and why the project needs it (a library's correct use, a
recurring fix pattern from history, a house rule no linter enforces). Report-only.>

## Scope

- **Trigger:** <which diffed files this check applies to, e.g. files importing `<library>`, or files under
  `<path>/`>. If none match, report "not applicable — <reason>" and stop. A silent skip reads as "checked
  and clean".
- **Read:** <what to read beyond the diff for context, e.g. the defining module of a store the diff uses>.
- **Report:** findings anchor to diffed files and lines. Issues found outside the diff are reported only
  when they affect a diffed file, labeled "upstream of this diff".

## Checks

### A. <Check group> — <when it applies, e.g. "when the diff touches client/">

- <A concrete, checkable rule: the pattern to flag, and the sanctioned alternative.>
- <Another rule.>

### B. <Check group>

- <Rule.>

When a group's trigger does not match the diff, list it as skipped in one line ("sections B skipped — no
matching files in diff").

## What to report

```
- **[SEVERITY]** `path/to/file.ext:LINE` — [what is wrong]
  Rule: [one-line statement of the convention]
  Suggestion: [the sanctioned alternative]
```

| Severity | Description |
|----------|-------------|
| **HIGH** | <correctness or data risk> |
| **MEDIUM** | <convention broken in new code> |
| **LOW** | <pre-existing or cosmetic> |

## What NOT to flag

- <Documented exceptions to the rules above.>
- Pre-existing violations in unchanged lines of a diffed file (note them at most once, labeled pre-existing).
- Generated files and test fixtures.
