#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/mysql2puml --help 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "${__HELP_TITLE}Description:${__HELP_NORMAL} convert mysql dump sql schema to plantuml format" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display version" {
    run ${toolsDir}/mysql2puml --version 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "mysql2puml Version: 0.1" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} bad skin file" {
    run ${toolsDir}/mysql2puml --skin badSkin 2>&1
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" == *"ERROR - conf file 'badSkin' not found"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} input file not found" {
    run ${toolsDir}/mysql2puml --skin default notFound.sql 2>&1
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" == *"FATAL - file notFound.sql does not exist"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} parse file" {
    run ${toolsDir}/mysql2puml --skin default "${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
    [ "$status" -eq 0 ]

    [[ "${output}" = "$(cat ${BATS_TEST_DIRNAME}/data/mysql2puml.puml)" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} parse file from input" {
    run ${toolsDir}/mysql2puml --skin default < "${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
    [ "$status" -eq 0 ]
    [[ "${output}" = "$(cat ${BATS_TEST_DIRNAME}/data/mysql2puml.puml)" ]]
}