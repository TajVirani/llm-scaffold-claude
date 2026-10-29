# JRN-008: caches published after the change

Run 2026-10-28 at commit 99801e5 (regenerate-caches, full mode, all three caches, scope = the published scope list).

- `check-staged-cache.sh` printed `ok` for modules, flows and architecture: [check-staged.txt](check-staged.txt). Mermaid was checked by hand (node cannot load mermaid and jsdom here).
- Published with `publish-cache.sh`; `cache-stamp-check.sh` reports all three `fresh`: [stamp-check.txt](stamp-check.txt).
- Architecture cache: no `install.sh:133` or `install.sh:187` entry; Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (bash).`
- Oracle comparison ([oracle-diff.txt](oracle-diff.txt), oracle 236 entries, published 251): every difference is a line shift in a file this spec changed, or a real call in a test file this spec added, except one:
  - `tests/scripts/extractor-bash.sh:205` `./x`: the text is on the second line of a multi-line single-quoted jq program, not a call. The extractor does not track single quotes across lines. Pre-existing extractor behaviour, not caused by the `case` fix; known gap, offered as backlog at 5.5.
