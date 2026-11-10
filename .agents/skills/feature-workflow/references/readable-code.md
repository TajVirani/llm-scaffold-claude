# Readable code and comments

This baseline applies to every line of code and test the workflow adds or changes, in every project. Projects do not opt in, and a profile cannot switch it off. A project's written standard can ask for more: a docstring on every public function, a licence header. A comment that standard requires is correct, not a finding.

## Rules

- **R1. Make the code explain itself.** Give each function, variable, type and test a name that says what it is for. When a step is hard to follow, extract it into a well-named function or variable before you reach for a comment.
- **R2. Comment only what the code cannot say.** A comment is a last resort. It gives the why: intent, context, the reasoning behind a choice, a necessary trade-off, a non-obvious workaround. A workaround or trade-off a later reader would likely undo gets that comment.
- **R3. Never restate the code.** `if user.age >= 18:` needs no comment. A comment that tells the reader what the next line does is noise.
- **R4. Keep the reason in the comment itself.** Write the reasoning as a sentence. A comment never points at a decision record or a document: no decision or ADR IDs (`ADR-0007`, `D12`), no paths to docs or workflow files (`docs/`, `.workflow/`, a spec, a task ID), no URLs to internal docs. Those references go stale, and the reader of the code cannot follow them. The decision record may link to the code; the code never links back. The `# File:` or `# Suite:` header block of a script is its interface doc and may name the paths the script reads or writes and what calls it; R4 governs body comments.
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

A name works the same way:

- Bad: `data = load(path)` then `for item in data: if item.ok: result.append(item)`. Every name is generic: the reader must trace the code to learn what `data`, `item` and `result` hold (R1).
- Good: `invoices = load(path)` then `for invoice in invoices: if invoice.paid: paid_invoices.append(invoice)`. Each name says what it holds, so no comment is needed (R1).

## Checking

Four checks apply these rules:

- **Self-review (3.4).** The implementer walks the lines in [Checking at 3.7](#checking-at-37) over its own diff and records a verdict for each.
- **Comment lint (3.5).** `check-comments.sh`, in the shell and test profiles' `lint` key, catches the R4 ids and workflow paths in shell comments.
- **Mini-review (3.7).** profile-mini-review judges the same lines on every task, as the one independent reader before the merge, and gives each breach its exact fix, which the orchestrator applies itself.
- **Standards lens (4.1)**, or the combined review (4.10) on the light path, grades each breach as the table says.

Judge only the comments and names the diff adds or changes. What counts as a breach:

- **A comment that says what the next line or block does is a breach (R3), even when it is accurate.** A comment earns its place only by explaining a process or a reason a reader could not infer from the code: why this approach, what would break without it, what the surrounding system expects.
- **A generic name is a breach (R1)** when a name that says what the thing holds or does is available: `data`, `result`, `tmp`, `item`, `info`, `handler`, `obj`, `value`, `manager`, or a single letter. A single letter is fine as a short loop index (`i`), in a conventional math use (`x`, `y`) or as a conventional callback argument (`e` for an event, `_` for an unused one).
- **A comment that gives a reason is correct: never flag a comment for existing.** A comment a project standard requires (a docstring, a licence header) is correct too: the standard wins over R2 and R3.

| Rule | Breach | Kind | At 3.7 | At 4.1 and 4.10 |
| --- | --- | --- | --- | --- |
| R4 | A comment names a decision or ADR ID, a doc or workflow path, a spec or task ID, or an internal doc URL | Hard rule: the line matches or it does not | `fail`; fix: delete, or replace with the reason | `standard`, severity `medium`, confidence 100 |
| R3 | A comment says what the line or block below it does | Judgement | `fail` when the comment says nothing the code does not; fix: delete | `standard`, severity `low`, confidence 80+; always routed to patch |
| R2 | A workaround or trade-off a reader would likely undo carries no reason | Judgement | `fail` only when you can name the change a reader would wrongly make; fix: insert the reason | `standard`, severity `low` |
| R1 | A name is generic, or hides or misstates what the thing is for | Judgement | `fail` when the name misleads or is generic where a telling name is available; fix: the new name at every place it is used | `standard`, severity `low`, confidence 80+; always routed to patch |
| R5 | A comment a newcomer cannot follow without project shorthand | Judgement | `fail` when the shorthand is undefined in the code; fix: replace with plain words | `standard`, severity `low` |

For a finding, quote this file and the rule id as the basis (`readable-code.md R4: "A comment never points at a decision record or a document."`) and the comment or name from the diff. The fix is to delete the comment, rewrite it as the reason, or rename. A breach of R1 or R3 is small to fix and is the breach agents make most, so at 4.4 it is never dismissed as noise or left open for being `low`: it is always patched.

A lint rule in the profile toolchain that already catches a breach covers it: at 3.7 mark the line `tool-covered` with that rule; at 4.1 it is the toolchain's.

### Checking at 3.7

The implementer's self-review and profile-mini-review check these lines after the profile's checklist and report each by its number (R1 to R5) with a verdict, without quoting it:

- `readable-code R1: names say what each thing is for.`
- `readable-code R2: a workaround or trade-off a reader would undo says why.`
- `readable-code R3: no comment restates the code.`
- `readable-code R4: no comment references a decision record or document.`
- `readable-code R5: comments use plain English and plain technical terms.`
