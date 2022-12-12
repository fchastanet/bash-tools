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
      .bash-tools/dbQueries \
      .bash-tools/dbScripts
    cp "${BATS_TEST_DIRNAME}/mocks/pv" bin
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
  run "${binDir}/dbScriptAllDatabases" --help
  # shellcheck disable=SC2154
  assert_line --index 2 "Usage: dbScriptAllDatabases [-j|--jobs <numberOfJobs>] [-o|--output <outputDirectory>] [-d|--dsn <dsn>] [-v|--verbose] [-l|--log-format <logFormat>] [--database <dbName>] <scriptToExecute> [optional parameters to pass to the script]"
}

function script_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"

  f() {
    HOME=/tmp/home "${binDir}/dbScriptAllDatabases" 2>&1
  }
  run f
  # shellcheck disable=SC2154
  assert_output "FATAL   - You must provide the script file to be executed"
}

function extractData { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallelDbScriptAllDatabases" "${HOME}/bin/parallel"
  # shellcheck disable=SC2016
  stub mysql \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$@" > /tmp/home/query0 ; '"cat ${BATS_TEST_DIRNAME}/data/getUserDbList.result" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e * : echo -n "$8" > /tmp/home/query1 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db1;" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e * : echo -n "$8" > /tmp/home/query2 ; '"cat ${BATS_TEST_DIRNAME}/data/databaseSize.result_db2;"

  f() {
    HOME=/tmp/home "${binDir}/dbScriptAllDatabases" \
      -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
      "${rootDir}/conf/dbScripts/extractData" \
      "${rootDir}/conf/dbQueries/databaseSize.sql"
  }
  run f

  [[ -f "/tmp/home/query1" ]]
  echo >>/tmp/home/query1 # add a new line as megalinter add a newline at end of file
  [[ "$(md5sum </tmp/home/query1)" == "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]

  [[ -f "/tmp/home/query2" ]]
  echo >>/tmp/home/query2 # add a new line as megalinter add a newline at end of file
  [[ "$(md5sum </tmp/home/query2)" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]

  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/dbScriptAllDatabases.result")"
}

function parallel_not_installed { #@test
  run "${binDir}/dbScriptAllDatabases" \
    -j2 \
    "${rootDir}/conf/dbQueries/databaseSize.sql" 2>&1

  # could fail if run outside docker because parallel could be installed
  assert_output --partial "ERROR   - parallel is not installed, please install it"
}
