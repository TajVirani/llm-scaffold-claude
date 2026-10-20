#!/usr/bin/env bash
# Suite: regenerate-caches scripts (publish-cache.sh, cache-stamp-check.sh).
# Covers: publishing and stamping Tier B caches, fresh/stale/missing/invalid classification, area filter, worktree use
#   of the main checkout (D18), front-matter stripping, and input rejections.
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

shellcheck_files "shellcheck: cache scripts" "$S"/*.sh
finish
