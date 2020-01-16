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

@test "env-file not provided" {
    local out=$(${toolsDir}/dbQueryAllDatabases "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1)
    [[ ${out} == *"ERROR - You must provide env-file parameter"* ]]
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
    alias parallel="dsfsdf"
    local out=$(${toolsDir}/dbQueryAllDatabases -j2 2>&1)
    echo $out
}
