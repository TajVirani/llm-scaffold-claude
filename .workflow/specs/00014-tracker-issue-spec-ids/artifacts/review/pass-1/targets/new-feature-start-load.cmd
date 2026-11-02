bash tests/lint/workflow-load-size.sh | sed -n 's/^new-feature start: \([0-9]*\) bytes.*/\1/p'
