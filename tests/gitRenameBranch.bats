#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

declare -g mysqlMockedStep=0


setup() {
    rm -Rf /tmp/gitRepo || true
    mkdir /tmp/gitRepo
    mkdir /tmp/gitRepoFake
    cd /tmp/gitRepo
    git init
    git config --local user.email "you@example.com"
    git config --local user.name "Your Name"

    touch f
    git add f
    git commit -m 'test'
    git checkout -b main master
    git checkout -b oldBranch master
}

teardown() {
  rm -Rf /tmp/gitRepo* || true
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/gitRenameBranch --help 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "${__HELP_TITLE}Description:${__HELP_NORMAL} rename git local branch, use options to push new branch and delete old branch" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} not a git repository" {
    cd /tmp/gitRepoFake
    run "${toolsDir}/gitRenameBranch" "test"  2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - not a git repository (or any of the parent directories)"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} master branch not supported" {
    git checkout master
    run ${toolsDir}/gitRenameBranch 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} main branch not supported" {
    git checkout main
    run ${toolsDir}/gitRenameBranch 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} master branch not supported as argument" {
    run ${toolsDir}/gitRenameBranch master 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} main branch not supported as argument" {
    run ${toolsDir}/gitRenameBranch main 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} new branch name not provided" {
    run ${toolsDir}/gitRenameBranch 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - new branch name not provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} branch not provided" {
    run ${toolsDir}/gitRenameBranch  2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - new branch name not provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} branch master provided" {
    run ${toolsDir}/gitRenameBranch master 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} branch main provided" {
    run ${toolsDir}/gitRenameBranch main 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} branch master provided as oldBranch" {
    run ${toolsDir}/gitRenameBranch newBranch master 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} too much parameters" {
    run ${toolsDir}/gitRenameBranch newBranch oldBranch toomuch 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"FATAL - too much arguments provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local and push branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'y' | ${toolsDir}/gitRenameBranch newBranch --push 2>&1))
    status="$?"

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push --set-upstream origin newBranch"
    [ ${#lines[@]} -eq 4 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local, push, delete remote branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'yy' | ${toolsDir}/gitRenameBranch newBranch --push --delete 2>&1))
    status="$?"

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push origin :oldBranch"
    assert_line -n 5 "git push --set-upstream origin newBranch"
    [ ${#lines[@]} -eq 6 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local, and delete remote branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            # should not call this as oldBranch provided
            exit 1
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'y' | ${toolsDir}/gitRenameBranch newBranch oldName --delete 2>&1))
    status="$?"

    [ "$status" -eq 0 ]

    assert_line -n 1 "git branch -m oldName newBranch"
    assert_line -n 3 "git push origin :oldName"
    [ ${#lines[@]} -eq 4 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local, and delete remote branch without oldName" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'y' | ${toolsDir}/gitRenameBranch newBranch --delete 2>&1))
    status="$?"

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push origin :oldBranch"
    [ ${#lines[@]} -eq 4 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local and push branch (assume-yes)" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(${toolsDir}/gitRenameBranch newBranch --push --assume-yes 2>&1))
    status="$?"

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push --set-upstream origin newBranch"
    [ ${#lines[@]} -eq 4 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local, push, delete remote branch (assume-yes)" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'yy' | ${toolsDir}/gitRenameBranch newBranch --push --delete --assume-yes 2>&1))
    status="$?"

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push origin :oldBranch"
    assert_line -n 5 "git push --set-upstream origin newBranch"
    [ ${#lines[@]} -eq 6 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local, and delete remote branch (assume-yes)" {
    git() {
        if [ "$2" = "--show-current" ]; then
            # should not call this as oldBranch provided
            exit 1
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'y' | ${toolsDir}/gitRenameBranch newBranch oldName --delete --assume-yes 2>&1))
    status="$?"

    [ "$status" -eq 0 ]

    assert_line -n 1 "git branch -m oldName newBranch"
    assert_line -n 3 "git push origin :oldName"
    [ ${#lines[@]} -eq 4 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} rename local, and delete remote branch without oldName (assume-yes)" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    IFS=$'\n'
    lines=($(echo -n 'y' | ${toolsDir}/gitRenameBranch newBranch --delete --assume-yes 2>&1))
    status="$?"

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push origin :oldBranch"
    [ ${#lines[@]} -eq 4 ]
}
