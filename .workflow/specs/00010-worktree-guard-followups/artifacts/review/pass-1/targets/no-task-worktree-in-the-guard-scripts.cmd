grep -ci 'task worktree' .agents/skills/feature-workflow/scripts/check-worktree-scope.sh .agents/hooks/worktree-write-guard.sh | awk -F: '{n+=$2} END{print n}'
