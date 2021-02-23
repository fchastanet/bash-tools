#!/usr/bin/env bash

# cat represents the whole list of tables
cat | \
    grep -v '.*_log' |
    grep -v '.*logs' |
    grep -v '.*tracking' |
    grep -v '.*stats' |
    grep -v '.*history.*' |
    # always finish by a cat to be sure the command does not return exit code != 0
    cat
