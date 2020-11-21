#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g mysqlMockedStep=0

@test "display help" {
    local help=$(${toolsDir}/dbQueryAllDatabases --help)
    [[ "${help}" == *"<query|queryFile> [--env-file|-e <envfile>] [-t|--as-tsv] [-q|--query] [--jobs|-j <numberOfJobs>] [--bar|-b]"* ]]
}

@test "query file not provided" {
    local out=$(${toolsDir}/dbQueryAllDatabases  2>&1)
    [[ ${out} == *"ERROR - You must provide the sql file to be executed"* ]]
}

@test "providing env-file changes the db connection parameters" {
    local out=$(${toolsDir}/dbQueryAllDatabases \
        -e "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
        "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
    )
    [[ ${out} == *"parameters OK"* ]]
}

@test "db size" {
    local out=$(
        ${toolsDir}/dbQueryAllDatabases \
            -e "${BATS_TEST_DIRNAME}/data/databaseSize.env.sh" \
            "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
    )
    [[ "${out}" = "$(cat "${BATS_TEST_DIRNAME}/data/databaseSize.expectedResult")" ]]
}

@test "parallel not installed" {
    local out=$(${toolsDir}/dbQueryAllDatabases \
        -j2 \
        "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
    )
    # could fail if run outside docker because parallel could be installed
    [[ "${out}" == *"ERROR - parallel is not installed, please install it"* ]]
}
