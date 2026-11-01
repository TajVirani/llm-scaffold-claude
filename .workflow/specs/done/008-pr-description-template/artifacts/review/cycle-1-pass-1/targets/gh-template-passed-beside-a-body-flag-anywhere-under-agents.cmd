git grep -h -E 'gh pr create' -- .agents | grep -E -- '--template|-T ' | grep -c -E -- '--body|-b |-F '
