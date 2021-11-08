#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

@test "${BATS_TEST_FILENAME#/bash/tests/} print usage" {
    run ${toolsDir}/mysql2puml --help 2>&1
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" == "mysql2puml Help" ]]
}


@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/mysql2puml --help 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "mysql2puml Help" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display version" {
    run ${toolsDir}/mysql2puml --version 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "mysql2puml Version: 0.1" ]]
}

