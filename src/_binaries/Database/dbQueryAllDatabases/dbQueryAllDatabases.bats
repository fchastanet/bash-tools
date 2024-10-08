#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.bash-tools/dsn" \
    "${HOME}/.bash-tools/dbImportDumps" \
    "${HOME}/.bash-tools/dbImportProfiles" \
    "${HOME}/.bash-tools/dbQueries"

  cp "${BATS_TEST_DIRNAME}/testsData/pv" "${HOME}/bin"
  cp "${BATS_TEST_DIRNAME}/testsData/gawk" "${HOME}/bin"
  cp "${BATS_TEST_DIRNAME}/testsData/gawk" "${HOME}/bin/awk"
  cp "${rootDir}/conf/defaultEnv/.env" "${HOME}/.bash-tools/.env"
  touch \
    "${HOME}/bin/mysql" \
    "${HOME}/bin/mysqldump" \
    "${HOME}/bin/mysqlshow" \
    "${HOME}/bin/builtinCommandWrapper" \
    "${HOME}/.bash-tools/dbQueries/fakeQuery.sql"
  chmod +x "${HOME}/bin/"*
  export BASH_FRAMEWORK_COMMAND="builtinCommandWrapper"

  cp "${BATS_TEST_DIRNAME}/testsData/dsn_"* "${HOME}/.bash-tools/dsn"

  export PATH="${PATH}:${HOME}/bin"
}

teardown() {
  rm -Rf "${HOME}" || true
  unstub_all
}

function Database::dbQueryAllDatabases::display_help { #@test

  testCommand "${binDir}/dbQueryAllDatabases" dbQueryAllDatabases.help.txt
}

function Database::dbQueryAllDatabases::query_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/parallel" "${HOME}/bin"
  # shellcheck disable=SC2154
  run "${binDir}/dbQueryAllDatabases" 2>&1
  assert_output --partial "ERROR   - Command dbQueryAllDatabases - Argument 'argQuery' should be provided at least 1 time(s)"
}

function Database::dbQueryAllDatabases::providingEnvFileChangeDbConnectionParametersAndRetrieveDbSize { #@test
  # shellcheck disable=SC2016,SC2086
  stub mysql \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo "$9" >'" '${HOME}/query1' ; cat '${BATS_TEST_DIRNAME}/testsData/getUserDbList.result'" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e \* : echo -n "${8}" >'" '${HOME}/query2' ; cat '${BATS_TEST_DIRNAME}/testsData/databaseSize.result_db1'" \
    '\* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e \* : echo -n "${8}" >'" '${HOME}/query3' ; cat '${BATS_TEST_DIRNAME}/testsData/databaseSize.result_db2'"

  # shellcheck disable=SC2016
  stub parallel \
    '--bar --eta --progress -j 1 * * * : while IFS= read -r db; do export DB_QUERY_ALL_DATABASES_COMMAND="DbQueryOneDatabase"; "$6" "$7" "${db}"; done'

  f() {
    # shellcheck disable=SC2317
    "${binDir}/dbQueryAllDatabases" \
      -f "${BATS_TEST_DIRNAME}/testsData/databaseSize.envProvided.sh" \
      "${rootDir}/conf/dbQueries/databaseSize.sql" 2>&1 | grep -v 'INFO    - Using dsn'
  }
  run f

  assert_output "$(cat "${BATS_TEST_DIRNAME}/testsData/dbQueryAllDatabases.result")"
  [[ -f "${HOME}/query1" ]]
  cat "${HOME}/query1"
  [[ "$(cat "${HOME}/query1")" == "$(cat "${BATS_TEST_DIRNAME}/testsData/getUserDbList.query")" ]]
  [[ -f "${HOME}/query2" ]]
  echo >>"${HOME}/query2" # add a new line as megalinter add a newline at end of file
  [[ "$(md5sum <"${HOME}/query2")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
  echo >>"${HOME}/query3" # add a new line as megalinter add a newline at end of file
  [[ -f "${HOME}/query3" ]]
  [[ "$(md5sum <"${HOME}/query3")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
}

function Database::dbQueryAllDatabases::multipleJobs { #@test
  export BATS_TEST_DIRNAME
  export HOME
  # shellcheck disable=SC2016,SC2086
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" >"${HOME}/query1" ; cat "${BATS_TEST_DIRNAME}/testsData/getUserDbList.result"' \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e * : echo -n "${8}" >"${HOME}/query2" ; cat "${BATS_TEST_DIRNAME}/testsData/databaseSize.result_db1"' \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e * : echo -n "${8}" >"${HOME}/query3" ; cat "${BATS_TEST_DIRNAME}/testsData/databaseSize.result_db2"'

  # shellcheck disable=SC2016
  stub parallel \
    '--bar --eta --progress -j 8 * * : while IFS= read -r db; do export DB_QUERY_ALL_DATABASES_COMMAND="DbQueryOneDatabase"; "$6" "$7" "${db}"; done'

  f() {
    # shellcheck disable=SC2317
    "${binDir}/dbQueryAllDatabases" \
      -f "${BATS_TEST_DIRNAME}/testsData/databaseSize.envProvided.sh" \
      -j 8 \
      "${rootDir}/conf/dbQueries/databaseSize.sql" 2>&1 | grep -v "INFO    - Using dsn"
  }
  run f
  assert_output "$(cat "${BATS_TEST_DIRNAME}/testsData/dbQueryAllDatabases.result")"
  [[ -f "${HOME}/query1" ]]
  [[ "$(cat "${HOME}/query1")" == "$(cat "${BATS_TEST_DIRNAME}/testsData/getUserDbList.query")" ]]
  [[ -f "${HOME}/query2" ]]
  echo >>"${HOME}/query2" # add a new line as megalinter add a newline at end of file
  [[ "$(md5sum <"${HOME}/query2")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
  echo >>"${HOME}/query3" # add a new line as megalinter add a newline at end of file
  [[ -f "${HOME}/query3" ]]
  [[ "$(md5sum <"${HOME}/query3")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]
}
