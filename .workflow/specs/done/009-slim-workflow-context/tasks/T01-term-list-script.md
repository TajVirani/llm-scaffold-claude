# T01: Term-list script

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: T3

**What to build:** A session can see every workflow term and the words to avoid without reading the whole glossary. `.agents/skills/domain-modeling/scripts/term-list.sh` (today an interface stub) prints one line per glossary entry with its `_Avoid_` aliases from the root `.workflow/GLOSSARY.md`, or from every glossary a `.workflow/GLOSSARY-MAP.md` names, each line labelled with its context; `--define <term>` prints exactly that one whole entry, and an unknown term exits non-zero (D5, D12). Entry and alias syntax comes from `.agents/skills/domain-modeling/assets/GLOSSARY-FORMAT.md`.

**Seam:** the script's command line, `term-list.sh [--define <term>]`, driven by `tests/scripts/term-list.sh` on fixture glossaries built at run time.

**Acceptance criteria:**

- [ ] `tests/run-all.sh --suite scripts/term-list` passes.
- [ ] Bash 3.2, shellcheck-clean, header per the shell-scripts profile; it sources nothing from `.agents/lib/` (domain-modeling may depend only on feature-workflow).
- [ ] Run on this repo's `.workflow/GLOSSARY.md`, it prints one line per entry (43 today).
- [ ] `PROVENANCE.md` names `skills/domain-modeling/scripts/term-list.sh`.

**Predicted files:** `.agents/skills/domain-modeling/scripts/term-list.sh`, `PROVENANCE.md`

**Phase 1 tests:** `tests/scripts/term-list.sh`

**Size:** S (2 files, about 120 changed lines).

**Mode:** afk.

**Notes:** Shares `PROVENANCE.md` with T3 under an approved `parallel_with`: each adds its own rows, merged in id order. The domain-modeling `SKILL.md` and its term gates keep reading the glossary whole (D11); do not change them.
