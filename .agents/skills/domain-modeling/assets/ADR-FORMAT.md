<!--
File: ADR format and the three-part ADR test for the first-party `domain-modeling` skill (D10). Used at 0.3.5-0.3.7; read by review-standards (4.1) and retrieval (0.2.4).
Sources: copied from mattpocock/skills skills/engineering/domain-modeling/ADR-FORMAT.md (MIT, Copyright (c) 2026 Matt Pocock; commit 49dd158; notice in ../LICENSE). Changes: `docs/adr/` -> `docs/decisions/adr/` (plan 00.4); the template now lives in adr.md; the Status frontmatter is written as a `status:` key; added the optional Deferred section (D80); added "Superseding an ADR" (plan 00.4 "Superseded ADRs stay, marked"; lifecycle and supersede back-link pattern from wshobson/agents plugins/documentation-generation/skills/architecture-decision-records/SKILL.md, MIT, pattern only).
-->

# ADR Format

ADRs live in `docs/decisions/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.

Create the `docs/decisions/adr/` directory lazily: only when the first ADR is needed.

## Template

Start from [adr.md](./adr.md). The required part is:

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why*, not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most ADRs won't need them.

- **Status** frontmatter (`status: proposed | accepted | deprecated | superseded by ADR-NNNN`): useful when decisions are revisited
- **Considered Options**: only when the rejected alternatives are worth remembering
- **Consequences**: only when non-obvious downstream effects need to be called out
- **Deferred**: decisions knowingly left open, each with its reason; used by the `project-standards` baseline ADR (`0001-project-baseline`, D80)

## Numbering

Scan `docs/decisions/adr/` for the highest existing number and increment by one.

## Superseding an ADR

A superseded ADR stays in place, marked. It is the record of what was decided before.

1. Write the new decision as a new ADR with the next number. Its body says which ADR it replaces and why: `Supersedes [ADR-NNNN](./NNNN-slug.md).`
2. In the old ADR, set the frontmatter to `status: superseded by ADR-MMMM`, where MMMM is the new ADR. Add the frontmatter if the old ADR has none.
3. Leave the old ADR's body unchanged. To change a decision, write a new ADR.

Use `status: deprecated` for a decision that no longer applies and that nothing replaces.

## When to offer an ADR

All three of these must be true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it: you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library: just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it; otherwise someone will suggest GraphQL again in six months.
