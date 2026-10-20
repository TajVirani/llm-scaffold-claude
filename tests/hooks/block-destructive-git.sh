#!/usr/bin/env bash
# Suite: hooks/block-destructive-git.sh (PreToolUse Bash, Claude and Codex): denies destructive git commands by parsing
#   the command into simple commands, so text that is only data is not matched.
# Covers: every blocked form (stash, reset --hard, checkout discard forms, switch --discard-changes, restore, clean,
#   push force/lease/delete/mirror/prune and +/: refspecs, branch -D and delete+force, rebase, filter-branch/-repo,
#   reflog expire/delete); detection through separators, subshells, wrappers (sudo, env, xargs, timeout), VAR= prefixes,
#   git global options, $(...), backquotes, sh -c, eval and a heredoc or here-string fed to a shell; allowed forms
#   (read-only git, plain push, branch -d, checkout <branch>, clean -n, stash list/show) and data that only mentions a
#   blocked command (heredoc bodies, quoted arguments, commit messages, comments, redirect targets); deny JSON shape;
#   Codex argv-array command; silence on empty input or no command; fail closed when the tokenizer cannot run; shellcheck.
# Policy notes: --force-with-lease is blocked (a lease still rewrites the remote branch; ask the user). Plain `git push`
#   is allowed (glab and the PR flow push branches), unlike the mattpocock/skills git-guardrails upstream. Every rebase is
#   blocked, not only rebases of shared branches, because the hook cannot tell which branches are shared.
# shellcheck disable=SC2016,SC2034  # check expressions (and the variables they read) are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/proj"
HOOK=$WORK/proj/.agents/hooks/block-destructive-git.sh
TEST_BASH=${TEST_BASH:-bash}

# run CMD : feed a Claude PreToolUse Bash payload; sets out and rc.
run() {
  out=$(jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c},hook_event_name:"PreToolUse",cwd:"/x"}' | "$TEST_BASH" "$HOOK" 2>&1)
  rc=$?
}
blocked() { # blocked CMD [REASON_SUBSTRING]
  run "$1"
  want=${2:-}
  check "blocked: $(printf '%s' "$1" | tr '\n' '|')" \
    '[ $rc -eq 0 ] && [ "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out" 2>/dev/null)" = deny ] && { [ -z "$want" ] || jq -r .hookSpecificOutput.permissionDecisionReason <<<"$out" | grep -qF -- "$want"; }' \
    "rc=$rc out=$out"
}
allowed() { # allowed CMD
  run "$1"
  check "allowed: $(printf '%s' "$1" | tr '\n' '|')" '[ $rc -eq 0 ] && [ -z "$out" ]' "rc=$rc out=$out"
}

echo "== blocked forms"
blocked 'git stash' 'git stash'
blocked 'git stash pop' 'git stash pop'
blocked 'git stash drop stash@{0}'
blocked 'git stash push -m wip'
blocked 'git stash apply'
blocked 'git stash clear'
blocked 'git reset --hard' 'git reset --hard'
blocked 'git reset --hard HEAD~1'
blocked 'git reset -q --hard origin/main'
blocked 'git checkout .' 'git checkout .'
blocked 'git checkout -- .' 'git checkout -- <paths>'
blocked 'git checkout -- src/a.ts'
blocked 'git checkout HEAD -- src/a.ts'
blocked 'git checkout ./src'
blocked 'git checkout -f main' 'git checkout -f'
blocked 'git checkout --force main'
blocked 'git switch --discard-changes main' 'git switch --discard-changes'
blocked 'git switch -f main'
blocked 'git restore .' 'git restore'
blocked 'git restore --staged a.txt'
blocked 'git restore --source=HEAD~1 a.txt'
blocked 'git clean -f' 'git clean'
blocked 'git clean -fd'
blocked 'git clean -fdx'
blocked 'git clean -xdf'
blocked 'git clean --force -d'
blocked 'git -c clean.requireForce=false clean'
blocked 'git push --force' 'git push --force'
blocked 'git push -f origin main' 'git push -f'
blocked 'git push origin main --force'
blocked 'git push -uf origin main'
blocked 'git push --force-with-lease' 'git push --force-with-lease'
blocked 'git push --force-with-lease=main:abc123 origin main'
blocked 'git push --force-if-includes --force-with-lease'
blocked 'git push origin +main' 'force refspec'
blocked 'git push origin +HEAD:refs/heads/main'
blocked 'git push origin :old-branch' 'delete refspec'
blocked 'git push --delete origin old-branch' 'git push --delete'
blocked 'git push -d origin old-branch'
blocked 'git push --mirror backup'
blocked 'git push --prune origin'
blocked 'git branch -D feature' 'git branch -D'
blocked 'git branch -d -f feature' 'force delete'
blocked 'git branch --delete --force feature'
blocked 'git branch -df feature'
blocked 'git branch -fd feature'
blocked 'git rebase main' 'git rebase'
blocked 'git rebase -i HEAD~3'
blocked 'git rebase --continue'
blocked 'git pull --rebase=false && git rebase origin/main'
blocked 'git filter-branch --tree-filter "rm x" HEAD' 'git filter-branch'
blocked 'git filter-repo --path secrets --invert-paths' 'git filter-repo'
blocked 'git reflog expire --expire=now --all' 'git reflog expire'
blocked 'git reflog delete HEAD@{1}' 'git reflog delete'

echo "== found inside compound and nested commands"
blocked 'git status && git reset --hard'
blocked 'git fetch; git reset --hard origin/main'
blocked 'false || git push -f'
blocked 'git log | head; git clean -fd'
blocked 'echo start & git stash'
blocked '(cd sub && git reset --hard)'
blocked $'git status\ngit reset --hard'
blocked $'git status \\\n  && git reset --hard'
blocked 'if true; then git rebase main; fi'
blocked '{ git stash; }'
blocked '! git push --force'
blocked 'sudo git reset --hard'
blocked 'sudo -u deploy git push -f'
blocked 'env -u FOO GIT_DIR=.git git reset --hard'
blocked 'GIT_TRACE=1 git push --force'
blocked 'command git clean -fd'
blocked 'nohup git stash &'
blocked 'timeout 30 git push --force'
blocked 'ls | xargs git branch -D'
blocked 'xargs -n 1 git branch -D < branches.txt'
blocked '/usr/bin/git reset --hard'
blocked 'git -C ../other reset --hard'
blocked 'git -c user.name=x --no-pager reset --hard'
blocked 'git --git-dir=.git --work-tree=. clean -fd'
blocked 'echo $(git reset --hard)'
blocked 'x="$(git stash pop)"'
blocked 'echo `git clean -fd`'
blocked "bash -c 'git rebase -i HEAD~2'"
blocked 'sh -c "cd x && git push --force"'
blocked "bash -lc 'git reset --hard'"
blocked 'eval git clean -fdx'
blocked "eval 'git reset --hard'"
blocked $'bash <<\'EOF\'\ngit stash\nEOF'
blocked $'sh <<-EOF\n\tgit reset --hard\n\tEOF'
blocked 'bash <<< "git reset --hard"'

echo "== allowed"
allowed 'git status'
allowed 'git log --oneline -n 5'
allowed 'git diff HEAD~1'
allowed 'git -c core.pager=cat --no-pager show HEAD'
allowed 'git stash list'
allowed 'git stash show -p stash@{0}'
allowed 'git reset HEAD a.txt'
allowed 'git reset --soft HEAD~1'
allowed 'git checkout main'
allowed 'git checkout -b feature/x'
allowed 'git switch -c feature/x'
allowed 'git switch main'
allowed 'git clean -n'
allowed 'git clean -nd'
allowed 'git clean --dry-run -x'
allowed 'git push'
allowed 'git push -u origin feature/x'
allowed 'git push origin HEAD:refs/heads/feature/x'
allowed 'git push --tags'
allowed 'git branch -d merged-branch'
allowed 'git branch -m old new'
allowed 'git branch --list'
allowed 'git reflog'
allowed 'git reflog show'
allowed 'git commit -m "revert: git reset --hard was a mistake"'
allowed "git commit -m 'never git push --force'"
allowed 'echo "git reset --hard"'
allowed "printf '%s\n' 'git clean -fd' 'git rebase main'"
allowed 'grep -rn "git stash pop" docs/'
allowed '# git reset --hard'
allowed 'git status # then git reset --hard'
allowed $'cat <<\'EOF\' > notes.md\ngit reset --hard\ngit push --force\nEOF'
allowed $'cat > run.sh <<EOF\ngit rebase main\ngit stash pop\nEOF\necho written'
allowed $'cat <<-EOF\n\tgit clean -fd\n\tEOF'
allowed $'cat <<A <<B\ngit reset --hard\nA\ngit push -f\nB\ngit status'
allowed 'git checkout main > .out 2>&1'
allowed 'git log 2> .err'
allowed 'bash ./scripts/build.sh'
allowed 'npm run rebase-docs'
allowed 'echo stash; echo reset --hard'
allowed 'ls -la'
allowed 'command -v git'

echo "== heredoc bodies are skipped but the commands after them are checked"
blocked $'cat <<EOF > x\ngit status\nEOF\ngit reset --hard'

echo "== output shape and payloads"
run 'git reset --hard'
eq "hookEventName" "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" PreToolUse
check "reason names the command and the safe alternative" \
  'jq -r .hookSpecificOutput.permissionDecisionReason <<<"$out" | grep -q "^BLOCKED: Destructive git command detected: git reset --hard" && jq -r .hookSpecificOutput.permissionDecisionReason <<<"$out" | grep -q worktree' "$out"
check "output is a single JSON object" '[ "$(jq -s length <<<"$out")" = 1 ]' "$out"
out=$(jq -cn '{tool_name:"Bash",tool_input:{command:["bash","-lc","git push --force"]},hook_event_name:"PreToolUse"}' | "$TEST_BASH" "$HOOK" 2>&1)
eq "Codex argv-array command is checked" "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out" 2>/dev/null)" deny
out=$(jq -cn '{tool_name:"Bash",tool_input:{command:["git","log"]}}' | "$TEST_BASH" "$HOOK" 2>&1)
eq "Codex argv-array read-only command allowed" "$out" ""
out=$(printf '{}' | "$TEST_BASH" "$HOOK" 2>&1); rc=$?
eq "no command: silent exit 0" "$rc:$out" "0:"
out=$(printf '' | "$TEST_BASH" "$HOOK" 2>&1); rc=$?
eq "empty stdin: silent exit 0" "$rc:$out" "0:"
out=$(printf 'not json' | "$TEST_BASH" "$HOOK" 2>&1); rc=$?
eq "invalid JSON: silent exit 0" "$rc:$out" "0:"

echo "== fail closed when the tokenizer cannot run"
NB=$WORK/noawk
mkdir -p "$NB"
for tool in jq cat; do ln -s "$(command -v "$tool")" "$NB/$tool"; done
BASH_BIN=$(command -v "$TEST_BASH")
out=$(jq -cn '{tool_input:{command:"echo \"git status\""}}' | PATH=$NB "$BASH_BIN" "$HOOK" 2>&1)
eq "no awk + mentions git -> deny" "$(jq -r .hookSpecificOutput.permissionDecision <<<"$out" 2>/dev/null)" deny
out=$(jq -cn '{tool_input:{command:"ls -la"}}' | PATH=$NB "$BASH_BIN" "$HOOK" 2>&1)
eq "no awk + no git -> allowed" "$out" ""

echo "== large heredoc"
big=$'cat > big.txt <<EOF\n'
i=0
while [ "$i" -lt 2000 ]; do big="${big}line $i: git reset --hard is only text here"$'\n'; i=$((i + 1)); done
big="${big}EOF"
allowed "$big"

shellcheck_files "shellcheck hook and suite" "$HOOK" "${BASH_SOURCE[0]}"

finish
