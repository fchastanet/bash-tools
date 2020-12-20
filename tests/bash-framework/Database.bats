#!/usr/bin/env bash

BASH_FRAMEWORK_FOLDER="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework"
# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "${BASH_FRAMEWORK_FOLDER}/_bootstrap.sh" || exit 1

import bash-framework/Database

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
}

@test "framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "Database::getDefaultConfDsnFolder" {
    [ "$(Database::getDefaultConfDsnFolder)" = "${__bash_framework_rootVendorPath}/conf/dsn" ]
}

@test "Database::getHomeConfDsnFolder" {
    [ "$(HOME=/home Database::getHomeConfDsnFolder)" = "/home/.bash-tools/dsn" ]
}

@test "Database::getDsnList" {
    output="$(HOME=/tmp/home Database::getDsnList)"
    [ "$(cat "${BATS_TEST_DIRNAME}/data/database.dsnList1")" = "${output}" ]
}

@test "Database::checkDsnFile file not found" {
    run Database::checkDsnFile "notfound" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"dsn file notfound not found"* ]]
}

@test "Database::checkDsnFile missing hostname" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_hostname.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_hostname.env : HOSTNAME not provided"* ]]
}

@test "Database::checkDsnFile warning hostname localhost" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_hostname_localhost.env" 2>&1
    [ "$status" -eq 0 ]
    [[ "${output}" == *"WARN  - dsn file /bash/tests/bash-framework/data/dsn_hostname_localhost.env : check that HOSTNAME should not be 127.0.0.1 instead of localhost"* ]]                        
}

@test "Database::checkDsnFile missing port" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_port.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_port.env : PORT not provided"* ]]
}

@test "Database::checkDsnFile invalid port" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_invalid_port.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_invalid_port.env : PORT invalid"* ]]
}

@test "Database::checkDsnFile missing user" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_user.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_user.env : USER not provided"* ]]
}

@test "Database::checkDsnFile missing password" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_missing_password.env" 2>&1
    [ "$status" -eq 1 ]
    [[ "${output}" == *"ERROR - dsn file /bash/tests/bash-framework/data/dsn_missing_password.env : PASSWORD not provided"* ]]
}

@test "Database::checkDsnFile valid" {
    run Database::checkDsnFile "${BATS_TEST_DIRNAME}/data/dsn_valid.env" 2>&1
    [ "$status" -eq 0 ]
    [[ "${output}" == "" ]]
}

@test "Database::newInstance unknown dsn file" {
    local -A dbFromInstance
    run Database::newInstance dbFromInstance "unknown"    
    [ "$status" -eq 1 ]
}

@test "Database::newInstance invalid dsn file" {
    local -A dbFromInstance
    run Database::newInstance dbFromInstance "dsn_missing_password"    
    [ "$status" -eq 1 ]
}

@test "Database::newInstance valid dsn file from framework" {
    local -A dbFromInstance
    run Database::newInstance dbFromInstance "default.local"
    
    [ "$status" -eq 0 ]
}

@test "Database::newInstance valid dsn file from home" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"    
    status=$?
    [ "$status" -eq 0 ]
    [ "${dbFromInstance['INITIALIZED']}" = "1" ]
    [ "${dbFromInstance['OPTIONS']}" = "--default-character-set=utf8" ]
    [ "${dbFromInstance['SSL_OPTIONS']}" = "--ssl-mode=DISABLED" ]
    [ "${dbFromInstance['DEFAULT_QUERY_OPTIONS']}" = "-s --skip-column-names --ssl-mode=DISABLED " ]
    [ "${dbFromInstance['QUERY_OPTIONS']}" = "-s --skip-column-names --ssl-mode=DISABLED " ]
    [ "${dbFromInstance['DUMP_OPTIONS']}" = "--default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED" ]
    [ "${dbFromInstance['DSN_FILE']}" = "/tmp/home/.bash-tools/dsn/dsn_valid.env" ]
    [[ ${dbFromInstance['AUTH_FILE']} = /tmp/mysql.* ]]
    [ -f "${dbFromInstance['AUTH_FILE']}" ]
    [ "$(cat "${dbFromInstance['DSN_FILE']}")" = "$(cat "${BATS_TEST_DIRNAME}/data/mysql_auth_file.cnf")" ]
}

@test "Database::authFile valid dsn file from home" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    run Database::authFile dbFromInstance
    [ "${output}" = "$(cat "${BATS_TEST_DIRNAME}/data/mysql_auth_file.cnf")" ]
}

@test "Database::setOptions" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    Database::setOptions dbFromInstance "test"
    [ "${dbFromInstance['OPTIONS']}" = "test" ]
}

@test "Database::setDumpOptions" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    Database::setDumpOptions dbFromInstance "test"
    [ "${dbFromInstance['DUMP_OPTIONS']}" = "test" ]
}

@test "Database::setQueryOptions" {
    declare -Agx dbFromInstance
    export HOME=/tmp/home
    Database::newInstance dbFromInstance "dsn_valid"
    status=$?
    [ "$status" -eq 0 ]
    Database::setQueryOptions dbFromInstance "test"
    [ "${dbFromInstance['QUERY_OPTIONS']}" = "test" ]
}

# TODO Database::ifDbExists
# TODO Database::isTableExists
# TODO Database::createDb
# TODO Database::dropDb
# TODO Database::dropTable
# TODO Database::dropTable
# TODO Database::dump

