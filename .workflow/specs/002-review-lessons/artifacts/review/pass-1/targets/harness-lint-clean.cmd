git ls-files -z -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
