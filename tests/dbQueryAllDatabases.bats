#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"

# shellcheck source=vendor/bash-tools-framework/src/Log/_.sh
source "${vendorDir}/bash-tools-framework/src/Log/_.sh" || exit 1

load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"
load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
  export HOME="/tmp/home"
  (
    mkdir -p "${HOME}"
    cd "${HOME}" || exit 1
    mkdir -p \
      bin \
      .bash-tools/dsn \
      .bash-tools/dbImportDumps \
      .bash-tools/dbImportProfiles \
      .bash-tools/dbQueries
    cp "${BATS_TEST_DIRNAME}/mocks/pv" bin
    cp "${BATS_TEST_DIRNAME}/mocks/gawk" bin
    cp "${BATS_TEST_DIRNAME}/mocks/gawk" bin/awk
    touch bin/mysql bin/mysqldump bin/mysqlshow
    chmod +x bin/*
    cp "${BATS_TEST_DIRNAME}/data/dsn_"* .bash-tools/dsn
  )
  export PATH="${PATH}:/tmp/home/bin"
}

teardown() {
  rm -Rf /tmp/home || true
  unstub_all
}

function display_help { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
  run "${binDir}/dbQueryAllDatabases" --help
  # shellcheck disable=SC2154
  assert_line --index 2 "Usage: dbQueryAllDatabases <query|queryFile> [-d|--dsn <dsn>] [-q|--query] [--jobs|-j <jobsCount>] [--bar|-b]"
}

function query_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
  HOME=/tmp/home run "${binDir}/dbQueryAllDatabases" 2>&1
  # shellcheck disable=SC2154
  assert_output --partial "FATAL   - You must provide the sql file to be executed"
}

function providing_env_file_change_db_connection_parameters_and_retrieve_db_size { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallelDbQueryAllDatabases" "${HOME}/bin/parallel"
  # shellcheck disable=SC2016
  stub mysql \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo $9 > /tmp/home/query1 ; '"cat ${BATS_TEST_DIRNAME}/data/getUserDbList.result" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e \* : echo -n "${8}" > /tmp/home/query2 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db1" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e \* : echo -n "${8}" > /tmp/home/query3 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db2"

  f() {
    "${binDir}/dbQueryAllDatabases" \
      -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
      "${rootDir}/conf/dbQueries/databaseSize.sql" 2>/dev/null
  }
  run f

  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/dbQueryAllDatabases.result")"
  [[ -f "/tmp/home/query1" ]]
  [[ "$(cat /tmp/home/query1)" == "$(cat "${BATS_TEST_DIRNAME}/data/getUserDbList.query")" ]]
  [[ -f "/tmp/home/query2" ]]
  echo >>/tmp/home/query2 # add a new line as megalinter add a newline at end of file
  [[ "$(md5sum </tmp/home/query2)" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
  echo >>/tmp/home/query3 # add a new line as megalinter add a newline at end of file
  [[ -f "/tmp/home/query3" ]]
  [[ "$(md5sum </tmp/home/query3)" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
}

function parallel_not_installed { #@test
  run "${binDir}/dbQueryAllDatabases" \
    -j2 \
    "${rootDir}/conf/dbQueries/databaseSize.sql"

  # could fail if run outside docker because parallel could be installed
  assert_output --partial "ERROR   - parallel is not installed, please install it"
}
