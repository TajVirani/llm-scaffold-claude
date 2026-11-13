# Data model: Per-run session handoffs

Spec: [spec.md](spec.md) · Placement: `standalone-skills` (handoff skill) and `hooks` (session-start offer), design-log Assumed entry of 2026-11-12

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Session handoff location | field | refactor | standalone-skills |
| Session handoff file name | field | refactor | standalone-skills |
| Handoff folder `.gitignore` | entity | create | standalone-skills |
| Handoff skill Resume | interface | extend | standalone-skills |
| Session-start offer, handoff list | interface | extend | hooks |
| Handoff frontmatter and body | entity | unchanged | standalone-skills |
| `WF_HANDOFF` | interface | unchanged | lib |
| install.sh ignore block, repo `.gitignore` | interface | unchanged | installer |

## Entities

### Session handoff (refactor)

One local, uncommitted file that a fresh session reads to carry on the work of a session that ended or reset its context.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| Folder | path | yes | `<checkout>/.workflow/.handoff/`, where `<checkout>` is the top level of the checkout the writing session works in, or `$PWD` outside git (CAP-NEW-per-run-handoffs, D5) | refactor |
| File name | string | yes | `<NNN-slug \| topic>--<YYYYMMDDTHHMMSSZ>-<4 chars of [a-z0-9]>.md`; never an existing file (D6) | refactor |
| Frontmatter (`goal`, `spec`, `step_at_handoff`, `main_sha`, `affected_paths`, `created`) | YAML | yes | as today | unchanged |
| Body sections | markdown | yes | as today | unchanged |

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| none | a session hands off | written | the name is new in the folder |
| written | a session resumes from it | resumed | named by path, or picked from the offer |
| resumed | the resuming session writes its own handoff, or finishes the work | deleted | only the session that resumed it deletes it |
| written | the spec worktree it sits in is removed | deleted | none |

**Invalid states ruled out:** two runs sharing one file (each name carries its own timestamp and random suffix); a handoff tracked by git (the folder's own `.gitignore` ignores everything in it). Still representable: a handoff nobody resumes stays until a human deletes it; a handoff under an old name (`<NNN-slug | topic>.md`) in a main checkout stays valid and is listed and resumed like any other.

### Handoff folder `.gitignore` (create)

A file `.workflow/.handoff/.gitignore` whose one line is `*`, so git ignores the folder and the file itself in any install. The handoff skill writes it whenever the file is missing. It is not a session handoff and is never listed in the offer.

## Migrations

None. Old handoffs stay where they are and remain readable.
