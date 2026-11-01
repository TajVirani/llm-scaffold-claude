#!/usr/bin/env bash
# Suite: JRN-002 "This repo's architecture cache drops the false entries": build-architecture.sh --cache architecture run on
#   a copy of this repo's working tree (the published cache's scope, rules.md and work profiles; tracked and untracked
#   files, ignored ones left out) committed into a scratch repo, so the run never writes to the repo.
# Covers: Unresolved edges has no entry for the `case` patterns at install.sh:133 and install.sh:187, and keeps every
#   other entry of the cache published stamped e530f63 except the paths quoted in multi-line strings (matched on file and
#   source text, so a line that moved still counts). CAP-005.
# shellcheck disable=SC2016  # literal Markdown backticks in single quotes
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/architecture-oracle.sh
source "$TESTS_DIR/fixtures/architecture-oracle.sh"
preflight

new_workdir
COPY="$WORK/repo"
git_init_repo "$COPY"
SCOPES=()
while IFS= read -r p; do SCOPES+=("$p"); done < <(architecture_oracle_scopes)

# Copy what the build reads from the working tree as it is now, so a run before the change is committed tests the change.
git -C "$REPO_ROOT" ls-files -z -co --exclude-standard -- "${SCOPES[@]}" .workflow/rules.md .workflow/profiles .workflow/tools \
  | while IFS= read -r -d '' f; do [ -f "$REPO_ROOT/$f" ] && printf '%s\0' "$f"; done >"$WORK/files.list"
tar -C "$REPO_ROOT" --null -T "$WORK/files.list" -cf - | tar -C "$COPY" -xf -
git_commit_all "$COPY" "copy of the working tree"
B="$COPY/.agents/skills/regenerate-caches/scripts/build-architecture.sh"

scope_args=()
for p in "${SCOPES[@]}"; do scope_args+=(--scope "$p"); done
arch=$(cd "$COPY" && "$B" --cache architecture "${scope_args[@]}" --root "$COPY" 2>"$WORK/build.err"); rc=$?
eq "JRN-002 the architecture build of this repo exits 0" "$rc" 0
unresolved=$(printf '%s\n' "$arch" | awk '/^## /{ on = ($0 == "## Unresolved edges"); next } on && /^- /')
check "JRN-002 the architecture body has Unresolved edges entries" '[ -n "$unresolved" ]' "$(cat "$WORK/build.err")"

# file_and_text : drop the line number from "- `<file>:<line>` `<text>`" bullets, so an entry whose line moved still matches.
file_and_text() { sed -E 's/^- `([^`]*):[0-9]+` /- `\1` /' | LC_ALL=C sort -u; }

eq "JRN-002 Unresolved edges has no install.sh:133 or install.sh:187 entry" \
  "$(printf '%s\n' "$unresolved" | grep -E '^- `install\.sh:(133|187)`')" ""
eq "JRN-002 no install.sh case pattern is listed as a call" \
  "$(printf '%s\n' "$unresolved" | grep -F '`../*`' | grep -F '`install.sh:')" ""
missing=$(LC_ALL=C comm -23 <(architecture_unresolved_oracle | file_and_text) <(printf '%s\n' "$unresolved" | file_and_text))
eq "JRN-002 every other published unresolved edge is still listed" "$missing" ""

shellcheck_files "shellcheck: build-architecture.sh, extractors/bash.sh" "$B" "$COPY/.agents/skills/regenerate-caches/scripts/extractors/bash.sh"
finish
