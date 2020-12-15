#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
load "${vendorDir}/bats-mock/stub.bash"

setup() {
    stub pv "cat" 
    stub mysql 'true'
    stub mysqldump 'true'
    stub mysqlshow 'true'
}

teardown() {
    # no need to unstub because thos programs does not exists in docker container
    true
}

@test "display help" {
    run ${toolsDir}/dbImport --help 2>&1
    [[ "${output}" == *"Description: Import source db into target db"* ]]
}

@test "remoteDbName not provided" {
    run ${toolsDir}/dbImport  2>&1
    [[ "${output}" == *"ERROR - you must provide remoteDbName"* ]]
}

@test "--from-aws and --from-dsn are incompatible" {
    run ${toolsDir}/dbImport --from-dsn default --from-aws fromDb 2>&1
    [[ "${output}" == *"ERROR - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "--from-aws missing S3_BASE_URL" {
    run ${toolsDir}/dbImport --from-aws fromDb 2>&1
    [[ "${output}" == *"ERROR - missing S3_BASE_URL, please provide a value in .env file"* ]]
}

# @test "-a and -f are incompatible" {
#     run ${toolsDir}/dbImport -f default -a fromDb 2>&1
#     [[ ${out} == *"ERROR - you cannot use from-dsn and from-aws at the same time"* ]]
# }
