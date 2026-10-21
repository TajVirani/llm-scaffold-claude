# Commit hygiene
<!-- verified_at_commit: 0a662df5d1046bd2984be858e813992a7fb36eb7 -->

## Objective

Keep the branch history readable as the developer's own: Conventional Commit subjects, and no AI attribution. Report-only.

## Scope

- **Trigger:** every PR. Read the commits with `git log --format='%H%n%s%n%b' <merge-base>..HEAD`. If the range has no commits, report "not applicable — no commits in range" and stop.
- **Read:** only the commit messages; the diff is not needed.
- **Report:** findings anchor to the commit sha.

## Checks

### A. Subject

- Flag a subject that is not `<type>(<optional scope>): <summary>` with type one of `feat`, `fix`, `docs`, `chore`, `test`, `refactor`. Suggest the matching type.

### B. Attribution

- Flag any `Co-Authored-By` trailer, and any mention of Claude, an AI or an AI assistant in the subject or body. Suggest removing it; the message reads as written by the developer.

## What to report

```
- **[SEVERITY]** `<short sha>` — [what is wrong]
  Rule: [one-line statement of the convention]
  Suggestion: [the sanctioned alternative]
```

| Severity | Description |
|----------|-------------|
| **HIGH** | AI attribution or a `Co-Authored-By` trailer |
| **MEDIUM** | subject not in Conventional Commit form |
| **LOW** | type is valid but a better-fitting one exists |

## What NOT to flag

- Merge commits.
- Commits already on the main branch before the merge-base.
