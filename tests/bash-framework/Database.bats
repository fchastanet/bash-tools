#!/usr/bin/env bash

BASH_FRAMEWORK_FOLDER="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework"
# shellcheck source=bash-framework/_bootstrap.sh
__BASH_FRAMEWORK_ENV_FILEPATH="" source "${BASH_FRAMEWORK_FOLDER}/_bootstrap.sh" || exit 1

import bash-framework/Database

declare vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
    (
        mkdir -p /tmp/home/.bash-tools/dsn
        cd /tmp/home/.bash-tools/dsn
        cp ${BATS_TEST_DIRNAME}/data/dsn_* /tmp/home/.bash-tools/dsn
        touch default.local.env
        touch other.local.env
    )
}

teardown() {
    rm -Rf /tmp/home || true 
    unstub_all
}

@test "${BATS_TEST_FILENAME#/bash/tests/} framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::getDefaultConfDsnFolder" {
    [ "$(Database::getDefaultConfDsnFolder)" = "${__BASH_FRAMEWORK_VENDOR_PATH}/conf/dsn" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::getHomeConfDsnFolder" {
    [ "$(HOME=/home Database::getHomeConfDsnFolder)" = "/home/.bash-tools/dsn" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile file not found" {
    run Database::checkDsnFile "notfound" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"dsn file notfound not found"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile missing hostname" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_hostname.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_hostname.env : HOSTNAME not provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile warning hostname localhost" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_hostname_localhost.env" 2>&1
    [ "$status" -eq 0 ]
    [[ "${output}" == *"WARN  - dsn file /bash/tests/bash-framework/data/dsn_hostname_localhost.env : check that HOSTNAME should not be 127.0.0.1 instead of localhost"* ]]                        
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile missing port" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_port.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_port.env : PORT not provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile invalid port" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_invalid_port.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_invalid_port.env : PORT invalid"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile missing user" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_user.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_user.env : USER not provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile missing password" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_password.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_password.env : PASSWORD not provided"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::checkDsnFile valid" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_valid.env" 2>&1
    [ "$status" -eq 0 ]
    [[ "${output}" == "" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::newInstance unknown dsn file" {
    local -A dbFromInstance
    export HOME=/tmp/home 
    run Database::newInstance dbFromInstance "unknown"
    [ "$status" -eq 1 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::newInstance invalid dsn file" {
    local -A dbFromInstance
    run Database::newInstance dbFromInstance "dsn_missing_password"    
    [ "$status" -eq 1 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::newInstance valid dsn file from framework" {
    local -A dbFromInstance
    run Database::newInstance dbFromInstance "default.local"
    
    [ "$status" -eq 0 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::newInstance valid dsn file from home" {
    declare -Ax dbFromInstance
    HOME=/tmp/home Database::newInstance dbFromInstance "dsn_valid"    
    status=$?
    [[ "$status" -eq 0 ]]
    [ "${dbFromInstance['INITIALIZED']}" = "1" ]
    [ "${dbFromInstance['OPTIONS']}" = "--default-character-set=utf8" ]
    [ "${dbFromInstance['SSL_OPTIONS']}" = "--ssl-mode=DISABLED" ]
    [ "${dbFromInstance['DUMP_OPTIONS']}" = "--default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED" ]
    [ "${dbFromInstance['DSN_FILE']}" = "/tmp/home/.bash-tools/dsn/dsn_valid.env" ]
    [[ ${dbFromInstance['AUTH_FILE']} = /tmp/mysql.* ]]
    [ -f "${dbFromInstance['AUTH_FILE']}" ]
    [[ "${dbFromInstance["DEFAULT_QUERY_OPTIONS"]}" = "-s --skip-column-names" ]]
    [[ "${dbFromInstance['QUERY_OPTIONS']}" = "-s --skip-column-names" ]]
    [ "$(cat "${dbFromInstance['AUTH_FILE']}")" = "$(cat "${BATS_TEST_DIRNAME}/data/mysql_auth_file.cnf")" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::authFile valid dsn file from home" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]

    [ "$(cat "${dbFromInstance['AUTH_FILE']}")" = "$(cat "${BATS_TEST_DIRNAME}/data/mysql_auth_file.cnf")" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::setOptions" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    Database::setOptions dbFromInstance "test"
    [ "${dbFromInstance['OPTIONS']}" = "test" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::setDumpOptions" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    Database::setDumpOptions dbFromInstance "test"
    [ "${dbFromInstance['DUMP_OPTIONS']}" = "test" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::setQueryOptions" {
    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    Database::setQueryOptions dbFromInstance "test"
    [ "${dbFromInstance['QUERY_OPTIONS']}" = "test" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::newInstance auth files should be deleted" {
    declare authFile1=""
    declare authFile2=""
    (
        declare -Ax dbFromInstance1
        declare -Ax dbFromInstance2
        export HOME=/tmp/home
        Database::newInstance dbFromInstance1 "dsn_valid"
        Database::newInstance dbFromInstance2 "dsn_valid"
        authFile1="${dbFromInstance1['AUTH_FILE']}"
        authFile2="${dbFromInstance2['AUTH_FILE']}"
        [[ -f "${authFile1}" ]]
        [[ -f "${authFile2}" ]]
        # we write variables in files as values will be lost outside of this subshell
        echo -n "${authFile1}" > /tmp/home/authFile1
        echo -n "${authFile2}" > /tmp/home/authFile2
    )
    [[ -f /tmp/home/authFile1 ]] 
    [[ -f /tmp/home/authFile2 ]]
    authFile1="$(cat /tmp/home/authFile1)"
    authFile2="$(cat /tmp/home/authFile2)"
    [[ -n "${authFile1}" ]]
    [[ -n "${authFile2}" ]]
    [[ ! -f "${authFile1}" ]]
    [[ ! -f "${authFile2}" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::ifDbExists exists" {
    # call 2: check if from db exists, this time we answer no
    stub mysqlshow \
        '* --ssl-mode=DISABLED mydb : echo "Database: mydb"' 

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"

    run Database::ifDbExists dbFromInstance 'mydb'
    [ "$status" -eq 0 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::isTableExists exists" {
    # call 2: check if from db exists, this time we answer no
    stub mysql \
        '* -s --skip-column-names --default-character-set=utf8 -e * : echo $6 > /tmp/home/query ; echo "1"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"

    run Database::isTableExists dbFromInstance 'mydb' 'mytable'
    [ "$status" -eq 0 ]
    [ -f "/tmp/home/query" ]
    [[ "$(cat /tmp/home/query)" == "$(cat "${BATS_TEST_DIRNAME}/data/isTableExists.query")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::isTableExists not exists" {
    # call 2: check if from db exists, this time we answer no
    stub mysql \
        '* -s --skip-column-names --default-character-set=utf8 -e * : echo $6 > /tmp/home/query ; echo ""'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"

    run Database::isTableExists dbFromInstance 'mydb' 'mytable'
    [ "$status" -eq 1 ]
    [ -f "/tmp/home/query" ]
    [[ "$(cat /tmp/home/query)" == "$(cat "${BATS_TEST_DIRNAME}/data/isTableExists.query")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::createDb " {
    stub mysql \
        '* -s --skip-column-names --default-character-set=utf8 -e * : echo $6 > /tmp/home/query ; echo "Database: mydb"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"

    run Database::createDb dbFromInstance 'mydb'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Db mydb has been created"* ]]
    [ -f "/tmp/home/query" ]
    [[ "$(cat /tmp/home/query)" == "$(cat "${BATS_TEST_DIRNAME}/data/createDb.query")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::dropDb " {
    stub mysql \
        '* -s --skip-column-names --default-character-set=utf8 -e * : echo $6 > /tmp/home/query ; echo "Database: mydb"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"

    run Database::dropDb dbFromInstance 'mydb'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Db mydb has been dropped"* ]]
    [ -f "/tmp/home/query" ]
    [[ "$(cat /tmp/home/query)" == "$(cat "${BATS_TEST_DIRNAME}/data/dropDb.query")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::dropTable " {
    stub mysql \
        '* -s --skip-column-names --default-character-set=utf8 mydb -e * : echo $7 > /tmp/home/query ; echo "Database: mydb"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    run Database::dropTable dbFromInstance 'mydb' 'mytable'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Table mydb.mytable has been dropped"* ]]
    [ -f "/tmp/home/query" ]
    [[ "$(cat /tmp/home/query)" == "$(cat "${BATS_TEST_DIRNAME}/data/dropTable.query")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::dump" {
    stub mysqldump \
        '* --default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED mydb : echo "dump"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    run Database::dump dbFromInstance 'mydb'

    [ "$status" -eq 0 ]
    [[ "$output" = "dump" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::dump with table list" {
    stub mysqldump \
        '* --default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED mydb table1 table2 : echo "dump table1 table2"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    run Database::dump dbFromInstance 'mydb' "table1 table2"

    [ "$status" -eq 0 ]
    [[ "$output" = "dump table1 table2" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Database::dump with additional options" {
    stub mysqldump \
        '* --default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-create-info --skip-add-drop-table --single-transaction=TRUE mydb : echo "dump additional options"'

    declare -Ax dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    run Database::dump dbFromInstance 'mydb' "" --no-create-info --skip-add-drop-table --single-transaction=TRUE

    [ "$status" -eq 0 ]
    [[ "$output" = "dump additional options" ]]
}