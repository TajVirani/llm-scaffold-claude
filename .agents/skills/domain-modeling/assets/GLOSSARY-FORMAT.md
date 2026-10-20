# .workflow/GLOSSARY.md Format

## Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account

## Relationships

- An **Order** produces one or more **Invoices**
- An **Invoice** belongs to exactly one **Customer**

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User**: resolved, these are distinct concepts.
```

`## Relationships` and `## Flagged ambiguities` are optional. Add them when they have an entry. `## Retired` (see below) goes at the tail, only when it has an entry.

## Rules

- **Glossary only.** No implementation details: no file paths, class names, schemas, statuses, dates or decisions. A glossary is not a spec, a scratch pad or a decision record. Rationale goes in an ADR; schema goes in the feature's `data-model.md`.
- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Bold term names** in Relationships, and express cardinality where obvious.
- **Flag conflicts explicitly.** When a term was used ambiguously and the stakeholder settled it, record the resolution in one line under "Flagged ambiguities".
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.

## Changing an existing entry

- **Refine** a definition in place when the agreed meaning sharpens.
- **Fold** a dropped synonym into the surviving entry's `_Avoid_` line. Folding is not retiring: the concept still exists.
- **Retire** a concept the project no longer has to a one-line entry under `## Retired`: what it meant, and what removed or replaced it. Retire it only when readers will still meet the term in the project's own material; otherwise delete it.
- Change an entry only on positive evidence that agrees with the stakeholder. Missing code is not that evidence: an entry outlives the code that implements it.

## Single vs multi-context repos

**Single context (most repos):** One `.workflow/GLOSSARY.md` at the repo root.

**Multiple contexts:** A `.workflow/GLOSSARY-MAP.md` at the repo root lists the contexts, where they live, and how they relate to each other:

```md
# Glossary Map

## Contexts

- [Ordering](./src/ordering/GLOSSARY.md): receives and tracks customer orders
- [Billing](./src/billing/GLOSSARY.md): generates invoices and processes payments
- [Fulfillment](./src/fulfillment/GLOSSARY.md): manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

The skill infers which structure applies:

- If `.workflow/GLOSSARY-MAP.md` exists, read it to find contexts
- If only a root `.workflow/GLOSSARY.md` exists, single context
- If neither exists, create a root `.workflow/GLOSSARY.md` lazily when the first term is resolved

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask.
