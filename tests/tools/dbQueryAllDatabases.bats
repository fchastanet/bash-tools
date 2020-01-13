#!/usr/bin/env bash

load '../../vendor/bats-support/load'
load '../../vendor/bats-assert/load'

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g mysqlMockedStep=0

@test "display help" {
    local help=$(${toolsDir}/dbQueryAllDatabases --help)
    [[ ${help} == *"<query|queryFile> [--env-file|-e <envfile>] [-t|--as-tsv] [-q|--query] [-w|--with-headers] [--jobs|-j <numberOfJobs>] [--bar|-b]"* ]]
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
    set -x
    local mysqlMockedStep=0
    mysqlMocked() {
        case ${mysqlMockedStep} in
        0)
            cat "${BATS_TEST_DIRNAME}/data/databaseSize.dbList"
            ;;
        1)
            cat "${BATS_TEST_DIRNAME}/data/databaseSize.result_db1"
            ;;
        2)
            cat "${BATS_TEST_DIRNAME}/data/databaseSize.result_db2"
            ;;
        esac
    }
    alias mysql=mysqlMocked

    Database::setMysqlCommands dbInstance \
        "mysql" \
        "${dbInstance['MYSQLDUMP_COMMAND']}" \
        "${dbInstance['MYSQLSHOW_COMMAND']}"

    local out=$(
        ${toolsDir}/dbQueryAllDatabases \
            -e "${BATS_TEST_DIRNAME}/data/localhost-root.env" \
            "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
    )
    echo $out
    [[ ${out} == *"ERROR - You must provide env-file parameter"* ]]
}

@test "parallel not installed" {
    alias parallel="dsfsdf"
    local out=$(${toolsDir}/dbQueryAllDatabases -j2 2>&1)
    echo $out
}
