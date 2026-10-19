<!--
Module of project-standards: step 4, interview the gaps.
Sources: first-party. Batches of at most eight, never ask what a scan answered, recall questions over review lists, show the evidence when the repo contradicts the user, and offer a non-obvious command as a candidate line adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/SKILL.md@8f0d50e step 4 (MIT; pattern only). Coaching path by default, fast path with [ASSUMPTION] tags, show the alternatives for load-bearing calls, and the divergence test adapted from bmad-code-org/BMAD-METHOD skills/bmad-architecture/SKILL.md@8f0d50e (MIT; pattern only). The conflict-point categories adapted from bmad-code-org/BMAD-METHOD src/bmm-skills/3-solutioning/bmad-create-architecture/steps/step-05-patterns.md and step-06-structure.md@560a2e3a (MIT; pattern only).
-->

# Interview the gaps

## Pick the path

Offer the choice before asking anything:

- **Coaching path** (default): ask each open point, lead with your recommended answer and the alternative you weighed, and push back where an answer leaves two builders free to diverge.
- **Fast path** (on request): draft every open point yourself, tag each drafted row `[ASSUMPTION]` in its Evidence cell, and let the human correct the rows at step 6.

Load-bearing calls (paradigm, starter, the major module boundaries) are shown on both paths: name the realistic alternatives and why you lean one way, then let the human choose.

## The question set

A point is open when discovery, the manifests and step 2 left it unsettled. For each category, ask: **could two agents building separately choose incompatibly here?** Ask only where the answer is yes and the choice is not obvious. Otherwise it is either settled by the ecosystem default (no line) or a `Deferred` row.

| Category | Conflict points |
| --- | --- |
| Stack and core decisions | paradigm; starter; data store; ID scheme; migrations; caching; auth flow and session; secrets handling; deployment target |
| Naming | database tables, columns, foreign keys, indexes; API endpoints, route and query params; code identifiers, services, error types; file names; test files |
| Structure | where tests live; by-feature or by-type organisation; where shared code goes and when it is promoted; config, env and asset locations |
| Boundaries | module ownership and allowed dependencies; shared core; layering inside a module (for example route → service → repository); type-only imports across workspaces; data access paths |
| Format | response envelope; error shape and codes; date and time format; JSON field casing; list and pagination shape |
| Communication | event or message naming and payload shape; state update pattern; logging format and levels |
| Process | error handling and recovery; retry policy; loading state; validation timing; required ordering (what must exist before what) |
| Libraries | the one library per concern (HTTP client, validation, server state, UI state, dates, styling) and the alternatives to forbid |
| Versions | runtime and tool versions, from the files that declare them |
| Deferred | what this baseline deliberately does not decide yet, each with the reason it can wait |

## Ask

- Batches of **at most eight** questions; fewer is better. Number them. Each states your recommended answer, so "yes" or the number accepts it.
- Never ask what discovery, a config file or a manifest already answers. Asking the human to confirm a path-checked fact is a defect.
- Ask recall questions ("what do agents keep getting wrong here?", "which areas are off limits?"), not review lists of scan output.
- A contradiction from discovery: show both citations and ask which one is the standard.
- A command whose correct form is not the obvious guess (a required wrapper, a filter flag) is a candidate line: offer it.
- A batch that yields nothing new ends the interview.

Write each answer into its baseline row as you go, with `human <date>` as its evidence.

Done when every category above has its points decided, deferred with a reason, or left open by the human's choice, and no open point is one a scan could answer.
