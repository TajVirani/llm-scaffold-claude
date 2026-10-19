<!--
Module of project-standards: refresh mode (stamps exist).
Sources: first-party. Refresh as a diff from the recorded sha, `git log --diff-filter=DR --name-only` against every line, re-verify every path and caveat, never re-ask what a prior run settled, and grow only on new evidence adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/SKILL.md@8f0d50e "Refresh" (MIT; pattern only).
-->

# Refresh

Bring the standards back in line with the code since they were last verified. Same steps as a full run, with step 1 as a diff and the interview limited to what changed.

## 1. Find the stamps

```bash
grep -rHo 'verified_at_commit: [0-9a-f]\{40\}' docs/rules.md profiles docs/decisions/adr docs/pr-quality AGENTS.md 2>/dev/null
```

Take the oldest stamped commit as `since_commit` (`git merge-base --is-ancestor` orders them). A doc with no stamp is treated as unverified: every line in it is re-checked as in brownfield.

Done when every standards doc has a `since_commit` or is marked unverified.

## 2. Diff the referents

- `git log --diff-filter=DR --name-only --format= <since_commit>..HEAD`: every path a doc names that was deleted or renamed is a drift row.
- `git diff --name-only <since_commit>..HEAD`: the changed paths decide which scopes need discovery.
- A changed lint, format or typecheck config named in a profile's Toolchain marks that profile as touched, so step 8 re-runs its `lint`.

Done when every path named in the docs is checked and the changed scopes are listed.

## 3. Discover the changed scopes

Launch `standards-discovery` per changed scope as in [discovery.md](discovery.md), with `since_commit` set and `instruction_files` listing the standards docs. Its `## Contradictions` section is the drift between the docs and the code.

Done when every changed scope's return is saved under `.standards-staging/`.

## 4. Report drift, then interview

Show the human one drift list: deleted or renamed referents, contradictions (doc says, code does, both cited), new conventions the code adopted since the stamp, and versions that changed in their declaring files. For each item, the question is: update the doc, or treat the code as the defect (then it is discovered work, not a standards change).

Interview per [interview.md](interview.md), limited to the drift list. Never re-ask a point a prior run settled and the code still follows.

Done when every drift item is answered.

## 5. Back to the main steps

Draft only the changed lines in `.standards-staging/baseline.md` (each removal is a row with its ground), then run SKILL.md steps 5-9. Re-stamp every doc this run re-verified, including one whose lines all still hold.
