#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
toolsDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

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
  run "${toolsDir}/dbQueryAllDatabases" --help
  # shellcheck disable=SC2154
  [[ "${lines[2]}" = "${__HELP_TITLE}Usage:${__HELP_NORMAL} dbQueryAllDatabases <query|queryFile> [-d|--dsn <dsn>] [-q|--query] [--jobs|-j <jobsCount>] [--bar|-b]" ]]
}

function query_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
  HOME=/tmp/home run "${toolsDir}/dbQueryAllDatabases" 2>&1
  # shellcheck disable=SC2154
  [[ ${output} == *"FATAL - You must provide the sql file to be executed"* ]]
}

function providing_env_file_change_db_connection_parameters_and_retrieve_db_size { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallelDbQueryAllDatabases" "${HOME}/bin/parallel"
  # shellcheck disable=SC2016
  stub mysql \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo $9 > /tmp/home/query1 ; '"cat ${BATS_TEST_DIRNAME}/data/getUserDbList.result" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e \* : echo -n "${8}" > /tmp/home/query2 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db1" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e \* : echo -n "${8}" > /tmp/home/query3 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db2"

  f() {
    "${toolsDir}/dbQueryAllDatabases" \
      -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
      "${rootDir}/conf/dbQueries/databaseSize.sql" 2>/dev/null
  }
  run f
  [[ -f "/tmp/home/query1" ]]
  [[ "$(cat /tmp/home/query1)" == "$(cat "${BATS_TEST_DIRNAME}/data/getUserDbList.query")" ]]
  [[ -f "/tmp/home/query2" ]]
  [[ "$(md5sum </tmp/home/query2)" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
  [[ -f "/tmp/home/query3" ]]
  [[ "$(md5sum </tmp/home/query3)" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
  [[ "${output}" == "$(cat "${BATS_TEST_DIRNAME}/data/dbQueryAllDatabases.result")" ]]
}

function parallel_not_installed { #@test
  run "${toolsDir}/dbQueryAllDatabases" \
    -j2 \
    "${rootDir}/conf/dbQueries/databaseSize.sql"

  # could fail if run outside docker because parallel could be installed
  [[ "${output}" == *"ERROR - parallel is not installed, please install it"* ]]
}
