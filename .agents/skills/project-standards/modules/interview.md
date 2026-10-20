<!--
Module of project-standards: step 4, interview.
Sources: first-party. Batches of at most eight, never ask what a scan answered, recall questions over review lists, show the evidence when the repo contradicts the user, and offer a non-obvious command as a candidate line adapted from bmad-code-org/BMAD-METHOD skills/bmad-project-context/SKILL.md@8f0d50e step 4 (MIT; pattern only). Coaching path by default, fast path with [ASSUMPTION] tags, show the alternatives for load-bearing calls, and the divergence test adapted from bmad-code-org/BMAD-METHOD skills/bmad-architecture/SKILL.md@8f0d50e (MIT; pattern only). The conflict-point categories adapted from bmad-code-org/BMAD-METHOD src/bmm-skills/3-solutioning/bmad-create-architecture/steps/step-05-patterns.md and step-06-structure.md@560a2e3a (MIT; pattern only). Mandatory coverage list (../assets/coverage.md) is first-party.
-->

# Interview

The interview is a **grill**: every item in [../assets/coverage.md](../assets/coverage.md) that applies gets an explicit answer from the human. Your recommendation speeds the answer up; it never replaces it.

## Path

- **Coaching** (the default, and the only path you start on): ask every applicable coverage item, as below.
- **Fast** only when the human explicitly asks for it in their own words ("fast path", "just draft it"). Never offer it as the first option and never choose it yourself. On the fast path you draft the rows with `A` evidence, and step 6 still blocks on every `A` row in a mandatory item until the human answers or delegates it, so the fast path moves the questions to the ledger, it does not remove them.

Record the path in the baseline header, with the human's words when it is `fast`.

## Ask

- Work through the coverage list in order (C1 per work type first, since later items depend on the libraries), in numbered batches of **at most eight**. Each question names the item id (`C1 backend: migrations`), your recommended answer, and the alternatives: for C1, the 2-3 verified candidates with their URLs; for C3, the drafted tree.
- A reply of "yes" or the number accepts the recommendation for that question only. A reply that skips a question leaves it open: ask it again in the next batch.
- "You choose" for an item, or for a whole group the human names, is a delegation: record it as `H delegated <date>` and say which choice you made.
- Push back where an answer leaves two builders free to diverge (two agents could pick incompatibly): ask the follow-up before moving on.
- Never ask what discovery, a config file or a manifest already answers; those rows carry `D` evidence. Asking the human to confirm a path-checked fact is a defect.
- A contradiction from discovery: show both citations and ask which one is the standard.
- After the coverage list, ask the recall questions once: "what do agents keep getting wrong here?", "which areas are off limits?". A command whose correct form is not the obvious guess (a required wrapper, a filter flag) is a candidate line: offer it.

Write each answer into its baseline row as you go, with `H human <date>` (or `H delegated <date>`) as its evidence.

Done when every applicable coverage item has a row whose evidence is `H`, and no open point is one a scan could answer. A batch that yields nothing new does not end the interview; an uncovered item does not either.
