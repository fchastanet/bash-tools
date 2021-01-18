#!/usr/bin/env bash

declare -g rootDir="$( cd "${BATS_TEST_DIRNAME}/../.." && pwd )"
declare -g toolsDir="${rootDir}/bin"
declare -g vendorDir="${rootDir}/vendor"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

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
            .bash-tools/dbQueries \
            .bash-tools/dbScripts
        cp "${BATS_TEST_DIRNAME}/mocks/pv" bin
        touch bin/mysql bin/mysqldump bin/mysqlshow
        chmod +x bin/*
        cp ${BATS_TEST_DIRNAME}/data/dsn_* .bash-tools/dsn
    )
    export PATH="$PATH:/tmp/home/bin"
}

teardown() {
    rm -Rf /tmp/home || true
    unstub_all
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
    run ${toolsDir}/dbScriptAllDatabases --help
    [[ "${lines[2]}" = "${__HELP_TITLE}Usage:${__HELP_NORMAL} dbScriptAllDatabases [-j|--jobs <numberOfJobs>] [-o|--output <outputDirectory>] [-d|--dsn <dsn>] [-v|--verbose] [-l|--log-format <logFormat>] [--database <dbName>] <scriptToExecute> [optional parameters to pass to the script]" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} script file not provided" {
    cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
    
    f() {
        HOME=/tmp/home  ${toolsDir}/dbScriptAllDatabases 2>&1
    }
    run f
    [[ ${output} == *"FATAL - You must provide the script file to be executed"* ]]
}


@test "${BATS_TEST_FILENAME#/bash/tests/} extractData" {
    cp "${BATS_TEST_DIRNAME}/mocks/parallelDbScriptAllDatabases" "${HOME}/bin/parallel"
    stub mysql \
        '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo $9 > /tmp/home/query1 ; '"cat ${BATS_TEST_DIRNAME}/data/getUserDbList.result" \
        '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e * : echo -n "${8}" > /tmp/home/query1 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db1;" \
        '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e * : echo -n "${8}" > /tmp/home/query2 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db2;" 

    f() {
        HOME=/tmp/home ${toolsDir}/dbScriptAllDatabases \
        -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
        "${rootDir}/conf/dbScripts/extractData.sh" \
        "${rootDir}/conf/dbQueries/databaseSize.sql"
    }
    run f 
    [ -f "/tmp/home/query1" ]
    [[ "$(cat /tmp/home/query1 | md5sum)" == "$(cat ${rootDir}/conf/dbQueries/databaseSize.sql | md5sum)" ]]
    [ -f "/tmp/home/query2" ]
    [[ "$(cat /tmp/home/query2 | md5sum)" = "$(cat ${rootDir}/conf/dbQueries/databaseSize.sql | md5sum)" ]]
    [[ "${output}" == "$(cat "${BATS_TEST_DIRNAME}/data/dbScriptAllDatabases.result")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} parallel not installed" {
    run ${toolsDir}/dbScriptAllDatabases \
        -j2 \
        "${rootDir}/conf/dbQueries/databaseSize.sql" 2>&1
    
    # could fail if run outside docker because parallel could be installed
    [[ "${output}" == *"ERROR - parallel is not installed, please install it"* ]]
}
