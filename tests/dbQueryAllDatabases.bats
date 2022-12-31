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
  BATS_TMP_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" -t bats-$$-XXXXXX)"
  export TMPDIR="${BATS_TMP_DIR}"

  export HOME="${BATS_TMP_DIR}/home"
  mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.bash-tools/dsn" \
    "${HOME}/.bash-tools/dbImportDumps" \
    "${HOME}/.bash-tools/dbImportProfiles" \
    "${HOME}/.bash-tools/dbQueries"

  cp "${BATS_TEST_DIRNAME}/mocks/pv" "${HOME}/bin"
  cp "${BATS_TEST_DIRNAME}/mocks/gawk" "${HOME}/bin"
  cp "${BATS_TEST_DIRNAME}/mocks/gawk" "${HOME}/bin/awk"
  touch \
    "${HOME}/bin/mysql" \
    "${HOME}/bin/mysqldump" \
    "${HOME}/bin/mysqlshow" \
    "${HOME}/bin/builtinCommandWrapper"
  chmod +x "${HOME}/bin/"*
  export BASH_FRAMEWORK_COMMAND="builtinCommandWrapper"

  cp "${BATS_TEST_DIRNAME}/data/dsn_"* "${HOME}/.bash-tools/dsn"

  export PATH="${PATH}:${HOME}/bin"
}

teardown() {
  rm -Rf "${BATS_TMP_DIR}" || true
  unstub_all
}

function Database::dbQueryAllDatabases::display_help { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
  run "${binDir}/dbQueryAllDatabases" --help
  # shellcheck disable=SC2154
  assert_line --index 2 "Usage: dbQueryAllDatabases <query|queryFile> [-d|--dsn <dsn>] [-q|--query] [--jobs|-j <jobsCount>] [--bar|-b]"
}

function Database::dbQueryAllDatabases::query_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
  run "${binDir}/dbQueryAllDatabases" 2>&1
  # shellcheck disable=SC2154
  assert_output --partial "FATAL   - You must provide the sql file to be executed"
}

function Database::dbQueryAllDatabases::providing_env_file_change_db_connection_parameters_and_retrieve_db_size { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallelDbQueryAllDatabases" "${HOME}/bin/parallel"
  # shellcheck disable=SC2016,SC2086
  stub mysql \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo "$9" >'" "${HOME}/query1" ; cat "${BATS_TEST_DIRNAME}/data/getUserDbList.result"" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e \* : echo -n "${8}" >'" "${HOME}/query2" ; cat "${BATS_TEST_DIRNAME}/data/databaseSize.result_db1"" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e \* : echo -n "${8}" >'" "${HOME}/query3" ; cat "${BATS_TEST_DIRNAME}/data/databaseSize.result_db2""

  f() {
    # shellcheck disable=SC2317
    "${binDir}/dbQueryAllDatabases" \
      -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
      "${rootDir}/conf/dbQueries/databaseSize.sql" 2>/dev/null
  }
  run f

  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/dbQueryAllDatabases.result")"
  [[ -f "${HOME}/query1" ]]
  cat "${HOME}/query1"
  [[ "$(cat "${HOME}/query1")" == "$(cat "${BATS_TEST_DIRNAME}/data/getUserDbList.query")" ]]
  [[ -f "${HOME}/query2" ]]
  echo >>"${HOME}/query2" # add a new line as megalinter add a newline at end of file
  [[ "$(md5sum <"${HOME}/query2")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
  echo >>"${HOME}/query3" # add a new line as megalinter add a newline at end of file
  [[ -f "${HOME}/query3" ]]
  [[ "$(md5sum <"${HOME}/query3")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
}
