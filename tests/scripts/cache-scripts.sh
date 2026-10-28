#!/usr/bin/env bash
# Suite: regenerate-caches scripts (publish-cache.sh, cache-stamp-check.sh, the Mermaid check of check-staged-cache.sh).
# Covers: publishing and stamping Tier B caches, fresh/stale/missing/invalid classification, area filter, worktree use
#   of the main checkout, front-matter stripping, and input rejections. JRN-007: the cache-regeneration agent names no skill
#   path outside regenerate-caches; check-staged-cache.sh flows runs validate_mermaid.mjs when node, mermaid and jsdom are
#   present (a node stand-in on PATH, stub packages), and otherwise still prints ok with exit 0 and says on stderr that the
#   body is not machine-validated, naming the hand checklist; exit codes 1 and 2 unchanged.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and read their variables through eval; literal Markdown backticks
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
S="$WORK/scaffold/.agents/skills/regenerate-caches/scripts"
B=$WORK
git_init_repo "$B/repo"
cd "$B/repo" || exit 1
mkdir -p src/a src/b .workflow/.cache-staging
echo 1 >src/a/x
echo 1 >src/b/y
git_commit_all "$B/repo" init
for ty in modules flows architecture; do echo "# $ty" > ".workflow/.cache-staging/$ty.md"; done
t pub-modules 0 "$S/publish-cache.sh" .workflow/.cache-staging/modules.md modules src/a
t pub-flows 0 "$S/publish-cache.sh" .workflow/.cache-staging/flows.md flows src/b
t pub-arch 0 "$S/publish-cache.sh" .workflow/.cache-staging/architecture.md architecture src/a src/b --generator dc
eq pub-removed-staged "$(find .workflow/.cache-staging -type f | wc -l | tr -d ' ')" 0
eq pub-sha "$(yq --front-matter=extract .generated_at_commit .workflow/cache/modules.md)" "$(git rev-parse HEAD)"
git_commit_all "$B/repo" caches
out=$("$S/cache-stamp-check.sh"); rc=$?
eq fresh-rc "$rc" 0
eq fresh-status "$(jq -r '[.caches[].status]|join(",")' <<<"$out")" fresh,fresh,fresh
eq stamps-sha "$(jq -r '.stamps.modules' <<<"$out")" "$(yq --front-matter=extract .generated_at_commit .workflow/cache/modules.md)"
echo x >src/b/z
git_commit_all "$B/repo" b
out=$("$S/cache-stamp-check.sh"); rc=$?
eq stale-rc "$rc" 1
eq stale-status "$(jq -r '[.caches[].status]|join(",")' <<<"$out")" fresh,stale,stale
eq stale-paths "$(jq -r '.caches[1].stale_paths[0]' <<<"$out")" src/b/z
"$S/cache-stamp-check.sh" --area src/a >/dev/null
eq area-rc "$?" 0
git commit -q --allow-empty -m e
echo q >README
git_commit_all "$B/repo" readme
out=$("$S/cache-stamp-check.sh" --area src/a)
eq unrelated-fresh "$(jq -r '[.caches[].status]|join(",")' <<<"$out")" fresh,fresh,fresh
# worktree: stale-check and publish from a worktree use the main checkout
git worktree add -q ../wt -b wtb
(cd ../wt && echo w >src/a/w && git add -A && git commit -qm wt-commit)
mainhead=$(git rev-parse HEAD)
out=$(cd ../wt && "$S/cache-stamp-check.sh")
eq wt-check-head "$(jq -r .head <<<"$out")" "$mainhead"
eq wt-check-reads-main "$(jq -r '.caches[0].status' <<<"$out")" fresh
echo body > .workflow/.cache-staging/modules.md
(cd ../wt && "$S/publish-cache.sh" "$B/repo/.workflow/.cache-staging/modules.md" modules src/a >/dev/null)
eq wt-pub-rc "$?" 0
eq wt-pub-sha "$(yq --front-matter=extract .generated_at_commit .workflow/cache/modules.md)" "$mainhead"
eq wt-no-local-write "$(git -C ../wt status --porcelain | wc -l | tr -d ' ')" 0
# invalid: unquoted timestamp
cp .workflow/cache/flows.md "$B/flows.bak"
sed -i.bak 's/^generated_at: "\(.*\)"/generated_at: \1/' .workflow/cache/flows.md
rm -f .workflow/cache/flows.md.bak
out=$("$S/cache-stamp-check.sh"); rc=$?
eq invalid-rc "$rc" 2
eq invalid-status "$(jq -r '.caches[1].status' <<<"$out")" invalid
eq invalid-stamp-null "$(jq -r '.stamps.flows' <<<"$out")" null
cp "$B/flows.bak" .workflow/cache/flows.md
# invalid: sha not in repo
sed -i.bak 's/^generated_at_commit: .*/generated_at_commit: 0123456789abcdef0123456789abcdef01234567/' .workflow/cache/flows.md
rm -f .workflow/cache/flows.md.bak
out=$("$S/cache-stamp-check.sh"); rc=$?
eq unknown-sha-rc "$rc" 2
eq unknown-sha-status "$(jq -r '.caches[1].status' <<<"$out")" invalid
eq unknown-sha-reason "$(jq -r '.caches[1].reason' <<<"$out" | grep -c 'not a commit')" 1
cp "$B/flows.bak" .workflow/cache/flows.md
# missing
mv .workflow/cache/architecture.md "$B/arch.bak"
out=$("$S/cache-stamp-check.sh")
eq missing-status "$(jq -r '.caches[2].status' <<<"$out")" missing
eq missing-stamp-null "$(jq -r '.stamps.architecture' <<<"$out")" null
mv "$B/arch.bak" .workflow/cache/architecture.md
# publish rejections
: > .workflow/.cache-staging/modules.md
t rej-empty 1 "$S/publish-cache.sh" .workflow/.cache-staging/modules.md modules src/a
t rej-missing 1 "$S/publish-cache.sh" .workflow/.cache-staging/nope.md modules src/a
echo b > outside.md
t rej-outside 1 "$S/publish-cache.sh" outside.md modules src/a
echo b > .workflow/.cache-staging/modules.md
t rej-glob 2 "$S/publish-cache.sh" .workflow/.cache-staging/modules.md modules 'src/*'
t rej-type 2 "$S/publish-cache.sh" .workflow/.cache-staging/modules.md bogus src/a
printf -- '---\nfoo: bar\n---\nreal\n' > .workflow/.cache-staging/modules.md
t fm-strip 0 "$S/publish-cache.sh" .workflow/.cache-staging/modules.md modules src/a
eq fm-strip-body "$(tail -1 .workflow/cache/modules.md)" real
eq fm-no-foo "$(grep -c foo .workflow/cache/modules.md)" 0
eq no-tmp-left "$(find .workflow/cache -name '.*' -type f | wc -l | tr -d ' ')" 0

echo "== JRN-007 cache-regeneration stays inside its ownership"
eq "JRN-007 cache-regeneration.md names no skill path outside regenerate-caches" \
  "$(grep -o 'skills/[A-Za-z0-9_.-]*' "$WORK/scaffold/.agents/agents/cache-regeneration.md" | LC_ALL=C sort -u)" "skills/regenerate-caches"

echo "== JRN-007 check-staged-cache.sh runs the Mermaid validator when it can"
# The project holds its own .agents/ and node_modules/ at the root, so the validator script, the working directory and
# the checkout root all lead to the same node_modules/.
M="$WORK/mermaid"
git_init_repo "$M"
copy_agents "$M"
mkdir -p "$M/.workflow/.cache-staging" "$M/node-bin"
cat >"$M/.workflow/.cache-staging/flows.md" <<'EOF'
# Flows

## Entry points

- `src/cli/main.ts`

## src/cli/main.ts

```mermaid
sequenceDiagram
  participant src_cli as src/cli
  participant src_billing as src/billing
  src_cli->>src_billing: charge()
```

Error branches:
- none
EOF
cat >"$M/node-bin/node" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$WORK/node.log"
echo "all diagrams parse"
EOF
chmod +x "$M/node-bin/node"
MC="$M/.agents/skills/regenerate-caches/scripts/check-staged-cache.sh"
CHECKLIST=visual-change-report/references/visual-library.md
git_commit_all "$M" init
# path_without_node : PATH with every node hidden: a PATH folder holding one is replaced by links to its other programs.
path_without_node() {
  local dir out="" n=0 f mirror
  local IFS=:
  for dir in $PATH; do
    if [ -x "$dir/node" ]; then
      n=$((n + 1))
      mirror="$WORK/no-node/$n"
      mkdir -p "$mirror"
      for f in "$dir"/*; do [ "${f##*/}" = node ] || ln -s "$f" "$mirror/${f##*/}"; done
      dir=$mirror
    fi
    out="${out:+$out:}$dir"
  done
  printf '%s\n' "$out"
}
NO_NODE_PATH=$(path_without_node)
# staged_flows PATH : run check-staged-cache.sh flows on the staged body from the project root with that PATH; stdout to
#   $WORK/mc.out, stderr to $WORK/mc.err, exit code to $WORK/mc.rc.
staged_flows() {
  (cd "$M" && PATH=$1 "$MC" flows .workflow/.cache-staging/flows.md >"$WORK/mc.out" 2>"$WORK/mc.err")
  echo $? >"$WORK/mc.rc"
}
# not_validated LABEL : the run printed ok, exited 0 and named the hand checklist on stderr.
not_validated() {
  eq "JRN-007 $1: ok on stdout" "$(cat "$WORK/mc.out")" ok
  eq "JRN-007 $1: exit 0" "$(cat "$WORK/mc.rc")" 0
  check "JRN-007 $1: stderr says not machine-validated and names the checklist" \
    'grep -q "not machine-validated" "$WORK/mc.err" && grep -qF "$CHECKLIST" "$WORK/mc.err"' "$(cat "$WORK/mc.err")"
}

: >"$WORK/node.log"
staged_flows "$M/node-bin:$PATH"
not_validated "node on PATH, mermaid and jsdom absent"
check "JRN-007 without the packages the validator is not run" '! grep -q validate_mermaid "$WORK/node.log"' "$(cat "$WORK/node.log")"

mkdir -p "$M/node_modules/mermaid" "$M/node_modules/jsdom"
printf '{"name":"mermaid","version":"11.0.0"}\n' >"$M/node_modules/mermaid/package.json"
printf '{"name":"jsdom","version":"24.0.0"}\n' >"$M/node_modules/jsdom/package.json"
if PATH=$NO_NODE_PATH command -v node >/dev/null 2>&1; then
  skip "JRN-007 node absent" "node could not be hidden from PATH"
else
  staged_flows "$NO_NODE_PATH"
  not_validated "mermaid and jsdom present, node absent"
fi

: >"$WORK/node.log"
staged_flows "$M/node-bin:$PATH"
eq "JRN-007 validator present: ok on stdout" "$(cat "$WORK/mc.out")" ok
eq "JRN-007 validator present: exit 0" "$(cat "$WORK/mc.rc")" 0
check "JRN-007 validator present: node runs validate_mermaid.mjs" 'grep -q "validate_mermaid\.mjs" "$WORK/node.log"' \
  "$(cat "$WORK/node.log" "$WORK/mc.err")"
check "JRN-007 validator present: stderr does not say not machine-validated" '! grep -q "not machine-validated" "$WORK/mc.err"' \
  "$(cat "$WORK/mc.err")"
printf '# Flows\n\n## Entry points\n\n- `b`\n- `a`\n' >"$M/.workflow/.cache-staging/bad-flows.md"
t "JRN-007 validator present: a body with problems still exits 1" 1 env PATH="$M/node-bin:$PATH" "$MC" flows "$M/.workflow/.cache-staging/bad-flows.md"
t "JRN-007 validator present: a usage error still exits 2" 2 env PATH="$M/node-bin:$PATH" "$MC" flows

mkdir -p "$M/rejecting-node-bin"
cat >"$M/rejecting-node-bin/node" <<'EOF'
#!/usr/bin/env bash
echo "diagram 1: FAIL — Parse error on line 3"
echo "1 FAILURES"
exit 1
EOF
chmod +x "$M/rejecting-node-bin/node"
staged_flows "$M/rejecting-node-bin:$PATH"
eq "JRN-007 validator rejects a diagram: exit 1" "$(cat "$WORK/mc.rc")" 1
eq "JRN-007 validator rejects a diagram: no ok on stdout" "$(cat "$WORK/mc.out")" ""
check "JRN-007 validator rejects a diagram: its error is on stderr" 'grep -q "diagram 1: FAIL" "$WORK/mc.err"' \
  "$(cat "$WORK/mc.err")"

mkdir -p "$WORK/validator-tmp"
TMPDIR="$WORK/validator-tmp" staged_flows "$M/node-bin:$PATH"
TMPDIR="$WORK/validator-tmp" staged_flows "$M/rejecting-node-bin:$PATH"
eq "JRN-007 the validator's temporary HTML is removed after a pass and a rejection" \
  "$(find "$WORK/validator-tmp" -type f | wc -l | tr -d ' ')" 0

shellcheck_files "shellcheck: cache scripts" "$S"/*.sh
finish
