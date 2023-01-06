#!/usr/bin/env bash

# shellcheck source=tests/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}" && pwd)/batsHeaders.sh"

setup() {
  BATS_TMP_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" -t bats-$$-XXXXXX)"
  export TMPDIR="${BATS_TMP_DIR}"

  export HOME="${BATS_TMP_DIR}/home"
  mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.bash-tools/dsn" \
    "${HOME}/.bash-tools/dbImportDumps" \
    "${HOME}/.bash-tools/dbImportProfiles" \
    "${HOME}/.bash-tools/dbQueries" \
    "${HOME}/.bash-tools/dbScripts"
  cp "${BATS_TEST_DIRNAME}/mocks/pv" "${HOME}/bin"
  touch \
    "${HOME}/bin/mysqldump" \
    "${HOME}/bin/mysqlshow" \
    "${HOME}/bin/builtinCommandWrapper"
  chmod +x "${HOME}/bin/"*
  export BASH_FRAMEWORK_COMMAND="builtinCommandWrapper"

  cp "${BATS_TEST_DIRNAME}/data/dsn_"* "${HOME}/.bash-tools/dsn"

  export PATH="${HOME}/bin:${PATH}"
}

teardown() {
  rm -Rf "${BATS_TMP_DIR}" || true
  unstub_all
}

function Database::dbScriptAllDatabases::display_help { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"
  run "${binDir}/dbScriptAllDatabases" --help
  assert_success
  # shellcheck disable=SC2154
  assert_line --index 2 --partial "Usage: dbScriptAllDatabases [-j|--jobs <numberOfJobs>] [-o|--output <outputDirectory>] [-d|--dsn <dsn>] [-v|--verbose] [-l|--log-format <logFormat>] [--database <dbName>] <scriptToExecute> [optional parameters to pass to the script]"
}

function Database::dbScriptAllDatabases::script_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallel" "${HOME}/bin"

  f() {
    # shellcheck disable=SC2317
    "${binDir}/dbScriptAllDatabases" 2>&1
  }
  run f
  assert_failure 1
  # shellcheck disable=SC2154
  assert_output --partial "FATAL   - You must provide the script file to be executed"
}

function Database::dbScriptAllDatabases::extractData { #@test
  cp "${BATS_TEST_DIRNAME}/mocks/parallelDbScriptAllDatabases" "${HOME}/bin/parallel"
  chmod +x "${HOME}/bin/parallel"
  export BATS_TEST_DIRNAME
  export HOME
  # shellcheck disable=SC2016
  stub mysql \
    '* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$@" > "${HOME}/query0" ; cat "${BATS_TEST_DIRNAME}/data/getUserDbList.result"' \
    '* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e * : echo "$8" > "${HOME}/query1" ; cat "${BATS_TEST_DIRNAME}/data/databaseSize.result_db1"' \
    '* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e * : echo "$8" > "${HOME}/query2" ; cat "${BATS_TEST_DIRNAME}/data/databaseSize.result_db2"'

  run "${binDir}/dbScriptAllDatabases" \
    -d "${BATS_TEST_DIRNAME}/data/databaseSize.envProvided.sh" \
    "${rootDir}/conf/dbScripts/extractData" \
    "${rootDir}/conf/dbQueries/databaseSize.sql"

  assert_success
  [[ -f "${HOME}/query1" ]]
  [[ "$(md5sum <"${HOME}/query1")" == "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]

  [[ -f "${HOME}/query2" ]]
  [[ "$(md5sum <"${HOME}/query2")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]

  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/dbScriptAllDatabases.result")"
}
