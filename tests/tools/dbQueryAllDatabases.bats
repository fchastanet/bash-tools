#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"

load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
    export HOME="/tmp/home"
    (
        mkdir -p "${HOME}" 
        cd "${HOME}"
        mkdir -p \
            bin \
            .bash-tools/dsn \
            .bash-tools/dbImportDumps \
            .bash-tools/dbImportProfiles \
            .bash-tools/dbQueries
        cp "${BATS_TEST_DIRNAME}/mocks/pv" bin
        touch bin/mysql bin/mysqldump bin/mysqlshow
        chmod +x bin/*
        cp ${BATS_TEST_DIRNAME}/data/dsn_* .bash-tools/dsn
        #cp ${BATS_TEST_DIRNAME}/data/.env .bash-tools
    )
    export PATH="$PATH:/tmp/home/bin"
}

teardown() {
    rm -Rf /tmp/home || true
    unstub_all
}

# @test "display help" {
#     run ${toolsDir}/dbQueryAllDatabases --help
#     [[ "${lines[2]}" == *"Usage: dbQueryAllDatabases <query|queryFile> [-d|--dsn <dsn>] [-t|--as-tsv] [-q|--query] [--jobs|-j <jobsCount>] [--bar|-b]"* ]]
# }

# @test "query file not provided" {
#     HOME=/tmp/home run ${toolsDir}/dbQueryAllDatabases  2>&1
#     [[ ${output} == *"ERROR - You must provide the sql file to be executed"* ]]
# }

# @test "providing env-file port invalid" {
#     run ${toolsDir}/dbQueryAllDatabases \
#         -d "${BATS_TEST_DIRNAME}/data/databaseSize.invalidParamPort.sh" \
#         "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
#     [[ "${output}" == *"ERROR - dsn file /bash/tests/tools/data/databaseSize.invalidParamPort.sh : PORT invalid"* ]]
# }
# TODO other invalid data

@test "providing env-file changes the db connection parameters + retrieve db size" {
    stub mysql \
        '\* -s --skip-column-names --connect-timeout=5 mysql -e show\ databases : cp ${1##*=} /tmp/connectionParameters ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.dbList" \
        "\* -s --skip-column-names --connect-timeout=5 db1 -e \* : cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db1" \
        "\* -s --skip-column-names --connect-timeout=5 db2 -e \* : cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db2"
    
    run ${toolsDir}/dbQueryAllDatabases \
        -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
        "${BATS_TEST_DIRNAME}/data/databaseSize.sql"
    [[ -f "/tmp/connectionParameters" ]]
    [[ "$(cat /tmp/connectionParameters)" = "$(cat "${BATS_TEST_DIRNAME}/data/databaseSize.expected.cnf")" ]]
    [[ "${output}" == "$(cat ${BATS_TEST_DIRNAME}/data/databaseSize.expectedResult)" ]]
}

@test "parallel not installed" {
    run ${toolsDir}/dbQueryAllDatabases \
        -j2 \
        "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
    
    # could fail if run outside docker because parallel could be installed
    [[ "${output}" == *"ERROR - parallel is not installed, please install it"* ]]
}

@test "parallel query" {
    cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
    stub mysql \
        "\* -s --skip-column-names --connect-timeout=5 mysql -e show\ databases : cat ${BATS_TEST_DIRNAME}/data/databaseSize.dbList" \
        "\* --connect-timeout=5 --default-character-set=utf8 db1 -e \* : cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db1" \
        "\* --connect-timeout=5 --default-character-set=utf8 db2 -e \* : cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db2"
    
    run ${toolsDir}/dbQueryAllDatabases \
        -j2 \
        "${BATS_TEST_DIRNAME}/data/databaseSize.sql" 2>&1
    
    [[ "${output}" = "$(cat "${BATS_TEST_DIRNAME}/data/databaseSize.expectedResult")" ]]
}