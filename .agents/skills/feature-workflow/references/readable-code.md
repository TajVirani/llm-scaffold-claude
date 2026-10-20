# Readable code and comments

This baseline applies to every line of code and test the workflow adds or changes, in every project. Projects do not opt in, and a profile cannot switch it off. A project's written standard can ask for more: a docstring on every public function, a licence header. A comment that standard requires is correct, not a finding.

## Rules

- **R1. Make the code explain itself.** Give each function, variable, type and test a name that says what it is for. When a step is hard to follow, extract it into a well-named function or variable before you reach for a comment.
- **R2. Comment only what the code cannot say.** A comment is a last resort. It gives the why: intent, context, the reasoning behind a choice, a necessary trade-off, a non-obvious workaround. A workaround or trade-off a later reader would likely undo gets that comment.
- **R3. Never restate the code.** `if user.age >= 18:` needs no comment. A comment that tells the reader what the next line does is noise.
- **R4. Keep the reason in the comment itself.** Write the reasoning as a sentence. A comment never points at a decision record or a document: no decision or ADR IDs (`ADR-0007`, `D12`), no paths to docs or workflow files (`docs/`, `.workflow/`, a spec, a task ID), no URLs to internal docs. Those references go stale, and the reader of the code cannot follow them. The decision record may link to the code; the code never links back.
- **R5. Write plainly.** Short sentences, plain English, plain technical terms. No jargon, no project shorthand a newcomer would not know.

Not comments under these rules: tool directives (`eslint-disable`, `# type: ignore`, pragmas), licence headers and generated code. When a directive carries a reason, the reason follows R2-R5.

### Example

```
(cachedResult, timestamp) = getAccountStatusFromCache();
if ((now() - timestamp).inMinutes() < 1)
  return cachedResult;
else
  return fetchAccountStatusFromServer();
```

- Bad: `// Get the account status from the cache, and return that if it's less than a minute old, otherwise fetch from the server.` It restates the code (R3).
- Good: `// Try to get the account status from the cache because this function is called frequently and it's expensive to check the account status from the server too frequently.` It gives the reason the cache exists (R2).

## Checking

Judge only the comments and names the diff adds or changes. A comment that gives a reason is correct: never flag a comment for existing.

| Rule | Breach | Kind | At 3.7 | At 4.1 |
| --- | --- | --- | --- | --- |
| R4 | A comment names a decision or ADR ID, a doc or workflow path, a spec or task ID, or an internal doc URL | Hard rule: the line matches or it does not | `fail` | `standard`, severity `medium`, confidence 100 |
| R3 | A comment only restates what the line or block below it does | Judgement | `fail` when the comment says nothing the code does not | `standard`, severity `low`, confidence 80+ only when the comment adds nothing |
| R2 | A workaround or trade-off a reader would likely undo carries no reason | Judgement | `fail` only when you can name the change a reader would wrongly make | `standard`, severity `low` |
| R1 | A name hides or misstates what the thing is for | Judgement | `fail` when the name misleads | `smell`, Mysterious Name (review-standards' smell baseline) |
| R5 | A comment a newcomer cannot follow without project shorthand | Judgement | `fail` when the shorthand is undefined in the code | `standard`, severity `low` |

For a finding, quote this file and the rule id as the basis (`readable-code.md R4: "A comment never points at a decision record or a document."`) and the comment line from the diff. The fix is to delete the comment, rewrite it as the reason, or rename.

A lint rule in the profile toolchain that already catches a breach covers it: at 3.7 mark the line `tool-covered` with that rule; at 4.1 it is the toolchain's.

### Checking at 3.7

profile-mini-review adds these lines after the profile's checklist, quoted exactly:

- `readable-code R1: names say what each thing is for.`
- `readable-code R2: a workaround or trade-off a reader would undo says why.`
- `readable-code R3: no comment restates the code.`
- `readable-code R4: no comment references a decision record or document.`
- `readable-code R5: comments use plain English and plain technical terms.`
