#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

declare -g mysqlMockedStep=0


@test "display help" {
    run ${toolsDir}/gitRenameBranch --help 2>&1
    [ "$status" -eq 0 ]
    (>&2 echo coucou $output)
    [[ "${output}" == *"Description: rename git local branch, use options to push new branch and delete old branch"* ]]
}

@test "branch not provided" {
    run ${toolsDir}/gitRenameBranch  2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"ERROR - master branch not supported by this command, please do it manually"* ]]
}

@test "branch master provided" {
    run ${toolsDir}/gitRenameBranch master 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"ERROR - master branch not supported by this command, please do it manually"* ]]
}

@test "branch master provided as oldBranch" {
    run ${toolsDir}/gitRenameBranch newBranch master 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"ERROR - master branch not supported by this command, please do it manually"* ]]
}

@test "too much parameters" {
    run ${toolsDir}/gitRenameBranch newBranch oldBranch toomuch 2>&1
    [ "$status" -eq 1 ]
    [[ ${output} == *"ERROR - too much arguments provided"* ]]
}

@test "rename local branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    run ${toolsDir}/gitRenameBranch newBranch  2>&1
    
    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    [ ${#lines[@]} -eq 2 ]
}

@test "rename local and push branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    run ${toolsDir}/gitRenameBranch newBranch --push 2>&1

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push --set-upstream origin newBranch"
    [ ${#lines[@]} -eq 4 ]
}

@test "rename local, push, delete remote branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    run ${toolsDir}/gitRenameBranch newBranch --push --delete 2>&1

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push origin :oldBranch"
    assert_line -n 5 "git push --set-upstream origin newBranch"
    [ ${#lines[@]} -eq 6 ]
}

@test "rename local, and delete remote branch" {
    git() {
        if [ "$2" = "--show-current" ]; then
            exit 1
        else
            echo "git $@"
        fi
    }
    export -f git
    run ${toolsDir}/gitRenameBranch newBranch oldName --delete 2>/dev/null

    [ "$status" -eq 0 ]

    assert_line -n 1 "git branch -m oldName newBranch"
    assert_line -n 3 "git push origin :oldName"
    [ ${#lines[@]} -eq 4 ]
}
    
@test "rename local, and delete remote branch without oldName" {
    git() {
        if [ "$2" = "--show-current" ]; then
            echo "oldBranch"
        else
            echo "git $@"
        fi
    }
    export -f git
    run ${toolsDir}/gitRenameBranch newBranch --delete 2>/dev/null

    [ "$status" -eq 0 ]
    assert_line -n 1 "git branch -m oldBranch newBranch"
    assert_line -n 3 "git push origin :oldBranch"
    [ ${#lines[@]} -eq 4 ]
}
