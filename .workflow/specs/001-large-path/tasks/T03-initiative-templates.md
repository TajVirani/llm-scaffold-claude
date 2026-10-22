# T03: Templates admit initiatives

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The templates a large path needs. The spec template admits an optional `initiative: NNN-slug` key (an emitted spec names the initiative it came from) and its validator treats it like `origin`: optional, a string, rejected when not a string, and no existing spec is rejected. The design-log template gains the entry shapes the large path writes: Conversion, Origin from an initiative, Initiative round, Emission. The Phase 1 stubs `assets/initiative.md` and `assets/questions.md` become real templates: frontmatter with every field `data-model.md` gives the Initiative, Slice and Initiative question entities, a yq validator in the template comment that enforces the enums and the conditional-presence rules (`emitted` needs `spec`, `settled` needs a settled line, only `research` may be `researching`), and the body sections (`initiative.md`: the goal and the reference table of emitted specs; `questions.md`: none beyond the records).

**Seam:** The yq validators embedded in the four templates, run against a fixture file (the frontmatter oracle used by `tests/scripts/initiative-emission.sh` and `tests/fixtures/initiative.sh`).

**Acceptance criteria:**

- [ ] `assets/spec.md` documents `initiative:` beside `origin:` ("Add no other keys" is updated), and its validator accepts a spec with or without the key, rejects a non-string value, and still prints `true` for every spec template field as today (`tests/scripts/status-transition-check-write.sh` stays green).
- [ ] `assets/design-log.md` gives the shape of a Conversion entry (the spec converted, the initiative created, the number consumed), an Origin entry written into an emitted spec's log (the initiative, the slice, the binding decisions carried), an Initiative round entry (the frontier asked, answers, launches left `researching`), and an Emission entry in the initiative's log.
- [ ] `assets/initiative.md` holds `status`, `origin`, `created`, `branch`, `merge_pr`, `slices[]` (`id`, `title`, `status`, `questions`, `depends_on`, `spec`) with placeholder values, a validator that prints `true` for the template and exits non-zero for `emitted` with `spec: null`, `planned` with a non-null `spec`, a duplicate slice id or an unknown `depends_on`, and a body with the goal and the reference table.
- [ ] `assets/questions.md` holds `questions[]` (`id`, `kind`, `state`, `question`, `depends_on`, `launched`, `settled`) with a validator that refuses a `decision` in `researching`, `settled` with a null settled line, and a non-null settled line outside `settled`.
- [ ] The seeded-initiative fixture builder in `tests/fixtures/initiative.sh` still seeds from these templates and every template validator prints `true` on its output.

**Predicted files:** `.agents/skills/feature-workflow/assets/spec.md`, `.agents/skills/feature-workflow/assets/design-log.md`, `.agents/skills/feature-workflow/assets/initiative.md`, `.agents/skills/feature-workflow/assets/questions.md`.

**Phase 1 tests:** None owned. The validator case of JRN-003 in `tests/scripts/initiative-emission.sh` goes green with this task; the suite is owned by T4, which completes it.

**Size:** S (4 files, about 150 changed lines).

**Mode:** afk.

**Notes:** Carries migration M3 and the template half of M4. Field names and enums come from `data-model.md` (Initiative, Slice, Initiative question); the `--settled <text>` and `--launched <task_type>|clear` flags T4 implements read and write exactly these keys, so do not rename them. Templates are `assets/` files under the agent-docs profile; the validators follow the yq idioms of `assets/spec.md` and `assets/work-item.md`.
